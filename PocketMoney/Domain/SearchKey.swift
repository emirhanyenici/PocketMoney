import Foundation

/// Türkçe karakter duyarsız arama anahtarı (Bölüm 8): "ŞOK" → "sok",
/// "İstanbulkart" → "istanbulkart", "Caffè Nero" → "caffe nero".
nonisolated enum SearchKey {
    private static let turkish = Locale(identifier: "tr_TR")

    static func make(from text: String) -> String {
        // Türkçe kurallarıyla küçült (I → ı, İ → i), sonra "ı"yı "i"ye çevir:
        // "ı" bir aksan değil ayrı bir harf olduğu için aksan katlama onu yakalamaz.
        let lowered = text.lowercased(with: turkish).replacingOccurrences(of: "ı", with: "i")
        return lowered
            .folding(options: .diacriticInsensitive, locale: turkish)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
