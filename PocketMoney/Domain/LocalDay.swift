import Foundation

/// İşlemin girildiği yerel gün anahtarı: "2026-08-31" (Bölüm 13, saat dilimi kuralı).
///
/// Yurt dışında 31 Ağustos 23:30'da girilen bir harcama, cihaz saat dilimi
/// değişince Eylül'e kaymamalı. Bu yüzden gün, işlem girildiği anda o anki
/// takvimle hesaplanıp saklanır; dönem gruplaması `Date` yerine bu anahtara
/// göre yapılır. Anahtar sözlük sırasıyla kronolojik sıralanır.
nonisolated enum LocalDay {
    /// Bölüm 13: Gregoryen takvim + cihazın o anki saat dilimi.
    static var currentCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    static func key(for date: Date, calendar: Calendar = currentCalendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
