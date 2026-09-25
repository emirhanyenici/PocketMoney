import SwiftData
import SwiftUI

/// Markalar (Bölüm 6.2-F, Bölüm 8): ara, ekle, gizle; dokununca düzenle / birleştir.
struct MerchantListView: View {
    @Environment(\.modelContext) private var context
    @Query private var merchants: [Merchant]

    @State private var search = ""
    @State private var showsNewMerchant = false
    @State private var nameDraft = ""
    @State private var errorMessage: String?

    private var repository: MerchantRepository { MerchantRepository(context: context) }

    /// Türkçe alfabe sırası ("Çiçeksepeti" C'den sonra gelir) ve karakter duyarsız arama.
    private var filtered: [Merchant] {
        let key = SearchKey.make(from: search)
        return merchants
            .filter { key.isEmpty || $0.searchKey.contains(key) }
            .sorted { $0.name.compare($1.name, options: .caseInsensitive, locale: Decimal.turkishLocale) == .orderedAscending }
    }

    var body: some View {
        let visible = filtered.filter { !$0.isHidden }
        let hidden = filtered.filter(\.isHidden)

        List {
            Section {
                ForEach(visible) { merchant in
                    row(merchant)
                        .swipeActions {
                            Button("Gizle", systemImage: "eye.slash") { perform { try repository.setHidden(merchant, true) } }
                                .tint(Color.textSecondary)
                        }
                }
            } footer: {
                Text("Gizlediğin markalar önerilerde çıkmaz, geçmiş kayıtlarda görünmeye devam eder.")
            }
            .listRowBackground(Color.surface)

            if !hidden.isEmpty {
                Section("Gizlenmiş") {
                    ForEach(hidden) { merchant in
                        row(merchant)
                            .swipeActions {
                                Button("Göster", systemImage: "eye") { perform { try repository.setHidden(merchant, false) } }
                                    .tint(Color.brandSecondary)
                            }
                    }
                }
                .listRowBackground(Color.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.background)
        .overlay {
            if filtered.isEmpty && !search.isEmpty {
                ContentUnavailableView.search(text: search)
            }
        }
        .searchable(text: $search, prompt: "Marka ara")
        .navigationTitle("Markalar")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Marka ekle", systemImage: "plus") {
                    nameDraft = search
                    showsNewMerchant = true
                }
            }
        }
        .alert("Marka ekle", isPresented: $showsNewMerchant) {
            TextField("Ad", text: $nameDraft)
            Button("Ekle") { perform { try repository.create(name: nameDraft) } }
            Button("Vazgeç", role: .cancel) {}
        }
        .alert("Olmadı", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(verbatim: errorMessage ?? "")
        }
    }

    private func row(_ merchant: Merchant) -> some View {
        NavigationLink { MerchantDetailView(merchant: merchant) } label: {
            HStack(spacing: Spacing.s) {
                MerchantAvatar(merchant: merchant, size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: merchant.name)
                        .foregroundStyle(merchant.isHidden ? Color.textSecondary : Color.textPrimary)
                    if let category = merchant.suggestedCategory {
                        Text(verbatim: category.name)
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
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

#if DEBUG
#Preview("Açık mod") {
    NavigationStack { MerchantListView() }
        .modelContainer(AppModelContainer.preview(withTransactions: false))
}

#Preview("Koyu mod") {
    NavigationStack { MerchantListView() }
        .modelContainer(AppModelContainer.preview(withTransactions: false))
        .preferredColorScheme(.dark)
}
#endif
