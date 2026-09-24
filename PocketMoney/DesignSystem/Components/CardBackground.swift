import SwiftUI

/// Kart zemini (Bölüm 5.2): köşe 20 `.continuous`, iç boşluk 16.
/// Açık modda minimum gölge. Koyu modda gölge yoktur; yüzey renkleri
/// (`surface`, `surfaceMint`) zaten zeminden açık olduğu için kartı ayırır.
private struct CardBackground: ViewModifier {
    var fill: Color = .surface
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: .rect(cornerRadius: Radius.card, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 8, y: 2)
    }
}

extension View {
    func cardBackground(_ fill: Color = .surface) -> some View {
        modifier(CardBackground(fill: fill))
    }
}
