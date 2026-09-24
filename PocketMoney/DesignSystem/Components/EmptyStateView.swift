import SwiftUI

/// Boş durum: ikon, tek cümle açıklama, tek buton (Bölüm 3 ilke 7, Bölüm 6.2-I).
/// Örnek/sahte veri gösterilmez.
struct EmptyStateView: View {
    let symbolName: String
    let message: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        ContentUnavailableView {
            Image(systemName: symbolName)
                .font(.system(size: 44))
                .foregroundStyle(Color.brandSecondary)
                .accessibilityHidden(true)
        } description: {
            Text(message)
                .font(.body)
                .foregroundStyle(Color.textSecondary)
        } actions: {
            Button(action: action) {
                Text(actionTitle)
                    .font(.headline)
                    .padding(.horizontal, Spacing.xs)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: Radius.button))
            .tint(.brandPrimary)
            .foregroundStyle(Color.textOnPrimary)
            .controlSize(.large)
        }
    }
}

#Preview("Açık mod") {
    EmptyStateView(
        symbolName: "tray",
        message: "Bu ay henüz harcama yok. İlkini eklemek 5 saniye sürer.",
        actionTitle: "İlk harcamanı ekle",
        action: {}
    )
    .background(Color.background)
}

#Preview("Koyu mod") {
    EmptyStateView(
        symbolName: "tray",
        message: "Bu ay henüz harcama yok. İlkini eklemek 5 saniye sürer.",
        actionTitle: "İlk harcamanı ekle",
        action: {}
    )
    .background(Color.background)
    .preferredColorScheme(.dark)
}
