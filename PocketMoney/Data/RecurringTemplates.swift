import Foundation

/// Hazır düzenli ödeme şablonu (Bölüm 9.2). Fiyat şablona gömülmez;
/// yalnızca ad, kategori ve periyot sağlar, tutarı kullanıcı girer.
nonisolated struct RecurringTemplate: Decodable, Hashable, Sendable, Identifiable {
    let name: String
    /// Listede başlık: "İzleme", "Dinleme"...
    let group: String
    let category: String
    let subcategory: String?
    let frequency: String

    var id: String { name }

    var recurrence: RecurrenceFrequency {
        RecurrenceFrequency(storageKey: frequency, customDays: nil) ?? .monthly
    }
}

nonisolated enum RecurringTemplates {
    /// `Data/Seed/recurringTemplates.json`; kapanan servisler JSON'dan çıkarılır.
    static func load(bundle: Bundle = .main) -> [RecurringTemplate] {
        guard let url = bundle.url(forResource: "recurringTemplates", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let templates = try? JSONDecoder().decode([RecurringTemplate].self, from: data)
        else { return [] }
        return templates
    }

    /// JSON sırasını koruyarak gruplar.
    static func grouped(_ templates: [RecurringTemplate]) -> [(group: String, items: [RecurringTemplate])] {
        var order: [String] = []
        var items: [String: [RecurringTemplate]] = [:]
        for template in templates {
            if items[template.group] == nil { order.append(template.group) }
            items[template.group, default: []].append(template)
        }
        return order.map { ($0, items[$0] ?? []) }
    }
}
