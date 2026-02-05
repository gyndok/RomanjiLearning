import SwiftUI

enum DeckFilter: String, CaseIterable {
    case all = "All"
    case favorites = "Favorites"
    case dueForReview = "Due"
    case category = "By Category"
}

struct FlashcardView: View {
    @Environment(PhraseManager.self) private var phraseManager
    @Environment(AudioService.self) private var audioService
    @Environment(ProgressManager.self) private var progressManager
    @Environment(SRSManager.self) private var srsManager

    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var dragOffset: CGFloat = 0
    @State private var deckFilter: DeckFilter = .all
    @State private var showCategoryFilter = false
    @State private var selectedDetail: Phrase?
    @State private var showSRSStudy = false

    private var cards: [Phrase] {
        switch deckFilter {
        case .all: return phraseManager.phrases
        case .favorites: return phraseManager.favorites
        case .dueForReview: return progressManager.phrasesForReview(from: phraseManager.phrases)
        case .category: return phraseManager.filteredPhrases
        }
    }

    private var currentPhrase: Phrase? {
        guard !cards.isEmpty, currentIndex >= 0, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    let dueCount = srsManager.getDueCount(from: phraseManager.phrases)
                    if dueCount > 0 {
                        Button {
                            showSRSStudy = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .foregroundStyle(.themeVermillion)
                                Text("\(dueCount) card\(dueCount == 1 ? "" : "s") due for review")
                                    .font(.rounded(.subheadline, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.themeVermillion.opacity(0.1))
                            .foregroundStyle(.themeVermillion)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.scale)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    filterPicker

                    if deckFilter == .category {
                        categoryBar
                    }

                    if let phrase = currentPhrase {
                        HStack {
                            progressLabel
                            Spacer()
                            masteryBadge(for: phrase.id)
                        }
                        .padding(.horizontal)

                        Spacer()

                        flashcard(for: phrase)
                            .offset(x: dragOffset)
                            .gesture(swipeGesture)

                        Spacer()

                        srsButtons(for: phrase)
                            .padding(.bottom, 4)

                        navigationBar
                            .padding(.bottom, 20)
                    } else {
                        Spacer()
                        emptyStateView
                        Spacer()
                    }
                }
            }
            .navigationTitle("Learn")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if progressManager.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.themeVermillion)
                                .font(.subheadline)
                            Text("\(progressManager.currentStreak)")
                                .font(.rounded(.subheadline, weight: .bold))
                                .foregroundStyle(.themeVermillion)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard !cards.isEmpty else { return }
                        currentIndex = Int.random(in: 0..<cards.count)
                        isFlipped = false
                    } label: {
                        Image(systemName: "shuffle")
                            .foregroundStyle(.themeIndigo)
                    }
                }
            }
            .onChange(of: deckFilter) {
                currentIndex = 0
                isFlipped = false
            }
            .onChange(of: phraseManager.selectedCategories) {
                currentIndex = 0
                isFlipped = false
            }
            .navigationDestination(item: $selectedDetail) { phrase in
                PhraseDetailView(phraseID: phrase.id)
            }
            .navigationDestination(isPresented: $showSRSStudy) {
                SRSStudyView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyIcon)
                .font(.system(size: 48))
                .foregroundStyle(.themeTextSecondary.opacity(0.5))
            Text(emptyTitle)
                .font(.rounded(.title3, weight: .semibold))
                .foregroundStyle(.themeText)
            Text(emptyDescription)
                .font(.rounded(.subheadline))
                .foregroundStyle(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var emptyTitle: String {
        switch deckFilter {
        case .favorites: return "No Favorites"
        case .dueForReview: return "All Caught Up!"
        default: return "No Phrases"
        }
    }

    private var emptyIcon: String {
        switch deckFilter {
        case .favorites: return "heart.slash"
        case .dueForReview: return "checkmark.circle"
        default: return "rectangle.on.rectangle.slash"
        }
    }

    private var emptyDescription: String {
        switch deckFilter {
        case .favorites: return "Tap the heart on any card to add favorites."
        case .dueForReview: return "No phrases are due for review right now. Great job!"
        default: return "Select a category or add new phrases."
        }
    }

    // MARK: - Filter Picker

    private var filterPicker: some View {
        Picker("Filter", selection: $deckFilter) {
            ForEach(DeckFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Category Filter

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(phraseManager.categories, id: \.self) { category in
                    let isSelected = phraseManager.selectedCategories.contains(category)
                    Button {
                        phraseManager.toggleCategory(category)
                    } label: {
                        Text(category)
                            .font(.smallCapsCategory)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.themeIndigo : Color.themeIndigo.opacity(0.08))
                            .foregroundStyle(isSelected ? .white : .themeIndigo)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.scale)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Progress

    private var progressLabel: some View {
        Text("\(currentIndex + 1) / \(cards.count)")
            .font(.rounded(.caption))
            .foregroundStyle(.themeTextSecondary)
            .padding(.top, 8)
    }

    private func masteryBadge(for id: UUID) -> some View {
        let level = progressManager.masteryLevel(for: id)
        return Text(level.rawValue)
            .font(.rounded(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(masteryColor(level).opacity(0.15))
            .foregroundStyle(masteryColor(level))
            .clipShape(Capsule())
            .padding(.top, 8)
    }

    private func masteryColor(_ level: MasteryLevel) -> Color {
        switch level {
        case .unseen: return .themeTextSecondary
        case .learning: return .themeVermillion
        case .familiar: return .themeIndigo
        case .mastered: return .themeMatcha
        }
    }

    // MARK: - Flashcard

    private func flashcard(for phrase: Phrase) -> some View {
        ZStack {
            frontFace(phrase)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            backFace(phrase)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isFlipped)
        .onTapGesture {
            if !isFlipped {
                progressManager.recordReview(phraseId: phrase.id.uuidString)
            }
            withAnimation(.spring(duration: 0.4)) {
                isFlipped.toggle()
            }
        }
    }

    private func frontFace(_ phrase: Phrase) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text(phrase.category)
                    .font(.smallCapsCategory)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.themeIndigo.opacity(0.1))
                    .foregroundStyle(.themeIndigo)
                    .clipShape(Capsule())
                Spacer()
                favoriteButton(phrase)
                detailButton(phrase)
            }

            Spacer()

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

            Spacer()

            difficultyDots(phrase.difficulty)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .padding(28)
        .themeCard()
        .padding(.horizontal, 24)
    }

    private func backFace(_ phrase: Phrase) -> some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                favoriteButton(phrase)
                detailButton(phrase)
            }

            Spacer()

            Text(phrase.japanese)
                .font(.japanese(size: 32))
                .foregroundStyle(.themeText)
                .multilineTextAlignment(.center)

            Text(phrase.romaji)
                .font(.romaji(size: 18))
                .foregroundStyle(.themeTextSecondary)
                .multilineTextAlignment(.center)

            Divider()
                .background(Color.themeSakura.opacity(0.3))
                .padding(.horizontal, 20)

            Text(phrase.english)
                .font(.rounded(.subheadline))
                .foregroundStyle(.themeTextSecondary)

            Spacer()

            Button {
                audioService.speak(phrase.japanese)
            } label: {
                Label("Listen", systemImage: "speaker.wave.2.fill")
                    .font(.rounded(.subheadline, weight: .medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.themeSakura.opacity(0.15))
                    .foregroundStyle(.themeSakura)
                    .clipShape(Capsule())
            }
            .buttonStyle(.scale)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .padding(28)
        .themeCard()
        .padding(.horizontal, 24)
    }

    // MARK: - SRS Buttons

    private func srsButtons(for phrase: Phrase) -> some View {
        HStack(spacing: 16) {
            Button {
                progressManager.recordReview(phraseID: phrase.id, correct: false)
                goToNext()
            } label: {
                Label("Still Learning", systemImage: "arrow.counterclockwise")
                    .font(.rounded(.subheadline, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.themeVermillion.opacity(0.12))
                    .foregroundStyle(.themeVermillion)
                    .clipShape(Capsule())
            }
            .buttonStyle(.scale)

            Button {
                progressManager.recordReview(phraseID: phrase.id, correct: true)
                goToNext()
            } label: {
                Label("Know It", systemImage: "checkmark")
                    .font(.rounded(.subheadline, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.themeMatcha.opacity(0.12))
                    .foregroundStyle(.themeMatcha)
                    .clipShape(Capsule())
            }
            .buttonStyle(.scale)
        }
        .opacity(isFlipped ? 1 : 0.3)
        .disabled(!isFlipped)
    }

    private func favoriteButton(_ phrase: Phrase) -> some View {
        Button {
            phraseManager.toggleFavorite(phrase)
        } label: {
            Image(systemName: phrase.isFavorite ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundStyle(phrase.isFavorite ? .themeSakura : .themeTextSecondary)
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: phrase.isFavorite)
    }

    private func detailButton(_ phrase: Phrase) -> some View {
        Button {
            selectedDetail = phrase
        } label: {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(.themeIndigo)
        }
    }

    private func difficultyDots(_ level: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= level ? Color.themeVermillion : Color.themeTextSecondary.opacity(0.2))
                    .frame(width: 7, height: 7)
            }
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
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
                    .foregroundStyle(currentIndex < cards.count - 1 ? Color.themeIndigo : Color.themeTextSecondary.opacity(0.3))
            }
            .disabled(currentIndex >= cards.count - 1)
        }
    }

    // MARK: - Gestures & Actions

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 80
                if value.translation.width < -threshold {
                    goToNext()
                } else if value.translation.width > threshold {
                    goToPrevious()
                }
                withAnimation(.spring(duration: 0.3)) {
                    dragOffset = 0
                }
            }
    }

    private func goToNext() {
        guard currentIndex < cards.count - 1 else { return }
        withAnimation(.spring(duration: 0.3)) { currentIndex += 1; isFlipped = false }
    }

    private func goToPrevious() {
        guard currentIndex > 0 else { return }
        withAnimation(.spring(duration: 0.3)) { currentIndex -= 1; isFlipped = false }
    }
}
