import Foundation

@Observable
class SRSManager {
    var srsData: [String: SRSData] = [:]

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sm2_srs_data.json")
    }

    init() {
        load()
    }

    // MARK: - Queries

    func getDueCards(from phrases: [Phrase]) -> [Phrase] {
        let now = Date()
        return phrases.filter { phrase in
            let key = phrase.id.uuidString
            guard let data = srsData[key] else { return true }
            return data.nextReview <= now
        }
    }

    func getDueCount() -> Int {
        let now = Date()
        var count = 0
        for (_, data) in srsData {
            if data.nextReview <= now {
                count += 1
            }
        }
        return count
    }

    func getDueCount(from phrases: [Phrase]) -> Int {
        getDueCards(from: phrases).count
    }

    func getLearnedCount() -> Int {
        srsData.values.filter { $0.interval > 21 }.count
    }

    func getTotalReviews() -> Int {
        srsData.values.reduce(0) { $0 + $1.repetitions }
    }

    // MARK: - SM-2 Algorithm

    func recordReview(phraseId: String, rating: SRSRating) {
        var data = srsData[phraseId] ?? SRSData(
            phraseId: phraseId,
            nextReview: Date()
        )

        data.lastReviewed = Date()

        let q = Double(rating.rawValue)

        if rating == .again {
            data.repetitions = 0
            data.interval = 1
        } else {
            if data.repetitions == 0 {
                data.interval = 1
            } else if data.repetitions == 1 {
                data.interval = 6
            } else {
                data.interval = Int(round(Double(data.interval) * data.easeFactor))
            }
            data.repetitions += 1
        }

        // Update ease factor using SM-2 formula
        let newEF = data.easeFactor + (0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02))
        data.easeFactor = max(1.3, newEF)

        // Adjust interval based on rating
        switch rating {
        case .again:
            data.interval = 1
        case .hard:
            data.interval = max(1, Int(Double(data.interval) * 0.8))
        case .good:
            break // standard interval
        case .easy:
            data.interval = Int(Double(data.interval) * 1.3)
        }

        data.nextReview = Calendar.current.date(
            byAdding: .day,
            value: max(1, data.interval),
            to: Date()
        ) ?? Date()

        srsData[phraseId] = data
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path()),
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: SRSData].self, from: data) else { return }
        srsData = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(srsData) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
