import SwiftUI

extension RecurrenceFrequency {
    /// Kullanıcıya görünen periyot adı.
    var title: String {
        switch self {
        case .weekly: String(localized: "Haftalık")
        case .monthly: String(localized: "Aylık")
        case .quarterly: String(localized: "3 ayda bir")
        case .semiannual: String(localized: "6 ayda bir")
        case .yearly: String(localized: "Yıllık")
        case .customDays(let days): String(localized: "\(days) günde bir")
        }
    }

    /// Ödeme günü seçimi yalnızca ay tabanlı periyotlarda anlamlıdır.
    var usesDayOfMonth: Bool {
        switch self {
        case .weekly, .customDays: false
        case .monthly, .quarterly, .semiannual, .yearly: true
        }
    }

    /// Formdaki seçici; "özel" ayrıca gün sayısıyla gelir.
    static let pickerCases: [RecurrenceFrequency] = [.weekly, .monthly, .quarterly, .semiannual, .yearly, .customDays(30)]
}

extension RecurringStatus {
    /// Yargılamayan kısa durum metni (Bölüm 21).
    var title: String {
        switch self {
        case .upcoming(let days) where days == 1: String(localized: "Yarın")
        case .upcoming(let days): String(localized: "\(days) gün sonra")
        case .dueToday: String(localized: "Bugün")
        case .overdue(let days): String(localized: "\(days) gün geçti")
        case .ended: String(localized: "Bitti")
        }
    }

    var color: Color {
        switch self {
        case .upcoming: .textSecondary
        case .dueToday: .brandPrimaryDeep
        case .overdue: .over
        case .ended: .textSecondary
        }
    }
}

/// Planla > Düzenli Ödemeler grupları (Bölüm 6.2-E).
enum RecurringGroup: Int, CaseIterable, Identifiable {
    case housing
    case digital
    case transport
    case other
    /// Taksiti biten veya durdurulan ödemeler, en altta.
    case ended

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .housing: String(localized: "Konut & Faturalar")
        case .digital: String(localized: "Dijital Abonelikler")
        case .transport: String(localized: "Ulaşım")
        case .other: String(localized: "Diğer")
        case .ended: String(localized: "Biten ödemeler")
        }
    }

    /// Seed kategori adlarına göre; yeniden adlandırılan kategoriler "Diğer"e düşer.
    init(category: Category?) {
        switch category?.name {
        case "Konut", "Faturalar & İletişim": self = .housing
        case "Abonelikler": self = .digital
        case "Ulaşım": self = .transport
        default: self = .other
        }
    }
}
