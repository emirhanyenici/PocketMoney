#if DEBUG
import Foundation
import SwiftData

/// Yalnızca `#Preview`'lar için örnek işlemler (Bölüm 15). Uygulamada asla
/// örnek veri gösterilmez (Bölüm 6.2-I).
enum PreviewSampleData {
    static func insertTransactions(into context: ModelContext) throws {
        let categories = try context.fetch(FetchDescriptor<Category>())
        let merchants = try context.fetch(FetchDescriptor<Merchant>())
        let methods = try context.fetch(FetchDescriptor<PaymentMethod>(sortBy: [SortDescriptor(\.sortOrder)]))

        func category(_ name: String, _ sub: String? = nil) -> (Category?, Category?) {
            let main = categories.first { $0.name == name && $0.parent == nil }
            return (main, sub.flatMap { s in main?.children.first { $0.name == s } })
        }
        func merchant(_ name: String) -> Merchant? { merchants.first { $0.name == name } }
        let card = methods.first { $0.type == .creditCard }
        let calendar = LocalDay.currentCalendar

        let samples: [(daysAgo: Int, amount: String, kind: TransactionKind, category: (Category?, Category?), merchant: Merchant?, channel: PurchaseChannel?)] = [
            (0, "95", .expense, category("Yeme & İçme", "Kahve & Kafe"), merchant("Starbucks"), .inStore),
            (0, "642.50", .expense, category("Market & Gıda", "Süpermarket"), merchant("Migros"), .inStore),
            (1, "229.99", .expense, category("Abonelikler", "Video"), nil, .online),
            (2, "1299", .expense, category("Giyim & Aksesuar", "Giyim"), merchant("Zara"), .online),
            (3, "15000", .expense, category("Konut", "Kira"), nil, nil),
            (4, "1850", .expense, category("Ulaşım", "Yakıt"), merchant("Shell"), .inStore),
            (5, "45000", .income, category("Maaş"), nil, nil),
            (33, "14200", .expense, category("Konut", "Kira"), nil, nil)
        ]
        for sample in samples {
            let date = calendar.date(byAdding: .day, value: -sample.daysAgo, to: .now) ?? .now
            context.insert(Transaction(
                amount: Decimal(string: sample.amount) ?? 0,
                kind: sample.kind,
                date: date,
                channel: sample.channel,
                category: sample.category.0,
                subcategory: sample.category.1,
                merchant: sample.merchant,
                paymentMethod: sample.kind == .expense ? card : nil
            ))
        }
        try context.save()
    }
}
#endif
