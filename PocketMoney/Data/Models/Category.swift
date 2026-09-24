import Foundation
import SwiftData

extension SchemaV1 {
    /// Ana kategori (`parent == nil`) veya alt kategori (Bölüm 7, Bölüm 12).
    @Model
    final class Category {
        @Attribute(.unique) var id: UUID
        var name: String
        /// SF Symbol adı.
        var symbolName: String
        /// `CategoryColor` ham değeri, ör. "cat.forest".
        var colorToken: String
        var kindRaw: String
        var sortOrder: Int
        /// Arşivlenen kategori geçmişte görünür, yeni girişte önerilmez (Bölüm 7).
        var isArchived: Bool
        /// Seed ile mi geldi.
        var isSystem: Bool
        var parent: Category?
        @Relationship(deleteRule: .cascade, inverse: \Category.parent)
        var children: [Category]

        var kind: TransactionKind {
            get { TransactionKind(rawValue: kindRaw) ?? .expense }
            set { kindRaw = newValue.rawValue }
        }

        init(
            name: String,
            symbolName: String,
            colorToken: String,
            kind: TransactionKind,
            sortOrder: Int,
            isSystem: Bool = false,
            parent: Category? = nil
        ) {
            self.id = UUID()
            self.name = name
            self.symbolName = symbolName
            self.colorToken = colorToken
            self.kindRaw = kind.rawValue
            self.sortOrder = sortOrder
            self.isArchived = false
            self.isSystem = isSystem
            self.parent = parent
            self.children = []
        }
    }
}
