import SwiftData
import SwiftUI

/// Ana kategori oluşturma / düzenleme: ad, renk, ikon (Bölüm 6.2-F).
struct CategoryFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let kind: TransactionKind
    private let category: Category?

    @State private var name: String
    @State private var symbolName: String
    @State private var color: CategoryColor
    @State private var errorMessage: String?

    init(kind: TransactionKind, category: Category? = nil) {
        self.kind = category?.kind ?? kind
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _symbolName = State(initialValue: category?.symbolName ?? "tag.fill")
        _color = State(initialValue: category.flatMap { CategoryColor(rawValue: $0.colorToken) } ?? .stone)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: Spacing.s) {
                        CategoryIcon(symbolName: symbolName, colorToken: color.rawValue, size: 44)
                        TextField("Kategori adı", text: $name)
                            .font(.body.weight(.semibold))
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                    }
                    if let errorMessage {
                        Text(verbatim: errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.over)
                    }
                }
                .listRowBackground(Color.surface)

                Section("Renk") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.s) {
                        ForEach(CategoryColor.allCases, id: \.self) { option in
                            Button { color = option } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if option == color {
                                            Image(systemName: "checkmark")
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(verbatim: option.title))
                            .accessibilityAddTraits(option == color ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, Spacing.xxs)
                }
                .listRowBackground(Color.surface)

                Section("İkon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Spacing.xs) {
                        ForEach(CategorySymbols.all, id: \.self) { symbol in
                            Button { symbolName = symbol } label: {
                                Image(systemName: symbol)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(symbol == symbolName ? Color.brandPrimaryDeep : Color.textSecondary)
                                    .background(symbol == symbolName ? Color.brandMint : Color.clear,
                                                in: .rect(cornerRadius: Radius.button, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(symbol == symbolName ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, Spacing.xxs)
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
            // Klavye renk/ikon ızgarasını kapatmasın: kaydırınca kapanır.
            .scrollDismissesKeyboard(.immediately)
            .background(Color.surfaceElevated)
            .navigationTitle(category == nil ? "Yeni kategori" : "Kategoriyi düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet", role: .confirm, action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .tint(.brandPrimary)
    }

    private func save() {
        let repository = CategoryRepository(context: context)
        do {
            if let category {
                try repository.update(category, name: name, symbolName: symbolName, colorToken: color.rawValue)
            } else {
                try repository.createMain(name: name, symbolName: symbolName, colorToken: color.rawValue, kind: kind)
            }
            dismiss()
        } catch {
            errorMessage = ManagementErrorMessage.text(for: error)
        }
    }
}

#if DEBUG
#Preview("Açık mod") {
    CategoryFormView(kind: .expense)
        .modelContainer(AppModelContainer.preview(withTransactions: false))
}

#Preview("Koyu mod") {
    CategoryFormView(kind: .expense)
        .modelContainer(AppModelContainer.preview(withTransactions: false))
        .preferredColorScheme(.dark)
}
#endif
