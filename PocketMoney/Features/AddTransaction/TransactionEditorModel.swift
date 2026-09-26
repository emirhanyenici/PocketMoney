import Foundation
import Observation
import SwiftData

/// Hızlı Ekle / Düzenle ekranının durumu ve kuralları (Bölüm 6.2-B).
@Observable
final class TransactionEditorModel {
    enum SaveError: Error {
        case invalidInput
    }

    private(set) var kind: TransactionKind
    var expression: AmountExpression
    private(set) var category: Category?
    private(set) var subcategory: Category?
    private(set) var merchant: Merchant?
    /// Listede olmayan, kayıtta kataloğa eklenecek marka adı (Bölüm 8).
    private(set) var pendingMerchantName: String?
    var merchantQuery = ""
    var channel: PurchaseChannel?
    var paymentMethod: PaymentMethod?
    var date: Date
    var note: String

    let editingTransaction: Transaction?
    /// Kullanıcı kategoriyi kendisi seçtiyse marka önerisi onu ezmez (Bölüm 6.2-B).
    private var categoryChosenByUser = false

    /// - Parameter initialKind: Yeni kayıtta başlangıç türü; Özet'teki "Gelir ekle" `.income` ile açar.
    init(transaction: Transaction? = nil, initialKind: TransactionKind = .expense) {
        editingTransaction = transaction
        kind = transaction?.kind ?? initialKind
        expression = transaction.map { AmountExpression(amount: $0.amount) } ?? AmountExpression()
        category = transaction?.category
        subcategory = transaction?.subcategory
        merchant = transaction?.merchant
        channel = transaction?.channel
        paymentMethod = transaction?.paymentMethod
        date = transaction?.date ?? .now
        note = transaction?.note ?? ""
        categoryChosenByUser = transaction != nil
    }

    // MARK: - Durum

    var isEditing: Bool { editingTransaction != nil }
    var amount: Decimal? { expression.value }
    /// Tutar yazılmış ama sıfır veya negatif (Bölüm 21 hata metni için).
    var isAmountInvalid: Bool { !expression.isEmpty && (amount ?? 0) <= 0 }
    /// Kaydet, tutar + kategori dolunca aktifleşir (Bölüm 6.2-B).
    var canSave: Bool { (amount ?? 0) > 0 && category != nil }
    var merchantDisplayName: String? { merchant?.name ?? pendingMerchantName }
    var hasDetails: Bool {
        merchantDisplayName != nil || channel != nil || paymentMethod != nil || !note.isEmpty
    }

    // MARK: - Seçimler

    func setKind(_ newKind: TransactionKind) {
        guard newKind != kind else { return }
        kind = newKind
        category = nil
        subcategory = nil
        categoryChosenByUser = false
    }

    func selectCategory(_ selected: Category) {
        if category != selected { subcategory = nil }
        category = selected
        categoryChosenByUser = true
    }

    /// Tam listeden (Tümü ekranı) ana + isteğe bağlı alt kategori birlikte seçilir.
    func select(category selected: Category, subcategory: Category?) {
        selectCategory(selected)
        self.subcategory = subcategory
    }

    /// Aynı alt kategoriye tekrar dokununca seçim kalkar.
    func toggleSubcategory(_ selected: Category) {
        subcategory = subcategory == selected ? nil : selected
    }

    func toggleChannel(_ selected: PurchaseChannel) {
        channel = channel == selected ? nil : selected
    }

    func togglePaymentMethod(_ selected: PaymentMethod) {
        paymentMethod = paymentMethod == selected ? nil : selected
    }

    func selectMerchant(_ selected: Merchant) {
        merchant = selected
        pendingMerchantName = nil
        merchantQuery = ""
        applySuggestions(from: selected)
    }

    /// "'X' olarak ekle": kayıt akışı kesilmez, marka kayıtla birlikte oluşur.
    func addQueryAsNewMerchant() {
        let name = merchantQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        merchant = nil
        pendingMerchantName = name
        merchantQuery = ""
    }

    func clearMerchant() {
        merchant = nil
        pendingMerchantName = nil
    }

    /// Bölüm 6.2-B akıllı varsayılanlar: markanın son kullanılan seçimleri
    /// önceliklidir, yoksa seed önerisi. Kullanıcının seçtikleri ezilmez.
    private func applySuggestions(from merchant: Merchant) {
        if !categoryChosenByUser {
            // Öneri yalnızca bu kaydın türüne uyan, arşivlenmemiş bir kategoriyse
            // kullanılır. Eski sürümler gelir kaydında da `lastUsedCategory` yazıyordu;
            // bu kontrol o bozuk değeri yok sayar, sonraki gider kaydı onu düzeltir.
            if let lastUsed = merchant.lastUsedCategory, isSuggestable(lastUsed) {
                category = lastUsed
                subcategory = merchant.lastUsedSubcategory.flatMap { isSuggestable($0) ? $0 : nil }
            } else if let suggested = merchant.suggestedCategory, isSuggestable(suggested) {
                category = suggested.parent ?? suggested
                subcategory = suggested.parent == nil ? nil : suggested
            }
        }
        if channel == nil { channel = merchant.lastUsedChannel }
        if paymentMethod == nil { paymentMethod = merchant.lastUsedPaymentMethod }
    }

    private func isSuggestable(_ candidate: Category) -> Bool {
        candidate.kind == kind && !candidate.isArchived && !(candidate.parent?.isArchived ?? false)
    }

    // MARK: - Öneri listeleri

    /// Sık kullanılan kategoriler önde, sonra varsayılan sıra (Bölüm 6.2-B).
    func orderedCategories(from all: [Category], recent: [Transaction]) -> [Category] {
        var usage: [UUID: Int] = [:]
        for transaction in recent where transaction.kind == kind {
            if let id = transaction.category?.id { usage[id, default: 0] += 1 }
        }
        return all
            .filter { $0.parent == nil && $0.kind == kind && !$0.isArchived }
            .sorted { lhs, rhs in
                let (l, r) = (usage[lhs.id] ?? 0, usage[rhs.id] ?? 0)
                return l != r ? l > r : lhs.sortOrder < rhs.sortOrder
            }
    }

    /// Izgarada gösterilecek kategoriler: sıralı listenin ilk `limit` tanesi.
    /// Seçili kategori bunların arasında değilse (Tümü'nden seçildiyse) sona
    /// eklenir ki ne seçildiği her zaman görünsün.
    func featuredCategories(from ordered: [Category], limit: Int = 7) -> [Category] {
        var featured = Array(ordered.prefix(limit))
        if let category, !featured.contains(category) {
            if featured.count < limit {
                featured.append(category)
            } else {
                featured[featured.count - 1] = category
            }
        }
        return featured
    }

    var subcategories: [Category] {
        (category?.children ?? [])
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Arama varsa Türkçe karakter duyarsız eşleşme (Bölüm 8); yoksa seçili
    /// kategoriye uyan markalar — seçili alt kategorinin markaları önce
    /// (Kahve & Kafe seçiliyken Starbucks, Burger King'den önce gelir).
    /// Online seçiliyse online markalar önce gelir.
    func merchantSuggestions(from all: [Merchant], limit: Int = 8) -> [Merchant] {
        let visible = all.filter { !$0.isHidden }
        let key = SearchKey.make(from: merchantQuery)
        var matches: [Merchant]
        if !key.isEmpty {
            let contained = visible.filter { $0.searchKey.contains(key) }
            matches = contained.filter { $0.searchKey.hasPrefix(key) } + contained.filter { !$0.searchKey.hasPrefix(key) }
        } else if let category {
            // Kullanıcının bu markadaki son seçimi seed önerisinden önceliklidir.
            func suggestion(for merchant: Merchant) -> Category? {
                merchant.lastUsedSubcategory ?? merchant.lastUsedCategory ?? merchant.suggestedCategory
            }
            let inCategory = visible.filter { merchant in
                let suggested = suggestion(for: merchant)
                return suggested == category || suggested?.parent == category
            }
            if let subcategory {
                matches = inCategory.filter { suggestion(for: $0) == subcategory }
                    + inCategory.filter { suggestion(for: $0) != subcategory }
            } else {
                matches = inCategory
            }
        } else {
            matches = []
        }
        if channel == .online {
            matches = matches.filter { $0.lastUsedChannel == .online } + matches.filter { $0.lastUsedChannel != .online }
        }
        return Array(matches.prefix(limit))
    }

    /// Yazılan ad katalogda birebir yoksa "'X' olarak ekle" gösterilir.
    func canAddQueryAsMerchant(existing all: [Merchant]) -> Bool {
        let key = SearchKey.make(from: merchantQuery)
        return !key.isEmpty && !all.contains { $0.searchKey == key }
    }

    // MARK: - Kaydet

    func save(in context: ModelContext) throws {
        guard let amount, amount > 0, let category else { throw SaveError.invalidInput }
        let resolvedMerchant = try resolveMerchant(in: context, category: category)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = trimmedNote.isEmpty ? nil : trimmedNote

        if let transaction = editingTransaction {
            transaction.amount = amount
            transaction.kind = kind
            transaction.category = category
            transaction.subcategory = subcategory
            transaction.merchant = resolvedMerchant
            transaction.channel = channel
            transaction.paymentMethod = paymentMethod
            transaction.note = noteValue
            if transaction.date != date { transaction.updateDate(date) }
            transaction.updatedAt = .now
        } else {
            context.insert(Transaction(
                amount: amount,
                kind: kind,
                date: date,
                note: noteValue,
                channel: channel,
                category: category,
                subcategory: subcategory,
                merchant: resolvedMerchant,
                paymentMethod: paymentMethod
            ))
        }

        if let resolvedMerchant {
            // Bir sonraki öneri kullanıcının bu seçimi olur (Bölüm 6.2-B). Marka
            // kategori hafızası gider içindir; gelir (iade vb.) onu ezmemeli.
            if kind == .expense {
                resolvedMerchant.lastUsedCategory = category
                resolvedMerchant.lastUsedSubcategory = subcategory
            }
            if let channel { resolvedMerchant.lastUsedChannel = channel }
            if let paymentMethod { resolvedMerchant.lastUsedPaymentMethod = paymentMethod }
        }
        try context.saveOrRollback()
    }

    /// Bekleyen yeni marka adı için aynı arama anahtarlı marka varsa onu kullanır;
    /// yoksa oluşturur. Böylece yanlışlıkla çift kayıt oluşmaz (Bölüm 8).
    private func resolveMerchant(in context: ModelContext, category: Category) throws -> Merchant? {
        guard let name = pendingMerchantName else { return merchant }
        let key = SearchKey.make(from: name)
        let existing = try context.fetch(FetchDescriptor<Merchant>(predicate: #Predicate { $0.searchKey == key }))
        if let match = existing.first { return match }
        // Önerilen kategori yalnızca giderden öğrenilir; gelir kategorisi markaya bağlanmaz.
        let created = Merchant(name: name, suggestedCategory: kind == .expense ? (subcategory ?? category) : nil)
        context.insert(created)
        return created
    }
}
