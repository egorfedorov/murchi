import AppKit
import Foundation

// Generate Murchi app icon — peach kawaii cat matching the in-app SVG cat.

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

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconsetPath, "-o", dir + "/AppIcon.icns"]
    try! process.run()
    process.waitUntilExit()

    try? FileManager.default.removeItem(atPath: iconsetPath)
    print("Created AppIcon.icns")
}

func renderIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    if let context = NSGraphicsContext.current {
        context.imageInterpolation = .high
        let cg = context.cgContext
        cg.setAllowsAntialiasing(true)
        cg.setShouldAntialias(true)
    }

    let s = CGFloat(size)
    let lw = max(1.5, s * 0.016)
    let small = size <= 32

    // — Background: warm peach-to-pink gradient —
    let bgRect = NSRect(x: 0, y: 0, width: s, height: s)
    let corner = s * 0.22
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: corner, yRadius: corner)

    let bgGrad = NSGradient(colors: [
        NSColor(red: 1.0, green: 0.88, blue: 0.78, alpha: 1.0),
        NSColor(red: 1.0, green: 0.78, blue: 0.72, alpha: 1.0),
        NSColor(red: 0.98, green: 0.68, blue: 0.68, alpha: 1.0),
    ])!
    bgGrad.draw(in: bgPath, angle: -50)

    // Soft light blobs
    NSGraphicsContext.saveGraphicsState()
    bgPath.addClip()
    NSColor(white: 1.0, alpha: 0.18).setFill()
    NSBezierPath(ovalIn: NSRect(x: s * 0.5, y: s * 0.5, width: s * 0.45, height: s * 0.4)).fill()
    NSColor(white: 1.0, alpha: 0.10).setFill()
    NSBezierPath(ovalIn: NSRect(x: -s * 0.05, y: s * 0.6, width: s * 0.4, height: s * 0.25)).fill()
    NSGraphicsContext.restoreGraphicsState()

    // Colors matching the SVG cat
    let peach = NSColor(red: 1.0, green: 0.784, blue: 0.635, alpha: 1.0)       // #FFC8A2
    let darkPeach = NSColor(red: 0.878, green: 0.533, blue: 0.345, alpha: 1.0)  // #E08858
    let lightPeach = NSColor(red: 1.0, green: 0.894, blue: 0.800, alpha: 1.0)   // #FFE4CC
    let outline = NSColor(red: 0.60, green: 0.38, blue: 0.22, alpha: 1.0)
    let eyeBlack = NSColor(red: 0.176, green: 0.176, blue: 0.176, alpha: 1.0)   // #2D2D2D
    let noseColor = NSColor(red: 1.0, green: 0.569, blue: 0.643, alpha: 1.0)    // #FF91A4
    let blushColor = NSColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.35)

    // Head center
    let cx = s * 0.5
    let headCY = s * 0.42
    let headW = s * 0.58
    let headH = s * 0.52

    // — Ears (behind head) —
    let earW = s * 0.20
    let earH = s * 0.22

    for side in [-1.0, 1.0] as [CGFloat] {
        let earCX = cx + side * s * 0.22
        let earBase = headCY + headH * 0.32

        let ear = NSBezierPath()
        ear.move(to: NSPoint(x: earCX - earW * 0.5, y: earBase))
        ear.curve(
            to: NSPoint(x: earCX, y: earBase + earH),
            controlPoint1: NSPoint(x: earCX - earW * 0.45, y: earBase + earH * 0.7),
            controlPoint2: NSPoint(x: earCX - earW * 0.15, y: earBase + earH * 0.95)
        )
        ear.curve(
            to: NSPoint(x: earCX + earW * 0.5, y: earBase),
            controlPoint1: NSPoint(x: earCX + earW * 0.15, y: earBase + earH * 0.95),
            controlPoint2: NSPoint(x: earCX + earW * 0.45, y: earBase + earH * 0.7)
        )
        ear.close()

        // Outer ear
        darkPeach.setFill()
        ear.fill()

        // Inner ear
        let inner = NSBezierPath()
        let inset: CGFloat = 0.35
        inner.move(to: NSPoint(x: earCX - earW * (0.5 - inset), y: earBase + earH * 0.15))
        inner.curve(
            to: NSPoint(x: earCX, y: earBase + earH * 0.82),
            controlPoint1: NSPoint(x: earCX - earW * 0.25, y: earBase + earH * 0.6),
            controlPoint2: NSPoint(x: earCX - earW * 0.05, y: earBase + earH * 0.78)
        )
        inner.curve(
            to: NSPoint(x: earCX + earW * (0.5 - inset), y: earBase + earH * 0.15),
            controlPoint1: NSPoint(x: earCX + earW * 0.05, y: earBase + earH * 0.78),
            controlPoint2: NSPoint(x: earCX + earW * 0.25, y: earBase + earH * 0.6)
        )
        inner.close()
        noseColor.withAlphaComponent(0.6).setFill()
        inner.fill()

        // Ear outline
        strokePath(ear, color: outline, width: lw)
    }

    // — Shadow under head —
    NSColor(red: 0.6, green: 0.35, blue: 0.2, alpha: 0.12).setFill()
    NSBezierPath(ovalIn: NSRect(x: cx - headW * 0.45, y: headCY - headH * 0.52, width: headW * 0.9, height: headH * 0.2)).fill()

    // — Paws (in front, bottom) —
    if !small {
        let pawW = s * 0.13, pawH = s * 0.09
        let pawY = headCY - headH * 0.42
        for side in [-1.0, 1.0] as [CGFloat] {
            let px = cx + side * s * 0.11 - pawW / 2
            let pawRect = NSRect(x: px, y: pawY, width: pawW, height: pawH)
            let pawPath = NSBezierPath(ovalIn: pawRect)
            peach.setFill()
            pawPath.fill()
            strokePath(pawPath, color: outline, width: lw * 0.8)

            // Toe beans
            if size >= 128 {
                let beanColor = NSColor(red: 1.0, green: 0.72, blue: 0.76, alpha: 0.85)
                beanColor.setFill()
                let beanR = s * 0.012
                for dx in [-0.6, -0.2, 0.2, 0.6] as [CGFloat] {
                    NSBezierPath(ovalIn: NSRect(
                        x: px + pawW / 2 + pawW * dx * 0.35 - beanR,
                        y: pawY + pawH * 0.55,
                        width: beanR * 2, height: beanR * 1.6
                    )).fill()
                }
            }
        }
    }

    // — Head — large oval —
    let headRect = NSRect(x: cx - headW / 2, y: headCY - headH / 2, width: headW, height: headH)
    let headPath = NSBezierPath(ovalIn: headRect)

    // Shadow
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 0.15)
    shadow.shadowBlurRadius = s * 0.04
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.015)
    shadow.set()
    peach.setFill()
    headPath.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Head fill
    peach.setFill()
    headPath.fill()

    // Light upper area
    lightPeach.setFill()
    NSBezierPath(ovalIn: NSRect(
        x: cx - headW * 0.35, y: headCY + headH * 0.02, width: headW * 0.7, height: headH * 0.4
    )).fill()

    // Highlight spot
    NSColor(white: 1.0, alpha: 0.15).setFill()
    NSBezierPath(ovalIn: NSRect(
        x: cx - s * 0.08, y: headCY + headH * 0.15, width: s * 0.16, height: s * 0.1
    )).fill()

    // Head outline
    strokePath(headPath, color: outline, width: lw)

    // — Blush cheeks —
    blushColor.setFill()
    NSBezierPath(ovalIn: NSRect(x: cx - headW * 0.48, y: headCY - headH * 0.12, width: s * 0.09, height: s * 0.06)).fill()
    NSBezierPath(ovalIn: NSRect(x: cx + headW * 0.48 - s * 0.09, y: headCY - headH * 0.12, width: s * 0.09, height: s * 0.06)).fill()

    // — Eyes — white sclera + dark pupils + highlight (matching SVG cat) —
    let eyeW = s * 0.11
    let eyeH = s * 0.13
    let eyeY = headCY + headH * 0.04
    let eyeGap = s * 0.04

    for side in [-1.0, 1.0] as [CGFloat] {
        let ex = cx + side * (eyeGap / 2 + eyeW / 2) - eyeW / 2
        let eyeRect = NSRect(x: ex, y: eyeY, width: eyeW, height: eyeH)

        // White sclera
        NSColor.white.setFill()
        NSBezierPath(ovalIn: eyeRect).fill()

        // Dark iris
        let irisW = eyeW * 0.72, irisH = eyeH * 0.72
        let irisRect = NSRect(x: ex + (eyeW - irisW) / 2, y: eyeY + (eyeH - irisH) / 2, width: irisW, height: irisH)
        eyeBlack.setFill()
        NSBezierPath(ovalIn: irisRect).fill()

        // Big highlight
        NSColor.white.setFill()
        let hlSize = irisW * 0.38
        NSBezierPath(ovalIn: NSRect(
            x: irisRect.minX + irisW * 0.12, y: irisRect.maxY - hlSize - irisH * 0.1,
            width: hlSize, height: hlSize
        )).fill()

        // Small highlight
        let shSize = irisW * 0.18
        NSBezierPath(ovalIn: NSRect(
            x: irisRect.maxX - shSize - irisW * 0.12, y: irisRect.minY + irisH * 0.1,
            width: shSize, height: shSize
        )).fill()
    }

    // — Nose —
    let noseY = headCY - headH * 0.08
    let noseW = s * 0.04, noseH = s * 0.03
    let nosePath = NSBezierPath()
    nosePath.move(to: NSPoint(x: cx, y: noseY + noseH))
    nosePath.line(to: NSPoint(x: cx - noseW, y: noseY))
    nosePath.line(to: NSPoint(x: cx + noseW, y: noseY))
    nosePath.close()
    nosePath.lineJoinStyle = .round
    noseColor.setFill()
    nosePath.fill()

    // — Mouth —
    let mouthY = noseY - s * 0.01
    let smilePath = NSBezierPath()
    smilePath.move(to: NSPoint(x: cx, y: mouthY))
    smilePath.line(to: NSPoint(x: cx, y: mouthY - s * 0.025))
    smilePath.lineCapStyle = .round
    outline.setStroke()
    smilePath.lineWidth = max(1.0, lw * 0.7)
    smilePath.stroke()

    // Smile curves
    let smileW = s * 0.045
    let smileCurve = NSBezierPath()
    smileCurve.move(to: NSPoint(x: cx - smileW, y: mouthY - s * 0.015))
    smileCurve.curve(
        to: NSPoint(x: cx, y: mouthY - s * 0.035),
        controlPoint1: NSPoint(x: cx - smileW * 0.4, y: mouthY - s * 0.04),
        controlPoint2: NSPoint(x: cx - smileW * 0.1, y: mouthY - s * 0.04)
    )
    smileCurve.move(to: NSPoint(x: cx + smileW, y: mouthY - s * 0.015))
    smileCurve.curve(
        to: NSPoint(x: cx, y: mouthY - s * 0.035),
        controlPoint1: NSPoint(x: cx + smileW * 0.4, y: mouthY - s * 0.04),
        controlPoint2: NSPoint(x: cx + smileW * 0.1, y: mouthY - s * 0.04)
    )
    smileCurve.lineCapStyle = .round
    smileCurve.lineWidth = max(1.0, lw * 0.7)
    outline.setStroke()
    smileCurve.stroke()

    // — Whiskers —
    if size >= 64 {
        let whiskerColor = NSColor(red: 0.65, green: 0.45, blue: 0.30, alpha: 0.7)
        whiskerColor.setStroke()
        let wLW = max(1.0, lw * 0.6)
        let wY = headCY - headH * 0.06
        for side in [-1.0, 1.0] as [CGFloat] {
            let baseX = cx + side * headW * 0.28
            let endX = cx + side * headW * 0.58
            // Upper whisker
            let w1 = NSBezierPath()
            w1.move(to: NSPoint(x: baseX, y: wY + s * 0.02))
            w1.line(to: NSPoint(x: endX, y: wY + s * 0.04))
            w1.lineWidth = wLW; w1.lineCapStyle = .round; w1.stroke()
            // Lower whisker
            let w2 = NSBezierPath()
            w2.move(to: NSPoint(x: baseX, y: wY - s * 0.015))
            w2.line(to: NSPoint(x: endX, y: wY - s * 0.03))
            w2.lineWidth = wLW; w2.lineCapStyle = .round; w2.stroke()
        }
    }

    // — Heart decoration —
    drawHeart(
        center: NSPoint(x: s * 0.82, y: s * 0.80),
        size: s * 0.10,
        color: NSColor(red: 1.0, green: 0.35, blue: 0.50, alpha: 0.9)
    )

    // — Sparkles —
    if size >= 64 {
        drawSparkle(center: NSPoint(x: s * 0.16, y: s * 0.78), radius: s * 0.028, color: NSColor(white: 1.0, alpha: 0.75))
        drawSparkle(center: NSPoint(x: s * 0.75, y: s * 0.18), radius: s * 0.02, color: NSColor(white: 1.0, alpha: 0.55))
    }

    image.unlockFocus()
    return image
}

func drawHeart(center: NSPoint, size: CGFloat, color: NSColor) {
    let heart = NSBezierPath()
    heart.move(to: NSPoint(x: center.x, y: center.y - size * 0.48))
    heart.curve(
        to: NSPoint(x: center.x - size * 0.55, y: center.y + size * 0.06),
        controlPoint1: NSPoint(x: center.x - size * 0.34, y: center.y - size * 0.10),
        controlPoint2: NSPoint(x: center.x - size * 0.58, y: center.y - size * 0.16)
    )
    heart.curve(
        to: NSPoint(x: center.x, y: center.y + size * 0.48),
        controlPoint1: NSPoint(x: center.x - size * 0.58, y: center.y + size * 0.44),
        controlPoint2: NSPoint(x: center.x - size * 0.10, y: center.y + size * 0.62)
    )
    heart.curve(
        to: NSPoint(x: center.x + size * 0.55, y: center.y + size * 0.06),
        controlPoint1: NSPoint(x: center.x + size * 0.10, y: center.y + size * 0.62),
        controlPoint2: NSPoint(x: center.x + size * 0.58, y: center.y + size * 0.44)
    )
    heart.curve(
        to: NSPoint(x: center.x, y: center.y - size * 0.48),
        controlPoint1: NSPoint(x: center.x + size * 0.58, y: center.y - size * 0.16),
        controlPoint2: NSPoint(x: center.x + size * 0.34, y: center.y - size * 0.10)
    )
    heart.close()
    color.setFill()
    heart.fill()
    NSColor(white: 1.0, alpha: 0.35).setFill()
    NSBezierPath(ovalIn: NSRect(
        x: center.x - size * 0.17, y: center.y + size * 0.15,
        width: size * 0.16, height: size * 0.10
    )).fill()
}

func drawSparkle(center: NSPoint, radius: CGFloat, color: NSColor) {
    let sparkle = NSBezierPath()
    sparkle.move(to: NSPoint(x: center.x, y: center.y + radius))
    sparkle.line(to: NSPoint(x: center.x, y: center.y - radius))
    sparkle.move(to: NSPoint(x: center.x - radius, y: center.y))
    sparkle.line(to: NSPoint(x: center.x + radius, y: center.y))
    sparkle.lineCapStyle = .round
    sparkle.lineWidth = max(1.0, radius * 0.55)
    color.setStroke()
    sparkle.stroke()
}

func strokePath(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
    path.lineJoinStyle = .round
    path.lineCapStyle = .round
    path.lineWidth = width
    color.setStroke()
    path.stroke()
}

generateIcon()
