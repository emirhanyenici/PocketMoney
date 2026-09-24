import Foundation
import SwiftData

extension SchemaV1 {
    /// Kira, fatura, abonelik gibi düzenli ödeme (Bölüm 9, Bölüm 12).
    /// Model v0.1'de şemaya girer; davranışı v0.2'de gelir.
    @Model
    final class RecurringPayment {
        @Attribute(.unique) var id: UUID
        var name: String
        var amount: Decimal
        /// `RecurrenceFrequency.storageKey`.
        var frequencyKey: String
        /// Yalnızca `.customDays(N)` için dolu.
        var frequencyCustomDays: Int?
        /// Ödeme günü; ayda o gün yoksa ayın son günü kullanılır (Bölüm 9.1).
        var dayOfPeriod: Int
        var startDate: Date
        var endDate: Date?
        var remainingInstallments: Int?
        var modeRaw: String
        /// "Ödendi" veya otomatik kayıtla ilerler.
        var nextDueDate: Date
        var reminderDaysBefore: Int?
        var isActive: Bool
        var category: Category?
        var subcategory: Category?
        var merchant: Merchant?
        var paymentMethod: PaymentMethod?
        var priceHistory: [PriceChange]

        var frequency: RecurrenceFrequency {
            get { RecurrenceFrequency(storageKey: frequencyKey, customDays: frequencyCustomDays) ?? .monthly }
            set {
                frequencyKey = newValue.storageKey
                frequencyCustomDays = newValue.customDays
            }
        }

        var mode: RecurringMode {
            get { RecurringMode(rawValue: modeRaw) ?? .confirm }
            set { modeRaw = newValue.rawValue }
        }

        init(
            name: String,
            amount: Decimal,
            frequency: RecurrenceFrequency,
            dayOfPeriod: Int,
            startDate: Date,
            nextDueDate: Date,
            mode: RecurringMode = .confirm
        ) {
            self.id = UUID()
            self.name = name
            self.amount = amount
            self.frequencyKey = frequency.storageKey
            self.frequencyCustomDays = frequency.customDays
            self.dayOfPeriod = dayOfPeriod
            self.startDate = startDate
            self.modeRaw = mode.rawValue
            self.nextDueDate = nextDueDate
            self.isActive = true
            self.priceHistory = []
        }
    }
}
