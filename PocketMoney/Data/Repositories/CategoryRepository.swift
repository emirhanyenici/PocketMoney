import Foundation
import SwiftData

/// Kategori yönetimi (Bölüm 6.2-F, Bölüm 7).
///
/// Temel kural: hiçbir işlem sessizce kaybolmaz. Arşivleme varsayılandır;
/// işlemi olan bir kategori ancak işlemler başka bir kategoriye taşınarak silinir.
struct CategoryRepository {
    enum CategoryError: Error, Equatable {
        case emptyName
        case duplicateName
        /// İşlemi olan kategori silinirken hedef seçilmedi.
        case moveTargetRequired
        /// Hedef, silinen kategori veya onun alt kategorisi.
        case invalidMoveTarget
        /// Gider kategorisinin işlemleri gelir kategorisine taşınamaz.
        case kindMismatch
    }

    let context: ModelContext

    // MARK: - Okuma

    func mainCategories(kind: TransactionKind) throws -> [Category] {
        try context.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)]))
            .filter { $0.parent == nil && $0.kind == kind }
    }

    /// Kategoriye (veya alt kategorilerine) bağlı işlem sayısı.
    func transactionCount(for category: Category) throws -> Int {
        let ids = Self.subtreeIDs(of: category)
        return try context.fetch(FetchDescriptor<Transaction>()).count { transaction in
            Self.contains(ids, transaction.category) || Self.contains(ids, transaction.subcategory)
        }
    }

    /// Aynı düzeyde (ana kategoriler arasında ya da aynı ana kategorinin alt
    /// kategorileri arasında) Türkçe karakter duyarsız aynı ad var mı.
    func isNameTaken(_ name: String, kind: TransactionKind, parent: Category?, excluding: Category? = nil) throws -> Bool {
        let key = SearchKey.make(from: name)
        let siblings = if let parent {
            parent.children
        } else {
            try mainCategories(kind: kind)
        }
        return siblings.contains { $0 != excluding && SearchKey.make(from: $0.name) == key }
    }

    // MARK: - Oluşturma ve düzenleme

    @discardableResult
    func createMain(name: String, symbolName: String, colorToken: String, kind: TransactionKind) throws -> Category {
        let trimmed = try validatedName(name, kind: kind, parent: nil)
        let order = (try mainCategories(kind: kind).map(\.sortOrder).max() ?? -1) + 1
        let category = Category(name: trimmed, symbolName: symbolName, colorToken: colorToken, kind: kind, sortOrder: order)
        context.insert(category)
        try context.saveOrRollback()
        return category
    }

    /// Alt kategori ana kategorinin ikonunu ve rengini paylaşır (Bölüm 3, ilke 4).
    @discardableResult
    func createSubcategory(name: String, parent: Category) throws -> Category {
        let trimmed = try validatedName(name, kind: parent.kind, parent: parent)
        let order = (parent.children.map(\.sortOrder).max() ?? -1) + 1
        let child = Category(
            name: trimmed,
            symbolName: parent.symbolName,
            colorToken: parent.colorToken,
            kind: parent.kind,
            sortOrder: order,
            parent: parent
        )
        context.insert(child)
        try context.saveOrRollback()
        return child
    }

    /// Ana kategorinin ikonu/rengi değişince alt kategoriler de aynı görünümü alır.
    func update(_ category: Category, name: String, symbolName: String, colorToken: String) throws {
        category.name = try validatedName(name, kind: category.kind, parent: category.parent, excluding: category)
        category.symbolName = symbolName
        category.colorToken = colorToken
        for child in category.children {
            child.symbolName = symbolName
            child.colorToken = colorToken
        }
        try context.saveOrRollback()
    }

    func rename(_ category: Category, to name: String) throws {
        category.name = try validatedName(name, kind: category.kind, parent: category.parent, excluding: category)
        try context.saveOrRollback()
    }

    /// Arşivlenen kategori geçmiş işlemlerde görünmeye devam eder, yeni girişte önerilmez.
    func setArchived(_ category: Category, _ archived: Bool) throws {
        category.isArchived = archived
        try context.saveOrRollback()
    }

    /// Verilen sıraya göre `sortOrder` yazar.
    func reorder(_ categories: [Category]) throws {
        for (index, category) in categories.enumerated() {
            category.sortOrder = index
        }
        try context.saveOrRollback()
    }

    // MARK: - Silme

    /// Kategoriyi (ve alt kategorilerini) siler. İşlemi varsa `target` zorunludur;
    /// işlemler, düzenli ödemeler ve marka önerileri hedefe taşınır.
    /// Hedef bir alt kategoriyse işlemler onun ana kategorisi + kendisine gider.
    func delete(_ category: Category, movingTransactionsTo target: Category?) throws {
        let deleted = Self.subtreeIDs(of: category)
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
            .filter { Self.contains(deleted, $0.category) || Self.contains(deleted, $0.subcategory) }

        if let target {
            guard !Self.contains(deleted, target) else { throw CategoryError.invalidMoveTarget }
            guard target.kind == category.kind else { throw CategoryError.kindMismatch }
        } else if !transactions.isEmpty {
            throw CategoryError.moveTargetRequired
        }

        let newMain = target?.parent ?? target
        let newSub = target?.parent == nil ? nil : target

        for transaction in transactions {
            reassign(&transaction.category, &transaction.subcategory, deleted: deleted, newMain: newMain, newSub: newSub)
            transaction.updatedAt = .now
        }
        for payment in try context.fetch(FetchDescriptor<RecurringPayment>()) {
            reassign(&payment.category, &payment.subcategory, deleted: deleted, newMain: newMain, newSub: newSub)
        }
        for merchant in try context.fetch(FetchDescriptor<Merchant>()) {
            if Self.contains(deleted, merchant.suggestedCategory) { merchant.suggestedCategory = target }
            reassign(&merchant.lastUsedCategory, &merchant.lastUsedSubcategory, deleted: deleted, newMain: newMain, newSub: newSub)
        }
        // Silinen kategorinin bütçesi anlamsızdır (Bölüm 10; bütçeler v0.3'te).
        for budget in try context.fetch(FetchDescriptor<Budget>()) where Self.contains(deleted, budget.category) {
            context.delete(budget)
        }

        context.delete(category)
        try context.saveOrRollback()
    }

    /// Ana/alt kategori çiftini silinen kategoriden hedefe çevirir. Yalnızca alt
    /// kategori siliniyorsa ve hedef yoksa ana kategori korunur.
    private func reassign(
        _ main: inout Category?,
        _ sub: inout Category?,
        deleted: Set<PersistentIdentifier>,
        newMain: Category?,
        newSub: Category?
    ) {
        if Self.contains(deleted, main) {
            main = newMain
            sub = newSub
        } else if Self.contains(deleted, sub) {
            if let newMain {
                main = newMain
                sub = newSub
            } else {
                sub = nil
            }
        }
    }

    // MARK: - Yardımcılar

    private func validatedName(
        _ name: String,
        kind: TransactionKind,
        parent: Category?,
        excluding: Category? = nil
    ) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CategoryError.emptyName }
        guard try !isNameTaken(trimmed, kind: kind, parent: parent, excluding: excluding) else {
            throw CategoryError.duplicateName
        }
        return trimmed
    }

    private static func subtreeIDs(of category: Category) -> Set<PersistentIdentifier> {
        Set([category.persistentModelID] + category.children.map(\.persistentModelID))
    }

    private static func contains(_ ids: Set<PersistentIdentifier>, _ category: Category?) -> Bool {
        category.map { ids.contains($0.persistentModelID) } ?? false
    }
}
