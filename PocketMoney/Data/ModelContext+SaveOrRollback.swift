import Foundation
import OSLog
import SwiftData

extension ModelContext {
    private static let persistenceLogger = Logger(subsystem: "PocketMoney", category: "Persistence")

    /// Kaydeder; başarısız olursa bekleyen tüm değişiklikleri geri alır ve hatayı yeniden fırlatır.
    ///
    /// `mainContext` otomatik kaydettiği için, geri alınmayan yarım değişiklikler
    /// kullanıcı "Kaydedilemedi" gördükten sonra bile sessizce kalıcı olabiliyordu
    /// (Bölüm 12: veri tutarlılığı, Bölüm 15: hatalar OSLog'a).
    func saveOrRollback() throws {
        do {
            try save()
        } catch {
            rollback()
            Self.persistenceLogger.error("Kaydetme başarısız, değişiklikler geri alındı: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}
