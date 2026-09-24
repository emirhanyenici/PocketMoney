import Foundation
import Testing
@testable import PocketMoney

struct AggregationsTests {
    private let housing = UUID()
    private let food = UUID()

    private var entries: [AmountEntry] {
        [
            AmountEntry(amount: 15000, kind: .expense, categoryID: housing),
            AmountEntry(amount: Decimal(string: "229.99") ?? 0, kind: .expense, categoryID: food),
            AmountEntry(amount: Decimal(string: "70.01") ?? 0, kind: .expense, categoryID: food),
            AmountEntry(amount: 40000, kind: .income, categoryID: nil)
        ]
    }

    @Test func totalsIncomeAndExpenseSeparately() {
        #expect(Aggregations.total(entries, kind: .expense) == 15300)
        #expect(Aggregations.total(entries, kind: .income) == 40000)
        #expect(Aggregations.net(entries) == 24700)
    }

    /// Decimal ile toplama kuruş kaybetmez (Bölüm 12: para asla Double tutulmaz).
    @Test func decimalSumIsExact() {
        let cents = Array(repeating: AmountEntry(amount: Decimal(string: "0.1") ?? 0, kind: .expense, categoryID: nil), count: 10)
        #expect(Aggregations.total(cents, kind: .expense) == 1)
    }

    @Test func groupsExpensesByCategoryDescending() {
        let byCategory = Aggregations.expensesByCategory(entries)
        #expect(byCategory.map(\.categoryID) == [housing, food])
        #expect(byCategory.map(\.amount) == [15000, 300])
    }

    @Test func changeAgainstPreviousPeriod() {
        #expect(Aggregations.change(current: 92, previous: 100) == Decimal(string: "-0.08"))
        #expect(Aggregations.change(current: 100, previous: 0) == nil)
    }

    /// Bölüm 11: en fazla 6 dilim; kalanlar "Diğer" olarak birleşir.
    @Test func mergesTailIntoOther() {
        // Tutarlar 9, 8, 7, 6, 5, 4, 3, 2 → ilk 5 dilim + "Diğer" (4 + 3 + 2).
        let totals = (1...8).map { (key: $0, amount: Decimal(10 - $0)) }
        let slices = Aggregations.slices(totals)

        #expect(slices.count == 6)
        #expect(slices.last?.key == .other)
        #expect(slices.last?.amount == 9)
        #expect(slices.reduce(0) { $0 + $1.amount } == totals.reduce(0) { $0 + $1.amount })
    }

    @Test func keepsAllWhenWithinLimit() {
        let slices = Aggregations.slices([(key: "a", amount: 3), (key: "b", amount: 1)])
        #expect(slices.map(\.key) == [.item("a"), .item("b")])
        #expect(slices.map(\.share) == [Decimal(string: "0.75"), Decimal(string: "0.25")])
    }

    @Test func formatsTurkishCurrencyAndPercent() {
        #expect((Decimal(string: "1234.56") ?? 0).tryFormatted == "₺1.234,56")
        #expect(Decimal(250).tryFormatted == "₺250,00")
        #expect((Decimal(string: "0.08") ?? 0).percentFormatted == "%8")
    }

    /// Bölüm 16: VoiceOver "iki yüz yirmi dokuz lira doksan dokuz kuruş" okumalı.
    @Test func spokenAmountSeparatesLiraAndKurus() {
        #expect((Decimal(string: "229.99") ?? 0).spokenTRY == "229 lira 99 kuruş")
        // Türkçe binlik ayırıcı; VoiceOver "on beş bin lira" okur.
        #expect((Decimal(string: "15000") ?? 0).spokenTRY == "15.000 lira")
        #expect((Decimal(string: "0.5") ?? 0).spokenTRY == "0 lira 50 kuruş")
        #expect((Decimal(string: "12.005") ?? 0).spokenTRY == "12 lira 1 kuruş")
    }
}
