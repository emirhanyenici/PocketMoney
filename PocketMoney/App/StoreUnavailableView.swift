import SwiftUI

/// Veri deposu açılamadığında gösterilir. Depoya dokunmaz, silmez, yeniden
/// oluşturmaz: veri cihazda durur ve düzeltilmiş bir sürümle açılabilir
/// (Bölüm 12: veri asla kaybolmamalı; Bölüm 21: sorun + çözüm, suçlamadan).
struct StoreUnavailableView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Kayıtların şu an açılamıyor", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("Kayıtların silinmedi, bu iPhone'da duruyor. TestFlight'tan uygulamanın en güncel sürümünü yükleyip tekrar aç.")
        }
        .foregroundStyle(Color.textPrimary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }
}

#Preview("Açık mod") {
    StoreUnavailableView()
}

#Preview("Koyu mod") {
    StoreUnavailableView()
        .preferredColorScheme(.dark)
}
