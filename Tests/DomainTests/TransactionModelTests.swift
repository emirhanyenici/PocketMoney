import Foundation
import Testing
@testable import PocketMoney

@MainActor
struct TransactionModelTests {
    private func calendar(_ identifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: identifier))
        return calendar
    }

    @Test func initStoresLocalDayOfEntry() throws {
        let istanbul = try calendar("Europe/Istanbul")
        let date = try #require(istanbul.date(from: DateComponents(year: 2026, month: 8, day: 31, hour: 23, minute: 30)))

        let transaction = Transaction(amount: 95, kind: .expense, date: date, calendar: istanbul)

        #expect(transaction.localDay == "2026-08-31")
        #expect(transaction.currencyCode == "TRY")
    }

    @Test func updateDateRecomputesLocalDay() throws {
        let istanbul = try calendar("Europe/Istanbul")
        let transaction = Transaction(amount: 95, kind: .expense, calendar: istanbul)
        let newDate = try #require(istanbul.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 10)))

        transaction.updateDate(newDate, calendar: istanbul)

        #expect(transaction.date == newDate)
        #expect(transaction.localDay == "2026-01-02")
    }

    @Test func enumAccessorsWriteRawStorage() {
        let transaction = Transaction(amount: Decimal(string: "229.99") ?? 0, kind: .expense)
        transaction.kind = .income
        transaction.channel = .online

        #expect(transaction.kindRaw == "income")
        #expect(transaction.channelRaw == "online")

        transaction.channel = nil
        #expect(transaction.channelRaw == nil)
    }
}
