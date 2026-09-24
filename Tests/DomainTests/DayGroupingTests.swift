import Testing
@testable import PocketMoney

struct DayGroupingTests {
    @Test func groupsConsecutiveKeysPreservingOrder() {
        let items = [("2026-09-24", 1), ("2026-09-24", 2), ("2026-09-23", 3)]
        let groups = DayGrouping.grouped(items, by: \.0)

        #expect(groups.map(\.key) == ["2026-09-24", "2026-09-23"])
        #expect(groups.map { $0.items.map(\.1) } == [[1, 2], [3]])
    }

    @Test func emptyInput() {
        #expect(DayGrouping.grouped([Int](), by: { $0 }).isEmpty)
    }
}
