import SwiftData
import SwiftUI

/// Ayrıntılar panelindeki metin alanları.
enum EditorField: Hashable {
    case merchant
    case note
}

/// Opsiyonel alanlar (Bölüm 6.2-B): marka, kanal, ödeme yöntemi, tarih, not.
struct EditorDetailsSection: View {
    @Bindable var model: TransactionEditorModel
    var focusedField: FocusState<EditorField?>.Binding
    /// Klavyeyi kapatıp tuş takımını geri getirir.
    let onFinishTyping: () -> Void

    @Query(sort: \Merchant.name) private var merchants: [Merchant]
    @Query(sort: \PaymentMethod.sortOrder) private var paymentMethods: [PaymentMethod]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            merchantField
            field("Kanal") {
                HStack(spacing: Spacing.xs) {
                    ForEach(PurchaseChannel.allCases, id: \.self) { channel in
                        Chip(title: channel.title, isSelected: model.channel == channel) {
                            model.toggleChannel(channel)
                        }
                    }
                }
            }
            field("Ödeme yöntemi") {
                ChipSelector(
                    items: paymentMethods,
                    isSelected: { $0 == model.paymentMethod },
                    title: \.name,
                    onSelect: { model.togglePaymentMethod($0) }
                )
                .padding(.horizontal, -Spacing.screen)
            }
            DatePicker("Tarih", selection: $model.date)
                .font(.body)
            TextField("Not", text: $model.note, axis: .vertical)
                .focused(focusedField, equals: .note)
                .font(.body)
                .lineLimit(1...4)
                .padding(Spacing.s)
                .background(Color.surface, in: .rect(cornerRadius: Radius.button, style: .continuous))
        }
        .fontWeight(.regular)
    }

    private var merchantField: some View {
        merchantFieldContent
            // Odaklanınca editör bu alanı yukarı kaydırır ki öneriler klavyenin altında kalmasın.
            .id(EditorField.merchant)
    }

    @ViewBuilder
    private var merchantFieldContent: some View {
        field("Marka / Mağaza") {
            if let name = model.merchantDisplayName {
                HStack {
                    Text(verbatim: name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Button("Markayı kaldır", systemImage: "xmark.circle.fill") { model.clearMerchant() }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Color.textTertiary)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, Spacing.s)
                .background(Color.surface, in: .rect(cornerRadius: Radius.button, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    TextField("Ara veya yeni marka yaz", text: $model.merchantQuery)
                        .focused(focusedField, equals: .merchant)
                        .submitLabel(.done)
                        .onSubmit(onFinishTyping)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding(Spacing.s)
                        .background(Color.surface, in: .rect(cornerRadius: Radius.button, style: .continuous))
                    merchantSuggestions
                }
            }
        }
    }

    private var merchantSuggestions: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.xs) {
                // Gerçek eşleşmeler önce; "olarak ekle" en sonda.
                ForEach(model.merchantSuggestions(from: merchants)) { merchant in
                    Chip(title: merchant.name, isSelected: false) {
                        onFinishTyping()
                        model.selectMerchant(merchant)
                    }
                }
                if model.canAddQueryAsMerchant(existing: merchants) {
                    let name = model.merchantQuery.trimmingCharacters(in: .whitespaces)
                    Chip(title: String(localized: "“\(name)” olarak ekle"), symbol: "plus", isSelected: false) {
                        onFinishTyping()
                        model.addQueryAsNewMerchant()
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func field(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
            content()
        }
    }
}
