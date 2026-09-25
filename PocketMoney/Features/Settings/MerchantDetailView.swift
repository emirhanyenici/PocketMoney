import SwiftData
import SwiftUI

/// Bir markanın ayarları: ad, önerilen kategori, gizle, birleştir (Bölüm 8).
struct MerchantDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    let merchant: Merchant

    @State private var name = ""
    @State private var transactionCount = 0
    @State private var showsMerge = false
    @State private var errorMessage: String?

    private var repository: MerchantRepository { MerchantRepository(context: context) }

    var body: some View {
        // Birleştirmeden sonra geri dönüş sırasında silinmiş modele erişilmemeli.
        if merchant.isDeleted || merchant.modelContext == nil {
            Color.background
        } else {
            form
        }
    }

    private var form: some View {
        Form {
            Section {
                HStack(spacing: Spacing.s) {
                    MerchantAvatar(merchant: merchant, size: 44)
                    TextField("Marka adı", text: $name)
                        .font(.body.weight(.semibold))
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(saveName)
                }
            } footer: {
                Text("\(transactionCount) kayıtta kullanıldı.")
            }
            .listRowBackground(Color.surface)

            Section {
                Picker("Önerilen kategori", selection: suggestedCategory) {
                    Text("Yok").tag(Category?.none)
                    ForEach(CategoryOptions.flatList(from: categories, kind: .expense)) { option in
                        CategoryOptionLabel(category: option).tag(Optional(option))
                    }
                }
                .pickerStyle(.navigationLink)
            } footer: {
                Text("Bu markayı seçtiğinde önerilir. Kayıt sırasında kendi seçtiğin kategori her zaman önceliklidir.")
            }
            .listRowBackground(Color.surface)

            Section {
                Toggle("Önerilerde gizle", isOn: hidden)
                Button("Başka bir markayla birleştir", systemImage: "arrow.triangle.merge") { showsMerge = true }
            } footer: {
                Text("Aynı marka yanlışlıkla iki kez eklendiyse birleştir; bu markanın kayıtları seçtiğin markaya taşınır.")
            }
            .listRowBackground(Color.surface)
        }
        .scrollContentBackground(.hidden)
        .background(Color.background)
        .navigationTitle(Text(verbatim: merchant.name))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = merchant.name
            transactionCount = (try? repository.transactionCount(for: merchant)) ?? 0
        }
        // Ad, alan bırakılınca da kaydedilir.
        .onDisappear(perform: saveName)
        .sheet(isPresented: $showsMerge) {
            MerchantMergeView(source: merchant, transactionCount: transactionCount) { target in
                showsMerge = false
                dismiss()
                perform { try repository.merge(merchant, into: target) }
            }
        }
        .alert("Olmadı", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(verbatim: errorMessage ?? "")
        }
    }

    private var suggestedCategory: Binding<Category?> {
        Binding(
            get: { merchant.suggestedCategory },
            set: { newValue in perform { try repository.setSuggestedCategory(merchant, newValue) } }
        )
    }

    private var hidden: Binding<Bool> {
        Binding(
            get: { merchant.isHidden },
            set: { newValue in perform { try repository.setHidden(merchant, newValue) } }
        )
    }

    private func saveName() {
        guard !merchant.isDeleted, merchant.modelContext != nil, name != merchant.name else { return }
        do {
            try repository.rename(merchant, to: name)
        } catch {
            errorMessage = ManagementErrorMessage.text(for: error)
            name = merchant.name
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
