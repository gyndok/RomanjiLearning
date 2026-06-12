import SwiftUI

struct QuizView: View {
    @Environment(PhraseManager.self) private var phraseManager
    @Environment(ProgressManager.self) private var progressManager
    @Environment(AudioService.self) private var audioService

    @State private var quizManager = QuizManager()
    @State private var showSetup = true
    @State private var selectedType: QuizType = .japaneseToEnglish
    @State private var selectedIndex: Int? = nil
    @State private var showingAnswer = false
    @State private var wrongAnswerShake: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()

                if showSetup {
                    setupView
                } else if quizManager.isComplete {
                    QuizResultView(
                        quizManager: quizManager,
                        onNewQuiz: { resetToSetup() },
                        onDone: { resetToSetup() }
                    )
                } else {
                    questionView
                }
            }
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.themeIndigo.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 52))
                    .foregroundStyle(.themeIndigo)
            }

            Text("Quiz Mode")
                .font(.rounded(.largeTitle, weight: .bold))
                .foregroundStyle(.themeText)

            VStack(spacing: 12) {
                Text("QUIZ TYPE")
                    .font(.smallCapsCategory)
                    .tracking(1)
                    .foregroundStyle(.themeTextSecondary)

                ForEach(QuizType.allCases) { type in
                    Button {
                        selectedType = type
                    } label: {
                        HStack {
                            Image(systemName: typeIcon(type))
                                .font(.title3)
                                .foregroundStyle(.themeIndigo)
                                .frame(width: 28)
                            Text(type.rawValue)
                                .font(.rounded(.body, weight: .medium))
                                .foregroundStyle(.themeText)
                            Spacer()
                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.themeSakura)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedType == type
                                    ? Color.themeSakura.opacity(0.08)
                                    : Color.themeCardBg)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedType == type ? Color.themeSakura : .clear, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                    }
                    .buttonStyle(.scale)
                }
            }
            .padding(.horizontal, 30)

            VStack(spacing: 8) {
                Text("QUESTIONS")
                    .font(.smallCapsCategory)
                    .tracking(1)
                    .foregroundStyle(.themeTextSecondary)
                Picker("Questions", selection: $quizManager.totalQuestions) {
                    Text("5").tag(5)
                    Text("10").tag(10)
                    Text("20").tag(20)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
            }

            let available = phraseManager.phrases.count
            Text("\(available) phrases available")
                .font(.rounded(.caption))
                .foregroundStyle(.themeTextSecondary)

            Button {
                startQuiz()
            } label: {
                Text("Start Quiz")
                    .font(.rounded(.headline, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.sakuraIndigo)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.scale)
            .padding(.horizontal, 40)
            .disabled(available < 4)

            Spacer()
        }
        .navigationTitle("Quiz")
    }

    private func typeIcon(_ type: QuizType) -> String {
        switch type {
        case .englishToJapanese: return "character.book.closed"
        case .japaneseToEnglish: return "textformat.alt"
        case .audioToEnglish: return "speaker.wave.2.fill"
        }
    }

    // MARK: - Question View

    private var questionView: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(quizManager.currentQuestion), total: Double(quizManager.questions.count))
                .tint(.themeSakura)
                .padding(.horizontal)
                .padding(.top, 8)

            HStack {
                Text("Question \(quizManager.currentQuestion + 1)/\(quizManager.questions.count)")
                    .font(.rounded(.caption))
                    .foregroundStyle(.themeTextSecondary)
                Spacer()
                Text("Score: \(quizManager.score)")
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(.themeIndigo)
            }
            .padding(.horizontal)
            .padding(.top, 4)

            Spacer()

            if let question = quizManager.current {
                promptView(for: question)
                    .padding(.horizontal)

                Spacer()

                VStack(spacing: 10) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        optionButton(option: option, index: index, question: question)
                    }
                }
                .padding(.horizontal)
                .disabled(showingAnswer)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: selectedIndex)
            }

            Spacer()
        }
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: quizManager.currentQuestion) {
            if quizManager.quizType == .audioToEnglish, let q = quizManager.current {
                audioService.speak(q.phrase.japanese)
            }
        }
        .onAppear {
            if quizManager.quizType == .audioToEnglish, let q = quizManager.current {
                audioService.speak(q.phrase.japanese)
            }
        }
    }

    private func promptView(for question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            switch quizManager.quizType {
            case .englishToJapanese:
                Text(question.phrase.english)
                    .font(.rounded(size: 24, weight: .bold))
                    .foregroundStyle(.themeText)
                    .multilineTextAlignment(.center)
                if let context = question.phrase.context {
                    Text(context)
                        .font(.rounded(.subheadline))
                        .foregroundStyle(.themeTextSecondary)
                }

            case .japaneseToEnglish:
                Text(question.phrase.japanese)
                    .font(.japanese(size: 32))
                    .foregroundStyle(.themeText)
                    .multilineTextAlignment(.center)
                Text(question.phrase.romaji)
                    .font(.romaji(size: 18))
                    .foregroundStyle(.themeTextSecondary)
                Button {
                    audioService.speak(question.phrase.japanese)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .padding(10)
                        .background(Color.themeSakura.opacity(0.15))
                        .foregroundStyle(.themeSakura)
                        .clipShape(Circle())
                }
                .buttonStyle(.scale)

            case .audioToEnglish:
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.themeIndigo)
                Text("Listen and choose")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.themeTextSecondary)
                Button {
                    audioService.speak(question.phrase.japanese)
                } label: {
                    Label("Play Again", systemImage: "speaker.wave.2.fill")
                        .font(.rounded(.headline, weight: .medium))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.themeIndigo.opacity(0.12))
                        .foregroundStyle(.themeIndigo)
                        .clipShape(Capsule())
                }
                .buttonStyle(.scale)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .themeCard(cornerRadius: 16)
    }

    // MARK: - Option Button

    private func optionButton(option: String, index: Int, question: QuizQuestion) -> some View {
        let isSelected = selectedIndex == index
        let isCorrect = index == question.correctIndex
        let isWrong = showingAnswer && isSelected && !isCorrect

        let bgColor: Color = {
            guard showingAnswer else { return .themeCardBg }
            if isCorrect { return Color.themeMatcha.opacity(0.12) }
            if isSelected && !isCorrect { return Color.themeVermillion.opacity(0.12) }
            return .themeCardBg
        }()

        let borderColor: Color = {
            guard showingAnswer else { return .clear }
            if isCorrect { return .themeMatcha }
            if isSelected && !isCorrect { return .themeVermillion }
            return .clear
        }()

        return Button {
            handleAnswer(index: index)
        } label: {
            HStack {
                Text(option)
                    .font(.rounded(.body, weight: .medium))
                    .foregroundStyle(.themeText)
                    .multilineTextAlignment(.leading)
                Spacer()
                if showingAnswer && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.themeMatcha)
                } else if showingAnswer && isSelected && !isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.themeVermillion)
                }
            }
            .padding(16)
            .frame(minHeight: 56)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.scale)
        .modifier(ShakeEffect(animatableData: isWrong ? wrongAnswerShake : 0))
    }

    // MARK: - Logic

    private func startQuiz() {
        quizManager.generateQuiz(type: selectedType, phrases: phraseManager.phrases)
        selectedIndex = nil
        showingAnswer = false
        wrongAnswerShake = 0
        showSetup = false
    }

    private func handleAnswer(index: Int) {
        selectedIndex = index
        quizManager.submitAnswer(index: index)

        let question = quizManager.questions[quizManager.currentQuestion]
        let isWrong = index != question.correctIndex

        withAnimation(.spring(duration: 0.3)) {
            showingAnswer = true
            if isWrong { wrongAnswerShake = 1 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showingAnswer = false
            selectedIndex = nil
            wrongAnswerShake = 0

            if quizManager.currentQuestion >= quizManager.questions.count - 1 {
                progressManager.recordQuiz(score: quizManager.score, total: quizManager.questions.count)
            }

            quizManager.advanceToNext()
        }
    }

    private func resetToSetup() {
        quizManager.reset()
        selectedIndex = nil
        showingAnswer = false
        wrongAnswerShake = 0
        showSetup = true
    }
}
