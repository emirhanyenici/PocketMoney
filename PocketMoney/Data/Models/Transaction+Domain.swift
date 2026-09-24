import Foundation

extension Transaction {
    /// Domain hesaplarına giden sade değer (Bölüm 13: Domain SwiftData'dan bağımsız).
    var amountEntry: AmountEntry {
        AmountEntry(amount: amount, kind: kind, categoryID: category?.id)
    }
}

extension Sequence where Element == Transaction {
    var amountEntries: [AmountEntry] { map(\.amountEntry) }
}
