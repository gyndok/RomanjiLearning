import SwiftUI

@main
struct RomanjiLearningApp: App {
    @State private var phraseManager = PhraseManager()
    @State private var audioService = AudioService()
    @State private var translationService = TranslationService()
    @State private var progressManager = ProgressManager()
    @State private var srsManager = SRSManager()
    @State private var importExportService = ImportExportService()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environment(phraseManager)
            .environment(audioService)
            .environment(translationService)
            .environment(progressManager)
            .environment(srsManager)
            .environment(importExportService)
            .tint(.themeSakura)
            .onOpenURL { url in
                importExportService.parseFile(at: url, existingPhrases: phraseManager.phrases)
            }
        }
    }
}
