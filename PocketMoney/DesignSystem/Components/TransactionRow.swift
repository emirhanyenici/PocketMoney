import SwiftData
import SwiftUI

/// İşlem satırı (Bölüm 5.3): ikon, başlık (marka veya kategori),
/// alt satır (alt kategori · ödeme yöntemi · online/mağaza), sağda tutar.
/// VoiceOver için tek öğe olarak birleştirilir (Bölüm 16).
struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: Spacing.s) {
            CategoryIcon(category: transaction.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: title)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(verbatim: subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: Spacing.xs)
            AmountText(amount: transaction.amount, kind: transaction.kind)
        }
        .padding(.vertical, Spacing.xxs)
        // Satırın tamamı dokunulabilir olsun; `.plain` buton stilinde aradaki
        // Spacer boşluğu aksi hâlde dokunmayı almaz.
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        transaction.merchant?.name
            ?? transaction.category?.name
            ?? String(localized: "Kategorisiz")
    }

    private var subtitle: String {
        var parts: [String] = []
        if transaction.merchant != nil {
            // Başlık marka olduğunda kategori alt satıra iner.
            if let name = transaction.subcategory?.name ?? transaction.category?.name { parts.append(name) }
        } else if let name = transaction.subcategory?.name {
            parts.append(name)
        }
        if let method = transaction.paymentMethod?.name { parts.append(method) }
        if let channel = transaction.channel { parts.append(channel.title) }
        return parts.joined(separator: " · ")
    }
}

extension PurchaseChannel {
    /// Kullanıcıya görünen ad.
    var title: String {
        switch self {
        case .inStore: String(localized: "Mağazada")
        case .online: String(localized: "Online")
        }
    }
}

#if DEBUG
#Preview("Açık mod") {
    TransactionRowPreview()
        .modelContainer(AppModelContainer.preview())
}

#Preview("Koyu mod") {
    TransactionRowPreview()
        .modelContainer(AppModelContainer.preview())
        .preferredColorScheme(.dark)
}

private struct TransactionRowPreview: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    var body: some View {
        List(transactions.prefix(5)) { TransactionRow(transaction: $0) }
    }
}
#endif
