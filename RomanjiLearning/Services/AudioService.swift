import AVFoundation

@Observable
class AudioService {
    private let synthesizer = AVSpeechSynthesizer()
    var useSlowSpeed: Bool = true

    var currentRate: Float {
        useSlowSpeed ? AVSpeechUtteranceDefaultSpeechRate * 0.6 : AVSpeechUtteranceDefaultSpeechRate
    }

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)

        // Ensure audio session is active before speaking
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = currentRate
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
