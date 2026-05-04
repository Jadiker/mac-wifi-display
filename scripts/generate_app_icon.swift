import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let iconSizes: [(name: String, points: CGFloat, scale: CGFloat)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2)
]

for iconSize in iconSizes {
    let pixelSize = Int(iconSize.points * iconSize.scale)
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))

    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize).fill()

    drawWifiIcon(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize))

    image.unlockFocus()

    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "ActualWifiBarsIconGenerator", code: 1)
    }

    try pngData.write(to: outputDirectory.appendingPathComponent(iconSize.name))
}

private func drawWifiIcon(in rect: NSRect) {
    let scale = min(rect.width, rect.height) / 1024
    let center = NSPoint(x: rect.midX, y: rect.minY + 230 * scale)
    let color = NSColor.systemGreen

    color.setStroke()
    color.setFill()

    drawArc(center: center, radius: 410 * scale, lineWidth: 94 * scale)
    drawArc(center: center, radius: 285 * scale, lineWidth: 94 * scale)
    drawArc(center: center, radius: 160 * scale, lineWidth: 94 * scale)

    NSBezierPath(ovalIn: NSRect(
        x: center.x - 62 * scale,
        y: center.y - 62 * scale,
        width: 124 * scale,
        height: 124 * scale
    )).fill()
}

private func drawArc(center: NSPoint, radius: CGFloat, lineWidth: CGFloat) {
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
