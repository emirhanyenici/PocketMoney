import Foundation

/// `AmountKeypad`'in hesap makinesi mantığı (Bölüm 5.3): "12,5+3×2".
/// Virgül ondalık ayırıcıdır (Bölüm 13). × işlemi + ve −'den önce yapılır.
nonisolated struct AmountExpression: Equatable, Sendable {
    enum Key: Hashable, Sendable {
        case digit(Int)
        case decimalSeparator
        case add
        case subtract
        case multiply
        case delete
        case clear
    }

    private enum Operator: Character {
        case add = "+"
        case subtract = "−"
        case multiply = "×"
    }

    private static let maxIntegerDigits = 9
    private static let maxFractionDigits = 2

    /// Ekranda görünen ifade.
    private(set) var text: String

    init() {
        text = ""
    }

    /// Düzenleme ekranı için mevcut tutardan başlatır: 229.99 → "229,99".
    init(amount: Decimal) {
        let plain = NSDecimalNumber(decimal: amount).stringValue
        text = plain.replacingOccurrences(of: ".", with: ",")
    }

    var isEmpty: Bool { text.isEmpty }

    /// İfadede işlem varsa ekranda sonuç ayrıca gösterilir.
    var hasOperator: Bool {
        text.contains { Operator(rawValue: $0) != nil }
    }

    /// İfadenin sonucu, 2 haneye yuvarlanmış. Boşsa `nil`; sondaki işlem yok sayılır.
    var value: Decimal? {
        var numbers: [Decimal] = []
        var operators: [Operator] = []
        var current = ""
        for character in text {
            if let op = Operator(rawValue: character) {
                guard let number = Self.parse(current) else { return nil }
                numbers.append(number)
                operators.append(op)
                current = ""
            } else {
                current.append(character)
            }
        }
        if let last = Self.parse(current) {
            numbers.append(last)
        } else if !operators.isEmpty {
            operators.removeLast()
        }
        guard !numbers.isEmpty else { return nil }
        return Self.rounded(Self.evaluate(numbers: numbers, operators: operators))
    }

    mutating func input(_ key: Key) {
        switch key {
        case .digit(let digit):
            appendDigit(digit)
        case .decimalSeparator:
            appendSeparator()
        case .add:
            appendOperator(.add)
        case .subtract:
            appendOperator(.subtract)
        case .multiply:
            appendOperator(.multiply)
        case .delete:
            if !text.isEmpty { text.removeLast() }
        case .clear:
            text = ""
        }
    }

    // MARK: - Girdi kuralları

    /// Son işlemden sonraki sayı parçası.
    private var currentNumber: Substring {
        guard let index = text.lastIndex(where: { Operator(rawValue: $0) != nil }) else { return text[...] }
        return text[text.index(after: index)...]
    }

    private mutating func appendDigit(_ digit: Int) {
        guard (0...9).contains(digit) else { return }
        let number = currentNumber
        if let comma = number.firstIndex(of: ",") {
            guard number[number.index(after: comma)...].count < Self.maxFractionDigits else { return }
        } else {
            guard number.count < Self.maxIntegerDigits else { return }
            // "0" ardından rakam gelirse baştaki sıfır silinir: "07" değil "7".
            if number == "0" { text.removeLast() }
        }
        text.append(Character(String(digit)))
    }

    private mutating func appendSeparator() {
        let number = currentNumber
        guard !number.contains(",") else { return }
        if number.isEmpty { text.append("0") }
        text.append(",")
    }

    private mutating func appendOperator(_ op: Operator) {
        guard let last = text.last else { return }
        if Operator(rawValue: last) != nil {
            // Arka arkaya iki işlem olmaz; sonuncusu yenisiyle değişir.
            text.removeLast()
        } else if last == "," {
            text.removeLast()
        }
        text.append(op.rawValue)
    }

    // MARK: - Hesap

    private static func parse(_ number: String) -> Decimal? {
        guard !number.isEmpty else { return nil }
        let normalized = number.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func evaluate(numbers: [Decimal], operators: [Operator]) -> Decimal {
        // Önce çarpmalar, sonra toplama/çıkarma.
        var terms: [Decimal] = [numbers[0]]
        var signs: [Operator] = []
        for (op, number) in zip(operators, numbers.dropFirst()) {
            if op == .multiply, let last = terms.popLast() {
                terms.append(last * number)
            } else {
                terms.append(number)
                signs.append(op)
            }
        }
        var result = terms[0]
        for (op, term) in zip(signs, terms.dropFirst()) {
            result = op == .add ? result + term : result - term
        }
        return result
    }

    private static func rounded(_ value: Decimal) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, maxFractionDigits, .plain)
        return output
    }
}
