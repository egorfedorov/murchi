import AppKit
import Foundation

// Generate Murchi app icon — plush kawaii cat portrait rendered as vector art.
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

    if let context = NSGraphicsContext.current {
        context.imageInterpolation = .high
        let cg = context.cgContext
        cg.setAllowsAntialiasing(true)
        cg.setShouldAntialias(true)
    }

    let s = CGFloat(size)
    let outlineWidth = max(1.5, s * 0.014)
    let smallIcon = size <= 32

    let bgRect = NSRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.23
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

    let gradient = NSGradient(colors: [
        NSColor(red: 0.63, green: 0.92, blue: 0.93, alpha: 1.0),
        NSColor(red: 0.50, green: 0.85, blue: 0.89, alpha: 1.0),
        NSColor(red: 0.99, green: 0.81, blue: 0.86, alpha: 1.0),
    ])!
    gradient.draw(in: bgPath, angle: -58)

    NSGraphicsContext.saveGraphicsState()
    bgPath.addClip()
    NSColor(red: 1.00, green: 0.93, blue: 0.88, alpha: 0.52).setFill()
    NSBezierPath(ovalIn: NSRect(x: s * 0.48, y: s * 0.44, width: s * 0.48, height: s * 0.46)).fill()
    NSColor(red: 0.87, green: 0.97, blue: 0.99, alpha: 0.55).setFill()
    NSBezierPath(ovalIn: NSRect(x: -s * 0.10, y: s * 0.55, width: s * 0.46, height: s * 0.30)).fill()
    NSColor(white: 1.0, alpha: 0.14).setFill()
    NSBezierPath(ovalIn: NSRect(x: s * 0.08, y: s * 0.68, width: s * 0.42, height: s * 0.16)).fill()
    NSGraphicsContext.restoreGraphicsState()

    let innerGlow = NSBezierPath(
        roundedRect: bgRect.insetBy(dx: s * 0.02, dy: s * 0.02),
        xRadius: cornerRadius * 0.88,
        yRadius: cornerRadius * 0.88
    )
    NSColor(white: 1.0, alpha: 0.12).setStroke()
    innerGlow.lineWidth = max(1.0, s * 0.018)
    innerGlow.stroke()

    let leftEarRect = NSRect(x: s * 0.18, y: s * 0.54, width: s * 0.23, height: s * 0.25)
    let rightEarRect = NSRect(x: s * 0.59, y: s * 0.54, width: s * 0.23, height: s * 0.25)
    let headRect = NSRect(x: s * 0.20, y: s * 0.20, width: s * 0.60, height: s * 0.57)
    let leftEar = makeEarPath(in: leftEarRect, mirrored: false)
    let rightEar = makeEarPath(in: rightEarRect, mirrored: true)
    let headPath = NSBezierPath(ovalIn: headRect)
    let furGradient = NSGradient(colors: [
        NSColor(red: 0.99, green: 0.96, blue: 0.91, alpha: 1.0),
        NSColor(red: 0.96, green: 0.87, blue: 0.73, alpha: 1.0)
    ])!
    let muzzleGradient = NSGradient(colors: [
        NSColor(red: 1.0, green: 0.99, blue: 0.97, alpha: 1.0),
        NSColor(red: 0.98, green: 0.92, blue: 0.87, alpha: 1.0)
    ])!
    let innerEarColor = NSColor(red: 0.98, green: 0.74, blue: 0.82, alpha: 1.0)
    let outlineColor = NSColor(red: 0.49, green: 0.39, blue: 0.36, alpha: 1.0)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(red: 0.26, green: 0.34, blue: 0.38, alpha: 0.18)
    shadow.shadowBlurRadius = s * 0.045
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.015)
    shadow.set()
    furGradient.draw(in: leftEar, angle: 96)
    furGradient.draw(in: rightEar, angle: 96)
    furGradient.draw(in: headPath, angle: 92)
    NSGraphicsContext.restoreGraphicsState()

    furGradient.draw(in: leftEar, angle: 96)
    furGradient.draw(in: rightEar, angle: 96)
    furGradient.draw(in: headPath, angle: 92)

    let leftInnerEar = makeEarPath(in: leftEarRect.insetBy(dx: s * 0.04, dy: s * 0.04), mirrored: false)
    let rightInnerEar = makeEarPath(in: rightEarRect.insetBy(dx: s * 0.04, dy: s * 0.04), mirrored: true)
    innerEarColor.setFill()
    leftInnerEar.fill()
    rightInnerEar.fill()

    stroke(leftEar, color: outlineColor, width: outlineWidth)
    stroke(rightEar, color: outlineColor, width: outlineWidth)
    stroke(headPath, color: outlineColor, width: outlineWidth)

    NSColor(white: 1.0, alpha: 0.26).setFill()
    NSBezierPath(ovalIn: NSRect(x: s * 0.30, y: s * 0.50, width: s * 0.23, height: s * 0.15)).fill()

    if !smallIcon {
        let pawY = s * 0.17
        let pawSize = NSSize(width: s * 0.14, height: s * 0.10)
        let leftPaw = NSBezierPath(ovalIn: NSRect(x: s * 0.33, y: pawY, width: pawSize.width, height: pawSize.height))
        let rightPaw = NSBezierPath(ovalIn: NSRect(x: s * 0.53, y: pawY, width: pawSize.width, height: pawSize.height))
        furGradient.draw(in: leftPaw, angle: 90)
        furGradient.draw(in: rightPaw, angle: 90)
        stroke(leftPaw, color: outlineColor, width: outlineWidth * 0.9)
        stroke(rightPaw, color: outlineColor, width: outlineWidth * 0.9)

        if size >= 128 {
            let toeColor = NSColor(red: 0.96, green: 0.73, blue: 0.80, alpha: 0.95)
            toeColor.setFill()
            for x in [0.365, 0.405, 0.565, 0.605] {
                NSBezierPath(ovalIn: NSRect(x: s * x, y: pawY + s * 0.04, width: s * 0.026, height: s * 0.022)).fill()
            }
        }
    }

    let muzzleRect = NSRect(x: s * 0.30, y: s * 0.29, width: s * 0.40, height: s * 0.25)
    let muzzlePath = NSBezierPath(roundedRect: muzzleRect, xRadius: s * 0.12, yRadius: s * 0.12)
    muzzleGradient.draw(in: muzzlePath, angle: 90)
    stroke(muzzlePath, color: NSColor(red: 0.88, green: 0.76, blue: 0.70, alpha: 0.9), width: max(1.0, outlineWidth * 0.55))

    let blushColor = NSColor(red: 0.97, green: 0.56, blue: 0.70, alpha: smallIcon ? 0.52 : 0.65)
    blushColor.setFill()
    NSBezierPath(ovalIn: NSRect(x: s * 0.26, y: s * 0.35, width: s * 0.11, height: s * 0.08)).fill()
    NSBezierPath(ovalIn: NSRect(x: s * 0.63, y: s * 0.35, width: s * 0.11, height: s * 0.08)).fill()

    let eyeWidth = s * (smallIcon ? 0.075 : 0.082)
    let eyeHeight = eyeWidth * (smallIcon ? 1.05 : 1.30)
    let eyeY = s * 0.44
    let leftEyeRect = NSRect(x: s * 0.37, y: eyeY, width: eyeWidth, height: eyeHeight)
    let rightEyeRect = NSRect(x: s * 0.55, y: eyeY, width: eyeWidth, height: eyeHeight)
    let eyeColor = NSColor(red: 0.23, green: 0.18, blue: 0.24, alpha: 1.0)
    eyeColor.setFill()
    NSBezierPath(ovalIn: leftEyeRect).fill()
    NSBezierPath(ovalIn: rightEyeRect).fill()

    NSColor(white: 1.0, alpha: 0.94).setFill()
    NSBezierPath(ovalIn: NSRect(x: leftEyeRect.minX + eyeWidth * 0.18, y: leftEyeRect.maxY - eyeHeight * 0.40, width: eyeWidth * 0.24, height: eyeHeight * 0.26)).fill()
    NSBezierPath(ovalIn: NSRect(x: rightEyeRect.minX + eyeWidth * 0.18, y: rightEyeRect.maxY - eyeHeight * 0.40, width: eyeWidth * 0.24, height: eyeHeight * 0.26)).fill()

    let nose = NSBezierPath()
    nose.move(to: NSPoint(x: s * 0.50, y: s * 0.405))
    nose.line(to: NSPoint(x: s * 0.47, y: s * 0.372))
    nose.line(to: NSPoint(x: s * 0.53, y: s * 0.372))
    nose.close()
    nose.lineJoinStyle = .round
    NSColor(red: 0.83, green: 0.47, blue: 0.53, alpha: 1.0).setFill()
    nose.fill()

    let smileColor = NSColor(red: 0.46, green: 0.35, blue: 0.34, alpha: 1.0)
    let smile = NSBezierPath()
    smile.move(to: NSPoint(x: s * 0.50, y: s * 0.372))
    smile.line(to: NSPoint(x: s * 0.50, y: s * 0.345))
    smile.appendArc(withCenter: NSPoint(x: s * 0.50, y: s * 0.345), radius: s * 0.052, startAngle: 200, endAngle: 340, clockwise: false)
    smile.lineCapStyle = .round
    smile.lineJoinStyle = .round
    smileColor.setStroke()
    smile.lineWidth = max(1.2, outlineWidth * 0.78)
    smile.stroke()

    if size >= 128 {
        let whisker = NSBezierPath()
        whisker.move(to: NSPoint(x: s * 0.39, y: s * 0.365))
        whisker.line(to: NSPoint(x: s * 0.26, y: s * 0.385))
        whisker.move(to: NSPoint(x: s * 0.39, y: s * 0.337))
        whisker.line(to: NSPoint(x: s * 0.27, y: s * 0.325))
        whisker.move(to: NSPoint(x: s * 0.61, y: s * 0.365))
        whisker.line(to: NSPoint(x: s * 0.74, y: s * 0.385))
        whisker.move(to: NSPoint(x: s * 0.61, y: s * 0.337))
        whisker.line(to: NSPoint(x: s * 0.73, y: s * 0.325))
        whisker.lineCapStyle = .round
        whisker.lineWidth = max(1.1, outlineWidth * 0.55)
        NSColor(red: 0.75, green: 0.63, blue: 0.58, alpha: 0.95).setStroke()
        whisker.stroke()
    }

    drawHeart(
        center: NSPoint(x: s * 0.78, y: s * 0.77),
        size: s * (smallIcon ? 0.11 : 0.12),
        color: NSColor(red: 1.0, green: 0.42, blue: 0.56, alpha: 0.96)
    )

    if size >= 64 {
        drawSparkle(center: NSPoint(x: s * 0.20, y: s * 0.77), radius: s * 0.032, color: NSColor(white: 1.0, alpha: 0.82))
        drawSparkle(center: NSPoint(x: s * 0.70, y: s * 0.22), radius: s * 0.022, color: NSColor(white: 1.0, alpha: 0.62))
    }

    image.unlockFocus()
    return image
}

func makeEarPath(in rect: NSRect, mirrored: Bool) -> NSBezierPath {
    let path = NSBezierPath()

    if mirrored {
        let start = NSPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.10)
        path.move(to: start)
        path.curve(
            to: NSPoint(x: rect.maxX - rect.width * 0.48, y: rect.maxY),
            controlPoint1: NSPoint(x: rect.maxX + rect.width * 0.03, y: rect.minY + rect.height * 0.52),
            controlPoint2: NSPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.96)
        )
        path.curve(
            to: NSPoint(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.20),
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.98),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.60)
        )
        path.curve(
            to: start,
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.02),
            controlPoint2: NSPoint(x: rect.maxX - rect.width * 0.05, y: rect.minY + rect.height * 0.02)
        )
    } else {
        let start = NSPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.10)
        path.move(to: start)
        path.curve(
            to: NSPoint(x: rect.minX + rect.width * 0.48, y: rect.maxY),
            controlPoint1: NSPoint(x: rect.minX - rect.width * 0.03, y: rect.minY + rect.height * 0.52),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.96)
        )
        path.curve(
            to: NSPoint(x: rect.maxX - rect.width * 0.04, y: rect.minY + rect.height * 0.20),
            controlPoint1: NSPoint(x: rect.maxX - rect.width * 0.70, y: rect.minY + rect.height * 0.98),
            controlPoint2: NSPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.60)
        )
        path.curve(
            to: start,
            controlPoint1: NSPoint(x: rect.maxX - rect.width * 0.10, y: rect.minY + rect.height * 0.02),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.02)
        )
    }

    path.close()
    return path
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

    NSColor(white: 1.0, alpha: 0.42).setFill()
    NSBezierPath(ovalIn: NSRect(
        x: center.x - size * 0.17,
        y: center.y + size * 0.15,
        width: size * 0.16,
        height: size * 0.10
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

func stroke(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
    path.lineJoinStyle = .round
    path.lineCapStyle = .round
    path.lineWidth = width
    color.setStroke()
    path.stroke()
}

generateIcon()
