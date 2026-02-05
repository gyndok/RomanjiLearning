import SwiftUI

struct SRSStudyView: View {
    @Environment(PhraseManager.self) private var phraseManager
    @Environment(SRSManager.self) private var srsManager
    @Environment(AudioService.self) private var audioService

    @State private var dueCards: [Phrase] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false

    private var currentPhrase: Phrase? {
        guard currentIndex >= 0, currentIndex < dueCards.count else { return nil }
        return dueCards[currentIndex]
    }

    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if dueCards.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.themeMatcha.opacity(0.6))
                        Text("All Caught Up!")
                            .font(.rounded(.title3, weight: .semibold))
                            .foregroundStyle(.themeText)
                        Text("No cards are due for review right now.")
                            .font(.rounded(.subheadline))
                            .foregroundStyle(.themeTextSecondary)
                    }
                    Spacer()
                } else if let phrase = currentPhrase {
                    dueHeader

                    Spacer()

                    srsCard(for: phrase)

                    Spacer()

                    ratingButtons(for: phrase)
                        .padding(.bottom, 8)

                    audioButton(for: phrase)
                        .padding(.bottom, 20)
                } else {
                    completedView
                }
            }
        }
        .navigationTitle("SRS Study")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDueCards()
        }
    }

    // MARK: - Due Header

    private var dueHeader: some View {
        HStack {
            Text("\(currentIndex + 1) / \(dueCards.count)")
                .font(.rounded(.caption))
                .foregroundStyle(.themeTextSecondary)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("\(dueCards.count - currentIndex) remaining")
                    .font(.rounded(.caption))
            }
            .foregroundStyle(.themeVermillion)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Card

    private func srsCard(for phrase: Phrase) -> some View {
        ZStack {
            srsFront(phrase)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            srsBack(phrase)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isFlipped)
        .onTapGesture {
            withAnimation(.spring(duration: 0.4)) { isFlipped.toggle() }
        }
    }

    private func srsFront(_ phrase: Phrase) -> some View {
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
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(30)
        .themeCard()
        .padding(.horizontal, 24)
    }

    private func srsBack(_ phrase: Phrase) -> some View {
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
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(30)
        .themeCard()
        .padding(.horizontal, 24)
    }

    // MARK: - Rating Buttons

    private func ratingButtons(for phrase: Phrase) -> some View {
        HStack(spacing: 10) {
            srsRatingButton(.again, color: .themeVermillion, for: phrase)
            srsRatingButton(.hard, color: .orange, for: phrase)
            srsRatingButton(.good, color: .themeMatcha, for: phrase)
            srsRatingButton(.easy, color: .themeIndigo, for: phrase)
        }
        .padding(.horizontal, 16)
        .opacity(isFlipped ? 1 : 0.3)
        .disabled(!isFlipped)
    }

    private func srsRatingButton(_ rating: SRSRating, color: Color, for phrase: Phrase) -> some View {
        Button {
            srsManager.recordReview(phraseId: phrase.id.uuidString, rating: rating)
            goToNext()
        } label: {
            VStack(spacing: 4) {
                Text(rating.label)
                    .font(.rounded(.subheadline, weight: .semibold))
                Text(intervalPreview(rating, for: phrase))
                    .font(.rounded(.caption2))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.scale)
    }

    private func intervalPreview(_ rating: SRSRating, for phrase: Phrase) -> String {
        let data = srsManager.srsData[phrase.id.uuidString]
        let currentInterval = data?.interval ?? 1
        let reps = data?.repetitions ?? 0
        let ef = data?.easeFactor ?? 2.5

        switch rating {
        case .again:
            return "1d"
        case .hard:
            let interval = max(1, Int(Double(currentInterval) * 0.8))
            return "\(interval)d"
        case .good:
            if reps == 0 { return "1d" }
            if reps == 1 { return "6d" }
            return "\(Int(round(Double(currentInterval) * ef)))d"
        case .easy:
            if reps == 0 { return "1d" }
            if reps == 1 { return "8d" }
            return "\(Int(round(Double(currentInterval) * ef * 1.3)))d"
        }
    }

    // MARK: - Audio

    private func audioButton(for phrase: Phrase) -> some View {
        Button {
            audioService.speak(phrase.japanese)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 24))
                .padding(12)
                .background(Color.themeIndigo)
                .foregroundStyle(.white)
                .clipShape(Circle())
        }
        .buttonStyle(.scale)
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.themeMatcha.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.themeMatcha)
            }
            Text("Session Complete!")
                .font(.rounded(.title2, weight: .semibold))
                .foregroundStyle(.themeText)
            Text("You've reviewed all due cards.")
                .font(.rounded(.subheadline))
                .foregroundStyle(.themeTextSecondary)
            Spacer()
        }
    }

    // MARK: - Navigation

    private func loadDueCards() {
        dueCards = srsManager.getDueCards(from: phraseManager.phrases)
        currentIndex = 0
        isFlipped = false
    }

    private func goToNext() {
        if currentIndex < dueCards.count - 1 {
            withAnimation(.spring(duration: 0.3)) {
                currentIndex += 1
                isFlipped = false
            }
        } else {
            withAnimation(.spring(duration: 0.3)) {
                currentIndex = dueCards.count
                isFlipped = false
            }
        }
    }
}
