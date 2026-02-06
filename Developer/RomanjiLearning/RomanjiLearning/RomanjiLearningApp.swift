import SwiftUI

@main
struct RomanjiLearningApp: App {
    @State private var phraseManager = PhraseManager()
    @State private var audioService = AudioService()
    @State private var translationService = TranslationService()
    @State private var progressManager = ProgressManager()
    @State private var srsManager = SRSManager()
    @State private var importExportService = ImportExportService()
    @State private var dictionaryService = DictionaryService()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
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
                .environment(dictionaryService)
                .tint(.themeSakura)
                .onOpenURL { url in
                    importExportService.parseFile(at: url, existingPhrases: phraseManager.phrases)
                }
                .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
