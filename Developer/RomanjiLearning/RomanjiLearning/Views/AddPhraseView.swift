import SwiftUI
import Translation

struct AddPhraseView: View {
    @Environment(PhraseManager.self) private var phraseManager
    @Environment(TranslationService.self) private var translationService

    @State private var englishText = ""
    @State private var japaneseText = ""
    @State private var romajiText = ""
    @State private var selectedCategory = "Custom"
    @State private var selectedDifficulty = 1
    @State private var contextText = ""
    @State private var showConfirmation = false
    @State private var showTranslationSheet = false
    @State private var translationConfig: Any?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter English phrase", text: $englishText)
                        .font(.rounded(.body))
                        .autocorrectionDisabled()

                    Button {
                        translatePhrase()
                    } label: {
                        Label("Translate to Japanese", systemImage: "translate")
                            .font(.rounded(.body, weight: .medium))
                            .foregroundStyle(.themeIndigo)
                    }
                    .disabled(englishText.trimmingCharacters(in: .whitespaces).isEmpty)
                } header: {
                    Text("ENGLISH PHRASE")
                        .font(.smallCapsCategory)
                        .tracking(1)
                }

                Section {
                    TextField("Japanese (auto-filled by translation)", text: $japaneseText)
                        .font(.japanese(size: 18))
                    TextField("Romaji (pronunciation)", text: $romajiText)
                        .font(.romaji(size: 16))
                        .autocorrectionDisabled()
                } header: {
                    Text("JAPANESE TRANSLATION")
                        .font(.smallCapsCategory)
                        .tracking(1)
                }

                Section {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Custom").tag("Custom")
                        ForEach(phraseManager.categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .font(.rounded(.body))

                    HStack {
                        Text("Difficulty")
                            .font(.rounded(.body))
                            .foregroundStyle(.themeText)
                        Spacer()
                        ForEach(1...5, id: \.self) { level in
                            Button {
                                selectedDifficulty = level
                            } label: {
                                Image(systemName: level <= selectedDifficulty ? "star.fill" : "star")
                                    .foregroundStyle(level <= selectedDifficulty ? .themeVermillion : .themeTextSecondary.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextField("Context note (optional)", text: $contextText)
                        .font(.rounded(.body))
                } header: {
                    Text("DETAILS")
                        .font(.smallCapsCategory)
                        .tracking(1)
                }

                if !japaneseText.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(englishText)
                                .font(.rounded(.headline))
                                .foregroundStyle(.themeText)
                            Text(japaneseText)
                                .font(.japanese(size: 22))
                                .foregroundStyle(.themeText)
                            if !romajiText.isEmpty {
                                Text(romajiText)
                                    .font(.romaji(size: 16))
                                    .foregroundStyle(.themeTextSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("PREVIEW")
                            .font(.smallCapsCategory)
                            .tracking(1)
                    }
                }

                Section {
                    Button {
                        addPhrase()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Add to Deck", systemImage: "plus.circle.fill")
                                .font(.rounded(.headline, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(LinearGradient.sakuraIndigo)
                    .disabled(englishText.trimmingCharacters(in: .whitespaces).isEmpty
                              || japaneseText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Add Phrase")
            .modifier(TranslationPresenter(
                isPresented: $showTranslationSheet,
                text: englishText,
                onResult: { handleTranslationResult($0) }
            ))
            .modifier(SessionTranslationModifier(
                config: $translationConfig,
                sourceText: englishText,
                onResult: { handleTranslationResult($0) }
            ))
            .overlay {
                if showConfirmation {
                    confirmationBadge
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Translation

    private func translatePhrase() {
        if #available(iOS 18, *) {
            let config = TranslationSession.Configuration(
                source: Locale.Language(identifier: "en"),
                target: Locale.Language(identifier: "ja")
            )
            translationConfig = config
        } else {
            showTranslationSheet = true
        }
    }

    private func handleTranslationResult(_ japanese: String) {
        japaneseText = japanese
        // Automatically generate romaji from the Japanese text
        romajiText = RomajiConverter.convert(japanese)
    }

    // MARK: - Add Phrase

    private func addPhrase() {
        let phrase = Phrase(
            english: englishText.trimmingCharacters(in: .whitespaces),
            japanese: japaneseText.trimmingCharacters(in: .whitespaces),
            romaji: romajiText.trimmingCharacters(in: .whitespaces),
            category: selectedCategory,
            difficulty: selectedDifficulty,
            context: contextText.isEmpty ? nil : contextText.trimmingCharacters(in: .whitespaces),
            isUserAdded: true
        )
        phraseManager.addPhrase(phrase)

        withAnimation(.spring(duration: 0.3)) { showConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(duration: 0.3)) { showConfirmation = false }
            resetForm()
        }
    }

    private func resetForm() {
        englishText = ""
        japaneseText = ""
        romajiText = ""
        contextText = ""
        selectedDifficulty = 1
    }

    private var confirmationBadge: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.themeMatcha)
            Text("Phrase Added!")
                .font(.rounded(.headline, weight: .semibold))
                .foregroundStyle(.themeText)
        }
        .padding(30)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Translation View Modifiers

private struct TranslationPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let text: String
    let onResult: (String) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17.4, *) {
            content.translationPresentation(
                isPresented: $isPresented,
                text: text,
                replacementAction: onResult
            )
        } else {
            content
        }
    }
}

private struct SessionTranslationModifier: ViewModifier {
    @Binding var config: Any?
    let sourceText: String
    let onResult: (String) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content.onChange(of: config as? TranslationSession.Configuration) { _, newValue in
            }
            .translationTask(config as? TranslationSession.Configuration) { session in
                guard !sourceText.isEmpty else { return }
                do {
                    let response = try await session.translate(sourceText)
                    await MainActor.run { onResult(response.targetText) }
                } catch {
                    print("Translation error: \(error)")
                }
                await MainActor.run { config = nil }
            }
        } else {
            content
        }
    }
}
