import Foundation
import SwiftData

extension SchemaV1 {
    /// Tek bir gider veya gelir kaydı (Bölüm 12).
    ///
    /// Enum alanları ham değer (`kindRaw`, `channelRaw`) olarak saklanır çünkü
    /// `#Predicate` enum karşılaştıramaz; kod her zaman `kind` / `channel`
    /// üzerinden çalışır.
    @Model
    final class Transaction {
        @Attribute(.unique) var id: UUID
        /// Her zaman pozitif; yönü `kind` belirler.
        var amount: Decimal
        /// "TRY" — çoklu para birimine hazırlık.
        var currencyCode: String
        var kindRaw: String
        var date: Date
        /// İşlemin girildiği yerel gün ("2026-08-31"). Dönem gruplaması bu alana
        /// göre yapılır (Bölüm 13, saat dilimi kuralı). `date` yalnızca
        /// `updateDate(_:calendar:)` ile değiştirilmeli ki ikisi uyumlu kalsın.
        var localDay: String
        var note: String?
        var tags: [String]
        var channelRaw: String?
        var createdAt: Date
        var updatedAt: Date

        var category: Category?
        var subcategory: Category?
        var merchant: Merchant?
        var paymentMethod: PaymentMethod?
        var recurringPayment: RecurringPayment?
        /// "2026-09" — aynı dönem için iki kez işlem oluşmaması için (Bölüm 9.4).
        var recurringPeriodKey: String?

        var kind: TransactionKind {
            get { TransactionKind(rawValue: kindRaw) ?? .expense }
            set { kindRaw = newValue.rawValue }
        }

        var channel: PurchaseChannel? {
            get { channelRaw.flatMap(PurchaseChannel.init(rawValue:)) }
            set { channelRaw = newValue?.rawValue }
        }

        init(
            amount: Decimal,
            kind: TransactionKind,
            date: Date = .now,
            calendar: Calendar = LocalDay.currentCalendar,
            currencyCode: String = "TRY",
            note: String? = nil,
            tags: [String] = [],
            channel: PurchaseChannel? = nil,
            category: Category? = nil,
            subcategory: Category? = nil,
            merchant: Merchant? = nil,
            paymentMethod: PaymentMethod? = nil
        ) {
            let now = Date.now
            self.id = UUID()
            self.amount = amount
            self.currencyCode = currencyCode
            self.kindRaw = kind.rawValue
            self.date = date
            self.localDay = LocalDay.key(for: date, calendar: calendar)
            self.note = note
            self.tags = tags
            self.channelRaw = channel?.rawValue
            self.createdAt = now
            self.updatedAt = now
            self.category = category
            self.subcategory = subcategory
            self.merchant = merchant
            self.paymentMethod = paymentMethod
        }

        /// Tarihi değiştirir ve `localDay`'i düzenlemenin yapıldığı takvime göre yeniden hesaplar.
        func updateDate(_ newDate: Date, calendar: Calendar = LocalDay.currentCalendar) {
            date = newDate
            localDay = LocalDay.key(for: newDate, calendar: calendar)
            updatedAt = .now
        }
    }
}
