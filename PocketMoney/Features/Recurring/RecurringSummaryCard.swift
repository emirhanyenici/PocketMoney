import SwiftUI

/// "Her ay ₺27.300 sabit" + "Bu dönem kalan: ₺4.120 (3 ödeme)" (Bölüm 6.2-E, 9.3).
struct RecurringSummaryCard: View {
    let summary: RecurringSummary

    init(payments: [RecurringPayment], period: Period) {
        summary = RecurringSummary(payments: payments, period: period)
    }

    var body: some View {
        SummaryCard(title: "Her ay sabit", amount: summary.monthlyTotal, change: nil) {
            if summary.remainingCount > 0 {
                Text("Bu dönem kalan: \(summary.remainingTotal.tryFormatted) (\(summary.remainingCount) ödeme)")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Text("Bu dönemin sabit ödemeleri tamam.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

/// Aktif gider ödemelerinden özet. Gelir olarak işaretli düzenli kayıtlar (ör. maaş)
/// sabit gider toplamına girmez.
struct RecurringSummary {
    let monthlyTotal: Decimal
    let remainingTotal: Decimal
    let remainingCount: Int

    init(payments: [RecurringPayment], period: Period, calendar: Calendar = LocalDay.currentCalendar) {
        let expenses = payments.filter { $0.isActive && ($0.category?.kind ?? .expense) == .expense }
        monthlyTotal = expenses.reduce(Decimal(0)) { total, payment in
            total + RecurrenceSchedule(frequency: payment.frequency, dayOfPeriod: payment.dayOfPeriod, calendar: calendar)
                .monthlyEquivalent(of: payment.amount)
        }
        // Dönem bitmeden vadesi gelen (gecikmişler dahil) ve henüz ödenmemiş olanlar.
        let remaining = expenses.filter { LocalDay.key(for: $0.nextDueDate, calendar: calendar) < period.endKey }
        remainingTotal = remaining.reduce(Decimal(0)) { $0 + $1.amount }
        remainingCount = remaining.count
    }
}
