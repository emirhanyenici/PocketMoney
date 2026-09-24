import SwiftUI

/// Kategori renginde daire içinde SF Symbol (Bölüm 5.3).
/// Renk tek başına anlam taşımaz; ikon her zaman bir etiketle birlikte kullanılır (Bölüm 4.4).
struct CategoryIcon: View {
    let symbolName: String
    let colorToken: String
    var size: CGFloat = 40

    /// Dynamic Type ile büyür (Bölüm 16).
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * scale * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size * scale, height: size * scale)
            .background(Color.category(token: colorToken), in: .circle)
            .accessibilityHidden(true)
    }
}

extension CategoryIcon {
    /// İşlemin ana kategorisi için ikon; kategorisizse nötr ikon.
    init(category: Category?, size: CGFloat = 40) {
        self.init(
            symbolName: category?.symbolName ?? "questionmark",
            colorToken: category?.colorToken ?? CategoryColor.stone.rawValue,
            size: size
        )
    }
}

#Preview("Açık mod") {
    HStack {
        CategoryIcon(symbolName: "house.fill", colorToken: "cat.forest")
        CategoryIcon(symbolName: "fork.knife", colorToken: "cat.caramel")
        CategoryIcon(symbolName: "cart.fill", colorToken: "cat.olive", size: 28)
    }
    .padding()
}

#Preview("Koyu mod") {
    HStack {
        CategoryIcon(symbolName: "house.fill", colorToken: "cat.forest")
        CategoryIcon(symbolName: "fork.knife", colorToken: "cat.caramel")
        CategoryIcon(symbolName: "cart.fill", colorToken: "cat.olive", size: 28)
    }
    .padding()
    .preferredColorScheme(.dark)
}
