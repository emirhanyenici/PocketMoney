import Foundation
import SwiftData

/// İşlem silme, geri alma ve kopyalama (Bölüm 6.2-C, Bölüm 5.4).
struct TransactionRepository {
    let context: ModelContext

    /// Silinen işlemi geri almak için gereken her şey. İlişkiler referans olarak
    /// tutulur; geri alınana kadar silinmiş olanlar `restore` sırasında düşürülür.
    struct Snapshot {
        fileprivate let id: UUID
        fileprivate let amount: Decimal
        fileprivate let currencyCode: String
        fileprivate let kind: TransactionKind
        fileprivate let date: Date
        fileprivate let localDay: String
        fileprivate let note: String?
        fileprivate let tags: [String]
        fileprivate let channel: PurchaseChannel?
        fileprivate let createdAt: Date
        fileprivate let category: Category?
        fileprivate let subcategory: Category?
        fileprivate let merchant: Merchant?
        fileprivate let paymentMethod: PaymentMethod?
        fileprivate let recurringPayment: RecurringPayment?
        fileprivate let recurringPeriodKey: String?
    }

    func delete(_ transaction: Transaction) throws -> Snapshot {
        let snapshot = Snapshot(
            id: transaction.id,
            amount: transaction.amount,
            currencyCode: transaction.currencyCode,
            kind: transaction.kind,
            date: transaction.date,
            localDay: transaction.localDay,
            note: transaction.note,
            tags: transaction.tags,
            channel: transaction.channel,
            createdAt: transaction.createdAt,
            category: transaction.category,
            subcategory: transaction.subcategory,
            merchant: transaction.merchant,
            paymentMethod: transaction.paymentMethod,
            recurringPayment: transaction.recurringPayment,
            recurringPeriodKey: transaction.recurringPeriodKey
        )
        context.delete(transaction)
        try context.saveOrRollback()
        return snapshot
    }

    /// Silinen işlemi aynı kimlik ve aynı yerel günle geri koyar.
    func restore(_ snapshot: Snapshot) throws {
        let transaction = Transaction(
            amount: snapshot.amount,
            kind: snapshot.kind,
            date: snapshot.date,
            currencyCode: snapshot.currencyCode,
            note: snapshot.note,
            tags: snapshot.tags,
            channel: snapshot.channel,
            category: live(snapshot.category),
            subcategory: live(snapshot.subcategory),
            merchant: live(snapshot.merchant),
            paymentMethod: live(snapshot.paymentMethod)
        )
        transaction.id = snapshot.id
        transaction.localDay = snapshot.localDay
        transaction.createdAt = snapshot.createdAt
        transaction.recurringPayment = live(snapshot.recurringPayment)
        transaction.recurringPeriodKey = snapshot.recurringPeriodKey
        context.insert(transaction)
        try context.saveOrRollback()
    }

    /// Geri alma penceresinde silinen (ör. kategori silme, marka birleştirme)
    /// modele bağlanmak kaydı bozar; o ilişki boş bırakılır.
    private func live<Model: PersistentModel>(_ model: Model?) -> Model? {
        guard let model, !model.isDeleted, model.modelContext != nil else { return nil }
        return model
    }

    /// Aynı harcamayı şimdiki zamanla tekrar ekler (sağa kaydır: Kopyala).
    @discardableResult
    func duplicateToNow(_ transaction: Transaction) throws -> Transaction {
        let copy = Transaction(
            amount: transaction.amount,
            kind: transaction.kind,
            currencyCode: transaction.currencyCode,
            note: transaction.note,
            tags: transaction.tags,
            channel: transaction.channel,
            category: transaction.category,
            subcategory: transaction.subcategory,
            merchant: transaction.merchant,
            paymentMethod: transaction.paymentMethod
        )
        context.insert(copy)
        try context.saveOrRollback()
        return copy
    }
}
