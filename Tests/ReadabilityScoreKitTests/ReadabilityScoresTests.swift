import XCTest
@testable import ReadabilityScoreKit

final class ReadabilityScoresTests: XCTestCase {

    /// Fixed counts, so each formula can be checked against the published
    /// constants worked out by hand rather than against the tokenizer.
    private let fixture = TextStatistics(
        wordCount: 100,
        sentenceCount: 5,
        characterCount: 500,
        syllableCount: 150,
        polysyllableCount: 10
    )

    func testFleschReadingEaseMatchesThePublishedFormula() {
        let scores = try! XCTUnwrap(ReadabilityScores(statistics: fixture))
        // 206.835 - 1.015 * 20 - 84.6 * 1.5
        XCTAssertEqual(scores.fleschReadingEase, 206.835 - 20.30 - 126.90, accuracy: 1e-9)
    }

    func testFleschKincaidGradeMatchesThePublishedFormula() {
        let scores = try! XCTUnwrap(ReadabilityScores(statistics: fixture))
        // 0.39 * 20 + 11.8 * 1.5 - 15.59
        XCTAssertEqual(scores.fleschKincaidGrade, 7.80 + 17.70 - 15.59, accuracy: 1e-9)
    }

    func testGunningFogMatchesThePublishedFormula() {
        let scores = try! XCTUnwrap(ReadabilityScores(statistics: fixture))
        // 0.4 * (20 + 100 * 0.10)
        XCTAssertEqual(scores.gunningFog, 0.4 * 30.0, accuracy: 1e-9)
    }

    func testSMOGMatchesThePublishedFormula() {
        let scores = try! XCTUnwrap(ReadabilityScores(statistics: fixture))
        // 1.0430 * sqrt(10 * (30 / 5)) + 3.1291
        XCTAssertEqual(scores.smogIndex, 1.0430 * 60.0.squareRoot() + 3.1291, accuracy: 1e-9)
    }

    func testColemanLiauMatchesThePublishedFormula() {
        let scores = try! XCTUnwrap(ReadabilityScores(statistics: fixture))
        // 0.0588 * 500 - 0.296 * 5 - 15.8
        XCTAssertEqual(scores.colemanLiauIndex, 0.0588 * 500.0 - 0.296 * 5.0 - 15.8, accuracy: 1e-9)
    }

    func testARIMatchesThePublishedFormula() {
        let scores = try! XCTUnwrap(ReadabilityScores(statistics: fixture))
        // 4.71 * 5 + 0.5 * 20 - 21.43
        XCTAssertEqual(scores.automatedReadabilityIndex, 4.71 * 5.0 + 10.0 - 21.43, accuracy: 1e-9)
    }

    func testAverageGradeLevelIsTheMeanOfTheFiveGradeFormulas() {
        let scores = try! XCTUnwrap(ReadabilityScores(statistics: fixture))
        let expected = (scores.fleschKincaidGrade + scores.gunningFog + scores.smogIndex
            + scores.colemanLiauIndex + scores.automatedReadabilityIndex) / 5.0
        XCTAssertEqual(scores.averageGradeLevel, expected, accuracy: 1e-9)
    }

    /// Unmeasurable text must be distinguishable from text that scored zero.
    func testEmptyTextProducesNoScores() {
        XCTAssertNil(Readability.score(""))
        XCTAssertNil(Readability.score("   \t\n "))
        XCTAssertNil(Readability.score("!!!"))
    }

    /// The direction of the scales: plain prose must read as easier than dense
    /// prose on Reading Ease, and as a lower grade on Flesch-Kincaid.
    func testSimpleTextScoresEasierThanComplexText() {
        let simple = "The cat sat on the mat. The dog ran. We had fun."
        let complex = """
        The epistemological ramifications of institutionalised methodological \
        individualism necessitate a comprehensive reconsideration of the \
        prevailing interpretative frameworks.
        """
        let simpleScores = try! XCTUnwrap(Readability.score(simple))
        let complexScores = try! XCTUnwrap(Readability.score(complex))

        XCTAssertGreaterThan(simpleScores.fleschReadingEase, complexScores.fleschReadingEase)
        XCTAssertLessThan(simpleScores.fleschKincaidGrade, complexScores.fleschKincaidGrade)
        XCTAssertLessThan(simpleScores.gunningFog, complexScores.gunningFog)
    }

    func testReadingEaseBands() throws {
        let bands: [(Double, ReadabilityScores.ReadingEaseBand)] = [
            (95, .veryEasy), (85, .easy), (75, .fairlyEasy), (65, .standard),
            (55, .fairlyDifficult), (40, .difficult), (10, .veryDifficult), (-5, .veryDifficult)
        ]
        for (ease, expected) in bands {
            let scores = try XCTUnwrap(Self.scores(targetingReadingEase: ease))
            XCTAssertEqual(scores.fleschReadingEase, ease, accuracy: 0.05, "ease: \(ease)")
            XCTAssertEqual(scores.readingEaseBand, expected, "ease: \(ease)")
        }
    }

    /// Builds a score set with a chosen Reading Ease by solving the published
    /// formula for the syllables-per-word term, so the band test exercises the
    /// real initialiser rather than a mock.
    private static func scores(targetingReadingEase target: Double) -> ReadabilityScores? {
        let words = 10_000
        let wordsPerSentence = 1.0
        let syllablesPerWord = (206.835 - 1.015 * wordsPerSentence - target) / 84.6
        let syllables = Int((syllablesPerWord * Double(words)).rounded())
        let stats = TextStatistics(
            wordCount: words,
            sentenceCount: words,
            characterCount: words * 4,
            syllableCount: max(0, syllables),
            polysyllableCount: 0
        )
        return ReadabilityScores(statistics: stats)
    }
}
