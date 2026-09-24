import Foundation

/// Bütçe dönemi (Bölüm 12). MVP'de yalnızca `.month` kullanılır.
/// Ham değerler kalıcı olarak saklanır; asla yeniden adlandırılmaz.
nonisolated enum BudgetPeriod: String, Codable, CaseIterable, Sendable {
    case month
    case week
    case year
}
