import Foundation

/// Düzenli ödemenin fiyat geçmişindeki tek bir değişiklik (Bölüm 9.3):
/// "Fiyat arttı: ₺199,99 → ₺229,99". Geçmiş işlemler bundan etkilenmez.
nonisolated struct PriceChange: Codable, Hashable, Sendable {
    var date: Date
    var oldAmount: Decimal
    var newAmount: Decimal
}
