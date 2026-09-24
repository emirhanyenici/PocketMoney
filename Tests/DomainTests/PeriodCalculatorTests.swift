import Foundation
import Testing
@testable import PocketMoney

struct PeriodCalculatorTests {
    private let istanbul: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) throws -> Date {
        try #require(istanbul.date(from: DateComponents(year: year, month: month, day: day, hour: hour)))
    }

    @Test func calendarMonthWhenStartDayIsFirst() throws {
        let calculator = PeriodCalculator(startDay: 1, calendar: istanbul)
        let period = calculator.period(containing: try date(2026, 9, 24))

        #expect(period.startKey == "2026-09-01")
        #expect(period.endKey == "2026-10-01")
        #expect(calculator.title(for: period) == "Eylül 2026")
    }

    /// Bölüm 13: başlangıç günü 15 ise "Eylül dönemi" = 15 Eylül → 14 Ekim.
    @Test func salaryDayPeriodSpansTwoMonths() throws {
        let calculator = PeriodCalculator(startDay: 15, calendar: istanbul)

        let september = calculator.period(containing: try date(2026, 10, 14))
        #expect(september.startKey == "2026-09-15")
        #expect(september.endKey == "2026-10-15")
        #expect(september.contains(localDay: "2026-10-14"))
        #expect(!september.contains(localDay: "2026-10-15"))

        let october = calculator.period(containing: try date(2026, 10, 15))
        #expect(october.startKey == "2026-10-15")
    }

    @Test func wrapsAcrossYears() throws {
        let calculator = PeriodCalculator(startDay: 15, calendar: istanbul)
        let period = calculator.period(containing: try date(2027, 1, 3))

        #expect(period.startKey == "2026-12-15")
        #expect(calculator.next(period).startKey == "2027-01-15")
        #expect(calculator.previous(period).startKey == "2026-11-15")
    }

    @Test func periodStartsAtMidnight() throws {
        let calculator = PeriodCalculator(startDay: 1, calendar: istanbul)
        let period = calculator.period(containing: try date(2026, 9, 1, hour: 0))

        #expect(period.start == istanbul.startOfDay(for: try date(2026, 9, 1)))
    }

    @Test(arguments: [0, -3, 29, 31])
    func clampsStartDayToValidRange(startDay: Int) {
        #expect((1...28).contains(PeriodCalculator(startDay: startDay).startDay))
    }
}
