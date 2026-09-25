import Foundation
import SwiftData
import Testing
import UIKit
@testable import PocketMoney

/// Kategori yönetimi kuralları (Bölüm 7): hiçbir işlem sessizce kaybolmaz.
@MainActor
struct CategoryRepositoryTests {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }
    private var repository: CategoryRepository { CategoryRepository(context: context) }

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

    @discardableResult
    private func addTransaction(_ main: PocketMoney.Category, _ sub: PocketMoney.Category? = nil) -> Transaction {
        let transaction = Transaction(amount: 10, kind: main.kind, category: main, subcategory: sub)
        context.insert(transaction)
        return transaction
    }

    private func transactionCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<Transaction>())
    }

    // MARK: - Oluşturma ve düzenleme

    @Test func createsMainCategoryAtEnd() throws {
        let created = try repository.createMain(name: "  Hobi  ", symbolName: "paintbrush.fill", colorToken: "cat.coral", kind: .expense)
        #expect(created.name == "Hobi")
        #expect(try repository.mainCategories(kind: .expense).last == created)
    }

    @Test func rejectsEmptyAndDuplicateNames() throws {
        #expect(throws: CategoryRepository.CategoryError.emptyName) {
            try repository.createMain(name: "   ", symbolName: "tag.fill", colorToken: "cat.stone", kind: .expense)
        }
        // Türkçe karakter duyarsız: "konut" = "Konut".
        #expect(throws: CategoryRepository.CategoryError.duplicateName) {
            try repository.createMain(name: "konut", symbolName: "tag.fill", colorToken: "cat.stone", kind: .expense)
        }
        // Aynı ad farklı ana kategoride alt kategori olabilir ("Seyahat › Ulaşım").
        #expect(throws: Never.self) {
            try repository.createSubcategory(name: "Yakıt", parent: try category("Seyahat"))
        }
    }

    @Test func subcategoryInheritsLookAndFollowsParentChanges() throws {
        let parent = try category("Ev & Yaşam")
        let child = try repository.createSubcategory(name: "Bahçe", parent: parent)
        #expect(child.colorToken == parent.colorToken)

        try repository.update(parent, name: "Ev", symbolName: "leaf.fill", colorToken: "cat.mint")
        #expect(child.symbolName == "leaf.fill")
        #expect(child.colorToken == "cat.mint")
    }

    @Test func reorderWritesSortOrder() throws {
        var mains = try repository.mainCategories(kind: .expense)
        mains.append(mains.removeFirst())
        try repository.reorder(mains)
        #expect(try repository.mainCategories(kind: .expense).last?.name == "Konut")
    }

    // MARK: - Silme

    @Test func deleteWithoutTransactionsNeedsNoTarget() throws {
        let unused = try category("Evcil Hayvan")
        try repository.delete(unused, movingTransactionsTo: nil)
        #expect(try context.fetch(FetchDescriptor<PocketMoney.Category>()).allSatisfy { $0.name != "Evcil Hayvan" })
    }

    @Test func deleteWithTransactionsRequiresTarget() throws {
        addTransaction(try category("Konut"), try category("Konut", "Kira"))
        #expect(throws: CategoryRepository.CategoryError.moveTargetRequired) {
            try repository.delete(try category("Konut"), movingTransactionsTo: nil)
        }
    }

    /// Ana kategori silinince işlemler (alt kategorilerindekiler dahil) hedefe taşınır.
    @Test func deletingMainMovesAllTransactions() throws {
        let housing = try category("Konut")
        addTransaction(housing, try category("Konut", "Kira"))
        addTransaction(housing)
        let before = try transactionCount()
        let target = try category("Faturalar & İletişim", "TV paketi")

        try repository.delete(housing, movingTransactionsTo: target)

        let moved = try context.fetch(FetchDescriptor<Transaction>())
        #expect(try transactionCount() == before)
        #expect(moved.allSatisfy { $0.category?.name == "Faturalar & İletişim" && $0.subcategory == target })
    }

    /// Alt kategori silinirken hedef ana kategorisinin kendisi olabilir ("alt kategorisiz").
    @Test func deletingSubcategoryCanMoveToParent() throws {
        let food = try category("Yeme & İçme")
        let coffee = try category("Yeme & İçme", "Kahve & Kafe")
        let transaction = addTransaction(food, coffee)

        try repository.delete(coffee, movingTransactionsTo: food)

        #expect(transaction.category == food)
        #expect(transaction.subcategory == nil)
        #expect(try transactionCount() == 1)
    }

    @Test func rejectsInvalidTargets() throws {
        let housing = try category("Konut")
        addTransaction(housing)
        #expect(throws: CategoryRepository.CategoryError.invalidMoveTarget) {
            try repository.delete(housing, movingTransactionsTo: try category("Konut", "Kira"))
        }
        #expect(throws: CategoryRepository.CategoryError.kindMismatch) {
            try repository.delete(housing, movingTransactionsTo: try category("Maaş"))
        }
    }

    @Test func deleteMovesMerchantSuggestions() throws {
        let shell = try #require(try context.fetch(FetchDescriptor<Merchant>()).first { $0.name == "Shell" })
        let target = try category("Seyahat", "Ulaşım")
        try repository.delete(try category("Ulaşım"), movingTransactionsTo: target)
        #expect(shell.suggestedCategory == target)
    }

    @Test func archivedCategoryIsNotSuggestedButKeepsHistory() throws {
        let housing = try category("Konut")
        let transaction = addTransaction(housing)
        try repository.setArchived(housing, true)

        let editor = TransactionEditorModel()
        let offered = editor.orderedCategories(from: try context.fetch(FetchDescriptor<PocketMoney.Category>()), recent: [])
        #expect(!offered.contains(housing))
        #expect(transaction.category == housing)
    }

    @Test func everyOfferedSymbolExists() {
        let missing = CategorySymbols.all.filter { UIImage(systemName: $0) == nil }
        #expect(missing.isEmpty)
    }
}
