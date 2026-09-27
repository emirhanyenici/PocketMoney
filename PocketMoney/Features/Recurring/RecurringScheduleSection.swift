import SwiftUI

/// Formun periyot bölümü: sıklık, ödeme günü, başlangıç, bitiş (Bölüm 9.1).
struct RecurringScheduleSection: View {
    @Bindable var model: RecurringFormModel

    var body: some View {
        Section {
            Picker("Sıklık", selection: $model.frequencyChoice) {
                ForEach(RecurringFormModel.FrequencyChoice.allCases) { Text(verbatim: $0.title).tag($0) }
            }
            if model.frequencyChoice == .custom {
                Stepper(value: $model.customDays, in: 1...365) {
                    Text("Her \(model.customDays) günde bir")
                }
            }
            if model.frequency.usesDayOfMonth {
                Picker("Ödeme günü", selection: $model.dayOfPeriod) {
                    ForEach(1...31, id: \.self) { Text("Ayın \($0). günü").tag($0) }
                }
            }
            DatePicker("Başlangıç", selection: $model.startDate, displayedComponents: .date)

            Picker("Bitiş", selection: $model.ending) {
                ForEach(RecurringFormModel.Ending.allCases) { Text(verbatim: $0.title).tag($0) }
            }
            switch model.ending {
            case .never:
                EmptyView()
            case .installments:
                Stepper(value: $model.installments, in: 1...120) {
                    Text("\(model.installments) taksit kaldı")
                }
            case .date:
                DatePicker("Son ödeme", selection: $model.endDate, in: model.startDate..., displayedComponents: .date)
            }
        } header: {
            Text("Periyot")
        } footer: {
            if model.frequency.usesDayOfMonth, model.dayOfPeriod > 28 {
                Text("Ayda \(model.dayOfPeriod). gün yoksa ödeme ayın son gününe düşer.")
            }
        }
    }
}
