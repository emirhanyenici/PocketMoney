import SwiftData
import SwiftUI

/// Bir dönemin özeti: hero kart, kategori dağılımı, son işlemler (Bölüm 6.2-A).
struct OverviewContent: View {
    @Query private var transactions: [Transaction]
    @Query private var previousTransactions: [Transaction]

    let onAdd: (TransactionKind) -> Void
    let onEdit: (Transaction) -> Void
    let onShowAll: () -> Void

    init(
        period: Period,
        previousPeriod: Period,
        onAdd: @escaping (TransactionKind) -> Void,
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
                action: { onAdd(.expense) }
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
                } else {
                    // Gelir girişi "+" sheet'inde bir segmentin arkasında kalıp fark
                    // edilmiyordu; net durum ancak gelirle hesaplanır (Bölüm 6.2-A).
                    AddIncomePrompt { onAdd(.income) }
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

/// Dönemde gelir yoksa: kısa açıklama + gelir modunda açılan ekleme butonu.
private struct AddIncomePrompt: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider().overlay(Color.divider)
            HStack(spacing: Spacing.s) {
                Text("Gelirini de girersen ne kadar kaldığını görürsün.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: action) {
                    Label("Gelir ekle", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.income)
                .frame(minHeight: 44)
            }
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
