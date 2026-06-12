import SwiftUI

struct QuizResultView: View {
    let quizManager: QuizManager
    let onNewQuiz: () -> Void
    let onDone: () -> Void

    @Environment(AudioService.self) private var audioService
    @State private var showMissedReview = false
    @State private var ringProgress: Double = 0

    private var percentage: Double {
        guard !quizManager.questions.isEmpty else { return 0 }
        return Double(quizManager.score) / Double(quizManager.questions.count)
    }

    private var message: String {
        if percentage >= 0.8 { return "Amazing work!" }
        if percentage >= 0.5 { return "Good effort, keep going!" }
        return "Practice makes perfect!"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                ZStack {
                    Circle()
                        .stroke(Color.themeTextSecondary.opacity(0.12), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.themeIndigo, .themeSakura]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text("\(quizManager.score)/\(quizManager.questions.count)")
                            .font(.rounded(size: 36, weight: .bold))
                            .foregroundStyle(.themeText)
                        Text("\(Int(percentage * 100))%")
                            .font(.rounded(.subheadline, weight: .medium))
                            .foregroundStyle(.themeTextSecondary)
                    }
                }
                .frame(width: 160, height: 160)
                .onAppear {
                    withAnimation(.spring(duration: 1.0).delay(0.2)) {
                        ringProgress = percentage
                    }
                }

                Text(message)
                    .font(.rounded(.title3, weight: .semibold))
                    .foregroundStyle(.themeText)

                let missed = quizManager.missedQuestions
                if !missed.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PHRASES TO REVIEW")
                            .font(.smallCapsCategory)
                            .tracking(1)
                            .foregroundStyle(.themeTextSecondary)
                            .padding(.horizontal)

                        ForEach(Array(missed.enumerated()), id: \.offset) { _, question in
                            missedRow(question)
                        }
                    }
                    .padding(.top, 8)
                }

                Spacer(minLength: 20)

                VStack(spacing: 12) {
                    if !missed.isEmpty {
                        Button {
                            showMissedReview = true
                        } label: {
                            Label("Review Missed Phrases", systemImage: "arrow.counterclockwise")
                                .font(.rounded(.headline, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.themeVermillion)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.scale)
                    }

                    Button {
                        onNewQuiz()
                    } label: {
                        Text("New Quiz")
                            .font(.rounded(.headline, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.sakuraIndigo)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.scale)

                    Button {
                        onDone()
                    } label: {
                        Text("Done")
                            .font(.rounded(.headline, weight: .medium))
                            .foregroundStyle(.themeText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.themeCardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }
                    .buttonStyle(.scale)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMissedReview) {
            MissedPhrasesReview(questions: quizManager.missedQuestions)
        }
    }

    private func missedRow(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(question.phrase.japanese)
                    .font(.japanese(size: 18))
                    .foregroundStyle(.themeText)
                Spacer()
                Button {
                    audioService.speak(question.phrase.japanese)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(.themeSakura)
                }
            }

            Text(question.phrase.romaji)
                .font(.romaji(size: 14))
                .foregroundStyle(.themeTextSecondary)

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.themeMatcha)
                    .font(.caption)
                Text(question.correctOption)
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.themeMatcha)
            }

            if let userAnswer = question.userAnswer, userAnswer != question.correctIndex {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.themeVermillion)
                        .font(.caption)
                    Text(question.options[userAnswer])
                        .font(.rounded(.subheadline))
                        .foregroundStyle(.themeVermillion)
                        .strikethrough()
                }
            }
        }
        .padding()
        .background(Color.themeCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Missed Phrases Flashcard Review

private struct MissedPhrasesReview: View {
    let questions: [QuizQuestion]

    @Environment(AudioService.self) private var audioService
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var isFlipped = false

    private var current: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if let q = current {
                        Text("\(currentIndex + 1) / \(questions.count)")
                            .font(.rounded(.caption))
                            .foregroundStyle(.themeTextSecondary)
                            .padding(.top, 12)

                        Spacer()

                        ZStack {
                            frontCard(q.phrase)
                                .opacity(isFlipped ? 0 : 1)
                                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                            backCard(q.phrase)
                                .opacity(isFlipped ? 1 : 0)
                                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                        }
                        .sensoryFeedback(.impact(flexibility: .soft), trigger: isFlipped)
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.4)) { isFlipped.toggle() }
                        }

                        Spacer()

                        HStack(spacing: 40) {
                            Button {
                                guard currentIndex > 0 else { return }
                                withAnimation(.spring(duration: 0.3)) { currentIndex -= 1; isFlipped = false }
                            } label: {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(currentIndex > 0 ? Color.themeIndigo : Color.themeTextSecondary.opacity(0.3))
                            }
                            .disabled(currentIndex == 0)

                            Button {
                                audioService.speak(q.phrase.japanese)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 28))
                                    .padding(14)
                                    .background(Color.themeIndigo)
                                    .foregroundStyle(.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.scale)

                            Button {
                                guard currentIndex < questions.count - 1 else { return }
                                withAnimation(.spring(duration: 0.3)) { currentIndex += 1; isFlipped = false }
                            } label: {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(currentIndex < questions.count - 1 ? Color.themeIndigo : Color.themeTextSecondary.opacity(0.3))
                            }
                            .disabled(currentIndex >= questions.count - 1)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.themeSakura)
                }
            }
        }
    }

    private func frontCard(_ phrase: Phrase) -> some View {
        VStack(spacing: 16) {
            Text("Tap to reveal")
                .font(.rounded(.caption2))
                .foregroundStyle(.themeTextSecondary.opacity(0.6))
            Text(phrase.english)
                .font(.rounded(size: 22, weight: .semibold))
                .foregroundStyle(.themeText)
                .multilineTextAlignment(.center)
            if let context = phrase.context {
                Text(context)
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.themeTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding(30)
        .themeCard()
        .padding(.horizontal, 24)
    }

    private func backCard(_ phrase: Phrase) -> some View {
        VStack(spacing: 16) {
            Text(phrase.japanese)
                .font(.japanese(size: 30))
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
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding(30)
        .themeCard()
        .padding(.horizontal, 24)
    }
}
