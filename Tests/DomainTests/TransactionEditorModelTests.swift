import Foundation
import SwiftData
import Testing
@testable import PocketMoney

/// Hızlı Ekle kuralları (Bölüm 6.2-B, Bölüm 8).
@MainActor
struct TransactionEditorModelTests {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

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

    private func allMerchants() throws -> [Merchant] {
        try context.fetch(FetchDescriptor<Merchant>(sortBy: [SortDescriptor(\.name)]))
    }

    @Test func saveRequiresPositiveAmountAndCategory() throws {
        let model = TransactionEditorModel()
        #expect(!model.canSave)

        model.expression.input(.digit(5))
        #expect(!model.canSave)

        model.selectCategory(try category("Konut"))
        #expect(model.canSave)
    }

    @Test func merchantSuggestsCategoryAndSubcategory() throws {
        let model = TransactionEditorModel()
        model.selectMerchant(try merchant("Shell"))

        #expect(model.category?.name == "Ulaşım")
        #expect(model.subcategory?.name == "Yakıt")
    }

    /// Kullanıcı kategoriyi önceden seçtiyse marka önerisi üzerine yazılmaz.
    @Test func merchantDoesNotOverrideUserCategory() throws {
        let model = TransactionEditorModel()
        let cosmetics = try category("Kozmetik & Kişisel Bakım")
        model.selectCategory(cosmetics)
        model.selectMerchant(try merchant("Koton"))

        #expect(model.category == cosmetics)
    }

    /// Seçili alt kategorinin markaları önce gelir (Kahve & Kafe → Starbucks, Burger King değil).
    @Test func suggestionsPreferSelectedSubcategory() throws {
        let model = TransactionEditorModel()
        model.selectCategory(try category("Yeme & İçme"))
        model.toggleSubcategory(try category("Yeme & İçme", "Kahve & Kafe"))

        let suggestions = model.merchantSuggestions(from: try allMerchants())
        let first = try #require(suggestions.first)
        #expect(first.suggestedCategory?.name == "Kahve & Kafe")
        #expect(!suggestions.prefix(8).contains { $0.name == "Burger King" })
    }

    @Test func searchIsTurkishInsensitive() throws {
        let model = TransactionEditorModel()
        model.merchantQuery = "sok"
        #expect(model.merchantSuggestions(from: try allMerchants()).first?.name == "ŞOK")
        #expect(!model.canAddQueryAsMerchant(existing: try allMerchants()))
    }

    /// Bir markada son seçilen kategori, kanal ve ödeme yöntemi hatırlanır.
    @Test func saveRemembersLastChoicesOnMerchant() throws {
        let koton = try merchant("Koton")
        let cosmetics = try category("Kozmetik & Kişisel Bakım")
        let card = try #require(try context.fetch(FetchDescriptor<PaymentMethod>()).first { $0.type == .creditCard })

        let first = TransactionEditorModel()
        first.expression.input(.digit(9))
        first.selectCategory(cosmetics)
        first.selectMerchant(koton)
        first.toggleChannel(.inStore)
        first.togglePaymentMethod(card)
        try first.save(in: context)

        let next = TransactionEditorModel()
        next.selectMerchant(koton)
        #expect(next.category == cosmetics)
        #expect(next.channel == .inStore)
        #expect(next.paymentMethod == card)
    }

    /// "'X' olarak ekle": marka kayıtla oluşur; aynı ad ikinci kez yeni marka açmaz.
    @Test func newMerchantIsCreatedOnceOnSave() throws {
        for _ in 0..<2 {
            let model = TransactionEditorModel()
            model.expression.input(.digit(4))
            model.selectCategory(try category("Yeme & İçme"))
            model.merchantQuery = "Köşe Büfe"
            model.addQueryAsNewMerchant()
            try model.save(in: context)
        }
        let matches = try allMerchants().filter { $0.searchKey == "kose bufe" }
        #expect(matches.count == 1)
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 2)
    }

    /// Özet'teki "Gelir ekle" editörü doğrudan gelir modunda açar.
    @Test func opensInRequestedKind() throws {
        let model = TransactionEditorModel(initialKind: .income)
        #expect(model.kind == .income)
        let offered = model.orderedCategories(from: try context.fetch(FetchDescriptor<PocketMoney.Category>()), recent: [])
        #expect(offered.first?.name == "Maaş")
    }

    /// Izgarada ilk 7; Tümü'nden seçilen kategori ızgarada görünür kalır.
    @Test func featuredCategoriesKeepSelectionVisible() throws {
        let model = TransactionEditorModel()
        let ordered = model.orderedCategories(from: try context.fetch(FetchDescriptor<PocketMoney.Category>()), recent: [])
        #expect(model.featuredCategories(from: ordered).count == 7)

        let pets = try category("Evcil Hayvan")
        model.select(category: pets, subcategory: try category("Evcil Hayvan", "Veteriner"))
        let featured = model.featuredCategories(from: ordered)

        #expect(featured.count == 7)
        #expect(featured.last == pets)
        #expect(model.subcategory?.name == "Veteriner")
    }

    @Test func switchingKindClearsCategory() throws {
        let model = TransactionEditorModel()
        model.selectCategory(try category("Konut"))
        model.setKind(.income)

        #expect(model.category == nil)
        #expect(model.orderedCategories(from: try context.fetch(FetchDescriptor<PocketMoney.Category>()), recent: [])
            .allSatisfy { $0.kind == .income })
    }
}
