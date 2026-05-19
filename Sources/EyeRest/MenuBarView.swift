import SwiftUI
import ServiceManagement

struct MenuBarView: View {
    @ObservedObject var timer: TimerController

    var body: some View {
        VStack(spacing: 14) {
            Text("护眼休息")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                Stepper("工作时长: \(workTimeDisplay)",
                        value: $timer.workSeconds,
                        in: 20...7200, step: 10)
                Stepper("休息时长: \(timer.restSeconds) 秒",
                        value: $timer.restSeconds,
                        in: 5...300, step: 5)
            }
            .disabled(timer.isRunning)
            .opacity(timer.isRunning ? 0.5 : 1.0)

            Divider()

            if timer.isRunning {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(timer.phase == .work ? Color.blue : Color.green)
                            .frame(width: 6, height: 6)
                        Text(timer.phase == .work ? "工作中" : "休息中")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(timeString(from: timer.remainingSeconds))
                        .font(.system(.title2, design: .monospaced))
                }
            }

            Toggle(isOn: isEnabled) {
                Text("启用")
                    .fontWeight(.medium)
            }
            .toggleStyle(.switch)
            .controlSize(.large)

            Divider()

            Toggle(isOn: $launchAtLogin) {
                Text("开机自启")
                    .font(.caption)
            }
            .toggleStyle(.switch)
            .onChange(of: launchAtLogin) { newValue in
                setLaunchAtLogin(newValue)
            }
        }
        .padding()
        .frame(width: 250)
        .onAppear {
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }

    @State private var launchAtLogin = false

    private func setLaunchAtLogin(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = false
        }
    }

    private var workTimeDisplay: String {
        let m = timer.workSeconds / 60
        let s = timer.workSeconds % 60
        if s == 0 {
            return "\(m) 分钟"
        }
        return "\(m)分\(s)秒"
    }

    private var isEnabled: Binding<Bool> {
        Binding(
            get: { timer.isRunning },
            set: { newValue in
                if newValue { timer.start() } else { timer.stop() }
            }
        )
    }

    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
