import Foundation

/// Yönetim ekranlarındaki hataların kullanıcı metni. Bölüm 21: hata mesajı hem
/// sorunu hem çözümü söyler, suçlamaz.
enum ManagementErrorMessage {
    static func text(for error: Error) -> String {
        switch error {
        case CategoryRepository.CategoryError.emptyName, MerchantRepository.MerchantError.emptyName:
            String(localized: "Ad boş kalamaz. Bir ad yaz.")
        case CategoryRepository.CategoryError.duplicateName:
            String(localized: "Bu adda bir kategori zaten var. Başka bir ad dene.")
        case MerchantRepository.MerchantError.duplicateName:
            String(localized: "Bu adda bir marka zaten var. Aynı markaysa birleştirebilirsin.")
        case CategoryRepository.CategoryError.moveTargetRequired:
            String(localized: "Kayıtların nereye taşınacağını seç, sonra tekrar dene.")
        case CategoryRepository.CategoryError.invalidMoveTarget, CategoryRepository.CategoryError.kindMismatch:
            String(localized: "Bu kategoriye taşınamaz. Başka bir kategori seç.")
        case MerchantRepository.MerchantError.mergeIntoSelf:
            String(localized: "Bir marka kendisiyle birleştirilemez. Başka bir marka seç.")
        default:
            String(localized: "Kaydedilemedi. Tekrar dene.")
        }
    }
}
