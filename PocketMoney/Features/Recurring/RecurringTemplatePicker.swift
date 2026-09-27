import SwiftUI

/// Hazır abonelik ve fatura şablonları (Bölüm 9.2). Fiyat yok; tutarı kullanıcı girer.
struct RecurringTemplatePicker: View {
    @Environment(\.dismiss) private var dismiss

    /// `nil`: boş form.
    let onPick: (RecurringTemplate?) -> Void

    @State private var search = ""
    private let templates = RecurringTemplates.load()

    private var groups: [(group: String, items: [RecurringTemplate])] {
        let key = SearchKey.make(from: search)
        let filtered = key.isEmpty ? templates : templates.filter { SearchKey.make(from: $0.name).contains(key) }
        return RecurringTemplates.grouped(filtered)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        pick(nil)
                    } label: {
                        Label("Kendin oluştur", systemImage: "square.and.pencil")
                            .foregroundStyle(Color.brandPrimaryDeep)
                    }
                }
                .listRowBackground(Color.surface)

                ForEach(groups, id: \.group) { group in
                    Section {
                        ForEach(group.items) { template in
                            Button { pick(template) } label: {
                                HStack {
                                    Text(verbatim: template.name).foregroundStyle(Color.textPrimary)
                                    Spacer()
                                    Text(verbatim: template.recurrence.title)
                                        .font(.footnote)
                                        .foregroundStyle(Color.textSecondary)
                                }
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text(verbatim: group.group)
                    }
                    .listRowBackground(Color.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceElevated)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Abonelik ara")
            .navigationTitle("Düzenli ödeme ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", role: .cancel) { dismiss() }
                }
            }
        }
        .tint(.brandPrimary)
    }

    private func pick(_ template: RecurringTemplate?) {
        onPick(template)
        dismiss()
    }
}

#Preview("Açık mod") {
    RecurringTemplatePicker { _ in }
}

#Preview("Koyu mod") {
    RecurringTemplatePicker { _ in }
        .preferredColorScheme(.dark)
}
