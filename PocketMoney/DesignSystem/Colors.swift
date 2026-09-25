import SwiftUI

// Renk tokenları — GUIDELINE.md Bölüm 4.
//
// Tüm tokenlar Assets.xcassets içinde açık/koyu varyantlı Color Set olarak
// tanımlıdır. Xcode bunlardan derleme zamanında `Color.brandPrimary`,
// `Color.textSecondary` gibi statik erişimciler üretir; bu yüzden burada elle
// yeniden tanımlanmazlar (yeniden tanım derleme hatası verir). Kodda asla hex
// yazılmaz, yalnızca bu tokenlar kullanılır.
//
// Bölüm 4.1 — Marka ve yüzey:
//   .brandPrimary      Ana butonlar, seçili tab, vurgular
//   .brandPrimaryDeep  Başlıklar, büyük tutar rakamları
//   .brandSecondary    İkincil vurgular, grafik ikincil çizgi
//   .brandMint         Seçili chip zemini, ilerleme çubuğu dolgusu
//   .surfaceMint       Özet kartı zemini
//   .background        Ekran zemini
//   .surface           Kartlar, listeler
//   .surfaceElevated   Sheet, modal, klavye üstü panel
//   .divider           Ayraç çizgileri
//
// Bölüm 4.2 — Metin:
//   .textPrimary       Ana metin, tutarlar
//   .textSecondary     Açıklama, tarih, alt başlık
//   .textTertiary      Placeholder, pasif
//   .textOnPrimary     Yeşil buton üstü metin
//
// Bölüm 4.3 — Durum:
//   .income            Gelir tutarları
//   .expense           Gider tutarları — bilinçli olarak nötr (.textPrimary ile aynı)
//   .warning           Bütçenin %80'i aşıldı
//   .over              Bütçe aşıldı, gecikmiş ödeme
//   .info              Bilgi notları
//
// Bölüm 4.4 — Kategori paleti: aşağıdaki `CategoryColor`.

// MARK: - 4.4 Kategori paleti

/// Kategori renkleri. `rawValue`, veri modelindeki `Category.colorToken`
/// (Bölüm 12) ile birebir aynıdır; kayıtlı token doğrudan renge çevrilebilir.
///
/// Koyu mod varyantları Asset Catalog'da ~%15 açılmış olarak tanımlıdır.
/// Renk asla tek başına anlam taşımaz; her zaman ikon + etiket eşlik eder.
enum CategoryColor: String, CaseIterable {
    /// Orman — Konut
    case forest = "cat.forest"
    /// Petrol — Ulaşım
    case petrol = "cat.petrol"
    /// Zeytin — Market & Gıda
    case olive = "cat.olive"
    /// Karamel — Yeme & İçme
    case caramel = "cat.caramel"
    /// Gül Kurusu — Kozmetik & Kişisel Bakım
    case rose = "cat.rose"
    /// Lavanta — Giyim & Aksesuar
    case lavender = "cat.lavender"
    /// Deniz — Elektronik & Teknoloji
    case sea = "cat.sea"
    /// Hardal — Abonelikler
    case mustard = "cat.mustard"
    /// Mercan — Eğlence & Sosyal
    case coral = "cat.coral"
    /// Nane — Sağlık
    case mint = "cat.mint"
    /// Toprak — Ev & Yaşam
    case earth = "cat.earth"
    /// Gri Taş — Diğer
    case stone = "cat.stone"

    /// Renk seçicide VoiceOver ve etiket için ad (Bölüm 4.4).
    var title: String {
        switch self {
        case .forest: String(localized: "Orman")
        case .petrol: String(localized: "Petrol")
        case .olive: String(localized: "Zeytin")
        case .caramel: String(localized: "Karamel")
        case .rose: String(localized: "Gül kurusu")
        case .lavender: String(localized: "Lavanta")
        case .sea: String(localized: "Deniz")
        case .mustard: String(localized: "Hardal")
        case .coral: String(localized: "Mercan")
        case .mint: String(localized: "Nane")
        case .earth: String(localized: "Toprak")
        case .stone: String(localized: "Gri taş")
        }
    }

    var color: Color {
        switch self {
        case .forest: .catForest
        case .petrol: .catPetrol
        case .olive: .catOlive
        case .caramel: .catCaramel
        case .rose: .catRose
        case .lavender: .catLavender
        case .sea: .catSea
        case .mustard: .catMustard
        case .coral: .catCoral
        case .mint: .catMint
        case .earth: .catEarth
        case .stone: .catStone
        }
    }
}

extension Color {
    /// Kategori paletinden renk üretir.
    static func category(_ token: CategoryColor) -> Color {
        token.color
    }

    /// Kayıtlı bir `colorToken` değerinden renk üretir.
    /// Token tanınmıyorsa nötr "Gri Taş" rengine düşer.
    static func category(token: String) -> Color {
        (CategoryColor(rawValue: token) ?? .stone).color
    }
}
