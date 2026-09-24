import OSLog
import SwiftData
import SwiftUI

@main
struct PocketMoneyApp: App {
    private let container: ModelContainer

    init() {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PocketMoney", category: "Persistence")
        do {
            container = try AppModelContainer.make()
        } catch {
            // Veri deposu açılamazsa uygulama çalışamaz. Silip yeniden oluşturmak
            // veriyi kaybettirir (Bölüm 12), bu yüzden bilinçli olarak durulur.
            logger.fault("ModelContainer açılamadı: \(error.localizedDescription, privacy: .public)")
            fatalError("ModelContainer açılamadı: \(error)")
        }
        do {
            try SeedLoader(context: container.mainContext).seedIfNeeded()
        } catch {
            // Seed hatası kullanıcı verisini etkilemez; uygulama açılmaya devam eder.
            logger.error("Seed yüklenemedi: \(error.localizedDescription, privacy: .public)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
