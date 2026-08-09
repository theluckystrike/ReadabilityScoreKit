/// The entry point of ReadabilityScoreKit.
///
/// ```swift
/// if let scores = Readability.score("The cat sat on the mat.") {
///     print(scores.fleschReadingEase)
///     print(scores.readingEaseBand.rawValue)
/// }
/// ```
public enum Readability {

    /// Scores a piece of English prose with all six formulas.
    ///
    /// - Parameter text: The text to score. Markdown, HTML tags and code are
    ///   not stripped; strip them first if the input contains them, otherwise
    ///   the markup is counted as words.
    /// - Returns: `nil` when the text contains no words.
    public static func score(_ text: String) -> ReadabilityScores? {
        ReadabilityScores(statistics: TextStatistics.measuring(text))
    }

    /// The raw counts for a piece of text, without evaluating any formula.
    ///
    /// Useful when you want word, sentence or syllable counts on their own, or
    /// when you want to feed adjusted counts into `ReadabilityScores` yourself.
    public static func statistics(for text: String) -> TextStatistics {
        TextStatistics.measuring(text)
    }
}
