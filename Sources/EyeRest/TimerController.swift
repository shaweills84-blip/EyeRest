import SwiftUI

class TimerController: ObservableObject {
    enum Phase: String {
        case idle = "未开始"
        case work = "工作中"
        case rest = "休息中"
    }

    @Published var phase: Phase = .idle
    @Published var remainingSeconds: Int = 0
    @Published var workSeconds: Int = 900 {
        didSet { save() }
    }
    @Published var restSeconds: Int = 20 {
        didSet { save() }
    }

    private var timer: DispatchSourceTimer?
    var onPhaseChange: ((Phase) -> Void)?
    var onTick: ((Int) -> Void)?

    var isRunning: Bool { phase != .idle }

    init() {
        load()
    }

    func start() {
        save()
        phase = .work
        remainingSeconds = workSeconds
        onPhaseChange?(.work)
        startTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        phase = .idle
        remainingSeconds = 0
        onPhaseChange?(.idle)
    }

    func skipRest() {
        guard phase == .rest else { return }
        remainingSeconds = workSeconds
        phase = .work
        onPhaseChange?(.work)
    }

    private func startTimer() {
        timer?.cancel()
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now() + 1.0, repeating: 1.0)
        t.setEventHandler { [weak self] in
            self?.tick()
        }
        t.resume()
        timer = t
    }

    private func tick() {
        remainingSeconds -= 1
        onTick?(remainingSeconds)

        guard remainingSeconds <= 0 else { return }

        switch phase {
        case .work:
            phase = .rest
            remainingSeconds = restSeconds
            onPhaseChange?(.rest)
        case .rest:
            phase = .work
            remainingSeconds = workSeconds
            onPhaseChange?(.work)
        case .idle:
            break
        }
    }

    private func load() {
        let defaults = UserDefaults.standard
        let w = defaults.integer(forKey: "workSeconds")
        let r = defaults.integer(forKey: "restSeconds")
        workSeconds = (w >= 20) ? w : 900
        restSeconds = (r >= 5) ? r : 20
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(workSeconds, forKey: "workSeconds")
        defaults.set(restSeconds, forKey: "restSeconds")
    }
}
