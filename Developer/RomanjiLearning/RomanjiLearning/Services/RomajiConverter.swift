import Foundation

/// Converts Japanese text (hiragana, katakana, and kanji) to romaji
enum RomajiConverter {

    // MARK: - Main Conversion Method

    /// Converts Japanese text to romaji
    /// - Parameter japanese: The Japanese text to convert (can contain hiragana, katakana, kanji, or mixed)
    /// - Returns: The romanized version of the text
    static func convert(_ japanese: String) -> String {
        // First, use CFStringTokenizer to get readings for kanji
        let withReadings = convertKanjiToReadings(japanese)

        // Then convert kana to romaji
        return convertKanaToRomaji(withReadings)
    }

    // MARK: - Kanji to Reading Conversion (using CFStringTokenizer)

    /// Uses Apple's CFStringTokenizer to convert kanji to their hiragana/romaji readings
    private static func convertKanjiToReadings(_ text: String) -> String {
        let mutableString = NSMutableString(string: text) as CFMutableString

        // Use CFStringTokenizer with Latin transcription for kanji
        let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            mutableString,
            CFRangeMake(0, CFStringGetLength(mutableString)),
            kCFStringTokenizerUnitWord,
            Locale(identifier: "ja") as CFLocale
        )

        var result = ""
        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        var lastEndIndex = text.startIndex

        while tokenType != [] {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let startIndex = text.index(text.startIndex, offsetBy: range.location)
            let endIndex = text.index(startIndex, offsetBy: range.length)

            // Add any text between the last token and this one (spaces, punctuation)
            if lastEndIndex < startIndex {
                result += String(text[lastEndIndex..<startIndex])
            }

            let token = String(text[startIndex..<endIndex])

            // Check if the token contains kanji
            if containsKanji(token) {
                // Get the Latin transcription (romaji) from tokenizer
                if let latinTranscription = CFStringTokenizerCopyCurrentTokenAttribute(
                    tokenizer,
                    kCFStringTokenizerAttributeLatinTranscription
                ) as? String {
                    result += latinTranscription
                } else {
                    // Fallback: keep original if no transcription available
                    result += token
                }
            } else {
                // No kanji, keep as is (will be converted in kana step)
                result += token
            }

            lastEndIndex = endIndex
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }

        // Add any remaining text after the last token
        if lastEndIndex < text.endIndex {
            result += String(text[lastEndIndex..<text.endIndex])
        }

        return result.isEmpty ? text : result
    }

    /// Checks if a string contains any kanji characters
    private static func containsKanji(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // CJK Unified Ideographs range
            if (0x4E00...0x9FFF).contains(scalar.value) ||
               (0x3400...0x4DBF).contains(scalar.value) || // CJK Extension A
               (0x20000...0x2A6DF).contains(scalar.value) { // CJK Extension B
                return true
            }
        }
        return false
    }

    // MARK: - Kana to Romaji Conversion

    /// Converts hiragana and katakana to romaji
    private static func convertKanaToRomaji(_ text: String) -> String {
        var result = ""
        var index = text.startIndex

        while index < text.endIndex {
            // Try to match combo characters first (2 characters)
            if let nextIndex = text.index(index, offsetBy: 2, limitedBy: text.endIndex) {
                let twoChars = String(text[index..<nextIndex])
                if let romaji = comboKanaToRomaji[twoChars] {
                    result += romaji
                    index = nextIndex
                    continue
                }
            }

            let char = text[index]
            let charStr = String(char)

            // Handle small tsu (っ/ッ) - doubles the next consonant
            if charStr == "っ" || charStr == "ッ" {
                let nextIdx = text.index(after: index)
                if nextIdx < text.endIndex {
                    let nextChar = String(text[nextIdx])
                    // Look up what the next character converts to
                    if let nextRomaji = singleKanaToRomaji[nextChar] ?? comboLookupFirst(text, from: nextIdx),
                       let firstConsonant = nextRomaji.first,
                       firstConsonant.isLetter && firstConsonant != "a" && firstConsonant != "i" &&
                       firstConsonant != "u" && firstConsonant != "e" && firstConsonant != "o" {
                        result += String(firstConsonant)
                    } else {
                        result += "t" // Default for small tsu before vowels or unknown
                    }
                } else {
                    result += "t" // Small tsu at end
                }
                index = text.index(after: index)
                continue
            }

            // Handle long vowel mark (ー)
            if charStr == "ー" {
                // Repeat the previous vowel
                if let lastChar = result.last {
                    let vowel: Character
                    switch lastChar {
                    case "a", "i", "u", "e", "o":
                        vowel = lastChar
                    default:
                        vowel = "u" // Default for katakana long vowel
                    }
                    result += String(vowel)
                }
                index = text.index(after: index)
                continue
            }

            // Handle single kana
            if let romaji = singleKanaToRomaji[charStr] {
                result += romaji
            } else {
                // Keep non-kana characters as-is (punctuation, spaces, already romanized)
                result += charStr
            }

            index = text.index(after: index)
        }

        return result
    }

    /// Helper to look up combo characters starting at an index
    private static func comboLookupFirst(_ text: String, from index: String.Index) -> String? {
        if let nextIndex = text.index(index, offsetBy: 2, limitedBy: text.endIndex) {
            let twoChars = String(text[index..<nextIndex])
            return comboKanaToRomaji[twoChars]
        }
        let char = String(text[index])
        return singleKanaToRomaji[char]
    }

    // MARK: - Kana Mapping Tables

    /// Single hiragana/katakana to romaji mapping
    private static let singleKanaToRomaji: [String: String] = [
        // Hiragana - Basic vowels
        "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
        // Hiragana - K row
        "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
        // Hiragana - S row
        "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
        // Hiragana - T row
        "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
        // Hiragana - N row
        "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
        // Hiragana - H row
        "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
        // Hiragana - M row
        "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
        // Hiragana - Y row
        "や": "ya", "ゆ": "yu", "よ": "yo",
        // Hiragana - R row
        "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
        // Hiragana - W row
        "わ": "wa", "を": "wo",
        // Hiragana - N
        "ん": "n",

        // Hiragana - Dakuten (voiced)
        "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
        "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
        "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
        "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",

        // Hiragana - Handakuten (p-sounds)
        "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",

        // Katakana - Basic vowels
        "ア": "a", "イ": "i", "ウ": "u", "エ": "e", "オ": "o",
        // Katakana - K row
        "カ": "ka", "キ": "ki", "ク": "ku", "ケ": "ke", "コ": "ko",
        // Katakana - S row
        "サ": "sa", "シ": "shi", "ス": "su", "セ": "se", "ソ": "so",
        // Katakana - T row
        "タ": "ta", "チ": "chi", "ツ": "tsu", "テ": "te", "ト": "to",
        // Katakana - N row
        "ナ": "na", "ニ": "ni", "ヌ": "nu", "ネ": "ne", "ノ": "no",
        // Katakana - H row
        "ハ": "ha", "ヒ": "hi", "フ": "fu", "ヘ": "he", "ホ": "ho",
        // Katakana - M row
        "マ": "ma", "ミ": "mi", "ム": "mu", "メ": "me", "モ": "mo",
        // Katakana - Y row
        "ヤ": "ya", "ユ": "yu", "ヨ": "yo",
        // Katakana - R row
        "ラ": "ra", "リ": "ri", "ル": "ru", "レ": "re", "ロ": "ro",
        // Katakana - W row
        "ワ": "wa", "ヲ": "wo",
        // Katakana - N
        "ン": "n",

        // Katakana - Dakuten (voiced)
        "ガ": "ga", "ギ": "gi", "グ": "gu", "ゲ": "ge", "ゴ": "go",
        "ザ": "za", "ジ": "ji", "ズ": "zu", "ゼ": "ze", "ゾ": "zo",
        "ダ": "da", "ヂ": "ji", "ヅ": "zu", "デ": "de", "ド": "do",
        "バ": "ba", "ビ": "bi", "ブ": "bu", "ベ": "be", "ボ": "bo",

        // Katakana - Handakuten (p-sounds)
        "パ": "pa", "ピ": "pi", "プ": "pu", "ペ": "pe", "ポ": "po",

        // Small kana (standalone, not as combo modifiers)
        "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
        "ァ": "a", "ィ": "i", "ゥ": "u", "ェ": "e", "ォ": "o",
        "ゃ": "ya", "ゅ": "yu", "ょ": "yo",
        "ャ": "ya", "ュ": "yu", "ョ": "yo",
    ]

    /// Combo kana (two-character sequences) to romaji mapping
    private static let comboKanaToRomaji: [String: String] = [
        // Hiragana combos - き row
        "きゃ": "kya", "きゅ": "kyu", "きょ": "kyo",
        // Hiragana combos - し row
        "しゃ": "sha", "しゅ": "shu", "しょ": "sho",
        // Hiragana combos - ち row
        "ちゃ": "cha", "ちゅ": "chu", "ちょ": "cho",
        // Hiragana combos - に row
        "にゃ": "nya", "にゅ": "nyu", "にょ": "nyo",
        // Hiragana combos - ひ row
        "ひゃ": "hya", "ひゅ": "hyu", "ひょ": "hyo",
        // Hiragana combos - み row
        "みゃ": "mya", "みゅ": "myu", "みょ": "myo",
        // Hiragana combos - り row
        "りゃ": "rya", "りゅ": "ryu", "りょ": "ryo",

        // Hiragana combos - voiced (dakuten)
        "ぎゃ": "gya", "ぎゅ": "gyu", "ぎょ": "gyo",
        "じゃ": "ja", "じゅ": "ju", "じょ": "jo",
        "ぢゃ": "ja", "ぢゅ": "ju", "ぢょ": "jo",
        "びゃ": "bya", "びゅ": "byu", "びょ": "byo",

        // Hiragana combos - handakuten
        "ぴゃ": "pya", "ぴゅ": "pyu", "ぴょ": "pyo",

        // Katakana combos - キ row
        "キャ": "kya", "キュ": "kyu", "キョ": "kyo",
        // Katakana combos - シ row
        "シャ": "sha", "シュ": "shu", "ショ": "sho",
        // Katakana combos - チ row
        "チャ": "cha", "チュ": "chu", "チョ": "cho",
        // Katakana combos - ニ row
        "ニャ": "nya", "ニュ": "nyu", "ニョ": "nyo",
        // Katakana combos - ヒ row
        "ヒャ": "hya", "ヒュ": "hyu", "ヒョ": "hyo",
        // Katakana combos - ミ row
        "ミャ": "mya", "ミュ": "myu", "ミョ": "myo",
        // Katakana combos - リ row
        "リャ": "rya", "リュ": "ryu", "リョ": "ryo",

        // Katakana combos - voiced (dakuten)
        "ギャ": "gya", "ギュ": "gyu", "ギョ": "gyo",
        "ジャ": "ja", "ジュ": "ju", "ジョ": "jo",
        "ヂャ": "ja", "ヂュ": "ju", "ヂョ": "jo",
        "ビャ": "bya", "ビュ": "byu", "ビョ": "byo",

        // Katakana combos - handakuten
        "ピャ": "pya", "ピュ": "pyu", "ピョ": "pyo",

        // Extended Katakana for foreign sounds
        "ファ": "fa", "フィ": "fi", "フェ": "fe", "フォ": "fo",
        "ティ": "ti", "ディ": "di",
        "トゥ": "tu", "ドゥ": "du",
        "ウィ": "wi", "ウェ": "we", "ウォ": "wo",
        "ヴァ": "va", "ヴィ": "vi", "ヴ": "vu", "ヴェ": "ve", "ヴォ": "vo",
        "シェ": "she", "ジェ": "je", "チェ": "che",
        "ツァ": "tsa", "ツィ": "tsi", "ツェ": "tse", "ツォ": "tso",

        // Long vowel patterns (hiragana)
        "おう": "ou", "おお": "oo",
        "えい": "ei", "ええ": "ee",
        "ああ": "aa", "いい": "ii", "うう": "uu",
    ]
}
