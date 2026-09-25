import SwiftData
import SwiftUI

/// Özet (Bölüm 6.2-A): dönem seçici + dönemin özeti.
struct OverviewView: View {
    /// Dönem başlangıç günü; Ayarlar'dan değişir (Bölüm 6.2-F).
    @AppStorage(AppSettings.periodStartDayKey) private var periodStartDay = AppSettings.defaultPeriodStartDay
    /// Seçili dönemin içinde kalan herhangi bir an.
    @State private var anchorDate = Date.now

    let onAdd: () -> Void
    let onEdit: (Transaction) -> Void
    let onShowAll: () -> Void

    private var calculator: PeriodCalculator { PeriodCalculator(startDay: periodStartDay) }
    private var period: Period { calculator.period(containing: anchorDate) }
    private var isCurrentPeriod: Bool { period.contains(localDay: LocalDay.key(for: .now)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    periodSelector
                    OverviewContent(
                        period: period,
                        previousPeriod: calculator.previous(period),
                        onAdd: onAdd,
                        onEdit: onEdit,
                        onShowAll: onShowAll
                    )
                    // Dönem değişince sorgular yeniden kurulur.
                    .id(period)
                }
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.background)
            .navigationTitle("Özet")
            .toolbar {
                // Bölüm 6.1: Ayarlar, Özet'in sağ üstündeki dişli ikonundan açılır.
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Ayarlar", systemImage: "gearshape")
                    }
                }
            }
        }
    }

    /// `‹ Eylül 2026 ›`. Gelecek dönemlere gidilmez.
    private var periodSelector: some View {
        HStack {
            Button("Önceki dönem", systemImage: "chevron.left") {
                anchorDate = calculator.previous(period).start
            }
            Spacer()
            VStack(spacing: 2) {
                Text(verbatim: calculator.title(for: period))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText())
                // Maaş günü dönemi ay adından anlaşılmaz; aralığı açıkça göster.
                if periodStartDay != 1 {
                    Text(verbatim: calculator.rangeTitle(for: period))
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Button("Sonraki dönem", systemImage: "chevron.right") {
                anchorDate = calculator.next(period).start
            }
            .disabled(isCurrentPeriod)
        }
        .labelStyle(.iconOnly)
        .font(.title3.weight(.semibold))
        .buttonStyle(.borderless)
        .tint(.brandPrimary)
        .frame(minHeight: 44)
    }
}

#if DEBUG
#Preview("Açık mod") {
    OverviewView(onAdd: {}, onEdit: { _ in }, onShowAll: {})
        .modelContainer(AppModelContainer.preview())
}

#Preview("Koyu mod") {
    OverviewView(onAdd: {}, onEdit: { _ in }, onShowAll: {})
        .modelContainer(AppModelContainer.preview())
        .preferredColorScheme(.dark)
}

#Preview("Boş") {
    OverviewView(onAdd: {}, onEdit: { _ in }, onShowAll: {})
        .modelContainer(AppModelContainer.preview(withTransactions: false))
}
#endif
