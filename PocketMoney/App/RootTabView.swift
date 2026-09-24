import OSLog
import SwiftData
import SwiftUI

/// Uygulamanın kökü (Bölüm 6.1): `[ Özet ] [ İşlemler ] ( + )`.
/// "+" her sekmeden erişilebilir ve içeriği kapatmaz.
struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selection: AppTab = .overview
    @State private var editor: EditorPresentation?
    @State private var toast: Toast?
    @State private var savedCount = 0
    @State private var deletedCount = 0

    private let logger = Logger(subsystem: "PocketMoney", category: "Transactions")

    var body: some View {
        TabView(selection: $selection) {
            Tab("Özet", systemImage: "chart.pie.fill", value: AppTab.overview) {
                OverviewView(
                    onAdd: { editor = .new },
                    onEdit: { editor = .edit($0) },
                    onShowAll: { selection = .transactions }
                )
            }
            Tab("İşlemler", systemImage: "list.bullet", value: AppTab.transactions) {
                TransactionsView(
                    onAdd: { editor = .new },
                    onEdit: { editor = .edit($0) },
                    onDelete: delete,
                    onCopy: duplicate
                )
            }
            Tab("Harcama ekle", systemImage: "plus.circle.fill", value: AppTab.add) {
                Color.clear
            }
        }
        .tint(.brandPrimary)
        .onChange(of: selection) { previous, current in
            // "+" bir sekme değil, eylemdir: sheet'i aç ve önceki sekmede kal.
            if current == .add {
                selection = previous
                editor = .new
            }
        }
        .sheet(item: $editor) { presentation in
            TransactionEditorView(transaction: presentation.transaction) {
                savedCount += 1
                show(Toast(message: String(localized: "Kaydedildi")))
            }
        }
        .overlay(alignment: .bottom) { toastOverlay }
        .sensoryFeedback(.success, trigger: savedCount)
        .sensoryFeedback(.warning, trigger: deletedCount)
    }

    // MARK: - Bildirim

    @ViewBuilder
    private var toastOverlay: some View {
        if let toast {
            ToastView(toast: toast) { self.toast = nil }
                .padding(.bottom, 72)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .task(id: toast.id) {
                    try? await Task.sleep(for: toast.duration)
                    if self.toast?.id == toast.id { hideToast() }
                }
        }
    }

    private func show(_ newToast: Toast) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) { toast = newToast }
    }

    private func hideToast() {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.3)) { toast = nil }
    }

    // MARK: - Eylemler

    /// Silme: `.warning` haptiği + 5 sn geri al (Bölüm 5.4).
    private func delete(_ transaction: Transaction) {
        let repository = TransactionRepository(context: context)
        do {
            let snapshot = try repository.delete(transaction)
            deletedCount += 1
            show(Toast(message: String(localized: "Silindi"), actionTitle: String(localized: "Geri al")) {
                do {
                    try repository.restore(snapshot)
                } catch {
                    logger.error("Geri alma başarısız: \(error.localizedDescription, privacy: .public)")
                    show(Toast(message: String(localized: "Geri alınamadı. Tekrar dene.")))
                }
            })
        } catch {
            logger.error("Silme başarısız: \(error.localizedDescription, privacy: .public)")
            show(Toast(message: String(localized: "Silinemedi. Tekrar dene.")))
        }
    }

    private func duplicate(_ transaction: Transaction) {
        do {
            try TransactionRepository(context: context).duplicateToNow(transaction)
            savedCount += 1
            show(Toast(message: String(localized: "Bugüne kopyalandı")))
        } catch {
            logger.error("Kopyalama başarısız: \(error.localizedDescription, privacy: .public)")
            show(Toast(message: String(localized: "Kopyalanamadı. Tekrar dene.")))
        }
    }
}

#if DEBUG
#Preview("Açık mod") {
    RootTabView()
        .modelContainer(AppModelContainer.preview())
}

#Preview("Koyu mod") {
    RootTabView()
        .modelContainer(AppModelContainer.preview())
        .preferredColorScheme(.dark)
}
#endif
