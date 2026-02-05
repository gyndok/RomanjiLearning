import Foundation

@Observable
class ProgressManager {
    // MARK: - SRS Data (existing)

    var progress: [UUID: PhraseProgress] = [:]
    var stats: UserStats = UserStats()

    // MARK: - Simple Progress Tracking

    var totalReviews: Int = 0
    var phrasesViewed: Set<String> = []
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastStudyDate: Date?
    var quizzesTaken: Int = 0
    var totalQuizScore: Int = 0

    // MARK: - File URLs

    private var srsProgressURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("srs_progress.json")
    }

    private var statsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("user_stats.json")
    }

    private var progressURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("progress.json")
    }

    init() {
        loadSRSProgress()
        loadStats()
        loadProgress()
        updateSRSStreak()
    }

    // MARK: - Simple Progress Review

    func recordReview(phraseId: String) {
        phrasesViewed.insert(phraseId)
        totalReviews += 1

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastStudyDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            if lastDay == today {
                // Same day — do nothing to streak
            } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                      calendar.startOfDay(for: yesterday) == lastDay {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastStudyDate = Date()

        saveProgress()
    }

    // MARK: - Quiz Tracking

    func recordQuiz(score: Int, total: Int) {
        quizzesTaken += 1
        totalQuizScore += score
        saveProgress()
    }

    // MARK: - SRS Review

    func recordReview(phraseID: UUID, correct: Bool) {
        var p = progress[phraseID] ?? PhraseProgress(id: phraseID)
        p.timesReviewed += 1
        p.lastReviewed = Date()

        if correct {
            p.timesCorrect += 1
            p.consecutiveCorrect += 1
            switch p.consecutiveCorrect {
            case 1: p.interval = 1
            case 2: p.interval = 3
            default: p.interval = Int(Double(p.interval) * p.easeFactor)
            }
            p.easeFactor = min(3.0, p.easeFactor + 0.1)
        } else {
            p.consecutiveCorrect = 0
            p.interval = 0
            p.easeFactor = max(1.3, p.easeFactor - 0.2)
        }

        p.nextReview = Calendar.current.date(byAdding: .day, value: max(1, p.interval), to: Date())
        progress[phraseID] = p

        updateDailyStats(correct: correct)
        saveSRSProgress()
        saveStats()
    }

    // MARK: - Queries

    func phrasesForReview(from phrases: [Phrase]) -> [Phrase] {
        phrases.filter { phrase in
            guard let p = progress[phrase.id] else { return true }
            return p.needsReview
        }
    }

    func masteryLevel(for phraseID: UUID) -> MasteryLevel {
        progress[phraseID]?.masteryLevel ?? .unseen
    }

    func progressFor(_ phraseID: UUID) -> PhraseProgress? {
        progress[phraseID]
    }

    var totalReviewed: Int {
        progress.values.filter { $0.timesReviewed > 0 }.count
    }

    var totalMastered: Int {
        progress.values.filter { $0.masteryLevel == .mastered }.count
    }

    var totalFamiliar: Int {
        progress.values.filter { $0.masteryLevel == .familiar }.count
    }

    var totalLearning: Int {
        progress.values.filter { $0.masteryLevel == .learning }.count
    }

    var overallAccuracy: Double {
        let reviewed = progress.values.filter { $0.timesReviewed > 0 }
        guard !reviewed.isEmpty else { return 0 }
        let totalCorrect = reviewed.reduce(0) { $0 + $1.timesCorrect }
        let totalAttempts = reviewed.reduce(0) { $0 + $1.timesReviewed }
        guard totalAttempts > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAttempts)
    }

    var todayReviewCount: Int {
        let today = UserStats.todayString
        return stats.dailyHistory.first { $0.date == today }?.reviewCount ?? 0
    }

    // MARK: - SRS Streak

    private func updateSRSStreak() {
        let today = UserStats.todayString
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let lastDate = stats.lastActiveDate,
              let lastDateObj = formatter.date(from: lastDate),
              let todayObj = formatter.date(from: today) else {
            return
        }

        let daysBetween = calendar.dateComponents([.day], from: lastDateObj, to: todayObj).day ?? 0

        if daysBetween > 1 {
            stats.currentStreak = 0
            saveStats()
        }
    }

    private func updateDailyStats(correct: Bool) {
        let today = UserStats.todayString

        if let index = stats.dailyHistory.firstIndex(where: { $0.date == today }) {
            stats.dailyHistory[index].reviewCount += 1
            if correct { stats.dailyHistory[index].correctCount += 1 }
        } else {
            if let lastDate = stats.lastActiveDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let lastObj = formatter.date(from: lastDate),
                   let todayObj = formatter.date(from: today) {
                    let days = Calendar.current.dateComponents([.day], from: lastObj, to: todayObj).day ?? 0
                    if days == 1 {
                        stats.currentStreak += 1
                    } else if days > 1 {
                        stats.currentStreak = 1
                    }
                }
            } else {
                stats.currentStreak = 1
            }
            stats.dailyHistory.append(DailyStats(date: today, reviewCount: 1, correctCount: correct ? 1 : 0))
        }

        stats.lastActiveDate = today
        stats.longestStreak = max(stats.longestStreak, stats.currentStreak)
        stats.totalLifetimeReviews += 1
    }

    // MARK: - Persistence (Simple Progress)

    private struct ProgressData: Codable {
        var totalReviews: Int
        var phrasesViewed: Set<String>
        var currentStreak: Int
        var longestStreak: Int
        var lastStudyDate: Date?
        var quizzesTaken: Int
        var totalQuizScore: Int

        init(totalReviews: Int, phrasesViewed: Set<String>, currentStreak: Int, longestStreak: Int, lastStudyDate: Date?, quizzesTaken: Int, totalQuizScore: Int) {
            self.totalReviews = totalReviews
            self.phrasesViewed = phrasesViewed
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.lastStudyDate = lastStudyDate
            self.quizzesTaken = quizzesTaken
            self.totalQuizScore = totalQuizScore
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            totalReviews = try container.decode(Int.self, forKey: .totalReviews)
            phrasesViewed = try container.decode(Set<String>.self, forKey: .phrasesViewed)
            currentStreak = try container.decode(Int.self, forKey: .currentStreak)
            longestStreak = try container.decode(Int.self, forKey: .longestStreak)
            lastStudyDate = try container.decodeIfPresent(Date.self, forKey: .lastStudyDate)
            quizzesTaken = (try? container.decode(Int.self, forKey: .quizzesTaken)) ?? 0
            totalQuizScore = (try? container.decode(Int.self, forKey: .totalQuizScore)) ?? 0
        }
    }

    private func loadProgress() {
        guard FileManager.default.fileExists(atPath: progressURL.path()),
              let data = try? Data(contentsOf: progressURL),
              let decoded = try? JSONDecoder().decode(ProgressData.self, from: data) else { return }
        totalReviews = decoded.totalReviews
        phrasesViewed = decoded.phrasesViewed
        currentStreak = decoded.currentStreak
        longestStreak = decoded.longestStreak
        lastStudyDate = decoded.lastStudyDate
        quizzesTaken = decoded.quizzesTaken
        totalQuizScore = decoded.totalQuizScore
    }

    private func saveProgress() {
        let payload = ProgressData(
            totalReviews: totalReviews,
            phrasesViewed: phrasesViewed,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastStudyDate: lastStudyDate,
            quizzesTaken: quizzesTaken,
            totalQuizScore: totalQuizScore
        )
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: progressURL, options: .atomic)
    }

    // MARK: - Persistence (SRS)

    private func loadSRSProgress() {
        guard FileManager.default.fileExists(atPath: srsProgressURL.path()),
              let data = try? Data(contentsOf: srsProgressURL),
              let decoded = try? JSONDecoder().decode([UUID: PhraseProgress].self, from: data) else { return }
        progress = decoded
    }

    private func saveSRSProgress() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        try? data.write(to: srsProgressURL, options: .atomic)
    }

    private func loadStats() {
        guard FileManager.default.fileExists(atPath: statsURL.path()),
              let data = try? Data(contentsOf: statsURL),
              let decoded = try? JSONDecoder().decode(UserStats.self, from: data) else { return }
        stats = decoded
    }

    private func saveStats() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        try? data.write(to: statsURL, options: .atomic)
    }
}
