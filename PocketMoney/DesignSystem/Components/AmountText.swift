import SwiftUI

/// TRY formatlı, rounded, eş genişlikli rakamlı tutar (Bölüm 5.1, 5.3).
/// Giderler nötr renkte, gelirler `income` renginde ve "+" ile gösterilir (Bölüm 4.3).
struct AmountText: View {
    enum Style {
        /// Ana ekrandaki büyük toplam.
        case hero
        /// Liste satırlarındaki tutar.
        case list
    }

    let amount: Decimal
    var kind: TransactionKind = .expense
    var style: Style = .list
    /// Gelirlerde başa "+" koyar.
    var showsIncomeSign = true

    var body: some View {
        Text(verbatim: sign + amount.tryFormatted)
            .font(style == .hero ? .largeTitle.bold() : .body.weight(.semibold))
            .fontDesign(.rounded)
            .monospacedDigit()
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            // VoiceOver "iki yüz yirmi dokuz lira doksan dokuz kuruş" okur (Bölüm 16).
            .accessibilityLabel(Text(verbatim: (kind == .income && showsIncomeSign ? String(localized: "artı ") : "") + amount.spokenTRY))
    }

    private var sign: String {
        kind == .income && showsIncomeSign ? "+" : ""
    }

    private var color: Color {
        switch (kind, style) {
        case (.income, _): .income
        case (.expense, .hero): .brandPrimaryDeep
        case (.expense, .list): .expense
        }
    }

}

#Preview("Açık mod") {
    VStack(spacing: 12) {
        AmountText(amount: 18450, style: .hero)
        AmountText(amount: Decimal(string: "229.99") ?? 0)
        AmountText(amount: 40000, kind: .income)
    }
    .padding()
    .background(Color.background)
}

#Preview("Koyu mod") {
    VStack(spacing: 12) {
        AmountText(amount: 18450, style: .hero)
        AmountText(amount: Decimal(string: "229.99") ?? 0)
        AmountText(amount: 40000, kind: .income)
    }
    .padding()
    .background(Color.background)
    .preferredColorScheme(.dark)
}
