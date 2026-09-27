import Foundation
import SwiftData

/// Şema sürüm 1 — GUIDELINE.md Bölüm 12.
///
/// ⚠️ DONDURULDU (TestFlight 0.1.0 build 1-2 bu şemayla veri oluşturdu).
/// `Data/Models/` altındaki V1 modellerinde alan ekleme/silme/tip değiştirme
/// YAPILMAZ; `SchemaV1FrozenTests` bunu yakalar. Değişiklik gerekiyorsa
/// modelleri SchemaV2'ye kopyala, değişikliği orada yap, geçiş planına
/// V1→V2 aşaması ekle ve aşağıdaki typealias'ları V2'ye çevir.
///
/// Modeller `Data/Models/` altında bu enum'un extension'ları olarak tanımlanır.
/// V2 geldiğinde V1 tipleri migration için olduğu gibi kalır; uygulamanın geri
/// kalanı aşağıdaki typealias'lar sayesinde her zaman güncel şemayı kullanır.
nonisolated enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Transaction.self,
            Category.self,
            Merchant.self,
            PaymentMethod.self,
            RecurringPayment.self,
            Budget.self
        ]
    }
}

// Yeni şema sürümünde bu satırlar SchemaV2'yi gösterecek şekilde güncellenir.
typealias Transaction = SchemaV1.Transaction
typealias Category = SchemaV1.Category
typealias Merchant = SchemaV1.Merchant
typealias PaymentMethod = SchemaV1.PaymentMethod
typealias RecurringPayment = SchemaV1.RecurringPayment
typealias Budget = SchemaV1.Budget
