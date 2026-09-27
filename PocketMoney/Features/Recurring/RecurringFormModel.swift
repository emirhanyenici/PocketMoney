import Foundation
import Observation

/// Düzenli ödeme formunun durumu; ekle ve düzenle aynı modeli kullanır (Bölüm 9.1).
@Observable
final class RecurringFormModel: Identifiable {
    /// Formdaki periyot seçimi; "özel" gün sayısı ayrı tutulur.
    enum FrequencyChoice: String, CaseIterable, Identifiable {
        case weekly, monthly, quarterly, semiannual, yearly, custom
        var id: String { rawValue }

        var title: String {
            switch self {
            case .custom: String(localized: "Her N günde bir")
            default: frequency(customDays: 1).title
            }
        }

        func frequency(customDays: Int) -> RecurrenceFrequency {
            switch self {
            case .weekly: .weekly
            case .monthly: .monthly
            case .quarterly: .quarterly
            case .semiannual: .semiannual
            case .yearly: .yearly
            case .custom: .customDays(max(customDays, 1))
            }
        }

        init(_ frequency: RecurrenceFrequency) {
            switch frequency {
            case .weekly: self = .weekly
            case .monthly: self = .monthly
            case .quarterly: self = .quarterly
            case .semiannual: self = .semiannual
            case .yearly: self = .yearly
            case .customDays: self = .custom
            }
        }
    }

    enum Ending: String, CaseIterable, Identifiable {
        case never, installments, date
        var id: String { rawValue }
        var title: String {
            switch self {
            case .never: String(localized: "Bitmez")
            case .installments: String(localized: "Taksit sayısı")
            case .date: String(localized: "Bitiş tarihi")
            }
        }
    }

    let id = UUID()
    let payment: RecurringPayment?

    var name: String
    var amountText: String
    var category: Category?
    var subcategory: Category?
    var paymentMethod: PaymentMethod?
    var frequencyChoice: FrequencyChoice
    var customDays: Int
    var dayOfPeriod: Int
    var startDate: Date
    var autoPost: Bool
    var ending: Ending
    var installments: Int
    var endDate: Date

    init(payment: RecurringPayment? = nil, template: RecurringTemplate? = nil, categories: [Category] = [], now: Date = .now) {
        self.payment = payment
        let calendar = LocalDay.currentCalendar
        name = payment?.name ?? template?.name ?? ""
        amountText = payment.map { $0.amount.editableTurkish } ?? ""
        let frequency = payment?.frequency ?? template?.recurrence ?? .monthly
        frequencyChoice = FrequencyChoice(frequency)
        customDays = frequency.customDays ?? 30
        dayOfPeriod = payment?.dayOfPeriod ?? calendar.component(.day, from: now)
        startDate = payment?.startDate ?? now
        autoPost = payment?.mode == .autoPost
        paymentMethod = payment?.paymentMethod
        installments = payment?.remainingInstallments ?? 12
        endDate = payment?.endDate ?? calendar.date(byAdding: .year, value: 1, to: now) ?? now
        ending = payment?.remainingInstallments != nil ? .installments : (payment?.endDate != nil ? .date : .never)

        if let payment {
            category = payment.category
            subcategory = payment.subcategory
        } else if let template {
            // Şablon kategori adlarıyla gelir; kullanıcı kategorisini yeniden adlandırdıysa boş kalır.
            let main = categories.first { $0.name == template.category && $0.parent == nil }
            category = main
            subcategory = template.subcategory.flatMap { sub in main?.children.first { $0.name == sub } }
        }
    }

    var amount: Decimal? { Decimal(turkish: amountText) }
    var frequency: RecurrenceFrequency { frequencyChoice.frequency(customDays: customDays) }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (amount ?? 0) > 0 && category != nil
    }

    var draft: RecurringPaymentRepository.Draft {
        RecurringPaymentRepository.Draft(
            name: name,
            amount: amount ?? 0,
            frequency: frequency,
            dayOfPeriod: dayOfPeriod,
            startDate: startDate,
            endDate: ending == .date ? endDate : nil,
            installments: ending == .installments ? max(installments, 1) : nil,
            mode: autoPost ? .autoPost : .confirm,
            reminderDaysBefore: payment?.reminderDaysBefore,
            category: category,
            subcategory: subcategory,
            merchant: payment?.merchant,
            paymentMethod: paymentMethod
        )
    }
}
