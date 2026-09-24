import Foundation

/// Alışveriş kanalı. Kategoriden ve markadan ayrı bir kavramdır (Bölüm 2, ilke 8).
/// Ham değerler kalıcı olarak saklanır; asla yeniden adlandırılmaz.
nonisolated enum PurchaseChannel: String, Codable, CaseIterable, Sendable {
    case inStore
    case online
}
