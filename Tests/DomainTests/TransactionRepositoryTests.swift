import Foundation
import SwiftData
import Testing
@testable import PocketMoney

/// Silme ve geri alma (Bölüm 5.4).
@MainActor
struct TransactionRepositoryTests {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }
    private var repository: TransactionRepository { TransactionRepository(context: context) }

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
        try SeedLoader(context: container.mainContext).seedIfNeeded()
    }

    private func category(_ name: String, _ sub: String? = nil) throws -> PocketMoney.Category {
        let all = try context.fetch(FetchDescriptor<PocketMoney.Category>())
        let main = try #require(all.first { $0.name == name && $0.parent == nil })
        guard let sub else { return main }
        return try #require(main.children.first { $0.name == sub })
    }

    private func merchant(_ name: String) throws -> Merchant {
        try #require(try context.fetch(FetchDescriptor<Merchant>()).first { $0.name == name })
    }

    private func onlyTransaction() throws -> Transaction {
        let all = try context.fetch(FetchDescriptor<Transaction>())
        #expect(all.count == 1)
        return try #require(all.first)
    }

    private func insertCoffee() throws -> Transaction {
        let transaction = Transaction(
            amount: 95,
            kind: .expense,
            category: try category("Yeme & İçme"),
            subcategory: try category("Yeme & İçme", "Kahve & Kafe"),
            merchant: try merchant("Starbucks")
        )
        context.insert(transaction)
        try context.save()
        return transaction
    }

    @Test func restoreBringsBackSameTransaction() throws {
        let original = try insertCoffee()
        let id = original.id
        let snapshot = try repository.delete(original)
        #expect(try context.fetch(FetchDescriptor<Transaction>()).isEmpty)

        try repository.restore(snapshot)
        let restored = try onlyTransaction()
        #expect(restored.id == id)
        #expect(restored.amount == 95)
        #expect(restored.subcategory?.name == "Kahve & Kafe")
        #expect(restored.merchant?.name == "Starbucks")
    }

    @Test func restoreSurvivesDeletedSubcategory() throws {
        let snapshot = try repository.delete(try insertCoffee())
        let coffee = try category("Yeme & İçme", "Kahve & Kafe")
        try CategoryRepository(context: context).delete(coffee, movingTransactionsTo: nil)

        try repository.restore(snapshot)
        let restored = try onlyTransaction()
        #expect(restored.category?.name == "Yeme & İçme")
        #expect(restored.subcategory == nil)
    }

    @Test func restoreSurvivesMergedMerchant() throws {
        let snapshot = try repository.delete(try insertCoffee())
        try MerchantRepository(context: context).merge(try merchant("Starbucks"), into: try merchant("Kahve Dünyası"))

        try repository.restore(snapshot)
        let restored = try onlyTransaction()
        #expect(restored.merchant == nil)
        #expect(restored.category?.name == "Yeme & İçme")
    }
}
