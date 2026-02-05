import AVFoundation

@Observable
class AudioService {
    private let synthesizer = AVSpeechSynthesizer()
    var useSlowSpeed: Bool = true

    var currentRate: Float {
        useSlowSpeed ? AVSpeechUtteranceDefaultSpeechRate * 0.6 : AVSpeechUtteranceDefaultSpeechRate
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)

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
