import Testing
@testable import PocketMoney

struct RecurrenceFrequencyTests {
    @Test(arguments: [
        RecurrenceFrequency.weekly, .monthly, .quarterly, .semiannual, .yearly, .customDays(1), .customDays(45)
    ])
    func roundTripsThroughStorage(frequency: RecurrenceFrequency) {
        let restored = RecurrenceFrequency(storageKey: frequency.storageKey, customDays: frequency.customDays)
        #expect(restored == frequency)
    }

    @Test func customDaysIsOnlySetForCustom() {
        #expect(RecurrenceFrequency.monthly.customDays == nil)
        #expect(RecurrenceFrequency.customDays(10).customDays == 10)
    }

    @Test func rejectsInvalidStorage() {
        #expect(RecurrenceFrequency(storageKey: "customDays", customDays: nil) == nil)
        #expect(RecurrenceFrequency(storageKey: "customDays", customDays: 0) == nil)
        #expect(RecurrenceFrequency(storageKey: "fortnightly", customDays: nil) == nil)
    }
}
