import Foundation

/// Düzenli ödemenin vadesi geldiğinde ne olacağı (Bölüm 9.1).
/// Varsayılan `.confirm`: uygulama ödeme yapılmış gibi davranmaz (Bölüm 2, ilke 9).
/// Ham değerler kalıcı olarak saklanır; asla yeniden adlandırılmaz.
nonisolated enum RecurringMode: String, Codable, CaseIterable, Sendable {
    /// Hatırlatır; kullanıcı "Ödendi" deyince işlem oluşur.
    case confirm
    /// Vadesi gelince işlem kendiliğinden oluşur, tek dokunuşla geri alınabilir.
    case autoPost
}
