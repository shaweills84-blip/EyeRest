import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var timerController: TimerController!
    private var overlayController: OverlayController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        timerController = TimerController()
        overlayController = OverlayController()

        timerController.onPhaseChange = { [weak self] phase in
            guard let self else { return }
            self.updateStatusIcon()
            switch phase {
            case .rest:
                self.overlayController.show(duration: self.timerController.restSeconds)
            case .work:
                self.overlayController.hide()
            case .idle:
                self.overlayController.hide()
            }
        }

        timerController.onTick = { [weak self] seconds in
            guard let self, self.timerController.phase == .rest else { return }
            self.overlayController.updateCountdown(seconds)
        }

        overlayController.onSkip = { [weak self] in
            DispatchQueue.main.async {
                self?.timerController.skipRest()
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        setupMenuBar()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = statusIcon(for: .idle)
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 320)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(timer: timerController)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        button.image = statusIcon(for: timerController.phase)
    }

    private func statusIcon(for phase: TimerController.Phase) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.isTemplate = true
        image.lockFocus()

        switch phase {
        case .idle:
            let p = NSBezierPath(ovalIn: NSRect(x: 3, y: 3, width: 12, height: 12))
            p.lineWidth = 1.5
            p.stroke()
        case .work:
            NSBezierPath(ovalIn: NSRect(x: 3, y: 3, width: 12, height: 12)).fill()
        case .rest:
            NSBezierPath(ovalIn: NSRect(x: 6, y: 6, width: 6, height: 6)).fill()
        }

        image.unlockFocus()
        return image
    }

    @objc private func screenParametersChanged() {
        if timerController.phase == .rest {
            overlayController.show(duration: timerController.remainingSeconds)
        }
    }
}
