import Foundation
import Testing
@testable import PocketMoney

/// Düzenli ödeme vade hesabı (Bölüm 9.1).
struct RecurrenceScheduleTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .gmt
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    private func schedule(_ frequency: RecurrenceFrequency, day: Int = 1) -> RecurrenceSchedule {
        RecurrenceSchedule(frequency: frequency, dayOfPeriod: day, calendar: calendar)
    }

    @Test func firstDueIsThisMonthWhenDayNotPassed() {
        #expect(schedule(.monthly, day: 25).firstDueDate(onOrAfter: date(2026, 9, 20)) == date(2026, 9, 25))
        #expect(schedule(.monthly, day: 20).firstDueDate(onOrAfter: date(2026, 9, 20)) == date(2026, 9, 20))
    }

    @Test func firstDueMovesToNextMonthWhenDayPassed() {
        #expect(schedule(.monthly, day: 5).firstDueDate(onOrAfter: date(2026, 9, 20)) == date(2026, 10, 5))
        #expect(schedule(.yearly, day: 5).firstDueDate(onOrAfter: date(2026, 9, 20)) == date(2027, 9, 5))
    }

    @Test func monthEndClampsWithoutDrifting() {
        let rent = schedule(.monthly, day: 31)
        let january = date(2027, 1, 31)
        let february = rent.nextDueDate(after: january)
        #expect(february == date(2027, 2, 28))
        #expect(rent.nextDueDate(after: february) == date(2027, 3, 31))
        #expect(rent.nextDueDate(after: date(2028, 1, 31)) == date(2028, 2, 29))
    }

    @Test func monthBasedSteps() {
        #expect(schedule(.quarterly, day: 15).nextDueDate(after: date(2026, 11, 15)) == date(2027, 2, 15))
        #expect(schedule(.semiannual, day: 15).nextDueDate(after: date(2026, 9, 15)) == date(2027, 3, 15))
        #expect(schedule(.yearly, day: 29).nextDueDate(after: date(2028, 2, 29)) == date(2029, 2, 28))
    }

    @Test func dayBasedSteps() {
        #expect(schedule(.weekly).firstDueDate(onOrAfter: date(2026, 9, 20)) == date(2026, 9, 20))
        #expect(schedule(.weekly).nextDueDate(after: date(2026, 9, 28)) == date(2026, 10, 5))
        #expect(schedule(.customDays(45)).nextDueDate(after: date(2026, 9, 1)) == date(2026, 10, 16))
    }

    @Test func monthlyEquivalent() {
        #expect(schedule(.yearly).monthlyEquivalent(of: 1200) == 100)
        #expect(schedule(.quarterly).monthlyEquivalent(of: 300) == 100)
        #expect(schedule(.monthly).monthlyEquivalent(of: Decimal(string: "229.99") ?? 0) == Decimal(string: "229.99"))
        #expect(schedule(.weekly).monthlyEquivalent(of: 120) == 520)
    }
}
