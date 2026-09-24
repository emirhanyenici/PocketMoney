import Testing
@testable import PocketMoney

struct SearchKeyTests {
    @Test(arguments: [
        ("ŞOK", "sok"),
        ("BİM", "bim"),
        ("İstanbulkart", "istanbulkart"),
        ("IKEA", "ikea"),
        ("Koçtaş", "koctas"),
        ("Çiçeksepeti", "ciceksepeti"),
        ("Martı", "marti"),
        ("Türk Hava Yolları", "turk hava yollari"),
        ("Caffè Nero", "caffe nero"),
        ("  Kahve   Dünyası ", "kahve dunyasi")
    ])
    func normalizes(input: String, expected: String) {
        #expect(SearchKey.make(from: input) == expected)
    }

    /// Bölüm 8: kullanıcı "sok" yazınca ŞOK bulunmalı.
    @Test func plainQueryMatchesTurkishName() {
        #expect(SearchKey.make(from: "sok") == SearchKey.make(from: "ŞOK"))
        #expect(SearchKey.make(from: "koctas") == SearchKey.make(from: "KOÇTAŞ"))
    }
}
