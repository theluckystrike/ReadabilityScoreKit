# ReadabilityScoreKit

Six classic English readability formulas in Swift, with no dependencies and no data files.

```swift
import ReadabilityScoreKit

if let scores = Readability.score("The cat sat on the mat. The dog ran.") {
    print(scores.fleschReadingEase)   // 117.66750000000002
    print(scores.readingEaseBand)     // veryEasy
    print(scores.averageGradeLevel)   // -1.6140688888888892
}
```

## What it computes

| Score | Published as | Formula |
| --- | --- | --- |
| `fleschReadingEase` | Flesch, 1948 | `206.835 - 1.015 x (words / sentences) - 84.6 x (syllables / words)` |
| `fleschKincaidGrade` | Kincaid et al., 1975 | `0.39 x (words / sentences) + 11.8 x (syllables / words) - 15.59` |
| `gunningFog` | Gunning, 1952 | `0.4 x [(words / sentences) + 100 x (complex words / words)]` |
| `smogIndex` | McLaughlin, 1969 | `1.0430 x sqrt(polysyllables x (30 / sentences)) + 3.1291` |
| `colemanLiauIndex` | Coleman and Liau, 1975 | `0.0588 x L - 0.296 x S - 15.8` |
| `automatedReadabilityIndex` | Smith and Senter, 1967 | `4.71 x (characters / words) + 0.5 x (words / sentences) - 21.43` |

Five of the six are expressed as a U.S. school grade. Flesch Reading Ease is a 0-100-ish
scale where higher means easier; it is unbounded, so very short simple sentences can score
above 100 and very dense ones below zero.

`averageGradeLevel` is the mean of the five grade formulas, which is steadier than any one
of them on short text.

## Installation

```swift
.package(url: "https://github.com/theluckystrike/ReadabilityScoreKit.git", from: "1.0.0")
```

```swift
.target(name: "YourTarget", dependencies: ["ReadabilityScoreKit"])
```

## Counts, and where they come from

Every formula reads from one `TextStatistics` value, so two scores for the same text always
agree about how many words it contains. You can inspect or supply the counts yourself:

```swift
let stats = Readability.statistics(for: text)
stats.wordCount
stats.sentenceCount
stats.syllableCount
stats.polysyllableCount        // three or more syllables
let scores = ReadabilityScores(statistics: stats)
```

- **Words** are whitespace-separated tokens containing at least one letter or digit, so a
  bare `--` is not counted.
- **Sentences** are runs of `.`, `!` or `?`. `Wait!!!` is one break, not three. Text with no
  terminal punctuation is treated as a single sentence so headlines still score.
- **Characters** are letters and digits only, excluding whitespace and punctuation.
- **Syllables** come from a vowel-group heuristic (see below).

`Readability.score` returns `nil` for text with no words, rather than zero, so
"unmeasurable" stays distinguishable from "scored zero".

## Accuracy: read this before trusting a number

The syllable count is a **heuristic, not a dictionary lookup**. It counts maximal vowel runs,
drops a silent trailing `e`, and adds one back for a consonant + `le` ending, with plurals
normalised so `circles` scores the same as `circle`. That gets ordinary English words right
most of the time, and gets some of them wrong: names, loanwords, and words where a vowel pair
spans a syllable boundary such as `cre-ate`. Flesch, Flesch-Kincaid, Gunning Fog and SMOG all
inherit that error. Coleman-Liau and ARI are character-based and do not.

Gunning's original definition of a "complex word" also excluded proper nouns, familiar jargon,
compounds, and words made polysyllabic only by an `-es` or `-ed` suffix. This implementation
applies none of those exclusions, so `gunningFog` reads a little high on text full of names.

Markdown, HTML tags and code are not stripped. Strip them before scoring or they are counted
as words.

Treat every score as a band, not a measurement.

## Platforms

Pure Swift with no dependencies and no Foundation requirement in the scoring path. Builds
anywhere a Swift 5.9 toolchain runs.

## Tests

```
swift test
```

The formula tests use fixed counts so each constant is checked against the published formula
by hand, rather than against this package's own tokenizer. The tokenizer and syllable counter
are tested separately.

## See also

The same six formulas, implemented as hosted web tools:

- [BeLikeNative Readability Scorer](https://belikenative.com/tools/readability-scorer/) - the
  hosted web implementation of these formulas, and the URL set as this repository's homepage.
- [Readability Score Checker on Zovo](https://zovo.one/free-tools/readability-checker) - a
  second implementation, with a written explanation of what each formula measures and where
  it came from.

Useful for sanity-checking this library's output against an independent implementation.

## Licence

MIT. See [LICENSE](LICENSE).
