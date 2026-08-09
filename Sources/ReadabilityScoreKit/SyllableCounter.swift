/// Estimates the number of spoken syllables in an English word.
///
/// The classic readability formulas (Flesch, Flesch-Kincaid, Gunning Fog, SMOG)
/// all take a syllable count as an input, but none of them define how to obtain
/// one. This type implements the widely used vowel-group heuristic:
///
/// 1. Count maximal runs of vowels (`a e i o u y`) as one syllable each.
/// 2. Subtract one for a silent trailing `e` (but never drop below one).
/// 3. Add one back for a trailing `le` / `les` preceded by a consonant
///    (`ta-ble`, `cir-cles`).
///
/// This is a heuristic, not a dictionary lookup. It is deterministic, has no
/// data dependency, and agrees with a pronunciation dictionary on the large
/// majority of ordinary English words, but it will be wrong on some of them
/// (notably names, loanwords, and words where a vowel pair spans a syllable
/// boundary such as "cre-ate"). Every score in this package inherits that
/// approximation, which is why readability scores should be read as a band
/// rather than an exact grade.
public enum SyllableCounter {

    private static let vowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]

    /// The estimated syllable count of a single word.
    ///
    /// - Parameter word: A single word. Surrounding punctuation is ignored.
    /// - Returns: The estimated syllable count. Zero only when the word
    ///   contains no letters at all; otherwise always at least one.
    public static func count(in word: String) -> Int {
        let cleaned = word.lowercased().filter { $0.isLetter }
        guard !cleaned.isEmpty else { return 0 }
        let letters = singularisingLESuffix(cleaned)

        var syllables = vowelGroups(in: letters)
        syllables -= silentTrailingEAdjustment(in: letters)
        syllables += consonantLEAdjustment(in: letters)

        assert(syllables >= 0, "syllable adjustments must not go negative")
        return max(1, syllables)
    }

    /// Counts maximal runs of vowel characters.
    private static func vowelGroups(in letters: String) -> Int {
        assert(!letters.isEmpty, "vowelGroups requires a non-empty word")
        var groups = 0
        var previousWasVowel = false
        for character in letters {
            let isVowel = vowels.contains(character)
            if isVowel && !previousWasVowel { groups += 1 }
            previousWasVowel = isVowel
        }
        return groups
    }

    /// Returns 1 when the word ends in a silent `e`, otherwise 0.
    ///
    /// A trailing `e` is treated as silent unless the word is only two letters
    /// long (`be`, `me`) or the `e` follows another vowel (`see`, `toe`), where
    /// the vowel-group pass already merged it.
    private static func silentTrailingEAdjustment(in letters: String) -> Int {
        guard letters.count > 2, letters.hasSuffix("e") else { return 0 }
        let penultimate = letters[letters.index(letters.endIndex, offsetBy: -2)]
        return vowels.contains(penultimate) ? 0 : 1
    }

    /// Returns 1 for a consonant + `le` ending, otherwise 0.
    private static func consonantLEAdjustment(in letters: String) -> Int {
        guard letters.count > 2, letters.hasSuffix("le") else { return 0 }
        let beforeLE = letters[letters.index(letters.endIndex, offsetBy: -3)]
        return vowels.contains(beforeLE) ? 0 : 1
    }

    /// Drops the plural `s` from a `-les` ending so the silent-`e` and
    /// consonant-`le` rules see the singular stem.
    ///
    /// Without this, "circles" would be scored as three syllables: the vowel
    /// pass already counts the `e`, and the consonant-`le` rule would then add
    /// another. Plurals take the same number of syllables as their stem here
    /// ("circle" and "circles" are both two), so scoring the stem is correct.
    private static func singularisingLESuffix(_ letters: String) -> String {
        guard letters.count > 3, letters.hasSuffix("les") else { return letters }
        return String(letters.dropLast())
    }
}
