import Foundation

/// Alt tab bar sekmeleri (Bölüm 6.1). Analiz v0.3'te eklenir.
enum AppTab: Hashable {
    case overview
    case transactions
    /// Sekme değil; seçildiğinde ekleme sheet'i açılır, önceki sekme korunur.
    case add
    /// Şimdilik yalnızca Düzenli Ödemeler; Bütçeler v0.3'te segment olarak gelir.
    case plan
}

/// Ekleme/düzenleme sheet'inin nasıl açıldığı.
enum EditorPresentation: Identifiable {
    /// Yeni kayıt; tür "+" için gider, Özet'teki "Gelir ekle" için gelir.
    case new(TransactionKind)
    case edit(Transaction)

    var id: String {
        switch self {
        case .new(let kind): "new-\(kind.rawValue)"
        case .edit(let transaction): transaction.id.uuidString
        }
    }

    var transaction: Transaction? {
        if case .edit(let transaction) = self { transaction } else { nil }
    }

    var initialKind: TransactionKind {
        switch self {
        case .new(let kind): kind
        case .edit(let transaction): transaction.kind
        }
    }
}
