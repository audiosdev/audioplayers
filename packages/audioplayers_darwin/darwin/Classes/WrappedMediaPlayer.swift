import AVFoundation

private let defaultPlaybackRate: Double = 1.0
private let defaultVolume: Float = 1.0
private let defaultLooping: Bool = false

typealias Completer = () -> Void
typealias CompleterError = () -> Void

class WrappedMediaPlayer {
    private(set) var eventHandler: AudioPlayersStreamHandler
    private(set) var isPlaying: Bool
    var looping: Bool

    private var reference: SwiftAudioplayersDarwinPlugin
    private var player: AVAudioPlayer?
    private var playbackRate: Double
    private var volume: Float
    private var url: String?

    init(
        reference: SwiftAudioplayersDarwinPlugin,
        eventHandler: AudioPlayersStreamHandler,
        playbackRate: Double = defaultPlaybackRate,
        volume: Float = defaultVolume,
        looping: Bool = defaultLooping,
        url: String? = nil
    ) {
        self.reference = reference
        self.eventHandler = eventHandler
        self.isPlaying = false
        self.playbackRate = playbackRate
        self.volume = volume
        self.looping = looping
        self.url = url
    }

    func setSourceUrl(
        url: String,
        isLocal: Bool,
        completer: Completer? = nil,
        completerError: CompleterError? = nil
    ) {
        if self.url != url {
            reset()
            self.url = url
            do {
                let player = try AVAudioPlayer(contentsOf: URL(string: url)!)
                player.delegate = self
                player.enableRate = true
                self.player = player
                self.player?.prepareToPlay()
                self.player?.volume = volume
                self.player?.rate = Float(playbackRate)
                if looping {
                    self.player?.numberOfLoops = -1
                }
                completer?()
            } catch {
                completerError?()
            }
        } else {
            completer?()
        }
    }

    func getDuration() -> Int? {
        return Int(player?.duration ?? 0)
    }

    func getCurrentPosition() -> Int? {
        return Int(player?.currentTime ?? 0)
    }

    func pause() {
        isPlaying = false
        player?.pause()
    }

    func resume() {
        isPlaying = true
        player?.play()
        updateDuration()
    }

    func setVolume(volume: Float) {
        self.volume = volume
        player?.volume = volume
    }

    func setPlaybackRate(playbackRate: Double) {
        self.playbackRate = playbackRate
        player?.rate = Float(playbackRate)
    }

    func seek(time: TimeInterval, completer: Completer? = nil) {
        player?.currentTime = time
        completer?()
    }

    func stop(completer: Completer? = nil) {
        pause()
        seek(time: 0)
        completer?()
    }

    func release(completer: Completer? = nil) {
        stop()
        reset()
        url = nil
        completer?()
    }

    func dispose(completer: Completer? = nil) {
        release()
        completer?()
    }

    private func updateDuration() {
        eventHandler.onDuration(millis: Int(player?.duration ?? 0))
    }

    private func reset() {
        player?.stop()
        player = nil
    }
}

extension WrappedMediaPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if looping {
            player.currentTime = 0
            player.play()
        } else {
            isPlaying = false
            eventHandler.onComplete()
        }
    }
}
