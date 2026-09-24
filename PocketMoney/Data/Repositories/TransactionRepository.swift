import Foundation
import SwiftData

/// İşlem silme, geri alma ve kopyalama (Bölüm 6.2-C, Bölüm 5.4).
struct TransactionRepository {
    let context: ModelContext

    /// Silinen işlemi geri almak için gereken her şey. İlişkili kategori, marka
    /// ve ödeme yöntemi silinmediği için referans olarak tutulabilir.
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
        try context.save()
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
            category: snapshot.category,
            subcategory: snapshot.subcategory,
            merchant: snapshot.merchant,
            paymentMethod: snapshot.paymentMethod
        )
        transaction.id = snapshot.id
        transaction.localDay = snapshot.localDay
        transaction.createdAt = snapshot.createdAt
        transaction.recurringPayment = snapshot.recurringPayment
        transaction.recurringPeriodKey = snapshot.recurringPeriodKey
        context.insert(transaction)
        try context.save()
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
        try context.save()
        return copy
    }
}
