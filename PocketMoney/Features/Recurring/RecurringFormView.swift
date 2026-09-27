import OSLog
import SwiftData
import SwiftUI

/// Düzenli ödeme ekle / düzenle (Bölüm 9.1). Varsayılan mod "Onayla"dır;
/// otomatik kayıt kullanıcı açarsa devreye girer (Bölüm 2, ilke 9).
struct RecurringFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Category> { $0.parent == nil && !$0.isArchived }, sort: \Category.sortOrder)
    private var mainCategories: [Category]
    @Query(sort: \PaymentMethod.sortOrder) private var paymentMethods: [PaymentMethod]

    @State private var model: RecurringFormModel
    @State private var showsCategoryPicker = false
    @State private var confirmsDelete = false
    @State private var errorMessage: String?

    init(model: RecurringFormModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Ad (ör. Kira, Netflix)", text: $model.name)
                        .textInputAutocapitalization(.words)
                    LabeledContent("Tutar") {
                        TextField("₺0", text: $model.amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
                    categoryRow
                    Picker("Ödeme yöntemi", selection: $model.paymentMethod) {
                        Text("Seçilmedi").tag(PaymentMethod?.none)
                        ForEach(paymentMethods) { Text(verbatim: $0.name).tag(Optional($0)) }
                    }
                } footer: {
                    if let errorMessage {
                        Text(verbatim: errorMessage).foregroundStyle(Color.over)
                    }
                }
                .listRowBackground(Color.surface)

                RecurringScheduleSection(model: model)
                    .listRowBackground(Color.surface)

                Section {
                    Toggle("Otomatik kaydet", isOn: $model.autoPost)
                } footer: {
                    Text(model.autoPost
                         ? "Vadesi gelince işlem kendiliğinden eklenir. Karttan kesin çekilen sabit tutarlı ödemeler için uygundur."
                         : "Vadesi gelince Planla'da bekler; \"Ödendi\" deyince işlem eklenir. Tutar o ay farklıysa değiştirebilirsin.")
                }
                .listRowBackground(Color.surface)

                if let payment = model.payment {
                    priceHistorySection(payment)
                    Section {
                        Button("Düzenli ödemeyi sil", role: .destructive) { confirmsDelete = true }
                    } footer: {
                        Text("Geçmiş işlemlerin silinmez.")
                    }
                    .listRowBackground(Color.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .background(Color.surfaceElevated)
            .navigationTitle(model.payment == nil ? "Yeni düzenli ödeme" : "Düzenli ödeme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet", role: .confirm, action: save).disabled(!model.canSave)
                }
            }
            .sheet(isPresented: $showsCategoryPicker) {
                CategoryPickerSheet(
                    categories: mainCategories.filter { $0.kind == .expense },
                    selectedCategory: model.category,
                    selectedSubcategory: model.subcategory
                ) { category, subcategory in
                    model.category = category
                    model.subcategory = subcategory
                }
            }
            .confirmationDialog("Düzenli ödeme silinsin mi?", isPresented: $confirmsDelete, titleVisibility: .visible) {
                Button("Sil", role: .destructive, action: delete)
            } message: {
                Text("Geçmiş işlemlerin silinmez.")
            }
        }
        .tint(.brandPrimary)
    }

    private var categoryRow: some View {
        Button { showsCategoryPicker = true } label: {
            HStack(spacing: Spacing.s) {
                CategoryIcon(category: model.category, size: 32)
                Text(verbatim: model.subcategory?.name ?? model.category?.name ?? String(localized: "Kategori seç"))
                    .foregroundStyle(model.category == nil ? Color.textSecondary : Color.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Kategori"))
        .accessibilityValue(Text(verbatim: model.subcategory?.name ?? model.category?.name ?? String(localized: "Seçilmedi")))
    }

    /// "Fiyat arttı: ₺199,99 → ₺229,99" (Bölüm 9.3).
    @ViewBuilder
    private func priceHistorySection(_ payment: RecurringPayment) -> some View {
        if !payment.priceHistory.isEmpty {
            Section("Fiyat geçmişi") {
                ForEach(payment.priceHistory.reversed(), id: \.self) { change in
                    LabeledContent {
                        Text(verbatim: "\(change.oldAmount.tryFormatted) → \(change.newAmount.tryFormatted)")
                            .monospacedDigit()
                    } label: {
                        Text(change.newAmount > change.oldAmount ? "Fiyat arttı" : "Fiyat düştü")
                        Text(verbatim: change.date.formatted(.dateTime.day().month(.wide).year().locale(Decimal.turkishLocale)))
                    }
                }
            }
            .listRowBackground(Color.surface)
        }
    }

    private func save() {
        let repository = RecurringPaymentRepository(context: context)
        do {
            if let payment = model.payment {
                try repository.update(payment, with: model.draft)
            } else {
                try repository.create(model.draft)
            }
            dismiss()
        } catch {
            Logger(subsystem: "PocketMoney", category: "Recurring")
                .error("Düzenli ödeme kaydedilemedi: \(error.localizedDescription, privacy: .public)")
            errorMessage = String(localized: "Kaydedilemedi. Ad ve tutarı kontrol edip tekrar dene.")
        }
    }

    private func delete() {
        guard let payment = model.payment else { return }
        do {
            try RecurringPaymentRepository(context: context).delete(payment)
            dismiss()
        } catch {
            errorMessage = String(localized: "Silinemedi. Tekrar dene.")
        }
    }
}

#if DEBUG
#Preview("Açık mod") {
    RecurringFormView(model: RecurringFormModel(template: RecurringTemplates.load().first))
        .modelContainer(AppModelContainer.preview(withTransactions: false))
}

#Preview("Koyu mod") {
    RecurringFormView(model: RecurringFormModel())
        .modelContainer(AppModelContainer.preview(withTransactions: false))
        .preferredColorScheme(.dark)
}
#endif
