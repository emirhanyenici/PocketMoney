import Foundation

/// Sıralı bir listeyi, sırayı koruyarak ardışık anahtarlara göre gruplar
/// (İşlemler ekranında günlere göre gruplama, Bölüm 6.2-C).
nonisolated enum DayGrouping {
    static func grouped<Item, Key: Equatable>(
        _ items: [Item],
        by key: (Item) -> Key
    ) -> [(key: Key, items: [Item])] {
        var groups: [(key: Key, items: [Item])] = []
        for item in items {
            let itemKey = key(item)
            if let lastKey = groups.last?.key, lastKey == itemKey {
                groups[groups.count - 1].items.append(item)
            } else {
                groups.append((key: itemKey, items: [item]))
            }
        }
        return groups
    }
}
