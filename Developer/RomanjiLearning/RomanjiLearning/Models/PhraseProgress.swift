import Foundation

struct PhraseProgress: Codable, Identifiable {
    var id: UUID
    var timesReviewed: Int = 0
    var timesCorrect: Int = 0
    var lastReviewed: Date?
    var nextReview: Date?
    var easeFactor: Double = 2.5
    var interval: Int = 0
    var consecutiveCorrect: Int = 0

    var accuracy: Double {
        guard timesReviewed > 0 else { return 0 }
        return Double(timesCorrect) / Double(timesReviewed)
    }

    var needsReview: Bool {
        guard let next = nextReview else { return true }
        return Date() >= next
    }

    var masteryLevel: MasteryLevel {
        if timesReviewed == 0 { return .unseen }
        if consecutiveCorrect >= 5 { return .mastered }
        if consecutiveCorrect >= 3 { return .familiar }
        if timesReviewed >= 1 { return .learning }
        return .unseen
    }
}

enum MasteryLevel: String, Codable, CaseIterable {
    case unseen = "Unseen"
    case learning = "Learning"
    case familiar = "Familiar"
    case mastered = "Mastered"

    var color: String {
        switch self {
        case .unseen: return "systemGray"
        case .learning: return "systemOrange"
        case .familiar: return "systemBlue"
        case .mastered: return "systemGreen"
        }
    }
}

struct DailyStats: Codable {
    var date: String
    var reviewCount: Int = 0
    var correctCount: Int = 0
}

struct UserStats: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDate: String?
    var dailyHistory: [DailyStats] = []
    var totalLifetimeReviews: Int = 0

    static var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
