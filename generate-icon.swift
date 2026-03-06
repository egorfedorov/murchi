import AppKit
import Foundation

// Generate Murchi app icon — pixel art cat face on gradient background
// Outputs .icns file for macOS app bundle

func generateIcon() {
    let sizes: [(Int, String)] = [
        (1024, "icon_512x512@2x"),
        (512, "icon_512x512"),
        (512, "icon_256x256@2x"),
        (256, "icon_256x256"),
        (256, "icon_128x128@2x"),
        (128, "icon_128x128"),
        (64, "icon_32x32@2x"),
        (32, "icon_32x32"),
        (32, "icon_16x16@2x"),
        (16, "icon_16x16"),
    ]

    // Create iconset directory
    let dir = FileManager.default.currentDirectoryPath
    let iconsetPath = dir + "/AppIcon.iconset"
    try? FileManager.default.removeItem(atPath: iconsetPath)
    try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

    for (size, name) in sizes {
        let image = renderIcon(size: size)
        let tiff = image.tiffRepresentation!
        let bitmap = NSBitmapImageRep(data: tiff)!
        let png = bitmap.representation(using: .png, properties: [:])!
        try! png.write(to: URL(fileURLWithPath: iconsetPath + "/\(name).png"))
    }

    print("Generated iconset at \(iconsetPath)")
    print("Converting to .icns...")

    // Use iconutil to convert
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconsetPath, "-o", dir + "/AppIcon.icns"]
    try! process.run()
    process.waitUntilExit()

    // Clean up iconset
    try? FileManager.default.removeItem(atPath: iconsetPath)

    print("Created AppIcon.icns")
}

func renderIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let s = CGFloat(size)

    // Background — rounded square with gradient
    let bgRect = NSRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.22
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient background — soft purple to blue
    let gradient = NSGradient(colors: [
        NSColor(red: 0.35, green: 0.25, blue: 0.65, alpha: 1.0),  // deep purple
        NSColor(red: 0.25, green: 0.35, blue: 0.70, alpha: 1.0),  // blue-purple
        NSColor(red: 0.20, green: 0.45, blue: 0.75, alpha: 1.0),  // soft blue
    ])!
    gradient.draw(in: bgPath, angle: -45)

    // Subtle inner glow
    let innerGlow = NSBezierPath(roundedRect: bgRect.insetBy(dx: s * 0.02, dy: s * 0.02),
                                  xRadius: cornerRadius * 0.9, yRadius: cornerRadius * 0.9)
    NSColor(white: 1.0, alpha: 0.05).set()
    innerGlow.lineWidth = s * 0.02
    innerGlow.stroke()

    // Draw pixel cat face — 16x16 grid mapped to icon
    let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
    let G: UInt32 = 0x9898B0, GD: UInt32 = 0x7E7E98, W: UInt32 = 0xF0F0F8
    let P: UInt32 = 0xFFBBCC, GR: UInt32 = 0x88DD88
    let Y: UInt32 = 0xFFDD33, BL: UInt32 = 0x55AAFF
    let H: UInt32 = 0xFF6688  // heart accent

    let catFace: [[UInt32]] = [
        [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],  // ear tips
        [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],  // ears
        [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],  // ear inner + head
        [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],  // head
        [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],// eyes
        [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],// eyes row 2
        [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],  // muzzle
        [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],  // nose
        [T,T,T,B,G,G,G,W,W,G,G,G,B,T,T,T],  // mouth smile
        [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],  // collar
        [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T], // body + bell
        [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],  // body
        [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],  // body bottom
        [T,T,B,W,W,G,G,G,G,G,G,W,W,B,T,T],  // paws
        [T,T,T,B,B,B,B,B,B,B,B,B,B,T,T,T],  // base
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ]

    let gridW = 16
    let gridH = 16
    let padding = s * 0.12
    let catArea = s - padding * 2
    let pixelSize = catArea / CGFloat(gridW)
    let offsetX = padding
    let offsetY = padding * 0.6  // slightly lower

    for row in 0..<gridH {
        for col in 0..<gridW {
            let hex = catFace[row][col]
            guard hex != 0 else { continue }
            let r = CGFloat((hex >> 16) & 0xFF) / 255.0
            let g = CGFloat((hex >> 8) & 0xFF) / 255.0
            let b = CGFloat(hex & 0xFF) / 255.0
            NSColor(red: r, green: g, blue: b, alpha: 1.0).set()
            let rect = NSRect(
                x: offsetX + CGFloat(col) * pixelSize,
                y: offsetY + CGFloat(gridH - 1 - row) * pixelSize,
                width: pixelSize + 0.5,  // slight overlap to avoid gaps
                height: pixelSize + 0.5
            )
            rect.fill()
        }
    }

    // Small heart in corner
    if size >= 64 {
        let heartSize = s * 0.09
        let hx = s * 0.82
        let hy = s * 0.82

        NSColor(red: 1, green: 0.35, blue: 0.45, alpha: 0.9).set()
        let heartPath = NSBezierPath()
        heartPath.move(to: NSPoint(x: hx, y: hy + heartSize * 0.3))
        heartPath.curve(to: NSPoint(x: hx - heartSize, y: hy + heartSize),
                       controlPoint1: NSPoint(x: hx - heartSize * 0.5, y: hy + heartSize * 0.3),
                       controlPoint2: NSPoint(x: hx - heartSize, y: hy + heartSize * 0.7))
        heartPath.curve(to: NSPoint(x: hx, y: hy - heartSize * 0.5),
                       controlPoint1: NSPoint(x: hx - heartSize, y: hy + heartSize * 1.3),
                       controlPoint2: NSPoint(x: hx, y: hy))
        heartPath.curve(to: NSPoint(x: hx + heartSize, y: hy + heartSize),
                       controlPoint1: NSPoint(x: hx, y: hy),
                       controlPoint2: NSPoint(x: hx + heartSize, y: hy + heartSize * 1.3))
        heartPath.curve(to: NSPoint(x: hx, y: hy + heartSize * 0.3),
                       controlPoint1: NSPoint(x: hx + heartSize, y: hy + heartSize * 0.7),
                       controlPoint2: NSPoint(x: hx + heartSize * 0.5, y: hy + heartSize * 0.3))
        heartPath.fill()
    }

    image.unlockFocus()
    return image
}

generateIcon()
