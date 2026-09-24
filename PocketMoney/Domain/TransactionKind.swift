import Foundation

/// İşlemin ya da kategorinin yönü (Bölüm 12).
/// Ham değerler kalıcı olarak saklanır; asla yeniden adlandırılmaz.
nonisolated enum TransactionKind: String, Codable, CaseIterable, Sendable {
    case expense
    case income
}
