import SwiftUI

/// Kategori çipleri; ana kategori seçilince alt kategori çipleri kayarak gelir.
/// Alt kategoriler ayara gömülmez, giriş ekranında görünür (Bölüm 2, ilke 5).
struct EditorCategorySection: View {
    let model: TransactionEditorModel
    let categories: [Category]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Kategori")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, Spacing.screen)

            ChipSelector(
                items: categories,
                isSelected: { $0 == model.category },
                title: \.name,
                symbol: { $0.symbolName },
                onSelect: { category in
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
                        model.selectCategory(category)
                    }
                }
            )

            if !model.subcategories.isEmpty {
                ChipSelector(
                    items: model.subcategories,
                    isSelected: { $0 == model.subcategory },
                    title: \.name,
                    onSelect: { model.toggleSubcategory($0) }
                )
                .id(model.category?.id)
                .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
}
