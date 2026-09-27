import Foundation
import SwiftData
import Testing
@testable import PocketMoney

/// Hazır abonelik şablonları (Bölüm 9.2).
@MainActor
struct RecurringTemplatesTests {
    private let templates = RecurringTemplates.load()

    @Test func loadsGuidelineTemplates() {
        let names = Set(templates.map(\.name))
        for expected in ["Netflix", "Spotify", "iCloud+", "Xbox Game Pass", "Spor salonu", "Kira"] {
            #expect(names.contains(expected))
        }
        // BluTV HBO Max çatısına geçti; ayrı şablon yok (Bölüm 9.2).
        #expect(!names.contains("BluTV"))
        #expect(names.count == templates.count)
    }

    @Test func everyTemplatePointsToSeededCategory() throws {
        let container = try AppModelContainer.make(inMemory: true)
        try SeedLoader(context: container.mainContext).seedIfNeeded()
        let categories = try container.mainContext.fetch(FetchDescriptor<PocketMoney.Category>())
        for template in templates {
            let main = categories.first { $0.name == template.category && $0.parent == nil }
            #expect(main != nil, "\(template.name): \(template.category)")
            if let sub = template.subcategory {
                #expect(main?.children.contains { $0.name == sub } == true, "\(template.name): \(sub)")
            }
            #expect(RecurrenceFrequency(storageKey: template.frequency, customDays: nil) != nil)
        }
    }

    @Test func groupsKeepJSONOrder() {
        let groups = RecurringTemplates.grouped(templates).map(\.group)
        #expect(groups.first == "İzleme")
        #expect(Set(groups).count == groups.count)
    }
}
