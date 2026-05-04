// SPDX-License-Identifier: GPL-3.0-or-later

import AppKit
import Foundation
import OSLog

private let appLogger = Logger(subsystem: "com.actualwifibars.app", category: "ActualWifiBars")

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let monitor = ConnectionMonitor()
    private let menu = NSMenu()
    private var graphWindow: NSWindow?
    private var latestSnapshot = ConnectionSnapshot(history: [])

    private let statusMenuItem = NSMenuItem(title: "Starting...", action: nil, keyEquivalent: "")
    private let latencyMenuItem = NSMenuItem(title: "Latency: --", action: nil, keyEquivalent: "")
    private let reliabilityMenuItem = NSMenuItem(title: "Reliability: --", action: nil, keyEquivalent: "")
    private let dataMenuItem = NSMenuItem(title: "Data: --", action: nil, keyEquivalent: "")
    private let lastCheckMenuItem = NSMenuItem(title: "Last check: --", action: nil, keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        appLogger.notice("Application did finish launching")
        NSApp.setActivationPolicy(.accessory)
        configureMenu()

        setStatusIcon(named: "wifi", accessibilityDescription: "Actual Wi-Fi Bars", tintColor: .labelColor)
        statusItem.button?.toolTip = "Actual Wi-Fi Bars"
        statusItem.menu = menu
        appLogger.notice("Status item configured. buttonExists=\(self.statusItem.button != nil, privacy: .public)")

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
        dataMenuItem.isEnabled = false
        lastCheckMenuItem.isEnabled = false

        menu.addItem(statusMenuItem)
        menu.addItem(latencyMenuItem)
        menu.addItem(reliabilityMenuItem)
        menu.addItem(dataMenuItem)
        menu.addItem(lastCheckMenuItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Check Now", action: #selector(checkNow), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Show Connectivity Graph", action: #selector(showGraph), keyEquivalent: "g"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Actual Wi-Fi Bars", action: #selector(quit), keyEquivalent: "q"))
    }

    private func render(_ snapshot: ConnectionSnapshot) {
        latestSnapshot = snapshot
        setStatusIcon(named: snapshot.systemSymbolName, accessibilityDescription: snapshot.summary, tintColor: snapshot.tintColor)
        statusItem.button?.toolTip = snapshot.tooltip

        statusMenuItem.title = snapshot.summary
        latencyMenuItem.title = "Latency: \(snapshot.latencyText)"
        reliabilityMenuItem.title = "Reliability: \(snapshot.reliabilityText)"
        dataMenuItem.title = "Data: \(snapshot.dataText)"
        lastCheckMenuItem.title = "Last check: \(snapshot.checkedAtText)"
        (graphWindow?.contentView as? ConnectivityGraphView)?.snapshot = snapshot
        appLogger.info("Rendered status. summary=\(snapshot.summary, privacy: .public) symbol=\(snapshot.systemSymbolName, privacy: .public) latency=\(snapshot.latencyText, privacy: .public) reliability=\(snapshot.reliabilityText, privacy: .public)")
    }

    private func setStatusIcon(named symbolName: String, accessibilityDescription: String, tintColor: NSColor) {
        guard let button = statusItem.button else { return }

        let image = StatusIconRenderer.image(symbolName: symbolName, tintColor: tintColor)
        button.title = ""
        button.image = image
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.contentTintColor = nil
        appLogger.debug("Set custom status icon. symbol=\(symbolName, privacy: .public) imageSize=\(image.size.width, privacy: .public)x\(image.size.height, privacy: .public)")
    }

    @objc private func checkNow() {
        appLogger.notice("Manual check requested")
        monitor.checkNow()
    }

    @objc private func showGraph() {
        appLogger.notice("Show graph requested")
        if let graphWindow {
            graphWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let graphView = ConnectivityGraphView(frame: NSRect(x: 0, y: 0, width: 560, height: 340))
        graphView.snapshot = latestSnapshot

        let window = NSWindow(
            contentRect: graphView.frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Connectivity Over Time"
        window.contentView = graphView
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        graphWindow = window
    }

    @objc private func quit() {
        appLogger.notice("Quit requested")
        monitor.stop()
        NSApp.terminate(nil)
    }
}

enum StatusIconRenderer {
    static func image(symbolName: String, tintColor: NSColor) -> NSImage {
        let size = NSSize(width: 20, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let color = tintColor.usingColorSpace(.deviceRGB) ?? .labelColor
        color.setStroke()
        color.setFill()

        let center = NSPoint(x: 10, y: 2.5)
        drawArc(center: center, radius: 13.2, lineWidth: 1.8)
        drawArc(center: center, radius: 9.2, lineWidth: 1.8)
        drawArc(center: center, radius: 5.2, lineWidth: 1.8)

        NSBezierPath(ovalIn: NSRect(x: 8.3, y: 1.0, width: 3.4, height: 3.4)).fill()

        if symbolName == "wifi.slash" {
            drawSlash(in: size, color: color)
        } else if symbolName == "wifi.exclamationmark" {
            drawExclamation(in: size, color: color)
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private static func drawArc(center: NSPoint, radius: CGFloat, lineWidth: CGFloat) {
        let path = NSBezierPath()
        path.appendArc(
            withCenter: center,
            radius: radius,
            startAngle: 42,
            endAngle: 138,
            clockwise: false
        )
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.stroke()
    }

    private static func drawSlash(in size: NSSize, color: NSColor) {
        color.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 3.5, y: 3))
        path.line(to: NSPoint(x: 16.5, y: 16))
        path.lineWidth = 2
        path.lineCapStyle = .round
        path.stroke()
    }

    private static func drawExclamation(in size: NSSize, color: NSColor) {
        color.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 16, y: 4))
        path.line(to: NSPoint(x: 16, y: 10))
        path.lineWidth = 1.8
        path.lineCapStyle = .round
        path.stroke()

        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: 15, y: 12.2, width: 2, height: 2)).fill()
    }
}

@main
enum ActualWifiBarsApp {
    private static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}

struct ProbeResult {
    let success: Bool
    let latency: TimeInterval?
    let checkedAt: Date
    let bytesSent: Int
    let bytesReceived: Int
}

struct ConnectionSnapshot {
    let history: [ProbeResult]

    private var recent: [ProbeResult] {
        Array(history.suffix(12))
    }

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

    var systemSymbolName: String {
        guard reliability > 0 else { return "wifi.slash" }
        if reliability < 0.65 { return "wifi.exclamationmark" }
        return "wifi"
    }

    var tintColor: NSColor {
        guard reliability > 0 else { return .systemRed }
        guard let latency = medianLatency else { return .labelColor }

        if reliability >= 0.9 && latency < 0.12 { return .systemGreen }
        if reliability >= 0.8 && latency < 0.25 { return .systemBlue }
        if reliability >= 0.65 && latency < 0.50 { return .systemOrange }
        return .systemRed
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

    var dataText: String {
        "\(Self.byteFormatter.string(fromByteCount: Int64(totalBytesSent))) sent, \(Self.byteFormatter.string(fromByteCount: Int64(totalBytesReceived))) received"
    }

    var checkedAtText: String {
        guard let date = history.last?.checkedAt else { return "--" }
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

    var totalBytesSent: Int {
        history.reduce(0) { $0 + $1.bytesSent }
    }

    var totalBytesReceived: Int {
        history.reduce(0) { $0 + $1.bytesReceived }
    }

    var historyForGraph: [ProbeResult] {
        history
    }

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter
    }()
}

final class ConnectionMonitor {
    private let endpoint = URL(string: "https://www.google.com/generate_204")!
    private let probeInterval: TimeInterval = 5
    private let timeout: TimeInterval = 2
    private let historyWindow: TimeInterval = 60 * 60
    private let queue = DispatchQueue(label: "ActualWifiBars.ConnectionMonitor")

    private var timer: DispatchSourceTimer?
    private var history: [ProbeResult] = []
    private var isChecking = false

    var onUpdate: ((ConnectionSnapshot) -> Void)?

    func start() {
        queue.async {
            appLogger.notice("Connection monitor starting")
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
        appLogger.debug("Starting probe")

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
            let result = ProbeResult(
                success: success,
                latency: success ? elapsed : nil,
                checkedAt: Date(),
                bytesSent: Self.estimatedRequestBytes(request),
                bytesReceived: Self.estimatedResponseBytes(response)
            )
            appLogger.info("Probe finished. success=\(success, privacy: .public) status=\(statusCode ?? -1, privacy: .public) elapsedMs=\(Int(elapsed * 1000), privacy: .public) error=\(String(describing: error), privacy: .public)")

            self.queue.async {
                self.isChecking = false
                self.history.append(result)
                let cutoff = Date().addingTimeInterval(-self.historyWindow)
                self.history.removeAll { $0.checkedAt < cutoff }
                self.onUpdate?(ConnectionSnapshot(history: self.history))
            }
        }.resume()
    }

    private static func estimatedRequestBytes(_ request: URLRequest) -> Int {
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path.isEmpty == false ? request.url?.path ?? "/" : "/"
        let query = request.url?.query.map { "?\($0)" } ?? ""
        let host = request.url?.host ?? ""
        var bytes = "\(method) \(path)\(query) HTTP/1.1\r\nHost: \(host)\r\n".utf8.count

        for (field, value) in request.allHTTPHeaderFields ?? [:] {
            bytes += "\(field): \(value)\r\n".utf8.count
        }
        bytes += 2
        return bytes
    }

    private static func estimatedResponseBytes(_ response: URLResponse?) -> Int {
        guard let response = response as? HTTPURLResponse else { return 0 }
        var bytes = "HTTP/1.1 \(response.statusCode)\r\n".utf8.count
        for (field, value) in response.allHeaderFields {
            bytes += "\(field): \(value)\r\n".utf8.count
        }
        bytes += 2
        return bytes
    }
}

final class ConnectivityGraphView: NSView {
    var snapshot = ConnectionSnapshot(history: []) {
        didSet {
            needsDisplay = true
        }
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()

        let bounds = bounds.insetBy(dx: 24, dy: 20)
        drawHeader(in: bounds)

        let graphRect = NSRect(x: bounds.minX, y: bounds.minY + 72, width: bounds.width, height: bounds.height - 102)
        drawGraph(in: graphRect)
        drawFooter(in: bounds)
    }

    private func drawHeader(in rect: NSRect) {
        drawText("Last Hour Connectivity", at: NSPoint(x: rect.minX, y: rect.minY), font: .boldSystemFont(ofSize: 18), color: .labelColor)
        drawText(snapshot.summary, at: NSPoint(x: rect.minX, y: rect.minY + 26), font: .systemFont(ofSize: 13), color: .secondaryLabelColor)
        drawText(snapshot.dataText, at: NSPoint(x: rect.minX, y: rect.minY + 46), font: .systemFont(ofSize: 13), color: .secondaryLabelColor)
    }

    private func drawGraph(in rect: NSRect) {
        NSColor.separatorColor.setStroke()
        let border = NSBezierPath(rect: rect)
        border.lineWidth = 1
        border.stroke()

        guard !snapshot.historyForGraph.isEmpty else {
            drawText("No probes yet", at: NSPoint(x: rect.midX - 38, y: rect.midY - 8), font: .systemFont(ofSize: 13), color: .secondaryLabelColor)
            return
        }

        let now = Date()
        let start = now.addingTimeInterval(-3600)
        let maxLatency: TimeInterval = 1.0
        let samples = snapshot.historyForGraph

        NSColor.systemGreen.withAlphaComponent(0.18).setFill()
        rect.fill()

        let path = NSBezierPath()
        var didMove = false

        for sample in samples {
            let xRatio = max(0, min(1, sample.checkedAt.timeIntervalSince(start) / 3600))
            let x = rect.minX + rect.width * xRatio

            if sample.success, let latency = sample.latency {
                let yRatio = max(0, min(1, latency / maxLatency))
                let y = rect.maxY - rect.height * yRatio
                let point = NSPoint(x: x, y: y)
                if didMove {
                    path.line(to: point)
                } else {
                    path.move(to: point)
                    didMove = true
                }
                drawDot(at: point, color: .systemBlue, radius: 2.5)
            } else {
                drawFailureMarker(x: x, rect: rect)
                didMove = false
            }
        }

        NSColor.systemBlue.setStroke()
        path.lineWidth = 2
        path.stroke()

        drawText("now", at: NSPoint(x: rect.maxX - 25, y: rect.maxY + 6), font: .systemFont(ofSize: 11), color: .tertiaryLabelColor)
        drawText("-1h", at: NSPoint(x: rect.minX, y: rect.maxY + 6), font: .systemFont(ofSize: 11), color: .tertiaryLabelColor)
        drawText("1s", at: NSPoint(x: rect.minX + 6, y: rect.minY + 4), font: .systemFont(ofSize: 11), color: .tertiaryLabelColor)
        drawText("0ms", at: NSPoint(x: rect.minX + 6, y: rect.maxY - 18), font: .systemFont(ofSize: 11), color: .tertiaryLabelColor)
    }

    private func drawFooter(in rect: NSRect) {
        let y = rect.maxY - 18
        let probes = snapshot.historyForGraph.count
        drawText("\(probes) probes, \(snapshot.reliabilityText)", at: NSPoint(x: rect.minX, y: y), font: .systemFont(ofSize: 12), color: .secondaryLabelColor)
    }

    private func drawDot(at point: NSPoint, color: NSColor, radius: CGFloat) {
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)).fill()
    }

    private func drawFailureMarker(x: CGFloat, rect: NSRect) {
        NSColor.systemRed.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: x, y: rect.minY))
        path.line(to: NSPoint(x: x, y: rect.maxY))
        path.lineWidth = 2
        path.stroke()
    }

    private func drawText(_ text: String, at point: NSPoint, font: NSFont, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        text.draw(at: point, withAttributes: attributes)
    }
}
