import Foundation
import SwiftData

/// İlk açılışta `Data/Seed/*.json` dosyalarından varsayılan kategorileri,
/// markaları ve ödeme yöntemlerini yükler (Bölüm 7, Bölüm 8).
///
/// Yalnızca veritabanında hiç kategori yokken çalışır; kullanıcı seed
/// kayıtlarını düzenledikten sonra uygulamayı tekrar açtığında hiçbir şey
/// yeniden eklenmez veya ezilmez.
struct SeedLoader {
    enum SeedError: Error, Equatable {
        case missingResource(String)
        case unknownCategory(merchant: String, category: String, subcategory: String?)
        case unknownValue(field: String, value: String)
    }

    let context: ModelContext
    var bundle: Bundle = .main

    func seedIfNeeded() throws {
        guard try context.fetchCount(FetchDescriptor<Category>()) == 0 else { return }

        let categories = try seedCategories()
        try seedMerchants(categories: categories)
        try seedPaymentMethods()
        try context.save()
    }

    // MARK: - Kategoriler

    /// Ana kategori adı → (kategori, alt kategori adı → alt kategori).
    /// Alt kategori adları farklı ana kategorilerde tekrar edebildiği için
    /// ("Seyahat › Ulaşım") eşleme her zaman ana kategori üzerinden yapılır.
    private typealias CategoryIndex = [String: (category: Category, children: [String: Category])]

    private func seedCategories() throws -> CategoryIndex {
        var index: CategoryIndex = [:]
        for (order, seed) in try decode([CategorySeed].self, from: "categories").enumerated() {
            guard let kind = TransactionKind(rawValue: seed.kind) else {
                throw SeedError.unknownValue(field: "kind", value: seed.kind)
            }
            let parent = Category(
                name: seed.name,
                symbolName: seed.symbol,
                colorToken: seed.color,
                kind: kind,
                sortOrder: order,
                isSystem: true
            )
            context.insert(parent)

            var children: [String: Category] = [:]
            for (childOrder, childName) in seed.children.enumerated() {
                // Alt kategori, ana kategorinin ikonunu ve rengini paylaşır (Bölüm 3, ilke 4).
                let child = Category(
                    name: childName,
                    symbolName: seed.symbol,
                    colorToken: seed.color,
                    kind: kind,
                    sortOrder: childOrder,
                    isSystem: true,
                    parent: parent
                )
                context.insert(child)
                children[childName] = child
            }
            index[seed.name] = (parent, children)
        }
        return index
    }

    // MARK: - Markalar

    private func seedMerchants(categories: CategoryIndex) throws {
        for seed in try decode([MerchantSeed].self, from: "merchants") {
            let merchant = Merchant(
                name: seed.name,
                suggestedCategory: try suggestedCategory(for: seed, in: categories),
                isSystem: true
            )
            if let channel = seed.channel {
                // Bölüm 8: online işlemde önce online kanalı olan markalar önerilir.
                // Modelde ayrı alan olmadığı için seed, kanalı "son kullanılan" olarak
                // başlatır; kullanıcının ilk seçimi bunu doğal olarak ezer.
                guard let value = PurchaseChannel(rawValue: channel) else {
                    throw SeedError.unknownValue(field: "channel", value: channel)
                }
                merchant.lastUsedChannel = value
            }
            context.insert(merchant)
        }
    }

    /// Alt kategori belirtilmişse onu, yoksa ana kategoriyi döner.
    /// Pazaryeri gibi kategorisi belirsiz markalar için `nil` geçerlidir.
    private func suggestedCategory(for seed: MerchantSeed, in categories: CategoryIndex) throws -> Category? {
        guard let categoryName = seed.category else { return nil }
        guard let entry = categories[categoryName] else {
            throw SeedError.unknownCategory(merchant: seed.name, category: categoryName, subcategory: seed.subcategory)
        }
        guard let subcategoryName = seed.subcategory else { return entry.category }
        guard let child = entry.children[subcategoryName] else {
            throw SeedError.unknownCategory(merchant: seed.name, category: categoryName, subcategory: subcategoryName)
        }
        return child
    }

    // MARK: - Ödeme yöntemleri

    private func seedPaymentMethods() throws {
        for (order, seed) in try decode([PaymentMethodSeed].self, from: "paymentMethods").enumerated() {
            guard let type = PaymentMethodType(rawValue: seed.type) else {
                throw SeedError.unknownValue(field: "type", value: seed.type)
            }
            context.insert(PaymentMethod(name: seed.name, type: type, sortOrder: order))
        }
    }

    // MARK: - JSON

    private func decode<T: Decodable>(_ type: T.Type, from resource: String) throws -> T {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw SeedError.missingResource("\(resource).json")
        }
        return try JSONDecoder().decode(type, from: Data(contentsOf: url))
    }
}

// MARK: - Seed dosya biçimleri

nonisolated private struct CategorySeed: Decodable {
    let name: String
    let symbol: String
    let color: String
    let kind: String
    let children: [String]
}

nonisolated private struct MerchantSeed: Decodable {
    let name: String
    let category: String?
    let subcategory: String?
    let channel: String?
}

nonisolated private struct PaymentMethodSeed: Decodable {
    let name: String
    let type: String
}
