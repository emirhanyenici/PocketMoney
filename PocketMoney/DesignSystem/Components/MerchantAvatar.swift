import SwiftUI

/// Marka baş harfleri + kategori rengi (Bölüm 5.3). Marka logosu kullanılmaz (Bölüm 8, 22).
struct MerchantAvatar: View {
    let name: String
    let colorToken: String?
    var size: CGFloat = 40

    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    var body: some View {
        Text(verbatim: initials)
            .font(.system(size: size * scale * 0.38, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size * scale, height: size * scale)
            .background(Color.category(token: colorToken ?? CategoryColor.stone.rawValue), in: .circle)
            .accessibilityHidden(true)
    }

    /// "Kahve Dünyası" → "KD", "Starbucks" → "ST", "H&M" → "H&".
    private var initials: String {
        let words = name.split(whereSeparator: \.isWhitespace)
        let letters: String = words.count >= 2
            ? words.prefix(2).compactMap(\.first).map(String.init).joined()
            : String(name.prefix(2))
        return letters.uppercased(with: Decimal.turkishLocale)
    }
}

extension MerchantAvatar {
    init(merchant: Merchant, size: CGFloat = 40) {
        let category = merchant.suggestedCategory ?? merchant.lastUsedCategory
        self.init(name: merchant.name, colorToken: category?.colorToken, size: size)
    }
}

#Preview("Açık mod") {
    HStack {
        MerchantAvatar(name: "Kahve Dünyası", colorToken: "cat.caramel")
        MerchantAvatar(name: "Starbucks", colorToken: "cat.caramel")
        MerchantAvatar(name: "İstanbulkart", colorToken: "cat.petrol")
        MerchantAvatar(name: "Köşe Büfe", colorToken: nil)
    }
    .padding()
}

#Preview("Koyu mod") {
    HStack {
        MerchantAvatar(name: "Kahve Dünyası", colorToken: "cat.caramel")
        MerchantAvatar(name: "İstanbulkart", colorToken: "cat.petrol")
    }
    .padding()
    .preferredColorScheme(.dark)
}
