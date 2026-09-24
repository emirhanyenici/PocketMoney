import SwiftData
import Testing
import UIKit
@testable import PocketMoney

/// Seed JSON'larının Bölüm 7 ve Bölüm 8 ile tutarlılığı.
@MainActor
struct SeedDataTests {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init() throws {
        container = try AppModelContainer.make(inMemory: true)
        try SeedLoader(context: container.mainContext).seedIfNeeded()
    }

    private func categories() throws -> [PocketMoney.Category] {
        try context.fetch(FetchDescriptor<PocketMoney.Category>())
    }

    private func merchant(named name: String) throws -> Merchant {
        let merchants = try context.fetch(FetchDescriptor<Merchant>(predicate: #Predicate { $0.name == name }))
        return try #require(merchants.first)
    }

    // MARK: - Kategoriler (Bölüm 7)

    @Test func seedsAllCategoriesFromGuideline() throws {
        let all = try categories()
        let main = all.filter { $0.parent == nil }

        #expect(main.filter { $0.kind == .expense }.count == 17)
        #expect(main.filter { $0.kind == .income }.count == 4)
        let subcategoryCount = all.count - main.count
        let allFromSeed = all.allSatisfy(\.isSystem)
        #expect(subcategoryCount == 86)
        #expect(allFromSeed)
    }

    @Test func everyColorTokenIsInPalette() throws {
        let invalid = try categories().filter { CategoryColor(rawValue: $0.colorToken) == nil }
        #expect(invalid.map(\.name).isEmpty)
    }

    @Test func everySymbolExists() throws {
        let invalid = try categories().filter { UIImage(systemName: $0.symbolName) == nil }
        #expect(Set(invalid.map(\.symbolName)).isEmpty)
    }

    @Test func subcategoriesInheritParentKindAndLook() throws {
        for child in try categories() {
            guard let parent = child.parent else { continue }
            #expect(child.kind == parent.kind, "\(child.name)")
            #expect(child.colorToken == parent.colorToken, "\(child.name)")
        }
    }

    // MARK: - Markalar (Bölüm 8)

    @Test func seedsAllMerchantsWithUniqueSearchKeys() throws {
        let merchants = try context.fetch(FetchDescriptor<Merchant>())
        #expect(merchants.count == 102)
        #expect(Set(merchants.map(\.searchKey)).count == merchants.count)
    }

    @Test func merchantSuggestsSubcategory() throws {
        let suggestion = try #require(try merchant(named: "Shell").suggestedCategory)
        #expect(suggestion.name == "Yakıt")
        #expect(suggestion.parent?.name == "Ulaşım")
    }

    @Test func marketplaceHasNoCategoryButIsOnline() throws {
        let trendyol = try merchant(named: "Trendyol")
        #expect(trendyol.suggestedCategory == nil)
        #expect(trendyol.lastUsedChannel == .online)
    }

    // MARK: - Ödeme yöntemleri ve tekrar çalıştırma

    @Test func seedsDefaultPaymentMethodsInOrder() throws {
        let methods = try context.fetch(FetchDescriptor<PaymentMethod>(sortBy: [SortDescriptor(\.sortOrder)]))
        #expect(methods.map(\.type) == [.cash, .creditCard, .debitCard, .transfer, .other])
    }

    @Test func seedingTwiceAddsNothing() throws {
        let before = try context.fetchCount(FetchDescriptor<PocketMoney.Category>())
        try SeedLoader(context: context).seedIfNeeded()
        #expect(try context.fetchCount(FetchDescriptor<PocketMoney.Category>()) == before)
        #expect(try context.fetchCount(FetchDescriptor<Merchant>()) == 102)
    }

    @Test func doesNotReseedAfterUserEdits() throws {
        let konut = try #require(try categories().first { $0.name == "Konut" })
        konut.name = "Ev"
        try context.save()

        try SeedLoader(context: context).seedIfNeeded()

        #expect(try categories().contains { $0.name == "Konut" } == false)
    }
}
