# Cüzdan Defteri — iOS Gider Takip Uygulaması Guideline

> Kişisel kullanım için, yalnızca iOS'ta çalışan, verisi cihazda kalan, TestFlight üzerinden dağıtılan aylık harcama takip uygulaması.
> Bu doküman ürün, tasarım ve teknik kararların tek referans noktasıdır. Uygulama adı çalışma adıdır, değiştirilebilir.

---

## İçindekiler

1. [Ürün Vizyonu](#1-ürün-vizyonu)
2. [Referans Uygulamalardan Çıkarımlar](#2-referans-uygulamalardan-çıkarımlar)
3. [Tasarım İlkeleri](#3-tasarım-ilkeleri)
4. [Renk Sistemi](#4-renk-sistemi)
5. [Tipografi, Boşluk ve Bileşenler](#5-tipografi-boşluk-ve-bileşenler)
6. [Bilgi Mimarisi ve Ekranlar](#6-bilgi-mimarisi-ve-ekranlar)
7. [Kategori Yapısı](#7-kategori-yapısı)
8. [Marka / Mağaza (Merchant) Kataloğu](#8-marka--mağaza-merchant-kataloğu)
9. [Düzenli Ödemeler ve Abonelikler](#9-düzenli-ödemeler-ve-abonelikler)
10. [Bütçeler](#10-bütçeler)
11. [Raporlar ve Grafikler](#11-raporlar-ve-grafikler)
12. [Veri Modeli](#12-veri-modeli)
13. [Teknik Mimari](#13-teknik-mimari)
14. [Proje Klasör Yapısı](#14-proje-klasör-yapısı)
15. [Kod Standartları](#15-kod-standartları)
16. [Erişilebilirlik ve Yerelleştirme](#16-erişilebilirlik-ve-yerelleştirme)
17. [Gizlilik ve Güvenlik](#17-gizlilik-ve-güvenlik)
18. [Yol Haritası (Sürümler)](#18-yol-haritası-sürümler)
19. [Test ve TestFlight Süreci](#19-test-ve-testflight-süreci)
20. [Tanım Kontrol Listesi (Definition of Done)](#20-tanım-kontrol-listesi-definition-of-done)
21. [Metin Tonu ve Mikro Metinler](#21-metin-tonu-ve-mikro-metinler)
22. [Karar Kaydı](#22-karar-kaydı)

---

## 1. Ürün Vizyonu

**Tek cümle:** "Paramın her ay nereye gittiğini 5 saniyede girip, 5 saniyede görebileyim."

### Temel sorular (uygulama her zaman bunlara cevap vermeli)
- Bu ay toplam ne harcadım, geçen aya göre nasılım?
- (Gelir girildiyse) Bu ay elime geçenden ne kadarı kaldı?
- En çok hangi kategoriye / hangi markaya harcadım?
- Sabit giderlerim (kira, faturalar, abonelikler) ne kadar tutuyor ve ne zaman ödenecek?
- Belirlediğim bütçenin neresindeyim?

### Hedef kullanıcı
- Birincil: Uygulamanın sahibi (tek kullanıcı, Türkiye, TRY).
- İkincil: TestFlight üzerinden davet edilen birkaç yakın kişi.

### Kapsam dışı (bilinçli olarak)
- Banka bağlantısı / açık bankacılık yok. Tüm veri manuel veya yarı otomatik girilir.
- Sunucu, hesap açma, giriş ekranı yok.
- Reklam, ödeme duvarı (paywall), premium katman yok.
- Android yok.

---

## 2. Referans Uygulamalardan Çıkarımlar

| Uygulama | Güçlü yanı (alıyoruz) | Zayıf yanı / şikâyet (kaçınıyoruz) |
|---|---|---|
| **Monefy** | Tek dokunuşla kayıt; sadece tutar zorunlu. Ana ekranda halka (donut) grafik ile anlık dağılım. Hesap makinesi entegre tuş takımı. | Kategori özelleştirme gibi temel şeylerin ücretli olması kullanıcıyı kızdırıyor. |
| **Money Manager (Bills & Budget)** | Ana + alt kategori, bütçe aşım uyarıları, fatura etiketleme ve hatırlatıcı, sevimli ve sıcak görsel dil. | Alt kategori ayarı bulunamıyor (keşfedilebilirlik sorunu). Tekrarlayan gider isteniyor ama ücretli. |
| **Money Tracker** | Düzenli (tekrarlayan) ödemeler kullanıcıların en sevdiği özellik. Yaklaşan ödemelerin nakit akışına etkisi. Etiket (hashtag), dışa aktarma. | Özel dönem (maaş gününden maaş gününe) takibi isteniyor; tekrarlayan kayıt sayısı sınırlı. |
| **My Budget (Daily Expense)** | Donut + bar grafik ikilisi, 170+ kategori ikonu, gelişmiş arama, PDF/CSV dışa aktarma, parmak izi/şifre kilidi. | Çok fazla özellik tek ekranda karmaşıklaşabiliyor. |
| **PocketPal** | Banka bağlantısı yok, veri cihazda. Maaş gününe senkron dönemler. "Suçluluk değil seri (streak)" yaklaşımı. Fiş tarama. | Zarf bütçeleme yöntemi ilk kullanımda öğrenme eğrisi yaratıyor. |

> Not: Bu çıkarımlar uygulamaların mağaza açıklamalarına ve kullanıcı yorumlarına dayanır; uygulamaların iOS sürümleri birebir incelenmemiştir. Amaç kopyalamak değil, ortak kullanıcı ihtiyaçlarını Türkçe ve yerel bir akışa uyarlamaktır.

### Bizim sentezimiz
1. **Hızlı giriş her şeyden önce gelir** (Monefy): Tutar → kategori → kaydet. Gerisi opsiyonel.
2. **Düzenli ödemeler birinci sınıf vatandaştır** (Money Tracker): Kira, fatura, Netflix, iCloud tek yerde; vadesi gelince hatırlatılır, istenirse otomatik kaydedilir.
3. **Marka seviyesinde detay** (bize özel): "Giyim" değil, "Giyim → Zara (online)" diyebilmek.
4. **Dönem esnekliği** (PocketPal, Money Tracker): Ay başı yerine maaş gününden başlayan dönem.
5. **Alt kategoriler keşfedilebilir olmalı** (Money Manager dersi): Ayar menüsüne gömülmez, giriş ekranında görünür.
6. **Hiçbir temel özellik kilitli değildir.**
7. **Yargılamayan dil:** Harcamalar kırmızıyla bağırmaz; sadece bütçe aşıldığında yumuşak bir uyarı rengi kullanılır.
8. **Kategori, marka ve kanal üç ayrı kavramdır:** Zara bir *marka*, Giyim bir *kategori*, Online bir *kanal*dır. Online giyim alışverişi hem "Giyim" hem "Online" filtresinde bulunur. Marka kategoriyi *önerir*, *belirlemez* (Koton'dan kozmetik de alınabilir).
9. **Uygulama senin yerine ödeme yapmış gibi davranmaz:** Düzenli ödemeler varsayılan olarak hatırlatır, kullanıcı "Ödendi" deyince işlem oluşur.

---

## 3. Tasarım İlkeleri

1. **Sakin, göz yormayan:** Krem/beyaz zeminler, koyu yeşil vurgular. Saf siyah (#000) ve saf beyaz üstüne neon renk yok.
2. **Veri önce, süs sonra:** Her ekranın bir ana sayısı vardır (örn. "Bu ay ₺18.450"). Büyük, net, okunaklı.
3. **Az dokunuş:** Yeni harcama en fazla 3 dokunuşla kaydedilebilmeli.
4. **Tutarlılık:** Aynı kategori her yerde aynı renk + aynı ikon.
5. **iOS yerliliği:** Apple Human Interface Guidelines'a uyum; SF Symbols, sistem sheet'leri, swipe aksiyonları, haptik geri bildirim.
6. **Karanlık mod baştan düşünülür**, sonradan eklenmez.
7. **Boş durumlar (empty state) güzeldir:** Veri yokken kullanıcıyı yönlendiren kısa metin + tek buton.

---

## 4. Renk Sistemi

Paranın çağrıştırdığı yeşiller, krem ve beyazla yumuşatılır. Tüm renkler Asset Catalog'da **isimli renk** (Color Set) olarak, açık/koyu varyantlarıyla tanımlanır. Kodda asla hex yazılmaz, `Color.brandPrimary` gibi token kullanılır.

### 4.1 Marka ve yüzey renkleri

| Token | Açık mod | Koyu mod | Kullanım |
|---|---|---|---|
| `brandPrimary` | `#1E5B3A` Orman Yeşili | `#6FBF8E` | Ana butonlar, seçili tab, vurgular |
| `brandPrimaryDeep` | `#143D28` Derin Yeşil | `#A8D8B9` | Başlıklar, büyük tutar rakamları |
| `brandSecondary` | `#7FA88A` Adaçayı | `#5E8C6C` | İkincil vurgular, grafik ikincil çizgi |
| `brandMint` | `#CFE8D5` Nane | `#24402F` | Seçili chip zemini, ilerleme çubuğu dolgusu |
| `surfaceMint` | `#E8F3EA` Açık Nane | `#1B2E22` | Özet kartı zemini |
| `background` | `#F7F3EA` Krem | `#0F1A14` | Ekran zemini |
| `surface` | `#FFFDF8` Fildişi | `#17241C` | Kartlar, listeler |
| `surfaceElevated` | `#FFFFFF` Beyaz | `#1E2E24` | Sheet, modal, klavye üstü panel |
| `divider` | `#E4DED1` | `#2A3A30` | Ayraç çizgileri |

### 4.2 Metin renkleri

| Token | Açık mod | Koyu mod | Kullanım |
|---|---|---|---|
| `textPrimary` | `#1F2A24` Mürekkep | `#EAF2EC` | Ana metin, tutarlar |
| `textSecondary` | `#5E6B63` | `#A3B3A8` | Açıklama, tarih, alt başlık |
| `textTertiary` | `#8C978F` | `#6F7F74` | Placeholder, pasif |
| `textOnPrimary` | `#FFFFFF` | `#0F1A14` | Yeşil buton üstü metin |

### 4.3 Durum renkleri (yumuşatılmış)

| Token | Açık mod | Koyu mod | Kullanım |
|---|---|---|---|
| `income` | `#2E7D4F` | `#7FD1A0` | Gelir tutarları |
| `expense` | `textPrimary` | `textPrimary` | Giderler **nötr** renkte gösterilir |
| `warning` | `#D9A441` Bal | `#E6B964` | Bütçenin %80'i aşıldı |
| `over` | `#C8553D` Kiremit | `#E07A63` | Bütçe aşıldı, gecikmiş ödeme |
| `info` | `#4F7C8A` | `#8DB5C2` | Bilgi notları |

### 4.4 Kategori paleti

Kategori renkleri doygunluğu düşük, yeşil ana temayla uyumlu bir paletten seçilir. Grafiklerde yan yana geldiklerinde ayırt edilebilir olmalıdır.

| # | Renk | Hex | Önerilen kategori |
|---|---|---|---|
| 1 | Orman | `#2F6B4F` | Konut |
| 2 | Petrol | `#3F7A8C` | Ulaşım |
| 3 | Zeytin | `#7A8B3E` | Market & Gıda |
| 4 | Karamel | `#B7834A` | Yeme & İçme |
| 5 | Gül Kurusu | `#B86B77` | Kozmetik & Kişisel Bakım |
| 6 | Lavanta | `#7D6FA8` | Giyim & Aksesuar |
| 7 | Deniz | `#4C6FA0` | Elektronik & Teknoloji |
| 8 | Hardal | `#C9A13B` | Abonelikler |
| 9 | Mercan | `#C7765B` | Eğlence & Sosyal |
| 10 | Nane | `#5FA38A` | Sağlık |
| 11 | Toprak | `#8C6E55` | Ev & Yaşam |
| 12 | Gri Taş | `#7C8781` | Diğer |

Koyu modda bu renkler ~%15 açılarak kullanılır. Renk asla tek başına anlam taşımaz; her zaman ikon + etiket eşlik eder.

### 4.5 Kontrast kuralı
Tüm metin/zemin çiftleri WCAG AA (normal metin 4.5:1, büyük metin 3:1) oranını geçmelidir. Yeni renk eklendiğinde kontrast kontrol edilir.

---

## 5. Tipografi, Boşluk ve Bileşenler

### 5.1 Tipografi
- Font: **SF Pro** (sistem). Büyük tutarlar için **SF Pro Rounded** (`.fontDesign(.rounded)`) sıcak ve paraya uygun bir his verir.
- Tutarlarda **eş genişlikli rakam** kullanılır: `.monospacedDigit()` — liste hizalaması bozulmaz.
- Dynamic Type zorunlu; sabit punto yok.

| Stil | SwiftUI | Kullanım |
|---|---|---|
| Hero tutar | `.largeTitle`, bold, rounded | Ana ekrandaki aylık toplam |
| Ekran başlığı | `.title2`, semibold | Ekran başlıkları |
| Kart başlığı | `.headline` | Kart başlıkları |
| Gövde | `.body` | Liste satırları |
| Tutar (liste) | `.body`, semibold, monospacedDigit | İşlem tutarları |
| Yardımcı | `.footnote` / `.caption` | Tarih, not, etiket |

### 5.2 Boşluk ve köşe
- Boşluk ölçeği (pt): `4, 8, 12, 16, 20, 24, 32`
- Ekran kenar boşluğu: `16`
- Kart iç boşluğu: `16`
- Köşe yarıçapı: kart `20`, buton `14`, chip `999` (kapsül). Tümü `.continuous` stil.
- Gölge: minimum; açık modda `y:2, blur:8, opacity:0.06`. Koyu modda gölge yerine hafif açık yüzey rengi.

### 5.3 Temel bileşenler (Design System)
- `AmountText` — TRY formatlı, rounded, monospaced tutar.
- `CategoryIcon` — renkli daire içinde SF Symbol.
- `MerchantAvatar` — marka baş harfleri + kategori rengi (marka logosu **kullanılmaz**).
- `SummaryCard` — başlık, ana tutar, karşılaştırma satırı.
- `BudgetProgressBar` — normal / warning / over durumlu ilerleme çubuğu.
- `TransactionRow` — ikon, başlık (marka veya kategori), alt satır (alt kategori · ödeme yöntemi · online/mağaza), sağda tutar.
- `ChipSelector` — yatay kaydırılabilir seçim çipleri.
- `AmountKeypad` — büyük tuşlu, `+ − ×` destekli hesap makinesi tuş takımı.
- `EmptyStateView` — ikon, 1 satır açıklama, 1 buton.
- `PrimaryButton` / `SecondaryButton`.

### 5.4 Hareket ve haptik
- Kayıt başarılı: `.sensoryFeedback(.success)` + kısa scale animasyonu.
- Silme: `.warning` haptiği, geri al (undo) seçeneği 5 sn.
- Animasyonlar `0.25–0.35 sn`, `.snappy` / `.smooth`. "Hareketi azalt" ayarı açıksa animasyonlar sadeleşir.

---

## 6. Bilgi Mimarisi ve Ekranlar

### 6.1 Navigasyon
Alt Tab Bar, 4 sekme + ortada belirgin **"+" Ekle** butonu:

```
[ Özet ]  [ İşlemler ]  ( + )  [ Planla ]  [ Analiz ]
                                   ↳ Bütçeler | Düzenli Ödemeler
Ayarlar: Özet ekranı sağ üstteki dişli ikonu
```

- "+" butonu her sekmeden erişilebilir, içerik kapatmaz, VoiceOver etiketi "Harcama ekle"dir.
- **Planla** sekmesi ileriye dönük her şeyi (bütçe limitleri, yaklaşan ödemeler) tek yerde toplar; Analiz geriye dönük bakıştır.

### 6.2 Ekranlar

#### A. Özet (Ana Sayfa)
- Üstte dönem seçici: `‹ Eylül 2026 ›` (kaydırarak ay değiştirme).
- **Hero kart:** Bu dönem toplam harcama, geçen döneme göre fark (`↓ %8 geçen aya göre`), varsa toplam bütçe ilerlemesi. Gelir girildiyse altında **net durum** (`Gelir − Gider = Kalan`).
- **Sabit vs değişken giderler** ayrımı (kira + faturalar + abonelikler vs diğerleri).
- **Kategori donut grafiği** + en çok harcanan 5 kategori listesi.
- **Yaklaşan ödemeler** (önümüzdeki 7 gün): "3 gün sonra — Netflix ₺229,99".
- **Son işlemler** (5 adet) + "Tümünü gör".

#### B. Hızlı Harcama Ekle (sheet)
Hedef: 3 dokunuşta kayıt.
0. En üstte `Gider | Gelir` segmenti (varsayılan Gider).
1. Açılışta **tutar** alanı odakta, büyük tuş takımı açık. Tutar sıfırdan büyük olmalı.
2. Altında **son kullanılan / sık kullanılan kategori çipleri** (ilk 6). Dokununca alt kategori çipleri kayarak gelir.
3. Opsiyonel alanlar katlanabilir panelde:
   - Marka / Mağaza (kategoriye göre filtrelenmiş öneriler + arama)
   - Kanal: `Mağazada` / `Online`
   - Ödeme yöntemi: Nakit / Kredi kartı / Banka kartı / Havale-EFT / Diğer (kullanıcı kart ekleyebilir: "Bonus", "Axess" vb.)
   - Tarih (varsayılan: şimdi)
   - Not, etiket (#tatil, #doğumgünü)
   - "Bunu düzenli ödeme yap" anahtarı
4. **Kaydet** butonu her zaman görünür; tutar + kategori dolunca aktifleşir.

Akıllı varsayılanlar:
- Marka seçilince kategori **önerilir** (Zara → Giyim; Shell → Yakıt), ancak kullanıcı kategoriyi önceden seçtiyse üzerine yazılmaz.
- Bir markada kullanıcı en son hangi kategoriyi, kanalı ve ödeme yöntemini seçtiyse o hatırlanır ve bir sonraki öneri olur (Koton'u hep kozmetik için kullanıyorsan öneri kozmetiğe döner).
- Listede olmayan marka adı yazıldığında "'X' olarak ekle" seçeneği çıkar; kayıt akışı hiç kesilmez.
- Kaydedince kısa ve sakin bir onay (haptik + küçük toast), özet anında güncellenir.

#### C. İşlemler
- Günlere göre gruplu liste, her grup başlığında gün toplamı.
- Arama (not, marka, kategori, tutar).
- Filtre: kategori, marka, kanal, ödeme yöntemi, tutar aralığı, etiket.
- Satırda sola kaydır: Sil. Sağa kaydır: Kopyala (aynı harcamayı bugüne tekrar ekle).
- Satıra dokun: Düzenleme ekranı.

#### D. Analiz
- Dönem: Hafta / Ay / Dönem (maaş günü) / Yıl / Özel aralık.
- Sekmeler: **Kategori** · **Marka** · **Kanal** (online vs mağaza) · **Trend**
- Detaya inme (drill-down): Kategori → Alt kategori → Marka → İşlemler.
- Bkz. [Bölüm 11](#11-raporlar-ve-grafikler).

#### E. Planla (Bütçeler + Düzenli Ödemeler)
Üstte segment: `Bütçeler | Düzenli Ödemeler`.

**Bütçeler:** Kategori bütçeleri; her satırda harcanan / kalan / yüzde ve dönemin kaçıncı gününde olunduğu. Limit satıra dokunarak düzenlenir. Bkz. [Bölüm 10](#10-bütçeler).

**Düzenli Ödemeler:**
- Aylık sabit gider toplamı en üstte ("Her ay ₺27.300 sabit").
- Liste: ad, tutar, periyot, sonraki ödeme tarihi, durum (bekliyor / ödendi / gecikti).
- Gruplar: Konut & Faturalar · Dijital Abonelikler · Ulaşım · Diğer.
- Bkz. [Bölüm 9](#9-düzenli-ödemeler-ve-abonelikler).

#### F. Ayarlar
- Dönem başlangıç günü (1–28 veya "maaş günü").
- Para birimi (varsayılan TRY) ve biçim.
- Kategoriler (ekle, düzenle, sırala, gizle, renk/ikon seç, alt kategori).
- Markalar (ekle, düzenle, birleştir, gizle).
- Ödeme yöntemleri.
- Bütçeler.
- Bildirimler (günlük hatırlatma saati, ödeme hatırlatma günü, **bildirimde tutar ve marka gösterilsin mi**).
- Face ID ile kilit.
- Görünüm: Sistem / Açık / Koyu.
- **Veri & Gizlilik:**
  - "Verilerin yalnızca bu iPhone'da saklanır. Uygulamayı silersen kayıtların da silinir; düzenli yedek almanı öneririz." açıklaması.
  - Son yedek tarihi ("Son yedek: 12 gün önce").
  - CSV dışa aktar, JSON yedek al / geri yükle.
  - Tüm veriyi sil (iki aşamalı onay: uyarı metni + "SİL" yazarak onay).

#### G. İlk açılış (Onboarding — en fazla 3 adım, tümü atlanabilir)
1. Hoş geldin: "Harcamalarını kendin kaydet, ay sonunda nereye gittiğini gör." + "Kayıtların bu cihazda kalır, banka hesabı bağlanmaz. Uygulamayı silersen kayıtlar da silinir."
2. Dönem başlangıç günü, (opsiyonel) aylık gelir ve (opsiyonel) aylık toplam bütçe.
3. Hızlı kurulum: Kira, faturalar ve abonelikleri işaretleyerek düzenli ödemeleri ekle (Netflix, iCloud+, Spotify... hazır liste). Önerilen kategorileri olduğu gibi al veya boş başla.

Onboarding'de hesap açma yok, **bildirim izni istenmez** (izin, kullanıcı ilk kez bir hatırlatma açtığında istenir).

#### H. Marka Detayı
İşlem listesinde veya Analiz'de bir markaya dokununca açılır. "Bu yıl Starbucks'a toplam ne kadar ödedim?" sorusunun cevabıdır.
- Bu ay / bu yıl / tüm zamanlar toplamı
- İşlem sayısı ve ortalama sepet tutarı
- Aylık mini bar grafik (son 12 ay)
- Kanal dağılımı (online / mağaza)
- Bu markaya ait işlemler listesi
- Markayı düzenle / birleştir / gizle

#### I. Ekran durumları
Her ekran için dört durum tasarlanır:
- **Boş:** Örnek/sahte veri gösterilmez; tek cümle açıklama + tek buton ("İlk harcamanı ekle").
- **Yükleniyor:** Yerel veri olduğu için genelde anlıktır; gerekirse iskelet (redacted) görünüm.
- **Hata:** Sorunu ve çözümü söyleyen tek cümle (bkz. [Bölüm 21](#21-metin-tonu-ve-mikro-metinler)).
- **Dolu:** Normal görünüm.

---

## 7. Kategori Yapısı

İki seviye: **Ana kategori → Alt kategori**. Tümü kullanıcı tarafından düzenlenebilir; aşağıdakiler ilk kurulumda gelen varsayılanlardır (seed data).

| Ana Kategori | SF Symbol | Alt Kategoriler |
|---|---|---|
| **Konut** | `house.fill` | Kira, Aidat, Elektrik, Su, Doğalgaz, İnternet, Ev sigortası (DASK/konut) |
| **Ulaşım** | `car.fill` | Yakıt, Toplu taşıma, Taksi / Yolculuk uygulaması, Scooter & Araç paylaşımı, Otopark, Köprü & Otoyol (HGS/OGS), Araç bakım & yıkama, Kasko & Trafik sigortası, Araç vergisi (MTV), Uçak / Otobüs bileti |
| **Market & Gıda** | `cart.fill` | Süpermarket, Manav & Kasap, Fırın, Online market |
| **Yeme & İçme** | `fork.knife` | Kahve & Kafe, Restoran, Fast food, Yemek siparişi, Tatlı & Pastane, Bar & Gece |
| **Giyim & Aksesuar** | `tshirt.fill` | Giyim, Ayakkabı, Çanta & Aksesuar, Spor giyim |
| **Kozmetik & Kişisel Bakım** | `sparkles` | Makyaj, Cilt bakımı, Parfüm, Kuaför & Berber, Estetik & Lazer, Kişisel hijyen |
| **Elektronik & Teknoloji** | `iphone` | Cihaz, Aksesuar, Yazılım & Uygulama |
| **Ev & Yaşam** | `sofa.fill` | Mobilya & Dekorasyon, Temizlik malzemesi, Mutfak eşyası, Tamir & Tadilat |
| **Abonelikler** | `repeat.circle.fill` | Video, Müzik, Bulut depolama, Yazılım, Oyun, Haber & Dergi, Spor salonu |
| **Faturalar & İletişim** | `phone.fill` | Mobil hat, Ev telefonu, TV paketi |
| **Sağlık** | `cross.case.fill` | Eczane, Doktor & Hastane, Diş, Özel sağlık sigortası, Vitamin & Takviye |
| **Eğlence & Sosyal** | `ticket.fill` | Sinema & Tiyatro, Konser & Etkinlik, Oyun (dijital), Hobi, Kitap |
| **Eğitim** | `book.fill` | Kurs, Kitap & Materyal, Online eğitim |
| **Seyahat** | `airplane` | Konaklama, Ulaşım, Tur & Aktivite |
| **Evcil Hayvan** | `pawprint.fill` | Mama, Veteriner, Bakım |
| **Finans** | `building.columns.fill` | Kredi taksiti, Kredi kartı faizi, Kredi kartı yıllık aidatı, Havale/EFT & banka ücreti, Vergi & harç |
| **Diğer** | `ellipsis.circle.fill` | Hediye, Bağış, Beklenmeyen gider |

### Gelir kategorileri
| Kategori | SF Symbol | Alt Kategoriler |
|---|---|---|
| **Maaş** | `banknote.fill` | — |
| **Ek gelir** | `plus.circle.fill` | Serbest iş, Kira geliri, Satış |
| **İade & Geri ödeme** | `arrow.uturn.backward.circle.fill` | Ürün iadesi, Arkadaştan geri ödeme |
| **Diğer gelir** | `ellipsis.circle.fill` | — |

Kurallar:
- Her işlemin **mutlaka** bir ana kategorisi olur; alt kategori opsiyoneldir. Başlangıç deneyimi fazla dallanmasın diye alt kategoriler giriş ekranında ikinci sırada, çip olarak gelir.
- **Arşivleme varsayılandır:** Kategori arşivlenince geçmiş işlemlerde görünmeye devam eder, yeni girişte önerilmez.
- **Silme** sadece kullanıcı isterse: İşlemi olan bir kategori silinirken "İşlemleri şu kategoriye taşı" seçimi zorunludur. Hiçbir işlem sessizce kaybolmaz.
- Online alışveriş bir kategori değildir; `channel` alanıyla tutulur (bkz. Bölüm 3, ilke 8).

---

## 8. Marka / Mağaza (Merchant) Kataloğu

Marka, işlemin "nereye" sorusunu cevaplar. Her markanın bir **önerilen kategorisi** vardır; kullanıcının son seçimi (kategori, kanal, ödeme yöntemi) hatırlanır ve öneride öncelik kazanır. Liste düzenlenebilir seed data'dır; eksik markalar kullanıcı tarafından tek dokunuşla eklenir.

> Marka logoları **kullanılmaz** (telif/marka hakkı ve uygulama boyutu). Bunun yerine `MerchantAvatar` bileşeni: baş harfler + kategori rengi.

| Kategori | Başlangıç markaları |
|---|---|
| **Giyim** | Koton, Mavi, LC Waikiki, DeFacto, Zara, Bershka, Pull&Bear, Stradivarius, Massimo Dutti, Mango, H&M, Beymen, Vakko, Network, Colin's, Boyner |
| **Spor giyim** | Nike, Adidas, Puma, New Balance, Decathlon, Skechers |
| **Online pazaryeri** | Trendyol, Hepsiburada, Amazon Türkiye, n11, Çiçeksepeti, Temu |
| **Kozmetik** | Gratis, Watsons, Sephora, Rossmann, Eve, MAC, Flormar, Golden Rose |
| **Süpermarket** | Migros, A101, BİM, ŞOK, CarrefourSA, Macrocenter, File, Metro |
| **Online market / hızlı teslimat** | Getir, Migros Hemen, Trendyol Go, Yemeksepeti Market, İstegelsin |
| **Yemek siparişi** | Yemeksepeti, Getir Yemek, Trendyol Yemek |
| **Kahve & Tatlı** | Starbucks, Kahve Dünyası, EspressoLab, Caffè Nero, Caribou, Tchibo, Gloria Jean's, Petra |
| **Fast food** | Burger King, McDonald's, Popeyes, Little Caesars, Domino's, Simit Sarayı |
| **Yakıt** | Shell, Opet, BP, Petrol Ofisi, TotalEnergies, Aytemiz |
| **Toplu taşıma & taksi** | İstanbulkart, Kentkart, BiTaksi, Uber |
| **Scooter & araç paylaşımı** | Martı, BinBin, TikTak, Moov |
| **Otopark** | İspark |
| **Uçak** | Pegasus, AJet, Türk Hava Yolları |
| **Elektronik** | MediaMarkt, Teknosa, Vatan Bilgisayar, Apple |
| **Ev & Yaşam** | IKEA, Koçtaş, English Home, Madame Coco, Karaca, Bauhaus |
| **Spor salonu** | MacFit |
| **Dijital oyun** | Steam, PlayStation Store, App Store |
| **Kitap & Eğitim** | D&R, Kitapyurdu, Remzi, Udemy |

Kurallar:
- Marka kataloğu uygulama içinde yerel JSON'dur; harici servis veya internet gerektirmez.
- Marka, kategoriyi **önerir, belirlemez** (bkz. Bölüm 3, ilke 8). Son seçim hatırlanır.
- Kullanıcı listede olmayan ismi her zaman yazabilir; yazdığı isim otomatik olarak kataloğa eklenir.
- Markalar arama ile bulunur; yazarken Türkçe karakter duyarsız eşleşme (ör. "sok" → ŞOK).
- Aynı marka yanlışlıkla iki kez eklenirse **birleştir** özelliği sunulur.
- Online işlem seçildiğinde öneri listesi önce online kanalı olan markaları gösterir.

---

## 9. Düzenli Ödemeler ve Abonelikler

Referans uygulamalarda en çok sevilen ve en çok istenen özellik. Burada **ücretsiz ve sınırsız**.

### 9.1 Tanım
Bir `RecurringPayment`:
- Ad, tutar, kategori (+ alt kategori), marka (opsiyonel), ödeme yöntemi
- Periyot: haftalık / aylık / 3 aylık / 6 aylık / yıllık / özel (her N gün)
- Başlangıç tarihi, (opsiyonel) bitiş tarihi veya taksit sayısı
- Ödeme günü (örn. her ayın 5'i; ayda o gün yoksa ayın son günü)
- Mod:
  - **Onayla (varsayılan):** Tarih gelince ödeme "Bekliyor" olur ve (açıksa) "Ödendi mi?" bildirimi gelir. Kullanıcı "Ödendi" deyince işlem oluşur; tutar o ay için değiştirilebilir (ör. elektrik, doğalgaz — her ay farklı tutar). Sonraki vade tarihi ancak o zaman ilerler.
  - **Otomatik kaydet (isteğe bağlı):** Karttan kesin çekildiğini bildiğin sabit tutarlı ödemeler için (ör. Netflix, iCloud+). Tarihi gelince işlem kendiliğinden oluşur, listede küçük "otomatik" etiketiyle görünür ve tek dokunuşla geri alınabilir.
- Durumlar: `Yaklaşıyor` · `Bekliyor` · `Ödendi` · `Atlandı` (bu ay ödenmedi/iptal).
- Hatırlatma: ödeme gününden X gün önce bildirim (isteğe bağlı).

### 9.2 Hazır abonelik şablonları (onboarding + ekleme ekranı)
- **İzleme:** Netflix, YouTube Premium, Disney+, Amazon Prime, HBO Max, Exxen, Gain, TOD
- **Dinleme:** Spotify, Apple Music
- **Depolama & yazılım:** iCloud+, Google One, Apple One, Adobe, ChatGPT
- **Oyun:** Xbox Game Pass, PlayStation Plus
- **Spor:** MacFit / spor salonu

> BluTV, Türkiye'de HBO Max çatısına geçtiği için ayrı şablon olarak eklenmez. Şablon listesi seed JSON'dur; kapanan veya ad değiştiren servisler kolayca güncellenir.

> Fiyatlar **şablona gömülmez**; Türkiye'de abonelik fiyatları sık değiştiği için kullanıcı tutarı kendisi girer. Şablon sadece ad, kategori, periyot ve ikon rengi sağlar.

### 9.3 Ekranda gösterim
- "Bu ay kalan sabit ödemeler: ₺4.120 (3 ödeme)"
- Aylık eşdeğer: Yıllık ₺1.200'lük abonelik "≈ ₺100/ay" olarak da gösterilir.
- Fiyat değişimi: Tutar güncellendiğinde geçmiş işlemler etkilenmez; "Fiyat arttı: ₺199,99 → ₺229,99" geçmişi tutulur.

### 9.4 Teknik not
- Uygulama her açılışta ve arka plan yenilemesinde (BGAppRefreshTask) **vadesi gelmiş** düzenli ödemeleri kontrol eder, eksik dönemleri oluşturur (idempotent: aynı dönem için iki kez işlem oluşmaz — `recurringId + periodKey` benzersiz anahtar).
- Bildirimler `UNUserNotificationCenter` ile yerel olarak planlanır; iOS 64 bekleyen bildirim sınırı nedeniyle sadece önümüzdeki ~30 günün bildirimleri planlanır ve her açılışta yenilenir.

---

## 10. Bütçeler

- **Toplam aylık bütçe** (opsiyonel) + **kategori bazlı bütçeler**.
- İleri sürüm: marka bazlı limit (ör. "Yemek siparişi ayda ₺3.000").
- Durumlar: `%0–79 normal (yeşil)` · `%80–99 warning (bal)` · `%100+ over (kiremit)`.
- Bildirim: %80 ve %100 eşiklerinde tek seferlik, yargılamayan dil:
  - ✅ "Kahve & Kafe bütçenin %80'ine ulaştın. Ayın bitmesine 9 gün var."
  - ❌ "Çok fazla harcadın!"
- **Günlük harcanabilir tutar:** `(bütçe − harcanan) / kalan gün` — hero kartta küçük satır.
- Dönem bitiminde kalan bütçe devretmez (MVP). Devir (rollover) ileri sürüm.

---

## 11. Raporlar ve Grafikler

**Swift Charts** kullanılır.

| Grafik | Tür | Nerede |
|---|---|---|
| Kategori dağılımı | Donut (`SectorMark`, innerRadius) — ortada toplam | Özet, Analiz |
| Aylık trend (son 6–12 ay) | Bar (`BarMark`) + ortalama çizgisi (`RuleMark`) | Analiz → Trend |
| Gün gün kümülatif harcama | Line/Area (`LineMark` + `AreaMark`), geçen ay kesikli çizgi ile üst üste | Analiz → Trend |
| En çok harcanan markalar | Yatay bar | Analiz → Marka |
| Online vs Mağaza | Yığılmış bar / iki dilimli donut | Analiz → Kanal |
| Sabit vs değişken | İki dilimli yatay bar | Özet |

Grafik kuralları:
- En fazla 6 dilim; kalanlar "Diğer" olarak birleşir.
- Dokunulan dilim/sütun seçilir, tutar ve yüzde gösterilir (`chartAngleSelection`, `chartXSelection`).
- Eksen etiketleri Türkçe ve kısaltılmış (`₺12,4B` yerine `₺12,4 bin`).
- Her grafiğin altında **metin özeti** vardır (erişilebilirlik ve hızlı okuma): "En büyük gider: Konut (%41)".

---

## 12. Veri Modeli

**SwiftData** ile. Parasal değerler **asla `Double` tutulmaz**, `Decimal` kullanılır.

```swift
@Model final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Decimal              // her zaman pozitif
    var currencyCode: String         // "TRY" — çoklu para birimine hazırlık
    var kind: TransactionKind        // .expense / .income
    var date: Date
    var note: String?
    var tags: [String]
    var channel: PurchaseChannel?    // .inStore / .online
    var createdAt: Date
    var updatedAt: Date

    var category: Category?
    var subcategory: Category?
    var merchant: Merchant?
    var paymentMethod: PaymentMethod?
    var recurringPayment: RecurringPayment?
    var recurringPeriodKey: String?  // "2026-09" — idempotency için
}

@Model final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String           // SF Symbol
    var colorToken: String           // "cat.forest" vb.
    var kind: TransactionKind        // gider mi gelir kategorisi mi
    var sortOrder: Int
    var isArchived: Bool
    var isSystem: Bool               // seed ile geldi mi
    var parent: Category?            // nil => ana kategori
    @Relationship(deleteRule: .cascade, inverse: \Category.parent)
    var children: [Category]
}

@Model final class Merchant {
    @Attribute(.unique) var id: UUID
    var name: String
    var searchKey: String            // küçük harf, Türkçe karakter sadeleştirilmiş
    var suggestedCategory: Category?     // seed'den gelen öneri
    var lastUsedCategory: Category?      // kullanıcının son seçimi (öneride öncelikli)
    var lastUsedSubcategory: Category?
    var lastUsedChannel: PurchaseChannel?
    var lastUsedPaymentMethod: PaymentMethod?
    var isHidden: Bool
    var isSystem: Bool
}

@Model final class PaymentMethod {
    @Attribute(.unique) var id: UUID
    var name: String                 // "Nakit", "Bonus Kart" ...
    var type: PaymentMethodType      // .cash / .creditCard / .debitCard / .transfer / .other
    var sortOrder: Int
}

@Model final class RecurringPayment {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Decimal
    var frequency: RecurrenceFrequency   // .weekly/.monthly/.quarterly/.semiannual/.yearly/.customDays(Int)
    var dayOfPeriod: Int
    var startDate: Date
    var endDate: Date?
    var remainingInstallments: Int?
    var mode: RecurringMode              // .confirm (varsayılan) / .autoPost
    var nextDueDate: Date                // "Ödendi" veya otomatik kayıtla ilerler
    var reminderDaysBefore: Int?
    var isActive: Bool
    var category: Category?
    var subcategory: Category?
    var merchant: Merchant?
    var paymentMethod: PaymentMethod?
    var priceHistory: [PriceChange]      // Codable struct
}

@Model final class Budget {
    @Attribute(.unique) var id: UUID
    var limit: Decimal
    var category: Category?          // nil => toplam bütçe
    var periodType: BudgetPeriod     // .month (MVP) / .week / .year
    var isActive: Bool
}
```

### Hesaplama kuralları
- Gelir ve gider ayrı toplanır; `net = gelir − gider`.
- Bütçe kullanımı yalnızca o kategori (ve alt kategorileri) ile o dönemdeki **giderlerden** hesaplanır; gelirler ve iadeler bütçeyi etkilemez (iade, ileride "gideri azaltan işlem" olarak ele alınabilir).
- "Bekliyor" durumundaki düzenli ödemeler toplamlara girmez; sadece "Yaklaşan ödemeler" alanında görünür.

Ayarlar (`UserDefaults` / `@AppStorage`): dönem başlangıç günü, görünüm, bildirim saati, Face ID açık/kapalı, onboarding tamamlandı mı.

### Şema değişiklikleri
- Model değiştiğinde `VersionedSchema` + `SchemaMigrationPlan` kullanılır. TestFlight'taki mevcut veri **asla kaybolmamalı**.
- Her şema sürümü `Schema/V1.swift`, `Schema/V2.swift` şeklinde ayrı dosyada.

---

## 13. Teknik Mimari

| Konu | Karar |
|---|---|
| Dil | Swift 6 (strict concurrency) |
| UI | SwiftUI |
| Minimum iOS | iOS 17 (SwiftData, `@Observable`, Swift Charts etkileşimleri için). Tek kullanıcı olduğundan cihazın desteklediği en güncel iOS'a çekilebilir. |
| Cihaz | iPhone (portre). iPad ileride. |
| Kalıcılık | SwiftData (cihazda) |
| Durum yönetimi | `@Observable` ViewModel'ler + `@Query` (listeler için) |
| Grafik | Swift Charts |
| Bildirim | UserNotifications (yerel) |
| Arka plan | BackgroundTasks (`BGAppRefreshTask`) — düzenli ödeme kontrolü |
| Kilit | LocalAuthentication (Face ID / şifre) |
| Dışa aktarma | `ShareLink` + CSV / JSON (`FileDocument`) |
| Bağımlılık | **Sıfır üçüncü parti paket** hedefi. Gerekirse sadece Swift Package Manager. |
| İleri sürüm | WidgetKit (ana ekran & kilit ekranı widget), App Intents (Siri / Kısayollar: "Kahveye 95 lira ekle"), VisionKit (fiş tarama), CloudKit senkron (opsiyonel) |

### Katmanlar
```
View (SwiftUI)  →  ViewModel (@Observable)  →  Service / Repository  →  SwiftData ModelContext
                                          ↘  Domain (saf Swift: hesaplamalar, dönem mantığı)
```
- **Domain** katmanı UI ve SwiftData'dan bağımsız, birim test edilebilir: dönem hesaplama, bütçe durumu, düzenli ödeme sonraki tarih hesabı, toplamlar.
- View'lar iş mantığı içermez; sadece gösterir ve kullanıcı olayını ViewModel'e iletir.

### Para birimi ve biçim
```swift
extension Decimal {
    var tryFormatted: String {
        formatted(.currency(code: "TRY").locale(Locale(identifier: "tr_TR")))
    }
}
// Çıktı: ₺1.234,56
```
- Tuş takımında virgül ondalık ayırıcıdır.
- Tüm toplamalar `Decimal` ile yapılır; yuvarlama sadece gösterimde.

### Dönem (Period) mantığı
- Kullanıcı "dönem başlangıç günü"nü seçer (varsayılan 1).
- Örn. başlangıç günü 15 ise "Eylül dönemi" = 15 Eylül 00:00 → 14 Ekim 23:59.
- `Calendar(identifier: .gregorian)` + `TimeZone.current`; tüm tarih hesapları tek bir `PeriodCalculator` üzerinden yapılır.
- **Saat dilimi kuralı:** Yurt dışına çıkıldığında 31 Ağustos 23:30'da girilmiş bir harcama Eylül'e kaymamalı. Bu yüzden işlemle birlikte girildiği yerel gün (`localDay`, örn. `2026-08-31`) de saklanır ve dönem gruplaması bu alana göre yapılır.

---

## 14. Proje Klasör Yapısı

```
CuzdanDefteri/
├── App/
│   ├── CuzdanDefteriApp.swift
│   ├── AppRouter.swift
│   └── RootTabView.swift
├── DesignSystem/
│   ├── Colors.swift            // Color token extension'ları
│   ├── Typography.swift
│   ├── Spacing.swift
│   └── Components/
│       ├── AmountText.swift
│       ├── CategoryIcon.swift
│       ├── MerchantAvatar.swift
│       ├── SummaryCard.swift
│       ├── BudgetProgressBar.swift
│       ├── TransactionRow.swift
│       ├── ChipSelector.swift
│       ├── AmountKeypad.swift
│       └── EmptyStateView.swift
├── Domain/
│   ├── PeriodCalculator.swift
│   ├── RecurrenceEngine.swift
│   ├── BudgetEvaluator.swift
│   └── Aggregations.swift
├── Data/
│   ├── Schema/
│   │   ├── V1.swift
│   │   └── MigrationPlan.swift
│   ├── Models/                 // @Model sınıfları
│   ├── Seed/
│   │   ├── categories.json
│   │   ├── merchants.json
│   │   └── subscriptionTemplates.json
│   ├── SeedLoader.swift
│   └── Repositories/
├── Features/
│   ├── Overview/
│   ├── AddTransaction/
│   ├── Transactions/
│   ├── Analytics/
│   ├── Recurring/
│   ├── Budgets/
│   ├── Settings/
│   └── Onboarding/
├── Services/
│   ├── NotificationService.swift
│   ├── BackgroundRefreshService.swift
│   ├── BiometricLockService.swift
│   └── ExportService.swift
├── Resources/
│   ├── Assets.xcassets         // renkler, app ikonu
│   └── Localizable.xcstrings
└── Tests/
    ├── DomainTests/
    └── UITests/
```

---

## 15. Kod Standartları

- **İsimlendirme:** Kod İngilizce (tip, fonksiyon, değişken). Kullanıcıya görünen metin Türkçe ve `Localizable.xcstrings` içinde.
- **Dosya başına bir ana tip.** View dosyaları 200 satırı geçerse alt view'lara bölünür.
- **Para:** `Decimal`. `Double` ile para işlemi PR'da reddedilir.
- **Tarih:** Tüm hesaplar `PeriodCalculator` / `Calendar` üzerinden; elle `86400` saniye eklenmez.
- **Önizleme:** Her ekran ve bileşenin açık + koyu mod `#Preview`'u vardır, in-memory `ModelContainer` ile örnek veri.
- **Hata yönetimi:** Kaydetme hataları kullanıcıya sade bir uyarı ile gösterilir, `Logger` (OSLog) ile kaydedilir.
- **Commit mesajı:** `feat:`, `fix:`, `refactor:`, `design:`, `chore:` önekleri.
- **Dal (branch):** `main` (TestFlight'a giden) · `feature/<kısa-ad>`.
- **SwiftLint** (opsiyonel, SPM plugin) — varsayılan kurallar.

---

## 16. Erişilebilirlik ve Yerelleştirme

- Dynamic Type en büyük boyuta kadar kırılmadan çalışmalı (gerekirse `ViewThatFits` ile dikey yerleşime geçilir).
- VoiceOver: Tutarlar "iki yüz yirmi dokuz lira doksan dokuz kuruş" şeklinde okunmalı; `TransactionRow` tek öğe olarak birleştirilir (`.accessibilityElement(children: .combine)`).
- Grafiklerde `accessibilityChartDescriptor` veya metin özeti.
- Dokunma alanları en az 44×44 pt.
- Renk tek başına anlam taşımaz (bkz. 4.4).
- Dil: Türkçe (birincil). Metinler baştan String Catalog'da tutulur, ileride İngilizce eklemek kolay olsun.
- Türkçe büyük/küçük harf: `uppercased(with: Locale(identifier: "tr_TR"))` — "i → İ" sorunu.

---

## 17. Gizlilik ve Güvenlik

- Tüm veri **cihazda**. Ağ isteği yok (ilk sürümlerde uygulamanın internete hiç çıkmaması hedeflenir).
- Analitik / takip SDK'sı yok. App Tracking Transparency gerekmez.
- Opsiyonel Face ID kilidi; uygulama arka plana gidince uygulama değiştirici (app switcher) görüntüsü bulanıklaştırılır.
- **Bildirim izni** sadece kullanıcı ilk kez bir hatırlatma açtığında, nedenini anlatan kısa bir açıklamadan sonra istenir. Reddedilirse uygulama bildirimsiz çalışmaya devam eder.
- **Bildirim önizlemesi:** Ayarlardan kapatılabilir; kapalıyken bildirimde "Bugün 1 ödemen var" yazar, tutar ve marka görünmez.
- **Veri kaybı uyarısı:** Veri sadece cihazda olduğu için uygulamayı silmek kayıtları siler. Bu bilgi onboarding'de ve Ayarlar → Veri & Gizlilik'te açıkça yazar; son yedekten 30 gün geçince Özet'te nazik bir "Yedek almak ister misin?" kartı çıkar.
- SwiftData dosyası iOS Data Protection (`completeUntilFirstUserAuthentication`) ile korunur.
- Yedek dosyası (JSON) kullanıcının kendi seçtiği yere (Dosyalar / iCloud Drive) kaydedilir.
- App Store Connect'te **Privacy Nutrition Label**: "Veri toplanmıyor."

---

## 18. Yol Haritası (Sürümler)

### v0.1 — MVP "Kaydet ve gör"
- [x] Proje iskeleti, Design System token'ları, açık/koyu mod
- [x] SwiftData modelleri + seed (kategoriler, markalar)
- [ ] Hızlı Ekle: gider **ve gelir** (tutar, kategori, alt kategori, marka, kanal, ödeme yöntemi, tarih, not)
- [ ] İşlemler listesi (gün gruplu, düzenle, sil, geri al)
- [ ] Özet ekranı (aylık toplam, net durum, geçen ay farkı, kategori donut, son işlemler)
- [ ] Ayarlar: dönem başlangıç günü, kategori & marka yönetimi
- [ ] İlk TestFlight build

### v0.2 — "Sabit giderler"
- [ ] Düzenli ödemeler (otomatik / onaylı), abonelik şablonları
- [ ] Yerel bildirimler (ödeme hatırlatma, onay bildirimi)
- [ ] Arka plan yenileme ile vadesi gelen ödemelerin oluşturulması
- [ ] Özet'te "Yaklaşan ödemeler" ve sabit/değişken ayrımı
- [ ] Onboarding
- [ ] **JSON yedek al / geri yükle ve CSV dışa aktarma** (veri sadece cihazda olduğu için erken geliyor)
- [ ] Tüm veriyi sil

### v0.3 — "Kontrol"
- [ ] Toplam ve kategori bütçeleri, %80 / %100 bildirimleri
- [ ] Analiz ekranı: trend, marka, kanal sekmeleri, drill-down
- [ ] Marka Detay ekranı ("Bu yıl Starbucks'a ne kadar ödedim?")
- [ ] Arama ve gelişmiş filtre
- [ ] Etiketler

### v0.4 — "Güven"
- [ ] Face ID kilidi, app switcher bulanıklaştırma
- [ ] Bildirim önizlemesini gizleme ayarı
- [ ] "Yedek almak ister misin?" hatırlatma kartı
- [ ] CSV içe aktarma (başka uygulamadan geçiş için)

### v0.5+ — "Kolaylık"
- [ ] Ana ekran ve kilit ekranı widget'ları (bu ay toplam, hızlı ekle)
- [ ] Siri / Kısayollar: "Kahveye 95 lira ekle"
- [ ] Fiş tarama (VisionKit + metin tanıma ile tutar ve mağaza önerisi)
- [ ] Kredi kartı taksitli alışveriş (tek alışveriş → N aylık işlem)
- [ ] Bütçe devri (rollover)
- [ ] Opsiyonel iCloud senkron (CloudKit)

---

## 19. Test ve TestFlight Süreci

### 19.1 Testler
- **Birim test (Swift Testing):** `PeriodCalculator`, `RecurrenceEngine` (ay sonu, artık yıl, 31'inde ödeme), `BudgetEvaluator`, `Aggregations`, Decimal formatlama.
- **UI test:** Harcama ekle → listede görünür → özet toplamı güncellenir.
- **Manuel kontrol listesi** her build öncesi: açık/koyu mod, en büyük Dynamic Type, VoiceOver ile bir harcama ekleme, uçak modu.

### 19.2 Kendi cihazında lokal çalıştırma
- Xcode'dan iPhone'a kablolu/kablosuz doğrudan yükleme mümkün. Ücretsiz Apple hesabıyla imzalanan build'ler kısa süre (yaklaşık 7 gün) sonra yeniden yükleme ister; bu yüzden düzenli kullanım için TestFlight tercih edilir.

### 19.3 TestFlight
1. **Apple Developer Program** üyeliği gerekir (yıllık ücretli).
2. App Store Connect'te uygulama kaydı: Bundle ID (örn. `com.<adın>.cuzdandefteri`), ad, SKU.
3. Xcode → Product → Archive → Distribute App → App Store Connect → Upload.
4. **Dahili test (Internal Testing):** App Store Connect ekibindeki kişiler (en fazla 100) Apple incelemesi beklemeden test edebilir. Kişisel kullanım için ideal.
5. **Harici test (External Testing):** Ekip dışından kişiler için; ilk build Beta App Review'dan geçer.
6. TestFlight build'leri yüklendikten **90 gün** sonra sona erer; düzenli yeni build yüklemek gerekir.
7. Sürümleme: `MARKETING_VERSION` = 0.1.0, 0.2.0 … · `CURRENT_PROJECT_VERSION` her yüklemede +1.
8. Her build için "Test edilecekler" (What to Test) notu yazılır.
9. **Şifreleme beyanı:** Uygulama standart dışı şifreleme kullanmadığı için `Info.plist`'e `ITSAppUsesNonExemptEncryption = NO` eklenir; her yüklemede soru sorulmaz.

### 19.4 Veri güvenliği (güncellemeler arasında)
- Yeni build öncesi: eski build'de örnek veri oluştur → yeni build'i üzerine yükle → verinin korunduğunu doğrula (migration testi).

---

## 20. Tanım Kontrol Listesi (Definition of Done)

Bir özellik "bitti" sayılmadan önce:

- [ ] Açık ve koyu modda doğru görünüyor
- [ ] En büyük Dynamic Type'ta kırılmıyor
- [ ] VoiceOver ile kullanılabiliyor
- [ ] Boş durum (empty state) tasarlanmış
- [ ] Tutarlar `Decimal` ve `₺1.234,56` formatında
- [ ] Domain mantığı birim testli
- [ ] `#Preview` mevcut
- [ ] Kullanıcıya görünen metinler String Catalog'da
- [ ] Mevcut veriyi bozmadığı (migration) doğrulanmış
- [ ] Gerçek cihazda denenmiş
- [ ] Boş, yükleniyor, hata ve dolu durumları düşünülmüş
- [ ] Kullanıcı ekranda ne kadar harcadığını ve ne yapabileceğini ilk bakışta anlıyor
- [ ] Kayıt akışına gereksiz zorunlu alan eklenmemiş
- [ ] Kategori, marka ve kanal ayrı kavramlar olarak korunuyor
- [ ] Metinler kullanıcıyı suçlamıyor (Bölüm 21)

---

## 21. Metin Tonu ve Mikro Metinler

Uygulama yargılamayan, sakin bir yardımcı gibi konuşur. Türkçe, kısa, doğrudan; "sen" diliyle. Finans jargonu yok.

| Durum | ✅ Böyle | ❌ Böyle değil |
|---|---|---|
| Bütçe aşımı | "Kahve & Kafe'de limitini ₺350 geçtin." | "Bütçeni aştın, kötü gidiyorsun!" |
| %80 uyarısı | "Market bütçenin %80'ine ulaştın. Ayın bitmesine 9 gün var." | "Dikkat! Paran bitiyor!" |
| Hata | "Tutarı kontrol et. 0'dan büyük bir değer gir." | "Geçersiz giriş." |
| Kayıt başarılı | "Kaydedildi" | "Harika! Süpersin! 🎉🎉" |
| Boş liste | "Bu ay henüz harcama yok. İlkini eklemek 5 saniye sürer." | "Veri bulunamadı." |
| Silme onayı | "Bu harcama silinsin mi? 5 saniye içinde geri alabilirsin." | "Emin misiniz?" |
| Tüm veriyi sil | "Tüm kayıtların bu cihazdan kalıcı olarak silinecek. Önce yedek almak ister misin?" | "Veriler silinecek." |

Kurallar:
- Hata mesajı hem sorunu hem çözümü söyler.
- Ünlem ve emoji minimum; kutlama sadece gerçek bir kilometre taşında (ör. ilk ayın tamamlanması).
- Tutarlar metin içinde de Türkçe biçimde: `₺1.250,00`.

---

## 22. Karar Kaydı

Bu rehber, başka iki rehber taslağıyla karşılaştırılarak güncellendi. Farklı yönde karar verilen noktalar ve gerekçeleri:

| Konu | Karar | Gerekçe |
|---|---|---|
| Marka logoları | **Kullanılmaz**; baş harf + kategori rengi avatarı | Logolar tescilli marka görselidir; izin gerekir, uygulama boyutunu büyütür, marka yenilendiğinde bakım ister. Baş harf avatarı tutarlı ve temiz görünür. |
| Market alışverişinin yeri | Ayrı **Market & Gıda** kategorisi (Yeme & İçme altında değil) | Market zorunlu ihtiyaç, restoran/kahve keyfi harcama; ayrı durunca "dışarıda yemeye ne harcıyorum" sorusu net cevaplanır. |
| Online alışveriş | Kategori değil, **kanal** alanı | Online giyim hem Giyim hem Online filtresinde görünür; aynı veri iki yerde tekrarlanmaz. |
| Marka → kategori | Öneri, zorunluluk değil | Aynı mağazadan farklı kategoride alışveriş yapılabilir. |
| Düzenli ödeme varsayılanı | **Onayla** (hatırlat, kullanıcı işaretlesin) | Uygulama ödeme yapılmış gibi sahte kayıt oluşturmamalı; otomatik kayıt isteğe bağlı. |
| Gelir takibi | MVP'de var | "Ne kadar kaldı?" sorusu gelir olmadan cevaplanamaz. |
| Yedek / dışa aktarma | v0.2'ye çekildi | Veri sadece cihazda; kayıp riski erken çözülmeli. |
| Dil sürümü | Swift 6 | Yeni projede strict concurrency baştan açılırsa ileride taşıma maliyeti olmaz. |
| Alt gezinme | Özet · İşlemler · (+) · Planla · Analiz | Bütçeler ve düzenli ödemeler "ileriye dönük" tek sekmede; Ayarlar dişli ikonunda. |
| Renk paleti | Bölüm 4'teki tokenlar geçerli | Diğer taslaklardaki öneriler (`#2E5A44`, `#245B45`, `#F9F9F6` vb.) aynı aileden; tek kaynak olsun diye Bölüm 4 esas alınır. |

---

*Son güncelleme: 23 Eylül 2026 · Sürüm: guideline v1.1 (iki ek rehber taslağıyla birleştirildi)*
