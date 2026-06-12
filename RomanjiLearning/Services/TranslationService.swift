import Foundation
import Translation

@Observable
class TranslationService {
    var sourceText: String = ""
    var translatedText: String = ""
    var isPresented: Bool = false
    var isTranslating: Bool = false
    var errorMessage: String?

    private var _configuration: Any?

    func requestTranslation(of text: String) {
        sourceText = text
        translatedText = ""
        errorMessage = nil

        if #available(iOS 18, *) {
            triggerSessionTranslation()
        } else {
            isPresented = true
        }
    }

    func handlePresentationResult(_ text: String) {
        translatedText = text
        isPresented = false
    }

    @available(iOS 18, *)
    var configuration: TranslationSession.Configuration? {
        get { _configuration as? TranslationSession.Configuration }
        set { _configuration = newValue }
    }

    @available(iOS 18, *)
    private func triggerSessionTranslation() {
        configuration = .init(
            source: Locale.Language(identifier: "en"),
            target: Locale.Language(identifier: "ja")
        )
    }

    @available(iOS 18, *)
    @MainActor
    func performTranslation(using session: TranslationSession) async {
        guard !sourceText.isEmpty else { return }
        isTranslating = true
        do {
            let response = try await session.translate(sourceText)
            translatedText = response.targetText
        } catch {
            errorMessage = error.localizedDescription
        }
        isTranslating = false
    }

    func reset() {
        sourceText = ""
        translatedText = ""
        isPresented = false
        isTranslating = false
        errorMessage = nil
        _configuration = nil
    }
}
