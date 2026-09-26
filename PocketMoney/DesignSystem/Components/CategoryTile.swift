import SwiftUI

/// Kategori ızgarasındaki kutu: ikon + ad. Seçili durumda nane zemin ve yeşil kenarlık.
/// Yatay kaydırmalı çiplerin yerine; her seçenek görünür (Bölüm 22 karar kaydı).
struct CategoryTile: View {
    let title: String
    let symbolName: String
    /// `nil` ise ikon kategori renginde değil, nötr çerçeveli gösterilir ("Tümü" gibi).
    let colorToken: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs + 2) {
                icon
                Text(verbatim: title)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.brandPrimaryDeep : Color.textPrimary)
                    .multilineTextAlignment(.center)
                    // İki satır yer her kutuda ayrılır; kutular ve ikonlar aynı hizada kalır.
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.xxs)
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .top)
            .background(isSelected ? Color.brandMint : Color.surface,
                        in: .rect(cornerRadius: Radius.button, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .strokeBorder(isSelected ? Color.brandPrimary : Color.divider, lineWidth: 1)
            }
            .contentShape(.rect(cornerRadius: Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var icon: some View {
        if let colorToken {
            CategoryIcon(symbolName: symbolName, colorToken: colorToken, size: 36)
        } else {
            Image(systemName: symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 36, height: 36)
                .overlay { Circle().strokeBorder(Color.divider, lineWidth: 1) }
                .accessibilityHidden(true)
        }
    }
}

#Preview("Açık mod") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
        CategoryTile(title: "Market & Gıda", symbolName: "cart.fill", colorToken: "cat.olive", isSelected: true) {}
        CategoryTile(title: "Kozmetik & Kişisel Bakım", symbolName: "sparkles", colorToken: "cat.rose", isSelected: false) {}
        CategoryTile(title: "Ulaşım", symbolName: "car.fill", colorToken: "cat.petrol", isSelected: false) {}
        CategoryTile(title: "Tümü", symbolName: "square.grid.2x2", colorToken: nil, isSelected: false) {}
    }
    .padding()
    .background(Color.surfaceElevated)
}

#Preview("Koyu mod") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
        CategoryTile(title: "Market & Gıda", symbolName: "cart.fill", colorToken: "cat.olive", isSelected: true) {}
        CategoryTile(title: "Tümü", symbolName: "square.grid.2x2", colorToken: nil, isSelected: false) {}
    }
    .padding()
    .background(Color.surfaceElevated)
    .preferredColorScheme(.dark)
}
