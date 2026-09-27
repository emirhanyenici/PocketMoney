import Foundation
import SwiftData
import Testing
@testable import PocketMoney

/// SchemaV1 DONDURULDU (Bölüm 12: TestFlight'taki veri asla kaybolmamalı).
///
/// TestFlight 0.1.0 (1) ve (2) cihazlarda bu şemayla veritabanı oluşturdu.
/// V1 modellerinde alan eklemek/silmek/tip değiştirmek eski veritabanının
/// açılamamasına yol açar. Bu test kırılırsa değişikliği geri al ve bunun
/// yerine: V1'i olduğu gibi bırak, modelleri SchemaV2'ye kopyala, değişikliği
/// orada yap, `PocketMoneyMigrationPlan`'a V1→V2 aşaması ekle, typealias'ları
/// V2'ye çevir. Bu testteki beklenen değer ASLA güncellenmez.
struct SchemaV1FrozenTests {
    private static let frozen = """
    Budget | id:UUID!,isActive:Bool,limit:NSDecimal,periodTypeRaw:String | category->Category
    Category | colorToken:String,id:UUID!,isArchived:Bool,isSystem:Bool,kindRaw:String,name:String,sortOrder:Int,symbolName:String | children->Category[],parent->Category
    Merchant | id:UUID!,isHidden:Bool,isSystem:Bool,lastUsedChannelRaw:Optional<String>?,name:String,searchKey:String | lastUsedCategory->Category,lastUsedPaymentMethod->PaymentMethod,lastUsedSubcategory->Category,suggestedCategory->Category
    PaymentMethod | id:UUID!,name:String,sortOrder:Int,typeRaw:String | 
    RecurringPayment | amount:NSDecimal,dayOfPeriod:Int,endDate:Optional<Date>?,frequencyCustomDays:Optional<Int>?,frequencyKey:String,id:UUID!,isActive:Bool,modeRaw:String,name:String,nextDueDate:Date,priceHistory:Array<PriceChange>,remainingInstallments:Optional<Int>?,reminderDaysBefore:Optional<Int>?,startDate:Date | category->Category,merchant->Merchant,paymentMethod->PaymentMethod,subcategory->Category
    Transaction | amount:NSDecimal,channelRaw:Optional<String>?,createdAt:Date,currencyCode:String,date:Date,id:UUID!,kindRaw:String,localDay:String,note:Optional<String>?,recurringPeriodKey:Optional<String>?,tags:Array<String>,updatedAt:Date | category->Category,merchant->Merchant,paymentMethod->PaymentMethod,recurringPayment->RecurringPayment,subcategory->Category
    """

    /// Şemanın kararlı, sıralı metin dökümü: tablo | alan:tip(?=opsiyonel, !=benzersiz) | ilişki->hedef([]=çoklu)
    private static func describe(_ schema: Schema) -> String {
        schema.entities
            .sorted { $0.name < $1.name }
            .map { entity in
                let attributes = entity.attributes
                    .map { "\($0.name):\($0.valueType)\($0.isOptional ? "?" : "")\($0.isUnique ? "!" : "")" }
                    .sorted()
                let relationships = entity.relationships
                    .map { "\($0.name)->\($0.destination)\($0.isToOneRelationship ? "" : "[]")" }
                    .sorted()
                return "\(entity.name) | " + attributes.joined(separator: ",") + " | " + relationships.joined(separator: ",")
            }
            .joined(separator: "\n")
    }

    @Test func schemaV1IsUnchanged() {
        let current = Self.describe(Schema(versionedSchema: SchemaV1.self))
        #expect(current == Self.frozen, "SchemaV1 değişti. V1 dondurulmuştur; değişikliği SchemaV2'de yap (dosyanın başındaki açıklamaya bak).")
    }

    @Test func schemaV1VersionIsUnchanged() {
        #expect(SchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
    }

    /// Geçiş planı V1'le başlamalı; yeni sürümler sona eklenir, V1 hiç çıkarılmaz.
    @Test func migrationPlanStartsWithV1() {
        #expect(PocketMoneyMigrationPlan.schemas.first.map { ObjectIdentifier($0) } == ObjectIdentifier(SchemaV1.self))
    }
}
