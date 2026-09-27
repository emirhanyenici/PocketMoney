import OSLog
import SwiftData
import SwiftUI

/// Uygulamanın kökü (Bölüm 6.1): `[ Özet ] [ İşlemler ] ( + )`.
/// "+" her sekmeden erişilebilir ve içeriği kapatmaz.
struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection: AppTab = .overview
    @State private var editor: EditorPresentation?
    @State private var toast: Toast?
    /// "Geri al" görünürken gelen düz bildirim; geri alma şansı kaybolmasın diye bekler.
    @State private var queuedToast: Toast?
    @State private var savedCount = 0
    @State private var deletedCount = 0

    private let logger = Logger(subsystem: "PocketMoney", category: "Transactions")

    var body: some View {
        TabView(selection: $selection) {
            Tab("Özet", systemImage: "chart.pie.fill", value: AppTab.overview) {
                OverviewView(
                    onAdd: { editor = .new($0) },
                    onEdit: { editor = .edit($0) },
                    onShowAll: { selection = .transactions }
                )
            }
            Tab("İşlemler", systemImage: "list.bullet", value: AppTab.transactions) {
                TransactionsView(
                    onAdd: { editor = .new(.expense) },
                    onEdit: { editor = .edit($0) },
                    onDelete: delete,
                    onCopy: duplicate
                )
            }
            // Bölüm 6.1: belirgin "+ Ekle"; VoiceOver etiketi "Harcama ekle".
            Tab("Ekle", systemImage: "plus", value: AppTab.add, role: Self.addTabRole) {
                Color.clear
            }
            .accessibilityLabel("Harcama ekle")
            Tab("Planla", systemImage: "calendar", value: AppTab.plan) {
                RecurringListView { show(Toast(message: $0)) }
            }
        }
        .tint(.brandPrimary)
        // Otomatik kayıtlı düzenli ödemelerin gelmiş vadeleri (Bölüm 9.4). Arka plan
        // yenilemesi ve bildirim yok (Bölüm 22); uygulama öne gelince işlenir.
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { postDueAutomaticPayments() }
        }
        .onChange(of: selection) { previous, current in
            // "+" bir sekme değil, eylemdir: sheet'i aç ve önceki sekmede kal.
            if current == .add {
                selection = previous
                editor = .new(.expense)
            }
        }
        .sheet(item: $editor) { presentation in
            TransactionEditorView(transaction: presentation.transaction, initialKind: presentation.initialKind) {
                savedCount += 1
                show(Toast(message: String(localized: "Kaydedildi")))
            }
        }
        .overlay(alignment: .bottom) { toastOverlay }
        .sensoryFeedback(.success, trigger: savedCount)
        .sensoryFeedback(.warning, trigger: deletedCount)
    }

    /// iOS 27'de sistem "+" sekmesini ayrı, vurgulu çizer; iOS 26'da düz sekme kalır.
    private static var addTabRole: TabRole? {
        if #available(iOS 27.0, *) { .prominent } else { nil }
    }

    // MARK: - Bildirim

    @ViewBuilder
    private var toastOverlay: some View {
        if let toast {
            ToastView(toast: toast) { hideToast() }
                .padding(.bottom, 72)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .task(id: toast.id) {
                    try? await Task.sleep(for: toast.duration)
                    if self.toast?.id == toast.id { hideToast() }
                }
        }
    }

    /// Yeni "Geri al" bildirimi öncekinin yerini alır (en son silme geri alınır);
    /// düz bildirim ise açık bir "Geri al"ın üstüne yazmaz, sıraya girer.
    private func show(_ newToast: Toast) {
        if toast?.action != nil, newToast.action == nil {
            queuedToast = newToast
            return
        }
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) { toast = newToast }
    }

    private func hideToast() {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.3)) { toast = nil }
        if let next = queuedToast {
            queuedToast = nil
            show(next)
        }
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

    private func postDueAutomaticPayments() {
        do {
            let posted = try RecurringPaymentRepository(context: context).postDueAutomaticPayments()
            if !posted.isEmpty {
                show(Toast(message: String(localized: "\(posted.count) otomatik ödeme eklendi")))
            }
        } catch {
            logger.error("Otomatik ödemeler eklenemedi: \(error.localizedDescription, privacy: .public)")
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
