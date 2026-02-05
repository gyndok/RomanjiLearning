import Foundation

enum QuizType: String, CaseIterable, Identifiable {
    case englishToJapanese = "English → Japanese"
    case japaneseToEnglish = "Japanese → English"
    case audioToEnglish = "Listen & Answer"

    var id: String { rawValue }
}

struct QuizQuestion {
    let phrase: Phrase
    let options: [String]
    let correctIndex: Int
    var userAnswer: Int?

    var isCorrect: Bool {
        guard let answer = userAnswer else { return false }
        return answer == correctIndex
    }

    var correctOption: String {
        options[correctIndex]
    }
}

@Observable
class QuizManager {
    var currentQuestion: Int = 0
    var score: Int = 0
    var totalQuestions: Int = 10
    var questions: [QuizQuestion] = []
    var isComplete: Bool = false
    var quizType: QuizType = .japaneseToEnglish

    var current: QuizQuestion? {
        guard currentQuestion < questions.count else { return nil }
        return questions[currentQuestion]
    }

    var missedQuestions: [QuizQuestion] {
        questions.filter { q in
            guard let answer = q.userAnswer else { return true }
            return answer != q.correctIndex
        }
    }

    func generateQuiz(type: QuizType, phrases: [Phrase]) {
        quizType = type
        currentQuestion = 0
        score = 0
        isComplete = false

        let shuffled = phrases.shuffled()
        let count = min(totalQuestions, shuffled.count)
        let selected = Array(shuffled.prefix(count))

        questions = selected.map { phrase in
            buildQuestion(for: phrase, type: type, allPhrases: phrases)
        }
    }

    func submitAnswer(index: Int) {
        guard currentQuestion < questions.count else { return }
        questions[currentQuestion].userAnswer = index
        if index == questions[currentQuestion].correctIndex {
            score += 1
        }
    }

    func advanceToNext() {
        if currentQuestion >= questions.count - 1 {
            isComplete = true
        } else {
            currentQuestion += 1
        }
    }

    func reset() {
        currentQuestion = 0
        score = 0
        isComplete = false
        questions = []
    }

    // MARK: - Private

    private func buildQuestion(for phrase: Phrase, type: QuizType, allPhrases: [Phrase]) -> QuizQuestion {
        let correctAnswer: String
        switch type {
        case .englishToJapanese:
            correctAnswer = phrase.japanese
        case .japaneseToEnglish, .audioToEnglish:
            correctAnswer = phrase.english
        }

        var distractors: [String] = []
        let others = allPhrases.filter { $0.id != phrase.id }.shuffled()
        for other in others where distractors.count < 3 {
            let option: String
            switch type {
            case .englishToJapanese:
                option = other.japanese
            case .japaneseToEnglish, .audioToEnglish:
                option = other.english
            }
            if option != correctAnswer && !distractors.contains(option) {
                distractors.append(option)
            }
        }

        var options = distractors + [correctAnswer]
        options.shuffle()
        let correctIndex = options.firstIndex(of: correctAnswer) ?? 0

        return QuizQuestion(phrase: phrase, options: options, correctIndex: correctIndex)
    }
}
