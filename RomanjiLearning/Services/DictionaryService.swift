import Foundation

struct WordEntry: Codable, Identifiable {
    var id: String { japanese }
    let japanese: String
    let romaji: String
    let english: String
    let partOfSpeech: String
}

struct WordToken: Identifiable {
    let id = UUID()
    let text: String
    let reading: String?
    let meaning: String?
    let partOfSpeech: String?
    let isFound: Bool
}

struct MissedWord: Codable {
    let word: String
    let context: String
    let timestamp: Date
}

@Observable
class DictionaryService {
    private var dictionary: [String: WordEntry] = [:]
    private var sortedKeys: [String] = []
    var missedWords: [MissedWord] = []

    private var missedWordsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("missed_words.json")
    }

    init() {
        loadDictionary()
        loadMissedWords()
    }

    private func loadDictionary() {
        guard let url = Bundle.main.url(forResource: "word_dictionary", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load word_dictionary.json")
            return
        }

        do {
            let entries = try JSONDecoder().decode([WordEntry].self, from: data)
            for entry in entries {
                dictionary[entry.japanese] = entry
            }
            sortedKeys = dictionary.keys.sorted { $0.count > $1.count }
        } catch {
            print("Error decoding dictionary: \(error)")
        }
    }

    func lookup(word: String) -> WordEntry? {
        dictionary[word]
    }

    func tokenize(phrase: String) -> [WordToken] {
        var tokens: [WordToken] = []
        var remaining = phrase

        while !remaining.isEmpty {
            var matched = false

            for key in sortedKeys {
                if remaining.hasPrefix(key) {
                    if let entry = dictionary[key] {
                        tokens.append(WordToken(
                            text: key,
                            reading: entry.romaji,
                            meaning: entry.english,
                            partOfSpeech: entry.partOfSpeech,
                            isFound: true
                        ))
                        remaining = String(remaining.dropFirst(key.count))
                        matched = true
                        break
                    }
                }
            }

            if !matched {
                let firstChar = String(remaining.prefix(1))

                if isJapanesePunctuation(firstChar) || firstChar.trimmingCharacters(in: .whitespaces).isEmpty {
                    tokens.append(WordToken(
                        text: firstChar,
                        reading: nil,
                        meaning: nil,
                        partOfSpeech: nil,
                        isFound: true
                    ))
                } else {
                    tokens.append(WordToken(
                        text: firstChar,
                        reading: nil,
                        meaning: nil,
                        partOfSpeech: nil,
                        isFound: false
                    ))
                }
                remaining = String(remaining.dropFirst(1))
            }
        }

        return mergeUnknownTokens(tokens)
    }

    private func mergeUnknownTokens(_ tokens: [WordToken]) -> [WordToken] {
        var result: [WordToken] = []
        var pendingUnknown = ""

        for token in tokens {
            if !token.isFound && token.meaning == nil && !isJapanesePunctuation(token.text) {
                pendingUnknown += token.text
            } else {
                if !pendingUnknown.isEmpty {
                    result.append(WordToken(
                        text: pendingUnknown,
                        reading: nil,
                        meaning: nil,
                        partOfSpeech: nil,
                        isFound: false
                    ))
                    pendingUnknown = ""
                }
                result.append(token)
            }
        }

        if !pendingUnknown.isEmpty {
            result.append(WordToken(
                text: pendingUnknown,
                reading: nil,
                meaning: nil,
                partOfSpeech: nil,
                isFound: false
            ))
        }

        return result
    }

    private func isJapanesePunctuation(_ char: String) -> Bool {
        let punctuation: Set<String> = ["。", "、", "？", "！", "「", "」", "『", "』", "（", "）", "・", "〜", "…", " ", "　"]
        return punctuation.contains(char)
    }

    func saveMissedWord(_ word: String, context: String) {
        guard !word.isEmpty else { return }

        if missedWords.contains(where: { $0.word == word }) {
            return
        }

        let missed = MissedWord(word: word, context: context, timestamp: Date())
        missedWords.append(missed)
        saveMissedWords()
    }

    private func loadMissedWords() {
        guard FileManager.default.fileExists(atPath: missedWordsURL.path()),
              let data = try? Data(contentsOf: missedWordsURL) else {
            return
        }

        do {
            missedWords = try JSONDecoder().decode([MissedWord].self, from: data)
        } catch {
            print("Error loading missed words: \(error)")
        }
    }

    private func saveMissedWords() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(missedWords)
            try data.write(to: missedWordsURL, options: .atomic)
        } catch {
            print("Error saving missed words: \(error)")
        }
    }
}
