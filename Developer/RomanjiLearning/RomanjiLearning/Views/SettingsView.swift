import SwiftUI

struct SettingsView: View {
    @Environment(PhraseManager.self) private var phraseManager
    @Environment(AudioService.self) private var audioService
    @Environment(ProgressManager.self) private var progressManager
    @Environment(SRSManager.self) private var srsManager

    var body: some View {
        NavigationStack {
            Form {
                progressSection
                srsStatsSection
                quizStatsSection
                statisticsSection
                audioSection
                categorySection
                scenariosSection
                offlineSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Settings")
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        Section {
            NavigationLink {
                StudyProgressView()
            } label: {
                Label("View Progress", systemImage: "chart.bar.fill")
                    .font(.rounded(.body))
            }

            LabeledContent {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.themeVermillion)
                        .font(.caption)
                    Text("\(progressManager.currentStreak) day\(progressManager.currentStreak == 1 ? "" : "s")")
                        .font(.rounded(.body))
                        .monospacedDigit()
                }
            } label: {
                Text("Current Streak")
                    .font(.rounded(.body))
            }

            LabeledContent {
                Text("\(progressManager.phrasesViewed.count) / \(phraseManager.totalCount)")
                    .font(.rounded(.body))
                    .monospacedDigit()
            } label: {
                Text("Phrases Learned")
                    .font(.rounded(.body))
            }
        } header: {
            Text("PROGRESS")
                .font(.smallCapsCategory)
                .tracking(1)
        }
    }

    // MARK: - SRS Stats

    private var srsStatsSection: some View {
        Section {
            LabeledContent {
                let due = srsManager.getDueCount(from: phraseManager.phrases)
                Text("\(due)")
                    .font(.rounded(.body, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(due > 0 ? .themeVermillion : .themeTextSecondary)
            } label: {
                Text("Cards Due Today")
                    .font(.rounded(.body))
            }

            LabeledContent {
                Text("\(srsManager.getLearnedCount())")
                    .font(.rounded(.body))
                    .monospacedDigit()
            } label: {
                Text("Cards Learned")
                    .font(.rounded(.body))
            }

            LabeledContent {
                Text("\(srsManager.getTotalReviews())")
                    .font(.rounded(.body))
                    .monospacedDigit()
            } label: {
                Text("Total SRS Reviews")
                    .font(.rounded(.body))
            }
        } header: {
            Text("SPACED REPETITION")
                .font(.smallCapsCategory)
                .tracking(1)
        }
    }

    // MARK: - Quiz Stats

    private var quizStatsSection: some View {
        Section {
            LabeledContent {
                Text("\(progressManager.quizzesTaken)")
                    .font(.rounded(.body))
                    .monospacedDigit()
            } label: {
                Text("Quizzes Taken")
                    .font(.rounded(.body))
            }

            if progressManager.quizzesTaken > 0 {
                LabeledContent {
                    let avg = Double(progressManager.totalQuizScore) / Double(progressManager.quizzesTaken)
                    Text(String(format: "%.1f", avg))
                        .font(.rounded(.body))
                        .monospacedDigit()
                } label: {
                    Text("Average Score")
                        .font(.rounded(.body))
                }
            }
        } header: {
            Text("QUIZ PERFORMANCE")
                .font(.smallCapsCategory)
                .tracking(1)
        }
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        Section {
            LabeledContent("Total Phrases", value: "\(phraseManager.totalCount)")
            LabeledContent("Bundled", value: "\(phraseManager.totalCount - phraseManager.userAddedCount)")
            LabeledContent("User-Added", value: "\(phraseManager.userAddedCount)")
            LabeledContent("Favorites", value: "\(phraseManager.favoritesCount)")

            if !phraseManager.selectedCategories.isEmpty {
                LabeledContent("Filtered View", value: "\(phraseManager.filteredPhrases.count) phrases")
            }
        } header: {
            Text("PHRASE LIBRARY")
                .font(.smallCapsCategory)
                .tracking(1)
        }
    }

    // MARK: - Audio

    private var audioSection: some View {
        Section {
            @Bindable var audio = audioService
            Toggle("Slow Speech", isOn: $audio.useSlowSpeed)
                .font(.rounded(.body))
                .tint(.themeSakura)

            Button {
                audioService.speak("こんにちは。日本へようこそ。")
            } label: {
                Label("Test Japanese Audio", systemImage: "speaker.wave.2")
                    .font(.rounded(.body))
                    .foregroundStyle(.themeIndigo)
            }
        } header: {
            Text("AUDIO PLAYBACK")
                .font(.smallCapsCategory)
                .tracking(1)
        }
    }

    // MARK: - Category Filters

    private var categorySection: some View {
        Section {
            ForEach(phraseManager.categories, id: \.self) { category in
                let count = phraseManager.phrases.filter { $0.category == category }.count
                let isSelected = phraseManager.selectedCategories.contains(category)

                Button {
                    phraseManager.toggleCategory(category)
                } label: {
                    HStack {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? .themeSakura : Color(.systemGray3))
                        Text(category)
                            .font(.rounded(.body))
                            .foregroundStyle(.themeText)
                        Spacer()
                        Text("\(count)")
                            .font(.rounded(.body))
                            .foregroundStyle(.themeTextSecondary)
                            .monospacedDigit()
                    }
                }
            }

            if !phraseManager.selectedCategories.isEmpty {
                Button("Clear All Filters", role: .destructive) {
                    phraseManager.selectedCategories.removeAll()
                }
                .font(.rounded(.body))
            }
        } header: {
            Text("CATEGORY FILTERS")
                .font(.smallCapsCategory)
                .tracking(1)
        } footer: {
            if phraseManager.selectedCategories.isEmpty {
                Text("All categories shown. Tap to filter the flashcard deck.")
                    .font(.rounded(.caption))
            } else {
                Text("\(phraseManager.selectedCategories.count) of \(phraseManager.categories.count) categories selected.")
                    .font(.rounded(.caption))
            }
        }
    }

    // MARK: - Scenarios

    private var scenariosSection: some View {
        Section {
            NavigationLink {
                ScenarioListView()
            } label: {
                Label("Browse Scenarios", systemImage: "map.fill")
                    .font(.rounded(.body))
            }
        } header: {
            Text("SCENARIO DECKS")
                .font(.smallCapsCategory)
                .tracking(1)
        }
    }

    // MARK: - Offline

    private var offlineSection: some View {
        Section {
            NavigationLink {
                OfflineLanguageView()
            } label: {
                Label("Download Japanese for Offline", systemImage: "arrow.down.circle")
                    .font(.rounded(.body))
            }
        } header: {
            Text("OFFLINE LANGUAGE")
                .font(.smallCapsCategory)
                .tracking(1)
        } footer: {
            Text("Download the Japanese language pack so translation and speech work without internet.")
                .font(.rounded(.caption))
        }
    }
}

// MARK: - Offline Language Instructions

struct OfflineLanguageView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.themeIndigo.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "globe.asia.australia.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.themeIndigo)
                }
                .padding(.top, 20)

                Text("Download Japanese Language")
                    .font(.rounded(.title2, weight: .semibold))
                    .foregroundStyle(.themeText)

                Text("To use translation and speech synthesis offline, download the Japanese language pack through system Settings.")
                    .font(.rounded(.body))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.themeTextSecondary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    step(1, "Open the Settings app")
                    step(2, "Go to General > Keyboard")
                    step(3, "Add a Japanese keyboard")
                    step(4, "Go to Apps > Translate > Downloaded Languages")
                    step(5, "Download Japanese")
                }
                .padding()
                .themeCard(cornerRadius: 14)
                .padding(.horizontal)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .font(.rounded(.headline, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient.sakuraIndigo)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.scale)
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("Offline Language")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.rounded(.caption, weight: .bold))
                .frame(width: 24, height: 24)
                .background(Color.themeIndigo)
                .foregroundStyle(.white)
                .clipShape(Circle())
            Text(text)
                .font(.rounded(.subheadline))
                .foregroundStyle(.themeText)
        }
    }
}
