import Foundation

struct SRSData: Codable {
    var phraseId: String
    var lastReviewed: Date?
    var nextReview: Date
    var easeFactor: Double = 2.5
    var interval: Int = 1
    var repetitions: Int = 0
}

enum SRSRating: Int, CaseIterable {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3

    var label: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }
}
