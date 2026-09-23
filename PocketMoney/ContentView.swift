import SwiftUI

/// Geçici geliştirici ekranı: GUIDELINE.md Bölüm 4 renk tokenlarını ve
/// Bölüm 5.1 tipografi stillerini açık/koyu modda gözle doğrulamak için.
/// v0.1 ilerledikçe yerini `RootTabView` alacak.
///
/// Buradaki metinler bilinçli olarak `Text(verbatim:)` ile yazılır: token
/// adları ve stil etiketleri kullanıcıya görünen metin değildir, bu yüzden
/// `Localizable.xcstrings` içine çıkarılmamalıdır (Bölüm 15).
struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TypographySection()
                    ColorSection(title: "Marka ve yüzey", tokens: Self.brandTokens)
                    ColorSection(title: "Metin renkleri", tokens: Self.textTokens)
                    ColorSection(title: "Durum renkleri", tokens: Self.statusTokens)
                    CategoryPaletteSection()
                }
                .padding(16)
            }
            .background(Color.background)
            .navigationTitle(Text(verbatim: "Tasarım Tokenları"))
        }
        .tint(.brandPrimary)
    }

    // MARK: - Token listeleri (Bölüm 4)

    private static let brandTokens: [ColorToken] = [
        .init(name: "brandPrimary", usage: "Ana buton, seçili tab", color: .brandPrimary),
        .init(name: "brandPrimaryDeep", usage: "Başlık, büyük tutar", color: .brandPrimaryDeep),
        .init(name: "brandSecondary", usage: "İkincil vurgu", color: .brandSecondary),
        .init(name: "brandMint", usage: "Seçili chip zemini", color: .brandMint),
        .init(name: "surfaceMint", usage: "Özet kartı zemini", color: .surfaceMint),
        .init(name: "background", usage: "Ekran zemini", color: .background),
        .init(name: "surface", usage: "Kart, liste", color: .surface),
        .init(name: "surfaceElevated", usage: "Sheet, modal", color: .surfaceElevated),
        .init(name: "divider", usage: "Ayraç çizgisi", color: .divider)
    ]

    private static let textTokens: [ColorToken] = [
        .init(name: "textPrimary", usage: "Ana metin, tutarlar", color: .textPrimary),
        .init(name: "textSecondary", usage: "Açıklama, tarih", color: .textSecondary),
        .init(name: "textTertiary", usage: "Placeholder, pasif", color: .textTertiary),
        .init(name: "textOnPrimary", usage: "Yeşil buton üstü metin", color: .textOnPrimary)
    ]

    private static let statusTokens: [ColorToken] = [
        .init(name: "income", usage: "Gelir tutarları", color: .income),
        .init(name: "expense", usage: "Gider — nötr renk", color: .expense),
        .init(name: "warning", usage: "Bütçenin %80'i aşıldı", color: .warning),
        .init(name: "over", usage: "Bütçe aşıldı, gecikme", color: .over),
        .init(name: "info", usage: "Bilgi notları", color: .info)
    ]
}

// MARK: - Bölüm 5.1 Tipografi

private struct TypographySection: View {
    private var sampleAmount: String {
        Decimal(18450).formatted(.currency(code: "TRY").locale(Locale(identifier: "tr_TR")))
    }

    var body: some View {
        TokenCard(title: "Tipografi") {
            VStack(alignment: .leading, spacing: 16) {
                sample("Hero tutar", ".largeTitle · bold · rounded") {
                    Text(sampleAmount)
                        .font(.largeTitle.bold())
                        .fontDesign(.rounded)
                        .monospacedDigit()
                        .foregroundStyle(Color.brandPrimaryDeep)
                }
                sample("Ekran başlığı", ".title2 · semibold") {
                    Text(verbatim: "Bu ay ne harcadım?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                }
                sample("Kart başlığı", ".headline") {
                    Text(verbatim: "Sabit giderler")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                sample("Gövde", ".body") {
                    Text(verbatim: "Market & Gıda · Süpermarket")
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                }
                sample("Tutar (liste)", ".body · semibold · monospacedDigit") {
                    Text(sampleAmount)
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.expense)
                }
                sample("Yardımcı", ".footnote / .caption") {
                    Text(verbatim: "23 Eylül 2026 · Kredi kartı")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private func sample(
        _ title: String,
        _ spec: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: "\(title) — \(spec)")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Bölüm 4 renk bölümleri

private struct ColorToken: Identifiable {
    let name: String
    let usage: String
    let color: Color

    var id: String { name }
}

private struct ColorSection: View {
    let title: String
    let tokens: [ColorToken]

    var body: some View {
        TokenCard(title: title) {
            VStack(spacing: 12) {
                ForEach(tokens) { token in
                    HStack(spacing: 12) {
                        Swatch(color: token.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(token.name)
                                .font(.body)
                                .foregroundStyle(Color.textPrimary)
                            Text(token.usage)
                                .font(.footnote)
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

private struct CategoryPaletteSection: View {
    var body: some View {
        TokenCard(title: "Kategori paleti") {
            VStack(spacing: 12) {
                ForEach(CategoryColor.allCases, id: \.self) { token in
                    HStack(spacing: 12) {
                        Swatch(color: token.color)
                        Text(token.rawValue)
                            .font(.body)
                            .foregroundStyle(Color.textPrimary)
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

// MARK: - Yardımcı görünümler (Bölüm 5.2 boşluk ve köşe ölçeği)

/// Açık renkli tokenların krem zemin üzerinde kaybolmaması için kenarlıklı kutu.
private struct Swatch: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(color)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.divider, lineWidth: 1)
            }
            .frame(width: 56, height: 40)
    }
}

private struct TokenCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.brandPrimaryDeep)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: .rect(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

#Preview("Açık mod") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Koyu mod") {
    ContentView()
        .preferredColorScheme(.dark)
}
