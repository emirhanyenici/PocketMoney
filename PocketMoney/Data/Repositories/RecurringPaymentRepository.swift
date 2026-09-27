import Foundation
import SwiftData

/// Düzenli ödemeler (Bölüm 9): ekle, düzenle, "Ödendi", "Atla", otomatik kayıt.
///
/// Her vade `recurringPeriodKey` (vadenin yerel günü, "2026-10-05") ile
/// işaretlenir; aynı ödeme + aynı anahtar için ikinci işlem oluşmaz (Bölüm 9.4).
struct RecurringPaymentRepository {
    enum RecurringError: Error, Equatable {
        case emptyName
        case nonPositiveAmount
        case notDue
    }

    /// Form alanları; ekleme ve düzenleme aynı değerleri kullanır.
    struct Draft {
        var name: String
        var amount: Decimal
        var frequency: RecurrenceFrequency = .monthly
        var dayOfPeriod: Int
        var startDate: Date = .now
        var endDate: Date?
        var installments: Int?
        var mode: RecurringMode = .confirm
        var reminderDaysBefore: Int?
        var category: Category?
        var subcategory: Category?
        var merchant: Merchant?
        var paymentMethod: PaymentMethod?
    }

    /// Kaçırılan vadeler en fazla bu kadar geriye doldurulur (uzun süre açılmayan uygulama).
    static let maxCatchUpOccurrences = 24

    let context: ModelContext
    var calendar: Calendar = LocalDay.currentCalendar

    // MARK: - Ekle / düzenle / sil

    @discardableResult
    func create(_ draft: Draft) throws -> RecurringPayment {
        let (name, amount) = try validated(draft)
        let schedule = RecurrenceSchedule(frequency: draft.frequency, dayOfPeriod: draft.dayOfPeriod, calendar: calendar)
        let payment = RecurringPayment(
            name: name,
            amount: amount,
            frequency: draft.frequency,
            dayOfPeriod: draft.dayOfPeriod,
            startDate: calendar.startOfDay(for: draft.startDate),
            nextDueDate: schedule.firstDueDate(onOrAfter: draft.startDate),
            mode: draft.mode
        )
        apply(draft, to: payment)
        context.insert(payment)
        try context.saveOrRollback()
        return payment
    }

    /// Tutar değişince fiyat geçmişine yazılır; geçmiş işlemler etkilenmez (Bölüm 9.3).
    /// Periyot, gün veya başlangıç değişirse sonraki vade yeniden hesaplanır.
    func update(_ payment: RecurringPayment, with draft: Draft, now: Date = .now) throws {
        let (name, amount) = try validated(draft)
        if amount != payment.amount {
            payment.priceHistory.append(PriceChange(date: now, oldAmount: payment.amount, newAmount: amount))
        }
        let startDay = calendar.startOfDay(for: draft.startDate)
        let scheduleChanged = draft.frequency != payment.frequency
            || draft.dayOfPeriod != payment.dayOfPeriod
            || startDay != payment.startDate
        payment.name = name
        payment.amount = amount
        payment.frequency = draft.frequency
        payment.dayOfPeriod = draft.dayOfPeriod
        payment.startDate = startDay
        payment.mode = draft.mode
        apply(draft, to: payment)
        if scheduleChanged {
            let schedule = RecurrenceSchedule(frequency: draft.frequency, dayOfPeriod: draft.dayOfPeriod, calendar: calendar)
            payment.nextDueDate = schedule.firstDueDate(onOrAfter: max(startDay, calendar.startOfDay(for: now)))
        }
        try context.saveOrRollback()
    }

    /// Geçmiş işlemler kalır; yalnızca düzenli ödemeye bağları çözülür.
    func delete(_ payment: RecurringPayment) throws {
        for transaction in try transactions(of: payment) {
            transaction.recurringPayment = nil
        }
        context.delete(payment)
        try context.saveOrRollback()
    }

    func setActive(_ payment: RecurringPayment, _ active: Bool) throws {
        payment.isActive = active
        try context.saveOrRollback()
    }

    // MARK: - Vade

    /// "Ödendi": bekleyen vade için işlem oluşturur ve vadeyi ilerletir.
    /// Tutar yalnızca bu vade için değiştirilebilir (elektrik, doğalgaz).
    /// Vadesi gelmemiş ödeme de erken ödenebilir.
    @discardableResult
    func markPaid(_ payment: RecurringPayment, amount: Decimal? = nil, on date: Date = .now) throws -> Transaction {
        let paidAmount = amount ?? payment.amount
        guard paidAmount > 0 else { throw RecurringError.nonPositiveAmount }
        guard payment.isActive else { throw RecurringError.notDue }
        let transaction = try post(payment, dueDate: payment.nextDueDate, amount: paidAmount, date: date)
        advance(payment)
        try context.saveOrRollback()
        return transaction
    }

    /// "Atla": bu vade ödenmedi/iptal; işlem oluşmadan vade ilerler.
    func skip(_ payment: RecurringPayment) throws {
        guard payment.isActive else { throw RecurringError.notDue }
        advance(payment)
        try context.saveOrRollback()
    }

    /// Otomatik kayıtlı ödemelerin gelmiş vadelerini, vade gününe işler.
    /// Açılışta ve arka planda çağrılır; tekrar çağrılması güvenlidir.
    @discardableResult
    func postDueAutomaticPayments(now: Date = .now) throws -> [Transaction] {
        let today = calendar.startOfDay(for: now)
        let autoMode = RecurringMode.autoPost.rawValue
        let candidates = try context.fetch(FetchDescriptor<RecurringPayment>(
            predicate: #Predicate { $0.isActive && $0.modeRaw == autoMode && $0.nextDueDate <= today }
        ))
        var posted: [Transaction] = []
        for payment in candidates {
            var count = 0
            while payment.isActive, payment.nextDueDate <= today, count < Self.maxCatchUpOccurrences {
                posted.append(try post(payment, dueDate: payment.nextDueDate, amount: payment.amount, date: payment.nextDueDate))
                advance(payment)
                count += 1
            }
        }
        if !posted.isEmpty { try context.saveOrRollback() }
        return posted
    }

    func status(of payment: RecurringPayment, today: Date = .now) -> RecurringStatus {
        RecurringStatus.of(nextDueDate: payment.nextDueDate, isActive: payment.isActive, today: today, calendar: calendar)
    }

    func transactions(of payment: RecurringPayment) throws -> [Transaction] {
        let id = payment.persistentModelID
        return try context.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
            .filter { $0.recurringPayment?.persistentModelID == id }
    }

    // MARK: - Yardımcılar

    private func validated(_ draft: Draft) throws -> (String, Decimal) {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw RecurringError.emptyName }
        guard draft.amount > 0 else { throw RecurringError.nonPositiveAmount }
        return (name, draft.amount)
    }

    private func apply(_ draft: Draft, to payment: RecurringPayment) {
        payment.endDate = draft.endDate.map { calendar.startOfDay(for: $0) }
        payment.remainingInstallments = draft.installments
        payment.reminderDaysBefore = draft.reminderDaysBefore
        payment.category = draft.category
        payment.subcategory = draft.subcategory
        payment.merchant = draft.merchant
        payment.paymentMethod = draft.paymentMethod
    }

    /// Aynı vade için işlem zaten varsa onu döner (idempotent).
    private func post(_ payment: RecurringPayment, dueDate: Date, amount: Decimal, date: Date) throws -> Transaction {
        let key = LocalDay.key(for: dueDate, calendar: calendar)
        let id = payment.persistentModelID
        let existing = try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.recurringPeriodKey == key }))
            .first { $0.recurringPayment?.persistentModelID == id }
        if let existing { return existing }

        let transaction = Transaction(
            amount: amount,
            kind: payment.category?.kind ?? .expense,
            date: date,
            calendar: calendar,
            category: payment.category,
            subcategory: payment.subcategory,
            merchant: payment.merchant,
            paymentMethod: payment.paymentMethod
        )
        transaction.recurringPayment = payment
        transaction.recurringPeriodKey = key
        context.insert(transaction)
        return transaction
    }

    /// Sonraki vadeye geçer; taksit bittiyse veya bitiş tarihi aşıldıysa durdurur.
    private func advance(_ payment: RecurringPayment) {
        let schedule = RecurrenceSchedule(frequency: payment.frequency, dayOfPeriod: payment.dayOfPeriod, calendar: calendar)
        payment.nextDueDate = schedule.nextDueDate(after: payment.nextDueDate)
        if let remaining = payment.remainingInstallments {
            payment.remainingInstallments = max(remaining - 1, 0)
            if remaining - 1 <= 0 { payment.isActive = false }
        }
        if let endDate = payment.endDate, payment.nextDueDate > endDate {
            payment.isActive = false
        }
    }
}
