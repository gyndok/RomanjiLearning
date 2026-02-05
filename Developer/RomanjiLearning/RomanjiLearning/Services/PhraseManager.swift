import Foundation

@Observable
class PhraseManager {
    var phrases: [Phrase] = []
    var selectedCategories: Set<String> = []

    var categories: [String] {
        Array(Set(phrases.map(\.category))).sorted()
    }

    var filteredPhrases: [Phrase] {
        if selectedCategories.isEmpty {
            return phrases
        }
        return phrases.filter { selectedCategories.contains($0.category) }
    }

    var favorites: [Phrase] {
        phrases.filter(\.isFavorite)
    }

    var totalCount: Int { phrases.count }
    var userAddedCount: Int { phrases.filter(\.isUserAdded).count }
    var favoritesCount: Int { favorites.count }

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("phrases.json")
    }

    init() {
        loadPhrases()
    }

    func loadPhrases() {
        if FileManager.default.fileExists(atPath: documentsURL.path()) {
            do {
                let data = try Data(contentsOf: documentsURL)
                phrases = try JSONDecoder().decode([Phrase].self, from: data)
                return
            } catch {
                print("Error loading from documents: \(error)")
            }
        }

        guard let url = Bundle.main.url(forResource: "japanese_travel_phrases", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load bundled phrases")
            return
        }

        do {
            phrases = try JSONDecoder().decode([Phrase].self, from: data)
            savePhrases()
        } catch {
            print("Error decoding bundled phrases: \(error)")
        }
    }

    func savePhrases() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(phrases)
            try data.write(to: documentsURL, options: .atomic)
        } catch {
            print("Error saving phrases: \(error)")
        }
    }

    func addPhrase(_ phrase: Phrase) {
        phrases.append(phrase)
        savePhrases()
    }

    func updatePhrase(_ phrase: Phrase) {
        guard let index = phrases.firstIndex(where: { $0.id == phrase.id }) else { return }
        phrases[index] = phrase
        savePhrases()
    }

    func deletePhrase(_ phrase: Phrase) {
        phrases.removeAll { $0.id == phrase.id }
        savePhrases()
    }

    func deletePhrase(at offsets: IndexSet, from list: [Phrase]) {
        let idsToRemove = offsets.map { list[$0].id }
        phrases.removeAll { idsToRemove.contains($0.id) }
        savePhrases()
    }

    func toggleFavorite(_ phrase: Phrase) {
        guard let index = phrases.firstIndex(where: { $0.id == phrase.id }) else { return }
        phrases[index].isFavorite.toggle()
        savePhrases()
    }

    func search(query: String) -> [Phrase] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let q = trimmed.lowercased()
        return phrases.filter {
            $0.english.lowercased().contains(q)
            || $0.japanese.contains(trimmed)
            || $0.romaji.lowercased().contains(q)
        }
    }

    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}
