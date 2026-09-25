import Foundation
import SwiftData
import Testing
@testable import PocketMoney

/// Marka yönetimi kuralları (Bölüm 8).
@MainActor
struct MerchantRepositoryTests {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }
    private var repository: MerchantRepository { MerchantRepository(context: context) }

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
        try SeedLoader(context: container.mainContext).seedIfNeeded()
    }

    private func merchant(_ name: String) throws -> Merchant {
        try #require(try context.fetch(FetchDescriptor<Merchant>()).first { $0.name == name })
    }

    @Test func createRejectsTurkishInsensitiveDuplicate() throws {
        #expect(throws: MerchantRepository.MerchantError.duplicateName) {
            try repository.create(name: "sok")
        }
        let created = try repository.create(name: "Köşe Büfe")
        #expect(created.searchKey == "kose bufe")
    }

    @Test func renameUpdatesSearchKeyAndPreventsCollision() throws {
        let koton = try merchant("Koton")
        try repository.rename(koton, to: "Koton Outlet")
        #expect(koton.searchKey == "koton outlet")

        #expect(throws: MerchantRepository.MerchantError.duplicateName) {
            try repository.rename(koton, to: "MAVİ")
        }
    }

    /// Birleştirme: kaynağın işlemleri hedefe geçer, kaynak silinir, işlem kaybolmaz.
    @Test func mergeMovesTransactionsAndDeletesSource() throws {
        let target = try merchant("Starbucks")
        let duplicate = try repository.create(name: "Starbucks Kadıköy")
        for merchant in [target, duplicate, duplicate] {
            context.insert(Transaction(amount: 95, kind: .expense, merchant: merchant))
        }

        try repository.merge(duplicate, into: target)

        #expect(try repository.transactionCount(for: target) == 3)
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 3)
        #expect(try repository.existing(named: "Starbucks Kadıköy") == nil)
    }

    @Test func mergeFillsMissingSuggestionFromSource() throws {
        let target = try repository.create(name: "Mahalle Kahvecisi")
        let source = try merchant("Kahve Dünyası")
        try repository.merge(source, into: target)
        #expect(target.suggestedCategory?.name == "Kahve & Kafe")
    }

    @Test func cannotMergeIntoSelf() throws {
        let koton = try merchant("Koton")
        #expect(throws: MerchantRepository.MerchantError.mergeIntoSelf) {
            try repository.merge(koton, into: koton)
        }
    }

    @Test func hiddenMerchantIsNotSuggested() throws {
        let sok = try merchant("ŞOK")
        try repository.setHidden(sok, true)

        let editor = TransactionEditorModel()
        editor.merchantQuery = "sok"
        #expect(!editor.merchantSuggestions(from: try context.fetch(FetchDescriptor<Merchant>())).contains(sok))
    }
}
