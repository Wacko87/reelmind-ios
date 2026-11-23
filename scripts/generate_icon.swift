import Cocoa

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else {
    exit(1)
}

// 1. Background Gradient (Deep Midnight to Royal Violet)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bgColors = [
    NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.12, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.12, green: 0.08, blue: 0.24, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.20, green: 0.10, blue: 0.38, alpha: 1.0).cgColor
] as CFArray

let bgLocations: [CGFloat] = [0.0, 0.5, 1.0]
if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
    context.drawLinearGradient(
        bgGradient,
        start: CGPoint(x: 0, y: 1024),
        end: CGPoint(x: 1024, y: 0),
        options: []
    )
}

// 2. Central Ambient Glow Circle
context.saveGState()
let glowColors = [
    NSColor(calibratedRed: 0.65, green: 0.30, blue: 0.95, alpha: 0.40).cgColor,
    NSColor(calibratedRed: 0.40, green: 0.20, blue: 0.90, alpha: 0.15).cgColor,
    NSColor(calibratedRed: 0.10, green: 0.05, blue: 0.30, alpha: 0.0).cgColor
] as CFArray
let glowLocations: [CGFloat] = [0.0, 0.6, 1.0]
if let radialGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: glowLocations) {
    context.drawRadialGradient(
        radialGradient,
        startCenter: CGPoint(x: 512, y: 512),
        startRadius: 50,
        endCenter: CGPoint(x: 512, y: 512),
        endRadius: 420,
        options: []
    )
}
context.restoreGState()

// 3. Inner Card / Badge with rounded corner
let cardRect = CGRect(x: 160, y: 160, width: 704, height: 704)
let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 160, yRadius: 160)

context.saveGState()
context.setShadow(
    offset: CGSize(width: 0, height: -20),
    blur: 40,
    color: NSColor(calibratedRed: 0.55, green: 0.25, blue: 0.95, alpha: 0.45).cgColor
)
NSColor(calibratedRed: 0.10, green: 0.08, blue: 0.20, alpha: 0.85).setFill()
cardPath.fill()
context.restoreGState()

// Inner stroke with subtle gradient border
cardPath.lineWidth = 4
NSColor(calibratedRed: 0.70, green: 0.40, blue: 1.0, alpha: 0.4).setStroke()
cardPath.stroke()

// 4. Central Emblem: SF Symbol "brain.head.profile" or "sparkles"
let pointSize: CGFloat = 340
let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
if let brainSymbol = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
    let symbolSize = brainSymbol.size
    let symbolRect = CGRect(
        x: (1024 - symbolSize.width) / 2,
        y: (1024 - symbolSize.height) / 2 + 10,
        width: symbolSize.width,
        height: symbolSize.height
    )

    // Draw symbol tinted with gradient
    context.saveGState()
    context.clip(to: symbolRect, mask: brainSymbol.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
    
    let iconColors = [
        NSColor(calibratedRed: 0.40, green: 0.80, blue: 1.0, alpha: 1.0).cgColor, // Cyan
        NSColor(calibratedRed: 0.75, green: 0.40, blue: 1.0, alpha: 1.0).cgColor, // Violet
        NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.75, alpha: 1.0).cgColor  // Magenta
    ] as CFArray
    let iconLocations: [CGFloat] = [0.0, 0.5, 1.0]
    if let iconGradient = CGGradient(colorsSpace: colorSpace, colors: iconColors, locations: iconLocations) {
        context.drawLinearGradient(
            iconGradient,
            start: CGPoint(x: 0, y: 1024),
            end: CGPoint(x: 1024, y: 0),
            options: []
        )
    }
    context.restoreGState()
}

// 5. Sparkle accent in the top right of the badge
let sparkleConfig = NSImage.SymbolConfiguration(pointSize: 110, weight: .bold)
if let sparkle = NSImage(systemSymbolName: "sparkle", accessibilityDescription: nil)?.withSymbolConfiguration(sparkleConfig) {
    let sparkleSize = sparkle.size
    let sparkleRect = CGRect(
        x: 680,
        y: 680,
        width: sparkleSize.width,
        height: sparkleSize.height
    )
    context.saveGState()
    context.setShadow(
        offset: .zero,
        blur: 20,
        color: NSColor(calibratedRed: 0.4, green: 0.85, blue: 1.0, alpha: 0.8).cgColor
    )
    context.clip(to: sparkleRect, mask: sparkle.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
    NSColor(calibratedRed: 0.6, green: 0.95, blue: 1.0, alpha: 1.0).setFill()
    context.fill(sparkleRect)
    context.restoreGState()
}

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Error encoding PNG")
    exit(1)
}

let outputPath = "/Users/wacko87/Desktop/Creacion Apps en Xcode/ReelMind/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
    print("✅ AppIcon-1024.png generated successfully at \(outputPath)")
} catch {
    print("Error saving PNG: \(error)")
    exit(1)
}
