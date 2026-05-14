import Foundation
import AVFoundation
import Combine

// MARK: - Speech Manager
// This class handles Text-to-Speech (TTS) for the app, providing accessibility support.
enum SpeechState {
    case speaking
    case paused
    case stopped
}

class SpeechManager: NSObject, ObservableObject {
    static let shared = SpeechManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var state: SpeechState = .stopped
    @Published var isSpeaking = false // Kept for backward compatibility
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Configure audio session to play even on silent mode
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("SpeechManager: Failed to set up audio session: \(error)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.1
        
        synthesizer.speak(utterance)
        state = .speaking
        isSpeaking = true
    }
    
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
            state = .paused
        }
    }
    
    func resume() {
        if state == .paused {
            synthesizer.continueSpeaking()
            state = .speaking
        }
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        state = .stopped
        isSpeaking = false
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        state = .stopped
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        state = .stopped
        isSpeaking = false
    }
}
