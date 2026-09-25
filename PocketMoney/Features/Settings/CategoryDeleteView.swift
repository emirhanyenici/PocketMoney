import SwiftData
import SwiftUI

/// Kategori silme (Bölüm 7): kategoride kayıt varsa nereye taşınacağı seçilmeden
/// silinemez. Hiçbir kayıt sessizce kaybolmaz.
struct CategoryDeleteView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    let category: Category
    let onDeleted: () -> Void

    @State private var target: Category?
    @State private var transactionCount = 0
    @State private var errorMessage: String?

    private var options: [Category] {
        CategoryOptions.flatList(from: categories, kind: category.kind, excluding: category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if transactionCount == 0 {
                        Text("“\(category.name)” kategorisinde kayıt yok. Silinince geri alınamaz.")
                    } else {
                        Text("“\(category.name)” kategorisinde \(transactionCount) kayıt var. Hiçbiri silinmez; önce nereye taşınacaklarını seç.")
                    }
                }
                .listRowBackground(Color.surface)

                if transactionCount > 0 {
                    Section("Kayıtları şuraya taşı") {
                        Picker("Hedef kategori", selection: $target) {
                            ForEach(options) { option in
                                CategoryOptionLabel(category: option).tag(Optional(option))
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                    .listRowBackground(Color.surface)
                }

                if let errorMessage {
                    Section {
                        Text(verbatim: errorMessage).foregroundStyle(Color.over)
                    }
                    .listRowBackground(Color.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceElevated)
            .navigationTitle("Kategoriyi sil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Sil", role: .destructive, action: delete)
                        .disabled(transactionCount > 0 && target == nil)
                }
            }
            .task {
                transactionCount = (try? CategoryRepository(context: context).transactionCount(for: category)) ?? 0
                // Alt kategori siliniyorsa en doğal hedef kendi ana kategorisidir.
                if target == nil, let parent = category.parent { target = parent }
            }
        }
        .tint(.brandPrimary)
    }

    private func delete() {
        do {
            try CategoryRepository(context: context).delete(category, movingTransactionsTo: target)
            dismiss()
            onDeleted()
        } catch {
            errorMessage = ManagementErrorMessage.text(for: error)
        }
    }
}
