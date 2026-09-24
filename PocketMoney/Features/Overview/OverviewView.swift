import SwiftData
import SwiftUI

/// Özet (Bölüm 6.2-A): dönem seçici + dönemin özeti.
struct OverviewView: View {
    /// Dönem başlangıç günü (Bölüm 12: ayarlar UserDefaults'ta). Ayarlar ekranı v0.1'in 6. maddesi.
    @AppStorage("periodStartDay") private var periodStartDay = 1
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
        }
    }

    /// `‹ Eylül 2026 ›`. Gelecek dönemlere gidilmez.
    private var periodSelector: some View {
        HStack {
            Button("Önceki dönem", systemImage: "chevron.left") {
                anchorDate = calculator.previous(period).start
            }
            Spacer()
            Text(verbatim: calculator.title(for: period))
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())
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
