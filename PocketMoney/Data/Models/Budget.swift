import Foundation
import SwiftData

extension SchemaV1 {
    /// Toplam (`category == nil`) veya kategori bütçesi (Bölüm 10, Bölüm 12).
    /// Model v0.1'de şemaya girer; davranışı v0.3'te gelir.
    @Model
    final class Budget {
        @Attribute(.unique) var id: UUID
        var limit: Decimal
        var category: Category?
        var periodTypeRaw: String
        var isActive: Bool

        var periodType: BudgetPeriod {
            get { BudgetPeriod(rawValue: periodTypeRaw) ?? .month }
            set { periodTypeRaw = newValue.rawValue }
        }

        init(limit: Decimal, category: Category? = nil, periodType: BudgetPeriod = .month) {
            self.id = UUID()
            self.limit = limit
            self.category = category
            self.periodTypeRaw = periodType.rawValue
            self.isActive = true
        }
    }
}
