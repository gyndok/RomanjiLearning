import SwiftUI

struct ScenarioListView: View {
    @Environment(PhraseManager.self) private var phraseManager

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(ScenarioDeck.allDecks) { deck in
                    let count = deck.phrases(from: phraseManager.phrases).count
                    NavigationLink(value: deck) {
                        deckCard(deck, phraseCount: count)
                    }
                    .buttonStyle(.scale)
                }
            }
            .padding()
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("Scenarios")
        .navigationDestination(for: ScenarioDeck.self) { deck in
            ScenarioDetailView(deck: deck)
        }
    }

    private func deckCard(_ deck: ScenarioDeck, phraseCount: Int) -> some View {
        VStack(spacing: 10) {
            Image(systemName: deck.icon)
                .font(.system(size: 32))
                .foregroundStyle(.themeIndigo)
                .frame(height: 40)

            Text(deck.name)
                .font(.rounded(.headline, weight: .semibold))
                .foregroundStyle(.themeText)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(deck.description)
                .font(.rounded(.caption))
                .foregroundStyle(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Text("\(phraseCount) phrases")
                .font(.smallCapsCategory)
                .tracking(0.5)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.themeIndigo.opacity(0.1))
                .foregroundStyle(.themeIndigo)
                .clipShape(Capsule())
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180)
        .themeCard(cornerRadius: 16)
    }
}

// MARK: - Scenario Detail

struct ScenarioDetailView: View {
    let deck: ScenarioDeck

    @Environment(PhraseManager.self) private var phraseManager
    @Environment(ProgressManager.self) private var progressManager
    @Environment(AudioService.self) private var audioService

    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var showQuiz = false
    @State private var flipCount = 0

    private var phrases: [Phrase] {
        deck.phrases(from: phraseManager.phrases)
    }

    private var currentPhrase: Phrase? {
        guard !phrases.isEmpty, currentIndex >= 0, currentIndex < phrases.count else { return nil }
        return phrases[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let phrase = currentPhrase {
                HStack {
                    Text("\(currentIndex + 1) / \(phrases.count)")
                        .font(.rounded(.caption))
                        .foregroundStyle(.themeTextSecondary)
                    Spacer()
                    masteryBadge(for: phrase.id)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                scenarioCard(for: phrase)

                Spacer()

                srsButtons(for: phrase)
                    .padding(.bottom, 8)

                scenarioNavigation
                    .padding(.bottom, 20)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.on.rectangle.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.themeTextSecondary.opacity(0.4))
                    Text("No Phrases")
                        .font(.rounded(.title3, weight: .semibold))
                        .foregroundStyle(.themeText)
                    Text("This scenario has no matching phrases.")
                        .font(.rounded(.subheadline))
                        .foregroundStyle(.themeTextSecondary)
                }
            }
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: flipCount)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if phrases.count >= 4 {
                    Button {
                        showQuiz = true
                    } label: {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(.themeIndigo)
                    }
                }
            }
        }
        .sheet(isPresented: $showQuiz) {
            NavigationStack {
                ScenarioQuizView(phrases: phrases)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { showQuiz = false }
                                .foregroundStyle(.themeTextSecondary)
                        }
                    }
            }
        }
    }

    private func scenarioCard(for phrase: Phrase) -> some View {
        ZStack {
            scenarioFront(phrase)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            scenarioBack(phrase)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .onTapGesture {
            withAnimation(.spring(duration: 0.4)) { isFlipped.toggle() }
            flipCount += 1
        }
    }

    private func scenarioFront(_ phrase: Phrase) -> some View {
        VStack(spacing: 16) {
            Text("Tap to reveal")
                .font(.rounded(.caption2))
                .foregroundStyle(.themeTextSecondary.opacity(0.5))

            Text(phrase.english)
                .font(.rounded(.title, weight: .semibold))
                .foregroundStyle(.themeText)
                .multilineTextAlignment(.center)

            if let context = phrase.context {
                Text(context)
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.themeTextSecondary)
                    .multilineTextAlignment(.center)
            }

            difficultyDots(phrase.difficulty)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding(30)
        .themeCard(cornerRadius: 20)
        .padding(.horizontal, 24)
    }

    private func scenarioBack(_ phrase: Phrase) -> some View {
        VStack(spacing: 16) {
            Text(phrase.japanese)
                .font(.japanese(size: 32))
                .foregroundStyle(.themeText)
                .multilineTextAlignment(.center)

            Text(phrase.romaji)
                .font(.romaji(size: 18))
                .foregroundStyle(.themeTextSecondary)

            Divider()
                .background(Color.themeSakura.opacity(0.3))
                .padding(.horizontal, 20)

            Text(phrase.english)
                .font(.rounded(.subheadline))
                .foregroundStyle(.themeTextSecondary)

            Button {
                audioService.speak(phrase.japanese)
            } label: {
                Label("Listen", systemImage: "speaker.wave.2.fill")
                    .font(.rounded(.subheadline, weight: .medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.themeIndigo.opacity(0.15))
                    .foregroundStyle(.themeIndigo)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding(30)
        .themeCard(cornerRadius: 20)
        .padding(.horizontal, 24)
    }

    private func srsButtons(for phrase: Phrase) -> some View {
        HStack(spacing: 20) {
            Button {
                progressManager.recordReview(phraseID: phrase.id, correct: false)
                goToNext()
            } label: {
                Label("Still Learning", systemImage: "arrow.counterclockwise")
                    .font(.rounded(.subheadline, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }

            Button {
                progressManager.recordReview(phraseID: phrase.id, correct: true)
                goToNext()
            } label: {
                Label("Know It", systemImage: "checkmark")
                    .font(.rounded(.subheadline, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.themeMatcha)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .opacity(isFlipped ? 1 : 0.3)
        .disabled(!isFlipped)
    }

    private func masteryBadge(for id: UUID) -> some View {
        let level = progressManager.masteryLevel(for: id)
        return Text(level.rawValue)
            .font(.smallCapsCategory)
            .tracking(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(masteryColor(level).opacity(0.15))
            .foregroundStyle(masteryColor(level))
            .clipShape(Capsule())
    }

    private func masteryColor(_ level: MasteryLevel) -> Color {
        switch level {
        case .unseen: return .themeTextSecondary
        case .learning: return .orange
        case .familiar: return .themeIndigo
        case .mastered: return .themeMatcha
        }
    }

    private func difficultyDots(_ level: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= level ? Color.themeVermillion : Color.themeTextSecondary.opacity(0.2))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private var scenarioNavigation: some View {
        HStack(spacing: 40) {
            Button { goToPrevious() } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(currentIndex > 0 ? Color.themeIndigo : Color.themeTextSecondary.opacity(0.3))
            }
            .disabled(currentIndex == 0)

            Button {
                if let phrase = currentPhrase {
                    audioService.speak(phrase.japanese)
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 28))
                    .padding(14)
                    .background(Color.themeIndigo)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.scale)

            Button { goToNext() } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(currentIndex < phrases.count - 1 ? Color.themeIndigo : Color.themeTextSecondary.opacity(0.3))
            }
            .disabled(currentIndex >= phrases.count - 1)
        }
    }

    private func goToNext() {
        guard currentIndex < phrases.count - 1 else { return }
        withAnimation(.spring(duration: 0.3)) { currentIndex += 1; isFlipped = false }
    }

    private func goToPrevious() {
        guard currentIndex > 0 else { return }
        withAnimation(.spring(duration: 0.3)) { currentIndex -= 1; isFlipped = false }
    }
}

// MARK: - Scenario Quiz (mini quiz within a scenario)

struct ScenarioQuizView: View {
    let phrases: [Phrase]

    @Environment(ProgressManager.self) private var progressManager
    @Environment(AudioService.self) private var audioService

    @State private var quizPhrases: [Phrase] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var score = 0
    @State private var showResult = false
    @State private var quizFinished = false
    @State private var wrongShake: CGFloat = 0

    private var currentPhrase: Phrase? {
        guard currentIndex < quizPhrases.count else { return nil }
        return quizPhrases[currentIndex]
    }

    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()

            if quizFinished {
                scenarioQuizResults
            } else if let phrase = currentPhrase {
                scenarioQuizCard(phrase)
            } else {
                ProgressView()
                    .onAppear { startQuiz() }
            }
        }
    }

    private func scenarioQuizCard(_ phrase: Phrase) -> some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(currentIndex), total: Double(quizPhrases.count))
                .tint(.themeSakura)
                .padding(.horizontal)
                .padding(.top, 8)

            HStack {
                Text("\(currentIndex + 1) / \(quizPhrases.count)")
                    .font(.rounded(.caption))
                    .foregroundStyle(.themeTextSecondary)
                Spacer()
                Text("Score: \(score)")
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(.themeIndigo)
            }
            .padding(.horizontal)
            .padding(.top, 4)

            Spacer()

            VStack(spacing: 12) {
                Text(phrase.japanese)
                    .font(.japanese(size: 32))
                    .foregroundStyle(.themeText)
                Text(phrase.romaji)
                    .font(.romaji(size: 18))
                    .foregroundStyle(.themeTextSecondary)
                Button { audioService.speak(phrase.japanese) } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .padding(10)
                        .background(Color.themeIndigo.opacity(0.15))
                        .foregroundStyle(.themeIndigo)
                        .clipShape(Circle())
                }
            }
            .padding()
            .themeCard(cornerRadius: 16)
            .padding(.horizontal)

            Spacer()

            let choices = generateChoices(for: phrase)
            VStack(spacing: 10) {
                ForEach(choices, id: \.self) { choice in
                    scenarioAnswerButton(choice: choice, correctAnswer: phrase.english)
                }
            }
            .padding(.horizontal)
            .disabled(showResult)
            .modifier(ShakeEffect(animatableData: wrongShake))

            Spacer()

            if showResult {
                Button {
                    advance()
                } label: {
                    Text(currentIndex < quizPhrases.count - 1 ? "Next" : "See Results")
                        .font(.rounded(.headline, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.sakuraIndigo)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.scale)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("Scenario Quiz")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func scenarioAnswerButton(choice: String, correctAnswer: String) -> some View {
        let isSelected = selectedAnswer == choice
        let isCorrect = choice == correctAnswer

        return Button {
            select(choice, correct: correctAnswer)
        } label: {
            HStack {
                Text(choice)
                    .font(.rounded(.body))
                    .foregroundStyle(.themeText)
                    .multilineTextAlignment(.leading)
                Spacer()
                if showResult && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.themeMatcha)
                } else if showResult && isSelected && !isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.themeVermillion)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(answerBackground(isSelected: isSelected, isCorrect: isCorrect))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(answerBorder(isSelected: isSelected, isCorrect: isCorrect), lineWidth: 2)
            )
        }
    }

    private func answerBackground(isSelected: Bool, isCorrect: Bool) -> Color {
        guard showResult else { return .themeCardBg }
        if isCorrect { return Color.themeMatcha.opacity(0.15) }
        if isSelected && !isCorrect { return Color.themeVermillion.opacity(0.15) }
        return .themeCardBg
    }

    private func answerBorder(isSelected: Bool, isCorrect: Bool) -> Color {
        guard showResult else { return .clear }
        if isCorrect { return .themeMatcha }
        if isSelected && !isCorrect { return .themeVermillion }
        return .clear
    }

    private var scenarioQuizResults: some View {
        VStack(spacing: 24) {
            Spacer()
            let pct = quizPhrases.isEmpty ? 0.0 : Double(score) / Double(quizPhrases.count)

            ZStack {
                Circle()
                    .stroke(Color.themeTextSecondary.opacity(0.12), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.themeIndigo, .themeSakura]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(score) / \(quizPhrases.count)")
                        .font(.rounded(size: 32, weight: .bold))
                        .foregroundStyle(.themeText)
                    Text("\(Int(pct * 100))%")
                        .font(.rounded(.caption))
                        .foregroundStyle(.themeTextSecondary)
                }
            }
            .frame(width: 140, height: 140)

            Text(pct >= 0.7 ? "Great job!" : "Keep practicing!")
                .font(.rounded(.title3, weight: .semibold))
                .foregroundStyle(.themeText)

            Spacer()

            Button {
                startQuiz()
            } label: {
                Text("Try Again")
                    .font(.rounded(.headline, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.sakuraIndigo)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.scale)
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .navigationTitle("Results")
    }

    private func startQuiz() {
        quizPhrases = phrases.shuffled()
        currentIndex = 0
        score = 0
        selectedAnswer = nil
        showResult = false
        quizFinished = false
    }

    private func generateChoices(for phrase: Phrase) -> [String] {
        var choices = [phrase.english]
        let others = phrases.filter { $0.id != phrase.id }.shuffled()
        for other in others where choices.count < 4 {
            if !choices.contains(other.english) {
                choices.append(other.english)
            }
        }
        return choices.shuffled()
    }

    private func select(_ answer: String, correct: String) {
        selectedAnswer = answer
        let isCorrect = answer == correct
        if isCorrect { score += 1 }
        if !isCorrect {
            withAnimation(.spring(duration: 0.3)) { wrongShake = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { wrongShake = 0 }
        }
        if let phrase = currentPhrase {
            progressManager.recordReview(phraseID: phrase.id, correct: isCorrect)
        }
        withAnimation(.spring(duration: 0.3)) { showResult = true }
    }

    private func advance() {
        if currentIndex < quizPhrases.count - 1 {
            currentIndex += 1
            selectedAnswer = nil
            showResult = false
        } else {
            withAnimation(.spring(duration: 0.3)) { quizFinished = true }
        }
    }
}
