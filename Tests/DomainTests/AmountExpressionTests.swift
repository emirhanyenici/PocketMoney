import Foundation
import Testing
@testable import PocketMoney

struct AmountExpressionTests {
    private func type(_ keys: [AmountExpression.Key]) -> AmountExpression {
        var expression = AmountExpression()
        keys.forEach { expression.input($0) }
        return expression
    }

    @Test func typesDecimalAmountWithComma() {
        let expression = type([.digit(2), .digit(2), .digit(9), .decimalSeparator, .digit(9), .digit(9)])
        #expect(expression.text == "229,99")
        #expect(expression.value == Decimal(string: "229.99"))
        #expect(!expression.hasOperator)
    }

    @Test func limitsFractionToTwoDigits() {
        let expression = type([.digit(1), .decimalSeparator, .digit(2), .digit(3), .digit(4)])
        #expect(expression.text == "1,23")
    }

    @Test func leadingSeparatorAddsZeroAndLeadingZeroIsReplaced() {
        #expect(type([.decimalSeparator, .digit(5)]).text == "0,5")
        #expect(type([.digit(0), .digit(7)]).text == "7")
    }

    @Test func multiplicationBeforeAddition() {
        let expression = type([.digit(1), .digit(0), .add, .digit(2), .multiply, .digit(3)])
        #expect(expression.text == "10+2×3")
        #expect(expression.value == 16)
        #expect(expression.hasOperator)
    }

    @Test func subtraction() {
        #expect(type([.digit(5), .digit(0), .subtract, .digit(1), .digit(2), .decimalSeparator, .digit(5)]).value == Decimal(string: "37.5"))
    }

    @Test func operatorRules() {
        #expect(type([.add]).text == "")
        #expect(type([.digit(5), .add, .multiply]).text == "5×")
        #expect(type([.digit(5), .add]).value == 5)
    }

    @Test func roundsProductToCents() {
        let expression = type([.digit(1), .decimalSeparator, .digit(5), .multiply, .digit(3), .decimalSeparator, .digit(3), .digit(3)])
        #expect(expression.value == Decimal(string: "5"))
    }

    @Test func deleteAndClear() {
        var expression = type([.digit(1), .digit(2)])
        expression.input(.delete)
        #expect(expression.text == "1")
        expression.input(.clear)
        #expect(expression.isEmpty)
        #expect(expression.value == nil)
    }

    @Test func startsFromExistingAmount() {
        #expect(AmountExpression(amount: Decimal(string: "229.99") ?? 0).text == "229,99")
        #expect(AmountExpression(amount: 250).text == "250")
    }
}
