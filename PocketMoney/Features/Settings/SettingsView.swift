import SwiftUI

/// Ayarlar (Bölüm 6.2-F). Şimdilik yalnızca dönem başlangıç günü; kategori,
/// marka ve diğer bölümler v0.1'in 6. maddesiyle eklenecek.
struct SettingsView: View {
    @AppStorage(AppSettings.periodStartDayKey) private var periodStartDay = AppSettings.defaultPeriodStartDay

    private var calculator: PeriodCalculator { PeriodCalculator(startDay: periodStartDay) }

    var body: some View {
        Form {
            Section {
                Picker("Dönem başlangıç günü", selection: $periodStartDay) {
                    ForEach(1...28, id: \.self) { day in
                        // Kısa tutulur; uzun etiket satırı iki satıra bölüyordu.
                        Text("Ayın \(day). günü").tag(day)
                    }
                }
                .pickerStyle(.navigationLink)

                LabeledContent("Şu anki dönem") {
                    Text(verbatim: calculator.rangeTitle(for: calculator.period(containing: .now)))
                        .monospacedDigit()
                }
            } header: {
                Text("Dönem")
            } footer: {
                Text("1 seçiliyse dönemler takvim ayıdır. Maaşının yattığı günü seçersen dönemlerin o günden başlar; örneğin 15 seçersen Eylül dönemi 15 Eylül'den 14 Ekim'e kadar sürer. Kayıtların değişmez, yalnızca gruplanışı değişir.")
            }
            .listRowBackground(Color.surface)
        }
        .scrollContentBackground(.hidden)
        .background(Color.background)
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Açık mod") {
    NavigationStack { SettingsView() }
}

#Preview("Koyu mod") {
    NavigationStack { SettingsView() }
        .preferredColorScheme(.dark)
}
