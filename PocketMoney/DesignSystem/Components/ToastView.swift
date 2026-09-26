import SwiftUI

/// Kısa ve sakin onay/geri al bildirimi (Bölüm 5.4, Bölüm 6.2-B).
struct Toast: Identifiable {
    let id = UUID()
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    /// "Geri al" seçeneği olan bildirimler 5 sn görünür (Bölüm 5.4).
    var duration: Duration { action == nil ? .seconds(2) : .seconds(5) }
}

struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            Text(verbatim: toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textPrimary)
            if let title = toast.actionTitle, let action = toast.action {
                Button {
                    // Önce kapat, sonra eylemi çalıştır: eylem yeni bir toast
                    // gösterirse ("Geri alınamadı") o hemen silinmesin.
                    onDismiss()
                    action()
                } label: {
                    Text(verbatim: title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                        .frame(minHeight: 44)
                }
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xs)
        .background(Color.surfaceElevated, in: .capsule)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Açık mod") {
    VStack(spacing: 20) {
        ToastView(toast: Toast(message: "Kaydedildi"), onDismiss: {})
        ToastView(toast: Toast(message: "Silindi", actionTitle: "Geri al", action: {}), onDismiss: {})
    }
    .padding()
    .background(Color.background)
}

#Preview("Koyu mod") {
    VStack(spacing: 20) {
        ToastView(toast: Toast(message: "Kaydedildi"), onDismiss: {})
        ToastView(toast: Toast(message: "Silindi", actionTitle: "Geri al", action: {}), onDismiss: {})
    }
    .padding()
    .background(Color.background)
    .preferredColorScheme(.dark)
}
