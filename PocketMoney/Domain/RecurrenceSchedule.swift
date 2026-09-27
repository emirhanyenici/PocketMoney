import Foundation

/// Düzenli ödemenin vade tarihleri (Bölüm 9.1, Bölüm 15: Domain'de, test edilebilir).
///
/// Ay tabanlı periyotlarda ödeme günü her vade için ayın kendisinden yeniden
/// hesaplanır: "her ayın 31'i" Şubat'ta 28'ine düşer ama Mart'ta yine 31'ine
/// döner, gün kaymaz. Haftalık ve "her N gün" periyotları başlangıçtan sayar.
nonisolated struct RecurrenceSchedule: Sendable {
    let frequency: RecurrenceFrequency
    /// Ay tabanlı periyotlarda ödeme günü (1–31).
    let dayOfPeriod: Int
    let calendar: Calendar

    init(frequency: RecurrenceFrequency, dayOfPeriod: Int, calendar: Calendar = LocalDay.currentCalendar) {
        self.frequency = frequency
        self.dayOfPeriod = min(max(dayOfPeriod, 1), 31)
        self.calendar = calendar
    }

    /// Başlangıç tarihinden itibaren ilk vade (günün başlangıcı).
    /// 20 Eylül'de başlayan "her ayın 5'i" ödemesinin ilk vadesi 5 Ekim'dir.
    func firstDueDate(onOrAfter start: Date) -> Date {
        let startDay = calendar.startOfDay(for: start)
        guard let months = monthStep else { return startDay }
        let candidate = dueDate(inMonthOf: startDay)
        return candidate >= startDay ? candidate : dueDate(inMonthOf: shifted(startDay, byMonths: months))
    }

    /// Bir vadeden sonraki vade.
    func nextDueDate(after due: Date) -> Date {
        let dueDay = calendar.startOfDay(for: due)
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: dueDay) ?? dueDay
        case .customDays(let days):
            return calendar.date(byAdding: .day, value: max(days, 1), to: dueDay) ?? dueDay
        case .monthly, .quarterly, .semiannual, .yearly:
            return dueDate(inMonthOf: shifted(dueDay, byMonths: monthStep ?? 1))
        }
    }

    /// Aylık eşdeğer: yıllık ₺1.200 → ≈ ₺100/ay (Bölüm 9.3). Kuruşa yuvarlanır.
    func monthlyEquivalent(of amount: Decimal) -> Decimal {
        let perMonth: Decimal = switch frequency {
        case .weekly: amount * 52 / 12
        case .customDays(let days): amount * Decimal(365) / Decimal(max(days, 1)) / 12
        case .monthly: amount
        case .quarterly: amount / 3
        case .semiannual: amount / 6
        case .yearly: amount / 12
        }
        var input = perMonth
        var output = Decimal()
        NSDecimalRound(&output, &input, 2, .plain)
        return output
    }

    // MARK: - Yardımcılar

    private var monthStep: Int? {
        switch frequency {
        case .monthly: 1
        case .quarterly: 3
        case .semiannual: 6
        case .yearly: 12
        case .weekly, .customDays: nil
        }
    }

    /// Verilen tarihin ayında ödeme günü; ayda o gün yoksa ayın son günü.
    private func dueDate(inMonthOf date: Date) -> Date {
        var parts = calendar.dateComponents([.year, .month], from: date)
        let monthStart = calendar.date(from: parts) ?? date
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 28
        parts.day = min(dayOfPeriod, daysInMonth)
        return calendar.date(from: parts) ?? monthStart
    }

    private func shifted(_ date: Date, byMonths months: Int) -> Date {
        // Ayın 1'ine göre kaydırılır; 31 Ocak + 1 ay Mart'a taşmasın.
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        return calendar.date(byAdding: .month, value: months, to: monthStart) ?? monthStart
    }
}
