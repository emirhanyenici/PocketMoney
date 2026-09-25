import Foundation
import SwiftData

/// Marka yönetimi (Bölüm 6.2-F, Bölüm 8): ekle, düzenle, gizle, birleştir.
struct MerchantRepository {
    enum MerchantError: Error, Equatable {
        case emptyName
        case duplicateName
        case mergeIntoSelf
    }

    let context: ModelContext

    /// Aynı arama anahtarına sahip ("sok" = "ŞOK") başka marka var mı.
    func existing(named name: String, excluding: Merchant? = nil) throws -> Merchant? {
        let key = SearchKey.make(from: name)
        return try context.fetch(FetchDescriptor<Merchant>(predicate: #Predicate { $0.searchKey == key }))
            .first { $0 != excluding }
    }

    @discardableResult
    func create(name: String, suggestedCategory: Category? = nil) throws -> Merchant {
        let trimmed = try validatedName(name)
        let merchant = Merchant(name: trimmed, suggestedCategory: suggestedCategory)
        context.insert(merchant)
        try context.save()
        return merchant
    }

    func rename(_ merchant: Merchant, to name: String) throws {
        merchant.rename(to: try validatedName(name, excluding: merchant))
        try context.save()
    }

    /// Gizlenen marka öneri ve aramada çıkmaz; geçmiş işlemlerde görünmeye devam eder.
    func setHidden(_ merchant: Merchant, _ hidden: Bool) throws {
        merchant.isHidden = hidden
        try context.save()
    }

    func setSuggestedCategory(_ merchant: Merchant, _ category: Category?) throws {
        merchant.suggestedCategory = category
        try context.save()
    }

    func transactionCount(for merchant: Merchant) throws -> Int {
        let id = merchant.persistentModelID
        return try context.fetch(FetchDescriptor<Transaction>()).count { $0.merchant?.persistentModelID == id }
    }

    /// Yanlışlıkla iki kez eklenen markayı birleştirir (Bölüm 8): `source`'un tüm
    /// işlemleri ve düzenli ödemeleri `target`'a geçer, `source` silinir.
    /// Hedefte eksik olan öneri bilgileri kaynaktan tamamlanır.
    func merge(_ source: Merchant, into target: Merchant) throws {
        guard source != target else { throw MerchantError.mergeIntoSelf }
        let sourceID = source.persistentModelID

        for transaction in try context.fetch(FetchDescriptor<Transaction>())
        where transaction.merchant?.persistentModelID == sourceID {
            transaction.merchant = target
            transaction.updatedAt = .now
        }
        for payment in try context.fetch(FetchDescriptor<RecurringPayment>())
        where payment.merchant?.persistentModelID == sourceID {
            payment.merchant = target
        }

        if target.suggestedCategory == nil { target.suggestedCategory = source.suggestedCategory }
        if target.lastUsedCategory == nil {
            target.lastUsedCategory = source.lastUsedCategory
            target.lastUsedSubcategory = source.lastUsedSubcategory
        }
        if target.lastUsedChannel == nil { target.lastUsedChannel = source.lastUsedChannel }
        if target.lastUsedPaymentMethod == nil { target.lastUsedPaymentMethod = source.lastUsedPaymentMethod }

        context.delete(source)
        try context.save()
    }

    private func validatedName(_ name: String, excluding: Merchant? = nil) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw MerchantError.emptyName }
        guard try existing(named: trimmed, excluding: excluding) == nil else { throw MerchantError.duplicateName }
        return trimmed
    }
}
