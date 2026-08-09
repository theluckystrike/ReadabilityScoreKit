import XCTest
@testable import ReadabilityScoreKit

final class TextStatisticsTests: XCTestCase {

    func testCountsForASimpleSentence() {
        let stats = TextStatistics.measuring("The cat sat on the mat.")
        XCTAssertEqual(stats.wordCount, 6)
        XCTAssertEqual(stats.sentenceCount, 1)
        XCTAssertEqual(stats.characterCount, 17)
        XCTAssertEqual(stats.syllableCount, 6)
        XCTAssertEqual(stats.polysyllableCount, 0)
    }

    func testMultipleSentences() {
        let stats = TextStatistics.measuring("One two. Three four! Five six?")
        XCTAssertEqual(stats.sentenceCount, 3)
        XCTAssertEqual(stats.wordCount, 6)
    }

    /// An ellipsis or "!!!" is one sentence break, not three.
    func testConsecutiveTerminatorsCountOnce() {
        XCTAssertEqual(TextStatistics.measuring("Wait!!! Stop.").sentenceCount, 2)
        XCTAssertEqual(TextStatistics.measuring("Well... maybe.").sentenceCount, 2)
    }

    /// A fragment with no terminal punctuation is still scoreable.
    func testUnterminatedTextIsOneSentence() {
        XCTAssertEqual(TextStatistics.measuring("a headline with no full stop").sentenceCount, 1)
    }

    func testEmptyText() {
        let stats = TextStatistics.measuring("   \n  ")
        XCTAssertEqual(stats.wordCount, 0)
        XCTAssertEqual(stats.sentenceCount, 0)
        XCTAssertTrue(stats.isEmpty)
    }

    /// Standalone punctuation is not a word.
    func testPunctuationOnlyTokensAreNotWords() {
        XCTAssertEqual(TextStatistics.measuring("hello -- world").wordCount, 2)
    }

    func testDerivedAveragesMatchTheRawCounts() {
        let stats = TextStatistics(
            wordCount: 20,
            sentenceCount: 2,
            characterCount: 100,
            syllableCount: 30,
            polysyllableCount: 4
        )
        XCTAssertEqual(stats.averageWordsPerSentence, 10.0, accuracy: 1e-12)
        XCTAssertEqual(stats.averageSyllablesPerWord, 1.5, accuracy: 1e-12)
        XCTAssertEqual(stats.averageCharactersPerWord, 5.0, accuracy: 1e-12)
        XCTAssertEqual(stats.polysyllableRatio, 0.2, accuracy: 1e-12)
    }

    func testAveragesAreZeroRatherThanNaNForEmptyText() {
        let stats = TextStatistics.measuring("")
        XCTAssertEqual(stats.averageWordsPerSentence, 0)
        XCTAssertEqual(stats.averageSyllablesPerWord, 0)
        XCTAssertEqual(stats.averageCharactersPerWord, 0)
    }
}
