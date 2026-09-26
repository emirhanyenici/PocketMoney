import SwiftUI

/// Kategori seçimi (Bölüm 6.2-B, Bölüm 22 karar kaydı): en sık kullanılan
/// kategoriler aşağı doğru dizilen ızgarada, sonda "Tümü" tam listeyi açar.
/// Ana kategori seçilince alt kategoriler sarılan çiplerle altında görünür;
/// alt kategoriler ayara gömülmez (Bölüm 2, ilke 5).
struct EditorCategorySection: View {
    let model: TransactionEditorModel
    /// Sık kullanılanlar önde, türe göre filtrelenmiş ana kategoriler.
    let categories: [Category]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsAllCategories = false

    private let columns = [GridItem(.adaptive(minimum: 78), spacing: Spacing.xs)]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Kategori")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textSecondary)

            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(model.featuredCategories(from: categories)) { category in
                    CategoryTile(
                        title: category.name,
                        symbolName: category.symbolName,
                        colorToken: category.colorToken,
                        isSelected: category == model.category
                    ) {
                        withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
                            model.selectCategory(category)
                        }
                    }
                }
                CategoryTile(
                    title: String(localized: "Tümü"),
                    symbolName: "square.grid.2x2",
                    colorToken: nil,
                    isSelected: false
                ) {
                    showsAllCategories = true
                }
                .accessibilityLabel("Tüm kategoriler")
            }

            if !model.subcategories.isEmpty {
                FlowLayout {
                    ForEach(model.subcategories) { subcategory in
                        Chip(title: subcategory.name, isSelected: subcategory == model.subcategory) {
                            model.toggleSubcategory(subcategory)
                        }
                    }
                }
                .id(model.category?.id)
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, Spacing.screen)
        .sheet(isPresented: $showsAllCategories) {
            CategoryPickerSheet(
                categories: categories,
                selectedCategory: model.category,
                selectedSubcategory: model.subcategory
            ) { category, subcategory in
                withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
                    model.select(category: category, subcategory: subcategory)
                }
            }
        }
    }
}
