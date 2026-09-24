import SwiftUI

/// Yatay kaydırılabilir seçim çipleri (Bölüm 5.3). Seçimin nasıl değişeceğine
/// (tekrar dokununca kaldırma vb.) çağıran taraf karar verir.
struct ChipSelector<Item: Identifiable>: View {
    let items: [Item]
    let isSelected: (Item) -> Bool
    let title: (Item) -> String
    var symbol: ((Item) -> String?)? = nil
    let onSelect: (Item) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: Spacing.xs) {
                    ForEach(items) { item in
                        Chip(
                            title: title(item),
                            symbol: symbol?(item),
                            isSelected: isSelected(item)
                        ) {
                            onSelect(item)
                        }
                        .id(item.id)
                    }
                }
                .padding(.horizontal, Spacing.screen)
            }
            .scrollIndicators(.hidden)
            // Seçili çip kenarda yarım kalmasın; ne seçildiği her zaman görünsün.
            .onChange(of: selectedID) { _, id in
                guard let id else { return }
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.3)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
            .onAppear {
                if let selectedID { proxy.scrollTo(selectedID, anchor: .center) }
            }
        }
    }

    private var selectedID: Item.ID? {
        items.first(where: isSelected)?.id
    }
}

/// Tek bir kapsül çip. Seçili durumda nane zemin ve yeşil kenarlık (Bölüm 4.1).
struct Chip: View {
    let title: String
    var symbol: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs + 2) {
                if let symbol {
                    Image(systemName: symbol)
                        .imageScale(.small)
                }
                Text(verbatim: title)
                    .lineLimit(1)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .padding(.horizontal, Spacing.s + 2)
            .frame(minHeight: 44)
            .foregroundStyle(isSelected ? Color.brandPrimaryDeep : Color.textPrimary)
            .background(isSelected ? Color.brandMint : Color.surface, in: .capsule)
            .overlay {
                Capsule().strokeBorder(isSelected ? Color.brandPrimary : Color.divider, lineWidth: 1)
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct PreviewItem: Identifiable {
    let id: Int
    let name: String
}

#Preview("Açık mod") {
    ChipSelector(
        items: [PreviewItem(id: 1, name: "Market & Gıda"), PreviewItem(id: 2, name: "Yeme & İçme"), PreviewItem(id: 3, name: "Ulaşım")],
        isSelected: { $0.id == 2 },
        title: \.name,
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(Color.background)
}

#Preview("Koyu mod") {
    ChipSelector(
        items: [PreviewItem(id: 1, name: "Market & Gıda"), PreviewItem(id: 2, name: "Yeme & İçme"), PreviewItem(id: 3, name: "Ulaşım")],
        isSelected: { $0.id == 2 },
        title: \.name,
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(Color.background)
    .preferredColorScheme(.dark)
}
