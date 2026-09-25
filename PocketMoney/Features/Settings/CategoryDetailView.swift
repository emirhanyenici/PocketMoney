import SwiftData
import SwiftUI

/// Bir ana kategorinin ayrıntısı: görünüm, alt kategoriler, arşivle / sil (Bölüm 7).
struct CategoryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let category: Category

    @State private var showsEditForm = false
    @State private var deletionTarget: Category?
    @State private var showsNewSubcategory = false
    @State private var renameTarget: Category?
    @State private var nameDraft = ""
    @State private var errorMessage: String?

    private var repository: CategoryRepository { CategoryRepository(context: context) }
    private var children: [Category] { category.children.sorted { $0.sortOrder < $1.sortOrder } }

    var body: some View {
        // Silindikten sonra geri dönüş animasyonu sırasında model erişimi çökmemeli.
        if category.isDeleted || category.modelContext == nil {
            Color.background
        } else {
            content
        }
    }

    private var content: some View {
        List {
            Section {
                Button { showsEditForm = true } label: {
                    HStack(spacing: Spacing.s) {
                        CategoryIcon(category: category, size: 44)
                        Text(verbatim: category.name)
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Text("Düzenle")
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }
            .listRowBackground(Color.surface)

            Section {
                ForEach(children.filter { !$0.isArchived }) { child in
                    subcategoryRow(child)
                }
                Button("Alt kategori ekle", systemImage: "plus") {
                    nameDraft = ""
                    showsNewSubcategory = true
                }
            } header: {
                Text("Alt kategoriler")
            } footer: {
                Text("Adını değiştirmek için dokun, arşivlemek ya da silmek için sola kaydır.")
            }
            .listRowBackground(Color.surface)

            let archivedChildren = children.filter(\.isArchived)
            if !archivedChildren.isEmpty {
                Section("Arşivlenmiş alt kategoriler") {
                    ForEach(archivedChildren) { child in
                        Text(verbatim: child.name)
                            .foregroundStyle(Color.textSecondary)
                            .swipeActions {
                                Button("Arşivden çıkar", systemImage: "tray.and.arrow.up") { perform { try repository.setArchived(child, false) } }
                                    .tint(Color.brandSecondary)
                            }
                    }
                }
                .listRowBackground(Color.surface)
            }

            Section {
                Button(category.isArchived ? "Arşivden çıkar" : "Arşivle",
                       systemImage: category.isArchived ? "tray.and.arrow.up" : "archivebox") {
                    perform { try repository.setArchived(category, !category.isArchived) }
                }
                Button("Kategoriyi sil", systemImage: "trash", role: .destructive) { deletionTarget = category }
            } footer: {
                Text("Arşivlemek kayıtlarına dokunmaz; kategori yalnızca yeni kayıtta önerilmez. Silerken kayıtların başka bir kategoriye taşınır.")
            }
            .listRowBackground(Color.surface)
        }
        .scrollContentBackground(.hidden)
        .background(Color.background)
        .navigationTitle(Text(verbatim: category.name))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsEditForm) {
            CategoryFormView(kind: category.kind, category: category)
        }
        .sheet(item: $deletionTarget) { target in
            CategoryDeleteView(category: target) {
                // Ana kategori silindiyse listeye dön.
                if target == category { dismiss() }
            }
        }
        .alert("Alt kategori ekle", isPresented: $showsNewSubcategory) {
            TextField("Ad", text: $nameDraft)
            Button("Ekle") { perform { try repository.createSubcategory(name: nameDraft, parent: category) } }
            Button("Vazgeç", role: .cancel) {}
        }
        .alert("Yeniden adlandır", isPresented: Binding(get: { renameTarget != nil }, set: { if !$0 { renameTarget = nil } })) {
            TextField("Ad", text: $nameDraft)
            Button("Kaydet") {
                if let renameTarget { perform { try repository.rename(renameTarget, to: nameDraft) } }
            }
            Button("Vazgeç", role: .cancel) {}
        }
        .alert("Olmadı", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(verbatim: errorMessage ?? "")
        }
    }

    private func subcategoryRow(_ child: Category) -> some View {
        Button {
            nameDraft = child.name
            renameTarget = child
        } label: {
            Text(verbatim: child.name)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .swipeActions {
            Button("Sil", systemImage: "trash", role: .destructive) { deletionTarget = child }
            Button("Arşivle", systemImage: "archivebox") { perform { try repository.setArchived(child, true) } }
                .tint(Color.warning)
        }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            errorMessage = ManagementErrorMessage.text(for: error)
        }
    }
}
