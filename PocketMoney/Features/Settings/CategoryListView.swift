import SwiftData
import SwiftUI

/// Kategoriler (Bölüm 6.2-F): ekle, sırala, arşivlenenleri gör.
struct CategoryListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var kind: TransactionKind = .expense
    @State private var showsNewCategory = false
    @State private var errorMessage: String?

    private var mains: [Category] { categories.filter { $0.parent == nil && $0.kind == kind } }
    private var active: [Category] { mains.filter { !$0.isArchived } }
    private var archived: [Category] { mains.filter(\.isArchived) }

    var body: some View {
        List {
            Section {
                Picker("Tür", selection: $kind) {
                    Text("Gider").tag(TransactionKind.expense)
                    Text("Gelir").tag(TransactionKind.income)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                ForEach(active) { category in
                    NavigationLink { CategoryDetailView(category: category) } label: {
                        CategoryListRow(category: category)
                    }
                }
                .onMove(perform: move)
            } footer: {
                Text("Sırayı değiştirmek için Düzenle'ye dokun. Kayıt ekranında sık kullandıkların yine önde gelir.")
            }
            .listRowBackground(Color.surface)

            if !archived.isEmpty {
                Section {
                    ForEach(archived) { category in
                        NavigationLink { CategoryDetailView(category: category) } label: {
                            CategoryListRow(category: category)
                        }
                    }
                } header: {
                    Text("Arşivlenmiş")
                } footer: {
                    Text("Arşivlenen kategoriler geçmiş kayıtlarda görünür, yeni kayıtta önerilmez.")
                }
                .listRowBackground(Color.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.background)
        .navigationTitle("Kategoriler")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Kategori ekle", systemImage: "plus") { showsNewCategory = true }
            }
        }
        .sheet(isPresented: $showsNewCategory) {
            CategoryFormView(kind: kind)
        }
        .alert("Sıralama kaydedilemedi", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(verbatim: errorMessage ?? "")
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = active
        reordered.move(fromOffsets: source, toOffset: destination)
        do {
            try CategoryRepository(context: context).reorder(reordered + archived)
        } catch {
            errorMessage = ManagementErrorMessage.text(for: error)
        }
    }
}

private struct CategoryListRow: View {
    let category: Category

    var body: some View {
        HStack(spacing: Spacing.s) {
            CategoryIcon(category: category, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: category.name)
                    .foregroundStyle(Color.textPrimary)
                let count = category.children.filter { !$0.isArchived }.count
                if count > 0 {
                    Text("\(count) alt kategori")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Açık mod") {
    NavigationStack { CategoryListView() }
        .modelContainer(AppModelContainer.preview(withTransactions: false))
}

#Preview("Koyu mod") {
    NavigationStack { CategoryListView() }
        .modelContainer(AppModelContainer.preview(withTransactions: false))
        .preferredColorScheme(.dark)
}
#endif
