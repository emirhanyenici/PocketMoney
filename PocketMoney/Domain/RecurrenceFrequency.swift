import Foundation

/// Düzenli ödeme periyodu (Bölüm 9.1).
///
/// `.customDays(Int)` ilişkili değer taşıdığı için model bu enum'u doğrudan
/// saklamaz; `storageKey` + `customDays` olarak iki sade alana ayırır.
/// Böylece SwiftData'nın ilişkili değerli enum desteğine bağımlı kalınmaz ve
/// alanlar sorgulanabilir kalır.
nonisolated enum RecurrenceFrequency: Hashable, Sendable {
    case weekly
    case monthly
    case quarterly
    case semiannual
    case yearly
    /// Her N günde bir. N en az 1'dir.
    case customDays(Int)

    /// Kalıcı olarak saklanan anahtar. Asla yeniden adlandırılmaz.
    var storageKey: String {
        switch self {
        case .weekly: "weekly"
        case .monthly: "monthly"
        case .quarterly: "quarterly"
        case .semiannual: "semiannual"
        case .yearly: "yearly"
        case .customDays: "customDays"
        }
    }

    /// Yalnızca `.customDays` için dolu.
    var customDays: Int? {
        if case .customDays(let days) = self { days } else { nil }
    }

    /// Saklanan iki alandan periyodu geri kurar.
    /// Tanınmayan anahtar ya da geçersiz gün sayısı `nil` döner.
    init?(storageKey: String, customDays: Int?) {
        switch storageKey {
        case "weekly": self = .weekly
        case "monthly": self = .monthly
        case "quarterly": self = .quarterly
        case "semiannual": self = .semiannual
        case "yearly": self = .yearly
        case "customDays":
            guard let customDays, customDays >= 1 else { return nil }
            self = .customDays(customDays)
        default: return nil
        }
    }
}
