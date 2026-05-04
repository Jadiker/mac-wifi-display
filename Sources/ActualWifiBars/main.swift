import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let monitor = ConnectionMonitor()
    private let menu = NSMenu()

    private let statusMenuItem = NSMenuItem(title: "Starting...", action: nil, keyEquivalent: "")
    private let latencyMenuItem = NSMenuItem(title: "Latency: --", action: nil, keyEquivalent: "")
    private let reliabilityMenuItem = NSMenuItem(title: "Reliability: --", action: nil, keyEquivalent: "")
    private let lastCheckMenuItem = NSMenuItem(title: "Last check: --", action: nil, keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenu()

        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        statusItem.button?.title = "Net --"
        statusItem.button?.toolTip = "Actual Wi-Fi Bars"
        statusItem.menu = menu

        monitor.onUpdate = { [weak self] snapshot in
            DispatchQueue.main.async {
                self?.render(snapshot)
            }
        }
        monitor.start()
    }

    private func configureMenu() {
        statusMenuItem.isEnabled = false
        latencyMenuItem.isEnabled = false
        reliabilityMenuItem.isEnabled = false
        lastCheckMenuItem.isEnabled = false

        menu.addItem(statusMenuItem)
        menu.addItem(latencyMenuItem)
        menu.addItem(reliabilityMenuItem)
        menu.addItem(lastCheckMenuItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Check Now", action: #selector(checkNow), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Actual Wi-Fi Bars", action: #selector(quit), keyEquivalent: "q"))
    }

    private func render(_ snapshot: ConnectionSnapshot) {
        let symbol = snapshot.symbol
        statusItem.button?.title = "Net \(symbol)"
        statusItem.button?.toolTip = snapshot.tooltip

        statusMenuItem.title = snapshot.summary
        latencyMenuItem.title = "Latency: \(snapshot.latencyText)"
        reliabilityMenuItem.title = "Reliability: \(snapshot.reliabilityText)"
        lastCheckMenuItem.title = "Last check: \(snapshot.checkedAtText)"
    }

    @objc private func checkNow() {
        monitor.checkNow()
    }

    @objc private func quit() {
        monitor.stop()
        NSApp.terminate(nil)
    }
}

@main
enum ActualWifiBarsApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

struct ProbeResult {
    let success: Bool
    let latency: TimeInterval?
    let checkedAt: Date
}

struct ConnectionSnapshot {
    let recent: [ProbeResult]

    private var successes: [ProbeResult] {
        recent.filter(\.success)
    }

    private var medianLatency: TimeInterval? {
        let values = successes.compactMap(\.latency).sorted()
        guard !values.isEmpty else { return nil }
        return values[values.count / 2]
    }

    private var reliability: Double {
        guard !recent.isEmpty else { return 0 }
        return Double(successes.count) / Double(recent.count)
    }

    var symbol: String {
        guard reliability > 0 else { return "x" }
        guard let latency = medianLatency else { return "?" }

        if reliability >= 0.9 && latency < 0.12 { return "▰▰▰▰" }
        if reliability >= 0.8 && latency < 0.25 { return "▰▰▰▱" }
        if reliability >= 0.65 && latency < 0.50 { return "▰▰▱▱" }
        return "▰▱▱▱"
    }

    var summary: String {
        guard reliability > 0 else { return "Offline or blocked" }
        guard let latency = medianLatency else { return "Checking..." }

        if reliability >= 0.9 && latency < 0.12 { return "Excellent connection" }
        if reliability >= 0.8 && latency < 0.25 { return "Good connection" }
        if reliability >= 0.65 && latency < 0.50 { return "Weak connection" }
        return "Unstable connection"
    }

    var latencyText: String {
        guard let medianLatency else { return "--" }
        return "\(Int(medianLatency * 1000)) ms median"
    }

    var reliabilityText: String {
        "\(Int((reliability * 100).rounded()))% over last \(recent.count)"
    }

    var checkedAtText: String {
        guard let date = recent.last?.checkedAt else { return "--" }
        return Self.timeFormatter.string(from: date)
    }

    var tooltip: String {
        "\(summary)\n\(latencyText), \(reliabilityText)"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()
}

final class ConnectionMonitor {
    private let endpoint = URL(string: "https://www.google.com/generate_204")!
    private let probeInterval: TimeInterval = 5
    private let timeout: TimeInterval = 2
    private let historyLimit = 12
    private let queue = DispatchQueue(label: "ActualWifiBars.ConnectionMonitor")

    private var timer: DispatchSourceTimer?
    private var recent: [ProbeResult] = []
    private var isChecking = false

    var onUpdate: ((ConnectionSnapshot) -> Void)?

    func start() {
        queue.async {
            self.scheduleTimer()
            self.performProbe()
        }
    }

    func stop() {
        queue.async {
            self.timer?.cancel()
            self.timer = nil
        }
    }

    func checkNow() {
        queue.async {
            self.performProbe()
        }
    }

    private func scheduleTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + probeInterval, repeating: probeInterval)
        timer.setEventHandler { [weak self] in
            self?.performProbe()
        }
        timer.resume()
        self.timer = timer
    }

    private func performProbe() {
        guard !isChecking else { return }
        isChecking = true

        var request = URLRequest(url: endpoint)
        request.httpMethod = "HEAD"
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("ActualWifiBars/1.0", forHTTPHeaderField: "User-Agent")

        let startedAt = DispatchTime.now()
        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            guard let self else { return }

            let elapsed = Double(DispatchTime.now().uptimeNanoseconds - startedAt.uptimeNanoseconds) / 1_000_000_000
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            let success = error == nil && statusCode.map { 200..<400 ~= $0 } == true
            let result = ProbeResult(success: success, latency: success ? elapsed : nil, checkedAt: Date())

            self.queue.async {
                self.isChecking = false
                self.recent.append(result)
                if self.recent.count > self.historyLimit {
                    self.recent.removeFirst(self.recent.count - self.historyLimit)
                }
                self.onUpdate?(ConnectionSnapshot(recent: self.recent))
            }
        }.resume()
    }
}
