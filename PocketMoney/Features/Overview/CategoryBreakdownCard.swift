import Charts
import SwiftUI

/// Kategori donut grafiği + en çok harcanan kategoriler (Bölüm 6.2-A, Bölüm 11).
/// En fazla 6 dilim; kalanlar "Diğer"de birleşir. Altında metin özeti vardır.
struct CategoryBreakdownCard: View {
    let transactions: [Transaction]

    private var categoriesByID: [UUID: Category] {
        Dictionary(transactions.compactMap(\.category).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private var slices: [Slice<UUID?>] {
        let totals = Aggregations.expensesByCategory(transactions.amountEntries)
        return Aggregations.slices(totals.map { (key: $0.categoryID, amount: $0.amount) })
    }

    var body: some View {
        let slices = slices
        let total = slices.reduce(Decimal.zero) { $0 + $1.amount }

        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Kategoriler")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            Chart(slices, id: \.key) { slice in
                // Grafik geometrisi için Double'a çevrilir; para hesabı değildir.
                SectorMark(
                    angle: .value("Tutar", NSDecimalNumber(decimal: slice.amount).doubleValue),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(color(for: slice))
            }
            .chartLegend(.hidden)
            .chartBackground { _ in
                VStack(spacing: 2) {
                    Text("Toplam")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    AmountText(amount: total)
                }
            }
            .frame(height: 200)
            .accessibilityHidden(true)

            if let top = slices.first {
                Text("En büyük gider: \(name(for: top)) (\(top.share.percentFormatted))")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }

            VStack(spacing: Spacing.s) {
                ForEach(slices.prefix(5), id: \.key) { slice in
                    legendRow(slice)
                }
            }
        }
        .cardBackground()
    }

    private func legendRow(_ slice: Slice<UUID?>) -> some View {
        HStack(spacing: Spacing.s) {
            CategoryIcon(category: category(for: slice), size: 32)
            Text(verbatim: name(for: slice))
                .font(.body)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                AmountText(amount: slice.amount)
                Text(verbatim: slice.share.percentFormatted)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func category(for slice: Slice<UUID?>) -> Category? {
        guard case .item(let id?) = slice.key else { return nil }
        return categoriesByID[id]
    }

    private func name(for slice: Slice<UUID?>) -> String {
        switch slice.key {
        case .other: String(localized: "Diğer")
        case .item: category(for: slice)?.name ?? String(localized: "Kategorisiz")
        }
    }

    private func color(for slice: Slice<UUID?>) -> Color {
        if case .other = slice.key { return .textTertiary }
        return Color.category(token: category(for: slice)?.colorToken ?? CategoryColor.stone.rawValue)
    }
}
