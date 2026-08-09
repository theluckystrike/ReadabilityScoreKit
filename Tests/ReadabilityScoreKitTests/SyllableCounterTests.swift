import XCTest
@testable import ReadabilityScoreKit

final class SyllableCounterTests: XCTestCase {

    /// Words whose syllable count the vowel-group heuristic gets right.
    func testKnownSyllableCounts() {
        let cases: [(String, Int)] = [
            ("cat", 1), ("the", 1), ("mat", 1), ("sat", 1),
            ("hello", 2), ("water", 2), ("simple", 2), ("table", 2),
            ("circles", 2), ("running", 2), ("before", 2),
            ("beautiful", 3), ("computer", 3), ("readable", 3),
            ("readability", 5), ("information", 4)
        ]
        for (word, expected) in cases {
            XCTAssertEqual(SyllableCounter.count(in: word), expected, "word: \(word)")
        }
    }

    /// The count must never be zero for a word that contains letters, because
    /// every formula divides by the word count and a zero would silently skew
    /// the average.
    func testEveryLetteredWordHasAtLeastOneSyllable() {
        for word in ["a", "I", "rhythm", "sky", "strengths", "e"] {
            XCTAssertGreaterThanOrEqual(SyllableCounter.count(in: word), 1, "word: \(word)")
        }
    }

    /// Tokens with no letters contribute nothing.
    func testNonWordsCountZero() {
        for token in ["", "---", "123", "!?"] {
            XCTAssertEqual(SyllableCounter.count(in: token), 0, "token: \(token)")
        }
    }

    /// Surrounding punctuation and capitalisation must not change the count.
    func testPunctuationAndCaseAreIgnored() {
        XCTAssertEqual(SyllableCounter.count(in: "\"Hello,\""), SyllableCounter.count(in: "hello"))
        XCTAssertEqual(SyllableCounter.count(in: "COMPUTER."), SyllableCounter.count(in: "computer"))
    }

    /// A trailing silent `e` is dropped, but a pronounced final vowel is not.
    func testSilentTrailingE() {
        XCTAssertEqual(SyllableCounter.count(in: "make"), 1)
        XCTAssertEqual(SyllableCounter.count(in: "be"), 1)
        XCTAssertEqual(SyllableCounter.count(in: "see"), 1)
    }

    /// A plural takes the same syllable count as its stem. Without the `-les`
    /// normalisation "circles" scores three: the vowel pass counts the `e` and
    /// the consonant-`le` rule then adds another.
    func testPluralsMatchTheirStem() {
        let plurals = ["circle", "apple", "puzzle", "table", "mile", "sale", "rule", "hole", "style"]
        for stem in plurals {
            XCTAssertEqual(
                SyllableCounter.count(in: stem + "s"),
                SyllableCounter.count(in: stem),
                "stem: \(stem)"
            )
        }
        XCTAssertEqual(SyllableCounter.count(in: "circles"), 2)
        XCTAssertEqual(SyllableCounter.count(in: "miles"), 1)
    }
}
