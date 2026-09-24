import SwiftUI

/// Başlık, ana tutar, karşılaştırma satırı (Bölüm 5.3). Ekranın ana sayısıdır
/// (Bölüm 3, ilke 2); altına ek satırlar `footer` ile eklenir.
struct SummaryCard<Footer: View>: View {
    let title: LocalizedStringKey
    let amount: Decimal
    /// Önceki döneme göre oran; `nil` ise karşılaştırma satırı gösterilmez.
    var change: Decimal?
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
            AmountText(amount: amount, style: .hero)
            if let change {
                ChangeLabel(change: change)
            }
            footer
        }
        .cardBackground(.surfaceMint)
    }
}

extension SummaryCard where Footer == EmptyView {
    init(title: LocalizedStringKey, amount: Decimal, change: Decimal?) {
        self.init(title: title, amount: amount, change: change) { EmptyView() }
    }
}

/// "↓ %8 geçen aya göre". Yargılamayan dil: artış kırmızıyla bağırmaz (Bölüm 2, ilke 7).
private struct ChangeLabel: View {
    let change: Decimal

    var body: some View {
        Label {
            if change == 0 {
                Text("Geçen dönemle aynı")
            } else {
                Text("\(abs(change).percentFormatted) geçen döneme göre")
            }
        } icon: {
            Image(systemName: change > 0 ? "arrow.up" : change < 0 ? "arrow.down" : "equal")
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(Color.textSecondary)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: Text {
        let percent = abs(change).percentFormatted
        if change > 0 { return Text("Geçen döneme göre \(percent) fazla") }
        if change < 0 { return Text("Geçen döneme göre \(percent) az") }
        return Text("Geçen dönemle aynı")
    }
}

#Preview("Açık mod") {
    VStack {
        SummaryCard(title: "Toplam harcama", amount: 18450, change: Decimal(string: "-0.08"))
        SummaryCard(title: "Toplam harcama", amount: 950, change: nil)
    }
    .padding()
    .background(Color.background)
}

#Preview("Koyu mod") {
    VStack {
        SummaryCard(title: "Toplam harcama", amount: 18450, change: Decimal(string: "0.12"))
        SummaryCard(title: "Toplam harcama", amount: 950, change: nil)
    }
    .padding()
    .background(Color.background)
    .preferredColorScheme(.dark)
}
