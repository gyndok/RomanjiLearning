import Foundation

struct ScenarioDeck: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let categories: Set<String>
    let maxDifficulty: Int
    let keywords: [String]

    func phrases(from allPhrases: [Phrase]) -> [Phrase] {
        allPhrases.filter { phrase in
            guard phrase.difficulty <= maxDifficulty else { return false }
            if !categories.isEmpty && !categories.contains(phrase.category) {
                return false
            }
            if !keywords.isEmpty {
                let text = (phrase.english + " " + (phrase.context ?? "")).lowercased()
                return keywords.contains { text.contains($0.lowercased()) }
            }
            return true
        }
    }

    static func == (lhs: ScenarioDeck, rhs: ScenarioDeck) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static let allDecks: [ScenarioDeck] = [
        ScenarioDeck(
            id: "first-day",
            name: "First Day Essentials",
            description: "The absolute must-know phrases for your first day in Japan",
            icon: "star.fill",
            categories: [],
            maxDifficulty: 1,
            keywords: []
        ),
        ScenarioDeck(
            id: "restaurant",
            name: "Restaurant Survival",
            description: "Order food, handle allergies, ask for the check",
            icon: "fork.knife",
            categories: ["Restaurant & Food"],
            maxDifficulty: 3,
            keywords: []
        ),
        ScenarioDeck(
            id: "train-station",
            name: "Train Station Pro",
            description: "Navigate trains, buy tickets, find platforms",
            icon: "tram.fill",
            categories: ["Transportation"],
            maxDifficulty: 3,
            keywords: []
        ),
        ScenarioDeck(
            id: "getting-around",
            name: "Getting Around",
            description: "Directions, landmarks, and finding your way",
            icon: "map.fill",
            categories: ["Directions & Navigation"],
            maxDifficulty: 3,
            keywords: []
        ),
        ScenarioDeck(
            id: "hotel",
            name: "Hotel Check-in",
            description: "Reservations, room issues, amenities, check-out",
            icon: "bed.double.fill",
            categories: ["Accommodation"],
            maxDifficulty: 3,
            keywords: []
        ),
        ScenarioDeck(
            id: "shopping",
            name: "Shopping Spree",
            description: "Prices, sizes, tax-free shopping, and receipts",
            icon: "bag.fill",
            categories: ["Shopping", "Numbers & Money"],
            maxDifficulty: 3,
            keywords: []
        ),
        ScenarioDeck(
            id: "emergency",
            name: "Emergency Kit",
            description: "Critical phrases for health emergencies and lost items",
            icon: "cross.case.fill",
            categories: ["Emergency & Health"],
            maxDifficulty: 2,
            keywords: []
        ),
        ScenarioDeck(
            id: "polite",
            name: "Polite Traveler",
            description: "Cultural phrases, temple etiquette, and respectful speech",
            icon: "hands.sparkles.fill",
            categories: ["Polite Expressions", "Greetings & Basics"],
            maxDifficulty: 4,
            keywords: []
        ),
        ScenarioDeck(
            id: "making-friends",
            name: "Making Friends",
            description: "Introduce yourself, small talk, and compliments",
            icon: "person.2.fill",
            categories: ["Self-Introduction", "Weather & Small Talk"],
            maxDifficulty: 3,
            keywords: []
        ),
        ScenarioDeck(
            id: "tech",
            name: "Stay Connected",
            description: "Wi-Fi, charging, SIM cards, and phone help",
            icon: "wifi",
            categories: ["Technology & Communication"],
            maxDifficulty: 3,
            keywords: []
        ),
    ]
}
