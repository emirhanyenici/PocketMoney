import SwiftUI

/// Kategori seçim listeleri için sıralı düz liste: ana kategori, hemen altında
/// alt kategorileri. Arşivlenenler ve hariç tutulan kategori (ile alt kategorileri) çıkarılır.
enum CategoryOptions {
    static func flatList(from all: [Category], kind: TransactionKind, excluding: Category? = nil) -> [Category] {
        func isExcluded(_ category: Category) -> Bool {
            guard let excluding else { return false }
            return category == excluding || category.parent == excluding
        }
        return all
            .filter { $0.parent == nil && $0.kind == kind && !$0.isArchived && !isExcluded($0) }
            .sorted { $0.sortOrder < $1.sortOrder }
            .flatMap { main in
                [main] + main.children
                    .filter { !$0.isArchived && !isExcluded($0) }
                    .sorted { $0.sortOrder < $1.sortOrder }
            }
    }
}

/// Seçim listesinde bir kategori satırı; alt kategoriler girintili.
struct CategoryOptionLabel: View {
    let category: Category

    var body: some View {
        HStack(spacing: Spacing.s) {
            CategoryIcon(category: category.parent ?? category, size: category.parent == nil ? 28 : 22)
            Text(verbatim: category.name)
                .font(category.parent == nil ? .body.weight(.semibold) : .body)
        }
        .padding(.leading, category.parent == nil ? 0 : Spacing.xl)
    }
}
