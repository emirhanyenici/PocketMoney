import SwiftData
import SwiftUI

/// Planla > Düzenli Ödemeler (Bölüm 6.2-E). Bütçeler v0.3'te gelince üstte
/// `Bütçeler | Düzenli Ödemeler` segmenti eklenir (Bölüm 22).
struct RecurringListView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(AppSettings.periodStartDayKey) private var periodStartDay = AppSettings.defaultPeriodStartDay

    @Query(sort: \RecurringPayment.nextDueDate) private var payments: [RecurringPayment]
    @Query(filter: #Predicate<Category> { $0.parent == nil }) private var mainCategories: [Category]

    /// Toast RootTabView'da gösterilir.
    let onMessage: (String) -> Void

    @State private var showsTemplates = false
    @State private var pickedTemplate: RecurringTemplate?
    @State private var startsBlankForm = false
    @State private var form: RecurringFormModel?
    @State private var paying: RecurringPayment?

    private var repository: RecurringPaymentRepository { RecurringPaymentRepository(context: context) }

    var body: some View {
        NavigationStack {
            List {
                if !payments.isEmpty {
                    Section {
                        RecurringSummaryCard(
                            payments: payments,
                            period: PeriodCalculator(startDay: periodStartDay).period(containing: .now)
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                ForEach(groups, id: \.group) { section in
                    Section(section.group.title) {
                        ForEach(section.items) { payment in
                            Button { form = RecurringFormModel(payment: payment) } label: {
                                RecurringRow(payment: payment, status: repository.status(of: payment)) {
                                    paying = payment
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                if repository.status(of: payment).isAwaitingConfirmation {
                                    Button("Ödendi") { paying = payment }.tint(.brandPrimary)
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .overlay {
                if payments.isEmpty {
                    EmptyStateView(
                        symbolName: "calendar.badge.clock",
                        message: "Kira, fatura ve aboneliklerini ekle; vadesi gelince hatırlatayım.",
                        actionTitle: "Düzenli ödeme ekle",
                        action: { showsTemplates = true }
                    )
                }
            }
            .navigationTitle("Planla")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Düzenli ödeme ekle", systemImage: "plus") { showsTemplates = true }
                }
            }
            .sheet(isPresented: $showsTemplates, onDismiss: openPickedTemplate) {
                RecurringTemplatePicker { template in
                    pickedTemplate = template
                    startsBlankForm = template == nil
                }
            }
            .sheet(item: $form) { RecurringFormView(model: $0) }
            .sheet(item: $paying) { MarkPaidSheet(payment: $0, onDone: onMessage) }
        }
        .tint(.brandPrimary)
    }

    /// Aktifler grup sırasıyla; bitenler en altta "Biten ödemeler".
    private var groups: [(group: RecurringGroup, items: [RecurringPayment])] {
        let active = payments.filter(\.isActive)
        return RecurringGroup.allCases.compactMap { group in
            let items = active.filter { RecurringGroup(category: $0.category) == group }
            return items.isEmpty ? nil : (group, items)
        } + (payments.contains { !$0.isActive } ? [(.ended, payments.filter { !$0.isActive })] : [])
    }

    /// Şablon sheet'i kapanınca form açılır; iki sheet aynı anda açılamaz.
    private func openPickedTemplate() {
        guard pickedTemplate != nil || startsBlankForm else { return }
        form = RecurringFormModel(template: pickedTemplate, categories: mainCategories)
        pickedTemplate = nil
        startsBlankForm = false
    }
}

#if DEBUG
#Preview("Açık mod") {
    RecurringListView(onMessage: { _ in })
        .modelContainer(AppModelContainer.preview())
}

#Preview("Koyu mod") {
    RecurringListView(onMessage: { _ in })
        .modelContainer(AppModelContainer.preview())
        .preferredColorScheme(.dark)
}

#Preview("Boş") {
    RecurringListView(onMessage: { _ in })
        .modelContainer(AppModelContainer.preview(withTransactions: false))
}
#endif
