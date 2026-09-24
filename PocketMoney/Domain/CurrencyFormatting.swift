import Foundation

/// Para ve oran biçimleri (Bölüm 13): ₺1.234,56 · %8.
/// Tüm hesaplar `Decimal` ile yapılır; yuvarlama yalnızca gösterimde.
extension Decimal {
    nonisolated static let turkishLocale = Locale(identifier: "tr_TR")

    /// "₺1.234,56"
    nonisolated var tryFormatted: String {
        formatted(.currency(code: "TRY").locale(Self.turkishLocale))
    }

    /// VoiceOver için: 229,99 → "229 lira 99 kuruş" (Bölüm 16). VoiceOver rakamları
    /// Türkçe okur: "iki yüz yirmi dokuz lira doksan dokuz kuruş". Foundation'ın
    /// tam ad biçimi ("₺229,99 Türk lirası") sembolü de okuttuğu için kullanılmaz.
    nonisolated var spokenTRY: String {
        var value = abs(self)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .plain)
        var liraPart = Decimal()
        NSDecimalRound(&liraPart, &rounded, 0, .down)
        let lira = NSDecimalNumber(decimal: liraPart).intValue
        let kurus = NSDecimalNumber(decimal: (rounded - liraPart) * 100).intValue
        let sign = self < 0 ? "−" : ""
        return kurus == 0
            ? String(localized: "\(sign)\(lira) lira")
            : String(localized: "\(sign)\(lira) lira \(kurus) kuruş")
    }

    /// Oranı yüzde olarak biçimler: 0,08 → "%8".
    nonisolated var percentFormatted: String {
        formatted(.percent.precision(.fractionLength(0)).locale(Self.turkishLocale))
    }
}
