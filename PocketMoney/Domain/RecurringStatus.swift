import Foundation

/// Düzenli ödemenin bugünkü durumu (Bölüm 6.2-E, Bölüm 9.1).
/// "Ödendi" ve "Atlandı" bir vadenin sonucudur; vade ilerleyince ödeme
/// yeniden "Yaklaşıyor" olur.
nonisolated enum RecurringStatus: Equatable, Sendable {
    /// Vadeye `days` gün var.
    case upcoming(days: Int)
    /// Vade bugün; onay bekliyor.
    case dueToday
    /// Vade `days` gün geçti; hâlâ onay bekliyor.
    case overdue(days: Int)
    /// Taksitler bitti, bitiş tarihi geçti ya da kullanıcı durdurdu.
    case ended

    static func of(
        nextDueDate: Date,
        isActive: Bool,
        today: Date = .now,
        calendar: Calendar = LocalDay.currentCalendar
    ) -> RecurringStatus {
        guard isActive else { return .ended }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: today),
            to: calendar.startOfDay(for: nextDueDate)
        ).day ?? 0
        if days > 0 { return .upcoming(days: days) }
        if days == 0 { return .dueToday }
        return .overdue(days: -days)
    }

    /// Onay bekleyen (bugün veya geçmiş) vade.
    var isAwaitingConfirmation: Bool {
        switch self {
        case .dueToday, .overdue: true
        case .upcoming, .ended: false
        }
    }
}
