import AVFoundation

@MainActor final class AudioSystem {
    enum Channel: String { case music, ambience, effect, narration, instructional }
    var enabled = true { didSet { if !enabled { stop() } } }
    private var players: [Channel: AVAudioPlayer] = [:]
    private var interruptionObserver: NSObjectProtocol?
    init() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] _ in Task { @MainActor in self?.stop() } }
    }
    deinit { if let interruptionObserver { NotificationCenter.default.removeObserver(interruptionObserver) } }
    func play(_ name: String, channel: Channel = .effect, looping: Bool = false) {
        guard enabled, let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = channel == .effect ? 0.3 : 0.2
            player.numberOfLoops = looping ? -1 : 0
            players[channel]?.stop(); players[channel] = player; player.play()
        } catch { /* Audio is optional; gameplay remains available offline. */ }
    }
    func stop() { players.values.forEach { $0.stop() }; players.removeAll() }
}
