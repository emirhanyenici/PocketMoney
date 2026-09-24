import Foundation

/// Toplam hesapları (Bölüm 12 hesaplama kuralları). SwiftData'dan bağımsızdır;
/// çağıran taraf modelleri `AmountEntry`'ye çevirir.
nonisolated struct AmountEntry: Sendable {
    let amount: Decimal
    let kind: TransactionKind
    /// Ana kategori kimliği. Kategorisiz işlemler için `nil`.
    let categoryID: UUID?
}

/// Grafik dilimi: ya tek bir anahtar ya da birleştirilmiş "Diğer".
nonisolated enum SliceKey<Key: Hashable & Sendable>: Hashable, Sendable {
    case item(Key)
    case other
}

nonisolated struct Slice<Key: Hashable & Sendable>: Hashable, Sendable {
    let key: SliceKey<Key>
    let amount: Decimal
    /// 0–1 arası pay.
    let share: Decimal
}

nonisolated enum Aggregations {
    /// Gelir ve gider ayrı toplanır; tutarlar her zaman pozitiftir.
    static func total(_ entries: [AmountEntry], kind: TransactionKind) -> Decimal {
        entries.lazy.filter { $0.kind == kind }.reduce(0) { $0 + $1.amount }
    }

    /// `net = gelir − gider`.
    static func net(_ entries: [AmountEntry]) -> Decimal {
        total(entries, kind: .income) - total(entries, kind: .expense)
    }

    /// Ana kategoriye göre gider toplamları, büyükten küçüğe.
    static func expensesByCategory(_ entries: [AmountEntry]) -> [(categoryID: UUID?, amount: Decimal)] {
        var totals: [UUID?: Decimal] = [:]
        for entry in entries where entry.kind == .expense {
            totals[entry.categoryID, default: 0] += entry.amount
        }
        return totals
            .map { (categoryID: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    /// Önceki döneme göre değişim oranı: 0,08 = %8 artış, −0,08 = %8 azalış.
    /// Önceki dönem boşsa karşılaştırma anlamsız olduğu için `nil`.
    static func change(current: Decimal, previous: Decimal) -> Decimal? {
        guard previous > 0 else { return nil }
        return (current - previous) / previous
    }

    /// Grafik dilimleri (Bölüm 11): en fazla `maxSlices` dilim; fazlası "Diğer"de birleşir.
    /// Girdi büyükten küçüğe sıralı olmalı.
    static func slices<Key: Hashable & Sendable>(
        _ totals: [(key: Key, amount: Decimal)],
        maxSlices: Int = 6
    ) -> [Slice<Key>] {
        let grandTotal = totals.reduce(0) { $0 + $1.amount }
        guard grandTotal > 0, maxSlices > 0 else { return [] }

        let needsOther = totals.count > maxSlices
        let kept = needsOther ? Array(totals.prefix(maxSlices - 1)) : totals
        var result = kept.map {
            Slice(key: .item($0.key), amount: $0.amount, share: $0.amount / grandTotal)
        }
        if needsOther {
            let rest = totals.dropFirst(maxSlices - 1).reduce(0) { $0 + $1.amount }
            result.append(Slice(key: .other, amount: rest, share: rest / grandTotal))
        }
        return result
    }
}
