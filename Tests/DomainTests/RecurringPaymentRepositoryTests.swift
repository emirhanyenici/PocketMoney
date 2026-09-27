import Foundation
import SwiftData
import Testing
@testable import PocketMoney

/// Düzenli ödeme davranışı (Bölüm 9).
@MainActor
struct RecurringPaymentRepositoryTests {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .gmt
        return calendar
    }()
    private var repository: RecurringPaymentRepository {
        RecurringPaymentRepository(context: context, calendar: calendar)
    }

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
        try SeedLoader(context: container.mainContext).seedIfNeeded()
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
    }

    private func category(_ name: String) throws -> PocketMoney.Category {
        try #require(try context.fetch(FetchDescriptor<PocketMoney.Category>()).first { $0.name == name && $0.parent == nil })
    }

    private func draft(
        _ name: String = "Kira",
        amount: Decimal = 15000,
        day: Int = 5,
        start: Date? = nil,
        mode: RecurringMode = .confirm
    ) throws -> RecurringPaymentRepository.Draft {
        RecurringPaymentRepository.Draft(
            name: name,
            amount: amount,
            dayOfPeriod: day,
            startDate: start ?? date(2026, 9, 20),
            mode: mode,
            category: try category("Konut")
        )
    }

    private func allTransactions() throws -> [Transaction] {
        try context.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date)]))
    }

    @Test func createComputesFirstDueDate() throws {
        let rent = try repository.create(try draft())
        #expect(rent.nextDueDate == date(2026, 10, 5))
        #expect(rent.mode == .confirm)
        #expect(try allTransactions().isEmpty)
    }

    @Test func rejectsInvalidDraft() throws {
        #expect(throws: RecurringPaymentRepository.RecurringError.emptyName) { try repository.create(try draft("  ")) }
        #expect(throws: RecurringPaymentRepository.RecurringError.nonPositiveAmount) { try repository.create(try draft(amount: 0)) }
    }

    @Test func confirmModeNeverPostsByItself() throws {
        let rent = try repository.create(try draft())
        #expect(try repository.postDueAutomaticPayments(now: date(2026, 12, 1)).isEmpty)
        #expect(rent.nextDueDate == date(2026, 10, 5))
        #expect(repository.status(of: rent, today: date(2026, 10, 7)) == .overdue(days: 2))
    }

    @Test func markPaidCreatesTransactionAndAdvances() throws {
        let rent = try repository.create(try draft())
        let paid = try repository.markPaid(rent, on: date(2026, 10, 6, hour: 10))
        #expect(paid.amount == 15000)
        #expect(paid.kind == .expense)
        #expect(paid.category?.name == "Konut")
        #expect(paid.recurringPayment == rent)
        #expect(paid.recurringPeriodKey == "2026-10-05")
        #expect(paid.localDay == "2026-10-06")
        #expect(rent.nextDueDate == date(2026, 11, 5))
        #expect(repository.status(of: rent, today: date(2026, 10, 6)) == .upcoming(days: 30))
    }

    @Test func markPaidCanOverrideAmountForThisPeriodOnly() throws {
        let bill = try repository.create(try draft("Elektrik", amount: 800))
        let paid = try repository.markPaid(bill, amount: 1135.40, on: date(2026, 10, 5))
        #expect(paid.amount == Decimal(string: "1135.4"))
        #expect(bill.amount == 800)
        #expect(bill.priceHistory.isEmpty)
    }

    @Test func skipAdvancesWithoutTransaction() throws {
        let rent = try repository.create(try draft())
        try repository.skip(rent)
        #expect(rent.nextDueDate == date(2026, 11, 5))
        #expect(try allTransactions().isEmpty)
    }

    @Test func autoPostFillsMissedPeriodsOnDueDatesOnce() throws {
        let netflix = try repository.create(try draft("Netflix", amount: 229.99, day: 15, start: date(2026, 8, 1), mode: .autoPost))
        let posted = try repository.postDueAutomaticPayments(now: date(2026, 10, 20))
        #expect(posted.map(\.localDay) == ["2026-08-15", "2026-09-15", "2026-10-15"])
        #expect(netflix.nextDueDate == date(2026, 11, 15))

        // Tekrar çalışınca (açılış + arka plan) aynı dönemler yeniden oluşmaz.
        #expect(try repository.postDueAutomaticPayments(now: date(2026, 10, 20)).isEmpty)
        #expect(try allTransactions().count == 3)
    }

    @Test func postingIsIdempotentPerPeriodKey() throws {
        let rent = try repository.create(try draft())
        let first = try repository.markPaid(rent, on: date(2026, 10, 5))
        // Vade geri alınıp aynı dönem tekrar ödenirse ikinci işlem oluşmaz.
        rent.nextDueDate = date(2026, 10, 5)
        let second = try repository.markPaid(rent, on: date(2026, 10, 5))
        #expect(first == second)
        #expect(try allTransactions().count == 1)
    }

    @Test func installmentsEndThePayment() throws {
        var installment = try draft("Telefon taksidi", amount: 2500)
        installment.installments = 2
        let phone = try repository.create(installment)
        try repository.markPaid(phone, on: date(2026, 10, 5))
        #expect(phone.isActive)
        #expect(phone.remainingInstallments == 1)
        try repository.markPaid(phone, on: date(2026, 11, 5))
        #expect(!phone.isActive)
        #expect(repository.status(of: phone) == .ended)
        #expect(throws: RecurringPaymentRepository.RecurringError.notDue) { try repository.markPaid(phone) }
    }

    @Test func endDateStopsAfterLastDue() throws {
        var gym = try draft("Spor salonu", amount: 1500)
        gym.endDate = date(2026, 11, 10)
        let membership = try repository.create(gym)
        try repository.markPaid(membership, on: date(2026, 10, 5))
        #expect(membership.isActive)
        try repository.markPaid(membership, on: date(2026, 11, 5))
        #expect(!membership.isActive)
    }

    @Test func amountChangeIsRecordedAndDoesNotTouchHistory() throws {
        let netflix = try repository.create(try draft("Netflix", amount: 199.99, day: 15))
        let old = try repository.markPaid(netflix, on: date(2026, 9, 25))

        var updated = try draft("Netflix", amount: 229.99, day: 15)
        updated.startDate = netflix.startDate
        try repository.update(netflix, with: updated, now: date(2026, 9, 26))

        #expect(netflix.amount == Decimal(string: "229.99"))
        #expect(netflix.priceHistory == [PriceChange(date: date(2026, 9, 26), oldAmount: Decimal(string: "199.99") ?? 0, newAmount: Decimal(string: "229.99") ?? 0)])
        #expect(old.amount == Decimal(string: "199.99"))
        // İlk vade 15 Ekim erken ödendi; yalnızca tutar değişti, vade yeniden hesaplanmaz.
        #expect(netflix.nextDueDate == date(2026, 11, 15))
    }

    @Test func deleteKeepsPastTransactions() throws {
        let rent = try repository.create(try draft())
        try repository.markPaid(rent, on: date(2026, 10, 5))
        try repository.delete(rent)
        let remaining = try allTransactions()
        #expect(remaining.count == 1)
        #expect(remaining.first?.recurringPayment == nil)
        #expect(try context.fetch(FetchDescriptor<RecurringPayment>()).isEmpty)
    }
}
