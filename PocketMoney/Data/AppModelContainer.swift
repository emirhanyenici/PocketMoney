import Foundation
import SwiftData

/// Uygulamanın tek `ModelContainer` kurulum noktası (Bölüm 12, Bölüm 13).
/// Önizleme ve testler aynı şemayı ve geçiş planını `inMemory: true` ile kullanır.
enum AppModelContainer {
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(
            for: schema,
            migrationPlan: PocketMoneyMigrationPlan.self,
            configurations: [configuration]
        )
    }

    #if DEBUG
    /// `#Preview`'lar için seed ve örnek işlemler yüklenmiş bellek içi container (Bölüm 15).
    static func preview(withTransactions: Bool = true) -> ModelContainer {
        do {
            let container = try make(inMemory: true)
            try SeedLoader(context: container.mainContext).seedIfNeeded()
            if withTransactions {
                try PreviewSampleData.insertTransactions(into: container.mainContext)
            }
            return container
        } catch {
            fatalError("Önizleme container'ı kurulamadı: \(error)")
        }
    }
    #endif
}
