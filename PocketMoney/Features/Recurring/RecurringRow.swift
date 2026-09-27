import SwiftUI

/// Düzenli ödeme satırı (Bölüm 6.2-E): ad, tutar, periyot, sonraki tarih, durum.
/// Onay bekleyen vadede "Ödendi" düğmesi satırın içinde durur.
struct RecurringRow: View {
    let payment: RecurringPayment
    let status: RecurringStatus
    let onPay: () -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            CategoryIcon(category: payment.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: payment.name)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                Text(verbatim: detail)
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                Text(verbatim: status.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(status.color)
            }
            Spacer(minLength: Spacing.xs)
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                AmountText(amount: payment.amount, kind: payment.category?.kind ?? .expense)
                if status.isAwaitingConfirmation {
                    Button("Ödendi", action: onPay)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)
                        .tint(.brandPrimary)
                        .foregroundStyle(Color.textOnPrimary)
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
        .contentShape(.rect)
    }

    /// "Aylık · 5 Ekim · otomatik"
    private var detail: String {
        var parts = [payment.frequency.title]
        if payment.isActive {
            parts.append(payment.nextDueDate.formatted(.dateTime.day().month(.wide).locale(Decimal.turkishLocale)))
        }
        if payment.mode == .autoPost { parts.append(String(localized: "otomatik")) }
        return parts.joined(separator: " · ")
    }
}
