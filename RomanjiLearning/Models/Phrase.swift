import Foundation

struct Phrase: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    let english: String
    let japanese: String
    let romaji: String
    let category: String
    let difficulty: Int
    var context: String?
    var isUserAdded: Bool
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        english: String,
        japanese: String,
        romaji: String,
        category: String,
        difficulty: Int,
        context: String? = nil,
        isUserAdded: Bool = false,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.english = english
        self.japanese = japanese
        self.romaji = romaji
        self.category = category
        self.difficulty = difficulty
        self.context = context
        self.isUserAdded = isUserAdded
        self.isFavorite = isFavorite
    }

    enum CodingKeys: String, CodingKey {
        case id, english, japanese, romaji, category, difficulty, context, isUserAdded, isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.english = try container.decode(String.self, forKey: .english)
        self.japanese = try container.decode(String.self, forKey: .japanese)
        self.romaji = try container.decode(String.self, forKey: .romaji)
        self.category = try container.decode(String.self, forKey: .category)
        self.difficulty = try container.decode(Int.self, forKey: .difficulty)
        self.context = try container.decodeIfPresent(String.self, forKey: .context)
        self.isUserAdded = (try? container.decode(Bool.self, forKey: .isUserAdded)) ?? false
        self.isFavorite = (try? container.decode(Bool.self, forKey: .isFavorite)) ?? false
    }
}
