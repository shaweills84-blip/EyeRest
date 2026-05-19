import Cocoa

class OverlayController {
    private var overlayWindows: [NSWindow] = []
    private var labels: [NSTextField] = []
    private var skipButtons: [NSButton] = []
    private var built = false

    var onSkip: (() -> Void)?

    func show(duration: Int) {
        if NSScreen.screens.count != overlayWindows.count {
            rebuild()
        }

        for (i, screen) in NSScreen.screens.enumerated() {
            guard i < overlayWindows.count else { break }
            let window = overlayWindows[i]
            window.setFrame(screen.frame, display: true)
            window.orderFront(nil)
        }
        updateCountdown(duration)
    }

    private func rebuild() {
        for window in overlayWindows {
            window.close()
        }
        overlayWindows.removeAll()
        labels.removeAll()
        skipButtons.removeAll()
        built = false
        buildIfNeeded()
    }

    func updateCountdown(_ seconds: Int) {
        let minutes = seconds / 60
        let secs = seconds % 60
        let text = String(format: "%02d:%02d", minutes, secs)
        for label in labels {
            label.stringValue = text
        }
    }

    func hide() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
    }

    @objc private func skipPressed() {
        onSkip?()
    }

    private func buildIfNeeded() {
        guard !built else { return }
        built = true

        for screen in NSScreen.screens {
            let frame = screen.frame

            // 200 sits above popUpMenu (101) and overlay (102), below screen saver (1000)
            let level = 200
            let window = NSWindow(
                contentRect: frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = NSWindow.Level(rawValue: level)
            window.backgroundColor = .black
            window.isOpaque = true
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.ignoresMouseEvents = false

            let containerView = NSView(frame: NSRect(origin: .zero, size: frame.size))
            containerView.wantsLayer = true
            containerView.layer?.backgroundColor = NSColor.black.cgColor

            let label = NSTextField(labelWithString: "")
            label.font = NSFont.monospacedDigitSystemFont(ofSize: 96, weight: .thin)
            label.textColor = NSColor(white: 0.25, alpha: 1.0)
            label.alignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])

            let skipButton = NSButton(title: "跳过休息", target: self, action: #selector(skipPressed))
            skipButton.isBordered = false
            skipButton.font = NSFont.systemFont(ofSize: 11)
            skipButton.attributedTitle = NSAttributedString(
                string: "跳过休息",
                attributes: [.foregroundColor: NSColor(white: 0.15, alpha: 1.0)]
            )
            skipButton.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(skipButton)

            NSLayoutConstraint.activate([
                skipButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                skipButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -40)
            ])

            window.contentView = containerView
            overlayWindows.append(window)
            labels.append(label)
            skipButtons.append(skipButton)
        }
    }
}
