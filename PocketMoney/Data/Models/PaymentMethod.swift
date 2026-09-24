import Foundation
import SwiftData

extension SchemaV1 {
    /// "Nakit", "Bonus Kart" gibi ödeme yöntemi (Bölüm 12).
    @Model
    final class PaymentMethod {
        @Attribute(.unique) var id: UUID
        var name: String
        var typeRaw: String
        var sortOrder: Int

        var type: PaymentMethodType {
            get { PaymentMethodType(rawValue: typeRaw) ?? .other }
            set { typeRaw = newValue.rawValue }
        }

        init(name: String, type: PaymentMethodType, sortOrder: Int) {
            self.id = UUID()
            self.name = name
            self.typeRaw = type.rawValue
            self.sortOrder = sortOrder
        }
    }
}
