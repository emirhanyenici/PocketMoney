import SwiftUI

/// Dönemin son 5 işlemi + "Tümünü gör" (Bölüm 6.2-A).
struct RecentTransactionsCard: View {
    let transactions: [Transaction]
    let onEdit: (Transaction) -> Void
    let onShowAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text("Son işlemler")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button("Tümünü gör", action: onShowAll)
                    .font(.subheadline.weight(.semibold))
                    .tint(.brandPrimary)
                    .frame(minHeight: 44)
            }
            ForEach(transactions) { transaction in
                Button { onEdit(transaction) } label: {
                    TransactionRow(transaction: transaction)
                }
                .buttonStyle(.plain)
                if transaction != transactions.last {
                    Divider().overlay(Color.divider)
                }
            }
        }
        .cardBackground()
    }
}
