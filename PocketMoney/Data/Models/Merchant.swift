import Foundation
import SwiftData

extension SchemaV1 {
    /// Marka / mağaza (Bölüm 8). Kategoriyi önerir, belirlemez (Bölüm 2, ilke 8).
    @Model
    final class Merchant {
        @Attribute(.unique) var id: UUID
        var name: String
        /// Küçük harf, Türkçe karakter sadeleştirilmiş (`SearchKey`).
        var searchKey: String
        /// Seed'den gelen öneri. Ana kategori de olabilir alt kategori de
        /// (Shell → Yakıt); alt kategoriyse ana kategori `parent`'tan bulunur.
        var suggestedCategory: Category?
        /// Kullanıcının son seçimi; öneride önceliklidir.
        var lastUsedCategory: Category?
        var lastUsedSubcategory: Category?
        var lastUsedChannelRaw: String?
        var lastUsedPaymentMethod: PaymentMethod?
        var isHidden: Bool
        var isSystem: Bool

        var lastUsedChannel: PurchaseChannel? {
            get { lastUsedChannelRaw.flatMap(PurchaseChannel.init(rawValue:)) }
            set { lastUsedChannelRaw = newValue?.rawValue }
        }

        init(name: String, suggestedCategory: Category? = nil, isSystem: Bool = false) {
            self.id = UUID()
            self.name = name
            self.searchKey = SearchKey.make(from: name)
            self.suggestedCategory = suggestedCategory
            self.isHidden = false
            self.isSystem = isSystem
        }

        /// Adı değiştirir ve arama anahtarını günceller.
        func rename(to newName: String) {
            name = newName
            searchKey = SearchKey.make(from: newName)
        }
    }
}
