import Foundation

/// `UserDefaults` / `@AppStorage` anahtarları (Bölüm 12: ayarlar UserDefaults'ta).
/// Anahtarlar kalıcıdır; yeniden adlandırılırsa kullanıcının ayarı kaybolur.
enum AppSettings {
    /// Dönem başlangıç günü, 1–28 (Bölüm 6.2-F). Varsayılan 1 = takvim ayı.
    static let periodStartDayKey = "periodStartDay"
    static let defaultPeriodStartDay = 1
}
