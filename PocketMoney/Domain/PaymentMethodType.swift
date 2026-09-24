import Foundation

/// Ödeme yöntemi türü (Bölüm 12). Kullanıcı aynı türden birden çok yöntem
/// ekleyebilir ("Bonus", "Axess" → ikisi de `.creditCard`).
/// Ham değerler kalıcı olarak saklanır; asla yeniden adlandırılmaz.
nonisolated enum PaymentMethodType: String, Codable, CaseIterable, Sendable {
    case cash
    case creditCard
    case debitCard
    case transfer
    case other
}
