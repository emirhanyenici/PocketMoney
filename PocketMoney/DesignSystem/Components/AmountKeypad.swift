import SwiftUI

/// Büyük tuşlu, `+ − ×` destekli hesap makinesi tuş takımı (Bölüm 5.3).
/// Hesap mantığı `AmountExpression`'dadır; bu görünüm yalnızca tuşları iletir.
struct AmountKeypad: View {
    let onKey: (AmountExpression.Key) -> Void

    private let rows: [[AmountExpression.Key]] = [
        [.digit(7), .digit(8), .digit(9), .multiply],
        [.digit(4), .digit(5), .digit(6), .subtract],
        [.digit(1), .digit(2), .digit(3), .add],
        [.decimalSeparator, .digit(0), .delete, .clear]
    ]

    var body: some View {
        Grid(horizontalSpacing: Spacing.xs, verticalSpacing: Spacing.xs) {
            ForEach(rows.indices, id: \.self) { row in
                GridRow {
                    ForEach(rows[row], id: \.self) { key in
                        KeypadButton(key: key) { onKey(key) }
                    }
                }
            }
        }
    }
}

private struct KeypadButton: View {
    let key: AmountExpression.Key
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
                .font(.title2.weight(isOperator ? .semibold : .regular))
                .fontDesign(.rounded)
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(isOperator ? Color.brandPrimary : Color.textPrimary)
                .background(isOperator ? Color.brandMint : Color.surface,
                            in: .rect(cornerRadius: Radius.button, style: .continuous))
                .contentShape(.rect(cornerRadius: Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
    }

    private var isOperator: Bool {
        switch key {
        case .add, .subtract, .multiply: true
        default: false
        }
    }

    @ViewBuilder
    private var label: some View {
        switch key {
        case .digit(let digit): Text(verbatim: "\(digit)")
        case .decimalSeparator: Text(verbatim: ",")
        case .add: Text(verbatim: "+")
        case .subtract: Text(verbatim: "−")
        case .multiply: Text(verbatim: "×")
        case .delete: Image(systemName: "delete.left")
        case .clear: Text(verbatim: "C")
        }
    }

    private var accessibilityTitle: Text {
        switch key {
        case .digit(let digit): Text(verbatim: "\(digit)")
        case .decimalSeparator: Text("Virgül")
        case .add: Text("Artı")
        case .subtract: Text("Eksi")
        case .multiply: Text("Çarpı")
        case .delete: Text("Sil")
        case .clear: Text("Temizle")
        }
    }
}

#Preview("Açık mod") {
    AmountKeypad { _ in }
        .padding()
        .background(Color.surfaceElevated)
}

#Preview("Koyu mod") {
    AmountKeypad { _ in }
        .padding()
        .background(Color.surfaceElevated)
        .preferredColorScheme(.dark)
}
