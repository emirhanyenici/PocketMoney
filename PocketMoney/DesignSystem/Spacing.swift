import CoreGraphics

/// Boşluk ölçeği (Bölüm 5.2): 4, 8, 12, 16, 20, 24, 32.
/// Saf sabitler; `Layout` gibi main actor dışı bağlamlarda da kullanılabilsin.
nonisolated enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    /// Ekran kenar boşluğu.
    static let screen: CGFloat = m
    /// Kart iç boşluğu.
    static let card: CGFloat = m
}

/// Köşe yarıçapları (Bölüm 5.2). Tümü `.continuous` stil ile kullanılır.
nonisolated enum Radius {
    static let card: CGFloat = 20
    static let button: CGFloat = 14
}
