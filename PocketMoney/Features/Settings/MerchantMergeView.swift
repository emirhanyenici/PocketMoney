import SwiftData
import SwiftUI

/// Birleştirilecek hedef markayı seçme (Bölüm 8). Seçimden sonra onay istenir;
/// işlem geri alınamaz ama hiçbir kayıt kaybolmaz.
struct MerchantMergeView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var merchants: [Merchant]

    let source: Merchant
    let transactionCount: Int
    let onMerge: (Merchant) -> Void

    @State private var search = ""
    @State private var pendingTarget: Merchant?

    private var candidates: [Merchant] {
        let key = SearchKey.make(from: search)
        return merchants
            .filter { $0 != source && (key.isEmpty || $0.searchKey.contains(key)) }
            .sorted { $0.name.compare($1.name, options: .caseInsensitive, locale: Decimal.turkishLocale) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List(candidates) { merchant in
                Button { pendingTarget = merchant } label: {
                    HStack(spacing: Spacing.s) {
                        MerchantAvatar(merchant: merchant, size: 32)
                        Text(verbatim: merchant.name).foregroundStyle(Color.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceElevated)
            .searchable(text: $search, prompt: "Marka ara")
            .navigationTitle(Text("“\(source.name)” şununla birleşsin"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", role: .cancel) { dismiss() }
                }
            }
            .confirmationDialog(
                "Birleştirilsin mi?",
                isPresented: Binding(get: { pendingTarget != nil }, set: { if !$0 { pendingTarget = nil } }),
                titleVisibility: .visible,
                presenting: pendingTarget
            ) { target in
                Button("“\(target.name)” ile birleştir", role: .destructive) { onMerge(target) }
                Button("Vazgeç", role: .cancel) {}
            } message: { target in
                Text("“\(source.name)” silinecek ve \(transactionCount) kaydı “\(target.name)” markasına taşınacak.")
            }
        }
        .tint(.brandPrimary)
    }
}
