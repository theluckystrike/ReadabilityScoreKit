/// The raw counts every readability formula in this package is built from.
///
/// Computing the statistics once and reusing them keeps the six formulas
/// consistent with each other: two scores derived from the same
/// `TextStatistics` value always agree about how many words the text contains.
public struct TextStatistics: Equatable, Sendable {

    /// Number of words. A word is a whitespace-separated token containing at
    /// least one letter or digit.
    public let wordCount: Int

    /// Number of sentences, counted as runs of `.`, `!` or `?`. Text that ends
    /// without terminal punctuation still counts as one sentence.
    public let sentenceCount: Int

    /// Number of letters and digits, excluding whitespace and punctuation.
    /// This is the "characters" input used by Coleman-Liau and ARI.
    public let characterCount: Int

    /// Total estimated syllables across all words.
    public let syllableCount: Int

    /// Words with three or more estimated syllables. Gunning Fog calls these
    /// "complex words"; SMOG calls them "polysyllables".
    public let polysyllableCount: Int

    public init(
        wordCount: Int,
        sentenceCount: Int,
        characterCount: Int,
        syllableCount: Int,
        polysyllableCount: Int
    ) {
        assert(wordCount >= 0 && sentenceCount >= 0, "counts must be non-negative")
        assert(polysyllableCount <= wordCount, "polysyllables cannot exceed words")
        self.wordCount = wordCount
        self.sentenceCount = sentenceCount
        self.characterCount = characterCount
        self.syllableCount = syllableCount
        self.polysyllableCount = polysyllableCount
    }

    /// True when the text has no words to measure, in which case no formula
    /// can produce a meaningful score.
    public var isEmpty: Bool { wordCount == 0 || sentenceCount == 0 }

    /// Mean words per sentence.
    public var averageWordsPerSentence: Double {
        guard sentenceCount > 0 else { return 0 }
        return Double(wordCount) / Double(sentenceCount)
    }

    /// Mean syllables per word.
    public var averageSyllablesPerWord: Double {
        guard wordCount > 0 else { return 0 }
        return Double(syllableCount) / Double(wordCount)
    }

    /// Mean characters per word.
    public var averageCharactersPerWord: Double {
        guard wordCount > 0 else { return 0 }
        return Double(characterCount) / Double(wordCount)
    }

    /// Share of words with three or more syllables, in the range 0...1.
    public var polysyllableRatio: Double {
        guard wordCount > 0 else { return 0 }
        return Double(polysyllableCount) / Double(wordCount)
    }

    /// Derives the statistics for a piece of English prose.
    public static func measuring(_ text: String) -> TextStatistics {
        let words = Tokenizer.words(in: text)
        var syllables = 0
        var polysyllables = 0
        var characters = 0

        for word in words {
            let wordSyllables = SyllableCounter.count(in: word)
            syllables += wordSyllables
            if wordSyllables >= 3 { polysyllables += 1 }
            characters += word.reduce(0) { $0 + ($1.isLetter || $1.isNumber ? 1 : 0) }
        }

        return TextStatistics(
            wordCount: words.count,
            sentenceCount: Tokenizer.sentenceCount(in: text, wordCount: words.count),
            characterCount: characters,
            syllableCount: syllables,
            polysyllableCount: polysyllables
        )
    }
}

/// Splits prose into the tokens the statistics are counted from.
enum Tokenizer {

    private static let terminators: Set<Character> = [".", "!", "?"]

    /// Whitespace-separated tokens that contain at least one letter or digit.
    static func words(in text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .filter { token in token.contains(where: { $0.isLetter || $0.isNumber }) }
    }

    /// Counts sentences as runs of terminal punctuation.
    ///
    /// Consecutive terminators ("Wait!!!", "Really...") count once. Text that
    /// contains words but no terminator counts as a single sentence, so that a
    /// headline or a fragment still yields a score.
    static func sentenceCount(in text: String, wordCount: Int) -> Int {
        var sentences = 0
        var previousWasTerminator = false
        for character in text {
            let isTerminator = terminators.contains(character)
            if isTerminator && !previousWasTerminator { sentences += 1 }
            previousWasTerminator = isTerminator
        }
        if sentences == 0 { return wordCount > 0 ? 1 : 0 }
        return sentences
    }
}
