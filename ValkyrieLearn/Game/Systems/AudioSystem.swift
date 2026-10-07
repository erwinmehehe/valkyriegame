import AVFoundation

@MainActor final class AudioSystem {
    enum Channel: String { case music, ambience, effect, narration, instructional }

    var enabled = true {
        didSet {
            if enabled {
                activateSessionIfNeeded()
            } else {
                stop()
            }
        }
    }

    private var players: [Channel: AVAudioPlayer] = [:]
    private var playerNames: [Channel: String] = [:]
    private var effectPlayers: [AVAudioPlayer] = []
    private let maxConcurrentEffects = 4
    private var urlCache: [String: URL] = [:]
    private var sessionActive = false
    private var interruptionObserver: NSObjectProtocol?

    init() {
        activateSessionIfNeeded()
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.sessionActive = false
                self?.stop()
            }
        }
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
    }

    func play(_ name: String, channel: Channel = .effect, looping: Bool = false) {
        guard enabled, let url = soundURL(named: name) else { return }
        activateSessionIfNeeded()

        let loopCount = looping ? -1 : 0

        if channel == .effect {
            playEffect(url: url, loopCount: loopCount)
            return
        }

        if let player = players[channel],
           playerNames[channel] == name,
           player.numberOfLoops == loopCount {
            player.currentTime = 0
            player.play()
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.2
            player.numberOfLoops = loopCount
            player.prepareToPlay()

            players[channel]?.stop()
            players[channel] = player
            playerNames[channel] = name
            player.play()
        } catch {
            // Audio is optional; gameplay remains available offline.
        }
    }

    func stop(channel: Channel) {
        if channel == .effect {
            effectPlayers.forEach { $0.stop() }
            effectPlayers.removeAll()
            return
        }

        players[channel]?.stop()
        players.removeValue(forKey: channel)
        playerNames.removeValue(forKey: channel)
    }

    func stop() {
        players.values.forEach { $0.stop() }
        effectPlayers.forEach { $0.stop() }
        players.removeAll()
        playerNames.removeAll()
        effectPlayers.removeAll()
    }

    private func playEffect(url: URL, loopCount: Int) {
        effectPlayers.removeAll { !$0.isPlaying }

        if effectPlayers.count >= maxConcurrentEffects {
            effectPlayers.removeFirst().stop()
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.3
            player.numberOfLoops = loopCount
            player.prepareToPlay()
            effectPlayers.append(player)
            player.play()
        } catch {
            // Effects are optional; never block gameplay on audio.
        }
    }

    private func activateSessionIfNeeded() {
        guard enabled, !sessionActive else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            sessionActive = true
        } catch {
            sessionActive = false
        }
    }

    private func soundURL(named name: String) -> URL? {
        if let cached = urlCache[name] { return cached }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return nil }
        urlCache[name] = url
        return url
    }
}
