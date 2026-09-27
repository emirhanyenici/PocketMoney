import OSLog
import SwiftData
import SwiftUI

/// "Ödendi mi?" (Bölüm 9.1): tutar bu vade için değiştirilebilir (elektrik,
/// doğalgaz). "Bu vadeyi atla" işlem oluşturmadan vadeyi ilerletir.
struct MarkPaidSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let payment: RecurringPayment
    let onDone: (String) -> Void

    @State private var amountText: String
    @State private var paidOn = Date.now
    @State private var errorMessage: String?

    init(payment: RecurringPayment, onDone: @escaping (String) -> Void) {
        self.payment = payment
        self.onDone = onDone
        _amountText = State(initialValue: payment.amount.editableTurkish)
    }

    private var amount: Decimal? { Decimal(turkish: amountText) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Tutar") {
                        TextField("Tutar", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.body.weight(.semibold).monospacedDigit())
                    }
                    DatePicker("Ödeme tarihi", selection: $paidOn, in: ...Date.now, displayedComponents: .date)
                } footer: {
                    Text("Tutar yalnızca bu vade için değişir; düzenli tutar aynı kalır.")
                }
                .listRowBackground(Color.surface)

                if let errorMessage {
                    Text(verbatim: errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.over)
                        .listRowBackground(Color.surface)
                }

                Section {
                    Button("Bu vadeyi atla", action: skip)
                        .foregroundStyle(Color.textSecondary)
                } footer: {
                    Text("Bu vade ödenmediyse veya iptal olduysa: işlem eklenmez, sonraki vadeye geçilir.")
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceElevated)
            .navigationTitle(Text(verbatim: payment.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ödendi", role: .confirm, action: pay)
                        .disabled((amount ?? 0) <= 0)
                }
            }
        }
        .tint(.brandPrimary)
        .presentationDetents([.medium, .large])
    }

    private func pay() {
        do {
            try RecurringPaymentRepository(context: context).markPaid(payment, amount: amount, on: paidOn)
            onDone(String(localized: "Ödendi olarak kaydedildi"))
            dismiss()
        } catch {
            Logger(subsystem: "PocketMoney", category: "Recurring")
                .error("Ödendi kaydı başarısız: \(error.localizedDescription, privacy: .public)")
            errorMessage = String(localized: "Kaydedilemedi. Tutarı kontrol edip tekrar dene.")
        }
    }

    private func skip() {
        do {
            try RecurringPaymentRepository(context: context).skip(payment)
            onDone(String(localized: "Bu vade atlandı"))
            dismiss()
        } catch {
            errorMessage = String(localized: "Atlanamadı. Tekrar dene.")
        }
    }
}

extension Decimal {
    /// "1.135,40" / "1135,4" / "229.99" → Decimal. Boş veya geçersizse `nil`.
    init?(turkish text: String) {
        var cleaned = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "₺", with: "")
        if cleaned.contains(",") {
            cleaned = cleaned.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        }
        guard !cleaned.isEmpty, let value = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) else { return nil }
        self = value
    }

    /// Düzenlenebilir metin: 229.99 → "229,99" (binlik ayırıcı yok).
    var editableTurkish: String {
        NSDecimalNumber(decimal: self).stringValue.replacingOccurrences(of: ".", with: ",")
    }
}

#if DEBUG
#Preview("Açık mod") {
    MarkPaidPreview()
        .modelContainer(AppModelContainer.preview())
}

#Preview("Koyu mod") {
    MarkPaidPreview()
        .modelContainer(AppModelContainer.preview())
        .preferredColorScheme(.dark)
}

private struct MarkPaidPreview: View {
    @Query private var payments: [RecurringPayment]

    var body: some View {
        if let payment = payments.first {
            MarkPaidSheet(payment: payment) { _ in }
        }
    }
}
#endif
