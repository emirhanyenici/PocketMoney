import SwiftData
import SwiftUI

/// Bir dönemin özeti: hero kart, kategori dağılımı, son işlemler (Bölüm 6.2-A).
struct OverviewContent: View {
    @Query private var transactions: [Transaction]
    @Query private var previousTransactions: [Transaction]

    let onAdd: () -> Void
    let onEdit: (Transaction) -> Void
    let onShowAll: () -> Void

    init(
        period: Period,
        previousPeriod: Period,
        onAdd: @escaping () -> Void,
        onEdit: @escaping (Transaction) -> Void,
        onShowAll: @escaping () -> Void
    ) {
        _transactions = Query(Self.descriptor(for: period))
        _previousTransactions = Query(Self.descriptor(for: previousPeriod))
        self.onAdd = onAdd
        self.onEdit = onEdit
        self.onShowAll = onShowAll
    }

    /// Dönem üyeliği `localDay` ile belirlenir (Bölüm 13). Anahtarlar sözlük
    /// sırasıyla kronolojik olduğu için aralık sorgusu doğrudan çalışır.
    private static func descriptor(for period: Period) -> FetchDescriptor<Transaction> {
        let start = period.startKey
        let end = period.endKey
        return FetchDescriptor(
            predicate: #Predicate { $0.localDay >= start && $0.localDay < end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
    }

    var body: some View {
        if transactions.isEmpty {
            EmptyStateView(
                symbolName: "chart.pie",
                message: "Bu ay henüz harcama yok. İlkini eklemek 5 saniye sürer.",
                actionTitle: "İlk harcamanı ekle",
                action: onAdd
            )
            .padding(.top, Spacing.xxl)
        } else {
            let entries = transactions.amountEntries
            let spent = Aggregations.total(entries, kind: .expense)
            let earned = Aggregations.total(entries, kind: .income)
            let previousSpent = Aggregations.total(previousTransactions.amountEntries, kind: .expense)

            SummaryCard(
                title: "Toplam harcama",
                amount: spent,
                change: Aggregations.change(current: spent, previous: previousSpent)
            ) {
                if earned > 0 {
                    NetBalanceRow(income: earned, expense: spent, net: Aggregations.net(entries))
                        .padding(.top, Spacing.xs)
                }
            }

            if spent > 0 {
                CategoryBreakdownCard(transactions: transactions)
            }

            RecentTransactionsCard(
                transactions: Array(transactions.prefix(5)),
                onEdit: onEdit,
                onShowAll: onShowAll
            )
        }
    }
}

/// "Gelir − Gider = Kalan" (Bölüm 6.2-A). Yalnızca gelir girildiyse gösterilir.
private struct NetBalanceRow: View {
    let income: Decimal
    let expense: Decimal
    let net: Decimal

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Divider().overlay(Color.divider)
            row("Gelir", AmountText(amount: income, kind: .income, showsIncomeSign: false))
            row("Gider", AmountText(amount: expense))
            row("Kalan", AmountText(amount: net))
        }
    }

    private func row(_ title: LocalizedStringKey, _ amount: AmountText) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            amount
        }
        .accessibilityElement(children: .combine)
    }
}
