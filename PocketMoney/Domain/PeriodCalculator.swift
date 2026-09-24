import Foundation

/// Bir harcama dönemi. Dönem başlangıç günü 15 ise "Eylül dönemi"
/// 15 Eylül 00:00 → 15 Ekim 00:00 (hariç) aralığıdır (Bölüm 13).
nonisolated struct Period: Hashable, Sendable {
    /// Dahil.
    let start: Date
    /// Hariç.
    let end: Date
    /// `start`'ın yerel gün anahtarı (dahil).
    let startKey: String
    /// `end`'in yerel gün anahtarı (hariç).
    let endKey: String

    /// İşlemler dönemlere `Date`'e göre değil, girildikleri yerel güne göre
    /// yerleşir (Bölüm 13, saat dilimi kuralı).
    func contains(localDay: String) -> Bool {
        localDay >= startKey && localDay < endKey
    }
}

/// Tüm dönem hesaplarının tek noktası (Bölüm 13, Bölüm 15).
nonisolated struct PeriodCalculator: Sendable {
    /// 1–28. 28'den büyük günler her ayda bulunmadığı için kabul edilmez (Bölüm 6.2-F).
    let startDay: Int
    let calendar: Calendar

    init(startDay: Int = 1, calendar: Calendar = LocalDay.currentCalendar) {
        self.startDay = min(max(startDay, 1), 28)
        self.calendar = calendar
    }

    func period(containing date: Date) -> Period {
        var parts = calendar.dateComponents([.year, .month], from: date)
        parts.day = startDay
        let startThisMonth = calendar.date(from: parts) ?? calendar.startOfDay(for: date)
        let isBeforeStartDay = calendar.component(.day, from: date) < startDay
        let start = isBeforeStartDay ? shifted(startThisMonth, byMonths: -1) : startThisMonth
        return makePeriod(start: start)
    }

    func previous(_ period: Period) -> Period {
        makePeriod(start: shifted(period.start, byMonths: -1))
    }

    func next(_ period: Period) -> Period {
        makePeriod(start: period.end)
    }

    /// Dönem adı başladığı aydan gelir: "Eylül 2026".
    func title(for period: Period, locale: Locale = Decimal.turkishLocale) -> String {
        let style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .month(.wide)
            .year()
        return period.start.formatted(style)
    }

    private func makePeriod(start: Date) -> Period {
        let end = shifted(start, byMonths: 1)
        return Period(
            start: start,
            end: end,
            startKey: LocalDay.key(for: start, calendar: calendar),
            endKey: LocalDay.key(for: end, calendar: calendar)
        )
    }

    private func shifted(_ date: Date, byMonths months: Int) -> Date {
        calendar.date(byAdding: .month, value: months, to: date) ?? date
    }
}
