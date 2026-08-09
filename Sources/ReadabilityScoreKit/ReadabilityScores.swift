#if canImport(Foundation)
import Foundation
#endif

/// The six classic readability formulas, evaluated from a `TextStatistics`.
///
/// Each formula is implemented exactly as originally published; the constants
/// are quoted in the doc comment for the property so they can be checked
/// against the source without reading the code.
public struct ReadabilityScores: Equatable, Sendable {

    /// The counts these scores were derived from.
    public let statistics: TextStatistics

    /// Flesch Reading Ease (Flesch, 1948).
    ///
    /// `206.835 - 1.015 x (words / sentences) - 84.6 x (syllables / words)`
    ///
    /// Higher is easier. The formula is unbounded in both directions, though
    /// ordinary prose lands between 0 and 100.
    public let fleschReadingEase: Double

    /// Flesch-Kincaid Grade Level (Kincaid et al., 1975).
    ///
    /// `0.39 x (words / sentences) + 11.8 x (syllables / words) - 15.59`
    ///
    /// Reported as a U.S. school grade.
    public let fleschKincaidGrade: Double

    /// Gunning Fog Index (Gunning, 1952).
    ///
    /// `0.4 x [(words / sentences) + 100 x (complex words / words)]`
    ///
    /// "Complex words" here means three or more estimated syllables. Gunning's
    /// original definition also excluded proper nouns, familiar jargon and
    /// compounds, and words made polysyllabic by `-es` / `-ed` suffixes. This
    /// implementation applies no such exclusions, so it reads slightly higher
    /// than a hand count on text rich in names.
    public let gunningFog: Double

    /// SMOG Index (McLaughlin, 1969).
    ///
    /// `1.0430 x sqrt(polysyllables x (30 / sentences)) + 3.1291`
    ///
    /// McLaughlin calibrated SMOG on samples of thirty sentences; on shorter
    /// text the normalisation term makes the result noisier.
    public let smogIndex: Double

    /// Coleman-Liau Index (Coleman and Liau, 1975).
    ///
    /// `0.0588 x L - 0.296 x S - 15.8`, where `L` is letters per 100 words and
    /// `S` is sentences per 100 words.
    ///
    /// Uses characters rather than syllables, so it does not inherit the
    /// syllable heuristic's error.
    public let colemanLiauIndex: Double

    /// Automated Readability Index (Smith and Senter, 1967).
    ///
    /// `4.71 x (characters / words) + 0.5 x (words / sentences) - 21.43`
    ///
    /// Like Coleman-Liau, character-based rather than syllable-based.
    public let automatedReadabilityIndex: Double

    /// Evaluates all six formulas.
    ///
    /// - Parameter statistics: Counts for the text being scored.
    /// - Returns: `nil` when the text contains no words or no sentences, since
    ///   every formula divides by one of those counts. Returning `nil` rather
    ///   than zero keeps "unmeasurable" distinct from "scored zero".
    public init?(statistics: TextStatistics) {
        guard !statistics.isEmpty else { return nil }
        assert(statistics.wordCount > 0, "guard above must exclude empty text")

        let wordsPerSentence = statistics.averageWordsPerSentence
        let syllablesPerWord = statistics.averageSyllablesPerWord
        let charactersPerWord = statistics.averageCharactersPerWord
        let sentences = Double(statistics.sentenceCount)

        self.statistics = statistics
        self.fleschReadingEase = 206.835 - 1.015 * wordsPerSentence - 84.6 * syllablesPerWord
        self.fleschKincaidGrade = 0.39 * wordsPerSentence + 11.8 * syllablesPerWord - 15.59
        self.gunningFog = 0.4 * (wordsPerSentence + 100.0 * statistics.polysyllableRatio)
        self.smogIndex = 1.0430 * (Double(statistics.polysyllableCount) * (30.0 / sentences)).squareRoot() + 3.1291
        self.colemanLiauIndex = 0.0588 * (charactersPerWord * 100.0)
            - 0.296 * (sentences / Double(statistics.wordCount) * 100.0)
            - 15.8
        self.automatedReadabilityIndex = 4.71 * charactersPerWord + 0.5 * wordsPerSentence - 21.43
    }
}

extension ReadabilityScores {

    /// The interpretation bands Flesch published for Reading Ease.
    public enum ReadingEaseBand: String, CaseIterable, Sendable {
        case veryEasy = "Very easy"
        case easy = "Easy"
        case fairlyEasy = "Fairly easy"
        case standard = "Standard"
        case fairlyDifficult = "Fairly difficult"
        case difficult = "Difficult"
        case veryDifficult = "Very difficult"
    }

    /// The band this text's Reading Ease score falls into.
    public var readingEaseBand: ReadingEaseBand {
        switch fleschReadingEase {
        case 90...: return .veryEasy
        case 80..<90: return .easy
        case 70..<80: return .fairlyEasy
        case 60..<70: return .standard
        case 50..<60: return .fairlyDifficult
        case 30..<50: return .difficult
        default: return .veryDifficult
        }
    }

    /// The mean of the five grade-level formulas, which is a steadier estimate
    /// than any single one of them.
    ///
    /// Reading Ease is excluded because it is not expressed as a grade.
    public var averageGradeLevel: Double {
        let grades = [fleschKincaidGrade, gunningFog, smogIndex, colemanLiauIndex, automatedReadabilityIndex]
        assert(!grades.isEmpty, "grade list must not be empty")
        return grades.reduce(0, +) / Double(grades.count)
    }
}
