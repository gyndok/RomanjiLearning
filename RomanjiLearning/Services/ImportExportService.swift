import Foundation
import UniformTypeIdentifiers

struct ImportResult {
    var importedCount: Int = 0
    var duplicateCount: Int = 0
    var errorCount: Int = 0
}

@Observable
class ImportExportService {
    var parsedPhrases: [Phrase] = []
    var parseErrors: [String] = []
    var importResult: ImportResult?
    var isShowingPreview = false
    var isShowingResult = false
    var errorMessage: String?
    var duplicateCount = 0

    // MARK: - Parse File

    func parseFile(at url: URL, existingPhrases: [Phrase]) {
        reset()

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let ext = url.pathExtension.lowercased()

            var phrases: [Phrase]
            if ext == "csv" {
                phrases = parseCSV(data: data)
            } else if ext == "json" {
                phrases = try parseJSON(data: data)
            } else {
                errorMessage = "Unsupported file format. Please use .csv or .json files."
                return
            }

            guard !phrases.isEmpty else {
                if parseErrors.isEmpty {
                    errorMessage = "No valid phrases found in the file."
                } else {
                    errorMessage = "No valid phrases found. \(parseErrors.count) row(s) had errors."
                }
                return
            }

            // Duplicate detection
            let existingSet = Set(existingPhrases.map { DuplicateKey(english: $0.english.lowercased(), japanese: $0.japanese) })
            var unique: [Phrase] = []
            var dupes = 0
            for phrase in phrases {
                let key = DuplicateKey(english: phrase.english.lowercased(), japanese: phrase.japanese)
                if existingSet.contains(key) {
                    dupes += 1
                } else {
                    unique.append(phrase)
                }
            }

            duplicateCount = dupes
            parsedPhrases = unique
            isShowingPreview = true
        } catch {
            errorMessage = "Failed to read file: \(error.localizedDescription)"
        }
    }

    // MARK: - Confirm Import

    func confirmImport(into phraseManager: PhraseManager) {
        let count = parsedPhrases.count
        phraseManager.addPhrases(parsedPhrases)
        importResult = ImportResult(
            importedCount: count,
            duplicateCount: duplicateCount,
            errorCount: parseErrors.count
        )
        parsedPhrases = []
        isShowingPreview = false
        isShowingResult = true
    }

    // MARK: - Export

    func exportCSV(phrases: [Phrase]) -> URL? {
        var csv = "english,japanese,romaji,category,difficulty\n"
        for phrase in phrases {
            csv += "\(csvEscape(phrase.english)),\(csvEscape(phrase.japanese)),\(csvEscape(phrase.romaji)),\(csvEscape(phrase.category)),\(phrase.difficulty)\n"
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("my_phrases.csv")
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            errorMessage = "Failed to export: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Template

    func generateTemplate() -> URL? {
        let csv = """
        english,japanese,romaji,category,difficulty
        Hello,こんにちは,konnichiwa,Greetings,1
        Thank you,ありがとうございます,arigatou gozaimasu,Greetings,1
        Where is the station?,駅はどこですか?,eki wa doko desu ka?,Transportation,2
        """

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("phrase_template.csv")
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            errorMessage = "Failed to create template: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Reset

    func reset() {
        parsedPhrases = []
        parseErrors = []
        importResult = nil
        isShowingPreview = false
        isShowingResult = false
        errorMessage = nil
        duplicateCount = 0
    }

    // MARK: - CSV Parsing

    private func parseCSV(data: Data) -> [Phrase] {
        guard let content = String(data: data, encoding: .utf8) else {
            parseErrors.append("File is not valid UTF-8 text.")
            return []
        }

        let rows = parseCSVRows(content)
        guard rows.count > 1 else {
            parseErrors.append("File appears to be empty or has only a header row.")
            return []
        }

        let header = rows[0].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }

        guard let englishIdx = header.firstIndex(of: "english"),
              let japaneseIdx = header.firstIndex(of: "japanese") else {
            parseErrors.append("CSV must have 'english' and 'japanese' columns in the header.")
            return []
        }

        let romajiIdx = header.firstIndex(of: "romaji")
        let categoryIdx = header.firstIndex(of: "category")
        let difficultyIdx = header.firstIndex(of: "difficulty")

        var phrases: [Phrase] = []

        for rowIndex in 1..<rows.count {
            let fields = rows[rowIndex]

            guard fields.count > max(englishIdx, japaneseIdx) else {
                parseErrors.append("Row \(rowIndex + 1): not enough columns.")
                continue
            }

            let english = fields[englishIdx].trimmingCharacters(in: .whitespaces)
            let japanese = fields[japaneseIdx].trimmingCharacters(in: .whitespaces)

            guard !english.isEmpty, !japanese.isEmpty else {
                parseErrors.append("Row \(rowIndex + 1): english or japanese is empty.")
                continue
            }

            let romaji: String
            if let idx = romajiIdx, idx < fields.count {
                romaji = fields[idx].trimmingCharacters(in: .whitespaces)
            } else {
                romaji = ""
            }

            let category: String
            if let idx = categoryIdx, idx < fields.count {
                let val = fields[idx].trimmingCharacters(in: .whitespaces)
                category = val.isEmpty ? "Custom" : val
            } else {
                category = "Custom"
            }

            let difficulty: Int
            if let idx = difficultyIdx, idx < fields.count,
               let val = Int(fields[idx].trimmingCharacters(in: .whitespaces)),
               (1...5).contains(val) {
                difficulty = val
            } else {
                difficulty = 3
            }

            phrases.append(Phrase(
                english: english,
                japanese: japanese,
                romaji: romaji,
                category: category,
                difficulty: difficulty,
                isUserAdded: true
            ))
        }

        return phrases
    }

    private func parseCSVRows(_ content: String) -> [[String]] {
        var rows: [[String]] = []
        var currentField = ""
        var currentRow: [String] = []
        var inQuotes = false
        let chars = Array(content)
        var i = 0

        while i < chars.count {
            let ch = chars[i]

            if inQuotes {
                if ch == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                        continue
                    } else {
                        inQuotes = false
                        i += 1
                        continue
                    }
                } else {
                    currentField.append(ch)
                    i += 1
                    continue
                }
            }

            if ch == "\"" {
                inQuotes = true
                i += 1
                continue
            }

            if ch == "," {
                currentRow.append(currentField)
                currentField = ""
                i += 1
                continue
            }

            if ch == "\r" {
                if i + 1 < chars.count && chars[i + 1] == "\n" {
                    i += 1
                }
                currentRow.append(currentField)
                currentField = ""
                if !currentRow.allSatisfy({ $0.isEmpty }) || !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = []
                i += 1
                continue
            }

            if ch == "\n" {
                currentRow.append(currentField)
                currentField = ""
                if !currentRow.allSatisfy({ $0.isEmpty }) || !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = []
                i += 1
                continue
            }

            currentField.append(ch)
            i += 1
        }

        // Handle last field/row
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows
    }

    // MARK: - JSON Parsing

    private func parseJSON(data: Data) throws -> [Phrase] {
        var phrases = try JSONDecoder().decode([Phrase].self, from: data)
        for i in phrases.indices {
            phrases[i].id = UUID()
            phrases[i].isUserAdded = true
        }
        return phrases
    }

    // MARK: - Helpers

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}

private struct DuplicateKey: Hashable {
    let english: String
    let japanese: String
}
