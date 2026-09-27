import OSLog
import SwiftData
import SwiftUI

@main
struct PocketMoneyApp: App {
    /// Açılamazsa `nil`; uygulama çökmek yerine `StoreUnavailableView` gösterir.
    private let container: ModelContainer?

    init() {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PocketMoney", category: "Persistence")
        do {
            container = try AppModelContainer.make()
        } catch {
            // Depo silinmez veya yeniden oluşturulmaz: bu veriyi kaybettirir (Bölüm 12).
            // Önceden fatalError vardı; şema uyumsuzluğunda uygulama her açılışta çökerdi.
            logger.fault("ModelContainer açılamadı: \(error.localizedDescription, privacy: .public)")
            container = nil
        }
        if let container {
            do {
                try SeedLoader(context: container.mainContext).seedIfNeeded()
            } catch {
                // Seed hatası kullanıcı verisini etkilemez; uygulama açılmaya devam eder.
                logger.error("Seed yüklenemedi: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootTabView()
                    .modelContainer(container)
            } else {
                StoreUnavailableView()
            }
        }
    }
}
