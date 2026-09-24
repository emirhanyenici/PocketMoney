import SwiftData
import SwiftUI

/// İşlemler (Bölüm 6.2-C): günlere göre gruplu liste, her grupta gün toplamı.
/// Sola kaydır: Sil · Sağa kaydır: Kopyala · Dokun: Düzenle.
/// Arama ve filtre v0.3'te gelir (Bölüm 18).
struct TransactionsView: View {
    @Query(sort: [
        SortDescriptor(\Transaction.localDay, order: .reverse),
        SortDescriptor(\Transaction.date, order: .reverse)
    ])
    private var transactions: [Transaction]

    let onAdd: () -> Void
    let onEdit: (Transaction) -> Void
    let onDelete: (Transaction) -> Void
    let onCopy: (Transaction) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    EmptyStateView(
                        symbolName: "list.bullet.rectangle",
                        message: "Henüz kayıt yok. İlkini eklemek 5 saniye sürer.",
                        actionTitle: "İlk harcamanı ekle",
                        action: onAdd
                    )
                } else {
                    list
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background)
            .navigationTitle("İşlemler")
        }
    }

    private var list: some View {
        List {
            ForEach(DayGrouping.grouped(transactions, by: \.localDay), id: \.key) { group in
                Section {
                    ForEach(group.items) { transaction in
                        Button { onEdit(transaction) } label: {
                            TransactionRow(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.surface)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Sil", systemImage: "trash", role: .destructive) { onDelete(transaction) }
                        }
                        .swipeActions(edge: .leading) {
                            Button("Kopyala", systemImage: "plus.square.on.square") { onCopy(transaction) }
                                .tint(Color.brandSecondary)
                        }
                    }
                } header: {
                    DayHeader(localDay: group.key, transactions: group.items)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

/// "Bugün", "Dün" veya "24 Eylül Perşembe" + o günün gider toplamı.
private struct DayHeader: View {
    let localDay: String
    let transactions: [Transaction]

    var body: some View {
        HStack {
            Text(verbatim: title)
            Spacer()
            let spent = Aggregations.total(transactions.amountEntries, kind: .expense)
            if spent > 0 {
                Text(verbatim: spent.tryFormatted)
                    .monospacedDigit()
            }
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Color.textSecondary)
        .textCase(nil)
    }

    private var title: String {
        let calendar = LocalDay.currentCalendar
        guard let date = LocalDay.date(fromKey: localDay, calendar: calendar) else { return localDay }
        if calendar.isDateInToday(date) { return String(localized: "Bugün") }
        if calendar.isDateInYesterday(date) { return String(localized: "Dün") }
        var style = Date.FormatStyle(locale: Decimal.turkishLocale, calendar: calendar, timeZone: calendar.timeZone)
            .day()
            .month(.wide)
            .weekday(.wide)
        if !calendar.isDate(date, equalTo: .now, toGranularity: .year) { style = style.year() }
        return date.formatted(style)
    }
}

#if DEBUG
#Preview("Açık mod") {
    TransactionsView(onAdd: {}, onEdit: { _ in }, onDelete: { _ in }, onCopy: { _ in })
        .modelContainer(AppModelContainer.preview())
}

#Preview("Koyu mod") {
    TransactionsView(onAdd: {}, onEdit: { _ in }, onDelete: { _ in }, onCopy: { _ in })
        .modelContainer(AppModelContainer.preview())
        .preferredColorScheme(.dark)
}

#Preview("Boş") {
    TransactionsView(onAdd: {}, onEdit: { _ in }, onDelete: { _ in }, onCopy: { _ in })
        .modelContainer(AppModelContainer.preview(withTransactions: false))
}
#endif
