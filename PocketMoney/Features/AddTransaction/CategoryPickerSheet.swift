import SwiftUI

/// Tüm kategoriler ve alt kategorileri, aranabilir liste (Bölüm 22 karar kaydı).
/// Ana kategoriye dokunmak onu, alt kategoriye dokunmak ikisini birden seçer.
struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let categories: [Category]
    let selectedCategory: Category?
    let selectedSubcategory: Category?
    let onPick: (Category, Category?) -> Void

    @State private var search = ""

    /// Arama ana kategori adına uyarsa tüm alt kategorileri, yalnızca bazı alt
    /// kategorilere uyarsa sadece onları gösterir (Türkçe karakter duyarsız).
    private var sections: [(main: Category, children: [Category])] {
        let key = SearchKey.make(from: search)
        return categories.compactMap { main in
            let children = main.children
                .filter { !$0.isArchived }
                .sorted { $0.sortOrder < $1.sortOrder }
            guard !key.isEmpty else { return (main, children) }
            if SearchKey.make(from: main.name).contains(key) { return (main, children) }
            let matches = children.filter { SearchKey.make(from: $0.name).contains(key) }
            return matches.isEmpty ? nil : (main, matches)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sections, id: \.main.id) { section in
                    Section {
                        row(section.main, subcategory: nil)
                        ForEach(section.children) { child in
                            row(section.main, subcategory: child)
                        }
                    }
                    .listRowBackground(Color.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceElevated)
            .overlay {
                if sections.isEmpty { ContentUnavailableView.search(text: search) }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Kategori ara")
            .navigationTitle("Kategori seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", role: .cancel) { dismiss() }
                }
            }
        }
        .tint(.brandPrimary)
    }

    private func row(_ main: Category, subcategory: Category?) -> some View {
        let isSelected = main == selectedCategory && subcategory == selectedSubcategory
        return Button {
            onPick(main, subcategory)
            dismiss()
        } label: {
            HStack(spacing: Spacing.s) {
                if let subcategory {
                    Text(verbatim: subcategory.name)
                        .foregroundStyle(Color.textPrimary)
                        .padding(.leading, 32 + Spacing.s)
                } else {
                    CategoryIcon(category: main, size: 32)
                    Text(verbatim: main.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
