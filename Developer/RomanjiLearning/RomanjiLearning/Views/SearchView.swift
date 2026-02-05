import SwiftUI

struct SearchView: View {
    @Environment(PhraseManager.self) private var phraseManager

    @State private var searchText = ""

    private var results: [Phrase] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return []
        }
        return phraseManager.search(query: searchText)
    }

    private func categoryColor(for category: String) -> Color {
        let hash = abs(category.hashValue)
        let colors: [Color] = [.themeIndigo, .themeSakura, .themeVermillion, .themeMatcha]
        return colors[hash % colors.count]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()

                Group {
                    if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundStyle(.themeTextSecondary.opacity(0.4))
                            Text("Search Phrases")
                                .font(.rounded(.title3, weight: .semibold))
                                .foregroundStyle(.themeText)
                            Text("Search by English, Japanese, or romaji.")
                                .font(.rounded(.subheadline))
                                .foregroundStyle(.themeTextSecondary)
                        }
                    } else if results.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        List(results) { phrase in
                            NavigationLink(value: phrase) {
                                phraseRow(phrase)
                            }
                            .listRowBackground(Color.themeCardBg)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "English, Japanese, or romaji")
            .navigationDestination(for: Phrase.self) { phrase in
                PhraseDetailView(phraseID: phrase.id)
            }
        }
    }

    private func phraseRow(_ phrase: Phrase) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(categoryColor(for: phrase.category))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(phrase.english)
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(.themeText)
                Text(phrase.japanese)
                    .font(.japanese(size: 16))
                    .foregroundStyle(.themeTextSecondary)
                Text(phrase.romaji)
                    .font(.romaji(size: 13))
                    .foregroundStyle(.themeTextSecondary.opacity(0.7))
            }

            Spacer()

            if phrase.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.themeSakura)
            }
        }
    }
}
