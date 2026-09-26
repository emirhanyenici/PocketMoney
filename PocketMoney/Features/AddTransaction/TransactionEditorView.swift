import OSLog
import SwiftData
import SwiftUI

/// Hızlı Ekle / Düzenle sheet'i (Bölüm 6.2-B). Hedef: 3 dokunuşta kayıt —
/// tutar → kategori → Kaydet. Gerisi katlanabilir "Ayrıntılar" panelinde.
struct TransactionEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(Self.recentDescriptor) private var recentTransactions: [Transaction]

    @State private var model: TransactionEditorModel
    @State private var showsDetails: Bool
    @State private var showsSaveError = false
    @FocusState private var focusedField: EditorField?
    /// Marka veya not yazılırken sistem klavyesi açılır; tuş takımı gizlenir
    /// ki ikisi üst üste binip sonuçları kapatmasın. Görünürlük `focusedField`'dan
    /// ayrı tutulur: odaktaki alan ekrandan kalkınca (marka seçilince)
    /// `FocusState` eski değerde takılı kalabiliyor.
    @State private var isTypingText = false

    private let onSaved: () -> Void

    private static var recentDescriptor: FetchDescriptor<Transaction> {
        var descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 100
        return descriptor
    }

    init(transaction: Transaction? = nil, initialKind: TransactionKind = .expense, onSaved: @escaping () -> Void) {
        let model = TransactionEditorModel(transaction: transaction, initialKind: initialKind)
        _model = State(initialValue: model)
        _showsDetails = State(initialValue: model.hasDetails)
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView { form }
                        .scrollDismissesKeyboard(.immediately)
                        .onChange(of: focusedField) { _, field in
                            // Marka önerileri klavyenin altında kalmasın.
                            guard field == .merchant else { return }
                            withAnimation(.snappy(duration: 0.3)) {
                                proxy.scrollTo(EditorField.merchant, anchor: .top)
                            }
                        }
                }

                if !isTypingText {
                    AmountKeypad { model.expression.input($0) }
                        .padding(Spacing.screen)
                        .background(Color.surfaceMint)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy(duration: 0.25), value: isTypingText)
            .onChange(of: focusedField) { _, field in
                isTypingText = field != nil
            }
            .background(Color.surfaceElevated)
            .navigationTitle(model.isEditing ? "Kaydı düzenle" : "Yeni kayıt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet", role: .confirm, action: save)
                        .disabled(!model.canSave)
                }
            }
            .alert("Kaydedilemedi", isPresented: $showsSaveError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Kayıt sırasında bir sorun oldu. Tekrar dene.")
            }
        }
        // Sheet, tab bar'ın tint'ini devralmaz; toolbar butonları dahil
        // tüm vurgular brandPrimary olmalı (Bölüm 4.1).
        .tint(.brandPrimary)
    }

    private var form: some View {
        VStack(spacing: Spacing.l) {
            kindPicker
            AmountDisplay(model: model)
                // Tutara dokunmak klavyeyi kapatıp tuş takımını geri getirir.
                .onTapGesture(perform: finishTyping)
            EditorCategorySection(
                model: model,
                categories: model.orderedCategories(from: categories, recent: recentTransactions)
            )
            DisclosureGroup("Ayrıntılar", isExpanded: $showsDetails) {
                EditorDetailsSection(model: model, focusedField: $focusedField, onFinishTyping: finishTyping)
                    .padding(.top, Spacing.s)
            }
            .font(.headline)
            .tint(Color.textPrimary)
            .padding(.horizontal, Spacing.screen)
        }
        .padding(.vertical, Spacing.m)
    }

    private var kindPicker: some View {
        Picker("Tür", selection: Binding(get: { model.kind }, set: { model.setKind($0) })) {
            Text("Gider").tag(TransactionKind.expense)
            Text("Gelir").tag(TransactionKind.income)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Spacing.screen)
    }

    private func finishTyping() {
        focusedField = nil
        isTypingText = false
    }

    private func save() {
        do {
            try model.save(in: context)
            onSaved()
            dismiss()
        } catch {
            Logger(subsystem: "PocketMoney", category: "Editor")
                .error("Kayıt başarısız: \(error.localizedDescription, privacy: .public)")
            showsSaveError = true
        }
    }
}

/// Büyük tutar alanı; işlem varsa sonucu altında gösterir.
private struct AmountDisplay: View {
    let model: TransactionEditorModel

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(verbatim: "₺" + (model.expression.isEmpty ? "0" : model.expression.text))
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(model.kind == .income ? Color.income : Color.brandPrimaryDeep)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.25), value: model.expression.text)
            if model.expression.hasOperator, let value = model.amount {
                Text(verbatim: "= " + value.tryFormatted)
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
            }
            if model.isAmountInvalid {
                Text("Tutarı kontrol et. 0'dan büyük bir değer gir.")
                    .font(.footnote)
                    .foregroundStyle(Color.over)
            }
        }
        .padding(.horizontal, Spacing.screen)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tutar")
        .accessibilityValue(Text(verbatim: model.amount?.tryFormatted ?? "₺0"))
    }
}

#if DEBUG
#Preview("Açık mod") {
    TransactionEditorView(onSaved: {})
        .modelContainer(AppModelContainer.preview())
}

#Preview("Koyu mod") {
    TransactionEditorView(onSaved: {})
        .modelContainer(AppModelContainer.preview())
        .preferredColorScheme(.dark)
}
#endif
