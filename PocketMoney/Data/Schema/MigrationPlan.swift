import Foundation
import SwiftData

/// Şema geçiş planı (Bölüm 12). TestFlight'taki mevcut veri asla kaybolmamalı:
/// her yeni şema sürümü `schemas` listesine eklenir ve bir önceki sürümden
/// geçiş aşaması `stages` içine yazılır.
nonisolated enum PocketMoneyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
