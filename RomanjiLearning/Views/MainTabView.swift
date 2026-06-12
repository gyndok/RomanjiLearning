import SwiftUI

struct MainTabView: View {
    @Environment(SRSManager.self) private var srsManager
    @Environment(PhraseManager.self) private var phraseManager

    var body: some View {
        TabView {
            FlashcardView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .badge(srsManager.getDueCount(from: phraseManager.phrases))

            QuizView()
                .tabItem {
                    Label("Quiz", systemImage: "questionmark.circle.fill")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            AddPhraseView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
