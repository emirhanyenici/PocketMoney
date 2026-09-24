import Foundation
import Testing
@testable import PocketMoney

struct LocalDayTests {
    private func calendar(_ identifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: identifier))
        return calendar
    }

    @Test func formatsAsZeroPaddedISODay() throws {
        let istanbul = try calendar("Europe/Istanbul")
        let date = try #require(istanbul.date(from: DateComponents(year: 2026, month: 3, day: 5, hour: 9)))
        #expect(LocalDay.key(for: date, calendar: istanbul) == "2026-03-05")
    }

    /// Bölüm 13: İstanbul'da 31 Ağustos 23:30'da girilen harcama Ağustos'ta kalmalı.
    /// Aynı an Tokyo takvimiyle 1 Eylül'e düşer; bu yüzden gün, giriş anında saklanır.
    @Test func dayDependsOnEntryTimeZone() throws {
        let istanbul = try calendar("Europe/Istanbul")
        let tokyo = try calendar("Asia/Tokyo")
        let date = try #require(istanbul.date(from: DateComponents(year: 2026, month: 8, day: 31, hour: 23, minute: 30)))

        #expect(LocalDay.key(for: date, calendar: istanbul) == "2026-08-31")
        #expect(LocalDay.key(for: date, calendar: tokyo) == "2026-09-01")
    }

    @Test func keysSortChronologically() throws {
        let istanbul = try calendar("Europe/Istanbul")
        let days = [(2026, 12, 31), (2026, 2, 9), (2026, 10, 1)].map { year, month, day in
            istanbul.date(from: DateComponents(year: year, month: month, day: day)).map {
                LocalDay.key(for: $0, calendar: istanbul)
            }
        }
        #expect(days.compactMap { $0 }.sorted() == ["2026-02-09", "2026-10-01", "2026-12-31"])
    }
}
