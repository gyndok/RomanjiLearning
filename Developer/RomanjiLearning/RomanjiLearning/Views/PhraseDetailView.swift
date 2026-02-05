import SwiftUI

struct PhraseDetailView: View {
    @Environment(PhraseManager.self) private var phraseManager
    @Environment(AudioService.self) private var audioService
    @Environment(\.dismiss) private var dismiss

    let phraseID: UUID

    @State private var showDeleteConfirmation = false
    @State private var isEditing = false
    @State private var editEnglish = ""
    @State private var editJapanese = ""
    @State private var editRomaji = ""
    @State private var editContext = ""

    private var phrase: Phrase? {
        phraseManager.phrases.first { $0.id == phraseID }
    }

    var body: some View {
        ScrollView {
            if let phrase {
                VStack(spacing: 24) {
                    headerCard(phrase)
                    detailsSection(phrase)
                    actionsSection(phrase)
                }
                .padding()
            }
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("Phrase Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let phrase, phrase.isFavorite {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.themeSakura)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            if let phrase {
                editSheet(phrase)
            }
        }
        .confirmationDialog("Delete Phrase", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let phrase {
                    phraseManager.deletePhrase(phrase)
                    dismiss()
                }
            }
        } message: {
            Text("This phrase will be permanently removed from your deck.")
        }
    }

    // MARK: - Header Card

    private func headerCard(_ phrase: Phrase) -> some View {
        VStack(spacing: 16) {
            TappableJapaneseText(
                text: phrase.japanese,
                fontSize: 36,
                contextPhrase: phrase.japanese
            )
            .frame(maxWidth: .infinity)

            Text("Tap any word for its meaning")
                .font(.rounded(.caption2))
                .foregroundStyle(.themeTextSecondary.opacity(0.7))

            Text(phrase.romaji)
                .font(.romaji(size: 18))
                .foregroundStyle(.themeTextSecondary)

            Divider()
                .background(Color.themeSakura.opacity(0.3))
                .padding(.horizontal, 40)

            Text(phrase.english)
                .font(.rounded(.title3, weight: .medium))
                .foregroundStyle(.themeText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .themeCard()
    }

    // MARK: - Details

    private func detailsSection(_ phrase: Phrase) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let context = phrase.context, !context.isEmpty {
                Label(context, systemImage: "info.circle")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.themeTextSecondary)
            }

            HStack {
                Label(phrase.category, systemImage: "folder")
                    .font(.smallCapsCategory)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.themeIndigo.opacity(0.1))
                    .foregroundStyle(.themeIndigo)
                    .clipShape(Capsule())

                Spacer()

                HStack(spacing: 3) {
                    Text("Difficulty")
                        .font(.rounded(.caption))
                        .foregroundStyle(.themeTextSecondary)
                    ForEach(1...5, id: \.self) { i in
                        Circle()
                            .fill(i <= phrase.difficulty ? Color.themeVermillion : Color.themeTextSecondary.opacity(0.2))
                            .frame(width: 7, height: 7)
                    }
                }

                if phrase.isUserAdded {
                    Text("CUSTOM")
                        .font(.smallCapsCategory)
                        .tracking(0.5)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.themeMatcha.opacity(0.15))
                        .foregroundStyle(.themeMatcha)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Actions

    private func actionsSection(_ phrase: Phrase) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    phraseManager.toggleFavorite(phrase)
                } label: {
                    Label(
                        phrase.isFavorite ? "Favorited" : "Favorite",
                        systemImage: phrase.isFavorite ? "heart.fill" : "heart"
                    )
                    .frame(maxWidth: .infinity)
                }
                .tint(phrase.isFavorite ? .themeSakura : .themeIndigo)
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    audioService.speak(phrase.japanese)
                } label: {
                    Label("Listen", systemImage: "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.themeIndigo)
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            HStack(spacing: 16) {
                Button {
                    audioService.useSlowSpeed = true
                    audioService.speak(phrase.japanese)
                } label: {
                    Label("Slow", systemImage: "tortoise.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.themeIndigo)
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    audioService.useSlowSpeed = false
                    audioService.speak(phrase.japanese)
                } label: {
                    Label("Normal", systemImage: "hare.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.themeIndigo)
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            if phrase.isUserAdded {
                Divider()
                    .background(Color.themeSakura.opacity(0.3))
                    .padding(.vertical, 4)

                HStack(spacing: 16) {
                    Button {
                        editEnglish = phrase.english
                        editJapanese = phrase.japanese
                        editRomaji = phrase.romaji
                        editContext = phrase.context ?? ""
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.themeIndigo)
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
    }

    // MARK: - Edit Sheet

    private func editSheet(_ phrase: Phrase) -> some View {
        NavigationStack {
            Form {
                Section("English") {
                    TextField("English", text: $editEnglish)
                        .font(.rounded(.body))
                }
                Section("Japanese") {
                    TextField("Japanese", text: $editJapanese)
                        .font(.japanese(size: 18))
                }
                Section("Romaji") {
                    TextField("Romaji", text: $editRomaji)
                        .font(.romaji(size: 16))
                }
                Section("Context") {
                    TextField("Context (optional)", text: $editContext)
                        .font(.rounded(.body))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Edit Phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditing = false }
                        .foregroundStyle(.themeTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = Phrase(
                            id: phrase.id,
                            english: editEnglish.trimmingCharacters(in: .whitespaces),
                            japanese: editJapanese.trimmingCharacters(in: .whitespaces),
                            romaji: editRomaji.trimmingCharacters(in: .whitespaces),
                            category: phrase.category,
                            difficulty: phrase.difficulty,
                            context: editContext.isEmpty ? nil : editContext.trimmingCharacters(in: .whitespaces),
                            isUserAdded: true,
                            isFavorite: phrase.isFavorite
                        )
                        phraseManager.updatePhrase(updated)
                        isEditing = false
                    }
                    .foregroundStyle(.themeSakura)
                    .disabled(editEnglish.trimmingCharacters(in: .whitespaces).isEmpty
                              || editJapanese.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
