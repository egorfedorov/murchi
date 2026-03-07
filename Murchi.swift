import AppKit
import Foundation
import AVFoundation
import Carbon.HIToolbox
import UserNotifications

// ═══════════════════════════════════════════════════════════════
// MURCHI — Desktop Tamagotchi Cat for macOS
// A kawaii cat that lives on your desktop, walks around,
// reacts to you, and needs love & care.
// ═══════════════════════════════════════════════════════════════

// MARK: - Cat Renderer (SVG-based Kawaii Peach Cat with Animation)

class CatRenderer {
    static let shared = CatRenderer()
    private var cache: [String: NSImage] = [:]
    private var cacheKeys: [String] = []
    private let maxCacheSize = 400
    let size: CGFloat = 160

    func clearCache() { cache.removeAll(); cacheKeys.removeAll() }

    private func cacheInsert(_ key: String, _ img: NSImage) {
        if cache[key] != nil { return }
        if cacheKeys.count >= maxCacheSize {
            let old = cacheKeys.removeFirst()
            cache.removeValue(forKey: old)
        }
        cache[key] = img
        cacheKeys.append(key)
    }

    enum CatPose { case sitting, walking, eating, sleeping, held, angry, jumping, playing, clinging, bathing, sick, dead, celebrating, crying, lonelySitting, standing, climbing }

    // Pet screen position for cursor tracking (updated by PetEngine)
    var petScreenCenter: NSPoint = NSPoint(x: 400, y: 100)

    // Pre-rendered animation frames
    private var sittingFramesOpen: [NSImage] = []
    private var sittingFramesClosed: [NSImage] = []
    private var walkFramesOpen: [NSImage] = []
    private var walkFramesClosed: [NSImage] = []
    private var eatingOpen: NSImage!
    private var eatingClosed: NSImage!
    private var eatingChompOpen: NSImage!
    private var eatingChompClosed: NSImage!
    private var sleepingFrames: [NSImage] = []
    private var heldFramesOpen: [NSImage] = []
    private var heldFramesClosed: [NSImage] = []
    private var angryFramesOpen: [NSImage] = []
    private var angryFramesClosed: [NSImage] = []
    private var jumpingImage: NSImage!
    private var playingFramesOpen: [NSImage] = []
    private var playingFramesClosed: [NSImage] = []
    private var bathingFrames: [NSImage] = []
    private var sickFrames: [NSImage] = []
    private var deadImage: NSImage!
    private var celebratingFrames: [NSImage] = []
    private var cryingFrames: [NSImage] = []
    private var lonelySittingFrames: [NSImage] = []
    private var standingFrames: [NSImage] = []
    private var climbingFramesOpen: [NSImage] = []
    private var climbingFramesClosed: [NSImage] = []

    init() {
        buildSittingFrames()
        buildWalkingFrames()
        buildEatingFrames()
        buildSleepingFrames()
        buildHeldFrames()
        buildAngryFrames()
        jumpingImage = renderSVG(CatRenderer.jumpingSVG)
        buildPlayingFrames()
        buildBathingFrames()
        buildSickFrames()
        deadImage = renderSVG(CatRenderer.deadSVG)
        buildCelebratingFrames()
        buildCryingFrames()
        buildLonelySittingFrames()
        buildStandingFrames()
        buildClimbingFrames()
    }

    // MARK: - SVG rendering

    private func renderSVG(_ svg: String) -> NSImage {
        guard let data = svg.data(using: .utf8),
              let img = NSImage(data: data) else {
            return NSImage(size: NSSize(width: size, height: size))
        }
        let output = NSImage(size: NSSize(width: size, height: size))
        output.lockFocus()
        img.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
                 from: NSRect(origin: .zero, size: img.size),
                 operation: .sourceOver, fraction: 1.0)
        output.unlockFocus()
        return output
    }

    /// Render SVG into a tall frame (for held/dangling pose)
    static let heldHeight: CGFloat = 240  // taller than square
    private func renderHeldSVG(_ svg: String) -> NSImage {
        guard let data = svg.data(using: .utf8),
              let img = NSImage(data: data) else {
            return NSImage(size: NSSize(width: size, height: CatRenderer.heldHeight))
        }
        let output = NSImage(size: NSSize(width: size, height: CatRenderer.heldHeight))
        output.lockFocus()
        img.draw(in: NSRect(x: 0, y: 0, width: size, height: CatRenderer.heldHeight),
                 from: NSRect(origin: .zero, size: img.size),
                 operation: .sourceOver, fraction: 1.0)
        output.unlockFocus()
        return output
    }

    // MARK: - Frame generation (SVG string manipulation)

    private func buildSittingFrames() {
        for i in 0..<16 {
            let phase = Double(i) / 16.0 * .pi * 2.0
            let openSVG = CatRenderer.makeSittingFrame(phase: phase, eyesClosed: false)
            let closedSVG = CatRenderer.makeSittingFrame(phase: phase, eyesClosed: true)
            sittingFramesOpen.append(renderSVG(openSVG))
            sittingFramesClosed.append(renderSVG(closedSVG))
        }
    }

    private func buildWalkingFrames() {
        for i in 0..<20 {
            let phase = Double(i) / 20.0 * .pi * 2.0

            let openSVG = CatRenderer.makeWalkFrame(phase: phase, eyesClosed: false)
            let closedSVG = CatRenderer.makeWalkFrame(phase: phase, eyesClosed: true)
            walkFramesOpen.append(renderSVG(openSVG))
            walkFramesClosed.append(renderSVG(closedSVG))
        }
    }

    private func buildEatingFrames() {
        eatingOpen = renderSVG(CatRenderer.eatingSVG)
        eatingClosed = renderSVG(CatRenderer.makeBlink(
            svg: CatRenderer.eatingSVG,
            eyePaths: CatRenderer.eatingEyePaths,
            closedEyes: CatRenderer.eatingClosedEyes))
        // Chomp frames: head slightly down toward the bowl
        let chompSVG = CatRenderer.makeEatingChomp(eyesClosed: false)
        let chompBlinkSVG = CatRenderer.makeEatingChomp(eyesClosed: true)
        eatingChompOpen = renderSVG(chompSVG)
        eatingChompClosed = renderSVG(chompBlinkSVG)
    }

    private func buildSleepingFrames() {
        for i in 0..<16 {
            let phase = Double(i) / 16.0 * .pi * 2.0
            sleepingFrames.append(renderSVG(CatRenderer.makeSleepingFrame(phase: phase)))
        }
    }

    private func buildHeldFrames() {
        for i in 0..<16 {
            let phase = Double(i) / 16.0 * .pi * 2.0
            heldFramesOpen.append(renderHeldSVG(CatRenderer.makeHeldFrame(phase: phase, eyesClosed: false)))
            heldFramesClosed.append(renderHeldSVG(CatRenderer.makeHeldFrame(phase: phase, eyesClosed: true)))
        }
    }

    private func buildAngryFrames() {
        for i in 0..<12 {
            let phase = Double(i) / 12.0 * .pi * 2.0
            angryFramesOpen.append(renderSVG(CatRenderer.makeAngryFrame(phase: phase, eyesClosed: false)))
            angryFramesClosed.append(renderSVG(CatRenderer.makeAngryFrame(phase: phase, eyesClosed: true)))
        }
    }

    private func buildPlayingFrames() {
        for i in 0..<16 {
            let phase = Double(i) / 16.0 * .pi * 2.0
            playingFramesOpen.append(renderSVG(CatRenderer.makePlayingFrame(phase: phase, eyesClosed: false)))
            playingFramesClosed.append(renderSVG(CatRenderer.makePlayingFrame(phase: phase, eyesClosed: true)))
        }
    }

    private func buildBathingFrames() {
        for i in 0..<16 {
            let phase = Double(i) / 16.0 * .pi * 2.0
            bathingFrames.append(renderSVG(CatRenderer.makeBathingFrame(phase: phase)))
        }
    }

    private func buildSickFrames() {
        for i in 0..<16 {
            let phase = Double(i) / 16.0 * .pi * 2.0
            sickFrames.append(renderSVG(CatRenderer.makeSickFrame(phase: phase)))
        }
    }

    private func buildCelebratingFrames() {
        for i in 0..<16 {
            let phase = Double(i) / 16.0 * .pi * 2.0
            celebratingFrames.append(renderSVG(CatRenderer.makeCelebratingFrame(phase: phase)))
        }
    }

    private func buildCryingFrames() {
        for i in 0..<16 {
            let phase = Double(i) / 16.0 * .pi * 2.0
            cryingFrames.append(renderSVG(CatRenderer.makeCryingFrame(phase: phase)))
        }
    }

    private func buildLonelySittingFrames() {
        for i in 0..<16 {
            let phase = Double(i) / 16.0 * .pi * 2.0
            lonelySittingFrames.append(renderSVG(CatRenderer.makeLonelySittingFrame(phase: phase)))
        }
    }

    private func buildStandingFrames() {
        for i in 0..<16 {
            let phase = Double(i) / 16.0 * .pi * 2.0
            standingFrames.append(renderSVG(CatRenderer.makeStandingFrame(phase: phase)))
        }
    }

    private func buildClimbingFrames() {
        for i in 0..<16 {
            let phase = Double(i) / 16.0 * .pi * 2.0
            climbingFramesOpen.append(renderSVG(CatRenderer.makeClimbingFrame(phase: phase, eyesClosed: false)))
            climbingFramesClosed.append(renderSVG(CatRenderer.makeClimbingFrame(phase: phase, eyesClosed: true)))
        }
    }

    // Format helper
    private static func f(_ v: Double) -> String { String(format: "%.1f", v) }

    // Body path segments as absolute coordinates (23 cubic beziers from M134.7,121.9)
    private static let bodySegs: [[Double]] = [
        [148.13,120.87, 162.22,120.77, 173.14,129.9],
        [184.92,138.98, 185.43,152.86, 183.97,163.79],
        [183.10,170.41, 180.12,177.87, 185.48,183.15],
        [189.93,184.90, 190.50,187.91, 193.73,194.45],  // 3: back leg
        [196.14,198.70, 195.27,202.40, 193.27,208.10],
        [190.82,213.43, 187.70,215.90, 184.52,214.92],
        [179.92,213.87, 179.10,207.24, 177.09,204.25],
        [175.64,201.75, 172.82,202.61, 165.87,200.81],  // 7: back leg end
        [158.08,198.67, 150.24,193.72, 149.32,192.38],
        [141.81,194.35, 131.93,194.45, 119.57,194.45],
        [119.62,201.27, 119.57,209.05, 117.02,213.49],  // 10: front leg
        [113.90,217.50, 104.52,218.12, 99.80,217.00],
        [95.90,215.77, 94.79,212.10, 97.00,207.89],
        [97.82,206.70, 97.72,206.70, 97.15,204.73],     // 13: front leg end
        [95.90,199.77, 94.00,193.11, 92.74,191.31],
        [81.17,186.91, 71.03,181.48, 65.72,162.70],
        [42.22,162.40, 10.22,155.97, 8.22,127.11],
        [7.96,117.50, 14.30,116.67, 14.46,106.01],
        [14.62,86.17, 22.99,66.02, 44.72,56.25],
        [54.00,52.10, 63.13,50.35, 74.55,50.55],
        [79.15,50.65, 90.22,51.79, 98.50,56.04],
        [118.85,64.51, 134.43,79.76, 135.10,112.04],
        [135.15,115.71, 134.99,117.98, 134.70,121.90],
    ]
    private static let bodySX = 134.7, bodySY = 121.9

    // Rotate point around pivot
    private static func rotPt(_ px: Double, _ py: Double, _ cx: Double, _ cy: Double, _ a: Double) -> (Double, Double) {
        let c = cos(a), s = sin(a)
        return (cx + (px-cx)*c - (py-cy)*s, cy + (px-cx)*s + (py-cy)*c)
    }

    // Rotate all 6 values in a bezier segment around pivot
    private static func rotSeg(_ seg: [Double], _ cx: Double, _ cy: Double, _ a: Double) -> [Double] {
        let (x1,y1) = rotPt(seg[0],seg[1],cx,cy,a)
        let (x2,y2) = rotPt(seg[2],seg[3],cx,cy,a)
        let (x3,y3) = rotPt(seg[4],seg[5],cx,cy,a)
        return [x1,y1,x2,y2,x3,y3]
    }

    // Generate morphed body path with rotated legs
    private static func morphBodyPath(backAngle: Double, frontAngle: Double) -> String {
        var s = bodySegs.map { $0 }
        let bx = 185.48, by = 183.15  // back leg pivot
        s[2] = rotSeg(s[2], bx, by, backAngle * 0.1)
        for i in 3...6 { s[i] = rotSeg(s[i], bx, by, backAngle) }
        s[7] = rotSeg(s[7], bx, by, backAngle * 0.6)
        s[8] = rotSeg(s[8], bx, by, backAngle * 0.2)

        let fx = 119.57, fy = 194.45  // front leg pivot
        s[9] = rotSeg(s[9], fx, fy, frontAngle * 0.1)
        for i in 10...12 { s[i] = rotSeg(s[i], fx, fy, frontAngle) }
        s[13] = rotSeg(s[13], fx, fy, frontAngle * 0.6)
        s[14] = rotSeg(s[14], fx, fy, frontAngle * 0.2)

        var d = "M\(f(bodySX)) \(f(bodySY))"
        for v in s { d += "C\(v.map { f($0) }.joined(separator: " "))" }
        return d + "Z"
    }

    // Generate far-side leg path rotated around pivot
    private static func farBackLegPath(angle: Double) -> String {
        let px = 185.0, py = 183.0
        let pts: [(Double,Double)] = [(185,183),(188,188),(190,196),(190,204),(189,211),(186,215),(183,214),(180,212),(180,204),(180,196),(181,188),(183,184)]
        let r = pts.map { rotPt($0.0, $0.1, px, py, angle) }
        let p = r.map { "\(f($0.0)) \(f($0.1))" }
        return "<path d=\"M\(p[0]) C\(p[1]) \(p[2]) \(p[3]) C\(p[4]) \(p[5]) \(p[6]) C\(p[7]) \(p[8]) \(p[9]) C\(p[10]) \(p[11]) \(p[0])\" fill=\"#E0A070\"/>"
    }

    private static func farFrontLegPath(angle: Double) -> String {
        let px = 117.0, py = 194.0
        let pts: [(Double,Double)] = [(117,194),(116,200),(113,207),(110,213),(107,217),(102,217),(100,215),(98,212),(103,205),(108,198),(112,194),(115,192)]
        let r = pts.map { rotPt($0.0, $0.1, px, py, angle) }
        let p = r.map { "\(f($0.0)) \(f($0.1))" }
        return "<path d=\"M\(p[0]) C\(p[1]) \(p[2]) \(p[3]) C\(p[4]) \(p[5]) \(p[6]) C\(p[7]) \(p[8]) \(p[9]) C\(p[10]) \(p[11]) \(p[0])\" fill=\"#E0A070\"/>"
    }

    // Back leg shadow line rotated with near back leg
    private static func backLegShadowPath(angle: Double) -> String {
        let bx = 185.48, by = 183.15
        let pts: [(Double,Double)] = [(146.9,179.2),(146.9,188.19),(149.0,197.27),(166.0,200.28)]
        let r = pts.map { rotPt($0.0, $0.1, bx, by, angle) }
        return "<path d=\"M\(f(r[0].0)) \(f(r[0].1)) C\(f(r[1].0)) \(f(r[1].1)) \(f(r[2].0)) \(f(r[2].1)) \(f(r[3].0)) \(f(r[3].1))\" stroke=\"#E08858\" stroke-linecap=\"round\" stroke-miterlimit=\"10\" stroke-width=\"3\"/>"
    }

    // Walking frame using body path morphing (rotation of bezier segments around hip pivots)
    // Near-side legs morph as part of body path, far-side legs are separate darker shapes
    private static func makeWalkFrame(phase: Double, eyesClosed: Bool) -> String {
        let amp = 0.35 // ~20 degrees
        let nearBackA = sin(phase) * amp
        let nearFrontA = sin(phase + .pi) * amp
        let farBackA = sin(phase + .pi) * amp
        let farFrontA = sin(phase) * amp
        let tailAngle = sin(phase + .pi / 3.0) * 12.0
        let bobY = sin(phase * 2.0) * 1.5

        let bodyD = morphBodyPath(backAngle: nearBackA, frontAngle: nearFrontA)

        var svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="250" height="250" fill="none" viewBox="0 0 250 250">
        <g transform="translate(0, \(f(bobY)))">
          <path d="m41.78 58.63c2.71-12.02 6.03-24.51 11.14-24.81 6.49-0.36 12.79 6.89 22.06 17.1l0.34 0.39-0.4-0.04-0.04 1.67-33.1 5.69z" fill="#E08858" stroke="#E08858" stroke-miterlimit="10" stroke-width=".25"/>
          <g transform="rotate(\(f(tailAngle)), 170, 135)">
            <path d="m172 129.3c11.2 3.68 17.25 12.83 25.06 22.23 7.71 9.24 16.86 15.64 31.04 14.71 8.9-0.6 12.7 0.33 15.58 5.67 2.93 5.48 1.09 11.91-7.67 14.81-12.11 4.16-27.94 1.05-39.81-12-9.14-10.3-13.22-16.49-17.52-17.7l-6.68-27.72z" fill="#E08858" stroke="#E08858" stroke-miterlimit="10" stroke-width=".25"/>
          </g>
          \(farBackLegPath(angle: farBackA))
          \(farFrontLegPath(angle: farFrontA))
          <path d="\(bodyD)" fill="#FFC8A2" stroke="#FFC8A2" stroke-miterlimit="10" stroke-width=".25"/>
          <path d="m135.4 122.2c-4.65 20.6-20.94 39.8-56.74 45.13-3.9 0.41-6.93 0.87-12.53-0.46l-0.57-4.01c11.57-0.05 35.33-0.86 50.45-15.18 11.21-9.38 17.21-17.57 18.78-25.78l0.61 0.3z" fill="#E08858" stroke="#E08858" stroke-miterlimit="10" stroke-width=".25"/>
          <path d="m114.4 67.69c-2.72-12.21-6.67-22.67-16.65-33.97-3.51-3.11-6.28-2.91-8.33-1.22-4.4 3.48-8.64 12.31-15.54 22.62-1.79 4.74-1.74 9.05 2.06 14.28 8.66 11.52 18.04 17.65 28.23 14.36 7.94-3.29 11.94-8.93 10.23-16.07z" fill="#E08858" stroke="#E08858" stroke-miterlimit="10" stroke-width=".25"/>
          <path d="m92.16 47.81c-2.05-3.67-5.23-2.08-6.64 0.92-3.56 5.79-6.69 10.92-6.18 13.97 0.47 4.16 8.8 11.72 11.57 12.75 3.34 1.23 3.91-5.44 3.03-16.31-0.52-4.01-1.09-8.52-1.78-11.33z" fill="#FFE4CC" stroke="#FFE4CC" stroke-miterlimit="10" stroke-width=".25"/>
          <path d="m45.32 92.86c-9.67 0-16.78 9.39-16.57 19.65s7.16 16.78 16.16 16.78c9.53 0 16.08-9.49 16.08-18.67 0-8.88-6.29-17.76-15.67-17.76z" fill="#FEFFFE" stroke="#FEFFFE" stroke-miterlimit="10" stroke-width=".25"/>
          <path d="m40.72 97.81c-7.21 0-11.86 7.95-11.5 15.88 0.32 8.06 5.42 13.86 10.73 13.65 6.95-0.26 10.46-8.62 10.46-14.73 0-7.26-4.29-14.8-9.69-14.8z" fill="#2D2D2D" stroke="#2D2D2D" stroke-miterlimit="10" stroke-width=".25"/>
          <path d="m36.01 102.7c-1.73 1.38-2.09 3.51-0.79 4.95 1.57 1.75 3.62 1.07 4.19 0.4 1.52-1.28 1-3.7 0.08-4.63-1.03-1.08-2.44-1.38-3.48-0.72z" fill="#FEFFFE" stroke="#FEFFFE" stroke-miterlimit="10" stroke-width=".25"/>
          <path d="m6.11 120.2c0-2.56 1.68-3.38 3.14-3.38 1.84 0 5.51 0.41 6.08 2.1 0.82 2.36-3.73 8.77-5.78 8.77-2.22 0-3.44-4.01-3.44-7.49z" fill="#FF91A4" stroke="#FF91A4" stroke-miterlimit="10" stroke-width=".25"/>
          <path d="m10.01 127.7c0 4.35 1.17 8.02 5.77 8.02 4.1 0 4.97-2.27 6.28-4.38" stroke="#2D2D2D" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3"/>
          <path d="m58.72 127.6c-4.7 1.18-5.91 4.29-5.59 6.31 0.62 3.87 4.81 4.95 8.66 4.75 5.87-0.31 8.31-3.65 8.26-5.47-0.16-4.1-4.34-5.95-11.33-5.59z" fill="#FFE4CC" stroke="#FFE4CC" stroke-miterlimit="10" stroke-width=".25"/>
          <path d="m84.51 121.2 17.71-3.39" stroke="#E08858" stroke-linecap="round" stroke-miterlimit="10" stroke-width="5"/>
          <path d="m84.51 131 17.71 2.53" stroke="#E08858" stroke-linecap="round" stroke-miterlimit="10" stroke-width="5"/>
          <path d="m81.63 139.8 13.09 7.85" stroke="#E08858" stroke-linecap="round" stroke-miterlimit="10" stroke-width="5"/>
          \(backLegShadowPath(angle: nearBackA))
        </g>
        </svg>
        """

        if eyesClosed {
            svg = makeBlink(svg: svg, eyePaths: walkEyePaths, closedEyes: walkClosedEyes)
        }
        return svg
    }

    // Sitting frame: breathing (translateY) + tail wag (rotate)
    private static func makeSittingFrame(phase: Double, eyesClosed: Bool) -> String {
        let bobY = sin(phase) * 1.5
        let tailAngle = sin(phase + .pi / 3.0) * 8.0

        var svg = sittingSVG

        // Do blink FIRST so closed eyes end up inside the breathing group
        if eyesClosed {
            svg = makeBlink(svg: svg, eyePaths: sittingEyePaths, closedEyes: sittingClosedEyes)
        }

        // Tail wag: wrap tail path in rotation group
        let tailD = "m175.1 198.6c16.19-2.24 23.89-17.58 34.9-24.3"
        if let range = svg.range(of: tailD) {
            let before = svg[svg.startIndex..<range.lowerBound]
            if let pStart = before.range(of: "<path", options: .backwards) {
                let after = svg[range.upperBound...]
                if let pEnd = after.range(of: "/>") {
                    let pathStr = String(svg[pStart.lowerBound..<pEnd.upperBound])
                    svg = svg.replacingOccurrences(
                        of: pathStr,
                        with: "<g transform=\"rotate(\(f(tailAngle)), 175, 199)\">\(pathStr)</g>"
                    )
                }
            }
        }

        // Breathing: wrap ALL content (including defs and closed eyes) in translateY
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: "(https://quiver.ai) -->\n<g transform=\"translate(0, \(f(bobY)))\">"
        )
        svg = svg.replacingOccurrences(of: "</svg>", with: "</g>\n</svg>")

        return svg
    }

    // Cursor tracking: sitting frame with pupils shifted toward cursor
    private static let sittingPupilPaths = [
        // Right pupil
        ##"<path d="m166.9 89.41c-11.6 0-20.15 11-20.15 21.5 0 11.4 8.69 20.54 19.69 20.54 11.15 0 19.7-11.01 19.7-21.37 0-10.77-8.41-20.67-19.24-20.67z" fill="#2D2D2D"/>"##,
        // Right highlight
        ##"<path d="m161.5 95.12c-4.3 0-5.75 3.21-5.75 5.51 0 3.53 2.81 5.62 5.34 5.62 3.68 0 5.85-2.9 5.85-5.44 0-3.1-2.4-5.69-5.44-5.69z" fill="#fff"/>"##,
        // Left pupil
        ##"<path d="m82.92 89.27c11.01 0 19.24 10.77 19.24 21.78 0 11.4-8.69 20.54-19.24 20.54s-20.15-10.16-20.15-20.99c0-11.54 9.35-21.33 20.15-21.33z" fill="#2D2D2D"/>"##,
        // Left highlight
        ##"<path d="m87.84 95.12c4.3 0 5.75 3.21 5.75 5.51 0 3.53-2.81 5.62-5.34 5.62-3.68 0-5.85-2.9-5.85-5.44 0-3.1 2.4-5.69 5.44-5.69z" fill="#fff"/>"##,
    ]

    private static func makeCursorTrackingFrame(phase: Double, pupilDX: Double, pupilDY: Double) -> String {
        // Start with a sitting frame (breathing + tail wag, eyes open)
        var svg = makeSittingFrame(phase: phase, eyesClosed: false)

        // Shift pupils toward cursor
        let tx = "translate(\(f(pupilDX)), \(f(pupilDY)))"
        for path in sittingPupilPaths {
            svg = svg.replacingOccurrences(
                of: path,
                with: "<g transform=\"\(tx)\">\(path)</g>"
            )
        }
        return svg
    }

    // Sleeping frame: breathing (translateY)
    private static func makeSleepingFrame(phase: Double) -> String {
        let bobY = sin(phase) * 1.0  // gentle breathing

        var svg = sleepingSVG
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: "(https://quiver.ai) -->\n<g transform=\"translate(0, \(f(bobY)))\">"
        )
        svg = svg.replacingOccurrences(of: "</svg>", with: "</g>\n</svg>")
        return svg
    }

    // Held frame: pendulum sway + breathing
    private static let heldEyePaths = [
        ##"<path d="m57.81 133.2c-2.64-3.48-5.88-5.74-10.6-5.25-7.39 0.74-12.11 7.22-12.11 12.68 0 6.72 5.22 12.19 11.69 12.19 7.39 0 11.36-6.48 11.36-11.94 0-2.74 0.24-5.21-0.34-7.68z" fill="#000"/>"##,
        ##"<path d="m50.98 136.6c2.18 0.67 3.98-1.46 2.85-3.58-1.19-2.33-5.11-1.51-5.11 0.89 0 1.35 0.76 2.26 2.26 2.69z" fill="#fff"/>"##,
        ##"<path d="m110.6 130.1c0-7.41-5.47-12.37-11.94-12.37-7.92 0-12.87 6.2-12.87 12.37 0 7.41 5.96 12.6 12.43 12.6 6.91 0 12.38-5.91 12.38-12.6z" fill="#000"/>"##,
        ##"<path d="m103.4 126.6c2.52 0 3.24-2.74 1.74-4.22-1.74-1.74-4.48-0.51-4.48 1.48 0 1.5 0.99 2.74 2.74 2.74z" fill="#fff"/>"##,
    ]
    private static let heldClosedEyes = ##"""
    <path d="M36 138 Q47 143 58 138" stroke="#000" stroke-width="2.5" stroke-linecap="round" fill="none"/>
    <path d="M86 132 Q99 137 112 132" stroke="#000" stroke-width="2.5" stroke-linecap="round" fill="none"/>
    """##

    private static func makeHeldFrame(phase: Double, eyesClosed: Bool) -> String {
        // Realistic "held by scruff" pendulum physics
        let sway = sin(phase) * 7.0                     // pendulum swing
        let breathY = sin(phase * 1.5) * 2.0            // body bob
        let pawScramble = sin(phase * 3.0) * 1.5        // fast paw kicking

        // Pivot around scruff area (top of head/neck)
        let cx = 90.0, cy = 60.0

        var svg = heldSVG
        if eyesClosed {
            svg = makeBlink(svg: svg, eyePaths: heldEyePaths, closedEyes: heldClosedEyes)
        }
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: "(https://quiver.ai) -->\n<g transform=\"rotate(\(f(sway)), \(f(cx)), \(f(cy))) translate(\(f(pawScramble)), \(f(breathY)))\">"
        )
        svg = svg.replacingOccurrences(of: "</svg>", with: "</g>\n</svg>")
        return svg
    }

    // Angry frame: trembling + bristle pulse
    private static let angryEyePaths = [
        ##"<path d="m108.7 137.7c0 7.89-6.4 13.07-12.58 13.07-7.2 0-12.18-6.8-12.18-13.07 0-7.23 5.8-12.4 12.18-12.4 7.2 0 12.58 6.41 12.58 12.4z" fill="url(#paint5_linear_1338_1255)"/>"##,
        ##"<path d="m93.92 135.6c0 2.56-1.93 3.67-3.4 3.67-1.82 0-3.01-1.56-3.01-3.12 0-1.94 1.57-3.35 3.01-3.35 2.09 0 3.4 1.46 3.4 2.8z" fill="#fff"/>"##,
        ##"<path d="m29.74 139.1c0 7.89 6.4 13.67 12.59 13.67 8.36 0 12.5-6.41 12.33-13.21-0.23-7.23-5.92-12.84-12.33-12.84-7.2 0-12.59 6.41-12.59 12.38z" fill="url(#paint6_linear_1338_1255)"/>"##,
        ##"<path d="m39.96 138.4c2.26-0.34 3.08-2.07 2.79-3.74-0.34-1.62-1.82-2.58-3.19-2.36-1.88 0.34-3.45 1.86-3.45 3.48s1.57 2.95 3.85 2.62z" fill="#fff"/>"##,
    ]
    private static let angryClosedEyes = """
    <path d="M84 137 Q96 141 108 137" stroke="#333" stroke-width="3" stroke-linecap="round" fill="none"/>
    <path d="M30 139 Q42 143 54 139" stroke="#333" stroke-width="3" stroke-linecap="round" fill="none"/>
    """

    private static func makeAngryFrame(phase: Double, eyesClosed: Bool) -> String {
        // Fast trembling: high-frequency small offset
        let shakeX = sin(phase * 3) * 1.5
        let shakeY = sin(phase * 2.3) * 0.8

        var svg = angrySVG
        if eyesClosed {
            svg = makeBlink(svg: svg, eyePaths: angryEyePaths, closedEyes: angryClosedEyes)
        }
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: "(https://quiver.ai) -->\n<g transform=\"translate(\(f(shakeX)), \(f(shakeY)))\">"
        )
        svg = svg.replacingOccurrences(of: "<defs>", with: "</g>\n<defs>")
        return svg
    }

    // Playing frame: bouncy movement + body tilt
    private static let playingEyePaths = [
        ##"<path d="m144.1 94.09c-1.3 7.17-7.13 12.52-12.9 12.07-6.23-0.55-10.1-5.9-10.1-11.45 0-7.32 6.23-11.94 12.46-11.94 6.79 0 11.84 4.86 10.54 11.32z" fill="url(#paint0_linear_201_525)"/>"##,
        ##"<path d="m141.4 92.27c0 2.77-3.24 4.07-5.12 2.44-1.87-1.48-1.6-4.7 0.91-5.62 2.37-0.85 4.21 0.92 4.21 3.18z" fill="#FEFFFE"/>"##,
        ##"<path d="m183.9 122.7c0 7.35-6.57 12.55-12.22 12.1-6.79-0.55-10.97-6.35-10.69-12.1 0.46-7.35 6.44-11.97 12.1-11.97 6.78 0 10.81 6.43 10.81 11.97z" fill="url(#paint1_linear_201_525)"/>"##,
        ##"<path d="m174.3 113.6c2.69 1.08 1.17 6.15-2.29 5.55-3.93-0.7-3.98-5.55-0.27-5.89 0.91-0.1 1.79 0.05 2.56 0.34z" fill="#FEFFFE"/>"##,
    ]
    private static let playingClosedEyes = """
    <path d="M121 96 Q133 100 144 96" stroke="#2D2D2B" stroke-width="3" stroke-linecap="round" fill="none"/>
    <path d="M161 123 Q173 127 184 123" stroke="#2D2D2B" stroke-width="3" stroke-linecap="round" fill="none"/>
    """

    private static func makePlayingFrame(phase: Double, eyesClosed: Bool) -> String {
        let bounceY = abs(sin(phase)) * -4.0  // bounce up
        let tilt = sin(phase * 0.5) * 2.5  // playful tilt
        let cx = 125.0, cy = 125.0

        var svg = playingSVG
        if eyesClosed {
            svg = makeBlink(svg: svg, eyePaths: playingEyePaths, closedEyes: playingClosedEyes)
        }
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: "(https://quiver.ai) -->\n<g transform=\"translate(0, \(f(bounceY))) rotate(\(f(tilt)), \(f(cx)), \(f(cy)))\">"
        )
        svg = svg.replacingOccurrences(of: "<defs>", with: "</g>\n<defs>")
        return svg
    }

    // Bathing frame: gentle bob in the tub
    private static func makeBathingFrame(phase: Double) -> String {
        let bobY = sin(phase) * 1.5  // gentle bob
        let wobble = sin(phase + .pi / 3) * 0.8  // slight tilt

        var svg = bathingSVG
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: "(https://quiver.ai) -->\n<g transform=\"translate(0, \(f(bobY))) rotate(\(f(wobble)), 125, 125)\">"
        )
        svg = svg.replacingOccurrences(of: "</svg>", with: "</g>\n</svg>")
        return svg
    }

    // Sick frame: shivering + breathing
    private static func makeSickFrame(phase: Double) -> String {
        let shiver = sin(phase * 4) * 1.0  // fast small shiver
        let breathY = sin(phase) * 1.0
        var svg = sickSVG
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: "(https://quiver.ai) -->\n<g transform=\"translate(\(f(shiver)), \(f(breathY)))\">"
        )
        svg = svg.replacingOccurrences(of: "</svg>", with: "</g>\n</svg>")
        return svg
    }

    // Celebrating frame: bouncy + tilt
    private static func makeCelebratingFrame(phase: Double) -> String {
        let bounceY = abs(sin(phase)) * -3.0
        let tilt = sin(phase * 0.5) * 2.0
        var svg = celebratingSVG
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: "(https://quiver.ai) -->\n<g transform=\"translate(0, \(f(bounceY))) rotate(\(f(tilt)), 125, 125)\">"
        )
        svg = svg.replacingOccurrences(of: "</svg>", with: "</g>\n</svg>")
        return svg
    }

    // Crying frame: gentle sobbing bob
    private static func makeCryingFrame(phase: Double) -> String {
        let sobY = sin(phase * 2) * 1.5  // sobbing rhythm
        let tilt = sin(phase) * 1.0  // head tilt
        var svg = cryingSVG
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: "(https://quiver.ai) -->\n<g transform=\"translate(0, \(f(sobY))) rotate(\(f(tilt)), 100, 100)\">"
        )
        svg = svg.replacingOccurrences(of: "</svg>", with: "</g>\n</svg>")
        return svg
    }

    // Lonely sitting frame: very slow gentle breathing
    private static func makeLonelySittingFrame(phase: Double) -> String {
        let breathY = sin(phase) * 0.8
        var svg = lonelySittingSVG
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: "(https://quiver.ai) -->\n<g transform=\"translate(0, \(f(breathY)))\">"
        )
        svg = svg.replacingOccurrences(of: "</svg>", with: "</g>\n</svg>")
        return svg
    }

    // Standing frame: gentle breathing + slight sway
    private static func makeStandingFrame(phase: Double) -> String {
        let breathY = sin(phase) * 1.0
        let sway = sin(phase * 0.5) * 0.5
        var svg = standingSVG
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: "(https://quiver.ai) -->\n<g transform=\"translate(0, \(f(breathY))) rotate(\(f(sway)), 100, 100)\">"
        )
        svg = svg.replacingOccurrences(of: "</svg>", with: "</g>\n</svg>")
        return svg
    }

    // Eating chomp: translate face elements down toward bowl
    private static func makeEatingChomp(eyesClosed: Bool) -> String {
        var svg = eatingSVG
        // Wrap face elements in a translate-down group
        for facePath in eatingFacePaths {
            svg = svg.replacingOccurrences(of: facePath,
                with: "<g transform=\"translate(0, 6)\">\(facePath)</g>")
        }
        if eyesClosed {
            svg = makeBlink(svg: svg, eyePaths: eatingEyePaths, closedEyes: eatingClosedEyesDown)
        }
        return svg
    }

    // Generic blink: remove eye paths, add closed-eye curves
    private static func makeBlink(svg: String, eyePaths: [String], closedEyes: String) -> String {
        var result = svg
        for ep in eyePaths {
            result = result.replacingOccurrences(of: ep, with: "")
        }
        result = result.replacingOccurrences(of: "</svg>", with: "\(closedEyes)\n</svg>")
        return result
    }

    // MARK: - Blink timing

    private func shouldBlink(frame: Int) -> Bool {
        let cycle = frame % 90
        return cycle >= 86 // blink for ~4 frames out of 90 (~3 sec at 30fps)
    }

    // MARK: - Pose mapping

    private func poseFor(_ behavior: PetBehavior) -> CatPose {
        switch behavior {
        case .idle, .sitting, .lookingAtCursor, .grooming, .pooping,
             .openingGift, .knockingGlass:
            return .sitting
        case .greeting, .watchingBird:
            return .standing
        case .lonelySitting:
            return .lonelySitting
        case .walking, .edgeWalking, .running, .chasingCursor,
             .chasingToy, .zoomies, .chasingButterfly, .promenade:
            return .walking
        case .eating:
            return .eating
        case .sleeping:
            return .sleeping
        case .beingPet:
            return .held
        case .bathing:
            return .bathing
        case .scratching:
            return .angry
        case .sick:
            return .sick
        case .jumping, .flying, .stretching:
            return .jumping
        case .playing, .tripping:
            return .playing
        case .clingingEdge:
            return .climbing
        case .dead:
            return .dead
        case .celebrating:
            return .celebrating
        case .crying:
            return .crying
        }
    }

    // MARK: - Sprite selection

    func getSprite(for behavior: PetBehavior, frame: Int, right: Bool) -> NSImage {
        let pose = poseFor(behavior)
        let walkPhase = frame % 20
        let blink = shouldBlink(frame: frame) && pose != .sleeping
        let eatPhase = (frame / 5) % 2  // chomp every 5 anim frames
        let key = "cat_\(behavior.rawValue)_\(walkPhase)_\(right)_\(blink)_\(eatPhase)"
        if behavior != .lookingAtCursor, let cached = cache[key] { return cached }

        let base: NSImage
        switch pose {
        case .sitting where behavior == .lookingAtCursor:
            // Eye tracking: shift pupils toward cursor
            let mousePos = NSEvent.mouseLocation
            let dx = mousePos.x - petScreenCenter.x
            let dy = mousePos.y - petScreenCenter.y
            let dist = max(sqrt(dx * dx + dy * dy), 1.0)
            let maxOffset = 5.0  // max pupil shift in SVG units
            let scale = min(dist / 80.0, 1.0) * maxOffset
            let pupilDX = (dx / dist) * scale
            let pupilDY = -(dy / dist) * scale  // SVG Y is inverted
            let sittingPhase = frame % 16
            let svg = CatRenderer.makeCursorTrackingFrame(
                phase: Double(sittingPhase) / 16.0 * .pi * 2.0,
                pupilDX: pupilDX, pupilDY: pupilDY
            )
            base = renderSVG(svg)
        case .sitting:
            let sittingPhase = frame % 16
            base = blink ? sittingFramesClosed[sittingPhase] : sittingFramesOpen[sittingPhase]
        case .walking:
            base = blink ? walkFramesClosed[walkPhase] : walkFramesOpen[walkPhase]
        case .eating:
            if eatPhase == 0 {
                base = blink ? eatingClosed : eatingOpen
            } else {
                base = blink ? eatingChompClosed : eatingChompOpen
            }
        case .sleeping:
            let sleepPhase = frame % 16
            base = sleepingFrames[sleepPhase]
        case .held:
            let heldPhase = frame % 16
            base = blink ? heldFramesClosed[heldPhase] : heldFramesOpen[heldPhase]
        case .angry:
            let angryPhase = frame % 12
            base = blink ? angryFramesClosed[angryPhase] : angryFramesOpen[angryPhase]
        case .jumping:
            base = jumpingImage
        case .playing:
            let playPhase = frame % 16
            base = blink ? playingFramesClosed[playPhase] : playingFramesOpen[playPhase]
        case .clinging:
            let clingPhase = frame % 16
            base = blink ? climbingFramesClosed[clingPhase] : climbingFramesOpen[clingPhase]
        case .climbing:
            let climbPhase = frame % 16
            base = blink ? climbingFramesClosed[climbPhase] : climbingFramesOpen[climbPhase]
        case .bathing:
            let bathPhase = frame % 16
            base = bathingFrames[bathPhase]
        case .sick:
            let sickPhase = frame % 16
            base = sickFrames[sickPhase]
        case .dead:
            base = deadImage
        case .celebrating:
            let celPhase = frame % 16
            base = celebratingFrames[celPhase]
        case .crying:
            let cryPhase = frame % 16
            base = cryingFrames[cryPhase]
        case .lonelySitting:
            let lonelyPhase = frame % 16
            base = lonelySittingFrames[lonelyPhase]
        case .standing:
            let standPhase = frame % 16
            base = standingFrames[standPhase]
        }

        let img = applyTransforms(base: base, behavior: behavior, pose: pose, frame: frame, right: right)
        cacheInsert(key, img)
        return img
    }

    // MARK: - Transform application (bounce, squash, flip)

    private func applyTransforms(base: NSImage, behavior: PetBehavior, pose: CatPose, frame: Int, right: Bool) -> NSImage {
        let isHeld = pose == .held
        let outW = size
        let outH = isHeld ? CatRenderer.heldHeight : size
        let output = NSImage(size: NSSize(width: outW, height: outH))
        output.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            output.unlockFocus()
            return output
        }
        ctx.setShouldAntialias(true)
        ctx.setAllowsAntialiasing(true)
        ctx.saveGState()

        // Flip for direction (SVG character faces left by default)
        if right {
            ctx.translateBy(x: outW, y: 0)
            ctx.scaleBy(x: -1, y: 1)
        }

        var bounce: CGFloat = 0
        var squashX: CGFloat = 1.0, squashY: CGFloat = 1.0
        var tilt: CGFloat = 0

        switch pose {
        case .walking:
            let t = Double(frame % 20) / 20.0 * .pi * 2.0
            bounce = CGFloat(abs(sin(t))) * 4
            tilt = CGFloat(sin(t)) * 0.03
            // Subtle squash on each step
            let stepPhase = CGFloat(sin(t * 2))
            squashX = 1.0 + stepPhase * 0.02
            squashY = 1.0 - stepPhase * 0.02
            let isRunning = behavior == .running || behavior == .chasingCursor ||
                behavior == .zoomies || behavior == .chasingButterfly || behavior == .chasingToy
            if isRunning { bounce *= 1.5; tilt *= 1.5; squashX = 1.0 + stepPhase * 0.04; squashY = 1.0 - stepPhase * 0.04 }
        case .eating:
            let t = Double(frame) * 0.6
            bounce = CGFloat(sin(t)) * 2
            // Chomping squash
            let chomp = CGFloat(sin(Double(frame) * 1.2))
            squashX = 1.0 + chomp * 0.02
            squashY = 1.0 - chomp * 0.02
        case .sleeping:
            break  // breathing is now SVG-level
        case .sitting:
            break  // breathing + tail wag are now SVG-level
        case .held:
            // Held by scruff — rendered in taller frame, minimal extra transform
            // SVG-level animation already handles sway/bob
            break
        case .angry:
            break  // trembling is now SVG-level
        case .jumping:
            if behavior == .stretching {
                // Slow stretch animation — lean forward, elongate
                let stretchT = Double(frame) * 0.15
                let stretchPhase = sin(stretchT)
                squashX = CGFloat(0.92 + stretchPhase * 0.08)  // narrow when stretched
                squashY = CGFloat(1.0 + abs(stretchPhase) * 0.1) // taller when stretching
                tilt = CGFloat(sin(stretchT * 0.7)) * 0.06      // slow lean
                bounce = CGFloat(abs(stretchPhase)) * 3          // rise up during stretch
            } else {
                // Regular jump — animated squash/stretch cycle
                let jumpT = sin(Double(frame) * 0.4)
                if jumpT > 0.3 {
                    squashX = 0.90; squashY = 1.12
                } else if jumpT < -0.3 {
                    squashX = 1.06; squashY = 0.94
                } else {
                    squashX = 1.03; squashY = 0.97
                }
                tilt = CGFloat(sin(Double(frame) * 0.5)) * 0.04
            }
        case .playing:
            break  // bounce + tilt are now SVG-level
        case .bathing:
            break  // bob + wobble are now SVG-level
        case .sick:
            break  // shivering is now SVG-level
        case .dead:
            break  // static pose
        case .celebrating:
            break  // bounce + tilt are now SVG-level
        case .crying:
            break  // sobbing bob is now SVG-level
        case .lonelySitting:
            break  // breathing is SVG-level
        case .standing:
            break  // breathing + sway are SVG-level
        case .clinging, .climbing:
            // Cat climbing up edge — rotate 90° with scramble animation (SVG-level)
            let t = Double(frame) * 0.6
            let swing = CGFloat(sin(t)) * 0.06       // subtle wobble
            let scramble = CGFloat(sin(t * 2.5)) * 1.5 // quick paw scramble offset

            let cx = size / 2, cy = size / 2
            ctx.translateBy(x: cx, y: cy)
            // On right edge: cat faces right, rotate so head points up
            // On left edge: cat faces left, rotate so head points up
            if right {
                ctx.rotate(by: .pi / 2 + swing)
            } else {
                ctx.rotate(by: -.pi / 2 + swing)
            }
            ctx.translateBy(x: -cx, y: -cy + scramble)

            base.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
                      from: NSRect(origin: .zero, size: base.size),
                      operation: .sourceOver, fraction: 1.0)

            ctx.restoreGState()
            output.unlockFocus()
            return output
        }

        let cx = outW / 2, cy = outH / 2
        ctx.translateBy(x: 0, y: bounce)
        ctx.translateBy(x: cx, y: cy)
        if squashX != 1.0 || squashY != 1.0 { ctx.scaleBy(x: squashX, y: squashY) }
        if tilt != 0 { ctx.rotate(by: tilt) }
        ctx.translateBy(x: -cx, y: -cy)

        base.draw(in: NSRect(x: 0, y: 0, width: outW, height: outH),
                  from: NSRect(origin: .zero, size: base.size),
                  operation: .sourceOver, fraction: 1.0)

        ctx.restoreGState()
        output.unlockFocus()
        return output
    }

    // MARK: - SVG path identifiers for animation

    // Walking SVG: front leg path (near side)
    private static let walkFrontLeg = ##"  <path d="m71.99 176.1c-8.01 10.06-12.18 13.07-11.97 24.04 0.16 8 4.51 12.07 10.44 11.35 7.46-0.91 7.73-6.45 9.45-11.4 0.97-2.1 5.97-3.3 12.87-8.89l0.66-2.03-18.33-14.16-3.12 1.09z" fill="#E08858" stroke="#E08858" stroke-miterlimit="10" stroke-width=".25"/>"##

    // Walking SVG: back leg path (near side)
    private static let walkBackLeg = ##"  <path d="m135.1 193.2c1.27 3.52 1.16 6.86 0.05 8.25-2.98 2.89-4.36 7.15-2.47 10.11 2.58 3.39 13.34 2.82 18.49 1.02 4.83-1.67 7.82-10.45 9.5-13.34l-8.23-8.19-17.34 2.15z" fill="#E08858" stroke="#E08858" stroke-miterlimit="10" stroke-width=".25"/>"##

    // Walking SVG: far-side front leg (darker, offset -8px left)
    private static let walkFarFrontLeg = ##"  <path id="farFrontLeg" d="m63.99 176.1c-8.01 10.06-12.18 13.07-11.97 24.04 0.16 8 4.51 12.07 10.44 11.35 7.46-0.91 7.73-6.45 9.45-11.4 0.97-2.1 5.97-3.3 12.87-8.89l0.66-2.03-18.33-14.16-3.12 1.09z" fill="#D07848" stroke="#D07848" stroke-miterlimit="10" stroke-width=".25"/>"##

    // Walking SVG: far-side back leg (darker, offset -8px left)
    private static let walkFarBackLeg = ##"  <path id="farBackLeg" d="m127.1 193.2c1.27 3.52 1.16 6.86 0.05 8.25-2.98 2.89-4.36 7.15-2.47 10.11 2.58 3.39 13.34 2.82 18.49 1.02 4.83-1.67 7.82-10.45 9.5-13.34l-8.23-8.19-17.34 2.15z" fill="#D07848" stroke="#D07848" stroke-miterlimit="10" stroke-width=".25"/>"##

    // Walking SVG: tail path
    private static let walkTailPath = ##"  <path d="m172 129.3c11.2 3.68 17.25 12.83 25.06 22.23 7.71 9.24 16.86 15.64 31.04 14.71 8.9-0.6 12.7 0.33 15.58 5.67 2.93 5.48 1.09 11.91-7.67 14.81-12.11 4.16-27.94 1.05-39.81-12-9.14-10.3-13.22-16.49-17.52-17.7l-6.68-27.72z" fill="#E08858" stroke="#E08858" stroke-miterlimit="10" stroke-width=".25"/>"##

    // Walking SVG: eye paths (to remove for blink)
    private static let walkEyePaths = [
        ##"  <path d="m45.32 92.86c-9.67 0-16.78 9.39-16.57 19.65s7.16 16.78 16.16 16.78c9.53 0 16.08-9.49 16.08-18.67 0-8.88-6.29-17.76-15.67-17.76z" fill="#FEFFFE" stroke="#FEFFFE" stroke-miterlimit="10" stroke-width=".25"/>"##,
        ##"  <path d="m40.72 97.81c-7.21 0-11.86 7.95-11.5 15.88 0.32 8.06 5.42 13.86 10.73 13.65 6.95-0.26 10.46-8.62 10.46-14.73 0-7.26-4.29-14.8-9.69-14.8z" fill="#2D2D2D" stroke="#2D2D2D" stroke-miterlimit="10" stroke-width=".25"/>"##,
        ##"  <path d="m36.01 102.7c-1.73 1.38-2.09 3.51-0.79 4.95 1.57 1.75 3.62 1.07 4.19 0.4 1.52-1.28 1-3.7 0.08-4.63-1.03-1.08-2.44-1.38-3.48-0.72z" fill="#FEFFFE" stroke="#FEFFFE" stroke-miterlimit="10" stroke-width=".25"/>"##,
    ]
    // Walking SVG: closed eye replacement
    private static let walkClosedEyes = ##"  <path d="M28,108 Q44,94 60,108" stroke="#2D2D2D" stroke-width="3.5" fill="none" stroke-linecap="round"/>"##

    // Sitting SVG: eye paths (right eye white, pupil, highlight; left eye white, pupil, highlight)
    private static let sittingEyePaths = [
        ##"  <path d="m171.8 82.11c-14.8 0-25.47 14.8-25.47 28.21 0 14.39 10.87 24.62 24.92 24.62 14.46 0 25.6-12.02 25.6-26.14 0-13.89-11-26.69-25.05-26.69z" fill="#fff"/>"##,
        ##"  <path d="m166.9 89.41c-11.6 0-20.15 11-20.15 21.5 0 11.4 8.69 20.54 19.69 20.54 11.15 0 19.7-11.01 19.7-21.37 0-10.77-8.41-20.67-19.24-20.67z" fill="#2D2D2D"/>"##,
        ##"  <path d="m161.5 95.12c-4.3 0-5.75 3.21-5.75 5.51 0 3.53 2.81 5.62 5.34 5.62 3.68 0 5.85-2.9 5.85-5.44 0-3.1-2.4-5.69-5.44-5.69z" fill="#fff"/>"##,
        ##"  <path d="m76.41 82.11c14.53-0.9 26.3 12.66 26.3 26.69 0 13.89-11.15 26.35-25.61 26.35-14.05 0-25.05-12.02-25.05-26.14 0-13.41 9.86-26.9 24.36-26.9z" fill="#fff"/>"##,
        ##"  <path d="m82.92 89.27c11.01 0 19.24 10.77 19.24 21.78 0 11.4-8.69 20.54-19.24 20.54s-20.15-10.16-20.15-20.99c0-11.54 9.35-21.33 20.15-21.33z" fill="#2D2D2D"/>"##,
        ##"  <path d="m87.84 95.12c4.3 0 5.75 3.21 5.75 5.51 0 3.53-2.81 5.62-5.34 5.62-3.68 0-5.85-2.9-5.85-5.44 0-3.1 2.4-5.69 5.44-5.69z" fill="#fff"/>"##,
    ]
    // Sitting SVG: closed eyes (happy ^^ style)
    private static let sittingClosedEyes = """
      <path d="M150,108 Q170,90 190,108" stroke="#2D2D2D" stroke-width="4" fill="none" stroke-linecap="round"/>
      <path d="M58,108 Q80,90 100,108" stroke="#2D2D2D" stroke-width="4" fill="none" stroke-linecap="round"/>
    """

    // Eating SVG: eye paths
    private static let eatingEyePaths = [
        ##"  <path d="m49.98 136.9c-10.17 0-16.3 9.72-16.3 17.08 0 9.76 8.23 16.64 16.76 16.64 9.82 0 15.38-7.68 15.38-15.57 0-8.99-6.85-18.15-15.84-18.15z" fill="#FEFFFE"/>"##,
        ##"  <path d="m109.7 136.9c-10.18 0-16.3 9.72-16.3 18.72 0 9.76 6.94 14.51 14.47 14.51 9.19 0 17.13-8.49 17.13-16.94 0-8.49-7.08-16.29-15.3-16.29z" fill="#FEFFFE"/>"##,
        ##"  <path d="m52.79 145.1c-8.53 0-12.82 7.94-12.82 13.02 0 7.39 5.74 12 11.81 12 7.85 0 13.21-6.44 13.21-12.47 0-6.73-5.6-12.55-12.2-12.55z" fill="#2B2A29"/>"##,
        ##"  <path d="m106.6 145.1c-7.85 0-11.9 6.5-11.9 12.99 0 7.39 6.08 12.03 11.9 12.03 7.12 0 11.97-6.44 11.97-12.03 0-6.93-5.87-12.99-11.97-12.99z" fill="#2B2A29"/>"##,
        ##"  <path d="m58.01 149.4c-2.72 0-3.47 1.91-3.47 3.73 0 2.37 1.84 3.95 3.68 3.95 2.46 0 3.93-2.09 3.93-4 0-2.1-1.79-3.68-4.14-3.68z" fill="#FEFFFE"/>"##,
        ##"  <path d="m101.9 149.4c-2.72 0-3.96 1.91-3.96 3.73 0 2.37 1.84 3.53 3.26 3.53 2.46 0 4.3-1.67 4.3-3.58 0-2.1-1.28-3.68-3.6-3.68z" fill="#FEFFFE"/>"##,
    ]
    // Eating SVG: closed eyes
    private static let eatingClosedEyes = """
      <path d="M36,157 Q52,143 68,157" stroke="#2B2A29" stroke-width="3.5" fill="none" stroke-linecap="round"/>
      <path d="M92,157 Q108,143 124,157" stroke="#2B2A29" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    """
    // Eating SVG: closed eyes shifted down for chomp frame
    private static let eatingClosedEyesDown = """
      <path d="M36,163 Q52,149 68,163" stroke="#2B2A29" stroke-width="3.5" fill="none" stroke-linecap="round"/>
      <path d="M92,163 Q108,149 124,163" stroke="#2B2A29" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    """
    // Eating SVG: face paths to translate down for chomp
    private static let eatingFacePaths: [String] = {
        var paths = eatingEyePaths
        paths.append(##"  <path d="m35.1 168.7c-3.72 0.97-5 4.08-2.18 6.27 3.27 2.61 5.99 3.21 9.06 2.7 4.15-0.7 4.53-3.02 3.43-5.85-1.24-3.26-5.72-4.18-10.31-3.12z" fill="#FFE4CC"/>"##)
        paths.append(##"  <path d="m125.2 168.1c-5.17 0.65-7.89 3.32-7.89 5.79 0 2.46 1.84 3.67 4.76 3.67 4.24 0 9.14-3.21 9.41-5.93 0.28-2.71-2.18-4.01-6.28-3.53z" fill="#FFE4CC"/>"##)
        paths.append(##"  <path d="m75.06 166.3c-2.22 0.7-3.23 2.79-1.34 5.21s3.45 3.58 6.17 3.58c3.46 0 6.18-2 6.93-5.07 0.61-2.42-1.08-3.72-3.9-3.95-2.36-0.23-5.38-0.51-7.86 0.23z" fill="#FF91A4"/>"##)
        paths.append(##"  <path d="m78.91 175.1 1.51-0.18 1.7 0.18c0 3.06 1.65 4.08 3.87 4.08 2.62 0 3.09-2.76 4.28-3.13 1.01-0.33 1.92 0.55 1.41 1.98-1.06 2.42-3.67 4.09-5.98 3.81-1.98-0.23-3.53-1.15-4.45-2.73-1.19 1.67-2.66 2.5-4.88 2.73-3.02 0.28-5.59-1.16-7.29-4.18-0.7-1.36 0.45-2.28 1.46-1.91 1.47 0.55 2.08 3.43 5.35 3.43 2.22 0 3.02-1.48 3.02-4.08z" fill="#294916"/>"##)
        return paths
    }()

    // MARK: - Pixel Sprite Helpers (used for items)


    static let poop: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x6B4226, L: UInt32 = 0x8B5E3C, H: UInt32 = 0xA0724D
        return [
            [T,T,T,H,T,T,T],
            [T,T,H,L,H,T,T],
            [T,H,L,B,L,H,T],
            [H,L,B,B,B,L,H],
            [T,H,B,B,B,H,T],
            [T,T,H,H,H,T,T],
        ]
    }()

    static let paw: [[UInt32]] = {
        let T: UInt32 = 0, P: UInt32 = 0xFFC8A2
        return [
            [T,T,P,T,T],
            [T,P,T,P,T],
            [T,T,T,T,T],
            [T,P,P,P,T],
            [T,P,P,P,T],
            [T,T,P,T,T],
        ]
    }()

    static let glass: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0xAADDFF, GD: UInt32 = 0x88BBDD
        return [
            [T,T,T,T,T,T,T,T],
            [T,T,B,B,B,B,T,T],
            [T,B,G,G,G,G,B,T],
            [T,B,G,GD,G,G,B,T],
            [T,B,G,G,G,G,B,T],
            [T,T,B,G,G,B,T,T],
            [T,T,B,G,G,B,T,T],
            [T,T,T,B,B,T,T,T],
        ]
    }()

    static func render(_ sprite: [[UInt32]], scale: Int = 5) -> NSImage {
        let w = sprite[0].count
        let h = sprite.count
        let imgW = w * scale
        let imgH = h * scale
        let image = NSImage(size: NSSize(width: imgW, height: imgH))
        image.lockFocus()
        NSColor.clear.set()
        NSRect(x: 0, y: 0, width: imgW, height: imgH).fill()
        for row in 0..<h {
            for col in 0..<w {
                let hex = sprite[row][col]
                guard hex != 0 else { continue }
                let r = CGFloat((hex >> 16) & 0xFF) / 255.0
                let g = CGFloat((hex >> 8) & 0xFF) / 255.0
                let b = CGFloat(hex & 0xFF) / 255.0
                NSColor(red: r, green: g, blue: b, alpha: 1.0).set()
                let rect = NSRect(
                    x: col * scale,
                    y: (h - 1 - row) * scale,
                    width: scale,
                    height: scale
                )
                rect.fill()
            }
        }
        image.unlockFocus()
        return image
    }

    static func renderMirrored(_ sprite: [[UInt32]], scale: Int = 5) -> NSImage {
        let mirrored = sprite.map { Array($0.reversed()) }
        return render(mirrored, scale: scale)
    }

    // MARK: - SVG Data

    static let sittingSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="250" height="250" fill="none" viewBox="0 0 250 250">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m161.5 33.27c15.41-13.14 34.6-21.99 52.49-22.26 8.22-0.13 11.32 2.97 12.91 11.05 3.67 19.2 1.44 46-5.14 69.55l-60.26-58.34z" fill="url(#paint0_linear_2043_11400)"/>
      <path d="m179.1 41.12c11.74-7.16 20.74-12.94 27.1-11.85 10.74 1.96 5.45 26.07 2.05 38.45l-29.15-26.6z" fill="#FFE4CC"/>
      <path d="m87.17 32.92c-15.56-13.06-34.69-21.61-51.76-21.64-7.55-0.01-10.64 2.59-12.6 10.67-4.06 17.06-2.78 43.34 4.14 69.12l60.22-58.15z" fill="url(#paint1_linear_2043_11400)"/>
      <path d="m70.01 40.63c-11.63-6.4-20.65-10.61-27-11.5-10.74-1.45-7.4 21.05-3.4 38.73l30.4-27.23z" fill="#FFE4CC"/>
      <path d="m226.4 117.7h13c3.33 0 3.97 2.36 3.97 3.99 0 1.96-1.44 3.55-3.97 3.62l-13 0.49c-4.44 0.27-6.26-0.93-6.26-3.9 0-2.68 1.59-4.2 6.26-4.2z" fill="url(#paint2_linear_2043_11400)"/>
      <path d="m222.7 135 13.21 4.44c2.9 1.06 2.83 3.08 2.26 4.9-0.69 2.23-2.71 2.79-5.25 2.03l-13.48-3.77c-3.4-1.13-4.74-2.88-3.92-5.42 0.89-2.74 3.43-3.38 7.18-2.18z" fill="url(#paint3_linear_2043_11400)"/>
      <path d="m175.1 198.6c16.19-2.24 23.89-17.58 34.9-24.3 13.07-7.16 21.62 3.48 23.64 11.03 3.75 13.89-8.82 27.78-25.01 32.28-12.16 4.12-21.16 4.61-30.98 4.61l-2.55-23.62z" fill="url(#paint4_linear_2043_11400)"/>
      <path d="m82.92 178.1c-10.09 17.68-13.84 37.89-10.87 48.19 2.67 9.35 12.36 9.35 27.7 7.9l4.51-1.45 41.65 0.96c11.01 2.4 27.07 1.94 30.28-4.41 4.51-9-0.51-32.07-8.48-51.6l-39.53-5.85-45.26 6.26z" fill="url(#paint5_linear_2043_11400)"/>
      <path d="m72.71 225.8c2.02-8.69 10-10.71 19.82-9.64l0.42-6.07c0.42 7.98 2.96 18.21 8.8 24.06-10.5 2.02-26.64 3.01-29.04-8.35z" fill="url(#paint6_linear_2043_11400)"/>
      <path d="m156.7 216.1c8.41-0.42 17.23 1.6 20.13 8.83 0.89 8.44-6.66 10.33-19.72 9.77-3.4-0.14-6.93-0.77-9.61-2.08 5.42-4.51 8.17-11.37 9.61-23.53l-0.41 7.01z" fill="url(#paint7_linear_2043_11400)"/>
      <path d="m82.03 180.2c0.76-1.59 1.52-3.03 2.35-4.55l83.33 1.31 1.13 3.59c-20.73 6.49-60.98 7.62-86.81-0.35z" fill="url(#paint8_linear_2043_11400)"/>
      <path d="m123.7 26.71c-58.47 0-101.4 39.02-101.4 90.51 0 36.44 25.83 57.64 68.02 60.38 9.69 1.23 23.79 1.51 33.88 1.51 11.22 0 22.82-0.92 32.51-2.05 41.11-3.9 69.91-22.2 69.91-59.84 0-45.77-40.02-90.51-102.9-90.51z" fill="url(#paint9_linear_2043_11400)"/>
      <path d="m171.8 82.11c-14.8 0-25.47 14.8-25.47 28.21 0 14.39 10.87 24.62 24.92 24.62 14.46 0 25.6-12.02 25.6-26.14 0-13.89-11-26.69-25.05-26.69z" fill="#fff"/>
      <path d="m166.9 89.41c-11.6 0-20.15 11-20.15 21.5 0 11.4 8.69 20.54 19.69 20.54 11.15 0 19.7-11.01 19.7-21.37 0-10.77-8.41-20.67-19.24-20.67z" fill="#2D2D2D"/>
      <path d="m161.5 95.12c-4.3 0-5.75 3.21-5.75 5.51 0 3.53 2.81 5.62 5.34 5.62 3.68 0 5.85-2.9 5.85-5.44 0-3.1-2.4-5.69-5.44-5.69z" fill="#fff"/>
      <path d="m76.41 82.11c14.53-0.9 26.3 12.66 26.3 26.69 0 13.89-11.15 26.35-25.61 26.35-14.05 0-25.05-12.02-25.05-26.14 0-13.41 9.86-26.9 24.36-26.9z" fill="#fff"/>
      <path d="m82.92 89.27c11.01 0 19.24 10.77 19.24 21.78 0 11.4-8.69 20.54-19.24 20.54s-20.15-10.16-20.15-20.99c0-11.54 9.35-21.33 20.15-21.33z" fill="#2D2D2D"/>
      <path d="m87.84 95.12c4.3 0 5.75 3.21 5.75 5.51 0 3.53-2.81 5.62-5.34 5.62-3.68 0-5.85-2.9-5.85-5.44 0-3.1 2.4-5.69 5.44-5.69z" fill="#fff"/>
      <path d="m124.4 117.2c-7.16 0-10.62 1.45-10.62 5.09 0 3.71 6.36 9.42 10.62 9.42 4.58 0 10.8-6.72 10.8-9.42 0-3.64-4-5.09-10.8-5.09z" fill="#FF91A4"/>
      <path d="m107.1 133.8c-1.66 0.49-1.66 2.31-1.03 3.86 2.68 5.56 10.44 7.58 15.46 5.56 1.3-0.56 2.33-1.31 3.09-2.31 1.69 2.55 4.53 3.28 7.57 2.96 5.78-0.65 10.66-4.91 11.15-7.76 0.21-1.37-0.78-2.65-2.23-2.45-1.75 0.28-1.89 2.03-3.02 3.3-1.89 2.16-4.29 2.61-6.72 2.16-3.33-0.69-3.75-3.01-3.75-6.41h-4.85c0 2.67-0.14 5.41-3.11 6.41-3.04 1.06-6.93-0.14-9.1-3.46-0.83-1.38-1.82-2.34-3.46-1.86z" fill="url(#paint10_linear_2043_11400)"/>
      <path d="m20.51 117.7h-9.95c-3.33 0-4.53 2.02-4.56 3.92-0.04 2.23 1.55 4.11 4.56 4.11l14.15-0.21c4.23 0 5.3-2.16 4.95-4.7-0.35-2.4-2.01-3.39-9.15-3.12z" fill="url(#paint11_linear_2043_11400)"/>
      <path d="m26.43 135.4-12.71 3.89c-2.9 1.06-2.83 3.74-2.27 5.05 1 2.43 3.02 2.64 5.28 2.08l13.76-3.97c3.4-1.13 3.82-3.37 2.92-5.7-1.06-2.54-3.9-2.4-6.98-1.35z" fill="url(#paint12_linear_2043_11400)"/>
      <path d="m196 130.1c-9 1.24-13.92 6.7-13.92 10.59 0 5.09 5.35 6.98 10.2 6.49 6.8-0.69 14.1-5.02 14.1-9.89 0-4.51-3.54-7.84-10.38-7.19z" fill="#FFE4CC"/>
      <path d="m49.81 130.6c-6.49 0.35-7.8 4.25-7.66 7.15 0.38 6.36 7.31 9.44 15.28 9.79 6.46 0.27 9.43-3.29 9.29-7.19-0.21-5.78-9.5-10.17-16.91-9.75z" fill="#FFE4CC"/>
      <path d="m121.7 211.5h5.6c-0.42 5.85-0.7 14.53 0.99 20.1 1.44 5.21 5.95 6.04 9.98 6.04 11.4 0 17.76-13.21 18.79-28.54l-0.89 7.01c-1.03 6.72-5.3 16.04-8.72 18.57-3.14 2.33-5.57 3.03-9.83 2.96-5.85-0.14-8.95-2.68-10.04-6.04h-5.38c-1.52 4.26-3.92 6.21-10.13 6.21-11.01 0-17.36-10.71-19.38-28.71l0.49 7.01c0.56 6 3.03 12.72 7.88 18 3.16 2.97 6.52 3.6 9.95 3.53 5.71-0.14 8.67-2.3 9.86-9.6 0.69-4.26 0.83-10.23 0.83-16.54z" fill="url(#paint13_linear_2043_11400)"/>
      <defs>
        <linearGradient id="paint0_linear_2043_11400" x1="173" x2="222.6" y1="17.31" y2="85.12" gradientUnits="userSpaceOnUse">
          <stop stop-color="#FFC8A2" offset="0"/>
          <stop stop-color="#E08858" offset="1"/>
        </linearGradient>
        <linearGradient id="paint1_linear_2043_11400" x1="30.6" x2="77.19" y1="16.07" y2="83.28" gradientUnits="userSpaceOnUse">
          <stop stop-color="#F0A878" offset="0"/>
          <stop stop-color="#E08858" offset="1"/>
        </linearGradient>
        <linearGradient id="paint2_linear_2043_11400" x1="231.8" x2="231.8" y1="117.7" y2="126" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#D07848" offset="1"/>
        </linearGradient>
        <linearGradient id="paint3_linear_2043_11400" x1="227.1" x2="227.1" y1="134.2" y2="146.9" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#D07848" offset="1"/>
        </linearGradient>
        <linearGradient id="paint4_linear_2043_11400" x1="192.8" x2="192.8" y1="172.2" y2="222.2" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#D07848" offset="1"/>
        </linearGradient>
        <linearGradient id="paint5_linear_2043_11400" x1="125.3" x2="125.3" y1="171.9" y2="236.2" gradientUnits="userSpaceOnUse">
          <stop stop-color="#FFC8A2" offset="0"/>
          <stop stop-color="#FFC8A2" offset="1"/>
        </linearGradient>
        <linearGradient id="paint6_linear_2043_11400" x1="87" x2="87" y1="209.1" y2="235.3" gradientUnits="userSpaceOnUse">
          <stop stop-color="#D07848" offset="0"/>
          <stop stop-color="#E08858" offset="1"/>
        </linearGradient>
        <linearGradient id="paint7_linear_2043_11400" x1="162.5" x2="162.5" y1="209.1" y2="235" gradientUnits="userSpaceOnUse">
          <stop stop-color="#D07848" offset="0"/>
          <stop stop-color="#E08858" offset="1"/>
        </linearGradient>
        <linearGradient id="paint8_linear_2043_11400" x1="125.4" x2="125.4" y1="175.7" y2="186.7" gradientUnits="userSpaceOnUse">
          <stop stop-color="#D07848" offset="0"/>
          <stop stop-color="#E08858" offset="1"/>
        </linearGradient>
        <linearGradient id="paint9_linear_2043_11400" x1="109.9" x2="130.3" y1="26.71" y2="178.9" gradientUnits="userSpaceOnUse">
          <stop stop-color="#FFC8A2" offset="0"/>
          <stop stop-color="#FFC8A2" offset="1"/>
        </linearGradient>
        <linearGradient id="paint10_linear_2043_11400" x1="124.6" x2="124.6" y1="128.9" y2="144" gradientUnits="userSpaceOnUse">
          <stop stop-color="#A0522D" offset="0"/>
          <stop stop-color="#8B4513" offset="1"/>
        </linearGradient>
        <linearGradient id="paint11_linear_2043_11400" x1="17.86" x2="17.86" y1="117.6" y2="125.7" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#D07848" offset="1"/>
        </linearGradient>
        <linearGradient id="paint12_linear_2043_11400" x1="22.44" x2="22.44" y1="134.4" y2="146.8" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#D07848" offset="1"/>
        </linearGradient>
        <linearGradient id="paint13_linear_2043_11400" x1="124.6" x2="124.6" y1="209.1" y2="237.7" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#E08858" offset="1"/>
        </linearGradient>
      </defs>
    </svg>
    """

    static let walkingSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="250" height="250" fill="none" viewBox="0 0 250 250">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m41.78 58.63c2.71-12.02 6.03-24.51 11.14-24.81 6.49-0.36 12.79 6.89 22.06 17.1l0.34 0.39-0.4-0.04-0.04 1.67-33.1 5.69z" fill="#E08858" stroke="#E08858" stroke-miterlimit="10" stroke-width=".25"/>
      <path d="m172 129.3c11.2 3.68 17.25 12.83 25.06 22.23 7.71 9.24 16.86 15.64 31.04 14.71 8.9-0.6 12.7 0.33 15.58 5.67 2.93 5.48 1.09 11.91-7.67 14.81-12.11 4.16-27.94 1.05-39.81-12-9.14-10.3-13.22-16.49-17.52-17.7l-6.68-27.72z" fill="#E08858" stroke="#E08858" stroke-miterlimit="10" stroke-width=".25"/>
    <!-- FAR_LEGS -->
      <path d="m134.7 121.9c13.43-1.03 27.52-1.13 38.44 8 11.78 9.08 12.29 22.96 10.83 33.89-0.87 6.62-3.85 14.08 1.51 19.36 4.45 1.75 5.02 4.76 8.25 11.3 2.41 4.25 1.54 7.95-0.46 13.65-2.45 5.33-5.57 7.8-8.75 6.82-4.6-1.05-5.42-7.68-7.43-10.67-1.45-2.5-4.27-1.64-11.22-3.44-7.79-2.14-15.63-7.09-16.55-8.43-7.51 1.97-17.39 2.07-29.75 2.07 0.05 6.82 0 14.6-2.55 19.04-3.12 4.01-12.5 4.63-17.22 3.51-3.9-1.23-5.01-4.9-2.8-9.11 0.82-1.19 0.72-1.19 0.15-3.16-1.25-4.96-3.15-11.62-4.41-13.42-11.57-4.4-21.71-9.83-27.02-28.61-23.5-0.3-55.5-6.73-57.5-35.59-0.26-9.61 6.08-10.44 6.24-21.1 0.16-19.84 8.54-39.99 30.26-49.76 9.28-4.15 18.41-5.9 29.83-5.7 4.6 0.1 15.67 1.24 23.95 5.49 20.35 8.47 35.93 23.72 36.6 56 0.05 3.67-0.11 5.94-0.4 9.86z" fill="#FFC8A2" stroke="#FFC8A2" stroke-miterlimit="10" stroke-width=".25"/>
    <!-- OVERLAY_LEGS -->
      <path d="m135.4 122.2c-4.65 20.6-20.94 39.8-56.74 45.13-3.9 0.41-6.93 0.87-12.53-0.46l-0.57-4.01c11.57-0.05 35.33-0.86 50.45-15.18 11.21-9.38 17.21-17.57 18.78-25.78l0.61 0.3z" fill="#E08858" stroke="#E08858" stroke-miterlimit="10" stroke-width=".25"/>
      <path d="m114.4 67.69c-2.72-12.21-6.67-22.67-16.65-33.97-3.51-3.11-6.28-2.91-8.33-1.22-4.4 3.48-8.64 12.31-15.54 22.62-1.79 4.74-1.74 9.05 2.06 14.28 8.66 11.52 18.04 17.65 28.23 14.36 7.94-3.29 11.94-8.93 10.23-16.07z" fill="#E08858" stroke="#E08858" stroke-miterlimit="10" stroke-width=".25"/>
      <path d="m92.16 47.81c-2.05-3.67-5.23-2.08-6.64 0.92-3.56 5.79-6.69 10.92-6.18 13.97 0.47 4.16 8.8 11.72 11.57 12.75 3.34 1.23 3.91-5.44 3.03-16.31-0.52-4.01-1.09-8.52-1.78-11.33z" fill="#FFE4CC" stroke="#FFE4CC" stroke-miterlimit="10" stroke-width=".25"/>
      <path d="m45.32 92.86c-9.67 0-16.78 9.39-16.57 19.65s7.16 16.78 16.16 16.78c9.53 0 16.08-9.49 16.08-18.67 0-8.88-6.29-17.76-15.67-17.76z" fill="#FEFFFE" stroke="#FEFFFE" stroke-miterlimit="10" stroke-width=".25"/>
      <path d="m40.72 97.81c-7.21 0-11.86 7.95-11.5 15.88 0.32 8.06 5.42 13.86 10.73 13.65 6.95-0.26 10.46-8.62 10.46-14.73 0-7.26-4.29-14.8-9.69-14.8z" fill="#2D2D2D" stroke="#2D2D2D" stroke-miterlimit="10" stroke-width=".25"/>
      <path d="m36.01 102.7c-1.73 1.38-2.09 3.51-0.79 4.95 1.57 1.75 3.62 1.07 4.19 0.4 1.52-1.28 1-3.7 0.08-4.63-1.03-1.08-2.44-1.38-3.48-0.72z" fill="#FEFFFE" stroke="#FEFFFE" stroke-miterlimit="10" stroke-width=".25"/>
      <path d="m6.11 120.2c0-2.56 1.68-3.38 3.14-3.38 1.84 0 5.51 0.41 6.08 2.1 0.82 2.36-3.73 8.77-5.78 8.77-2.22 0-3.44-4.01-3.44-7.49z" fill="#FF91A4" stroke="#FF91A4" stroke-miterlimit="10" stroke-width=".25"/>
      <path d="m10.01 127.7c0 4.35 1.17 8.02 5.77 8.02 4.1 0 4.97-2.27 6.28-4.38" stroke="#2D2D2D" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3"/>
      <path d="m58.72 127.6c-4.7 1.18-5.91 4.29-5.59 6.31 0.62 3.87 4.81 4.95 8.66 4.75 5.87-0.31 8.31-3.65 8.26-5.47-0.16-4.1-4.34-5.95-11.33-5.59z" fill="#FFE4CC" stroke="#FFE4CC" stroke-miterlimit="10" stroke-width=".25"/>
      <path d="m84.51 121.2 17.71-3.39" stroke="#E08858" stroke-linecap="round" stroke-miterlimit="10" stroke-width="5"/>
      <path d="m84.51 131 17.71 2.53" stroke="#E08858" stroke-linecap="round" stroke-miterlimit="10" stroke-width="5"/>
      <path d="m81.63 139.8 13.09 7.85" stroke="#E08858" stroke-linecap="round" stroke-miterlimit="10" stroke-width="5"/>
      <path d="m146.9 179.2c0 8.99 2.1 18.07 19.1 21.08" stroke="#E08858" stroke-linecap="round" stroke-miterlimit="10" stroke-width="3"/>
    </svg>
    """

    static let eatingSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="250" height="250" fill="none" viewBox="0 0 250 250">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m188 52.4c12.12 3.86 20.92 9.26 25.92 12.28 12.2 7.39 29.24 22.84 30.04 45.29 0.54 15.14-8.17 33.07-20.59 33.39-8.18 0.23-14.45-6.65-11.98-15.62 1.93-7.22 7.58-9.93 7.58-20.32 0-11.16-8.57-19.95-16.75-26.44l-14.22-6.64v-21.94z" fill="url(#paint0_linear_133_1163)"/>
      <path d="m202 60.53c5.4 4.38 7.18 12.68 4.15 18.51l-4.29-3.23-7.39-13.53-3.72-9.27c4 1.1 7.37 4.26 11.25 7.52z" fill="#F0A878"/>
      <path d="m139 30.43c-32.87 0-57.1 18.85-71.61 43.53l-4.57 8.35-3.72 2.37c-8.23-5.26-20.3-13.5-34.43-13.5-3.86 0-5.69 2.5-7.12 8.52-2.82 11.53-2.21 27.12 3.26 40.02-4.29 9.27-5.66 19.24-5.05 29.2l1.32 6.79h-8.61c-1.99 0-2.92 1.21-2.92 2.42 0 1.48 1.11 2.54 2.49 2.49l11.26-0.5 1.74 5.26-8.57 4.24c-1.27 0.65-1.65 1.91-1.13 2.97 0.61 1.26 1.99 1.35 3 0.93l8.84-3.48c3.81 5.45 6.99 9.02 11.04 12.18-3.5 4.89-5.2 9.97-3.12 13.44 2.17 3.71 7.03 4.36 13.16 3.71l3.46-9.26 6.89-1.32 7.53-1.58 9.49-1.48 13.3 1.48 16.8 1.58 10.4-1.58c5.31-2.32 11.39-5.49 17.52-8.61-0.52 3.57-3.33 9.16-2.68 14.56 0.97 6.07 5.88 7.93 12.44 7.56 7.53-0.47 12.01-3.63 15.73-11.56 5.74-12.41 7.16-25.94 5.69-42.15 4.29-2.09 6.46-3.67 9.59-6.64 3.41 4.65 6.13 11.87 3.41 19.09-2.86 4.05-3.14 10.65 1.86 13.45 3.03 1.31 10.11 1.78 14.26-0.59 7.53-4.05 9.99-14.44 11.41-25.97 0.76-6.93-2.56-10.19-3.03-13.61-0.8-6.59 4.65-19.26 4.65-38.02 0-30.61-19.91-64.29-63.98-64.29z" fill="url(#paint1_linear_133_1163)"/>
      <path d="m134.8 67.82c-10.87 0-23.08 9.22-27.74 13.12-8.94-4-22.33-6.88-41.04-3.62l-1.89 4.52c13.21-2.93 26.9-1.92 39.59 3.07-1.79 2.23-2.8 4.27-2.43 7.2 1.43 8.07 17.76 13.95 38.29 20.59 4.29-9.49 5.71-23.02 2.44-34.78-1.38-4.38-3.94-10.1-7.22-10.1z" fill="#E08858"/>
      <path d="m185.8 110.4c-3.46 16.24-10.99 24.31-24.29 33.53" stroke="#E08858" stroke-linecap="round" stroke-width="4.431"/>
      <path d="m143 118.8c6.36-11.76 7.64-34.73 0.74-45.21-4.61-6.59-11.21-6.03-20.7-1.65s-19.8 12.87-21.27 17.76c-2.46 7.93 7.03 12.82 17.38 16.87 6.74 2.77 15.48 5.38 19.82 6.53 5.74 10.79 9.74 23.74 6.77 43.4l-2.71 0.47c-2.93 0-3.9 4.75 0.85 4.75h0.76c-0.43 1.86-0.99 3.48-1.85 5.34l-3.86 0.23c-2.72 0.43-3.28 4.81 1.01 4.81l-2.31 3.31c-2.32 2.97-5.59 5.39-6.2 7.06l0.61 3.22c6.65-3.08 12.83-10.78 15.14-14.09l1.79 1.53c3.46 1.48 4.93-3.07 1.47-4.55l-2.31-1.11c0.96-2.33 1.57-3.71 2-6.37l3.02-0.52c3.72-0.43 3.39-5.32-0.66-4.89l-2.36 0.23c2.92-12.03 0-26.18-5.3-36.97l-1.83-0.15z" fill="#E08858"/>
      <path d="m134.2 75.11c-8.27-0.92-21.06 7.91-25.96 12.5-3.5 3.21-4.11 6.03 0.89 9.45 6.7 4.59 19.06 10.23 26 12.18 4.85-6.21 8.31-33.07-0.93-34.13z" fill="#F0A878"/>
      <path d="m131.2 82.31c-6.27 0-15.02 6.5-18.09 8.87 8.13 4.05 15.07 10.55 19.59 16.15 4.05-2.05 4.76-25.02-1.5-25.02z" fill="#FFE4CC"/>
      <path d="m24.71 71.18c10.3-1.11 23.23 6.48 32.07 12.07 4.05 2.67 5.33 5.6 2.87 11.19-4.05 8.49-14.54 12.2-29.64 16.58-3.46 1.06-5.92 2.92-8 5.73-5.74-10.48-5.46-30.69-2.79-39.91 0.96-3.16 2.29-5.3 5.49-5.66z" fill="#F0A878"/>
      <path d="m29.66 82.63c5.65-1.48 14.75 4.54 18.8 8.59-7.53 4.89-14.47 11.39-19.92 16.98-3.13-3.47-3.83-24.14 1.12-25.57z" fill="#FFE4CC"/>
      <path d="m49.98 136.9c-10.17 0-16.3 9.72-16.3 17.08 0 9.76 8.23 16.64 16.76 16.64 9.82 0 15.38-7.68 15.38-15.57 0-8.99-6.85-18.15-15.84-18.15z" fill="#FEFFFE"/>
      <path d="m109.7 136.9c-10.18 0-16.3 9.72-16.3 18.72 0 9.76 6.94 14.51 14.47 14.51 9.19 0 17.13-8.49 17.13-16.94 0-8.49-7.08-16.29-15.3-16.29z" fill="#FEFFFE"/>
      <path d="m52.79 145.1c-8.53 0-12.82 7.94-12.82 13.02 0 7.39 5.74 12 11.81 12 7.85 0 13.21-6.44 13.21-12.47 0-6.73-5.6-12.55-12.2-12.55z" fill="#2B2A29"/>
      <path d="m106.6 145.1c-7.85 0-11.9 6.5-11.9 12.99 0 7.39 6.08 12.03 11.9 12.03 7.12 0 11.97-6.44 11.97-12.03 0-6.93-5.87-12.99-11.97-12.99z" fill="#2B2A29"/>
      <path d="m58.01 149.4c-2.72 0-3.47 1.91-3.47 3.73 0 2.37 1.84 3.95 3.68 3.95 2.46 0 3.93-2.09 3.93-4 0-2.1-1.79-3.68-4.14-3.68z" fill="#FEFFFE"/>
      <path d="m101.9 149.4c-2.72 0-3.96 1.91-3.96 3.73 0 2.37 1.84 3.53 3.26 3.53 2.46 0 4.3-1.67 4.3-3.58 0-2.1-1.28-3.68-3.6-3.68z" fill="#FEFFFE"/>
      <path d="m35.1 168.7c-3.72 0.97-5 4.08-2.18 6.27 3.27 2.61 5.99 3.21 9.06 2.7 4.15-0.7 4.53-3.02 3.43-5.85-1.24-3.26-5.72-4.18-10.31-3.12z" fill="#FFE4CC"/>
      <path d="m125.2 168.1c-5.17 0.65-7.89 3.32-7.89 5.79 0 2.46 1.84 3.67 4.76 3.67 4.24 0 9.14-3.21 9.41-5.93 0.28-2.71-2.18-4.01-6.28-3.53z" fill="#FFE4CC"/>
      <path d="m42.26 209.2 5.83-20.25c0-5.21 14-7.72 32.89-7.72s33.4 3.52 33.4 8.72l5.83 18.68c0 6.4-17.54 10.6-39.97 10.6s-37.98-4.2-37.98-10.03z" fill="url(#paint2_linear_133_1163)"/>
      <path d="m80.98 196.6c16.91 0 32.93-3.65 32.93-7.63 0-3.99-15.1-7.25-32.01-7.25s-31.55 2.77-31.55 6.75c0 3.99 13.72 8.13 30.63 8.13z" fill="url(#paint3_linear_133_1163)"/>
      <path d="m94.71 182.2c-1.79 0-2.98 1.67-4.58 1.67-2.22 0-3.18-2.18-8.24-2.18-4.53 0-5.91 2.18-8.17 2.18-1.6 0-2.75-1.67-4.92-1.67-4.58 0-8.63 1.67-8.63 7.26l-0.56 1.16c4.61 0.97 11.41 1.55 21.32 1.55s17.99-1.58 23.69-3.06c0.6-4.19-4.25-6.91-9.91-6.91z" fill="#895830"/>
      <path d="m78.91 175.1 1.51-0.18 1.7 0.18c0 3.06 1.65 4.08 3.87 4.08 2.62 0 3.09-2.76 4.28-3.13 1.01-0.33 1.92 0.55 1.41 1.98-1.06 2.42-3.67 4.09-5.98 3.81-1.98-0.23-3.53-1.15-4.45-2.73-1.19 1.67-2.66 2.5-4.88 2.73-3.02 0.28-5.59-1.16-7.29-4.18-0.7-1.36 0.45-2.28 1.46-1.91 1.47 0.55 2.08 3.43 5.35 3.43 2.22 0 3.02-1.48 3.02-4.08z" fill="#294916"/>
      <path d="m75.06 166.3c-2.22 0.7-3.23 2.79-1.34 5.21s3.45 3.58 6.17 3.58c3.46 0 6.18-2 6.93-5.07 0.61-2.42-1.08-3.72-3.9-3.95-2.36-0.23-5.38-0.51-7.86 0.23z" fill="#FF91A4"/>
      <defs>
        <linearGradient id="paint0_linear_133_1163" x1="218.7" x2="232" y1="52.4" y2="143.9" gradientUnits="userSpaceOnUse">
          <stop stop-color="#F0A878" offset="0"/>
          <stop stop-color="#FFD0A8" offset="1"/>
        </linearGradient>
        <linearGradient id="paint1_linear_133_1163" x1="106.8" x2="121.7" y1="30.43" y2="201.6" gradientUnits="userSpaceOnUse">
          <stop stop-color="#FFD0A8" offset="0"/>
          <stop stop-color="#FFD0A8" offset="1"/>
        </linearGradient>
        <linearGradient id="paint2_linear_133_1163" x1="81.24" x2="81.24" y1="181.2" y2="219.2" gradientUnits="userSpaceOnUse">
          <stop stop-color="#A56941" offset="0"/>
          <stop stop-color="#A56941" offset="1"/>
        </linearGradient>
        <linearGradient id="paint3_linear_133_1163" x1="82.13" x2="82.13" y1="181.7" y2="196.6" gradientUnits="userSpaceOnUse">
          <stop stop-color="#B8825A" offset="0"/>
          <stop stop-color="#B8825A" offset="1"/>
        </linearGradient>
      </defs>
    </svg>
    """

    static let sleepingSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="250" height="250" viewBox="0 0 250 250">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m92.81 69.7c4.63-9.62 21.16-24.64 30.41-24.7 6.87-0.04 14.21 17.02 15.69 25.09 9.21-4.96 23.08-5.88 31.87-5.47 37.41 1.77 68.54 26.81 72.67 62.13 4.62 40.34-28.17 73.16-84.41 77.38-17.95 0.85-31.92-1.61-42.42-6.96-3.64 0.8-7.7-0.36-10.9-3.9-3.93 4.06-8.74 5.02-15.6 4.66-12.66-0.7-28.78-4.02-33.64-15.41l-0.86-2.9-9.21-5.3-6.96 2.9-9.31-37c-9.21-5.3-23.13-25.5-24.13-36.81-1-8.05 14.66-11.75 25.71-12.7 5.65-0.48 11.7-0.58 14.79-0.28 12.82-13.29 29.2-20.42 46.3-20.73z" fill="#FFC8A2"/>
      <path d="m142.7 68.03c3.02 1.66 3.31 11.06 3.46 17.23 6.96 6.62 10.93 14.35 13.01 21.52l4.43-1.28c3.45-0.69 3.85 4.42 0.67 4.94l-3.77 1.4c0.77 3.41 1.1 6.59 1.22 8.17l3.89-1.07c3.69-0.75 4.08 4.36 0.53 5.01l-4.44 0.71c-0.36 14.06-7.64 28.32-29.55 43.45l16.45 4.51c3.2-4.64 7.85-6.26 13.25-7.45-5.46-17.74 0.54-44.85 27.84-48.56 5.02-0.68 3.98 3.3 0.3 3.69-20 2.93-29.8 20.43-22.64 45.63 0.81 2.08-0.25 2.88-2.08 2.89-5.07 0.44-9.36 2.19-11.48 4.89 14.68 3.18 38.18-2.42 52.91-13.68 1.41-2.08 2.36-2.72 3.47-1.61 1.26 1.26-0.18 3.18-2.38 5.21-15.08 12.71-35.65 17.36-52.74 14.75-8.16-1.21-16.23-3.79-24.45-5.56-9.46-2.35-20.01 0.26-21.63 9.57-1.25 6.62 1.64 12.07 8.89 14.72-4.49 1.42-11.74-1.09-12.95-5.43l-0.51-3.97 0.2-4.5c-11.5 4.3-24.81 5.92-33.61 4.96-6.76-0.56-12.92-1.66-14.68-7.16l3.69 1.1c15.18 3.05 33.44-0.39 45.7-6.79 3.93-5.3 9.08-7.38 17.3-7.69 18.77-10.82 32.69-23.92 34-44.17l-2.2-0.35c-3.04-0.7-2.59-4.99 0.81-4.39l1.83 0.2c-0.15-2.8-0.75-5.15-1.45-7.5l-2.2 1.72c-2.99 1.41-4.3-3.03-1.7-4.29l2.6-1.41c-2.79-7.73-7.33-14.6-14.19-20.85 0.2-5.45-0.65-11.71-2.58-18.57 1.05-0.44 2.44-0.59 4.78 0.01z" fill="#E08858"/>
      <path d="m45.46 91.27c-6.35 6.82-13.64 17.64-16.34 34.54-6.56-5.75-12.22-15.8-12.31-19.04 0.05-4.39 5.11-4.79 10.02-5.14 4.29-0.35 9.45-0.5 11.8-0.5 1.16-2.18 3.41-5.51 6.83-9.86z" fill="#FFE4CC"/>
      <path d="m104.2 69.19c6.66-7.78 13.22-12.98 17.01-12.48 4.03 0.6 7.72 13.3 8.33 22.41-7.72-4.69-16.23-8.43-25.34-9.93z" fill="#FFE4CC"/>
      <path d="m92.71 69.44c4.91-9.26 19.28-23.83 30.62-24.44 4.71-0.27 11.57 11.96 15.46 23.12 1.67 5.25 3.33 11.71 2.93 18.02l-3.29-2.9c-2.12-1.82-4.52-3.9-8.41-6.15-0.95-8.31-5.09-20.69-8.54-20.58-3.74-0.15-11.26 7.07-16.76 12.77-3.74-0.4-8.18-0.45-12.01 0.16z" fill="#E08858"/>
      <path d="m46.31 90.73c-7.16-1.11-19.43-0.76-28.19 2.09-6.96 2.3-12.41 5.01-12.01 10.81 0.9 9.51 12.16 27.25 23.61 36.71l-0.7-7.12 0.5-6.61c-5.3-4.1-12.16-14.56-12.81-19.46-0.6-4.49 6.06-5.34 11.27-5.54l10.01 0.4 7.16-10.91 1.16-0.37z" fill="#E08858"/>
      <path d="m38.65 162.4-10.66 4.75c-1.93 2.03-0.05 4.2 1.63 3.29l11.29-5.1c3.84-1.61 1.86-4.8-2.26-2.94z" fill="#E08858"/>
      <path d="m45.41 170.5-8.32 7.32c-1 2.08 1.85 4.25 3.67 2.48l7.66-7.11c2.25-2.18-0.6-4.73-3.01-2.69z" fill="#E08858"/>
      <path d="m61.11 165.1c-7.72 1.26-8.07 7.52-3.07 8.73 5.75 1.46 12.01-1.15 12.01-4.94 0-2.85-3.74-4.5-8.94-3.79z" fill="#FFE4CC"/>
      <path d="m143.9 125.2c-5.65 3.55-8.85 9.96-5.15 11.52 4.75 2.03 10.35-2.97 11.5-6.67 1.1-3.64-2.1-7.09-6.35-4.85z" fill="#FFE4CC"/>
      <path d="m136.2 118.4c-1.6-0.08-2 1.37-2.25 3.09-1.65 8.51-11.06 14.12-20.17 8.77-3.19-1.86-4.74 2.39-1.89 4.05 11.1 6.31 24.51-1.56 26.31-12.47 0.4-2.13 0.15-3.39-2-3.44z" fill="#8B4513"/>
      <path d="m84.41 143.2c-1.6 0.05-2 1.5-2.35 3.22-1.95 7.62-11.01 12.22-20.97 7.27-3.3-1.98-5.2 2.21-2.5 3.82 10.16 6.11 24.02-0.2 27.22-10.36 0.7-2.2 0.6-4-1.4-3.95z" fill="#8B4513"/>
      <path d="m104.2 141.1c-4.09 1.15-8.59 3.61-8.69 5.76-0.2 2.95 4.5 5.16 7.3 4.71 3.5-0.55 5.3-6.21 5.2-8.06-0.1-1.86-1.4-3.01-3.81-2.41z" fill="#FF91A4"/>
      <path d="m104.2 152.5c0.4 2.3-1.1 5.6-5.91 4.75-2.4-1.05-3.2-0.55-3.4 0.5-0.25 1.31 1.3 2.16 2.8 2.71 4.31 1.15 7.71-1.05 9.01-4.21 4.4 2.41 9.56-0.95 10.16-5.3 0.4-2.65-2.75-3.25-2.95-0.85-0.5 3.5-4.91 6-8.21 3.2-0.75-0.6-1-1.75-1.5-0.8z" fill="#8B4513"/>
    </svg>
    """

    static let heldSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="194" height="296" fill="none" viewBox="0 0 194 296">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m155.1 211.9c11.92 10.03 20.88 28.89 20.53 45.73-0.31 14.28-8.82 31.18-20.94 31.18-8.85 0-10.78-5.97-11-9.82-0.34-6.04 4.39-11.1 7.43-15.95 5.64-8.93 5.07-20.76 0.36-30.09-1.27-2.65-6.27-6.74-3.72-11.73 1.49-3.11 3.32-8.02 7.34-9.32z" fill="#FFC8A2" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m156.1 213.4c1.19 7.65-1.19 13.59-4.64 18.37l-1.42-2.72-1.73-2.05 5.45-14.21 2.34 0.61z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m80.11 214.4c-3.2 10.85-1.66 22.31 8.95 29.21 1.91 1.27 1.86 1.3 0.89 4.11-1.54 4.77-2.03 15.75 5.67 15.75 7.29 0 10.5-7.88 13.5-17.84l0.49-10.92 11.4-1 8.35 10.14c-2.27 4.39-5.08 15.85 0.25 19.68 3.47 2.58 10.13 0.18 13.48-6.12 2.81-5.26 5-10.93 4.38-15.29-0.75-5.24-0.61-6.86 2.35-11.51 4.29-6.68 6.69-20.4 4.96-30.45-3.03-17.43-9.79-33.08-18.65-51.01l-1.17-1.74 0.02-1.2-25.76-9.74-40.25 7.59-12.39 31.13c-3.69 11.9-6.5 34.57 1.23 41.54 3.2 3.04 7.7 2.06 9.9-0.68 2.5-3.2 3.98-11.08 3.98-11.08l3.2 6.97 5.22 2.46z" fill="#FFC8A2" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m80.11 218.2c3.2 9.38 12.56 19 29.36 19l0.25-3.02-0.11-0.5-8.35-0.75c-6.08-1.48-12.55-4.4-17.22-10.23l-3.93-4.5z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m93.07 254.1v4.81" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m98.86 256.5v5.51" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m130.1 256.5v4.52" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m136.9 257.5v5.26" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m57.81 210.7 0.98 4.47" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m64.57 212.7v4.99" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m123.8 212.9c-4.21 5.75-5.48 15.91-2.51 21.65" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m70.01 188.5c1.68 12.23 4.71 23.43 8.2 27.9" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m97.88 182.7c-0.6 9.68-2.7 25.98 2.03 32.23 2.5 3 8.98 2.51 11.71-0.49 6.24-6.72 8.74-19.44 8.74-31.98" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m103.9 210.7v4.71" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m109.1 210.7v5.46" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m45.08 77.48c-8.89-3.2-19.02-3.49-26.9-3.49-12.23 0-17.3 0.73-17.79 6.98-1.17 9.64 6.71 26.57 15.86 40.29l28.83-43.78z" fill="#FFC8A2" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m19.71 107.4c3.3-7.3 7.77-13.6 7.77-13.6-2.74-6-13.89-9.47-18.87-8.73-4.47 0.74-4.47 3.48-2.74 7.95 1.97 5.75 6.69 14.61 10.91 19.33l2.93-4.95z" fill="#FFE4CC"/>
      <path d="m144.5 121.3c-0.74-12.73-5.71-22.11-9.45-27.64l0.24-13.47-7.87-32.04c-3.23-5.18-6.56-6.15-10.49-4.43-8.61 3.69-15.61 11.81-20.81 17.43l-6 4.81c-18.66-0.98-35.36 3.22-46.26 10.68-14.69 9.41-27.6 26.34-27.6 54.24 0 21.47 10.14 42.45 41.69 45.92 21.97 2.74 46.19-4.72 56.33-11.2 11.97-7.65 25.95-18.85 30.22-37.47v-6.83z" fill="#FFC8A2" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m119.9 87.75c-5.77-5.59-10.07-8.59-19.17-11.55 4-9.19 11.3-21.94 19.65-27.14" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m135 147.4c-6.01 8.37-15.24 15.66-22.17 19.38" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m135 93.62v-4.99" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m60.12 136.3c-1.17-9.61-7.95-17.42-17.31-17.42s-15.33 7.81-15.33 17.42c0 9.12 7.46 17.48 16.07 17.48 9.36 0 17.31-7.88 16.57-17.48z" fill="#fff" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".72"/>
      <path d="m57.81 133.2c-2.64-3.48-5.88-5.74-10.6-5.25-7.39 0.74-12.11 7.22-12.11 12.68 0 6.72 5.22 12.19 11.69 12.19 7.39 0 11.36-6.48 11.36-11.94 0-2.74 0.24-5.21-0.34-7.68z" fill="#000"/>
      <path d="m50.98 136.6c2.18 0.67 3.98-1.46 2.85-3.58-1.19-2.33-5.11-1.51-5.11 0.89 0 1.35 0.76 2.26 2.26 2.69z" fill="#fff"/>
      <path d="m117.9 125.2c0-10.35-8.72-17.52-17.15-17.52-10.62 0-18.05 8.17-18.05 18.78 0 9.37 7.43 17.29 16.79 17.29 9.86 0 18.41-8.17 18.41-18.55z" fill="#fff" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".72"/>
      <path d="m110.6 130.1c0-7.41-5.47-12.37-11.94-12.37-7.92 0-12.87 6.2-12.87 12.37 0 7.41 5.96 12.6 12.43 12.6 6.91 0 12.38-5.91 12.38-12.6z" fill="#000"/>
      <path d="m103.4 126.6c2.52 0 3.24-2.74 1.74-4.22-1.74-1.74-4.48-0.51-4.48 1.48 0 1.5 0.99 2.74 2.74 2.74z" fill="#fff"/>
      <path d="m128.5 141c0-3.23-3-3.23-4.98-3.23-5.22 0-8.69 3-8.69 6 0 2.24 2.23 3.47 4.47 3.47 4.22 0 9.2-3 9.2-6.24z" fill="#FFE4CC"/>
      <path d="m44.58 160.1c0-2.5-3-3.24-6-3.24-3.97 0-6.47 0.99-6.47 3.73 0 2.24 2.24 3.73 6.22 3.73 3.25 0 6.25-1.98 6.25-4.22z" fill="#FFE4CC"/>
      <path d="m8.12 150.6 14.49-1.48" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="4.32"/>
      <path d="m16.25 165.8 10.14-8.1" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="4.32"/>
      <path d="m138 124.9 14.98-4.72" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="4.32"/>
      <path d="m137.7 134.6 15.23 2.74" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="4.32"/>
      <path d="m65.53 176.8c5.22 0.5 6.95 0.25 6.95 0.25" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m72.48 140.1c3.24-0.74 4.97-1.45 4.97 0.8 0 2.74-3.47 5.98-4.97 5.98-2.74 0-6.97-1.48-6.97-4.73 0-3 3.24-3 6.97-2.05z" fill="#FCD26E" stroke="#C4A030" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m73.46 147.8 0.49 4.72-5.74 4.21" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m73.46 151.3 7.45 2.48" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
    </svg>
    """

    static let angrySVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" fill="none" viewBox="0 0 256 256">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m249.7 44.88c-0.92-1.23-2.28-0.67-3.64 0.23 2.42-6.85 1.95-14.72-3.76-15.1 0.58-3.96 0-9.38-3.4-9.7-4.2-0.4-8.85 3.01-10.84 6.1-1.19-1.25-2.19-1.69-3.25-1.6-5.24 0.46-8.71 9.34-10.21 16.1-0.89-1.7-2.22-2.82-3.87-2.19-3.83 1.52-4.46 10-2.91 17.26-1.36-2.06-3.05-3.31-5.02-2.15-3.35 1.99-1.88 12.48-0.2 19.99-1.57-1.71-4.2-4.03-5.12-1.91-1.3 3.22-0.63 15.95 0.79 24.85l-4.65-5.78c1.25-0.79 2.14-1.99 0.2-3.55s-6.22-2.85-9.97-3.56c1.65-1.38 3.23-3.66 0.96-4.97-2.16-1.22-7.91-1.71-12.64-0.99 1.19-1.87 1.83-4.15-1.09-4.71s-8.88 0.68-11.43 2.49c0.7-2.28 1.25-4.28-1.67-4.28-3.21 0-10.55 3.25-15.06 5.81l-3.87 8.69 2.26 29.2 7.94 3.95 60.7-1c9.03-4.89 22.85-16.08 24.26-19.14 1.19-2.79-1.11-2.79-3.53-2.51 5.59-4.33 11.23-10.52 11.06-11.93-0.34-2.37-2.7-1.52-4.69-1.06 6.81-6.11 11.73-13.34 10.96-16.72-0.59-2.22-2.24-1.94-4.06-1.27 5.35-8.47 7.77-17.81 5.75-20.55z" fill="url(#paint0_linear_1338_1255)" stroke="#FFD0A8" stroke-miterlimit="10" stroke-width=".7"/>
      <path d="m155.2 194.8-2.06 10.44c-4.51 1.23-5.33 7.28-4.03 11.05 1.57 4.17 7.16 5.13 16.07 3.25 6.96-1.51 11.61-16.04 14.4-25.74l-4.09-12.86-16.3-0.77-3.99 14.63z" fill="url(#paint1_linear_1338_1255)" stroke="#FFD0A8" stroke-miterlimit="10" stroke-width=".7"/>
      <path d="m68.11 185.3-5.96 25.29c-5.9 2.38-7.03 7.5-6.45 11.51 0.88 5.37 9.02 6.72 17.93 4.54 5.29-1.32 7.78-3.5 10.93-9.8 2.46-4.63 6.61-11.72 9.06-17.72l-5.4-12.15-20.11-1.67z" fill="url(#paint2_linear_1338_1255)" stroke="#FFD0A8" stroke-miterlimit="10" stroke-width=".7"/>
      <path d="m7.42 74.11c-5.29 3.71-0.58 26.82 8.74 47.06l7.06-4.07 25.52-31.99c-15.63-8.25-35.53-14.95-41.32-11z" fill="url(#paint3_linear_1338_1255)" stroke="#E08858" stroke-miterlimit="10" stroke-width=".7"/>
      <path d="m15.29 85.11c-3.58 2.75 1.82 17.72 6.74 26.19l14.03-18.99c-8.14-5.26-17.79-9.4-20.77-7.2z" fill="#FFE4CC" stroke="#FFD0A8" stroke-miterlimit="10" stroke-width=".7"/>
      <path d="m196.3 95.01c-12.01-11-26.18-17.93-45.22-20.1-4.92 2.23-7.34 3.74-7.92 4.02-1.08-11-3.11-18.65-7.71-19.32-9.7-1.46-26.29 11.21-35.2 20.32-7.2-2.17-13.6-2.85-20.06-2.68-28.34 0-55.03 14.4-64.73 44.2-5.13 15.94-3.48 32.29 0.6 42.73 8.42 14.74 23.17 19.91 51.8 21.09 1.14 5.79 8.96 13.07 39.06 14.69l3.3 19.19c-2.92 2.11-3.03 7.28-1.73 10.24 2.92 6.36 13.78 5.35 19.74 1.12 3.3-2.47 4.66-5.49 6.37-39.5 12.3-10.17 15.93-18.81 32.29-21.77 1.26 12.56 5.13 21.48 15.87 28.07 3.04 1.94 2.03 7.42 1.21 14.53-4.65 2.97-5.14 8.45-3.21 12.35 2.31 4.6 9.37 4.1 14.61 2.64 6.4-1.81 9.01-6.65 13.93-24.99 3.05-10.72 1.4-12.72-0.31-15.09-2.92-3.82-2.21-9.6 0.98-19.06 8.91-27.08 3.88-56.56-13.67-72.68z" fill="url(#paint4_linear_1338_1255)" stroke="#FFD0A8" stroke-miterlimit="10" stroke-width=".7"/>
      <path d="m144.7 76.91c1.3 9.8 0 26.32-4.65 38.31 3.15 5.84 5.09 13.54 5.09 22.01 0 23.23-14.44 50.74-57.63 51.6-5.59 0.12-11.33-0.57-14.25-1.42 19.74-1.12 35.93-4.48 45.92-10.59 14.75-8.91 23.06-20.21 23.06-40.21 0-8.47-3.15-18.58-4.8-21.22 4.2-8.15 5.85-23.25 5.67-35.35 0.64-1.11 0.87-1.96 1.59-3.13z" fill="#D07848" stroke="#FFD0A8" stroke-miterlimit="10" stroke-width=".7"/>
      <path d="m151.4 136.8-12.01 1.67c-1.99 0.3-2.95 4.31 0.11 4.87l11.73-2c3.25-0.67 3.42-4.94 0.17-4.54z" fill="#D07848"/>
      <path d="m148.6 150.1-9.99-1.29c-2.92 0-3.21 4.57 0.29 5.37l9.7 2.06c3.4 0.39 3.83-5.45 0-6.14z" fill="#D07848"/>
      <path d="m127.1 73.31c-5.35 0.85-13.23 9.6-15.92 13.6 7.77 4.45 13.11 8.83 18.15 14.61 3.36-10.88 5.29-29.33-2.23-28.21z" fill="#FFE4CC" stroke="#FFD0A8" stroke-miterlimit="10" stroke-width=".7"/>
      <path d="m116 136.1c0 10.82-8.36 17.87-16.95 17.87-9.26 0-15.83-8.25-15.83-17.06 0-8.8 7.52-16.26 15.83-16.26 8.85 0 16.95 7.46 16.95 15.45z" fill="#fff"/>
      <path d="m108.7 137.7c0 7.89-6.4 13.07-12.58 13.07-7.2 0-12.18-6.8-12.18-13.07 0-7.23 5.8-12.4 12.18-12.4 7.2 0 12.58 6.41 12.58 12.4z" fill="url(#paint5_linear_1338_1255)"/>
      <path d="m93.92 135.6c0 2.56-1.93 3.67-3.4 3.67-1.82 0-3.01-1.56-3.01-3.12 0-1.94 1.57-3.35 3.01-3.35 2.09 0 3.4 1.46 3.4 2.8z" fill="#fff"/>
      <path d="m26.11 137.9c0 9.91 7.35 17.37 15.94 17.37 9.82 0 13.97-8.52 13.79-16.5-0.23-9.4-7.04-16.2-15.03-16.2-7.76 0-14.7 7.57-14.7 15.33z" fill="#fff"/>
      <path d="m29.74 139.1c0 7.89 6.4 13.67 12.59 13.67 8.36 0 12.5-6.41 12.33-13.21-0.23-7.23-5.92-12.84-12.33-12.84-7.2 0-12.59 6.41-12.59 12.38z" fill="url(#paint6_linear_1338_1255)"/>
      <path d="m39.96 138.4c2.26-0.34 3.08-2.07 2.79-3.74-0.34-1.62-1.82-2.58-3.19-2.36-1.88 0.34-3.45 1.86-3.45 3.48s1.57 2.95 3.85 2.62z" fill="#fff"/>
      <path d="m107.3 118.6-27.02 14.2c-2.2 1.11-1.2 4.88 1.12 4.1l27.36-15.19c1.61-1.01 0.31-4.03-1.46-3.11z" fill="url(#paint7_linear_1338_1255)"/>
      <path d="m31.36 123c-1.08 2.06 0.17 3.28 1.47 3.9l23.41 10.49c2.98 1.33 3.8-3.41 1.48-4.36l-24.61-11.48c-0.88-0.44-1.46 0.73-1.75 1.45z" fill="url(#paint8_linear_1338_1255)"/>
      <path d="m126.5 150.1c0.98 4.06-3.53 8.01-9.99 9.13-4.65 0.85-6.42-2.11-6.42-4.17 0-3.41 3.82-7.47 9.51-8.03 3.54-0.44 6.3 0.79 6.9 3.07z" fill="#FFE4CC"/>
      <path d="m36.06 156.7c3.76 2.6 1.16 8.03-5.24 7.46-5.9-0.56-8.7-4.07-8.7-6.44 0-3.47 4.04-4.64 6.59-4.03 2.65 0.62 4.4 1.24 7.35 3.01z" fill="#FFE4CC"/>
      <path d="m61.01 146.8c-0.88 2.74 1.92 6.56 6.84 6.9 4.4 0.28 6.76-4.27 6.76-6.9 0-2.18-2.65-2.8-5.8-2.8-3.58 0-7.06 0.34-7.8 2.8z" fill="#FF91A4" stroke="#D9B936" stroke-miterlimit="10" stroke-width=".7"/>
      <path d="m67.62 153.9 0.23 2.29h2.61l0.17-2.63-3.01 0.34z" fill="#8B4513"/>
      <path d="m64.92 157c-5.64 1.25-8.29 5.42-8.29 10.05 0 3.07 2.11 4.41 3.98 4.41 2.81 0 4.68-0.73 6.1-1.63 2.92-0.72 7.01 0.29 11.21 0.9 4.84 0.67 6.49-1.39 6.49-4.13 0-5.48-4.65-10-7.57-10-2.15 0-4.82 0.4-11.92 0.4z" fill="url(#paint9_linear_1338_1255)"/>
      <path d="m62.21 159c-1.94 0.67-3.3 2.18-3.3 3.95 0 1.82 1.13 2.78 2.21 2.78 1.72 0 3.02-2.75 4.03-5.49-0.43-0.96-1.19-1.75-2.94-1.24z" fill="#fff"/>
      <path d="m74.81 162.7c0.88-2.63 1.6-5.76 2.8-5.59 1.71 0.28 4.46 2.06 6.11 5.83-2.6-1.23-5.4-1.51-8.91-0.24z" fill="#fff"/>
      <path d="m4.22 145.2 9.7 1.06v3.57l-9.99-1.83c-2.92-0.56-2.04-3.19 0.29-2.8z" fill="#D07848" stroke="#FFD0A8" stroke-miterlimit="10" stroke-width=".7"/>
      <path d="m13.58 156.7-7.29 3.5c-1.65 1.11-0.46 4.3 2.05 3.4l7.82-3.51-0.88-4.01-1.7 0.62z" fill="#D07848" stroke="#FFD0A8" stroke-miterlimit="10" stroke-width=".7"/>
      <defs>
        <linearGradient id="paint0_linear_1338_1255" x1="249" x2="190.8" y1="20.26" y2="113.4" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#D07848" offset="1"/>
        </linearGradient>
        <linearGradient id="paint1_linear_1338_1255" x1="164.2" x2="164.2" y1="180.1" y2="220.6" gradientUnits="userSpaceOnUse">
          <stop stop-color="#D07848" offset="0"/>
          <stop stop-color="#E08858" offset="1"/>
        </linearGradient>
        <linearGradient id="paint2_linear_1338_1255" x1="74.51" x2="74.51" y1="185.2" y2="227.7" gradientUnits="userSpaceOnUse">
          <stop stop-color="#D07848" offset="0"/>
          <stop stop-color="#E08858" offset="1"/>
        </linearGradient>
        <linearGradient id="paint3_linear_1338_1255" x1="31.6" x2="31.6" y1="72.74" y2="121.2" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#D07848" offset="1"/>
        </linearGradient>
        <linearGradient id="paint4_linear_1338_1255" x1="114.5" x2="114.5" y1="59.43" y2="233.9" gradientUnits="userSpaceOnUse">
          <stop stop-color="#FFD0A8" offset="0"/>
          <stop stop-color="#FFD0A8" offset="1"/>
        </linearGradient>
        <linearGradient id="paint5_linear_1338_1255" x1="96.33" x2="96.33" y1="125.3" y2="150.8" gradientUnits="userSpaceOnUse">
          <stop stop-color="#333" offset="0"/>
          <stop stop-color="#282828" offset="1"/>
        </linearGradient>
        <linearGradient id="paint6_linear_1338_1255" x1="42.23" x2="42.23" y1="126.7" y2="152.7" gradientUnits="userSpaceOnUse">
          <stop stop-color="#333" offset="0"/>
          <stop stop-color="#282828" offset="1"/>
        </linearGradient>
        <linearGradient id="paint7_linear_1338_1255" x1="94.36" x2="94.36" y1="118.4" y2="137.1" gradientUnits="userSpaceOnUse">
          <stop stop-color="#8B4513" offset="0"/>
          <stop stop-color="#8B4513" offset="1"/>
        </linearGradient>
        <linearGradient id="paint8_linear_1338_1255" x1="44.7" x2="44.7" y1="121.4" y2="137.6" gradientUnits="userSpaceOnUse">
          <stop stop-color="#8B4513" offset="0"/>
          <stop stop-color="#8B4513" offset="1"/>
        </linearGradient>
        <linearGradient id="paint9_linear_1338_1255" x1="70.52" x2="70.52" y1="156.6" y2="171.5" gradientUnits="userSpaceOnUse">
          <stop stop-color="#993939" offset="0"/>
          <stop stop-color="#B74456" offset="1"/>
        </linearGradient>
      </defs>
    </svg>
    """

    static let jumpingSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="186" height="220" fill="none" viewBox="0 0 186 220">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m70.49-1.68c5.35 0 8.52-2.61 9.16-6.56 0.31-1.95-1.76-4.47-5.74-4.69-5.98-0.33-10.18 3.14-10.18 5.87 0 2.61 2.66 5.38 6.76 5.38z" fill="url(#paint0_linear_131_2932)"/>
      <path d="m122.7 52.36c0.6-9.27 3.01-17.27 6.55-17.27 8.55 0 23.65 14.69 32.95 36.22l0.67 1.81-10.68-2.06-29.49-18.7z" fill="url(#paint1_linear_131_2932)"/>
      <path d="m50.01 56.61c-7.13 2.71-3.23 16.88 8 34.09 1.58 2.67 3.2 5.06 4.82 7.03-1.36 8.55-0.85 16.2 0.55 22.02l-8.33 1.18-1.14 0.18-0.2 0.96c-0.33 1.54 0.71 2.71 2.07 2.54l9-1.1 1.5 3.5c-12.16 2.17-22.17 6.46-28.92 15.95-8.2-4.8-14.22-13.18-13.95-24.3 0.44-11.89 10.42-22.54 10.71-31.07 0.24-7.01-4.11-12.68-11.91-13-11.48-0.48-21.15 15.87-22.14 32.64-0.98 16.76 6.14 37.76 26.42 46.07 1.66 0.72 3.38 1.31 5.14 1.79-1.57 4.79-1.85 9.87-1.42 15.97 0.2 3.1 0.07 7.55-1.42 8.65-3.58 2.67-5.05 2.07-7.78 10.15s-3.62 17.85 1.6 23.24c2.31 1.81 5.33 2.19 8.77 0.12 3.81-2.24 5.78-7.25 6.84-12.8 4.17 0.53 7.89-0.41 11.19-1.41-0.89 7.52 2.3 13.27 7.72 13.65 5.78 0.41 9.77-6.29 10.38-13.85 8.96-0.2 14.78-4.69 19.5-11.63 9.82-2.59 19.21-6.77 28.18-11.02 3.15 0.73 3.92 2.85 6.52 6.02 4.78 5.81 12.01 4.55 15.67 1.23 5.9-5.32 2.6-15.29-2.06-21.27 4.26 0.65 7.56 1.77 9 4.93 2.62 5.81 7.8 7.04 11.4 6.56 6.09-0.79 8.9-8.31 6.61-14.82-3.42-10.05-12.51-14.15-19.45-14.94l-0.16-1.01c17.19-5.15 33.39-15.57 34.2-31.79l8.92 1.58 0.98-0.24 0.29-1.3c0.36-1.66-0.78-2.15-1.64-2.23l-8.41-0.77-0.2-5.24 9.43-2.89 0.65-0.87-0.16-1.18c-0.29-1.58-1.47-1.14-2.08-1.02l-8.51 1.71c-2.05-9.81-6.13-19.78-13.26-27.51-9.86-11.1-22.91-18.75-40.7-18.75h-0.2c-0.4-0.04-0.81-0.04-1.25-0.04-12.69 0-22.75 2.75-32.77 7.81-10.85-4.41-27.85-7.12-38-3.52z" fill="url(#paint2_linear_131_2932)"/>
      <path d="m140.3 146.7c-2.37 5.94-5.02 10.55-7.03 13.79 1.7 0.56 6.7 0.9 9.6 3.65 2.05 2.01 2.25 8.72 9.53 9.15 6.9 0.4 9.56-6.9 8.67-11.94-1.7-9.66-10.85-16.01-20.77-14.65z" fill="url(#paint3_linear_131_2932)"/>
      <path d="m142 143.4c-10.85 6.52-21.7 9.69-35.79 9.33-15.51-0.44-28.61-4.94-36.21-17.83l0.89-1.89c7.27 9.39 18.88 14.7 36.58 14.7 14.35 0 25.24-1.97 34.53-5.51v1.2z" fill="#E08858"/>
      <path d="m116.1 155.1c11.65 0 23.32 7.92 23.32 20.57 0 5.94-3.7 8.3-7.97 8.06-5.78-0.33-6.76-6.58-10.34-8.55-4.93-2.67-8.74-1.96-17.46-1.64" stroke="#E08858" stroke-linecap="round" stroke-width="2.5"/>
      <path d="m63.77 176.5c-1.1 12.3-12.26 23.34-26.69 21.98-1.02 6.95-4.97 14.39-10.83 14.39-5.14 0-6.84-5.77-6.03-11.93 0.89-7.03 3.55-17.17 8.65-18.69 3.84-1.17 1.87-7.31 1.87-15.07 0-17.17 10.19-32.92 26.98-38.28 4.91-1.58 10.01-2.72 12.25-1.99l0.98 2.32c-1.93 1.7-3.18 2.47-3.18 2.47 5.7 7.51 10.4 16.3 33.51 19.47-10.85 2.89-21.5 0.81-33.51-17.87 2.41 5.55-1.54 19.96-4 43.2z" fill="url(#paint4_linear_131_2932)"/>
      <path d="m60.52 189.6c6.34 0.4 16.76 0 25.64-2.67l0.85-0.29c-4.23 6.59-11.05 11.56-19.99 11.16l0.2-0.08c-0.81 5.51-3.29 13.31-9.99 13.31-6 0-7.41-7.03-7.21-11l0.2-1.6c3.81-1.44 8.31-4.69 10.3-8.83z" fill="url(#paint5_linear_131_2932)"/>
      <path d="m66.82 118.8-11.77 1.54" stroke="#D07848" stroke-linecap="round" stroke-width="4.5"/>
      <path d="m69.78 128.8-9.01 4.48" stroke="#D07848" stroke-linecap="round" stroke-width="4.5"/>
      <path d="m102.1 91.02c-8.8 0-14.62 7.72-14.62 15.06 0 8.24 7.13 15.23 14.82 15.23 8.68 0 15.08-6.6 15.08-14.36 0-7.72-7.13-15.93-15.28-15.93z" fill="#fff"/>
      <path d="m105.4 96.11c-7.52 0-11.22 6.52-11.22 11.31 0 6.52 5.5 11.32 10.9 11.32 6.82 0 12.22-5.4 12.22-11.44 0-6.52-5.48-11.19-11.9-11.19z" fill="#2D2D2B"/>
      <path d="m109 99.11c-2.41 0-2.94 1.87-2.94 2.96 0 1.87 1.58 3.05 2.86 3.05 1.93 0 3.28-1.71 3.28-3.21 0-1.74-1.56-2.8-3.2-2.8z" fill="#fff"/>
      <path d="m150.7 83.02c-8.55-0.4-12.66 8.29-12.66 14.33 0 7.73 6.12 14.25 12.21 14.25 8.07 0 14.08-6.99 14.08-13.99 0-7.35-6.62-14.3-13.63-14.59z" fill="#fff"/>
      <path d="m153.1 87.07c-6.82 0-10.52 5.81-10.52 10.6 0 6.51 5.1 11.3 10.52 11.3 6.42 0 11.2-5.81 11.2-11.3 0-6.04-5.22-10.6-11.2-10.6z" fill="#2D2D2B"/>
      <path d="m157 89.49c-2.41 0-3.18 1.42-3.18 2.78 0 1.97 1.42 2.99 2.78 2.99 1.93 0 3.07-1.66 3.07-2.99 0-1.76-1.26-2.78-2.67-2.78z" fill="#fff"/>
      <path d="m125.4 108.1c-1.89 1.44-0.27 4.1 2.23 5.34 2.41 1.2 5.31 1 6.8-0.8 1.81-2.27 3.57-4.7 2.51-5.72-2.1-2.05-8.66-0.85-11.54 1.18z" fill="#FF91A4"/>
      <path d="m123.1 118.7c2.5 3.29 9.2 2.51 10.09-3.43 3.01 3.67 8.03 2.47 8.8-0.8" stroke="#8B4513" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
      <path d="m56.63 67.71c-0.61-3.7 2.41-4.18 5.88-3.86 4.59 0.44 11.53 2.94 15.1 4.51-4.78 4.41-8.88 11.36-10.87 17.05-4.78-3.66-9.35-12.6-10.11-17.7z" fill="#FFE4CC"/>
      <path d="m160.1 116.7c-3.14-1.54-0.73-6.51 3.5-8.48 3.3-1.48 6.45 0 6.81 1.61 0.81 3.52-5.09 9.36-10.31 6.87z" fill="#FFE4CC"/>
      <path d="m82.13 123.9c-1.12 3.13 2.58 5.57 6.99 5.57 4.78 0 6.94-2.12 6.94-4.17 0-3.28-3.54-5.52-8.6-5.52-3.04 0-4.68 1.43-5.33 4.12z" fill="#FFE4CC"/>
      <defs>
        <linearGradient id="paint0_linear_131_2932" x1="71.69" x2="71.69" y1="-13.05" y2="-1.681" gradientUnits="userSpaceOnUse">
          <stop stop-color="#D07848" offset="0"/>
          <stop stop-color="#E08858" offset="1"/>
        </linearGradient>
        <linearGradient id="paint1_linear_131_2932" x1="142.8" x2="142.8" y1="35.09" y2="73.12" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#D07848" offset="1"/>
        </linearGradient>
        <linearGradient id="paint2_linear_131_2932" x1="93.56" x2="93.56" y1="35.09" y2="214.5" gradientUnits="userSpaceOnUse">
          <stop stop-color="#FFD0A8" offset="0"/>
          <stop stop-color="#FFD0A8" offset="1"/>
        </linearGradient>
        <linearGradient id="paint3_linear_131_2932" x1="150.8" x2="150.8" y1="146.5" y2="173.4" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#D07848" offset="1"/>
        </linearGradient>
        <linearGradient id="paint4_linear_131_2932" x1="49.36" x2="49.36" y1="126.6" y2="212.9" gradientUnits="userSpaceOnUse">
          <stop stop-color="#FFD0A8" offset="0"/>
          <stop stop-color="#FFD0A8" offset="1"/>
        </linearGradient>
        <linearGradient id="paint5_linear_131_2932" x1="68.51" x2="68.51" y1="186.6" y2="211" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#D07848" offset="1"/>
        </linearGradient>
      </defs>
    </svg>
    """

    static let playingSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="250" height="250" fill="none" viewBox="0 0 250 250">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m129.1 67.78c5.77-14.5 19.68-33.46 27.94-33.78 7.64-0.29 16.18 16.28 18.71 29.71l0.16 0.85 0.33 0.61-10.02 3.94-37.12-1.33z" fill="#E08858"/>
      <path d="m142.3 61.59c4.53-8.8 10.4-16.1 14.81-16.1 3.88 0 7.99 9.92 9.59 17.15l-5.66 6.09-22.94-2.52 4.2-4.62z" fill="#FFD0A8"/>
      <path d="m208.2 86.41c13.96-1.4 29.76 1.44 34.84 6.45 3.75 2.32 3.55 6.55-2.14 15.25-6.13 9.52-15.67 18.97-24.71 24.99l-8.96-15.06 0.97-31.63z" fill="#E08858"/>
      <path d="m213 94.81c8.23-0.1 18.42 1 20.05 3.4 3.1 4.62-6.75 14.66-15.93 21.98l-4.12-2.98v-22.4z" fill="#FFD0A8"/>
      <path d="m112.2 84.19-5.59-5.36c-0.99-0.96-2.17-0.65-2.53-0.02-0.46 0.81-0.28 2.01 0.46 2.75l5.9 5.86 1.76-3.23z" fill="#E08858"/>
      <path d="m108.2 92.91-7.08-2.99c-1.3-0.55-2.19 0.26-2.41 1.3-0.28 1.25 0.26 2.45 1.2 2.77l6.94 2.62 1.35-3.7z" fill="#E08858"/>
      <path d="m91.42 109.3c-8.44 0-15.01 3.83-15.51 10.16-0.45 5.67 5.38 10.31 11.37 9.59l3.75-0.47c0.82 5.25 2.86 10.18 5.93 13.84l21.97-7.71c-5.14-5.24-9.99-12.63-12.62-19-2.69-3.94-7.6-6.41-14.89-6.41z" fill="#E08858"/>
      <path d="m26.97 123.2c-6.03 0-9.59 3.06-14.6 11.3-5.65 9.25-7.1 17.02-6.68 26.44 0.97 17.82 17.18 45.8 53.27 46.28 7.23 0.1 13.8-1.13 19.03-2.77l-6.2-12.26c-4.18 0-8.56 0.7-16.68-1.24-9.09-2.31-25.03-13.71-25.19-27.04-0.1-11.1 6.27-15.04 8.69-21.27 3.46-8.04-1.42-19.44-11.64-19.44z" fill="#E08858"/>
      <path d="m57.91 125.5c-7.08 0-11.8 14.34-13.82 24.61-1.63 8.25 1.05 11.59 9.8 12.69-1.17 6.23-0.11 12.56 6.26 18l8.17-9.45 19.59-26.24c-2.99-6.44-12.73-10.11-22.27-4.66 1.17-7.05-0.26-14.4-7.73-14.95z" fill="#D07848"/>
      <path d="m168.6 166c-11.66 25.96-33.6 48.89-63.7 48.98-24.8 0-44.8-16.32-45.35-37.15-0.45-15.14 11.26-31.77 27.73-35.14 7.79-1.65 16.82-4.49 25.62-9.2-7.64-11.42-9.12-24.42-6.8-33.45 4.9-19.81 24.06-40.3 49.9-40.3 25.3 0 51.9 18.15 61.08 43.04 4.02 11.01 1.6 31.26-5.97 45.12-3.83 6.86-10 18.39-30 19.59-4 0-8.22-0.57-12.51-1.49z" fill="#FFC8A2"/>
      <path d="m147.4 92.77c0 8.51-7.22 14.72-13.6 14.35-7.84-0.45-12.93-6.2-12.93-12.41 0-7.9 6.79-14.68 13.87-14.68 8 0 12.66 5.98 12.66 12.74z" fill="#FEFFFE"/>
      <path d="m144.1 94.09c-1.3 7.17-7.13 12.52-12.9 12.07-6.23-0.55-10.1-5.9-10.1-11.45 0-7.32 6.23-11.94 12.46-11.94 6.79 0 11.84 4.86 10.54 11.32z" fill="url(#paint0_linear_201_525)"/>
      <path d="m141.4 92.27c0 2.77-3.24 4.07-5.12 2.44-1.87-1.48-1.6-4.7 0.91-5.62 2.37-0.85 4.21 0.92 4.21 3.18z" fill="#FEFFFE"/>
      <path d="m190.7 123.8c0 9.45-7.89 15.12-14.97 14.67-8.75-0.58-14.73-8.05-14.73-15.1 0-8.65 7.7-14.63 15.34-14.63 8.9 0 14.36 7.35 14.36 15.06z" fill="#FEFFFE"/>
      <path d="m183.9 122.7c0 7.35-6.57 12.55-12.22 12.1-6.79-0.55-10.97-6.35-10.69-12.1 0.46-7.35 6.44-11.97 12.1-11.97 6.78 0 10.81 6.43 10.81 11.97z" fill="url(#paint1_linear_201_525)"/>
      <path d="m174.3 113.6c2.69 1.08 1.17 6.15-2.29 5.55-3.93-0.7-3.98-5.55-0.27-5.89 0.91-0.1 1.79 0.05 2.56 0.34z" fill="#FEFFFE"/>
      <path d="m143 109.1c1.79-1.48 5.1 0.16 9.86 4.69 2.37 2.31 0 5-4.91 5-4.28 0-6.8-8.03-4.95-9.69z" fill="#FF91A4"/>
      <path d="m134.7 114c-0.87 2.84 0.97 7.03 5.26 7.03 3.93 0 5.24-3.1 5.24-4.93l-1.98-0.65c-0.25 1.93-1.55 3.24-3.52 3.09-2.68-0.2-3.28-2.61-3.03-4.09 0.15-1.01-1.54-1.77-1.97-0.45z" fill="#8B4513"/>
      <path d="m135.1 123.7c1.06-1.23 2.85-1.68 4.12-1.48 3.93 0.55 8.01 3.6 9.03 6.44-1.93 2.58-7.1 4.51-10.55 3.07-3.35-1.33-3.74-5.66-2.6-8.03z" fill="#D46479"/>
      <path d="m141.7 119.6c0.51 1.25 1.97 4.62 6.3 7.03 1.8 0.97 3.77 1.29 5.12 0.53 1.11-0.65 0.66-2.86-0.98-2.41-2.22 0.7-3.53 0-4.96-1.02-1.7-1.23-2.57-3.21-2.98-4.44-0.6-1.23-3.02-1.03-2.5 0.31z" fill="#8B4513"/>
      <path d="m112.9 97.34c3.24-0.9 6.08 2.37 7.51 6.12 1.33 3.66-1.35 5.27-3.67 4.72-3.86-1.01-6.11-4.27-6.31-7.37-0.15-1.83 0.6-3.02 2.47-3.47z" fill="#FFE4CC"/>
      <path d="m176.2 142.4c4.43-1.4 9.46-0.32 11.44 3.82 1.53 3.4-0.34 5.11-2.87 5.56-4.58 0.9-9.61-2.04-11.13-4.67-1.22-2.31 0.13-3.96 2.56-4.71z" fill="#FFE4CC"/>
      <path d="m146.6 155.1c6.21 5.7 15.01 9.71 22 10.91l-2.17 2.41c-7.95-1.17-15.22-3.37-20.53-5.37-1.5-10.05-8-20.9-22.19-20.9-8.8 0-12.91 5.15-12.91 9.55 0 5.5 5.26 9.2 10.3 9.2 3.24 0 5.92-1.1 8.03-2.54 1.33-0.91 2.37 1.54 1.07 2.34-1.43 0.95-2.93 1.55-3.99 1.9-0.31 5.45 0.71 11.1 6.22 14.45 1.31 0.85-0.22 2.56-1.62 1.7-5.84-3.45-7.2-9.62-7.4-15.45-1.01 0.2-2.06 0.3-3.2 0.3-6.79 0-12.06-5.39-12.06-11 0-6.33 5.56-12.91 16.03-12.91 11.62 0 19.62 7.42 22.42 15.41z" fill="#E08858"/>
      <path d="m85.72 147.9c-7.79 0.75-20.13 19.14-20.13 28.49 0 6.03 3.34 8.34 8.95 8.94-1.23 5.5 0.57 11.25 3.37 14.09 1.3 1.35 3.05-0.53 1.8-1.97-3.4-3.84-3-8.86-2.4-13.05l0.25-1.23-1.35-0.15c-4.99-0.6-7.59-2.33-7.59-7.13 0-7.1 10.49-24.77 17.86-25.52 4.81-0.5 6.83 4.42 6.63 8.03-0.2 2.74-0.9 7.6-2 10.69 2.94-1.3 4.59-2.95 10.2-1.9 7.8 1.45 14.06 7 14.06 14.7 0 1.83 2.47 1.68 2.37-0.2-0.4-9.5-7.82-15.55-16.03-16.5-2.8-0.35-5.13 0.15-7 0.81 0.45-2.21 0.7-4.71 0.7-7.01 0-5.7-3.25-11.74-9.69-11.09z" fill="#E08858"/>
      <path d="m203.1 150.8c-1.36 1.07-1.26 2.57 0.27 3.62l9.26 5.65c2.32 1.45 3.38-1.39 2.13-3.2l-9-6.42c-0.8-0.6-1.91-0.5-2.66 0.35z" fill="#E08858"/>
      <path d="m196.7 157.6c-1.25 1-1 2.39-0.1 3.49l6.11 7.15c1.7 1.55 3.97-0.7 2.87-2.75l-5.93-7.59c-0.8-1.05-2-1.1-2.95-0.3z" fill="#E08858"/>
      <defs>
        <linearGradient id="paint0_linear_201_525" x1="132.6" x2="132.6" y1="82.77" y2="106.2" gradientUnits="userSpaceOnUse">
          <stop stop-color="#202121" offset="0"/>
          <stop stop-color="#343535" offset="1"/>
        </linearGradient>
        <linearGradient id="paint1_linear_201_525" x1="172.5" x2="172.5" y1="110.7" y2="134.8" gradientUnits="userSpaceOnUse">
          <stop stop-color="#202121" offset="0"/>
          <stop stop-color="#343535" offset="1"/>
        </linearGradient>
      </defs>
    </svg>
    """

    static let bathingSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="250" height="250" fill="none" viewBox="0 0 250 250">
      <path d="m139.7 31.19c-5.88-1.18-9.96-1.37-14.98-1.37-12.01 0-21.42 1.64-30.03 6.05-7.48-7.45-24.67-19.1-38.82-19.7-11.5-0.5-11.7 22-10.1 38.75 0.9 9.86 3 17.81 4.9 23.83-3.5 7.35-4.2 16-4 23.85 0.7 19.26 8.5 33.01 26.3 41.76 10.2 5.12 23.1 8.33 41.9 8.33l10.9-0.3c23.5-1.2 35.4-5.42 46.9-11.64 15.1-8.45 25-19.8 26.9-36.15 1.6-12.75-1.7-24.5-6.3-36.56 3.6-13.92 1.5-42.03-6.4-57.28-2.3-4.31-6.3-4.31-9.8-3.21-10.9 3.51-23 14.46-33.3 24.71l-4.07-1.07z" fill="#FFC8A2" stroke="#FFC8A2" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m157.9 37.07c8.5 3.81 17.1 9.72 24.1 16.85 1.4 1.4 2.1 0.2 2.6-3.11 1.3-7.93 0.3-21.69-4.2-28.1-2.2-3.31-7.9-1-11.3 2.2-4.8 3.61-8.3 6.82-10.8 10.76-0.7 0.7-1.2 1-0.4 1.4z" fill="#FFE4CC"/>
      <path d="m59.11 63.23c-4.2-9.15-4.9-18.6-3.1-28.06 1.2-5.01 4.3-5.01 7.9-3.91 6.1 2.11 12.2 6.11 16.3 10.32 0.9 0.9 1.2 1.9-0.5 3.1-9.5 5.91-14.5 10.94-19.7 18.85-0.2 0.4-0.7 0.4-0.9-0.3z" fill="#FFE4CC"/>
      <path d="m139.9 106.2c4.2 4.2 8.7 6.71 14.9 6.51 8.2-0.3 14.7-5.01 18.6-12.22" stroke="#2D2D2D" stroke-linecap="round" stroke-linejoin="round" stroke-width="3.2"/>
      <path d="m71.91 109.7c4.2 6.12 9.8 8.93 17 8.52 7.2-0.4 12.3-3.9 16.5-9.42" stroke="#2D2D2D" stroke-linecap="round" stroke-linejoin="round" stroke-width="3.2"/>
      <path d="m123.9 120.7c0 5.42-1.6 8.22-7.7 10.03" stroke="#8B4513" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m123.9 120.7c0.3 4.21 2.3 6.02 5.8 7.52" stroke="#8B4513" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m120.1 112c2.7-0.3 5.9-0.3 8.6 0 2.7 0.4 2.8 3.81 0 6.21-2.8 2.51-4.8 2.51-6.4 2.01-3.5-0.9-5.6-3.01-5.6-5.31-0.1-1.91 1-2.61 3.4-2.91z" fill="#FF91A4"/>
      <path d="m195.1 102.3c5.5-0.6 11.3-1.7 17.1-2.21 2.6-0.29 1.7-2.1 0.5-1.9-5.4 0.3-10.3 0.9-17.7 1.8-1.4 0.21-1.8 2.61 0.1 2.31z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="3.2"/>
      <path d="m193.2 112.1c5.7 1.2 9.6 2.5 15.5 4.61 1.2 0.5 1-0.6 0.1-0.7-5.6-2.11-8.6-3.11-15.2-4.31-1.2-0.3-1.5 0.1-0.4 0.4z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="4.2"/>
      <path d="m36.21 113.9c-0.1-1.1 0.4-1.5 2-1.5l15.1-0.2c2.2-0.1 1.6 1.9-0.1 1.9l-15.7 1.11c-0.8 0-1.2-0.4-1.3-1.31z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="3.2"/>
      <path d="m43.11 130.1c-0.5-0.9 0.2-1.4 1.2-1.9l12.6-5.82c1.9-0.9 2.4 1.41 0.9 2.21l-13.1 6.51c-0.8 0.3-1.2-0.2-1.6-1z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="4.2"/>
      <path d="m177.2 166.8c-1.8-9.05-4.3-14.87-9.1-23.71l-5.1 2.01c-2.9-4.41-4.9-7.81-5.2-11.72l-9.5-8.45-13.6-1.7-6.5 12.95 2.8 16.25 6.8 3.71-1.1 21.7h39.1l1.4-11.04z" fill="#FFC8A2" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m86.81 150c-4.6 7.83-8.8 18.48-8.8 27.83h58.7c0-6.62 0.5-11.64 3-19.7-15.8 3.91-37.6 2.11-52.9-8.13z" fill="#FFC8A2" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m131 124.2c2.9-5.22 9.7-6.33 14.6-2.21 5.6-3.31 12.5 0.2 12.1 6.71 5 3.11 5.4 7.62 1.2 11.53l-3.5-6.02-8.4-6.21-8.4 2.71-5.6 1.2c-5.9 1.1-8.4 8.65-3.8 13.26 1 1 1.4 1.6 1.2 3-0.7 5.02 4.2 9.53 9.5 7.87l-2.8-14.85 1.5-9.28 7.5-3.91 7.7 5.01 3.3 3.01 10.6 15.36" fill="#D2EEF9"/>
      <path d="m138.8 132.3c1.9 2.41 2.9 4.41 3.2 6.82" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.6"/>
      <path d="m146.3 128.8c1.9 1.41 2.8 3.21 3.3 5.92" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.6"/>
      <path d="m151.5 169.6c-8.5-7.95-17-21.5-14.5-33.85 1.8-8.26 11-10.06 17.5-3.25 4.2 4.51 6.6 11.13 13.1 18.87" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m101 167.5-1.4 6.12" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m69.81 120.7c-6.4 1.01-7.8 5.42-3.9 8.02 5.3 3.41 12.1 1.31 14.2-1.7 3.2-4.41-3.2-7.02-10.3-6.32z" fill="#FFE4CC"/>
      <path d="m174.8 113c-5.8 2.31-6.7 7.12-0.4 8.63 5.8 1.4 10.6-0.91 11.8-3.71 2.4-5.32-3.7-7.62-11.4-4.92z" fill="#FFE4CC"/>
      <path d="m47.21 141.6c-6 0.5-9.1 7.22-6.9 12.34 2.7 6.32 9.8 6.23 13.3 2.62 5.2-5.22 1.6-14.46-6.4-14.96z" fill="#C2E8F6" stroke="#5AA8CB" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.6"/>
      <path d="m48.21 145.3c-2.9 0.6-3.5 3.91-1.4 5.22 2.5 1.51 5.1-0.4 5-2.61-0.1-2.01-1.9-3.01-3.6-2.61z" fill="#FEFFFE" fill-opacity=".71"/>
      <path d="m193.7 140.6c-5.5 0.7-6.5 7.02-4 10.33 3.5 4.71 9.3 2.51 10.5-1.9 1.3-4.42-2-8.73-6.5-8.43z" fill="#C2E8F6" stroke="#5AA8CB" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.6"/>
      <path d="m194.7 143.8c-2.7 0.3-3.4 3.3-2 4.81 2 2.21 5 0.71 5.2-1.6 0.2-1.91-1.3-3.41-3.2-3.21z" fill="#FEFFFE" fill-opacity=".71"/>
      <path d="m210.8 179.1h-173.4c-7.6 0-8.3 13.66 0.5 13.86l3.5 0.1 8.5 33.3c2.5 9.45 9.9 15.76 18.7 15.76h111c8.8 0 17-7.65 18.5-15.76l9.4-33.6h3.1c8.5 0 8.8-13.66 0.2-13.66z" fill="#88CDEF" stroke="#3588B1" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.6"/>
      <path d="m41.41 193.1 2.1 7.01h138.7l-7.1 26.79c-2.7 9.45-10.4 14.66-16.4 14.66l19.7 0.1c9.3 0 18.1-7.74 19.7-16.19l8.9-32.37h-165.6z" fill="#5DAED8"/>
      <path d="m210.8 179.1h-173.4c-7.6 0-8.3 13.66 0.5 13.86l3.5 0.1h169.2c8.5-0.3 8.8-13.96 0.2-13.96z" fill="#88CDEF" stroke="#3588B1" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.6"/>
      <path d="m205.8 178.3c0.3-5.41-4.9-9.52-11.9-7.52-2.5-6.92-7.4-8.52-12.2-7.82-5.6 0.8-8.7 4.71-10.1 10.03-6.3-3.21-9.9 1.2-11.3 5.31h45.5z" fill="#D2EEF9" stroke="#90D0E0" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m180.9 166.5c-3.9 0.6-4.1 5.62-0.5 6.32 3.3 0.7 5.2-2.71 3.8-4.92-0.8-1.1-2-1.6-3.3-1.4z" fill="#FEFFFE"/>
      <path d="m122.9 178.3c-0.5-6.01-7.7-11.23-15.5-6.01-0.8 0.6-1.4 1.2-2.2 0.7-3.5-2.21-6-1.3-8.2 1-2.2-3.51-6.1-4.81-9.7-3.51-1.5-8.26-7.4-13.67-15.5-13.17-7 0.5-11.7 5.81-13.2 11.63-8.6-2.51-14.5 3.95-14.5 9.36h78.8z" fill="#D2EEF9" stroke="#90D0E0" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m69.21 162c-2.9 1.7-2.1 5.71 1.2 6.11s4.5-3.01 3-5.21c-1-1.6-3-1.8-4.2-0.9z" fill="#FEFFFE"/>
    </svg>
    """


    static let sickSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" fill="none" viewBox="0 0 200 200">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m193 60.98c-8.86-4.27-21.87-6.25-32.59-7.01-1.4-6.02-6.48-8.8-13.23-13.9 1.63-1.76 2.12-3.89 1.83-4.95-1.12-4.06-9.8-6.33-14.18-5.32-3.39 0.79-3.28 2.49-2.86 6.81-9.24 1.16-21.32 2.66-21.93 13.12-0.05 0.85-0.15 1.18-1.29 0.95-12.42-2.69-28.12-3.4-43.25 2.51-5.34 2.22-2.57 9.14-0.39 12.33-23.34-1.09-53.61 10.85-58.72 43.59-0.76 4.98-1.09 10.56-0.28 14.87-5.12 13.18 0.13 31.05 20.14 40.06 18.72 8.5 46.05 7.71 61.49 0.67 5.1-2.4 8.77-5.04 10.77-7.42 8.82 2.43 27.69 2.34 32.98-1.17 1.01-0.67 2.12-1.96 2.12-1.96 3.8 3.56 11.74 3.46 18.47 2.15 10.69-2 21.93-8.35 20.06-19.74-0.33-1.69-1-3.09-1.3-3.65 4.5-3.36 8.14-7.61 9.96-11.08 3.04 1.37 5.39 3.27 7.21 5.31 0.94 0.57 0.92-0.9 0.45-1.46-1.69-2.03-3.83-3.68-6.43-4.98 0.73-1.78 1.17-3.03 1.67-4.83 3.34 0.45 6.3 1.31 8.49 2.38 0.97 0.39 1.1-1.03 0.31-1.47-2.37-1.34-5.3-2.2-8.25-2.8 0.55-2.2 0.8-4.2 0.93-5.63 3.64-0.4 6.8-0.1 9.02 0.53 1.07 0.29 1.1-1.18 0.09-1.52-2.29-0.81-5.44-1.02-8.97-0.69 0.46-6.62-2.51-15.54-5.29-23.52 7.06-4.72 12.1-10.95 14.4-17 1-2.38 0.63-4.35-1.43-5.18z" fill="#000" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m160.4 55.36c9.8 0.05 23.33 2.65 32.17 6.36 2.27 0.97 2.16 3.34 0.83 6.19-3.66 7.82-9.09 12.55-14.04 15.54l-6.05-12.52-12.91-15.57z" fill="#FFC8A2" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m192.3 63.05c-5.12 5.91-7.56 10.86-16.8 14.02l2.16 4.7c6.19-4.06 12.01-10.51 14.64-18.72z" fill="#E08858"/>
      <path d="m66.36 54.21c11.96-5.43 28.82-5.22 42.05-2.05 1.3 0.4 2.01-0.17 2.01-1.93 0-9.02 9.9-12.12 22.36-12.9l13.58 1.59c6.95 5.91 12.38 8.17 12.55 15.99 0.16 6.45-5.12 8.71-10.07 7.28-5.43-1.59-9.49-4.18-15.08-4.35-6.78 1.13-16.85 2.14-21.23-4.61-1.12-1.01-3.38 0.49-4.67 0.08-12.62-4.15-28.98-3.2-41.17 1.6-2.85 1.17-2.68 4.02-0.75 8.22 3.39 7.66 8.18 13.57 13.93 19-3.75 7.49-5.06 14.82-4.05 22.97-2.85-0.32-5.73-0.29-8.7 0.89-0.84 0.39-0.34 1.68 0.59 1.35 2.63-0.85 5.26-0.85 8.28-0.28 0.24 2.03 0.6 3.87 1.12 5.64-2.4 0.53-5.03 1.42-7.74 3.01-0.81 0.56-0.41 1.6 0.56 1.21 2.47-1.04 4.86-1.85 7.83-2.27 0.73 2.03 1.3 3.12 1.97 4.47-2.26 1.29-4.52 2.96-6.68 5.55-0.73 0.85 0.32 1.66 1.13 0.85 2.04-2.04 3.98-3.44 6.24-4.64 6.29 9.24 16.03 15.53 23.9 18.04-4.44-0.24-6.6 0-6.6 0.33 0 0.47 1.4 0.47 4.03 0.47 5.54 0 9.14 1.25 12.71 1.9 7.81 1.43 15.46 2.54 18.31 8.45 1.76 4.22-1.21 6.17-5.51 7.14-8.95 1.76-17.63 0.75-27.21-1.13 1.01-4.72-0.84-11.64-9.33-12.11-3.66-0.24-6.51 0.87-9.55 1.34-2.16-1.94-1.99-6.66-1.52-10.71 0.08-0.85-1.08-0.93-1.33 0-1.2 3.72-1.11 7.78-0.56 11.25l-3.05 1.11c-1.94-3.9-5.74-5.34-10.45-5.58 6.58-9.24 5.76-26.3-8.94-34.66-5.35-3.16-12.92-3.16-18.04-0.17-0.73 0.39-0.4 0.72 0.33 0.47 11.2-3.21 20.14 1.74 25.17 10.42 4.6 7.9 3.3 18.28-2.8 26.02 6.1-1.35 10.73 0.41 13.2 4.31-11.71 4.31-28.07 4.31-39.47 0.76-6.95-2.38-13.53-7.1-14.34-11.16-0.39-1.01-0.98 0.24-0.65 1.36 1.54 5.08 8.04 9.88 16.53 11.92 11.79 2.99 24.48 2.12 35.46-1.19 7.37-2.18 12.07-4.54 18.9-5.02 8.11-0.47 10.37 5.11 9.16 9.6-2.63 9.02-16.75 13.58-32.03 15.02-14.7 1.29-32.46-1.65-42.12-7.08-15.61-9.02-19.5-22.26-17.47-35.16l1.3 1.94-0.93-10.95c1.01-27.7 20.64-50.75 53.29-51.4l6.2-0.08c-3.39-5.21-4.83-10.41-0.65-12.12z" fill="#FFC8A2" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m160.1 57.04c10.31 6.74 18.04 19.02 22.79 39.67 2.71 10.21 1.87 15.45-2.59 24.17-5.6 10.13-15.67 16.41-29.87 19.09-13.69 2.76-29.22 2.76-43.14-1.65-15.45-5.07-25.76-14.88-28.73-30.85-1.46-8.53-0.45-17.56 3.05-25.87-7.37-5.19-12.91-13.53-14.85-18.88 3.23 5.91 7.93 12.26 14.03 15.72 0.94 0.49 2.96-0.08 3.05-1.54 1.3-5.07 5.18-9.68 10.05-11.64-7.45-4.31-13.95-6.49-23.36-7.05-2.27-0.16-2.51 2.61-1.83 3.9l-0.52-1.88c-0.57-2.18 0.44-3.11 2.47-2.95 9.16 0.69 14.69 2.14 23.49 7.23-5.24 2.26-8.72 7.45-9.83 12.23-0.39 1.37-1.36 1.13-2.09 0.57-5.33-3.9-9.76-10.25-12.22-15.28-1.1-2.38-1.01-4.5 1.45-4.5 8.41-0.09 16.44 1.65 23.81 6.29 0.57 0.4 0.33 2.16-1.37 2.24-4.38 0.25-8.83 6.16-9.85 10.35 3.13-7.53 6.16-10.02 10.02-11.39-8.05-5.6-15.34-6.44-23.2-7.01-1.55-0.16-2.36 0.77-2.16 2.06-0.6-2.14 0.12-3.36 2.32-3.44 8.84-0.24 16.79 0.49 25.18 5.48 0.81 0.49 0.81 2.63-1.31 3.32 4.21-1.97 8.51-3.4 13.03-2.3 1.93 0.49 2.18-2.98 3.19-2.05 5.04 4.64 11.62 4.23 19.35 2.94 4.45-0.73 9.4 1.9 14.94 3.49 6.19 1.85 11.73-0.33 13.66-4.46 3.66 1.96 7.4 4.86 10.54 8.17 0.73 0.85 1.2-0.91 0.29-1.94-2.63-3.16-6.1-6.23-9.79-8.81v-3.43z" fill="#FFC8A2"/>
      <path d="m65.61 68.88c-23.69-0.73-51.7 10.13-57.08 39.15 4.95-25.41 25.5-39.07 57.08-39.15z" fill="#FFE4CC"/>
      <path d="m133.5 147.4c2.04-3.98 5.26-4.47 10.46-5.13 4.37-0.57 8.25-1.58 12.79-3.34l2.07 3.55c2.18 3.29 8.08 2.2 9.2-1.79 0.73-2.49-0.21-4.61-1.89-5.62l2.62-1.59c2.63 2.69 2.96 8.76-0.61 13.76-5.34 6.36-14.2 8.4-21.77 8.4-7.03 0-14.17-1.19-12.87-8.24z" fill="#FFC8A2" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m135.1 150.7c3.12 2.58 9.15 2.5 14.97 1.07 7.04-1.77 12.71-4.68 16.02-8.74-2.87 3.16-6.09 3.57-8.13 3-2.75-0.85-2.59-4.03-3.8-5.25-3.88 1.67-7.13 1.88-11.34 2.73-3.97 0.85-7.11 2.61-7.72 7.19z" fill="#E08858"/>
      <path d="m84.74 116.9c7.37 11.84 21.49 19.2 42.6 19.85 11.68 0.44 20.28-0.73 27.74-3.02l3.04 2.46c-9.57 4.48-24.36 5.82-38.04 3.43-15.76-2.7-28.3-8.69-37.06-19.97l1.72-2.75z" fill="#E08858"/>
      <path d="m68.45 135c0.76 2.16 2.26 3.01 4.81 2.85 2.12-0.16 3.41 0.88 3.98 2.39l0.23 4.64-2.09 0.77c-1.76-3.74-5.37-5.33-10.24-5.72l3.31-4.93z" fill="#E08858"/>
      <path d="m98.12 151.4c4.79 2.67 12.8 3.78 19.74 3.45 4.45-0.24 9.15-0.94 12.95-2.9l1.12 1.27c-4.87 3.86-20.48 4.18-31.88 1.59l-1.93-3.41z" fill="#E08858"/>
      <path d="m7.07 133.1c0.65 10.3 7.07 20.85 19.12 25.49 17.84 7.28 39.42 7.85 56.44 2.18 6.69-2.42 11.81-5.47 15.09-8.62-2.54 5.75-9.65 11.55-23.46 14.29-17.02 2.98-36.57 0.33-48.15-5.51-12.63-6.61-19.04-16.18-19.04-27.83z" fill="#E08858"/>
      <path d="m132.8 30.61c3.39-1.68 9.33-1.03 13.85 2.44 3.13 2.28 2.74 4.04 0.96 6.3-1.21 1.59-1.82 2.32-4.77 2.32-5.04 0-10.57-2.95-11.06-5.54-0.49-2.26-0.66-4.52 1.02-5.52z" fill="#000" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m133 31.44c3.39-1.68 7.99-1.03 12.51 1.78 3.14 1.94 3.14 3.53 1.84 4.89-1.65 1.76-3.25 2-5.63 1.67-5.04-0.69-8.93-2.69-9.42-4.86-0.49-1.7-0.57-2.71 0.7-3.48z" fill="#C1E8F0" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m114.1 42.16c-3.56 3.08-3.95 6.71-2.01 10.6 2.86 5.08 9.52 5.65 16.89 4.56 6.48-1.04 8.26-0.61 15.02 1.85 6.76 2.59 12.29 2.59 13.99-2.84 1.67-5.6-1.99-9.81-10.48-14.99l-1.45-2.25c-1.85 1.68-5.18 1.52-8.32 0.49-2.97-1.02-4.8-2.49-5.3-3.57-7.28 0.73-13.6 1.94-18.34 6.15z" fill="#76CBEA" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m113.9 42.4c-2.87 2.84-2.38 6.83 1.1 9.51 4.44 3.33 8.57 2.76 15.47 2.01 6.56-0.69 10.13 1.15 15.74 3.32 4.6 1.69 9.72 1.17 10.69-2.57 0.57-2.28-0.45-4.64-2.22-4.15-2.63 0.73-3.12-0.41-3.61-3.1" fill="#89D3F5"/>
      <path d="m124.6 43.91c3.05-2.78 6.35-4.66 9.4-5.07" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m136.8 47.82c0.33-2.9 0.99-5.01 2.56-5.66 2.63-1.1 6.68 1.75 9.06 6.46" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m118.8 76.33c-2.14 3.38-5.1 4.22-8.84 4.63" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.16"/>
      <path d="m109.9 84.73c-8.94 0.41-13.81 8.4-13.4 16.56 0.49 8.56 6.69 16.48 14.25 16.07 8.3-0.49 14.7-8.43 14.7-17.29 0-8.45-7.16-15.7-15.55-15.34z" fill="#000" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m110.6 85.06c-7.72 0-13.46 6.27-13.46 14.17 0 0.67 0.05 1.33 0.14 1.98l27.3-5.19c-1.45-6.27-6.69-10.96-13.98-10.96z" fill="#E08858"/>
      <path d="m97.72 102.2c1.89 6.46 7.19 10.77 13.49 10.52 7.56-0.33 13-6.99 13.16-14.61 0-0.62-0.05-1.24-0.14-1.85l-15.45 3.28-11.06 1.36c-0.16 0.69-0.16 0.61 0 1.3z" fill="#FEFFFE" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m106.9 101.2 4.21-1.1 11.14-2.47c0.25 0.77 0.09 1.97-0.16 3.08-1.38 5.35-5.04 7.21-8.69 6.89-3.14-0.24-5.48-1.94-6.21-3.89l2.54-0.85-2.83-1.66z" fill="#000"/>
      <path d="m157.1 85.47c-7.94 0.65-11.41 8.19-11.16 14.47 0.33 7.92 6.73 14.67 13.85 14.26 7.56-0.49 12.9-8.03 12.9-15.58 0-7.2-7.25-13.8-15.59-13.15z" fill="#000" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m158.4 86.04c-6.84-0.41-11.14 5.02-11.63 10.37l25.1 4.72c0.41-1.52 0.41-2.35 0.33-4.02-0.66-6.21-6.2-10.62-13.8-11.07z" fill="#E08858"/>
      <path d="m147.1 97.64c-0.65 7.38 5.07 13.37 11.71 13.13 5.94-0.25 10.64-4.81 12.44-9.85l-11.4-1.77-11.31-2.74c-0.73-0.17-1.3 0-1.44 1.23z" fill="#FEFFFE" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m159.3 101.1 4.7 0.65c-1.01 1.86-2.95 2.87-4.56 1.94l-0.14-2.59z" fill="#000"/>
      <path d="m150.3 77.35c1.94 3.07 4.9 4.01 8.13 4.09" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.16"/>
      <path d="m134.6 109.2c-2.44 0.57-1.95 3.24 1.1 4.75 2.71 1.29 3 1.12 4.21 0 2.46-2.27 3.57-4.95-0.24-5.12-1.94-0.08-3.3-0.08-5.07 0.37z" fill="#F8B64C" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m137.8 121 7.84-0.33 16.67 13.71c2.45 1.01 5.66 1.01 6.15 4.65 0.49 3.98-2.47 5.76-4.83 5.76-3.23 0-4.99-2.44-5.49-5.51l-21.07-16.06 0.73-2.22z" fill="#FEFFFE" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m146.4 127.8 12.95 9.81c1.54 0.57 1.69 0.4 2.02 2.2 0.49 2.3 1.79 2.63 3.26 2.38 1.6-0.32 2.17-1.91 1.85-3.5-0.41-1.76-2-2.41-3.77-2.08l-14.74-10.6-1.57 1.79z" fill="#D8422E" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".72"/>
      <path d="m147.9 128.9-0.84 1.01" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m150.1 130.6-1.01 1.21" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m152.5 132.4-1.26 1.45" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m154.7 134.1-1.27 1.54" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m130.1 125.8c1.94-2.58 4.71-3.6 7.67-3.68l7.64-0.41" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.4"/>
      <path d="m137.8 114.7-0.16 6.42" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.4"/>
      <path d="m180.1 108.8c3.05-1.01 8.4-1.74 13.6-0.45" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.4"/>
      <path d="m179 114.8c3.79 0.41 8.5 1.93 12.72 3.38" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.4"/>
      <path d="m176.9 120.1c3.39 1.21 8.09 4.51 10.98 7.19" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.4"/>
      <path d="m72.52 62.35c3.8-1.19 9.03 0.62 14.95 3.96l-3.74 10.1c-4.87-2.5-10.31-10.1-11.21-14.06z" fill="#FFE4CC"/>
    </svg>
    """

    static let celebratingSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="250" height="250" fill="none" viewBox="0 0 250 250">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m149.8 191.6c11.64-0.6 24.2-4.48 33.24-20.86 4.27-7.53 7.32-16.63 15.3-16.63 4.99 0 7.6 6.69 7.34 12.13-0.79 16.89-21 33.56-42.47 34.14-5.33 0.15-10.04-0.64-13.36-1.65l-0.05-7.13z" fill="#FFC8A2" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m150.6 196c3.51 1.11 8.08 1.76 13.03 1.35 17.23-1.44 34.62-14.12 39.28-28.24 2.21-6.69-0.75-12.94-5.11-12.99 2.61 1.28 4.71 5.8 2.26 12.54-5.14 14.77-21.15 26.64-36.93 27.5-4.25 0.25-8.52 0-12.53-0.86v0.7z" fill="#000" opacity=".2"/>
      <path d="m152.2 206.2c3.91-1.22 7.87-1.27 10.83 6.76 3.46 9.92 1.81 15.82-3.98 16.28-4.72 0.41-8.44-5.39-9.17-8.94l2.32-14.1z" fill="#E08858" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m88.08 200c-0.93 9.82-0.42 25.41 13.98 30.48 3.05 1.12 6.87 1.07 8.21 0.61-2.41 0.46-5.02 0.15-5.02 3.06 0 5.85 2.86 9.55 6.93 9.19 6.63-0.61 8.17-10.63 8.17-16.83 0-3.8-2.86-5.33-4.56-5.33l0.93-7.38 9.77-0.87-1.38-1.11-37.03-11.82z" fill="#FFC8A2" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m110.3 231.1c-1.54 0.36-3.54 0.36-5.48 0.1 1.28 0.92 3.17 0.87 4.14 0.41-0.92 1.48-0.61 6.34 1.24 8.3 1.85 1.97 6.19 0.25 7.52-5.09 1.02-4.28 1.02-9.4-0.51-11.22-1.13-1.33-2.87-1.38-3.74-0.98l0.41-2.6 1.28-0.4 0.46-4.43-2.96 0.25-0.72 5.29c1.74 2.61 1.28 7.42-1.64 10.37z" fill="#000" opacity=".2"/>
      <path d="m85.82 170.1c-10.89-3.34-24.01-11.27-28.62-18.95-4.11-6.79-0.35-14.12 8.89-12.35 7.02 1.37 13.11 9.2 29.9 15.3l0.62 0.15c-10.59-4.76-22.5-15.09-26.27-23.33-5.68-12.88-1.12-26.84 2.94-34.77l-4.67-12.77c-0.87-16.08 3.58-41.09 11.36-44.64 5.38-2.51 23.01 11.96 27.52 19.54 7.43-8.14 23.7-9.76 42.44 5.77 7.98-5.62 19.94-10.09 31.28-10.85 7.88-0.56 7.52 15.72 5.78 24.67-1.7 9.05-4.86 17.23-7.27 26.06 2.51 10.02 2.26 21.1-2.61 32.39-2.41 5.6-6.13 9.05-10.99 12.6l1.59-3.7c8.18-2.07 11.24 1.87 10.37 7.05-2.05 10.83-19.13 17.83-28.1 24.42-1.38 1.07 0.93 6.15 2.37 10.43 2 6.3-0.16 14.78-0.41 19.69-0.21 3.25 1.07 4.62 3.18 5.33-1.49 4.62-3.7 13.25-11.68 14.06-8.73 0.87-13.59-4.84-17.31-12.48-7.32 1.58-18.79 0.46-26.01-2.99-8.03-3.8-16.01-11.48-16.21-25.63-0.1-5.06 0.77-11.01 2.47-16.97l-0.56 1.97z" fill="#FFC8A2" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m177.9 100c3.11 9.44 1.11 23.45-2.76 33.17-7.87 15.5-28.53 18.2-39.47 18.2-26.87 0.76-55.47-5.99-69.4-20.81 3.46 7.33 13.67 17.35 23.4 23.15 7.47 4.62 16.26 9.74 30.08 9.74 12.49 0 19.46-3.06 26.09-6.35 6.17-3.6 15.5-8.94 20.31-10.66 4.01-1.37 9.1-8 11.86-16.28 2.86-8.94 2.86-18.48-0.11-30.16z" fill="#000" opacity=".2"/>
      <path d="m130 189.2c0 11.87-8.13 18.91-17.72 18.91-11.33 0-18.91-9.15-18.91-21.02 0-10.94 8.33-20.28 17.17-20.28 11.33 0 19.46 11.46 19.46 22.39z" fill="#FEFFFE" opacity=".3"/>
      <path d="m57.92 140.9c-2.61 2.38-2.46 6.78 1.11 11.7 5.48 7.53 15.16 13.12 25.9 16.32l2.16-7.88c-7.17-2.53-14.04-7.87-19.37-11.87-4.01-3.06-6.87-10.44-9.8-8.27z" fill="#000" fill-opacity=".25"/>
      <path d="m89.45 202.7c1.79 5.7 6.8 9.4 11.61 11.03 4.16 1.37 7.73 1.63 10.09 1.37l0.46-1.97c-5.14-0.41-16.32-3.12-22.16-10.43z" fill="#000" fill-opacity=".25"/>
      <path d="m130 158.8c4.16 0.1 9.85-0.61 12.76-1.32 5.43-3.55 14.37-8.74 20.5-11.38 5.69-2.47 13.01-2.42 13.53 1.63 1.07 8.33-10.63 17.27-18.46 21.48-5.09 2.76-9.58 4.98-11.48 7.55" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m149.8 198c1.33 1.17 4.14 1.72 6.55 1.93" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m149.8 223.4c2.41-0.3 5.42-2.37 6.29-4.64" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m171.8 133.9c4.45 1.37 9.01 3.98 12.88 6.98" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m172.3 126.8c5.49-0.71 11.38-0.81 17.28 1.66" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m161.8 73.48c5-5.49 11.23-9.59 15.4-10.65 2.71-0.71 3.53 2.08 3.22 6.59-0.51 6.99-2.56 15.22-6.02 23.4-3.77-7.73-7.34-14.37-12.6-19.34z" fill="#FFE4CC" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m76.51 74.86c-0.62-9.15 0.71-20.76 4.53-26.71 1.08-1.82 2-0.91 3.74 0.56 4.17 3.7 8.13 8.32 9.62 12.8-6.68 3.34-10.79 6.54-17.89 13.35z" fill="#FFE4CC" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m83.04 49.32c-1.95 1.63-4.66 8.22-5.63 19.59l0.1 3.25c3.47-4.47 9.31-9.03 14.64-11-2.1-5.04-5.33-9.14-9.11-11.84z" fill="#000" opacity=".2"/>
      <path d="m137.7 17.78-30.49 40.23c9.83 8.28 24.13 11.58 43.38 9.31l-0.93-0.91-10.08-47.72-1.88-0.91z" fill="#F04849" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m137.2 9.1c-1.18-2.91-5.19-2.35-6.11 0.11-1.29 3.5 1.02 5.47 2.05 6.08-3.06-0.61-4.24 1.16-3.62 3.43 0.92 3.5 5.18 1.93 6.51 0.56l0.67-0.3c-0.72 2.07 1.43 5.17 4.49 5.17 2.81 0 4.46-2.59 3.95-5.5 2.96 0 4.96-1.63 4.96-3.95 0-2.37-2.21-3.64-5.07-3.39 1.33-2.06 1.59-5.17-1.37-6.18-3.56-1.32-5.79 2.08-6.46 3.97z" fill="#B078A7" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m134.1 30.99c0 3.95-3.15 5.72-5.91 5.72-0.77 0-1.49-0.15-2.11-0.41l6.24-8.28c1.07 0.61 1.78 1.68 1.78 2.97z" fill="#E08858" opacity=".5"/>
      <path d="m144.4 38.73c0.72 1.97 1.18 4.19 1.18 6.31 0 1.67-1.39 2.79-2.93 2.79-2.76 0-5.06-2.12-5.06-4.91 0-2.91 2.41-4.88 5.17-4.88 0.51 0 1.13 0.2 1.64 0.69z" fill="#E08858" opacity=".5"/>
      <path d="m128 46.92c-3.57 0-5.21 2.76-5.21 4.78 0 3.4 2.56 5.22 4.96 5.22 3.26 0 5.11-2.71 5.11-5.22 0-2.79-2.41-4.78-4.86-4.78z" fill="#E08858" opacity=".5"/>
      <path d="m112.7 52.62c3.31 1.37 4.44 4.23 3.31 6.4-0.87 1.82-2.61 2.58-4.1 2.68-1.44-0.91-2.83-1.97-4.21-3.14l5-5.94z" fill="#E08858" opacity=".5"/>
      <path d="m140 60.39c-4.07 0-5.35 3.35-5.35 4.92 0 1.12 0.31 2.13 0.88 2.94 3.11 0.26 6.42 0.21 9.94-0.15 0.21-0.71 0.31-1.52 0.31-2.38 0-2.9-2.41-5.33-5.78-5.33z" fill="#E08858" opacity=".5"/>
      <path d="m161.1 129.1c0 3.8-4.45 5.07-7.41 4.82-4.9-0.41-8.77-2.78-8.77-6.03 0-2.76 2.86-3.47 5.93-3.47 4.9 0 10.25 1.17 10.25 4.68z" fill="#FEFFFE" opacity=".3"/>
      <path d="m84.78 117.1c0 2.96-3.77 3.67-6.17 3.42-5.24-0.41-8.6-2.78-8.6-5.25 0-2.86 2.1-2.71 5.27-2.96 4.9 0 9.5 1.82 9.5 4.79z" fill="#FEFFFE" opacity=".3"/>
      <path d="m100.1 107.4c-0.82-7.33-5.27-13.78-12.14-13.78-6.43 0-11.48 5.9-11.94 10.86-0.15 1.62 1.69 1.62 2.36 0.61 2.66-4.15 5.72-6.94 10.72-6.94 5.28 0 8.5 5.45 9.37 10.06 0.26 1.22 1.84 0.86 1.63-0.81z" fill="#000"/>
      <path d="m131.3 113.9c2.51-6.6 7.07-8.36 12.08-8.01 5.53 0.41 8.49 4.88 10.03 10.83 0.46 1.77 2.97 1.21 3.13-0.81 0.51-6.99-5.83-13.43-12.26-13.43-7.88 0-12.04 5.33-13.99 10.57-0.62 1.77 0.25 2.68 1.01 0.85z" fill="#000"/>
      <path d="m101 119.6c0.36 3.5 2.77 5.12 5.07 5.12 3.17 0 4.81-2.07 5.68-4.68 1.03 2.37 3.43 5.08 6.59 5.08 2.46 0 4.51-1.57 6.46-4.04" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m105.3 125.2c0.3 5.6 1.84 11.6 6.94 11.19 5.24-0.4 6.88-5.31 7.81-9.46-3.01 1.01-8.35 0.15-14.75-1.73z" fill="#000"/>
      <path d="m108.8 113.2c0 2.37 2.05 5.03 4.81 5.03 2.77 0 5.18-2.22 5.18-3.79 0-1.62-2.97-2.13-5.38-2.13-2.15 0-4.61-0.71-4.61 0.89z" fill="#FEDC82" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m108.4 133.2c0.46-2.17 2.67-3.79 5.33-3.79 1.89 0 3.33 0.51 4.3 1.37-1.33 2.81-3.23 5.08-6.34 5.08-1.7 0.05-2.78-1.01-3.29-2.66z" fill="#F7636D" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width=".5"/>
      <path d="m48.81 105.2c4.9 0 11.08 1.82 14.8 4.04" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m48.81 118.6c3.91-1.82 9.01-2.83 14.8-3.14" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path d="m40.08 65.66c-3.87-3.95-6.63-11.78-5.45-13.25 0.82-1.06 4.48-2.43 5.45-2.74 1.34-0.45 2.11-0.35 2 1.72-0.3 4.86 1.75 8.36 3.54 9.73 1.13 0.91 0.41 2.08-0.41 2.48-1.38 0.66-4.14 2.03-5.13 2.06z" fill="#FFD563" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m216.7 62.58c2 0.51 4.41 1.11 4.72 2.18 1.17 4.05-1.84 11.38-4.35 12.55-0.72 0.3-5.96-1.22-6.93-2.13-0.77-0.76-0.1-1.57 0.57-2.28 2.96-3.15 3.21-6.7 3.06-9.66-0.05-1.12 0.67-1.27 2.93-0.66z" fill="#F7B179" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m205.1 89.38c1.02-1.06 3.07 1.9 4.35 3.32 0.82 0.91 0.62 1.77-0.2 3.24-2.51 4.2-6.77 6.67-9.18 7.12-1.33 0.26-4.39-4.04-4.96-4.85-0.46-0.76 0.41-1.26 1.64-1.67 4.21-1.31 6.21-4.4 8.35-7.16z" fill="#59CC79" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m91.13 16.71c1.64-1.11 3.79-3.58 5.33-4.09 2.26-0.81 7.65 5.49 7.65 10.78 0 1.62-0.21 1.32-1.28 2.23-1.64 1.42-4.15 2.69-5.02 2.59-1.13-0.1-0.67-2.07-1.69-4.54-1.18-3.05-3.23-4.92-4.97-5.78-0.92-0.45-0.92-0.65-0.02-1.19z" fill="#66D9D4" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m36.82 90.09c-0.31-1.37 1.59-1.47 2.61-1.88 4.01-1.57 5.29-3.79 6.37-6.3 0.56-1.37 1.95-0.92 2.62-0.21 1.38 1.42 3.23 3.04 3.23 4.21 0 2.37-5.74 8.87-9.9 9.37-1.39 0.16-4.62-4-4.93-5.19z" fill="#F65792" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m172.9 34.79c2.1-4.77 6.37-8.17 10.43-9.54 2.16-0.76 3.8 1.66 5.08 3.98 0.82 1.52-0.1 2.48-1.18 2.63-4.6 1.17-7.26 4.47-8.9 7.92-0.57 0.96-1.54 0.25-2.26-0.86-1.18-1.67-3.58-3.19-3.17-4.13z" fill="#C375A7" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m27.89 126.9c0.62-1.92 1.9-4.88 2.82-5.64 1.18-0.96 2 0.41 2.77 1.63 2.31 3.4 5.42 4.62 8.43 4.82 1.74 0.1 1.84 1.17 1.18 2.64-0.82 1.97-2.47 4.63-3.44 4.63-4.5-0.4-10.44-4.6-11.76-8.08z" fill="#6495E6" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
      <path d="m206.8 126.2c0-2.12 2.15-2.42 4.51-3.69 1.64-0.91 2.05-0.31 2.15 1.41 0.31 4.1 2.15 7.11 4.15 8.88 1.18 1.06 0.87 2.28-0.1 2.79-1.44 0.81-4.4 2.33-4.97 2.02-3.31-1.72-6.02-8.52-5.74-11.41z" fill="#F04849" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.2"/>
    </svg>
    """

    static let deadSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" fill="none" viewBox="0 0 200 200">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m66.19 34.07c1.43-9.25 7.66-22.86 12.44-22.86 7.36 0 19.18 16.53 23.4 26.36l0.31 0.39c6.64 4.81 13.59 9.52 16.37 14.15 3.05-2.1 5.98-4.97 8.18-5.5-2.18 1.65-4.95 3.48-7.08 6.48 1.27 2 2.44 4.08 3.25 5.6 3.13-1.05 5.75-1.52 8.83-1.9-2.15 1.16-5.67 1.56-8.08 2.78 1.67 4.34 2.44 9.04 1.08 16.52-1.3 7.13-4.75 13.7-7.03 17.24 6.62-3.12 15.32-9.15 22.16-9.37 4.89-0.16 6.96 3.21 6.17 6.55-1.41 6.26-9.24 12.1-15.28 17.28 6.08 4.6 11.97 11.09 14.52 18.35 10.16 3.47 24.55 9.12 24.88 17.57 0.28 7.25-9.08 7.66-20.46 5.2-3.64-0.8-6.32-1.35-9.74-0.69l-2.4 3.04c7.2 6.51 13.6 9.38 23.56 8.65 10.62-0.8 15.62-7.73 23-9.69 6.64-1.81 10.84 2.4 10.48 7.4-0.83 9.47-14.44 17.26-29.96 17.44-13.26 0.16-25.01-4.85-35.63-16.75l-0.35-0.49 0.1-0.09-0.5-0.51-0.64 0.64-0.88 0.67-0.7 0.56c3.82 7.53 8.67 19.15 5.14 25.7-2.22 4.29-7.57 4.8-13.71-0.08-5.59-4.42-9.53-11.8-15.31-18.57-9.2-2.79-16.23-13.03-20.82-25.05-7.57 4.89-15.72 11.82-23.63 11.82-4.58 0-7.74-3.25-6.45-7.89 1.95-7.38 11.48-13.61 17.51-20.31-10.69 1.18-21.54 0-29.01-5.94-3.66-1.69-9.89-8.99-12.9-17.96l-3-6.93c-10.12-8.7-17.8-20.95-19.01-32.58-0.35-3.54 1.64-4.83 7.46-6.13 6.64-1.51 13.66-1.51 21.45-0.59 8.25-10.85 20.15-18 32.28-20.97v0.46z" fill="#FFC8A2" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m137.3 155.1c-2.08 2.62 0.74 7.75 11.67 12.92 9.18 4.5 21.74 4.26 29.91-0.12 8.09-4.28 14.69-7.49 14.3-12.88 0.97 2.74 0.74 7.68-7.47 13.66-8.74 6.47-20.03 7.02-29 5.4-9.67-1.88-17.92-7.86-23.04-12.66-2.49-2.45-2.25-4.69-1-5.4 1.4-0.8 2.87-1.7 4.63-0.92z" fill="#E08858"/>
      <path d="m145 127.2c2.16 0.63 17.96 6.02 23.17 11.86 2.48 2.91 2.64 6.67-0.37 8.74-4.04 2.77-14.54-0.64-19.71-2.07-2.93-0.83-3.29-3.36-3.17-4.99-0.97-0.71-2.06 0.16-2.93 2.34l-1.82 4.16 4.87 0.75c6.56 1.79 15.61 3.22 20.66 1.2 4.35-1.71 5.3-6.11 3.35-9.28-4.16-6.77-17.06-10.97-23.85-13.38l-0.2 0.67z" fill="#E08858"/>
      <path d="m144 86.22c2.26 2.03 0.61 7.66-6.19 13.84-3.83 3.58-7.69 6.65-9.65 7.36l-4.24-2.7c4-1.04 9.98-5.54 13.18-8.54 4.63-4.3 6.18-8.05 6.9-9.96z" fill="#E08858"/>
      <path d="m122 63.16c2.26 8.97-0.83 20.02-10.36 31.92-8.74 11.04-23.21 20.21-35.5 21.88-15.8 2.37-25.41 1.12-33.8-3.05-7.24-4.44-12.26-11.97-15.27-17.18 3.86 9.39 9.56 18.94 16.2 22.68 9.52 5.6 20.86 5.72 32.12 3.46 13.3-2.86 24.76-7.94 33.69-18.79 7.67-9.47 15.58-22.37 14.71-33.96-0.24-2.66-0.95-5.03-1.79-6.96z" fill="#E08858"/>
      <path d="m78.99 18.92c3.2-1.51 11.03 8.39 14.12 16.04-5.98-1.95-12.62-2.3-16.78-1.95 0-4.16 0.75-12.78 2.66-14.09z" fill="#FFE4CC" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m78.91 19.4c-1.59 1.81-2.3 8.62-2.18 12.71l1.98-0.2c-0.4-3.93 0.36-9.77 1.91-11.84 0.39-0.83-0.44-1.54-1.71-0.67z" fill="#E08858"/>
      <path d="m98.21 37.18c7.67 3.86 17.2 11.53 19.57 14.93" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m115.7 54.93c1.54-2.78 7.25-7.3 10.99-8.52" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m118.3 59.13c2.86-1.55 8.49-2.42 13.2-2.62" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m35.31 54.11c9.13-11.59 21.91-20.23 38.81-21.49 6.37-0.51 12.73 0.16 18.71 2.1" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m29.03 63.63c-3.86-2.37-13.78-2.92-15.81-0.98-2.03 1.93 4.85 13.52 11.22 19.06 0.73-7.87 2.22-12.79 4.59-18.08z" fill="#FFE4CC" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m13.77 63.79c0.04 1.85 5.41 11.91 10.16 16.11 0.39-4.88 1.28-10.74 3.31-14.19-3.82-2.35-11.32-3.69-13.47-1.92z" fill="#E08858"/>
      <path d="m83.62 136.1c-1.71 0.16-11.91 9.83-20.3 13.28-5.58 2.37-9.8 1.34-10.94-1.48-0.67 3.3 2.33 5.45 5.99 4.9 7.91-1.16 17.17-9.85 23.94-13.71 3.41 9.25 9.39 18.52 20.65 24.12 5.21 6.81 11.19 17.5 17.95 22 4.9 3.23 8.51 2.01 9.77-0.9 2.03-5.6-2.87-16.8-5.65-26.19 7.28-4.3 14.16-11.21 17.88-16.8" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m121.1 103.1c9.53 3.46 20.78 12.16 24.23 27.68" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m116.5 110.4c-10.74-0.83-19.4 7.86-18.57 19.02 0.83 10.34 9.53 18.66 19.73 17.83 10.39-0.83 18.07-9.95 16.84-18.62-1.23-9.5-8.51-17.41-18-18.23z" fill="#FFE4CC"/>
      <path d="m57.22 73.88-4.68 19.06c-0.42 1.67 1.34 2.89 2.74 2.45 0.93-0.31 1.56-1.1 1.76-2.08l3.2-18.4c0.43-2.37-2.35-3.41-3.57-1.98-0.28 0.28 0.51 0.32 0.55 0.95z" fill="#000"/>
      <path d="m46.91 80.18 19.01 3.55c2.78 0.55 2.19 4.72-0.59 4.4l-18.3-3.85c-2.86-0.67-2.51-4.69-0.12-4.1z" fill="#000"/>
      <path d="m85.76 53.71 17.83 3.85c2.78 0.75 1.52 5.29-1.26 4.93l-16.92-4.22c-2.86-0.83-2.03-4.95 0.35-4.56z" fill="#000"/>
      <path d="m95.11 47.32 1.16 0.19c1.5 0.32 2.17 1.58 1.86 3.05l-3.45 16.9c-0.67 2.87-4.9 2.2-4.47-0.67l3.45-17.66c0.2-1.1 0.75-1.81 1.45-1.81z" fill="#000"/>
      <path d="m85.05 72.93c1.23 0 1.58 1.94 0.99 3.88-0.63 2.07-0.99 2.82-2.14 3.21-1.55 0.59-5.78 0-6.29-1.93-0.39-1.68 5.2-5.16 7.44-5.16z" fill="#FCD26E" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m84.97 80.02 1.95 3.08 6.9 0.43" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m84.22 83.1-0.24 1.14-0.2 0.94-0.4 1.81-0.23 1.02-0.08 0.4-0.04 0.31 0.04-0.11 0.04-0.16" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m109.2 102.4c2.33-2.44 4.93-6.24 6.88-8.31" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m25.53 116.9c3.2-3.86 7.7-7.72 13.68-8.86" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m35.12 125.1c1.95-4.88 4.69-8.74 7.43-11.91" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m68.92 123.6c4.52-0.83 9.04-2.37 14.23-4.3" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m57.93 97.72c-4.26 0.71-7.71 4.57-7.77 7.4-0.08 2.37 2.54 2.96 5.68 1.59 3.93-1.75 5.96-4.42 5.88-6.37-0.08-1.83-1.59-3.01-3.79-2.62z" fill="#FFE4CC"/>
      <path d="m112.6 62.1c-3.85 0-7.3 3.46-8.05 6.29-0.67 2.25 1.53 3.04 4.35 2.21 3.94-1.26 6.28-4.33 6.71-5.87 0.59-1.81-0.76-2.91-3.01-2.63z" fill="#FFE4CC"/>
    </svg>
    """

    static let cryingSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" fill="none" viewBox="0 0 200 200">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m194.4 139.8c-0.7-12.01-7.57-24.3-16.41-24.48-6.26-0.13-9.74 6.5-8.03 12.94 1.67 6.62 6.65 12.44 6.55 21.04-0.11 7.57-6.33 15.3-11.78 15.83l-1.9 10.92c16.13-0.09 32.8-13.28 31.57-36.25z" fill="#FFC8A2" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m193.2 140.2c-0.28 8.83-5.38 19.52-15.79 25.58-2.49 1.52-3.56 1.45-4.55-1.58-0.6-1.97-0.71-2.25-2.73-1.05-2.13 1.27-3.15 1.73-4.71 1.97l-2.1 10.34c13.81-0.34 30.61-11.24 29.88-35.26z" fill="#000" opacity=".2"/>
      <path d="m119.9 16.01c10.31 1.44 28.37 9.73 49.42 17.23 5.32 2.02 6.64 5.39 3.42 10.11-5.7 8.34-12.87 11.8-21.4 14.73 2.1 5.66 3.38 12.83 2.6 21.03-1.44 15.91-10.45 27.95-14.13 30.97 8.03 9.68 26.13 24.65 26.13 49.54 0 12.47-6.24 24.49-22.09 27.99-6.43 1.47-15.71 2.36-23.41 2.91-6.6 0.49-10.27-2.38-12.69-8.31-2.7 3.5-5.52 4.62-8.94 4.3-2.9-0.28-3.87-0.89-4.97-3.36-2.7 2.77-7.38 2.56-9.59 0.21-5.31 0.62-10.1 0.55-16.74 0.62-7.42 0.07-12.47-8.17-12.96-15.07-0.35-5.66 2.93-9.15 7.19-8.8 3.38 0.29 5.56 1.41 7.7 3.5 1.51-3.85 3.21-5.87 5.97-8.19-0.97-10.15-0.97-18.46-0.42-27.69-16.28-1.54-30.78-6.91-41.85-20.92-6.78-6.43-8.49-17.54-6.99-27.99 0.63-4.06 1.6-8.76 2.09-13.67l0.21-5.05c-8.17-1.67-15.59-5.38-20.6-11.6-3.67-4.49-2.4-8.55 3.3-10.57 11.15-3.99 23.66-10.89 34.96-15.73 3.53-1.54 7.63-2.53 10.04-4.4 10.94-6.9 22.63-9.31 33.71-9.31 12.23 0 20.59 1.8 33.32 7.52h-3.28z" fill="#FFC8A2" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m151.9 57.37c7.82-2.89 16.02-8.88 19.91-16.05-6.91 6.62-15.41 11.39-29.76 8.69-4.45-0.83-5.89-1.52-7.09-1.93 2.29 4.27 7.16 7.13 13.79 8.87l-0.35 1.41 3.5-0.99z" fill="#000" opacity=".2"/>
      <path d="m28.91 53.47c-8.1 0.28-14.8-2.35-20.88-6.37 3.18 6.76 12.29 11.81 20.11 12.86l1.12-5.86-0.35-0.63z" fill="#000" opacity=".2"/>
      <path d="m150.5 58.15-1.92 0.49c2.28 6.97 2.14 14.07 0.21 21.55-4.52 0.69-4.94 2.07-4.94 2.07 1.93-0.21 3.6-0.56 4.52-0.56-1.2 5.12-1.69 7.01-5.16 12.2-8.43 13.02-21.95 22.96-47.02 25.66-20.5 2.35-42.38-1.08-55.47-10.45-2.83-2.09-5.04-3.99-6.97-5.72 6.19 11.49 19.2 21.03 41.59 23.92l-0.14 2.51c6.56 3.39 18.11 4.52 27.89 1.53 13.09-4.21 20.58-7.3 35.96-21.52 8.4-7.84 15.89-19.09 15.75-33.6 0-6.22-1.04-12.37-4.3-18.08z" fill="#000" opacity=".2"/>
      <path d="m53.93 18.92c-13.66 8.33-23.72 22.26-26.21 40.9" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m135.2 48.08c8.36 2.83 17.57 2.62 26.52-0.42" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m141.6 110c-8.24 8.33-17.12 11.9-27.92 13.69" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m143.6 82.81c5.32-2.09 11.82-2.83 20.39-1.64" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m143.1 90.05c4.98 0 10.22 1.26 17.27 3.78" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m141.2 97.22c4.52 0.92 8.84 3.52 14.68 7.94" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m75.17 155.1c1.27 11.12 3.06 19.92 8.24 28.01" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m69.86 166.8c-2.1-3.09-5.14-5.69-9.83-4.64-3.91 0.92-4.12 5.55-3.11 9.6 1.27 5.3 4.79 11.16 10.35 11.16 3.74 0 7.9-0.35 12.49-1.2" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m143.9 148.6c-11.76-0.7-20.36 6.13-24.03 18.6" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m107.9 177.6c-2.9 5.19-6.08 7.82-9.99 7.82-4.73 0-4.66-3.71-3.22-14.23 1.64-11.87 4.13-21.1 4.62-31.26" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m121.8 142.6c-0.84 7.24-3.53 16.11-6.23 22.4" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m122.8 172.8c-3.6-6.3-6.99-7.39-10.44-7.11-5.31 0.42-6.58 5.43-5.95 11.92 0.64 6.36 3.95 12.36 11.54 12.36 5.63 0 18.22-2.02 25-3.47 12.16-2.8 21.94-10.35 21.94-26.47" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m56.85 166.1c0.49-1.95 2.28-3.01 4.21-1.74 3.18 2.09 4.38 6.68 5.42 10.94 0.58 2.57 1.95 2.86 4.44 2.3 4.32-1.05 5.03-0.91 4.11-4.69-0.9-3.88-1.32-6.11-2.06-8.09l-1.84 3.03c-2.21-3.03-4.91-5.41-8.72-5.55-3.42-0.14-5.98 1.3-5.56 3.8z" fill="#000" opacity=".2"/>
      <path d="m109.9 171.3c2.42-1.2 4.84 3.4 6.28 10.38 0.71 3.49 2.37 3.21 4.93 3 11.76-0.81 22.68-2.26 29.11-6.61 7.96-5.33 12.63-12.06 13.5-17.5 1.1 10.1-4.97 22.61-17.92 26.11-8.71 2.57-17.85 3.03-25.13 3.24-7.56 0.21-11.69-4.11-13.19-10.33-0.97-4.2-0.28-7.22 2.42-8.29z" fill="#000" opacity=".2"/>
      <path d="m88.26 152c1.67 2.7 2.57 5.4 2.22 10-0.55 6.59-1.11 15.04-1.46 17.06s0 3.56 1.12 4.19c-3.11 1.44-5.18 0.42-7.01-3.15-1.51-3.2-4.9-11.23-5.7-21.53-0.28-3.53-0.35-5.33-0.35-7.49l4.76 0.14 6.42 0.78z" fill="#000" opacity=".2"/>
      <path d="m84.71 140.8c0.42 4.59 4.03 10.36 9.66 15.41 1.57 1.44 2.7-2.27 3.12-7.96 0.42-5.72 0.28-9.71-3.04-11.67-4.73-2.7-10.23-0.48-9.74 4.22z" fill="#FEFFFE" opacity=".3"/>
      <path d="m124.2 64.02c-11.08 1.13-22.36-1.22-27.34-9.49 0.64 3.34 3.06 5.21 5.76 6.58-7.42 2.56-12.22 9.73-12.22 16.9 0 9.75 7.5 18.02 18.33 18.02 1.99 0 3.94-0.3 5.78-0.87 2.42 0.21 3.09 1.85 1.84 4.87-2.14 5.3-2.42 13.39 4.08 13.81 5.38 0.35 7.67-7.13 4.63-12.82-1.44-2.86-3.93-5.21-2.96-8.74 0.56-2.35 3.12-5.55 4.56-10.88 1.44-6.36-0.36-12.36-4.56-16.96 0.7-0.07 1.35-0.21 2.1-0.42z" fill="#000" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m117.9 65.51c5.05 3.3 7.15 10.98 5.68 17.51-0.37 1.69-0.98 3.31-1.83 4.8l2.45-0.75c1.1-2.28 2.07-4.81 2.35-7.83 0.49-5.73-2.28-11.38-5.42-14.52l-3.23 0.79z" fill="#FEFFFE"/>
      <path d="m102.1 66.5c-4.33 0-6.32 4.06-6.32 6.42 0 3.5 2.69 4.69 4.97 4.69 4.39 0 6.95-3.99 6.95-6.79s-2.14-4.32-5.6-4.32z" fill="#FEFFFE"/>
      <path d="m114 78.22c-2.83 0-3.56 3.99-1.07 5.01 3.18 1.3 4.61-1.97 3.31-3.87-0.56-0.85-1.39-1.14-2.24-1.14z" fill="#FEFFFE"/>
      <path d="m122.3 87.14c-3.04-1.3-5.97-0.28-8.39 1.91-3.18 2.86-8.98 1.42-12.87 0.36-2.35-0.64-3.99-0.29-4.41 0.63 3.53 3.93 9.01 5.77 15.51 4.88 4.62-0.64 6.69 1.19 4.55 6.66-1.9 5.13-0.87 10.6 3.65 10.6 4.2 0 6.13-6.22 3.36-11.23-2.21-4.09-4.8-6.03-2.87-9.99 0.66-1.48 1.82-2.54 1.47-3.82z" fill="#99DEF9" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.08"/>
      <path d="m122.2 101.7c-2-0.55-2.84 3.13-1.94 5.21 0.9 2.12 3.46 0.99 3.46-1.61 0-1.9-0.56-3.28-1.52-3.6z" fill="#FEFFFE" opacity=".7"/>
      <path d="m37.34 67.42c9.09-0.81 17.97-3.09 23.37-11.36-1.8 3.9-3.54 5.05-4.66 5.97 8.16 1.12 13.96 10.1 13.96 17.27 0 9.75-7.24 17.56-17.3 17.21-2.8-0.14-4.6-0.7-7.5-0.14-5.3 1.05-8.03-3.74-7.13-6.96 0.87-3.3 3.36-2.55 0-4.25-2.42-3.89-2.14-12.52 2.75-17.53l-3.49-0.21z" fill="#000" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m41.93 68.44c-4.52 3.55-5.29 11.68-3.12 17.47 0.42 1.16 1.52 1.44 2.41 1.3l-2.28 0.92c-1.13-1.61-2.33-3.4-2.75-6.43-0.9-5.72 1.62-11.34 4.25-13.69l1.49 0.43z" fill="#FEFFFE"/>
      <path d="m50.27 68.72c-3.91 0.92-5.42 4.34-5.42 6.29 0 3.21 2.32 4.44 4.38 4.23 3.98-0.42 5.72-4.02 5.72-6.53 0-2.63-1.74-4.69-4.68-3.99z" fill="#FEFFFE"/>
      <path d="m60.19 81.01c-2.28 1.12-1.93 4.76 0.77 4.76 2.59 0 2.87-2.7 1.81-4.21-0.71-1.02-1.95-0.95-2.58-0.55z" fill="#FEFFFE"/>
      <path d="m39.84 90.96c-0.21-3.54 3.92-3.19 7.27-1.9 2.9 1.12 4.34 3.15 9.07 2.7 2.97-0.3 4.77-1.65 7.23-1.83 1.2-0.07 1.55 0.53 0.91 1.69-2 3.19-7.4 4.79-11.36 4.19-3.84-0.58-5.03-0.72-7.02-0.3-3.01 0.72-5.89-0.98-6.1-4.55z" fill="#99DEF9" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".7"/>
      <path d="m74.34 91.17c0.28-1.76 2.08-1.69 5.61-1.76 3.32-0.07 4.59 0.21 4.38 1.83-0.28 2.02-3.29 4.72-4.96 4.51-2-0.21-5.46-2.34-5.03-4.58z" fill="#F7D16A" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m73.98 107.5c1.77-3.6 3.84-5.11 6.7-5.11 3.46 0 6.26 1.87 8.62 4.31" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m79.52 95.33v6.32" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m30.28 91.02c-3.53-1.05-8.15-0.91-14.79 1.05" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m32.63 98.12c-3.86 0.63-7.21 2-12.58 4.8" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
      <path d="m36.37 104.6c-3.74 2.21-7.46 5.23-11.42 8.63" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"/>
    </svg>
    """

    static let lonelySittingSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" fill="none" viewBox="0 0 200 200">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m118.6 25.79c3.79-7.62 16.03-19.61 22.16-20.18 8.18-0.77 12.47 22.18 12.9 33.22l-0.77 0.42c-9-8.42-19.68-12.44-32.8-13.44l-1.49-0.02z" fill="#FFC8A2" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m127.8 27.02c3.99-6.26 10.03-13.11 13.43-12.57 4.93 0.78 7.12 13.46 6.8 20.47-5.83-4.25-11.37-6.31-20.23-7.9z" fill="#FFE4CC" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m80.87 120.9c-15.69-7.11-26.11-21.58-24.5-43.73 0.28-3.28 0.89-6.51 1.84-9.65-4.58-15.69-1.3-37.09 3.82-50.23 2.21-4.96 4.96-4.89 7.03-4.77 8.2 0.45 19.87 10.23 26.81 16.15 6.29-2.25 11.74-2.9 19.79-3 21.28-0.3 42.31 9.42 51.46 31 2.7 6.38 3.25 11.46 4.2 15.4 0.79 3.45 3.86 7.08 4.17 12.08 1.23 16.17-12.18 30.22-35.48 37.37 0.81 4.35 1.3 8.26 0.8 16.37l-1.63 39.04c3.51 2.37 4.56 6.09 3.34 9.67-1.45 3.94-5.55 4.12-10.34 3.33-2.02 0.49-3-0.56-3.27-0.16-2.25 4.4-12.09 5.8-17.7-0.86-1.29-1.62-2.1-2.96-3.09-4.74l-3.09 0.94c-0.25 4.76-2.67 8.38-13.62 8.54-8.9-0.08-21.35-0.79-27.12-3.7-2.17-1.08-4.33-3.75-5.38-4.88-17.2 2.8-32.54-6.46-36.99-20.82-4.66-15.11 3.69-25.38 3.39-33.12-0.24-8.08-8.22-13.18-9.59-20.37s4.74-14.14 13.76-13.99c13.28 0.24 19.33 13.12 19.83 23.38 0.78 13.92-8.2 24.52-8.92 35.52-0.62 9.28 5.52 15 12.53 16.4-1.71-14.5 2.99-26.16 13.13-35.4 5.93-5.56 10.39-7.92 14.82-15.77z" fill="#FFC8A2" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m140.1 121.6c-19.43 5.62-43.23 6.05-57.42-0.43 12.1 7.56 27.12 13.24 47.22 10.99 3.41-0.39 6.75-1.27 10.08-2.24-0.08-2.8-0.37-5.19 0.12-8.32z" fill="#E08858"/>
      <path d="m139.7 144.7c-2.76 10.04-7.55 18.68-13.53 23.6l0.4 5.04c7.14-3.36 12.21-15.2 13.13-28.64z" fill="#E08858"/>
      <path d="m48.41 171.3c-0.43 4.92-0.5 9.19 1.83 12.64l7.58-0.62-4.11-10.53c-1.83-0.37-3.62-0.85-5.3-1.49z" fill="#E08858"/>
      <path d="m125.9 153.7 1.23 26.27c2.98 1.69 4.13 6.98 1.65 10.02" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m134.9 184.9c0.31 1.97 0.15 3.5-0.63 4.7" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m138.9 184.1c0.31 1.59-0.12 3.44-1.2 4.69" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m104 160.8c0.97 10.9 4.33 21.3 8.19 27.4 2.98 4.77 9.17 6.16 12.84 5.1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m121.5 188.8c0.97 1.55 0.89 3.1 0.2 4.5" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m79.24 151.7c10.58-0.79 18.17 8.04 18.4 17.48 0.08 3.94-0.88 7.52-2.52 10.05 4.69 0.69 9.89 1.48 10.2 7.82" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m93.42 186.8c2.44 1.41 2.2 4.11 1.77 6.36" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m98.61 187.5c1.37 0.97 1.21 2.71 0.32 4.26" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m174 77.81 7.75-2.78c2.25-0.79 2.33-0.27 1.82 0.88l-8.82 3.3-0.75-1.4z" fill="#FFC8A2" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="3"/>
      <path d="m175.6 86.21 7.3 1.15c1.05 0.16 0.81 0.85 0.31 0.85l-7.51-1.5-0.1-0.5z" fill="#FFC8A2" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/>
      <path d="m168.8 64.91c2.16 9.26-0.67 19.05-7.88 19.05-5.99 0-10.79-8.89-10.79-18.33 0-7.48 2.99-11.88 6.7-11.88 5 0 10.09 2.66 11.97 11.16z" fill="#FEFFFE" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".75"/>
      <path d="m167 67.95c1.64 6.81 0.27 13.01-3.67 13.16-3.6 0.14-7.41-6.98-7.91-13-0.43-5.32 2.33-10.28 4.85-10.2 3.35 0.1 5.53 4.3 6.73 10.04z" fill="#000"/>
      <path d="m158.2 66.71c1.43 0 1.8-1.48 1.8-2.26 0-1.24-0.79-2.24-1.69-2.24-1.06 0-1.76 1.2-1.76 2.3 0 1.2 0.7 2.2 1.65 2.2z" fill="#FEFFFE"/>
      <path d="m115.2 60.55h1.56c8.97 0 15.54 9.08 15.54 17.5 0 8.96-7.22 15.86-15.54 15.86h-1.56c-9.52 0-16.59-7.2-16.43-15.62 0.16-9.58 7.24-17.74 16.43-17.74z" fill="#FEFFFE" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m120.9 65.71c6.88 0 11.05 7.54 10.82 13.3-0.3 7.12-5.7 11.4-10.5 11.16-5.99-0.31-10.86-6.34-10.86-12.36 0-6.5 4.69-12.1 10.54-12.1z" fill="#000"/>
      <path d="m116.4 74.91c1.93 0 2.35-1.55 2.27-2.5-0.16-1.3-1.2-2.2-2.35-2.2-1.3 0-2.27 1.2-2.27 2.35 0 1.25 1.05 2.35 2.35 2.35z" fill="#FEFFFE"/>
      <path d="m142.9 82.61c2.15-1.3 6.37-1.54 7.8-1.1 1.94 0.6 1.7 2.4 0.48 4.58-1.23 2.34-2.74 3.32-4.38 3.02-2.09-0.36-4.99-1.67-5.42-3.38-0.44-1.52 0.12-2.34 1.52-3.12z" fill="#FCD26E" stroke="#C4A030" stroke-linecap="round" stroke-linejoin="round" stroke-width=".75"/>
      <path d="m148.3 89.71c-0.16 4.1 1.21 5.5 5.4 5.92" stroke="#000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m148.3 90.41c-0.59 4.56-2.84 6.4-5.98 7.64" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m66.62 14.11c-6.64 11.16-4.39 32 3.29 49.88" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m98.28 33.35c-8.97-9.56-20-19.6-29.84-20.2" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m76.17 23.71c-4.11-1.76-5.89 2.24-4.92 11.56 0.69 6.48 3.29 14.9 4.8 19.94 0.36 0.96 4.56-4.08 7.46-7.38 3.43-3.88 6.41-6.78 6.84-8.52 0.7-2.72-10.24-14-14.18-15.6z" fill="#FFE4CC" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m70.12 95.21 15.93-0.9c1.86-0.1 2.11 2.3 0.16 2.5l-15.93 1c-1.94 0.1-2.26-2.34-0.16-2.6z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m76.01 108.1 12.7-7.13c1.94-1.15 3 1.35 1.05 2.35l-12.85 7.12c-1.55 0.88-2.69-1.34-0.9-2.34z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="m104.6 95.71c-5.84 0-8 2.58-7.92 4.8 0.07 2.78 3.21 4.3 7.58 4.14 4.8-0.16 7.41-2.6 7.33-5.04-0.07-2.25-2.43-3.9-6.99-3.9z" fill="#FFE4CC"/>
      <path d="m169.9 83.91c-2.98 1.12-4.03 3.1-3.44 4.7 0.89 2.44 3.34 1.92 4.21 1.5 2.35-1.08 3.04-2.94 2.44-4.8-0.51-1.56-1.81-1.96-3.21-1.4z" fill="#FFE4CC"/>
    </svg>
    """

    static let standingSVG = """
    <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" fill="none" viewBox="0 0 200 200">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m149.5 5.62c-7.59-0.55-19.7 17.46-21.56 22.04-16.68 0-27.88 4.52-37.36 10.97-9.11-4.15-18.41-6.99-29.47-6.99-17.49 0-8.65 31.35 4.65 52.32-0.58 9.02 1.88 17.97 6.97 25.77-8.86 0.56-16.66 3.02-22.71 8.99-11.97-2.09-26.56-15.71-17.62-32.81 4.37-8.15 7-11.04 5.56-17.94-1.86-7.56-8.46-10.7-15.31-9.26-11.21 2.58-17.1 17-17.37 30.21-0.58 14.99 9.63 36.87 31.67 41.89l4.1 1.44c-6.2 14.08-1.99 38.56 2.72 54.36 1.58 4.67 6.13 5.55 11.23 5.55 5.11 0 7.71-2.25 7.13-6.26-0.43-2.14-2.07-2.93-2.02-4.65 0.09-2.26 0.73-6.14 1.9-7.79 1.44-1.21 2.77-2.53 3.97-3.95 1.05 4.35 2.6 10.6 3.77 13.45 1.58 4.1 6.23 4.66 11.03 4.38 5.61-0.28 8.44-3.13 6.32-7.71-0.72-1.44-2.02-1.87-1.59-3.47l0.74-4.85c4.85 0.28 8.02 0 13.35-0.56 1.16 7.82 2.6 16.59 5.18 20.53 2.58 3.65 8.88 3.93 13.1 2.53 4.52-1.44 5.82-5.68 2.72-9.97l2.3-16.65c1.01 0 2.02-0.18 2.98-0.53 0.92 6.6 1.76 15.29 4.19 19.86 2.43 3.41 7.08 3.41 10.91 2.85 4.96-0.86 6.68-5.44 3.71-9.46l-0.58-1.44 4.65-32.23c3.98-7.28 4.41-13.87 4.55-26.81 14.17-7.32 31.14-19.37 32.3-37.77l0.43-2.7 6.6 3.27c3.25 0.56 2.96-3.46 0.38-3.46l-7.27-1.01-2.58-12.05c-3.01-7-7.22-12.69-11.74-18.66-1.58-12.04-11.35-40.83-21.93-41.43z" fill="#FFC8A2" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m147.8 147.1c-4.69 10.13-11.01 18.94-21.36 22.01l-1.21-1.99 0.59-0.32c11.01-2.84 18.52-11.65 21.98-19.7z" fill="#E08858"/>
      <path d="m67.91 167.6c5.86 2.17 12.6 3.17 18.3 3.58l-1.09 5.52c-0.14 1.11 1.03 1.71 1.71 2.97 2.29 4.29-0.68 7.43-6.14 7.43-4.71 0-8.68-0.83-10.12-4.48s-2.45-9.9-3.17-13.69l0.51-1.33z" fill="url(#paint0_linear_161_362)" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m39.12 117.2c-3.61 2.25-5.38 7.7-5.38 11.35l3.37 1.5 4.21 1.44 1.54-2.25 4.37-8.15c-2.42-0.72-6.13-2.33-8.11-3.89z" fill="#E08858"/>
      <path d="m152.9 118.7c-10.31 4.45-24.94 9.56-37.98 10.12-14.07 0.55-27.84-2.16-37.04-11.75l-1.86 0.55c10.78 10.69 25.93 17.38 44.87 17.66 10.49 0.14 20.12-3.05 31.59-7.63l0.42-8.95z" fill="#E08858"/>
      <path d="m139.2 28.22c6.85 2.14 13 4.99 19.31 8.89 1.58 1.15 2 0 1.28-3.34-1.58-7.18-5.41-18.16-9.63-18.16-4.37 0-10.96 10.43-10.96 12.61z" fill="#FFE4CC"/>
      <path d="m79.73 46.04c-4.52-2.14-7.82-3.29-13.52-4.3-4.07-0.56-5.65 2.16-5.22 6.45 0.72 6.59 3.97 16.74 7.22 19.3 1.44 0 3.7-7.47 8.65-13.78 2.87-3.79 5.3-6.24 2.87-7.67z" fill="#FFE4CC"/>
      <path d="m155.8 46.61c-8.94-0.43-15.24 7.86-15.24 17.05 0 9.2 7.8 16.38 15.6 15.37 9.67-1.21 14.48-8.11 14.19-16.12-0.58-7.76-6.33-15.9-14.55-16.3z" fill="#FEFFFE" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m155.3 47.47c-6.59 0-10.42 5.97-10.42 11.42 0 6.17 5.56 11.19 10.71 10.77 6.3-0.43 11.1-5.74 11.1-11.19 0-5.83-4.95-11-11.39-11z" fill="#000"/>
      <path d="m149.8 52.49c-2.02 0-2.75 1.44-2.75 2.52 0 1.6 1.35 2.56 2.45 2.47 1.72-0.14 3.02-1.67 3.02-3.02 0-1.25-1.16-1.97-2.72-1.97z" fill="#FEFFFE"/>
      <path d="m104.8 61.81c-10.78 0-17.38 8.41-17.38 18.28 0 9.19 7.31 15.74 15.96 15.46 9.25-0.28 17.05-8.04 16.76-16.94-0.28-8.58-6.58-16.8-15.34-16.8z" fill="#FEFFFE" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m106.6 63.25c-7.17 0-11.29 5.36-11.29 11.1 0 6.9 5.75 11.19 11.29 10.91 6.6-0.28 11.11-6.25 11.11-10.82 0-5.22-4.51-11.19-11.11-11.19z" fill="#000"/>
      <path d="m101.6 68.27c-2.29 0-3.01 1.44-3.01 2.45 0 1.6 1.07 2.32 2.23 2.18 1.72-0.14 2.74-1.58 2.74-2.73 0-1.06-0.68-1.9-1.96-1.9z" fill="#FEFFFE"/>
      <path d="m135.9 75.43c-3.69 0.86-7.52 1.72-7.52 4.13 0 2.71 4.37 4.15 6.67 4.15 3.25 0 4.69-4.29 4.69-6.43 0-1.71-1.58-2.41-3.84-1.85z" fill="#FCD26E"/>
      <path d="m136.3 84.82c0.43 3.13 3.41 5.13 8.35 4.7" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m136.3 85.11c0 3.41-1.58 6.25-5.54 8.4" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m177.5 79.71c-0.43 3.4-5.23 6.11-8.97 5.83-3.12-0.28-3.99-1.58-3.85-3.59 0.29-2.99 4.5-5.7 7.75-5.42 3.25 0.14 5.36 1.15 5.07 3.18z" fill="#FFE4CC"/>
      <path d="m103.2 101.2c0.43 3.69-4.51 6.54-8.73 6.54-3.97 0-5.69-1.57-5.69-3.72 0-3.34 4.52-5.92 8.35-5.92 3.11 0 5.83 0.97 6.07 3.1z" fill="#FFE4CC"/>
      <path d="m180.2 70.81 11.97-4.58c2.3-0.86 2.88 1.7 0.85 2.56l-12.39 4.29c-2.03 0.56-2.17-1.7-0.43-2.27z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m181.6 78.63 11.09 1.44c1.58 0.28 1.44 2.15-0.28 1.87l-10.66-1.73c-1.59-0.28-1.59-1.86-0.15-1.58z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m62.38 105.7 15.01-4.29c2.02-0.56 2.31 2.57 0 3.13l-14.04 3.13c-1.89 0.43-2.61-1.4-0.97-1.97z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m70.71 118.7 11.45-8.99c1.3-1.11 2.27 1.03 0.87 2.14l-10.92 8.35c-1.69 1.26-2.84-0.51-1.4-1.5z" fill="#E08858" stroke="#E08858" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.2"/>
      <path d="m100 169.1-0.96-7.77" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m122.3 158.2-2.83 24.91c3.25 3.13 2.97 8.45-1.88 10.15" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m113.2 188.8c-0.73 1.72-0.58 3.16 0 4.74" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m117.8 187.6c0.97 1.31 1.11 3.03 0.68 4.61" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m137.2 184.5c-0.58 1.72-0.44 3.16 0.14 4.73" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m141.7 184.5c0.43 1.15 0.57 2.41 0 3.63" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m52.18 186.2c0.58 1.44 0.58 3.01 0.29 4.45" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m57.13 185.7c0.97 1.44 1.11 3.16 0.53 4.73" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <path d="m72.01 155.1c-0.82 6.73-3.94 13.04-9.99 18.74-1.58 1.57-2.16 5.87-2.31 8.01" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width=".8"/>
      <defs>
        <linearGradient id="paint0_linear_161_362" x1="72.9" x2="83.32" y1="170.2" y2="185.3" gradientUnits="userSpaceOnUse">
          <stop stop-color="#E08858" offset="0"/>
          <stop stop-color="#E08858" stop-opacity=".75" offset="1"/>
        </linearGradient>
      </defs>
    </svg>
    """

    // Climbing pose — cat climbing up a wall (recolored from green SVG)
    private static let climbingSVG = ##"""
    <svg xmlns="http://www.w3.org/2000/svg" width="168" height="168" fill="none" viewBox="0 0 168 168">
    <!-- SVG created with Arrow, by QuiverAI (https://quiver.ai) -->
      <path d="m50.17 32.19 2.1-2.78c2.71-10.26 6.25-17.28 11.55-23.9 1.95-2.25 4.46-1.95 5.86-0.74 7.06 6.11 11.04 12.94 12.95 17.17 9.15 1.82 17.2 6.86 23.34 13.28 8.84-1.08 16.2 0.13 21.29 2.72 2.22 1.09 1.91 3.57 1.1 5.99-2.44 7.26-9.2 15.66-14.99 21.55-2.45 11.46-9.11 21.78-23.35 22.13 4.33 11.3 4.14 24.2 0.81 32.01-3.58 8.64-11.94 15.17-23.46 15.3-2.75 0.03-5.23-0.3-7.74-0.65-1.77-0.26-2.82-0.08-3.52 1.16-1.03 1.48-3.23 1.98-5.48 1.15-4.92-1.89-8.5-9.77-10.32-14.93-1.09-4.37 0.15-7.5 3.3-7.27 2.43-0.04 4.1 1.03 5.83 2.53l0.73-33.89c-2.99-5.94-6.56-10.61-9.73-15.09-2.51-3.6-1.75-11.16 4.37-11.22 2.25-0.03 4.02 0.75 5.36 1.68v-26.2z" fill="#FFC8A2"/>
      <path d="m53.38 28.71c1.63-7.48 4.71-15.05 10.49-22.01 1.84-2.29 4.04-2.46 5.74-1.07 5.56 4.66 9.67 10.73 12.18 15.88-10.67-1.57-20.55 0.76-28.41 7.2z" fill="#FFE4CC"/>
      <path d="m61.31 24.47c0.86-4.26 2.72-8.59 5.38-12.78 0.92-1.27 2.3-0.78 3.13 0.05 2.66 2.77 4.56 5.67 5.89 8.57-4.86-0.12-9.72 1.1-14.4 4.16z" fill="#FFE4CC"/>
      <path d="m106.8 35.93c7.27-0.97 14.24-0.19 19.89 2.56 2.15 1.04 2.26 2.93 1.45 5.42-2.49 7.6-8.69 15.37-14.48 20.91 1.09-9.61-1.25-20.14-6.86-28.89z" fill="#FFE4CC"/>
      <path d="m109.3 41.08c4.31-0.62 8.49-0.29 11.23 0.98 1.3 0.61 1.58 1.73 0.87 3.43-1.91 3.92-4.66 7.67-7.71 10.67-0.25-5.15-1.76-10.35-4.39-15.08z" fill="#FFE4CC"/>
      <path d="m53.07 30.11c7.22-6.3 16.01-9.5 24.85-9.12 19.1 0.85 36.69 15.92 36.57 37.73-0.1 13.27-8.84 29.12-24.4 28.79-10.38-0.23-19.61-5.6-24.27-8.89-3.9-8.53-8.81-16.23-14.81-21.01l2.06-27.5z" fill="#FFC8A2"/>
      <path d="m52.21 48.82-0.07 6.51c1.97 0.76 3.14-0.67 3.22-2.22 0.09-1.89-1.09-3.63-3.15-4.29z" fill="#FFE4CC"/>
      <path d="m63.39 36.69c-6.07-0.13-9.06 5.73-9.06 10.52 0 5.2 3.86 9.43 8.85 9.43 5.49 0 8.67-4.18 8.67-10.02 0-5.2-3.44-9.81-8.46-9.93z" fill="#FEFFFE"/>
      <path d="m64.31 40.96c-5.09 0-7.42 4.66-7.42 8.15 0 4.33 3.33 7.51 6.99 7.41 4.94-0.13 7.64-3.81 7.64-8.29 0-3.73-3.11-7.27-7.21-7.27z" fill="#2E2E2E"/>
      <path d="m68.01 44.93c-1.65 0-1.98 1.18-1.98 1.88 0 1.31 0.98 1.91 1.9 1.91 1.25 0 2.05-0.93 2.05-2.02 0-0.98-0.8-1.77-1.97-1.77z" fill="#FEFFFE"/>
      <path d="m93.75 53.95c-6.57 0-10.24 5.96-10.24 10.52 0 5.74 4.17 8.51 9.31 8.51 5.89 0 9.7-5.15 9.7-9.48 0-5.21-4.43-9.55-8.77-9.55z" fill="#FEFFFE"/>
      <path d="m91.26 56.72c-5.04 0-7.65 4.56-7.65 7.89 0 4.84 3.57 7.1 7.24 7.1 4.66 0 7.17-4.48 7.17-7.33 0-4.47-3.33-7.66-6.76-7.66z" fill="#2E2E2E"/>
      <path d="m90.31 58.32c-1.7 0-2.03 1.31-2.03 1.92 0 1.31 1.03 2.01 1.89 2.01 1.38 0 2.08-1.09 2.08-2.07 0-1.09-0.92-1.86-1.94-1.86z" fill="#FEFFFE"/>
      <path d="m95.95 74.93c-3.04-0.5-5.94 0.21-5.94 2.47 0 2.31 3.28 3.34 5.72 3.34 2.98 0 4.01-1.18 4.01-2.39 0-1.31-1.83-3.09-3.79-3.42z" fill="#FCD26E"/>
      <path d="m73.86 56.72c-1.7 0-1.97 1.09-1.8 2.07 0.27 1.43 0.76 3.32 1.9 3.82 1.19 0.55 2.74 0.55 3.99-0.38 1.29-0.98 1.73-1.58 0.87-2.74-0.98-1.26-2.91-2.77-4.96-2.77z" fill="#FCD26E"/>
      <path d="m73.41 63.7-1.43 1.53-2.76-0.06c-0.65 0-0.87 0.55-0.87 0.88 0 0.6 0.38 0.99 1.09 0.99l2.51-0.22 0.87 2.04c0.33 0.65 0.93 0.65 1.31 0.48 0.55-0.27 0.72-0.82 0.44-1.53l-0.93-2.36 0.87-1.53-1.1-0.22z" fill="#000000"/>
      <path d="m107.9 76.99c-0.98 0-1.36 0.71-1.36 1.31 0 0.49 0.38 1.04 0.87 1.42l4.71 2.9c0.98 0.6 1.74 0.11 2.07-0.44 0.49-0.82 0.11-1.65-0.76-2.2l-4.53-2.8c-0.39-0.17-0.66-0.19-1-0.19z" fill="#E08858"/>
      <path d="m103.9 81.7c-1.19 0-1.46 0.82-1.46 1.42 0 0.61 0.44 0.99 0.77 1.38l3.57 3.23c0.87 0.77 1.73 0.38 2.12-0.22 0.49-0.77 0.05-1.8-0.66-2.57l-3.1-2.85c-0.44-0.33-0.77-0.39-1.24-0.39z" fill="#E08858"/>
      <path d="m65.55 78.21c6.34 4.52 15.8 8.9 24.46 9.5l-0.87 2.42c-9.23-0.87-18.02-4.87-24.02-8.92l-0.6 0.43c-2.71-9.5-8.81-19.22-15.8-24.06l1.75-0.33c6.75 4.84 12.44 13.53 15.08 20.96z" fill="#E08858"/>
      <path d="m50.32 83.62 1.34 2.59-1.34 0.82v23.68l0.87-1.09c2.75-3.74 8.96-5.79 15.53-2.05 0.6 0.39 0.6 1.04 0.33 1.32-0.38 0.49-1.04 0.32-1.53-0.06-5.37-3.49-11.36-0.72-13.42 3.28-1.78 3.65-1.94 6.24-1.78 8.39 0.17 0.6 0 0.98-0.49 1.15-0.65 0.11-1.03-0.33-1.2-1.15-0.22-1.78-0.16-3.27 0.11-4.8l-0.55-0.49c-1.13-0.77-2.42-1.1-4.25-0.99-3.63 0.11-4.55 3.7-3.42 7.49 2.29 7.2 6.59 14.11 11.2 15.09 2.34 0.49 4.27-0.65 5.19-2.25 0.49-0.6 1.2-0.49 2.23-0.44 3.27 0.44 5.28 0.71 7.88 0.71-3.57 7.2-6.71 18.17-2.49 30.24l1.19 2.59h15.79c0.6-3.54-0.79-6.64-3.18-11.79-3.8-8.15-2.82-15.62-0.39-22.82l0.27 0.11c-6.28 2.9-14.59 1.76-17.02 1.27-1.97-0.44-3.27-0.27-4.3 0.94-1.44 1.77-3.54 1.99-5.5 1.28-5.09-1.89-8.84-9.6-10.94-14.93-1.29-4.18 0-7.46 2.75-7.46 2.34 0 3.88 0.71 5.58 1.97l1.54 0.5v-33.1z" fill="#FFC8A2"/>
    </svg>
    """##

    // Climbing eye paths (for blink)
    private static let climbingEyePaths = [
        ##"<path d="m63.39 36.69c-6.07-0.13-9.06 5.73-9.06 10.52 0 5.2 3.86 9.43 8.85 9.43 5.49 0 8.67-4.18 8.67-10.02 0-5.2-3.44-9.81-8.46-9.93z" fill="#FEFFFE"/>"##,
        ##"<path d="m64.31 40.96c-5.09 0-7.42 4.66-7.42 8.15 0 4.33 3.33 7.51 6.99 7.41 4.94-0.13 7.64-3.81 7.64-8.29 0-3.73-3.11-7.27-7.21-7.27z" fill="#2E2E2E"/>"##,
        ##"<path d="m68.01 44.93c-1.65 0-1.98 1.18-1.98 1.88 0 1.31 0.98 1.91 1.9 1.91 1.25 0 2.05-0.93 2.05-2.02 0-0.98-0.8-1.77-1.97-1.77z" fill="#FEFFFE"/>"##,
        ##"<path d="m93.75 53.95c-6.57 0-10.24 5.96-10.24 10.52 0 5.74 4.17 8.51 9.31 8.51 5.89 0 9.7-5.15 9.7-9.48 0-5.21-4.43-9.55-8.77-9.55z" fill="#FEFFFE"/>"##,
        ##"<path d="m91.26 56.72c-5.04 0-7.65 4.56-7.65 7.89 0 4.84 3.57 7.1 7.24 7.1 4.66 0 7.17-4.48 7.17-7.33 0-4.47-3.33-7.66-6.76-7.66z" fill="#2E2E2E"/>"##,
        ##"<path d="m90.31 58.32c-1.7 0-2.03 1.31-2.03 1.92 0 1.31 1.03 2.01 1.89 2.01 1.38 0 2.08-1.09 2.08-2.07 0-1.09-0.92-1.86-1.94-1.86z" fill="#FEFFFE"/>"##,
    ]
    private static let climbingClosedEyes = ##"""
    <path d="M56 47 Q63 52 72 47" stroke="#2E2E2E" stroke-width="2.5" stroke-linecap="round" fill="none"/>
    <path d="M84 61 Q92 66 102 61" stroke="#2E2E2E" stroke-width="2.5" stroke-linecap="round" fill="none"/>
    """##

    // Climbing animation: paw scramble + body bob
    private static func makeClimbingFrame(phase: Double, eyesClosed: Bool) -> String {
        // Alternate paw scramble: translate body up/down slightly, tilt for effort
        let scrambleY = sin(phase * 2) * 2.5      // fast vertical bobbing (scrambling paws)
        let effortTilt = sin(phase) * 1.5          // slight side-to-side effort
        let breathX = sin(phase * 0.7) * 0.5       // tiny horizontal sway
        let cx = 84.0, cy = 84.0

        var svg = climbingSVG
        if eyesClosed {
            svg = makeBlink(svg: svg, eyePaths: climbingEyePaths, closedEyes: climbingClosedEyes)
        }
        svg = svg.replacingOccurrences(
            of: "(https://quiver.ai) -->",
            with: ##"(https://quiver.ai) -->"##
            + "\n<g transform=\"translate(\(f(breathX)), \(f(scrambleY))) rotate(\(f(effortTilt)), \(f(cx)), \(f(cy)))\">"
        )
        svg = svg.replacingOccurrences(of: "</svg>", with: "</g>\n</svg>")
        return svg
    }

    static let medicine: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let W: UInt32 = 0xF0F0F8, R: UInt32 = 0xFF5555
        return [
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,B,B,B,B,T,T,T,T],
            [T,T,T,B,R,R,W,W,B,T,T,T],
            [T,T,B,R,R,R,W,W,W,B,T,T],
            [T,T,B,R,R,R,W,W,W,B,T,T],
            [T,T,B,R,R,R,W,W,W,B,T,T],
            [T,T,T,B,R,R,W,W,B,T,T,T],
            [T,T,T,T,B,B,B,B,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    static let milk: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let W: UInt32 = 0xF5F5FF, M: UInt32 = 0xFFFDE8
        let BW: UInt32 = 0xCC4444
        return [
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,B,M,M,M,M,M,M,M,B,T],
            [T,B,W,M,M,M,M,M,M,W,W,B],
            [T,B,BW,BW,BW,BW,BW,BW,BW,BW,BW,B],
            [T,T,B,BW,BW,BW,BW,BW,BW,BW,B,T],
            [T,T,T,B,BW,BW,BW,BW,BW,B,T,T],
            [T,T,T,T,B,B,B,B,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    static let treat: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let C: UInt32 = 0xDDA860, CH: UInt32 = 0x553322
        return [
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,B,B,B,B,T,T,T,T],
            [T,T,T,B,C,C,C,C,B,T,T,T],
            [T,T,B,C,CH,C,C,CH,C,B,T,T],
            [T,T,B,C,C,C,C,C,C,B,T,T],
            [T,T,B,C,C,CH,C,C,C,B,T,T],
            [T,T,T,B,C,C,C,CH,B,T,T,T],
            [T,T,T,T,B,B,B,B,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    static let fish: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let F: UInt32 = 0xFF8866, FD: UInt32 = 0xDD6644
        let E: UInt32 = 0xFFFFFF
        return [
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,B,B,B,T,T,T,T,T],
            [T,T,T,B,F,F,F,B,B,T,T,T],
            [T,B,B,F,F,E,F,F,F,B,T,T],
            [B,FD,B,F,F,F,F,F,F,F,B,T],
            [T,B,B,F,F,F,F,F,F,B,T,T],
            [T,T,T,B,F,F,F,B,B,T,T,T],
            [T,T,T,T,B,B,B,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    static let pawPrint: [[UInt32]] = {
        let T: UInt32 = 0, P: UInt32 = 0x6E6E85
        return [
            [T,P,T,P,T],
            [P,T,T,T,P],
            [T,P,P,P,T],
            [T,P,P,P,T],
            [T,T,P,T,T],
        ]
    }()
}

typealias Sprites = CatRenderer

// MARK: - Particle System

struct Particle {
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var life: CGFloat  // 0..1
    var decay: CGFloat
    var color: NSColor
    var size: CGFloat
    var type: ParticleType

    enum ParticleType {
        case heart, star, sparkle, note, poof, tear, confetti, zzz, dream, firefly
    }
}

class ParticleSystem {
    var particles: [Particle] = []

    func emit(at point: NSPoint, type: Particle.ParticleType, count: Int = 5) {
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 1...4)
            let color: NSColor
            let size: CGFloat
            switch type {
            case .heart:
                color = NSColor(red: 1, green: CGFloat.random(in: 0.2...0.5), blue: CGFloat.random(in: 0.3...0.5), alpha: 1)
                size = CGFloat.random(in: 6...12)
            case .star:
                color = NSColor(red: 1, green: 0.9, blue: CGFloat.random(in: 0.2...0.5), alpha: 1)
                size = CGFloat.random(in: 4...10)
            case .sparkle:
                color = NSColor(red: CGFloat.random(in: 0.8...1), green: CGFloat.random(in: 0.8...1), blue: 1, alpha: 1)
                size = CGFloat.random(in: 3...7)
            case .note:
                color = NSColor(red: 0.6, green: 0.8, blue: 1, alpha: 1)
                size = CGFloat.random(in: 5...9)
            case .poof:
                color = NSColor(white: 0.8, alpha: 0.7)
                size = CGFloat.random(in: 4...8)
            case .tear:
                color = NSColor(red: 0.4, green: 0.7, blue: 1, alpha: 0.9)
                size = CGFloat.random(in: 3...5)
            case .confetti:
                let colors: [NSColor] = [.red, .orange, .yellow, .green, .cyan, .magenta, .purple]
                color = colors.randomElement()!
                size = CGFloat.random(in: 3...6)
            case .zzz:
                color = NSColor(white: 0.9, alpha: 0.8)
                size = CGFloat.random(in: 8...14)
            case .dream:
                color = NSColor(red: 0.9, green: 0.85, blue: 1, alpha: 0.9)
                size = CGFloat.random(in: 10...16)
            case .firefly:
                color = NSColor(red: 1, green: 0.95, blue: CGFloat.random(in: 0.3...0.6), alpha: 0.9)
                size = CGFloat.random(in: 2...4)
            }
            let vx: CGFloat
            let vy: CGFloat
            switch type {
            case .tear:
                vx = CGFloat.random(in: -0.5...0.5)
                vy = -CGFloat.random(in: 1...3)  // fall downward
            case .zzz:
                vx = CGFloat.random(in: 0.5...1.5)
                vy = CGFloat.random(in: 1...2)  // drift up-right
            case .confetti:
                vx = cos(angle) * speed * 1.5
                vy = sin(angle) * speed + 4  // burst upward
            case .dream:
                vx = CGFloat.random(in: -0.3...0.3)
                vy = CGFloat.random(in: 0.5...1.0)  // drift up slowly
            case .firefly:
                vx = CGFloat.random(in: -0.8...0.8)
                vy = CGFloat.random(in: -0.3...0.5)  // wander
            default:
                vx = cos(angle) * speed
                vy = sin(angle) * speed + 2  // upward bias
            }
            particles.append(Particle(
                x: point.x + CGFloat.random(in: -10...10),
                y: point.y + CGFloat.random(in: -5...15),
                vx: vx,
                vy: vy,
                life: 1.0,
                decay: (type == .zzz || type == .dream) ? CGFloat.random(in: 0.008...0.015) : type == .firefly ? CGFloat.random(in: 0.005...0.012) : CGFloat.random(in: 0.015...0.035),
                color: color,
                size: size,
                type: type
            ))
        }
    }

    func update() {
        for i in (0..<particles.count).reversed() {
            particles[i].x += particles[i].vx
            particles[i].y += particles[i].vy
            let grav: CGFloat = (particles[i].type == .dream || particles[i].type == .firefly) ? 0.0 : 0.05
            particles[i].vy -= grav
            if particles[i].type == .firefly {
                particles[i].vx += CGFloat.random(in: -0.15...0.15)
                particles[i].vy += CGFloat.random(in: -0.1...0.1)
            }
            particles[i].life -= particles[i].decay
            if particles[i].life <= 0 {
                particles.remove(at: i)
            }
        }
    }

    func draw(in view: NSView) {
        for p in particles {
            let alpha = max(0, p.life)
            let color = p.color.withAlphaComponent(alpha)
            color.set()

            switch p.type {
            case .heart:
                drawHeart(at: NSPoint(x: p.x, y: p.y), size: p.size * alpha)
            case .star:
                drawStar(at: NSPoint(x: p.x, y: p.y), size: p.size * alpha)
            case .tear:
                let s = p.size * alpha
                let path = NSBezierPath()
                path.move(to: NSPoint(x: p.x, y: p.y + s))
                path.curve(to: NSPoint(x: p.x, y: p.y - s * 0.5),
                           controlPoint1: NSPoint(x: p.x - s * 0.6, y: p.y),
                           controlPoint2: NSPoint(x: p.x - s * 0.3, y: p.y - s * 0.5))
                path.curve(to: NSPoint(x: p.x, y: p.y + s),
                           controlPoint1: NSPoint(x: p.x + s * 0.3, y: p.y - s * 0.5),
                           controlPoint2: NSPoint(x: p.x + s * 0.6, y: p.y))
                path.fill()
            case .confetti:
                let s = p.size * alpha
                let rect = NSRect(x: p.x - s / 2, y: p.y - s / 4, width: s, height: s / 2)
                let path = NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1)
                path.fill()
            case .zzz:
                let s = p.size * alpha
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: s),
                    .foregroundColor: p.color.withAlphaComponent(alpha)
                ]
                "z".draw(at: NSPoint(x: p.x, y: p.y), withAttributes: attrs)
            case .dream:
                let s = p.size * alpha
                // Thought bubble circle
                let bubbleColor = p.color.withAlphaComponent(alpha * 0.6)
                bubbleColor.set()
                NSBezierPath(ovalIn: NSRect(x: p.x - s, y: p.y - s, width: s * 2, height: s * 2)).fill()
                // Small trail circles
                let t1 = s * 0.3
                NSBezierPath(ovalIn: NSRect(x: p.x - s * 1.2 - t1, y: p.y - s * 1.1, width: t1 * 2, height: t1 * 2)).fill()
                let t2 = s * 0.15
                NSBezierPath(ovalIn: NSRect(x: p.x - s * 1.6 - t2, y: p.y - s * 1.6, width: t2 * 2, height: t2 * 2)).fill()
                // Dream icon inside bubble
                let icons = ["\u{1F41F}", "\u{2764}\u{FE0F}", "\u{2B50}", "\u{1F9F6}", "\u{1F33C}"]
                let iconIdx = Int(p.x * 7 + p.y * 3) % icons.count
                let iconSize = s * 0.9
                let iconAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: iconSize)
                ]
                let icon = icons[abs(iconIdx)]
                icon.draw(at: NSPoint(x: p.x - iconSize * 0.4, y: p.y - iconSize * 0.4), withAttributes: iconAttrs)
            case .firefly:
                let s = p.size * alpha
                // Glow halo
                let glowAlpha = alpha * 0.3 * (0.7 + 0.3 * CGFloat(sin(Double(p.x + p.y) * 0.5)))
                NSColor(red: 1, green: 1, blue: 0.5, alpha: glowAlpha).set()
                NSBezierPath(ovalIn: NSRect(x: p.x - s * 2, y: p.y - s * 2, width: s * 4, height: s * 4)).fill()
                // Bright core
                p.color.withAlphaComponent(alpha).set()
                NSBezierPath(ovalIn: NSRect(x: p.x - s / 2, y: p.y - s / 2, width: s, height: s)).fill()
            default:
                let rect = NSRect(x: p.x - p.size * alpha / 2, y: p.y - p.size * alpha / 2,
                                 width: p.size * alpha, height: p.size * alpha)
                let path = NSBezierPath(ovalIn: rect)
                path.fill()
            }
        }
    }

    private func drawHeart(at point: NSPoint, size: CGFloat) {
        let s = size / 2
        let path = NSBezierPath()
        path.move(to: NSPoint(x: point.x, y: point.y + s * 0.3))
        path.curve(to: NSPoint(x: point.x - s, y: point.y + s),
                   controlPoint1: NSPoint(x: point.x - s * 0.5, y: point.y + s * 0.3),
                   controlPoint2: NSPoint(x: point.x - s, y: point.y + s * 0.7))
        path.curve(to: NSPoint(x: point.x, y: point.y - s * 0.5),
                   controlPoint1: NSPoint(x: point.x - s, y: point.y + s * 1.3),
                   controlPoint2: NSPoint(x: point.x, y: point.y))
        path.curve(to: NSPoint(x: point.x + s, y: point.y + s),
                   controlPoint1: NSPoint(x: point.x, y: point.y),
                   controlPoint2: NSPoint(x: point.x + s, y: point.y + s * 1.3))
        path.curve(to: NSPoint(x: point.x, y: point.y + s * 0.3),
                   controlPoint1: NSPoint(x: point.x + s, y: point.y + s * 0.7),
                   controlPoint2: NSPoint(x: point.x + s * 0.5, y: point.y + s * 0.3))
        path.fill()
    }

    private func drawStar(at point: NSPoint, size: CGFloat) {
        let r = size / 2
        let rect = NSRect(x: point.x - r, y: point.y - r, width: size, height: size)
        NSBezierPath(ovalIn: rect).fill()
        // Cross sparkle lines
        let path = NSBezierPath()
        path.lineWidth = 1
        path.move(to: NSPoint(x: point.x - r, y: point.y))
        path.line(to: NSPoint(x: point.x + r, y: point.y))
        path.move(to: NSPoint(x: point.x, y: point.y - r))
        path.line(to: NSPoint(x: point.x, y: point.y + r))
        path.stroke()
    }
}

// MARK: - Pet Stats

struct PetStats: Codable {
    var hunger: Double = 80
    var happiness: Double = 80
    var energy: Double = 80
    var social: Double = 80
    var hygiene: Double = 80
    var health: Double = 100
    var isSick: Bool = false
    var isDead: Bool = false
    var sickSince: Date? = nil
    var totalPets: Int = 0
    var totalFeedings: Int = 0
    var totalPlays: Int = 0
    var totalBaths: Int = 0
    var totalHeals: Int = 0
    var totalWalks: Int = 0
    var xp: Int = 0
    var level: Int = 1
    var lastSeen: Date = Date()
    var birthDate: Date = Date()
    var name: String = "Murchi"
    var poopCount: Int = 0
    var lastPoopClean: Date = Date()
    var accessory: String? = nil
    var milestones: [String] = []

    var mood: Mood {
        if isDead { return .sad }
        if isSick { return .sick }
        let avg = (hunger + happiness + energy + social) / 4.0
        if energy < 20 { return .sleepy }
        if avg < 25 { return .sad }
        if avg < 50 { return .neutral }
        return .happy
    }

    enum Mood: String, Codable {
        case happy, neutral, sad, sleepy, sick
    }

    var xpForNextLevel: Int { level * 150 + 100 }

    mutating func addXP(_ amount: Int) {
        xp += amount
        while xp >= xpForNextLevel {
            xp -= xpForNextLevel
            level += 1
        }
    }

    var evolutionStage: String {
        if level >= 20 { return "Cosmic Murchi" }
        if level >= 15 { return "Legendary Murchi" }
        if level >= 10 { return "Epic Murchi" }
        if level >= 5 { return "Cool Murchi" }
        return "Baby Murchi"
    }

    mutating func decay(seconds: Double) {
        let rate = seconds / 60.0
        hunger = max(0, hunger - 0.15 * rate)
        happiness = max(0, happiness - 0.1 * rate)
        energy = max(0, energy - 0.08 * rate)
        social = max(0, social - 0.12 * rate)
        hygiene = max(0, hygiene - 0.05 * rate)

        // Health decays when other stats are very low
        if hunger < 15 || hygiene < 15 {
            health = max(0, health - 0.1 * rate)
        } else if !isSick {
            health = min(100, health + 0.02 * rate)  // slow recovery
        }

        // Sickness chance when health is low
        if !isSick && health < 30 && Double.random(in: 0...1) < 0.002 * rate {
            isSick = true
            sickSince = Date()
            happiness = max(0, happiness - 20)
            energy = max(0, energy - 20)
        }

        // Sick makes everything worse
        if isSick {
            happiness = max(0, happiness - 0.2 * rate)
            energy = max(0, energy - 0.15 * rate)
            health = max(0, health - 0.05 * rate)
        }

        // Poop chance when hunger is low
        if hunger < 30 && Int.random(in: 0..<Int(max(1, 100 / rate))) == 0 {
            poopCount += 1
            hygiene = max(0, hygiene - 10)
        }

        // Death when health reaches 0
        if health <= 0 && !isDead {
            isDead = true
        }
    }

    mutating func feed() {
        hunger = min(100, hunger + 25)
        happiness = min(100, happiness + 5)
        totalFeedings += 1
        addXP(2)
    }

    mutating func pet() {
        happiness = min(100, happiness + 15)
        social = min(100, social + 10)
        totalPets += 1
        addXP(1)
    }

    mutating func play() {
        happiness = min(100, happiness + 20)
        social = min(100, social + 15)
        energy = max(0, energy - 10)
        totalPlays += 1
        addXP(3)
    }

    mutating func rest() {
        energy = min(100, energy + 30)
    }

    mutating func cleanPoop() {
        poopCount = 0
        hygiene = min(100, hygiene + 20)
        lastPoopClean = Date()
        addXP(1)
    }

    mutating func bathe() {
        hygiene = min(100, hygiene + 40)
        happiness = max(0, happiness - 5) // cats don't love baths
        totalBaths += 1
        addXP(1)
    }

    mutating func heal() {
        if isDead {
            isDead = false
            isSick = false
            sickSince = nil
            health = 50
            hunger = 50
            happiness = 30
            energy = 50
            totalHeals += 1
            addXP(10)
            return
        }
        guard isSick else { return }
        isSick = false
        sickSince = nil
        health = min(100, health + 50)
        happiness = min(100, happiness + 10)
        energy = min(100, energy + 10)
        totalHeals += 1
        addXP(4)
    }

    mutating func feedMilk() {
        hunger = min(100, hunger + 15)
        happiness = min(100, happiness + 10)
        health = min(100, health + 5)
        totalFeedings += 1
        addXP(2)
    }

    mutating func feedTreat() {
        hunger = min(100, hunger + 8)
        happiness = min(100, happiness + 20)
        totalFeedings += 1
        addXP(2)
    }

    mutating func walk() {
        happiness = min(100, happiness + 15)
        energy = max(0, energy - 15)
        social = min(100, social + 10)
        health = min(100, health + 5)
        totalWalks += 1
        addXP(4)
    }

    mutating func addMilestone(_ text: String) {
        let dateStr = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()
        let entry = "[\(dateStr)] \(text)"
        if !milestones.contains(entry) {
            milestones.append(entry)
            if milestones.count > 200 { milestones.removeFirst() }
        }
    }

    var needsAttention: Bool {
        return isSick || hunger < 20 || happiness < 20 || energy < 15 || hygiene < 15 || health < 30 || poopCount >= 3
    }

    static let savePath: String = {
        let dir = NSHomeDirectory() + "/.murchi"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        return dir + "/stats.json"
    }()

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: URL(fileURLWithPath: PetStats.savePath))
        }
    }

    static func load() -> PetStats {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: savePath)),
              let stats = try? JSONDecoder().decode(PetStats.self, from: data) else {
            return PetStats()
        }
        return stats
    }
}

// MARK: - Behavior State Machine

enum PetBehavior: String {
    case idle, walking, sitting, sleeping, eating, beingPet, playing
    case lookingAtCursor, chasingCursor, jumping, stretching, tripping
    case greeting, grooming, running, pooping
    case chasingToy, scratching, edgeWalking, zoomies
    case sick, bathing, promenade
    case chasingButterfly, watchingBird, knockingGlass, openingGift
    case flying, clingingEdge
    case dead, celebrating, crying, lonelySitting
}

// MARK: - Speech Bubbles

struct SpeechBubbles {
    // ── Per-pet phrases ──
    static func idle(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return ["...", "*nose twitch*", "*ear wiggle*", "*looks around*", "*hops in place*"]
        case "bird":   return ["...", "*preens feathers*", "*head tilt*", "*looks around*", "*fluffs up*"]
        default:       return ["...", "*purrrr*", "*licks paw*", "*looks around*", "*tail swish*"]
        }
    }

    static func happy(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "*binky!*", "You're the best!", "I love you!", "*nose boops*",
            "Best human ever!", "Play with me!", "Life is good~",
            "*happy hops*", "*thump thump*", "Feeling great!",
        ]
        case "bird": return [
            "Tweet tweet~!", "You're the best!", "I love you!", "*sings happily*",
            "Best human ever!", "Play with me!", "Life is good~",
            "*happy chirp*", "Chirp chirp!", "Feeling great!",
        ]
        default: return [
            "Mrrrow~!", "You're the best!", "I love you!", "*purrs loudly*",
            "Best human ever!", "Play with me!", "Life is good~",
            "*happy chirp*", "Meow meow!", "Feeling great!",
        ]
        }
    }

    static func neutral(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "*thump*", "*yawn*", "Hey there.", "*ear twitch*", "Hm...",
            "What's up?", "*nose wiggle*", "Carrots?", "Bored...",
        ]
        case "bird": return [
            "Chirp.", "*yawn*", "Hey there.", "*ruffles feathers*", "Hm...",
            "What's up?", "*head bob*", "Seeds?", "Bored...",
        ]
        default: return [
            "Meow.", "*yawn*", "Hey there.", "*stretches*", "Hm...",
            "What's up?", "*stares*", "Feed me?", "Bored...",
        ]
        }
    }

    static func sad(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "I'm hungry...", "I'm lonely...", "Pay attention to me...",
            "*sad thump*", "Don't forget me...", "I'm not okay...",
            "*flattens ears*", "Why so long...", "Miss you...",
        ]
        case "bird": return [
            "I'm hungry...", "I'm lonely...", "Pay attention to me...",
            "*sad peep*", "Don't forget me...", "I'm not okay...",
            "*droopy wings*", "Why so long...", "Miss you...",
        ]
        default: return [
            "I'm hungry...", "I'm lonely...", "Pay attention to me...",
            "*sad meow*", "Don't forget me...", "I'm not okay...",
            "*whimpers*", "Why so long...", "Miss you...",
        ]
        }
    }

    static let sleepy = [
        "So tired...", "*yawn*", "zzz...", "Sleepy...",
        "Five more minutes...", "*nods off*", "Need nap...",
    ]

    static func eating(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "Nom nom nom!", "Yummy!", "Mmmm carrots!", "*happy munching*",
            "SO GOOD!", "*crunch crunch*", "More hay please!",
        ]
        case "bird": return [
            "Nom nom nom!", "Yummy!", "Mmmm seeds!", "*happy pecking*",
            "SO GOOD!", "*peck peck*", "More seeds please!",
        ]
        default: return [
            "Nom nom nom!", "Yummy!", "Mmmm fish!", "*happy munching*",
            "SO GOOD!", "*crunch crunch*", "More please!",
        ]
        }
    }

    static func petted(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "*tooth purr*", "More pets please!", "Right there!",
            "I love ear rubs!", "*flops over*", "Don't stop!",
            "*melts*", "So soft~", "Yes yes yes!",
        ]
        case "bird": return [
            "*happy trill*", "More scratches!", "Right there!",
            "I love head scratches!", "*fluffs up*", "Don't stop!",
            "*melts*", "Tweet~!", "Yes yes yes!",
        ]
        default: return [
            "*PURRRR*", "More pets please!", "Right there!",
            "I love scratches!", "Mrrrow~", "Don't stop!",
            "*melts*", "Purrfect~", "Yes yes yes!",
        ]
        }
    }

    static func greeting(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "You're back!!!", "I missed you!", "FINALLY!",
            "Where were you?!", "*binky binky binky!*", "DON'T LEAVE AGAIN!",
            "*runs in circles*", "SO HAPPY!",
        ]
        case "bird": return [
            "You're back!!!", "I missed you!", "FINALLY!",
            "Where were you?!", "TWEET TWEET TWEET!", "DON'T LEAVE AGAIN!",
            "*flies in circles*", "SO HAPPY!",
        ]
        default: return [
            "You're back!!!", "I missed you!", "FINALLY!",
            "Where were you?!", "Meow meow meow!", "DON'T LEAVE AGAIN!",
            "*runs in circles*", "SO HAPPY!",
        ]
        }
    }

    static let morning = ["Good morning!", "Rise and shine!", "New day!", "Breakfast time!"]
    static let evening = ["Good evening~", "Cozy time!", "Getting sleepy...", "Dinner?"]
    static let lateNight = ["Go to sleep...", "It's so late...", "zzz... you too...", "Bed time?"]

    static func playing(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "Wheee!", "Catch me!", "So fun!", "*binky!*",
            "FASTER!", "Can't catch me!", "*hop hop hop*",
        ]
        case "bird": return [
            "Wheee!", "Catch me!", "So fun!", "*flap flap*",
            "FASTER!", "Can't catch me!", "*swooop!*",
        ]
        default: return [
            "Wheee!", "Catch me!", "So fun!", "*zoomies*",
            "FASTER!", "Can't catch me!", "*pounce*",
        ]
        }
    }

    static func grooming(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "*lick lick*", "Must stay clean!", "Looking good~",
            "*grooms ears*", "Fluffiest bunny!",
        ]
        case "bird": return [
            "*preen preen*", "Must stay clean!", "Looking good~",
            "*preens feathers*", "Shiniest feathers!",
        ]
        default: return [
            "*lick lick*", "Must stay clean!", "Looking good~",
            "*grooms fur*", "Purrfect fur!",
        ]
        }
    }

    static let levelUp = [
        "I LEVELED UP!", "I'm getting stronger!", "NEW POWERS!",
        "EVOLUTION!", "Watch me grow!",
    ]

    static let poop = [
        "Oops...", "I couldn't hold it!", "Sorry...",
        "*looks embarrassed*", "Clean it please...",
    ]

    static let dirty = [
        "I need a bath...", "I'm dirty...", "Gross...",
        "*sniffs self* ugh",
    ]

    static let sickBubbles = [
        "I don't feel good...", "*cough*", "Need medicine...",
        "My tummy hurts...", "*shivers*", "Help me...",
        "So dizzy...", "*groan*",
    ]

    static func bathBubbles(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "*splash splash*", "Water! Nooo!", "Bunnies hate baths!",
            "Okay... it's warm...", "*bubbles*", "Almost done?",
        ]
        case "bird": return [
            "*splash splash*", "Bath time!", "Birdie bath!",
            "*flaps in water*", "*bubbles*", "So refreshing!",
        ]
        default: return [
            "*splash splash*", "Water! Nooo!", "I hate baths!",
            "Okay... it's warm...", "*bubbles*", "Almost done?",
        ]
        }
    }

    static func promenadeBubbles(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "Nice hop!", "Fresh air!", "Adventure!",
            "Look, clover!", "Exploring!", "This is fun!",
            "New smells!", "What's over there?",
        ]
        case "bird": return [
            "Nice stroll!", "Fresh air!", "Adventure!",
            "Look, worms!", "Exploring!", "This is fun!",
            "New sights!", "What's over there?",
        ]
        default: return [
            "Nice walk!", "Fresh air!", "Adventure!",
            "Look, a bird!", "Exploring!", "This is fun!",
            "New smells!", "What's over there?",
        ]
        }
    }

    static let healBubbles = [
        "Medicine time... *gulp*", "I feel better!",
        "Thank you doctor!", "Bleh, but it helps!",
    ]

    static func milkBubbles(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "Water! Yummy!", "*sip sip sip*", "Refreshing!",
            "Mmmm nice and cool~",
        ]
        case "bird": return [
            "Water! Yummy!", "*sip sip sip*", "Refreshing!",
            "Mmmm nice and cool~",
        ]
        default: return [
            "Milk! Yummy!", "*lap lap lap*", "Creamy!",
            "Mmmm warm milk~",
        ]
        }
    }

    static let treatBubbles = [
        "A TREAT!", "Yay!", "SO TASTY!",
        "*happy crunch*", "Best snack ever!",
    ]

    static func butterflyBubbles(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "A butterfly!!", "So pretty!!", "*nose twitch*",
            "Come here little friend!", "SO PRETTY!",
        ]
        case "bird": return [
            "A butterfly!!", "A friend?!", "*head tilt*",
            "Come here little friend!", "SO PRETTY!",
        ]
        default: return [
            "A butterfly!!", "Must catch!!", "*wiggles butt*",
            "Come here little friend!", "SO PRETTY!",
        ]
        }
    }

    static func birdWatchBubbles(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "*stares at bird*", "What's that?", "*ear perk*",
            "*watching closely*", "*nose twitch*", "Birdie!",
        ]
        case "bird": return [
            "*stares at bird*", "A friend!", "*chirp chirp!*",
            "*excited singing*", "*flaps wings*", "Hello birdie!",
        ]
        default: return [
            "*stares at bird*", "Chirp?", "Must... not... pounce...",
            "*intense staring*", "*tail twitching*", "Birdie!",
        ]
        }
    }

    static let giftBubbles = [
        "A PRESENT!!", "What's inside?!", "For ME?!",
        "Best day ever!", "Yay yay yay!!",
    ]

    static func knockBubbles(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "*eyes glass*", "Should I...?", "*boop*",
            "Oops! *innocent face*", "It was like that!",
            "*nudges gently*", "What happens if...?",
        ]
        case "bird": return [
            "*eyes glass*", "Should I...?", "*tap tap*",
            "Oops! *innocent face*", "It was like that!",
            "*pecks at glass*", "Shiny!",
        ]
        default: return [
            "*eyes glass*", "Should I...?", "*boop*",
            "Oops! *innocent face*", "It was like that!",
            "*pushes slowly*", "Physics experiment!",
        ]
        }
    }

    static func forMood(_ mood: PetStats.Mood, pet: String) -> [String] {
        switch mood {
        case .happy: return happy(pet)
        case .neutral: return neutral(pet)
        case .sad: return sad(pet)
        case .sleepy: return sleepy
        case .sick: return sickBubbles
        }
    }

    static func zoomies(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "*BINKY!*", "CAN'T STOP!", "ZOOOOM!", "*hops everywhere*",
            "MAXIMUM SPEED!", "Turbo bunny!", "WHEEEEE!",
        ]
        case "bird": return [
            "*SWOOSH!*", "CAN'T STOP!", "ZOOOOM!", "*flies around*",
            "MAXIMUM SPEED!", "Turbo bird!", "WHEEEEE!",
        ]
        default: return [
            "*NYOOOM*", "CAN'T STOP!", "ZOOOOM!", "*crashes into wall*",
            "MAXIMUM SPEED!", "Turbo mode!", "WHEEEEE!",
        ]
        }
    }

    static func scratching(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "*scratch scratch*", "Gotta dig!", "Itchy ear!",
            "*digs furiously*", "Almost there!",
        ]
        case "bird": return [
            "*scratch scratch*", "Itchy feathers!", "Gotta preen!",
            "*ruffles feathers*", "Ahh better!",
        ]
        default: return [
            "*scratch scratch*", "Gotta sharpen!", "My claws~",
            "*shreds everything*", "DESTROY!",
        ]
        }
    }

    static func chasingToy(_ pet: String) -> [String] {
        switch pet {
        case "rabbit": return [
            "A toy!", "I'll get it!", "Come here!", "*hop hop!*",
            "Almost got it!", "MINE!", "So fast!",
        ]
        case "bird": return [
            "A toy!", "I'll get it!", "Come here!", "*swoop!*",
            "Almost got it!", "MINE!", "So fast!",
        ]
        default: return [
            "MOUSE!", "I'll get it!", "Come here!", "*pounce!*",
            "Almost got it!", "MINE!", "So fast!",
        ]
        }
    }

    static let accessoryReaction = [
        "Looking fancy!", "New look!", "Do I look good?",
        "I'm fabulous~", "Style upgrade!",
    ]

    static func timeGreeting() -> String? {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 6 && hour < 10 { return morning.randomElement() }
        if hour >= 18 && hour < 22 { return evening.randomElement() }
        if hour >= 23 || hour < 5 { return lateNight.randomElement() }
        return nil
    }
}

// MARK: - Accessory System

struct Accessory {
    let name: String
    let minLevel: Int
    let sprite: [[UInt32]]  // overlay sprite (legacy, kept for compatibility)
    let vectorDraw: ((CGContext, CGFloat, CGFloat) -> Void)?

    init(name: String, minLevel: Int, sprite: [[UInt32]], vectorDraw: ((CGContext, CGFloat, CGFloat) -> Void)? = nil) {
        self.name = name
        self.minLevel = minLevel
        self.sprite = sprite
        self.vectorDraw = vectorDraw
    }

    // Hat — yellow party hat (vector kawaii)
    static let partyHat: Accessory = {
        let T: UInt32 = 0
        let sprite: [[UInt32]] = Array(repeating: Array(repeating: T, count: 16), count: 16)
        return Accessory(name: "\u{1F389} Party Hat", minLevel: 1, sprite: sprite) { ctx, cx, cy in
            // Yellow triangle hat
            let hatTop = cy + 38
            let hatBase = cy + 14
            ctx.setFillColor(NSColor(red: 1, green: 0.84, blue: 0, alpha: 1).cgColor)
            ctx.move(to: CGPoint(x: cx, y: hatTop))
            ctx.addLine(to: CGPoint(x: cx - 14, y: hatBase))
            ctx.addLine(to: CGPoint(x: cx + 14, y: hatBase))
            ctx.closePath()
            ctx.fillPath()
            // Outline
            ctx.setStrokeColor(NSColor(white: 0.15, alpha: 1).cgColor)
            ctx.setLineWidth(1.5)
            ctx.move(to: CGPoint(x: cx, y: hatTop))
            ctx.addLine(to: CGPoint(x: cx - 14, y: hatBase))
            ctx.addLine(to: CGPoint(x: cx + 14, y: hatBase))
            ctx.closePath()
            ctx.strokePath()
            // Red ball on top
            ctx.setFillColor(NSColor(red: 1, green: 0.27, blue: 0.27, alpha: 1).cgColor)
            ctx.addEllipse(in: CGRect(x: cx - 4, y: hatTop - 2, width: 8, height: 8))
            ctx.fillPath()
            // Brim
            ctx.setFillColor(NSColor(white: 0.18, alpha: 1).cgColor)
            ctx.addEllipse(in: CGRect(x: cx - 16, y: hatBase - 3, width: 32, height: 6))
            ctx.fillPath()
        }
    }()

    // Bow tie — red (vector kawaii)
    static let bowTie: Accessory = {
        let T: UInt32 = 0
        let sprite: [[UInt32]] = Array(repeating: Array(repeating: T, count: 16), count: 16)
        return Accessory(name: "\u{1F380} Bow Tie", minLevel: 2, sprite: sprite) { ctx, cx, cy in
            let bowY = cy - 14
            // Left wing
            ctx.setFillColor(NSColor(red: 1, green: 0.2, blue: 0.33, alpha: 1).cgColor)
            ctx.move(to: CGPoint(x: cx, y: bowY))
            ctx.addCurve(to: CGPoint(x: cx - 14, y: bowY + 6),
                         control1: CGPoint(x: cx - 4, y: bowY + 8),
                         control2: CGPoint(x: cx - 10, y: bowY + 8))
            ctx.addCurve(to: CGPoint(x: cx, y: bowY),
                         control1: CGPoint(x: cx - 10, y: bowY - 8),
                         control2: CGPoint(x: cx - 4, y: bowY - 8))
            ctx.fillPath()
            // Right wing
            ctx.move(to: CGPoint(x: cx, y: bowY))
            ctx.addCurve(to: CGPoint(x: cx + 14, y: bowY + 6),
                         control1: CGPoint(x: cx + 4, y: bowY + 8),
                         control2: CGPoint(x: cx + 10, y: bowY + 8))
            ctx.addCurve(to: CGPoint(x: cx, y: bowY),
                         control1: CGPoint(x: cx + 10, y: bowY - 8),
                         control2: CGPoint(x: cx + 4, y: bowY - 8))
            ctx.fillPath()
            // Center knot
            ctx.setFillColor(NSColor(red: 0.8, green: 0.13, blue: 0.27, alpha: 1).cgColor)
            ctx.addEllipse(in: CGRect(x: cx - 3, y: bowY - 3, width: 6, height: 6))
            ctx.fillPath()
        }
    }()

    // Crown — gold (vector kawaii)
    static let crown: Accessory = {
        let T: UInt32 = 0
        let sprite: [[UInt32]] = Array(repeating: Array(repeating: T, count: 16), count: 16)
        return Accessory(name: "\u{1F451} Crown", minLevel: 5, sprite: sprite) { ctx, cx, cy in
            let crownBase = cy + 14
            let crownTop = cy + 34
            // Gold base band
            ctx.setFillColor(NSColor(red: 1, green: 0.84, blue: 0, alpha: 1).cgColor)
            ctx.fill(CGRect(x: cx - 16, y: crownBase, width: 32, height: 8))
            // Three points
            for px in [cx - 12, cx, cx + 12] as [CGFloat] {
                ctx.move(to: CGPoint(x: px - 5, y: crownBase + 8))
                ctx.addLine(to: CGPoint(x: px, y: crownTop))
                ctx.addLine(to: CGPoint(x: px + 5, y: crownBase + 8))
                ctx.closePath()
                ctx.fillPath()
            }
            // Gems (red, blue, red)
            let gemColors: [NSColor] = [
                NSColor(red: 1, green: 0.2, blue: 0.2, alpha: 1),
                NSColor(red: 0.2, green: 0.4, blue: 1, alpha: 1),
                NSColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
            ]
            for (i, gx) in [cx - 10, cx, cx + 10].enumerated() {
                ctx.setFillColor(gemColors[i].cgColor)
                ctx.addEllipse(in: CGRect(x: gx - 2.5, y: crownBase + 1, width: 5, height: 5))
                ctx.fillPath()
            }
            // Outline
            ctx.setStrokeColor(NSColor(white: 0.15, alpha: 1).cgColor)
            ctx.setLineWidth(1.2)
            ctx.addRect(CGRect(x: cx - 16, y: crownBase, width: 32, height: 8))
            ctx.strokePath()
        }
    }()

    // Sunglasses (vector kawaii)
    static let sunglasses: Accessory = {
        let T: UInt32 = 0
        let sprite: [[UInt32]] = Array(repeating: Array(repeating: T, count: 16), count: 16)
        return Accessory(name: "\u{1F576} Sunglasses", minLevel: 3, sprite: sprite) { ctx, cx, cy in
            let glassY = cy + 4
            // Bridge
            ctx.setStrokeColor(NSColor(white: 0.1, alpha: 1).cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: cx - 4, y: glassY + 5))
            ctx.addLine(to: CGPoint(x: cx + 4, y: glassY + 5))
            ctx.strokePath()
            // Arms
            ctx.move(to: CGPoint(x: cx - 18, y: glassY + 5))
            ctx.addLine(to: CGPoint(x: cx - 24, y: glassY + 8))
            ctx.strokePath()
            ctx.move(to: CGPoint(x: cx + 18, y: glassY + 5))
            ctx.addLine(to: CGPoint(x: cx + 24, y: glassY + 8))
            ctx.strokePath()
            // Left lens
            ctx.setFillColor(NSColor(white: 0.1, alpha: 0.85).cgColor)
            let leftLens = CGRect(x: cx - 18, y: glassY, width: 14, height: 10)
            let leftPath = CGPath(roundedRect: leftLens, cornerWidth: 3, cornerHeight: 3, transform: nil)
            ctx.addPath(leftPath)
            ctx.fillPath()
            // Right lens
            let rightLens = CGRect(x: cx + 4, y: glassY, width: 14, height: 10)
            let rightPath = CGPath(roundedRect: rightLens, cornerWidth: 3, cornerHeight: 3, transform: nil)
            ctx.addPath(rightPath)
            ctx.fillPath()
            // Lens shine
            ctx.setFillColor(NSColor(white: 1, alpha: 0.3).cgColor)
            ctx.addEllipse(in: CGRect(x: cx - 15, y: glassY + 4, width: 4, height: 3))
            ctx.fillPath()
            ctx.addEllipse(in: CGRect(x: cx + 7, y: glassY + 4, width: 4, height: 3))
            ctx.fillPath()
        }
    }()

    // Halo — for cosmic level (vector kawaii)
    static let halo: Accessory = {
        let T: UInt32 = 0
        let sprite: [[UInt32]] = Array(repeating: Array(repeating: T, count: 16), count: 16)
        return Accessory(name: "\u{1F607} Halo", minLevel: 10, sprite: sprite) { ctx, cx, cy in
            let haloY = cy + 36
            // Glow
            ctx.setFillColor(NSColor(red: 1, green: 0.93, blue: 0.53, alpha: 0.3).cgColor)
            ctx.addEllipse(in: CGRect(x: cx - 18, y: haloY - 3, width: 36, height: 12))
            ctx.fillPath()
            // Halo ring
            ctx.setStrokeColor(NSColor(red: 1, green: 0.87, blue: 0.27, alpha: 1).cgColor)
            ctx.setLineWidth(3)
            ctx.addEllipse(in: CGRect(x: cx - 14, y: haloY, width: 28, height: 8))
            ctx.strokePath()
            // Highlight
            ctx.setStrokeColor(NSColor(red: 1, green: 0.95, blue: 0.7, alpha: 0.7).cgColor)
            ctx.setLineWidth(1.5)
            ctx.addArc(center: CGPoint(x: cx, y: haloY + 4), radius: 12, startAngle: .pi * 0.2, endAngle: .pi * 0.8, clockwise: false)
            ctx.strokePath()
        }
    }()

    // Flower — pink flower behind ear (vector kawaii)
    static let flower: Accessory = {
        let T: UInt32 = 0
        let sprite: [[UInt32]] = Array(repeating: Array(repeating: T, count: 16), count: 16)
        return Accessory(name: "\u{1F338} Flower", minLevel: 1, sprite: sprite) { ctx, cx, cy in
            let fx = cx + 18
            let fy = cy + 22
            let petalSize: CGFloat = 6
            // Petals (5 around center)
            ctx.setFillColor(NSColor(red: 1, green: 0.6, blue: 0.7, alpha: 1).cgColor)
            for i in 0..<5 {
                let angle = CGFloat(i) * (.pi * 2 / 5) - .pi / 2
                let px = fx + cos(angle) * 5
                let py = fy + sin(angle) * 5
                ctx.addEllipse(in: CGRect(x: px - petalSize/2, y: py - petalSize/2, width: petalSize, height: petalSize))
                ctx.fillPath()
            }
            // Center
            ctx.setFillColor(NSColor(red: 1, green: 0.9, blue: 0.3, alpha: 1).cgColor)
            ctx.addEllipse(in: CGRect(x: fx - 3, y: fy - 3, width: 6, height: 6))
            ctx.fillPath()
        }
    }()

    static let all: [Accessory] = [partyHat, bowTie, sunglasses, crown, flower, halo]

    static func available(for level: Int) -> [Accessory] {
        return all.filter { $0.minLevel <= level }
    }
}

// MARK: - Toy System

struct Toy {
    var x: CGFloat
    var y: CGFloat
    var type: ToyType
    var isActive: Bool = true

    enum ToyType {
        case mouseToy, yarnBall, laserDot
    }
}

// MARK: - Rabbit Renderer (commented out)
/*
class RabbitRenderer {
    static let shared = RabbitRenderer()
    private var cache: [String: NSImage] = [:]
    private var cacheKeys: [String] = []
    private let maxCacheSize = 200
    let size: CGFloat = 160

    func clearCache() { cache.removeAll(); cacheKeys.removeAll() }

    private func cacheInsert(_ key: String, _ img: NSImage) {
        if cache[key] != nil { return }
        if cacheKeys.count >= maxCacheSize {
            let old = cacheKeys.removeFirst()
            cache.removeValue(forKey: old)
        }
        cache[key] = img
        cacheKeys.append(key)
    }

    enum RabbitExpression {
        case neutral, happy, love, excited, sleeping, blink, eating
        case annoyed, shocked, sick, straining, curious
    }

    enum RabbitPose {
        case standing, sitting, walkL, walkR, jump, lyingDown, lyingDown2, stretch
    }

    // Walk cycle phase: 0..3 → smooth 4-frame hop cycle
    // Phase 0: crouch (prepare), 1: push off (walkL), 2: airborne (up), 3: land (walkR)
    private func walkPhase(_ frame: Int) -> Int { return frame % 4 }

    func getSprite(for behavior: PetBehavior, frame: Int, right: Bool) -> NSImage {
        let key = "rabbit_\(behavior.rawValue)_\(frame % 16)_\(right)"
        if behavior != .lookingAtCursor, let cached = cache[key] { return cached }

        let expression: RabbitExpression
        let pose: RabbitPose

        switch behavior {
        case .idle:
            expression = frame % 12 == 0 ? .blink : .neutral
            pose = .standing
        case .walking, .edgeWalking, .knockingGlass:
            expression = .neutral
            // 4-frame bunny hop cycle
            let phase = walkPhase(frame)
            pose = phase < 2 ? .walkL : .walkR
        case .running, .chasingCursor, .chasingToy, .zoomies, .chasingButterfly:
            expression = .excited
            let phase = walkPhase(frame)
            pose = phase < 2 ? .walkL : .walkR
        case .sitting, .watchingBird:
            expression = .neutral
            pose = .sitting
        case .sleeping:
            expression = .sleeping
            pose = frame % 4 < 2 ? .lyingDown : .lyingDown2
        case .eating:
            expression = .eating
            pose = frame % 4 < 2 ? .sitting : .standing
        case .beingPet, .greeting:
            expression = .love
            pose = .standing
        case .playing:
            expression = frame % 3 == 0 ? .happy : .excited
            pose = frame % 4 < 2 ? .standing : .jump
        case .jumping:
            expression = .excited
            pose = .jump
        case .stretching:
            expression = .neutral
            pose = .stretch
        case .tripping:
            expression = .shocked
            pose = .lyingDown
        case .grooming:
            expression = frame % 4 < 2 ? .neutral : .blink
            pose = .sitting
        case .bathing:
            // Rabbit shakes off water, not happy about it
            expression = frame % 3 == 0 ? .shocked : .annoyed
            pose = frame % 4 < 2 ? .standing : .sitting
        case .scratching:
            expression = .annoyed
            pose = frame % 4 < 2 ? .standing : .stretch
        case .pooping:
            expression = .straining
            pose = .sitting
        case .sick:
            expression = .sick
            pose = .lyingDown
        case .promenade:
            expression = .happy
            let phase = walkPhase(frame)
            pose = phase < 2 ? .walkL : .walkR
        case .openingGift:
            expression = frame % 3 == 0 ? .excited : .happy
            pose = .jump
        case .flying:
            expression = .excited
            pose = .jump
        case .clingingEdge:
            expression = .excited
            pose = .standing
        case .lookingAtCursor:
            let mousePos = NSEvent.mouseLocation
            let lookR = mousePos.x > 400
            let quantized = Int(mousePos.x / 200)
            let cursorKey = "rabbit_cursor_\(quantized)_\(lookR)"
            if let cached = cache[cursorKey] { return cached }
            let img = render(expression: .curious, pose: .standing, lookRight: lookR, walkFrame: 0)
            cacheInsert(cursorKey, img)
            return img
        }

        let img = render(expression: expression, pose: pose, lookRight: right, walkFrame: frame % 16)
        cacheInsert(key, img)
        return img
    }

    func render(expression: RabbitExpression, pose: RabbitPose, lookRight: Bool, walkFrame: Int = 0) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }
        ctx.setShouldAntialias(true)
        ctx.setAllowsAntialiasing(true)
        ctx.saveGState()

        if !lookRight {
            ctx.translateBy(x: size, y: 0)
            ctx.scaleBy(x: -1, y: 1)
        }

        // Scale rabbit to 88% and center — gives headroom for ears during bounce/jump
        let rabbitScale: CGFloat = 0.88
        let offsetX: CGFloat = (size - size * rabbitScale) / 2  // center horizontally
        let offsetY: CGFloat = -4  // shift down for extra ear room
        ctx.translateBy(x: offsetX, y: offsetY)
        ctx.scaleBy(x: rabbitScale, y: rabbitScale)

        // ── PALETTE — soft pink/lavender rabbit ──
        let bodyMain = NSColor(red: 0.82, green: 0.68, blue: 0.85, alpha: 1)
        let earInner = NSColor(red: 0.92, green: 0.72, blue: 0.80, alpha: 1)
        let bellyC = NSColor(red: 0.92, green: 0.82, blue: 0.90, alpha: 1)
        let cheekC = NSColor(red: 0.95, green: 0.70, blue: 0.75, alpha: 0.6)
        let noseC = NSColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
        let mouthC = NSColor(red: 0.34, green: 0.20, blue: 0.17, alpha: 1)
        let eyeC = NSColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
        let bodyDark = NSColor(red: 0.70, green: 0.56, blue: 0.73, alpha: 1)

        let isLying = pose == .lyingDown || pose == .lyingDown2
        let isWalking = pose == .walkL || pose == .walkR
        let isSitting = pose == .sitting

        // ── BUNNY HOP ANIMATION (4-phase cycle) ──
        // phase 0: crouch (squash down), 1: push off (stretch up+forward),
        // 2: airborne (highest point, slight stretch), 3: land (squash on ground)
        let hopPhase = walkFrame % 4
        var hopBounce: CGFloat = 0      // vertical offset
        var hopSquashX: CGFloat = 1.0   // horizontal scale
        var hopSquashY: CGFloat = 1.0   // vertical scale
        var hopTilt: CGFloat = 0        // body rotation
        var hopShiftX: CGFloat = 0      // horizontal shift

        if isWalking {
            switch hopPhase {
            case 0: // crouch — preparing to push off
                hopBounce = -2
                hopSquashX = 1.08; hopSquashY = 0.92
                hopTilt = -0.03
            case 1: // push off — stretching upward
                hopBounce = 6
                hopSquashX = 0.93; hopSquashY = 1.08
                hopTilt = 0.04
                hopShiftX = 2
            case 2: // airborne — at the top
                hopBounce = 10
                hopSquashX = 0.96; hopSquashY = 1.05
                hopTilt = 0.02
                hopShiftX = 3
            case 3: // landing — squash on impact
                hopBounce = 1
                hopSquashX = 1.10; hopSquashY = 0.90
                hopTilt = -0.02
                hopShiftX = 1
            default: break
            }
        }

        // Jump pose: bigger stretch
        let jumpBounce: CGFloat = pose == .jump ? 12 : 0
        let jumpSquashX: CGFloat = pose == .jump ? 0.90 : 1.0
        let jumpSquashY: CGFloat = pose == .jump ? 1.12 : 1.0
        let sitDrop: CGFloat = isSitting ? -4 : 0
        let lyingDrop: CGFloat = isLying ? -8 : 0

        // Idle breathing: subtle scale pulse
        var breatheX: CGFloat = 1.0, breatheY: CGFloat = 1.0
        if !isWalking && pose != .jump && !isLying {
            let breathPhase = sin(Double(walkFrame) * 0.8)
            breatheX = 1.0 + CGFloat(breathPhase) * 0.015
            breatheY = 1.0 - CGFloat(breathPhase) * 0.01
        }

        // Stretch pose: elongate vertically
        let stretchScaleX: CGFloat = pose == .stretch ? 0.92 : 1.0
        let stretchScaleY: CGFloat = pose == .stretch ? 1.15 : 1.0
        let stretchBounce: CGFloat = pose == .stretch ? 4 : 0

        // Apply transforms: translate to center, scale (squash/stretch), translate back
        let centerX: CGFloat = 80, centerY: CGFloat = 70
        ctx.translateBy(x: hopShiftX, y: hopBounce + jumpBounce + sitDrop + lyingDrop + stretchBounce)

        // Squash & stretch around body center (combine all scale effects)
        let totalSquashX = hopSquashX * jumpSquashX * breatheX * stretchScaleX
        let totalSquashY = hopSquashY * jumpSquashY * breatheY * stretchScaleY
        if totalSquashX != 1.0 || totalSquashY != 1.0 {
            ctx.translateBy(x: centerX, y: centerY)
            ctx.scaleBy(x: totalSquashX, y: totalSquashY)
            ctx.translateBy(x: -centerX, y: -centerY)
        }

        // Body tilt during hop
        if hopTilt != 0 {
            ctx.translateBy(x: centerX, y: 40)
            ctx.rotate(by: hopTilt)
            ctx.translateBy(x: -centerX, y: -40)
        }

        if isLying {
            ctx.translateBy(x: 80, y: 40)
            ctx.rotate(by: pose == .lyingDown ? -0.25 : -0.2)
            ctx.translateBy(x: -80, y: -40)
        }

        // ═══ EARS (drawn behind body, animated with hop physics) ═══
        drawEarsAnimated(ctx, pose: pose, expression: expression, bodyMain: bodyMain, earInner: earInner, hopPhase: isWalking ? hopPhase : -1)

        // ═══ BODY (exact SVG path) ═══
        let bodyOutline = CGMutablePath()
        bodyOutline.move(to: CGPoint(x: 124.6, y: 141.8))
        bodyOutline.addCurve(to: CGPoint(x: 113.8, y: 155.7), control1: CGPoint(x: 124.6, y: 152.0), control2: CGPoint(x: 118.6, y: 155.7))
        bodyOutline.addCurve(to: CGPoint(x: 90.6, y: 110.6), control1: CGPoint(x: 103.4, y: 155.7), control2: CGPoint(x: 92.4, y: 140.2))
        bodyOutline.addCurve(to: CGPoint(x: 80.1, y: 111.9), control1: CGPoint(x: 87.1, y: 111.6), control2: CGPoint(x: 84.0, y: 111.9))
        bodyOutline.addCurve(to: CGPoint(x: 69.4, y: 110.8), control1: CGPoint(x: 76.4, y: 111.9), control2: CGPoint(x: 73.1, y: 111.7))
        bodyOutline.addCurve(to: CGPoint(x: 45.4, y: 155.6), control1: CGPoint(x: 69.1, y: 128.6), control2: CGPoint(x: 61.8, y: 155.6))
        bodyOutline.addCurve(to: CGPoint(x: 34.4, y: 141.3), control1: CGPoint(x: 38.3, y: 155.6), control2: CGPoint(x: 34.4, y: 149.0))
        bodyOutline.addCurve(to: CGPoint(x: 52.6, y: 101.6), control1: CGPoint(x: 34.4, y: 128.2), control2: CGPoint(x: 41.6, y: 114.5))
        bodyOutline.addCurve(to: CGPoint(x: 37.1, y: 68.8), control1: CGPoint(x: 43.2, y: 93.4), control2: CGPoint(x: 37.1, y: 82.2))
        bodyOutline.addCurve(to: CGPoint(x: 57.8, y: 44.9), control1: CGPoint(x: 37.1, y: 57.8), control2: CGPoint(x: 44.9, y: 49.0))
        bodyOutline.addCurve(to: CGPoint(x: 52.4, y: 19.2), control1: CGPoint(x: 53.6, y: 36.8), control2: CGPoint(x: 51.4, y: 27.2))
        bodyOutline.addCurve(to: CGPoint(x: 54.3, y: 13.8), control1: CGPoint(x: 52.7, y: 16.8), control2: CGPoint(x: 53.4, y: 15.1))
        bodyOutline.addCurve(to: CGPoint(x: 48.0, y: 7.7), control1: CGPoint(x: 50.3, y: 13.2), control2: CGPoint(x: 48.0, y: 10.4))
        bodyOutline.addCurve(to: CGPoint(x: 54.2, y: 4.3), control1: CGPoint(x: 48.0, y: 5.5), control2: CGPoint(x: 50.4, y: 4.3))
        bodyOutline.addLine(to: CGPoint(x: 65.8, y: 4.3))
        bodyOutline.addCurve(to: CGPoint(x: 71.9, y: 6.0), control1: CGPoint(x: 68.8, y: 4.3), control2: CGPoint(x: 71.2, y: 5.0))
        bodyOutline.addCurve(to: CGPoint(x: 80.0, y: 5.3), control1: CGPoint(x: 74.8, y: 5.3), control2: CGPoint(x: 77.7, y: 5.3))
        bodyOutline.addCurve(to: CGPoint(x: 87.9, y: 6.0), control1: CGPoint(x: 82.8, y: 5.3), control2: CGPoint(x: 85.4, y: 5.5))
        bodyOutline.addCurve(to: CGPoint(x: 94.1, y: 4.3), control1: CGPoint(x: 89.0, y: 4.9), control2: CGPoint(x: 90.6, y: 4.3))
        bodyOutline.addLine(to: CGPoint(x: 105.2, y: 4.3))
        bodyOutline.addCurve(to: CGPoint(x: 111.4, y: 8.1), control1: CGPoint(x: 109.3, y: 4.3), control2: CGPoint(x: 111.4, y: 5.6))
        bodyOutline.addCurve(to: CGPoint(x: 105.7, y: 13.8), control1: CGPoint(x: 111.4, y: 10.6), control2: CGPoint(x: 109.1, y: 12.8))
        bodyOutline.addCurve(to: CGPoint(x: 107.0, y: 16.4), control1: CGPoint(x: 106.2, y: 14.6), control2: CGPoint(x: 106.6, y: 15.4))
        bodyOutline.addCurve(to: CGPoint(x: 109.5, y: 15.8), control1: CGPoint(x: 107.7, y: 16.1), control2: CGPoint(x: 108.5, y: 15.8))
        bodyOutline.addCurve(to: CGPoint(x: 115.2, y: 21.3), control1: CGPoint(x: 113.0, y: 15.8), control2: CGPoint(x: 115.2, y: 18.3))
        bodyOutline.addCurve(to: CGPoint(x: 118.2, y: 25.3), control1: CGPoint(x: 117.8, y: 21.7), control2: CGPoint(x: 118.2, y: 23.8))
        bodyOutline.addCurve(to: CGPoint(x: 114.5, y: 30.0), control1: CGPoint(x: 118.2, y: 27.4), control2: CGPoint(x: 116.9, y: 29.4))
        bodyOutline.addCurve(to: CGPoint(x: 110.4, y: 34.7), control1: CGPoint(x: 114.9, y: 31.9), control2: CGPoint(x: 114.2, y: 34.7))
        bodyOutline.addCurve(to: CGPoint(x: 106.2, y: 32.8), control1: CGPoint(x: 108.5, y: 34.7), control2: CGPoint(x: 107.0, y: 33.9))
        bodyOutline.addCurve(to: CGPoint(x: 102.2, y: 44.4), control1: CGPoint(x: 104.9, y: 37.0), control2: CGPoint(x: 103.3, y: 40.9))
        bodyOutline.addCurve(to: CGPoint(x: 122.4, y: 69.1), control1: CGPoint(x: 113.8, y: 48.5), control2: CGPoint(x: 122.4, y: 56.3))
        bodyOutline.addCurve(to: CGPoint(x: 107.1, y: 101.1), control1: CGPoint(x: 122.4, y: 79.9), control2: CGPoint(x: 116.7, y: 91.9))
        bodyOutline.addCurve(to: CGPoint(x: 124.6, y: 141.8), control1: CGPoint(x: 116.7, y: 112.7), control2: CGPoint(x: 124.6, y: 125.3))
        bodyOutline.closeSubpath()
        ctx.setFillColor(bodyMain.cgColor)
        ctx.addPath(bodyOutline); ctx.fillPath()

        // ═══ BELLY ═══
        let bellyArea = CGMutablePath()
        bellyArea.move(to: CGPoint(x: 80.1, y: 39.4))
        bellyArea.addCurve(to: CGPoint(x: 64.6, y: 23.1), control1: CGPoint(x: 72.6, y: 39.4), control2: CGPoint(x: 64.6, y: 35.4))
        bellyArea.addCurve(to: CGPoint(x: 79.4, y: 9.0), control1: CGPoint(x: 64.6, y: 13.9), control2: CGPoint(x: 70.9, y: 9.0))
        bellyArea.addCurve(to: CGPoint(x: 95.0, y: 23.1), control1: CGPoint(x: 88.2, y: 9.0), control2: CGPoint(x: 95.0, y: 14.1))
        bellyArea.addCurve(to: CGPoint(x: 80.1, y: 39.4), control1: CGPoint(x: 95.0, y: 32.8), control2: CGPoint(x: 87.2, y: 39.4))
        bellyArea.closeSubpath()
        ctx.setFillColor(bellyC.cgColor)
        ctx.addPath(bellyArea); ctx.fillPath()

        // ═══ CHEEKS ═══
        let cheekL = CGMutablePath()
        cheekL.move(to: CGPoint(x: 49.0, y: 63.9))
        cheekL.addCurve(to: CGPoint(x: 44.1, y: 60.6), control1: CGPoint(x: 45.6, y: 63.9), control2: CGPoint(x: 44.1, y: 62.3))
        cheekL.addCurve(to: CGPoint(x: 49.6, y: 57.3), control1: CGPoint(x: 44.1, y: 58.4), control2: CGPoint(x: 46.9, y: 57.3))
        cheekL.addCurve(to: CGPoint(x: 54.3, y: 60.1), control1: CGPoint(x: 52.4, y: 57.3), control2: CGPoint(x: 54.3, y: 58.6))
        cheekL.addCurve(to: CGPoint(x: 49.0, y: 63.9), control1: CGPoint(x: 54.3, y: 61.8), control2: CGPoint(x: 52.2, y: 63.9))
        cheekL.closeSubpath()
        ctx.setFillColor(cheekC.cgColor)
        ctx.addPath(cheekL); ctx.fillPath()

        let cheekR = CGMutablePath()
        cheekR.move(to: CGPoint(x: 110.2, y: 63.9))
        cheekR.addCurve(to: CGPoint(x: 105.0, y: 60.3), control1: CGPoint(x: 106.4, y: 63.9), control2: CGPoint(x: 105.0, y: 61.8))
        cheekR.addCurve(to: CGPoint(x: 109.8, y: 57.3), control1: CGPoint(x: 105.0, y: 58.5), control2: CGPoint(x: 107.3, y: 57.3))
        cheekR.addCurve(to: CGPoint(x: 115.0, y: 61.0), control1: CGPoint(x: 113.1, y: 57.3), control2: CGPoint(x: 115.0, y: 59.5))
        cheekR.addCurve(to: CGPoint(x: 110.2, y: 63.9), control1: CGPoint(x: 115.0, y: 62.5), control2: CGPoint(x: 113.4, y: 63.9))
        cheekR.closeSubpath()
        ctx.setFillColor(cheekC.cgColor)
        ctx.addPath(cheekR); ctx.fillPath()

        // ═══ EYES ═══
        drawRabbitEyes(ctx, expression: expression, eyeC: eyeC, bodyDark: bodyDark)

        // ═══ NOSE (from SVG) ═══
        let nosePath = CGMutablePath()
        nosePath.move(to: CGPoint(x: 80.2, y: 69.4))
        nosePath.addLine(to: CGPoint(x: 78.0, y: 69.4))
        nosePath.addCurve(to: CGPoint(x: 75.3, y: 67.7), control1: CGPoint(x: 76.2, y: 69.4), control2: CGPoint(x: 75.3, y: 69.0))
        nosePath.addCurve(to: CGPoint(x: 79.9, y: 64.0), control1: CGPoint(x: 75.3, y: 65.9), control2: CGPoint(x: 77.6, y: 64.0))
        nosePath.addCurve(to: CGPoint(x: 84.1, y: 67.9), control1: CGPoint(x: 82.4, y: 64.0), control2: CGPoint(x: 84.1, y: 66.5))
        nosePath.addCurve(to: CGPoint(x: 80.2, y: 69.4), control1: CGPoint(x: 84.1, y: 69.1), control2: CGPoint(x: 83.0, y: 69.4))
        nosePath.closeSubpath()
        ctx.setFillColor(noseC.cgColor)
        ctx.addPath(nosePath); ctx.fillPath()
        // Nose highlight
        ctx.setFillColor(NSColor(white: 1, alpha: 0.3).cgColor)
        ctx.fillEllipse(in: CGRect(x: 78.5, y: 67.5, width: 3, height: 1.5))

        // ═══ MOUTH (from SVG paths + expression-dependent) ═══
        drawRabbitMouth(ctx, expression: expression, mouthC: mouthC)

        ctx.restoreGState()
        img.unlockFocus()
        return img
    }

    // MARK: - Ear Drawing with Animation

    private func drawEarsAnimated(_ ctx: CGContext, pose: RabbitPose, expression: RabbitExpression, bodyMain: NSColor, earInner: NSColor, hopPhase: Int = -1) {
        // Much more dramatic ear angles — ears should FLOP and BOUNCE
        var earAngleL: CGFloat = 0
        var earAngleR: CGFloat = 0

        if hopPhase >= 0 {
            // Walking hop cycle — ears trail behind body motion (secondary animation)
            switch hopPhase {
            case 0: // crouching — ears up, perky
                earAngleL = 0.05; earAngleR = -0.05
            case 1: // pushing off — ears swing back (trailing the upward push)
                earAngleL = -0.25; earAngleR = -0.20
            case 2: // airborne — ears flop way back (inertia from jump)
                earAngleL = -0.35; earAngleR = -0.30
            case 3: // landing — ears swing forward (overshoot from landing)
                earAngleL = 0.20; earAngleR = 0.15
            default: break
            }
        } else {
            switch pose {
            case .jump:
                earAngleL = -0.35; earAngleR = -0.30  // ears swept far back during jump
            case .sitting:
                earAngleL = 0.12; earAngleR = -0.12   // ears relaxed outward
            case .stretch:
                earAngleL = 0.30; earAngleR = -0.30   // ears spread very wide
            case .lyingDown, .lyingDown2:
                earAngleL = 0.25; earAngleR = 0.20    // ears droopy
            default:
                // Idle — gentle sway (using walkFrame for subtle life)
                earAngleL = 0.03; earAngleR = -0.03
            }
        }

        // Expressions override: ears perk up for love/excited, droop for sick/sleeping
        if expression == .love || expression == .excited {
            earAngleL += 0.15; earAngleR -= 0.15  // perk outward
        } else if expression == .sleeping {
            earAngleL = 0.30; earAngleR = 0.25  // fully droopy
        } else if expression == .sick {
            earAngleL = 0.22; earAngleR = 0.18  // sad droop
        } else if expression == .shocked {
            earAngleL = -0.20; earAngleR = 0.20  // ears shoot straight up/out
        }

        // ── LEFT EAR (pivot ~57, 105) ──
        ctx.saveGState()
        ctx.translateBy(x: 57.3, y: 105.0)
        ctx.rotate(by: earAngleL)
        ctx.translateBy(x: -57.3, y: -105.0)
        // Left ear inner fill from SVG
        let leftEarInner = CGMutablePath()
        leftEarInner.move(to: CGPoint(x: 57.3, y: 104.7))
        leftEarInner.addCurve(to: CGPoint(x: 43.0, y: 134.4), control1: CGPoint(x: 49.4, y: 113.3), control2: CGPoint(x: 43.0, y: 124.5))
        leftEarInner.addCurve(to: CGPoint(x: 48.2, y: 142.6), control1: CGPoint(x: 43.0, y: 139.4), control2: CGPoint(x: 45.4, y: 142.6))
        leftEarInner.addCurve(to: CGPoint(x: 63.7, y: 108.2), control1: CGPoint(x: 54.3, y: 142.6), control2: CGPoint(x: 63.0, y: 130.0))
        leftEarInner.addLine(to: CGPoint(x: 57.3, y: 104.7))
        leftEarInner.closeSubpath()
        ctx.setFillColor(earInner.cgColor)
        ctx.addPath(leftEarInner); ctx.fillPath()
        ctx.restoreGState()

        // ── RIGHT EAR (pivot ~96, 108) ──
        ctx.saveGState()
        ctx.translateBy(x: 95.6, y: 108.0)
        ctx.rotate(by: earAngleR)
        ctx.translateBy(x: -95.6, y: -108.0)
        let rightEarInner = CGMutablePath()
        rightEarInner.move(to: CGPoint(x: 95.6, y: 108.2))
        rightEarInner.addCurve(to: CGPoint(x: 108.1, y: 141.3), control1: CGPoint(x: 95.6, y: 123.0), control2: CGPoint(x: 100.8, y: 135.4))
        rightEarInner.addCurve(to: CGPoint(x: 116.6, y: 136.2), control1: CGPoint(x: 111.3, y: 143.9), control2: CGPoint(x: 116.4, y: 142.4))
        rightEarInner.addCurve(to: CGPoint(x: 102.2, y: 104.7), control1: CGPoint(x: 116.9, y: 126.0), control2: CGPoint(x: 110.3, y: 113.7))
        rightEarInner.addLine(to: CGPoint(x: 95.6, y: 108.2))
        rightEarInner.closeSubpath()
        ctx.setFillColor(earInner.cgColor)
        ctx.addPath(rightEarInner); ctx.fillPath()
        ctx.restoreGState()
    }

    // MARK: - Eye Drawing

    private func drawRabbitEyes(_ ctx: CGContext, expression: RabbitExpression, eyeC: NSColor, bodyDark: NSColor) {
        // Eye positions from SVG (center-left ~60, center-right ~100, Y ~75)
        switch expression {
        case .sleeping:
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.5)
            for centerX in [60.0, 100.0] as [CGFloat] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: centerX - 8, y: 75.0))
                p.addQuadCurve(to: CGPoint(x: centerX + 8, y: 75.0), control: CGPoint(x: centerX, y: 71.0))
                ctx.addPath(p); ctx.strokePath()
            }
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: bodyDark.withAlphaComponent(0.4)
            ]
            NSAttributedString(string: "z", attributes: attrs).draw(at: NSPoint(x: 112, y: 100))
            let a2: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: bodyDark.withAlphaComponent(0.3)
            ]
            NSAttributedString(string: "z", attributes: a2).draw(at: NSPoint(x: 120, y: 112))

        case .blink:
            drawRabbitEyeSVG(ctx, left: true, eyeC: eyeC)
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.5)
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 92, y: 75.0))
            p.addQuadCurve(to: CGPoint(x: 108, y: 75.0), control: CGPoint(x: 100, y: 71.0))
            ctx.addPath(p); ctx.strokePath()

        case .happy:
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.8)
            for centerX in [60.0, 100.0] as [CGFloat] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: centerX - 8, y: 73.0))
                p.addQuadCurve(to: CGPoint(x: centerX + 8, y: 73.0), control: CGPoint(x: centerX, y: 79.0))
                ctx.addPath(p); ctx.strokePath()
            }

        case .love:
            for centerX in [60.0, 100.0] as [CGFloat] {
                let hs: CGFloat = 8.0
                let cy: CGFloat = 75.0
                let p = CGMutablePath()
                p.move(to: CGPoint(x: centerX, y: cy - hs * 0.3))
                p.addCurve(to: CGPoint(x: centerX - hs, y: cy + hs * 0.3),
                           control1: CGPoint(x: centerX - hs * 0.1, y: cy + hs * 0.5),
                           control2: CGPoint(x: centerX - hs, y: cy + hs * 0.8))
                p.addCurve(to: CGPoint(x: centerX, y: cy + hs),
                           control1: CGPoint(x: centerX - hs, y: cy - hs * 0.2),
                           control2: CGPoint(x: centerX, y: cy))
                p.move(to: CGPoint(x: centerX, y: cy - hs * 0.3))
                p.addCurve(to: CGPoint(x: centerX + hs, y: cy + hs * 0.3),
                           control1: CGPoint(x: centerX + hs * 0.1, y: cy + hs * 0.5),
                           control2: CGPoint(x: centerX + hs, y: cy + hs * 0.8))
                p.addCurve(to: CGPoint(x: centerX, y: cy + hs),
                           control1: CGPoint(x: centerX + hs, y: cy - hs * 0.2),
                           control2: CGPoint(x: centerX, y: cy))
                ctx.setFillColor(NSColor(red: 0.9, green: 0.2, blue: 0.3, alpha: 1).cgColor)
                ctx.addPath(p); ctx.fillPath()
            }

        case .excited:
            drawRabbitEyeSVG(ctx, left: true, eyeC: eyeC, highlightScale: 1.4)
            drawRabbitEyeSVG(ctx, left: false, eyeC: eyeC, highlightScale: 1.4)

        case .eating:
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.5)
            for centerX in [60.0, 100.0] as [CGFloat] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: centerX - 7, y: 75.0))
                p.addQuadCurve(to: CGPoint(x: centerX + 7, y: 75.0), control: CGPoint(x: centerX, y: 78.0))
                ctx.addPath(p); ctx.strokePath()
            }

        case .annoyed:
            drawRabbitEyeSVG(ctx, left: true, eyeC: eyeC)
            drawRabbitEyeSVG(ctx, left: false, eyeC: eyeC)
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.5)
            ctx.move(to: CGPoint(x: 50, y: 88)); ctx.addLine(to: CGPoint(x: 68, y: 85)); ctx.strokePath()
            ctx.move(to: CGPoint(x: 110, y: 88)); ctx.addLine(to: CGPoint(x: 92, y: 85)); ctx.strokePath()

        case .shocked:
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 48, y: 65, width: 24, height: 24))
            ctx.setFillColor(eyeC.cgColor)
            ctx.fillEllipse(in: CGRect(x: 57, y: 74, width: 6, height: 6))
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 88, y: 65, width: 24, height: 24))
            ctx.setFillColor(eyeC.cgColor)
            ctx.fillEllipse(in: CGRect(x: 97, y: 74, width: 6, height: 6))

        case .sick:
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(1.8)
            for centerX in [60.0, 100.0] as [CGFloat] {
                let cy: CGFloat = 75.0
                let p = CGMutablePath()
                for i in 0..<12 {
                    let angle = CGFloat(i) * 0.6
                    let r = CGFloat(i) * 0.7 + 1.5
                    let px = centerX + cos(angle) * r
                    let py = cy + sin(angle) * r
                    if i == 0 { p.move(to: CGPoint(x: px, y: py)) }
                    else { p.addLine(to: CGPoint(x: px, y: py)) }
                }
                ctx.addPath(p); ctx.strokePath()
            }

        case .straining:
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.5)
            for centerX in [60.0, 100.0] as [CGFloat] {
                let cy: CGFloat = 75.0; let s: CGFloat = 6
                ctx.move(to: CGPoint(x: centerX - s, y: cy - s))
                ctx.addLine(to: CGPoint(x: centerX + s, y: cy + s)); ctx.strokePath()
                ctx.move(to: CGPoint(x: centerX + s, y: cy - s))
                ctx.addLine(to: CGPoint(x: centerX - s, y: cy + s)); ctx.strokePath()
            }

        case .curious:
            drawRabbitEyeSVG(ctx, left: true, eyeC: eyeC, highlightScale: 1.2)
            drawRabbitEyeSVG(ctx, left: false, eyeC: eyeC)

        case .neutral:
            drawRabbitEyeSVG(ctx, left: true, eyeC: eyeC)
            drawRabbitEyeSVG(ctx, left: false, eyeC: eyeC)
        }
    }

    // MARK: - Mouth Drawing

    private func drawRabbitMouth(_ ctx: CGContext, expression: RabbitExpression, mouthC: NSColor) {
        ctx.setStrokeColor(mouthC.cgColor); ctx.setLineWidth(2.0)
        ctx.setLineCap(.round)

        switch expression {
        case .eating:
            // Open mouth — rabbit munching
            ctx.setFillColor(NSColor(red: 0.85, green: 0.25, blue: 0.2, alpha: 0.8).cgColor)
            ctx.fillEllipse(in: CGRect(x: 76, y: 56, width: 8, height: 6))
            // Buck teeth!
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(CGRect(x: 78, y: 62, width: 2.5, height: 3.5))
            ctx.fill(CGRect(x: 81, y: 62, width: 2.5, height: 3.5))

        case .happy, .love, .excited:
            // Smile curves from SVG
            let smileL = CGMutablePath()
            smileL.move(to: CGPoint(x: 73.5, y: 61.9))
            smileL.addCurve(to: CGPoint(x: 77.1, y: 59.5), control1: CGPoint(x: 74.1, y: 60.0), control2: CGPoint(x: 75.7, y: 59.5))
            smileL.addCurve(to: CGPoint(x: 80.4, y: 63.9), control1: CGPoint(x: 79.5, y: 59.5), control2: CGPoint(x: 80.4, y: 61.4))
            ctx.addPath(smileL); ctx.strokePath()
            let smileR = CGMutablePath()
            smileR.move(to: CGPoint(x: 80.3, y: 61.5))
            smileR.addCurve(to: CGPoint(x: 83.4, y: 59.5), control1: CGPoint(x: 81.0, y: 60.1), control2: CGPoint(x: 82.0, y: 59.5))
            smileR.addCurve(to: CGPoint(x: 86.7, y: 61.9), control1: CGPoint(x: 85.2, y: 59.5), control2: CGPoint(x: 86.4, y: 60.7))
            ctx.addPath(smileR); ctx.strokePath()

        case .shocked:
            // Big O mouth
            ctx.setFillColor(NSColor(red: 0.25, green: 0.10, blue: 0.08, alpha: 0.6).cgColor)
            ctx.fillEllipse(in: CGRect(x: 76, y: 55, width: 8, height: 8))

        default:
            // Neutral bunny mouth — two small curves from SVG
            let smileL = CGMutablePath()
            smileL.move(to: CGPoint(x: 73.5, y: 61.9))
            smileL.addCurve(to: CGPoint(x: 77.1, y: 59.5), control1: CGPoint(x: 74.1, y: 60.0), control2: CGPoint(x: 75.7, y: 59.5))
            smileL.addCurve(to: CGPoint(x: 80.4, y: 63.9), control1: CGPoint(x: 79.5, y: 59.5), control2: CGPoint(x: 80.4, y: 61.4))
            ctx.addPath(smileL); ctx.strokePath()
            let smileR = CGMutablePath()
            smileR.move(to: CGPoint(x: 80.3, y: 61.5))
            smileR.addCurve(to: CGPoint(x: 83.4, y: 59.5), control1: CGPoint(x: 81.0, y: 60.1), control2: CGPoint(x: 82.0, y: 59.5))
            smileR.addCurve(to: CGPoint(x: 86.7, y: 61.9), control1: CGPoint(x: 85.2, y: 59.5), control2: CGPoint(x: 86.4, y: 60.7))
            ctx.addPath(smileR); ctx.strokePath()
        }
    }

    // MARK: - SVG Eye Helper

    private func drawRabbitEyeSVG(_ ctx: CGContext, left: Bool, eyeC: NSColor, highlightScale: CGFloat = 1.0) {
        if left {
            // Left eye white sclera
            let w = CGMutablePath()
            w.move(to: CGPoint(x: 59.8, y: 84.8))
            w.addCurve(to: CGPoint(x: 48.9, y: 73.6), control1: CGPoint(x: 53.0, y: 84.8), control2: CGPoint(x: 48.9, y: 78.7))
            w.addCurve(to: CGPoint(x: 59.6, y: 62.9), control1: CGPoint(x: 48.9, y: 67.4), control2: CGPoint(x: 53.7, y: 62.9))
            w.addCurve(to: CGPoint(x: 70.0, y: 73.6), control1: CGPoint(x: 66.1, y: 62.9), control2: CGPoint(x: 70.0, y: 68.1))
            w.addCurve(to: CGPoint(x: 59.8, y: 84.8), control1: CGPoint(x: 70.0, y: 79.6), control2: CGPoint(x: 65.2, y: 84.8))
            w.closeSubpath()
            ctx.setFillColor(NSColor.white.cgColor); ctx.addPath(w); ctx.fillPath()
            // Left iris
            let d = CGMutablePath()
            d.move(to: CGPoint(x: 61.8, y: 81.6))
            d.addCurve(to: CGPoint(x: 53.8, y: 73.1), control1: CGPoint(x: 56.3, y: 81.6), control2: CGPoint(x: 53.8, y: 76.7))
            d.addCurve(to: CGPoint(x: 61.7, y: 64.6), control1: CGPoint(x: 53.8, y: 68.0), control2: CGPoint(x: 57.9, y: 64.6))
            d.addCurve(to: CGPoint(x: 69.8, y: 73.0), control1: CGPoint(x: 67.1, y: 64.6), control2: CGPoint(x: 69.8, y: 69.0))
            d.addCurve(to: CGPoint(x: 61.8, y: 81.6), control1: CGPoint(x: 69.8, y: 77.8), control2: CGPoint(x: 66.8, y: 81.6))
            d.closeSubpath()
            ctx.setFillColor(eyeC.cgColor); ctx.addPath(d); ctx.fillPath()
            // Highlight
            let hx: CGFloat = 64.7, hy: CGFloat = 77.0
            let hr: CGFloat = 2.5 * highlightScale
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: hx - hr, y: hy - hr, width: hr * 2, height: hr * 2))
        } else {
            // Right eye white sclera
            let w = CGMutablePath()
            w.move(to: CGPoint(x: 100.1, y: 84.8))
            w.addCurve(to: CGPoint(x: 89.1, y: 73.0), control1: CGPoint(x: 92.9, y: 84.8), control2: CGPoint(x: 89.1, y: 78.3))
            w.addCurve(to: CGPoint(x: 99.8, y: 62.9), control1: CGPoint(x: 89.1, y: 67.1), control2: CGPoint(x: 93.6, y: 62.9))
            w.addCurve(to: CGPoint(x: 110.3, y: 73.8), control1: CGPoint(x: 106.3, y: 62.9), control2: CGPoint(x: 110.3, y: 68.9))
            w.addCurve(to: CGPoint(x: 100.1, y: 84.8), control1: CGPoint(x: 110.3, y: 79.6), control2: CGPoint(x: 105.6, y: 84.8))
            w.closeSubpath()
            ctx.setFillColor(NSColor.white.cgColor); ctx.addPath(w); ctx.fillPath()
            // Right iris
            let d = CGMutablePath()
            d.move(to: CGPoint(x: 98.4, y: 81.6))
            d.addCurve(to: CGPoint(x: 90.3, y: 72.7), control1: CGPoint(x: 92.9, y: 81.6), control2: CGPoint(x: 90.3, y: 77.2))
            d.addCurve(to: CGPoint(x: 98.0, y: 64.6), control1: CGPoint(x: 90.3, y: 67.5), control2: CGPoint(x: 94.2, y: 64.6))
            d.addCurve(to: CGPoint(x: 106.2, y: 73.1), control1: CGPoint(x: 103.0, y: 64.6), control2: CGPoint(x: 106.2, y: 69.5))
            d.addCurve(to: CGPoint(x: 98.4, y: 81.6), control1: CGPoint(x: 106.2, y: 77.6), control2: CGPoint(x: 102.4, y: 81.6))
            d.closeSubpath()
            ctx.setFillColor(eyeC.cgColor); ctx.addPath(d); ctx.fillPath()
            // Highlight
            let hx: CGFloat = 95.4, hy: CGFloat = 77.0
            let hr: CGFloat = 2.5 * highlightScale
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: hx - hr, y: hy - hr, width: hr * 2, height: hr * 2))
        }
    }
}

class BirdRenderer {
    static let shared = BirdRenderer()
    private var cache: [String: NSImage] = [:]
    private var cacheKeys: [String] = []
    private let maxCacheSize = 200
    let size: CGFloat = 160

    func clearCache() { cache.removeAll(); cacheKeys.removeAll() }

    private func cacheInsert(_ key: String, _ img: NSImage) {
        if cache[key] != nil { return }
        if cacheKeys.count >= maxCacheSize {
            let old = cacheKeys.removeFirst()
            cache.removeValue(forKey: old)
        }
        cache[key] = img
        cacheKeys.append(key)
    }

    enum BirdExpression {
        case neutral, happy, love, excited, sleeping, blink, eating
        case annoyed, shocked, sick, straining, curious
    }

    enum BirdPose {
        case standing, sitting, walkL, walkR, jump, lyingDown, lyingDown2, stretch
        case flyUp, flyDown  // flying poses with wing positions
    }

    func getSprite(for behavior: PetBehavior, frame: Int, right: Bool) -> NSImage {
        let key = "bird_\(behavior.rawValue)_\(frame % 16)_\(right)"
        if behavior != .lookingAtCursor, let cached = cache[key] { return cached }

        let expression: BirdExpression
        let pose: BirdPose

        switch behavior {
        case .idle:
            expression = frame % 12 == 0 ? .blink : .neutral
            pose = .standing
        case .walking, .edgeWalking, .knockingGlass:
            expression = .neutral
            pose = frame % 4 < 2 ? .walkL : .walkR
        case .running, .chasingCursor, .chasingToy, .zoomies, .chasingButterfly:
            expression = .excited
            pose = frame % 4 < 2 ? .walkL : .walkR
        case .sitting, .watchingBird:
            expression = .neutral
            pose = .sitting
        case .sleeping:
            expression = .sleeping
            pose = frame % 4 < 2 ? .lyingDown : .lyingDown2
        case .eating:
            expression = .eating
            pose = frame % 4 < 2 ? .sitting : .standing
        case .beingPet, .greeting:
            expression = .love
            pose = .standing
        case .playing:
            expression = frame % 3 == 0 ? .happy : .excited
            let cycle = frame % 4
            pose = cycle < 2 ? .jump : (cycle == 2 ? .flyUp : .flyDown)
        case .jumping:
            expression = .excited
            pose = frame % 2 == 0 ? .flyUp : .flyDown
        case .stretching:
            expression = .neutral
            pose = .stretch
        case .tripping:
            expression = .shocked
            pose = .lyingDown
        case .grooming:
            expression = frame % 4 < 2 ? .neutral : .blink
            pose = .sitting
        case .bathing:
            // Bird loves bathing — splashing happily
            expression = frame % 3 == 0 ? .happy : .excited
            pose = frame % 4 < 2 ? .standing : .sitting
        case .scratching:
            expression = .annoyed
            pose = frame % 4 < 2 ? .standing : .stretch
        case .pooping:
            expression = .straining
            pose = .sitting
        case .sick:
            expression = .sick
            pose = .lyingDown
        case .promenade:
            expression = .happy
            pose = frame % 4 < 2 ? .walkL : .walkR
        case .openingGift:
            expression = frame % 3 == 0 ? .excited : .happy
            pose = frame % 2 == 0 ? .flyUp : .flyDown
        case .flying:
            expression = .happy
            pose = frame % 2 == 0 ? .flyUp : .flyDown
        case .clingingEdge:
            expression = .excited
            pose = .standing
        case .lookingAtCursor:
            let mousePos = NSEvent.mouseLocation
            let lookR = mousePos.x > 400
            let quantized = Int(mousePos.x / 200)
            let cursorKey = "bird_cursor_\(quantized)_\(lookR)"
            if let cached = cache[cursorKey] { return cached }
            let img = render(expression: .curious, pose: .standing, lookRight: lookR, walkFrame: 0)
            cacheInsert(cursorKey, img)
            return img
        }

        let img = render(expression: expression, pose: pose, lookRight: right, walkFrame: frame % 16)
        cacheInsert(key, img)
        return img
    }

    func render(expression: BirdExpression, pose: BirdPose, lookRight: Bool, walkFrame: Int = 0) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }
        ctx.setShouldAntialias(true)
        ctx.setAllowsAntialiasing(true)
        ctx.saveGState()

        if !lookRight {
            ctx.translateBy(x: size, y: 0)
            ctx.scaleBy(x: -1, y: 1)
        }

        // ── PALETTE ──
        let bodyMain = NSColor(red: 0.47, green: 0.76, blue: 0.24, alpha: 1)
        let bodyDark = NSColor(red: 0.36, green: 0.63, blue: 0.19, alpha: 1)
        let bellyC = NSColor(red: 0.66, green: 0.88, blue: 0.30, alpha: 1)
        let cheekC = NSColor(red: 0.72, green: 0.88, blue: 0.34, alpha: 1)
        let beakTopC = NSColor(red: 0.72, green: 0.88, blue: 0.34, alpha: 1)
        let beakBotC = NSColor(red: 0.44, green: 0.71, blue: 0.20, alpha: 1)
        let footC = NSColor(red: 0.31, green: 0.60, blue: 0.20, alpha: 1)
        let wingDark = NSColor(red: 0.36, green: 0.63, blue: 0.19, alpha: 1)
        let wingLight = NSColor(red: 0.39, green: 0.68, blue: 0.23, alpha: 1)
        let eyeC = NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)

        let isLying = pose == .lyingDown || pose == .lyingDown2
        let isFlying = pose == .flyUp || pose == .flyDown
        let isWalking = pose == .walkL || pose == .walkR
        let isSitting = pose == .sitting

        // ── Bird animation: waddle walk, hop bounce, fly bob, idle breathing ──
        let birdPhase = walkFrame % 4
        var birdBounce: CGFloat = 0
        var birdSquashX: CGFloat = 1.0, birdSquashY: CGFloat = 1.0
        var birdTilt: CGFloat = 0
        var birdShiftX: CGFloat = 0

        if isWalking {
            // Cute bird waddle — side-to-side with small hops
            switch birdPhase {
            case 0: birdBounce = 0; birdSquashX = 1.04; birdSquashY = 0.96; birdTilt = -0.06
            case 1: birdBounce = 5; birdSquashX = 0.96; birdSquashY = 1.05; birdTilt = 0.02; birdShiftX = 1
            case 2: birdBounce = 1; birdSquashX = 1.04; birdSquashY = 0.96; birdTilt = 0.06
            case 3: birdBounce = 5; birdSquashX = 0.96; birdSquashY = 1.05; birdTilt = -0.02; birdShiftX = -1
            default: break
            }
        } else if pose == .jump {
            birdBounce = 8; birdSquashX = 0.92; birdSquashY = 1.10
        } else if isFlying {
            birdBounce = 6
            let flapPhase = sin(Double(walkFrame) * 1.5)
            birdSquashX = 1.0 + CGFloat(flapPhase) * 0.04
            birdSquashY = 1.0 - CGFloat(flapPhase) * 0.03
        } else if pose == .stretch {
            birdSquashX = 0.90; birdSquashY = 1.12; birdBounce = 3
        } else if !isLying {
            // Idle breathing
            let breathPhase = sin(Double(walkFrame) * 0.8)
            birdSquashX = 1.0 + CGFloat(breathPhase) * 0.015
            birdSquashY = 1.0 - CGFloat(breathPhase) * 0.01
        }

        let sitDrop: CGFloat = isSitting ? -6 : 0
        let lyingDrop: CGFloat = isLying ? -10 : 0

        // Apply squash/stretch centered on body
        let birdCX: CGFloat = 80, birdCY: CGFloat = 60
        ctx.translateBy(x: birdShiftX, y: birdBounce + sitDrop + lyingDrop)
        if birdSquashX != 1.0 || birdSquashY != 1.0 {
            ctx.translateBy(x: birdCX, y: birdCY)
            ctx.scaleBy(x: birdSquashX, y: birdSquashY)
            ctx.translateBy(x: -birdCX, y: -birdCY)
        }
        if birdTilt != 0 {
            ctx.translateBy(x: birdCX, y: 40)
            ctx.rotate(by: birdTilt)
            ctx.translateBy(x: -birdCX, y: -40)
        }

        if isLying {
            // Tilt bird when lying down
            ctx.translateBy(x: 80, y: 40)
            ctx.rotate(by: pose == .lyingDown ? -0.3 : -0.25)
            ctx.translateBy(x: -80, y: -40)
        }

        // ═══ WINGS (drawn behind body, animated by pose) ═══
        drawWings(ctx, pose: pose, wingDark: wingDark, wingLight: wingLight)

        // ═══ FEET (animated during walk, hidden during fly/lying) ═══
        if !isLying && !isFlying {
            drawFeet(ctx, pose: pose, footC: footC, isSitting: isSitting)
        }

        // ═══ BODY ═══
        drawBody(ctx, bodyMain: bodyMain)

        // ═══ BELLY ═══
        drawBelly(ctx, bellyC: bellyC)

        // ═══ CHEEKS ═══
        drawCheeks(ctx, cheekC: cheekC)

        // ═══ EYES (expression-dependent) ═══
        drawEyes(ctx, expression: expression, eyeC: eyeC, bodyDark: bodyDark)

        // ═══ BEAK (expression-dependent for eating) ═══
        drawBeak(ctx, expression: expression, pose: pose, beakTopC: beakTopC, beakBotC: beakBotC)

        ctx.restoreGState()
        img.unlockFocus()
        return img
    }

    // MARK: - Wing Drawing with Animation

    private func drawWings(_ ctx: CGContext, pose: BirdPose, wingDark: NSColor, wingLight: NSColor) {
        // Wing rotation angle based on pose
        let wingAngle: CGFloat
        switch pose {
        case .flyUp:
            wingAngle = 0.45  // wings raised up
        case .flyDown:
            wingAngle = -0.35  // wings swept down
        case .walkL:
            wingAngle = 0.12  // slight flap during walk
        case .walkR:
            wingAngle = -0.08
        case .jump:
            wingAngle = 0.3  // wings up during jump
        case .stretch:
            wingAngle = 0.5  // wings spread wide
        case .sitting:
            wingAngle = -0.1  // wings tucked
        default:
            wingAngle = 0  // neutral
        }

        // ── LEFT WING (pivot near shoulder ~37, 77) ──
        ctx.saveGState()
        ctx.translateBy(x: 37.6, y: 77.3)
        ctx.rotate(by: wingAngle)
        ctx.translateBy(x: -37.6, y: -77.3)

        let leftWing = CGMutablePath()
        leftWing.move(to: CGPoint(x: 29.3, y: 79.2))
        leftWing.addCurve(to: CGPoint(x: 13.9, y: 85.5), control1: CGPoint(x: 22.4, y: 81.1), control2: CGPoint(x: 17.5, y: 83.8))
        leftWing.addCurve(to: CGPoint(x: 7.0, y: 86.8), control1: CGPoint(x: 9.3, y: 87.7), control2: CGPoint(x: 7.9, y: 87.6))
        leftWing.addCurve(to: CGPoint(x: 15.3, y: 70.6), control1: CGPoint(x: 3.8, y: 83.6), control2: CGPoint(x: 7.3, y: 75.0))
        leftWing.addLine(to: CGPoint(x: 15.3, y: 70.6))
        leftWing.addCurve(to: CGPoint(x: 15.0, y: 69.8), control1: CGPoint(x: 15.7, y: 70.4), control2: CGPoint(x: 15.5, y: 69.8))
        leftWing.addCurve(to: CGPoint(x: 8.4, y: 69.7), control1: CGPoint(x: 12.1, y: 70.4), control2: CGPoint(x: 9.4, y: 70.9))
        leftWing.addCurve(to: CGPoint(x: 19.1, y: 59.3), control1: CGPoint(x: 6.3, y: 67.2), control2: CGPoint(x: 10.7, y: 60.9))
        leftWing.addCurve(to: CGPoint(x: 20.9, y: 58.7), control1: CGPoint(x: 20.0, y: 59.1), control2: CGPoint(x: 20.9, y: 59.0))
        leftWing.addCurve(to: CGPoint(x: 18.4, y: 57.8), control1: CGPoint(x: 20.9, y: 58.4), control2: CGPoint(x: 19.8, y: 58.3))
        leftWing.addCurve(to: CGPoint(x: 23.5, y: 51.0), control1: CGPoint(x: 15.0, y: 56.5), control2: CGPoint(x: 16.1, y: 52.5))
        leftWing.addCurve(to: CGPoint(x: 33.1, y: 51.1), control1: CGPoint(x: 27.0, y: 50.3), control2: CGPoint(x: 30.5, y: 50.6))
        leftWing.addLine(to: CGPoint(x: 36.0, y: 53.0))
        leftWing.addLine(to: CGPoint(x: 37.6, y: 77.3))
        leftWing.addLine(to: CGPoint(x: 29.3, y: 79.2))
        leftWing.closeSubpath()
        ctx.setFillColor(wingDark.cgColor)
        ctx.addPath(leftWing); ctx.fillPath()
        ctx.restoreGState()

        // ── RIGHT WING (pivot near shoulder ~125, 78) ──
        ctx.saveGState()
        ctx.translateBy(x: 125.2, y: 77.9)
        ctx.rotate(by: -wingAngle)  // mirror rotation
        ctx.translateBy(x: -125.2, y: -77.9)

        let rightWing = CGMutablePath()
        rightWing.move(to: CGPoint(x: 130.5, y: 79.2))
        rightWing.addCurve(to: CGPoint(x: 145.9, y: 85.5), control1: CGPoint(x: 137.4, y: 81.1), control2: CGPoint(x: 142.3, y: 83.8))
        rightWing.addCurve(to: CGPoint(x: 152.7, y: 87.4), control1: CGPoint(x: 150.5, y: 87.7), control2: CGPoint(x: 151.9, y: 88.2))
        rightWing.addCurve(to: CGPoint(x: 145.0, y: 71.3), control1: CGPoint(x: 155.9, y: 84.7), control2: CGPoint(x: 153.0, y: 75.7))
        rightWing.addLine(to: CGPoint(x: 145.0, y: 71.2))
        rightWing.addCurve(to: CGPoint(x: 145.2, y: 70.5), control1: CGPoint(x: 144.6, y: 71.0), control2: CGPoint(x: 144.8, y: 70.4))
        rightWing.addCurve(to: CGPoint(x: 151.2, y: 69.7), control1: CGPoint(x: 148.1, y: 71.1), control2: CGPoint(x: 150.2, y: 71.2))
        rightWing.addCurve(to: CGPoint(x: 140.6, y: 59.4), control1: CGPoint(x: 152.8, y: 67.2), control2: CGPoint(x: 147.7, y: 61.2))
        rightWing.addCurve(to: CGPoint(x: 139.4, y: 58.8), control1: CGPoint(x: 139.7, y: 59.2), control2: CGPoint(x: 139.4, y: 59.1))
        rightWing.addCurve(to: CGPoint(x: 141.7, y: 57.8), control1: CGPoint(x: 139.4, y: 58.5), control2: CGPoint(x: 140.3, y: 58.4))
        rightWing.addCurve(to: CGPoint(x: 135.8, y: 51.1), control1: CGPoint(x: 144.9, y: 56.4), control2: CGPoint(x: 142.6, y: 52.5))
        rightWing.addCurve(to: CGPoint(x: 126.8, y: 51.3), control1: CGPoint(x: 132.3, y: 50.4), control2: CGPoint(x: 128.7, y: 51.0))
        rightWing.addLine(to: CGPoint(x: 124.6, y: 53.0))
        rightWing.addLine(to: CGPoint(x: 125.2, y: 77.9))
        rightWing.addLine(to: CGPoint(x: 130.5, y: 79.2))
        rightWing.closeSubpath()
        ctx.setFillColor(wingLight.cgColor)
        ctx.addPath(rightWing); ctx.fillPath()
        ctx.restoreGState()
    }

    // MARK: - Feet Drawing with Walk Animation

    private func drawFeet(_ ctx: CGContext, pose: BirdPose, footC: NSColor, isSitting: Bool) {
        // During walking, alternate feet position (one forward, one back)
        let leftFootOffset: CGFloat
        let rightFootOffset: CGFloat
        if pose == .walkL {
            leftFootOffset = 3.0   // left foot forward
            rightFootOffset = -3.0  // right foot back
        } else if pose == .walkR {
            leftFootOffset = -3.0
            rightFootOffset = 3.0
        } else {
            leftFootOffset = 0
            rightFootOffset = 0
        }

        // Sitting: feet splay out wider
        let splayL: CGFloat = isSitting ? -3 : 0
        let splayR: CGFloat = isSitting ? 3 : 0

        // ── LEFT FOOT ──
        ctx.saveGState()
        ctx.translateBy(x: splayL + leftFootOffset, y: 0)
        let leftFoot = CGMutablePath()
        leftFoot.move(to: CGPoint(x: 95.1, y: 23.1))
        leftFoot.addLine(to: CGPoint(x: 95.1, y: 16.1))
        leftFoot.addLine(to: CGPoint(x: 103.7, y: 14.7))
        leftFoot.addCurve(to: CGPoint(x: 105.0, y: 11.8), control1: CGPoint(x: 105.3, y: 14.4), control2: CGPoint(x: 105.7, y: 12.9))
        leftFoot.addCurve(to: CGPoint(x: 102.7, y: 11.1), control1: CGPoint(x: 104.5, y: 11.0), control2: CGPoint(x: 103.5, y: 10.9))
        leftFoot.addLine(to: CGPoint(x: 98.4, y: 12.2))
        leftFoot.addLine(to: CGPoint(x: 99.6, y: 9.6))
        leftFoot.addCurve(to: CGPoint(x: 97.5, y: 7.1), control1: CGPoint(x: 100.3, y: 8.2), control2: CGPoint(x: 99.3, y: 6.5))
        leftFoot.addCurve(to: CGPoint(x: 92.6, y: 12.0), control1: CGPoint(x: 96.0, y: 7.7), control2: CGPoint(x: 94.5, y: 10.9))
        leftFoot.addLine(to: CGPoint(x: 88.3, y: 9.7))
        leftFoot.addCurve(to: CGPoint(x: 85.7, y: 11.3), control1: CGPoint(x: 87.0, y: 9.0), control2: CGPoint(x: 85.7, y: 10.1))
        leftFoot.addCurve(to: CGPoint(x: 87.0, y: 13.3), control1: CGPoint(x: 85.7, y: 12.2), control2: CGPoint(x: 86.3, y: 12.9))
        leftFoot.addLine(to: CGPoint(x: 91.7, y: 15.8))
        leftFoot.addLine(to: CGPoint(x: 91.7, y: 23.1))
        leftFoot.addLine(to: CGPoint(x: 95.1, y: 23.1))
        leftFoot.closeSubpath()
        ctx.setFillColor(footC.cgColor)
        ctx.addPath(leftFoot); ctx.fillPath()
        ctx.restoreGState()

        // ── RIGHT FOOT ──
        ctx.saveGState()
        ctx.translateBy(x: splayR + rightFootOffset, y: 0)
        let rightFoot = CGMutablePath()
        rightFoot.move(to: CGPoint(x: 64.1, y: 23.1))
        rightFoot.addLine(to: CGPoint(x: 64.1, y: 16.1))
        rightFoot.addLine(to: CGPoint(x: 56.4, y: 14.7))
        rightFoot.addCurve(to: CGPoint(x: 55.1, y: 11.8), control1: CGPoint(x: 54.8, y: 14.4), control2: CGPoint(x: 54.4, y: 12.9))
        rightFoot.addCurve(to: CGPoint(x: 57.2, y: 11.1), control1: CGPoint(x: 55.6, y: 11.0), control2: CGPoint(x: 56.4, y: 10.9))
        rightFoot.addLine(to: CGPoint(x: 61.4, y: 12.2))
        rightFoot.addLine(to: CGPoint(x: 60.3, y: 9.7))
        rightFoot.addCurve(to: CGPoint(x: 62.3, y: 7.1), control1: CGPoint(x: 59.6, y: 8.3), control2: CGPoint(x: 60.8, y: 6.9))
        rightFoot.addCurve(to: CGPoint(x: 67.3, y: 12.0), control1: CGPoint(x: 64.0, y: 7.4), control2: CGPoint(x: 65.1, y: 10.9))
        rightFoot.addLine(to: CGPoint(x: 71.6, y: 9.7))
        rightFoot.addCurve(to: CGPoint(x: 74.2, y: 11.3), control1: CGPoint(x: 72.8, y: 9.0), control2: CGPoint(x: 74.2, y: 10.1))
        rightFoot.addCurve(to: CGPoint(x: 72.8, y: 13.3), control1: CGPoint(x: 74.2, y: 12.2), control2: CGPoint(x: 73.5, y: 12.9))
        rightFoot.addLine(to: CGPoint(x: 67.8, y: 15.8))
        rightFoot.addLine(to: CGPoint(x: 67.8, y: 23.1))
        rightFoot.addLine(to: CGPoint(x: 64.1, y: 23.1))
        rightFoot.closeSubpath()
        ctx.setFillColor(footC.cgColor)
        ctx.addPath(rightFoot); ctx.fillPath()
        ctx.restoreGState()
    }

    // MARK: - Body

    private func drawBody(_ ctx: CGContext, bodyMain: NSColor) {
        let bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: 86.8, y: 141.0))
        bodyPath.addCurve(to: CGPoint(x: 75.3, y: 153.6), control1: CGPoint(x: 86.1, y: 147.8), control2: CGPoint(x: 80.5, y: 153.6))
        bodyPath.addCurve(to: CGPoint(x: 74.6, y: 146.7), control1: CGPoint(x: 71.3, y: 154.0), control2: CGPoint(x: 73.0, y: 148.3))
        bodyPath.addCurve(to: CGPoint(x: 65.9, y: 146.6), control1: CGPoint(x: 71.7, y: 147.9), control2: CGPoint(x: 67.3, y: 148.7))
        bodyPath.addCurve(to: CGPoint(x: 69.2, y: 140.5), control1: CGPoint(x: 64.4, y: 144.4), control2: CGPoint(x: 66.8, y: 142.0))
        bodyPath.addCurve(to: CGPoint(x: 29.8, y: 91.2), control1: CGPoint(x: 49.3, y: 137.5), control2: CGPoint(x: 32.2, y: 123.0))
        bodyPath.addCurve(to: CGPoint(x: 50.3, y: 28.0), control1: CGPoint(x: 27.5, y: 70.5), control2: CGPoint(x: 28.6, y: 41.6))
        bodyPath.addCurve(to: CGPoint(x: 80.1, y: 20.5), control1: CGPoint(x: 57.5, y: 23.5), control2: CGPoint(x: 68.0, y: 20.5))
        bodyPath.addCurve(to: CGPoint(x: 122.8, y: 41.7), control1: CGPoint(x: 100.9, y: 20.5), control2: CGPoint(x: 115.1, y: 30.3))
        bodyPath.addCurve(to: CGPoint(x: 130.4, y: 80.6), control1: CGPoint(x: 129.7, y: 52.6), control2: CGPoint(x: 131.3, y: 67.1))
        bodyPath.addCurve(to: CGPoint(x: 86.8, y: 141.0), control1: CGPoint(x: 128.6, y: 113.2), control2: CGPoint(x: 115.0, y: 137.5))
        bodyPath.closeSubpath()
        ctx.setFillColor(bodyMain.cgColor)
        ctx.addPath(bodyPath); ctx.fillPath()
    }

    // MARK: - Belly

    private func drawBelly(_ ctx: CGContext, bellyC: NSColor) {
        let bellyPath = CGMutablePath()
        bellyPath.move(to: CGPoint(x: 79.9, y: 62.7))
        bellyPath.addCurve(to: CGPoint(x: 49.0, y: 32.0), control1: CGPoint(x: 61.5, y: 62.7), control2: CGPoint(x: 49.0, y: 47.6))
        bellyPath.addCurve(to: CGPoint(x: 49.3, y: 28.4), control1: CGPoint(x: 49.0, y: 30.7), control2: CGPoint(x: 49.2, y: 29.5))
        bellyPath.addCurve(to: CGPoint(x: 79.6, y: 20.6), control1: CGPoint(x: 56.5, y: 23.7), control2: CGPoint(x: 66.5, y: 20.6))
        bellyPath.addCurve(to: CGPoint(x: 110.3, y: 28.9), control1: CGPoint(x: 90.6, y: 20.6), control2: CGPoint(x: 100.4, y: 23.3))
        bellyPath.addCurve(to: CGPoint(x: 79.9, y: 62.7), control1: CGPoint(x: 111.2, y: 44.8), control2: CGPoint(x: 100.0, y: 62.7))
        bellyPath.closeSubpath()
        ctx.setFillColor(bellyC.cgColor)
        ctx.addPath(bellyPath); ctx.fillPath()
    }

    // MARK: - Cheeks

    private func drawCheeks(_ ctx: CGContext, cheekC: NSColor) {
        let cheekLPath = CGMutablePath()
        cheekLPath.move(to: CGPoint(x: 42.3, y: 82.8))
        cheekLPath.addCurve(to: CGPoint(x: 37.6, y: 79.9), control1: CGPoint(x: 38.5, y: 82.8), control2: CGPoint(x: 37.6, y: 80.7))
        cheekLPath.addCurve(to: CGPoint(x: 43.6, y: 75.9), control1: CGPoint(x: 37.6, y: 77.5), control2: CGPoint(x: 40.9, y: 75.9))
        cheekLPath.addCurve(to: CGPoint(x: 49.2, y: 79.3), control1: CGPoint(x: 47.4, y: 75.9), control2: CGPoint(x: 49.2, y: 77.5))
        cheekLPath.addCurve(to: CGPoint(x: 42.3, y: 82.8), control1: CGPoint(x: 49.2, y: 81.2), control2: CGPoint(x: 46.9, y: 82.8))
        cheekLPath.closeSubpath()
        ctx.setFillColor(cheekC.cgColor)
        ctx.addPath(cheekLPath); ctx.fillPath()

        let cheekRPath = CGMutablePath()
        cheekRPath.move(to: CGPoint(x: 116.4, y: 82.8))
        cheekRPath.addCurve(to: CGPoint(x: 110.7, y: 79.1), control1: CGPoint(x: 112.6, y: 82.8), control2: CGPoint(x: 110.7, y: 80.6))
        cheekRPath.addCurve(to: CGPoint(x: 115.3, y: 75.9), control1: CGPoint(x: 110.7, y: 76.7), control2: CGPoint(x: 113.1, y: 75.9))
        cheekRPath.addCurve(to: CGPoint(x: 121.7, y: 79.7), control1: CGPoint(x: 118.8, y: 75.9), control2: CGPoint(x: 121.7, y: 78.3))
        cheekRPath.addCurve(to: CGPoint(x: 116.4, y: 82.8), control1: CGPoint(x: 121.7, y: 81.7), control2: CGPoint(x: 119.7, y: 82.8))
        cheekRPath.closeSubpath()
        ctx.setFillColor(cheekC.cgColor)
        ctx.addPath(cheekRPath); ctx.fillPath()
    }

    // MARK: - Eyes (Expression-Dependent)

    private func drawEyes(_ ctx: CGContext, expression: BirdExpression, eyeC: NSColor, bodyDark: NSColor) {
        switch expression {
        case .sleeping:
            // Closed eyes — horizontal curves
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.5)
            for centerX in [55.0, 104.0] as [CGFloat] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: centerX - 8, y: 95.0))
                p.addQuadCurve(to: CGPoint(x: centerX + 8, y: 95.0), control: CGPoint(x: centerX, y: 91.0))
                ctx.addPath(p); ctx.strokePath()
            }
            // Zzz
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: bodyDark.withAlphaComponent(0.4)
            ]
            NSAttributedString(string: "z", attributes: attrs).draw(at: NSPoint(x: 112, y: 112))
            let a2: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: bodyDark.withAlphaComponent(0.3)
            ]
            NSAttributedString(string: "z", attributes: a2).draw(at: NSPoint(x: 120, y: 124))

        case .blink:
            // Left eye normal, right eye closed
            drawBirdEyeSVG(ctx, left: true, eyeC: eyeC)
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.5)
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 96, y: 95.0))
            p.addQuadCurve(to: CGPoint(x: 112, y: 95.0), control: CGPoint(x: 104, y: 91.0))
            ctx.addPath(p); ctx.strokePath()

        case .happy:
            // Happy crescent eyes (curved upward arcs)
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.8)
            for centerX in [55.0, 104.0] as [CGFloat] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: centerX - 8, y: 92.0))
                p.addQuadCurve(to: CGPoint(x: centerX + 8, y: 92.0), control: CGPoint(x: centerX, y: 98.0))
                ctx.addPath(p); ctx.strokePath()
            }

        case .love:
            // Heart-shaped eyes
            for centerX in [55.0, 104.0] as [CGFloat] {
                let heartSize: CGFloat = 9.0
                let cy: CGFloat = 94.0
                let p = CGMutablePath()
                // Left lobe
                p.move(to: CGPoint(x: centerX, y: cy - heartSize * 0.3))
                p.addCurve(to: CGPoint(x: centerX - heartSize, y: cy + heartSize * 0.3),
                           control1: CGPoint(x: centerX - heartSize * 0.1, y: cy + heartSize * 0.5),
                           control2: CGPoint(x: centerX - heartSize, y: cy + heartSize * 0.8))
                p.addCurve(to: CGPoint(x: centerX, y: cy + heartSize),
                           control1: CGPoint(x: centerX - heartSize, y: cy - heartSize * 0.2),
                           control2: CGPoint(x: centerX, y: cy))
                // Right lobe
                p.move(to: CGPoint(x: centerX, y: cy - heartSize * 0.3))
                p.addCurve(to: CGPoint(x: centerX + heartSize, y: cy + heartSize * 0.3),
                           control1: CGPoint(x: centerX + heartSize * 0.1, y: cy + heartSize * 0.5),
                           control2: CGPoint(x: centerX + heartSize, y: cy + heartSize * 0.8))
                p.addCurve(to: CGPoint(x: centerX, y: cy + heartSize),
                           control1: CGPoint(x: centerX + heartSize, y: cy - heartSize * 0.2),
                           control2: CGPoint(x: centerX, y: cy))
                ctx.setFillColor(NSColor(red: 0.9, green: 0.2, blue: 0.3, alpha: 1).cgColor)
                ctx.addPath(p); ctx.fillPath()
            }

        case .excited:
            // Big sparkly eyes — larger SVG eyes with bigger highlight
            drawBirdEyeSVG(ctx, left: true, eyeC: eyeC, highlightScale: 1.4)
            drawBirdEyeSVG(ctx, left: false, eyeC: eyeC, highlightScale: 1.4)

        case .eating:
            // Squinted happy eyes while eating
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.5)
            for centerX in [55.0, 104.0] as [CGFloat] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: centerX - 7, y: 94.0))
                p.addQuadCurve(to: CGPoint(x: centerX + 7, y: 94.0), control: CGPoint(x: centerX, y: 97.0))
                ctx.addPath(p); ctx.strokePath()
            }

        case .annoyed:
            // Squinted angry eyes with angled brows
            drawBirdEyeSVG(ctx, left: true, eyeC: eyeC)
            drawBirdEyeSVG(ctx, left: false, eyeC: eyeC)
            // Angry eyebrows
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.5)
            // Left brow: angled down toward center
            ctx.move(to: CGPoint(x: 46, y: 108)); ctx.addLine(to: CGPoint(x: 62, y: 105))
            ctx.strokePath()
            // Right brow
            ctx.move(to: CGPoint(x: 113, y: 108)); ctx.addLine(to: CGPoint(x: 97, y: 105))
            ctx.strokePath()

        case .shocked:
            // Big wide eyes with tiny pupils
            // Left eye
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 43, y: 84, width: 24, height: 24))
            ctx.setFillColor(eyeC.cgColor)
            ctx.fillEllipse(in: CGRect(x: 52, y: 93, width: 6, height: 6))
            // Right eye
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 92, y: 84, width: 24, height: 24))
            ctx.setFillColor(eyeC.cgColor)
            ctx.fillEllipse(in: CGRect(x: 101, y: 93, width: 6, height: 6))

        case .sick:
            // Spiral/dizzy eyes
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(1.8)
            for centerX in [55.0, 104.0] as [CGFloat] {
                let cy: CGFloat = 94.0
                let p = CGMutablePath()
                // Small spiral
                for i in 0..<12 {
                    let angle = CGFloat(i) * 0.6
                    let r = CGFloat(i) * 0.7 + 1.5
                    let px = centerX + cos(angle) * r
                    let py = cy + sin(angle) * r
                    if i == 0 { p.move(to: CGPoint(x: px, y: py)) }
                    else { p.addLine(to: CGPoint(x: px, y: py)) }
                }
                ctx.addPath(p); ctx.strokePath()
            }

        case .straining:
            // X-shaped eyes
            ctx.setStrokeColor(eyeC.cgColor); ctx.setLineWidth(2.5)
            for centerX in [55.0, 104.0] as [CGFloat] {
                let cy: CGFloat = 94.0; let s: CGFloat = 6
                ctx.move(to: CGPoint(x: centerX - s, y: cy - s))
                ctx.addLine(to: CGPoint(x: centerX + s, y: cy + s))
                ctx.strokePath()
                ctx.move(to: CGPoint(x: centerX + s, y: cy - s))
                ctx.addLine(to: CGPoint(x: centerX - s, y: cy + s))
                ctx.strokePath()
            }

        case .curious:
            // One eye slightly bigger (tilted head feel)
            drawBirdEyeSVG(ctx, left: true, eyeC: eyeC, highlightScale: 1.2)
            drawBirdEyeSVG(ctx, left: false, eyeC: eyeC)

        case .neutral:
            // Standard SVG eyes
            drawBirdEyeSVG(ctx, left: true, eyeC: eyeC)
            drawBirdEyeSVG(ctx, left: false, eyeC: eyeC)
        }
    }

    // MARK: - Beak (Expression-Dependent)

    private func drawBeak(_ ctx: CGContext, expression: BirdExpression, pose: BirdPose, beakTopC: NSColor, beakBotC: NSColor) {
        // Beak opens during eating (lower beak drops)
        let beakOpen: CGFloat = expression == .eating ? -4.0 : 0
        // Shocked: beak slightly open
        let shockOpen: CGFloat = expression == .shocked ? -2.0 : 0
        let openAmount = beakOpen + shockOpen

        // ── BEAK TOP (from SVG) ──
        let beakTopPath = CGMutablePath()
        beakTopPath.move(to: CGPoint(x: 79.6, y: 90.6))
        beakTopPath.addCurve(to: CGPoint(x: 70.2, y: 84.0), control1: CGPoint(x: 73.5, y: 90.6), control2: CGPoint(x: 70.2, y: 84.0))
        beakTopPath.addCurve(to: CGPoint(x: 79.7, y: 80.7), control1: CGPoint(x: 73.7, y: 82.4), control2: CGPoint(x: 77.2, y: 80.7))
        beakTopPath.addCurve(to: CGPoint(x: 89.3, y: 84.0), control1: CGPoint(x: 82.2, y: 80.7), control2: CGPoint(x: 85.8, y: 82.8))
        beakTopPath.addCurve(to: CGPoint(x: 79.6, y: 90.6), control1: CGPoint(x: 89.3, y: 84.0), control2: CGPoint(x: 85.1, y: 90.6))
        beakTopPath.closeSubpath()
        ctx.setFillColor(beakTopC.cgColor)
        ctx.addPath(beakTopPath); ctx.fillPath()

        // ── BEAK BOTTOM (from SVG, shifted down when eating) ──
        ctx.saveGState()
        if openAmount != 0 { ctx.translateBy(x: 0, y: openAmount) }
        let beakBotPath = CGMutablePath()
        beakBotPath.move(to: CGPoint(x: 71.7, y: 82.2))
        beakBotPath.addCurve(to: CGPoint(x: 79.6, y: 77.8), control1: CGPoint(x: 73.5, y: 81.5), control2: CGPoint(x: 77.2, y: 77.8))
        beakBotPath.addCurve(to: CGPoint(x: 87.9, y: 82.2), control1: CGPoint(x: 82.0, y: 77.8), control2: CGPoint(x: 85.2, y: 81.2))
        beakBotPath.addCurve(to: CGPoint(x: 79.8, y: 74.1), control1: CGPoint(x: 86.8, y: 79.4), control2: CGPoint(x: 81.9, y: 74.1))
        beakBotPath.addCurve(to: CGPoint(x: 71.7, y: 82.2), control1: CGPoint(x: 77.3, y: 74.1), control2: CGPoint(x: 72.2, y: 79.9))
        beakBotPath.closeSubpath()
        ctx.setFillColor(beakBotC.cgColor)
        ctx.addPath(beakBotPath); ctx.fillPath()
        ctx.restoreGState()

        // Dark mouth interior visible when beak is open
        if openAmount < -1 {
            ctx.setFillColor(NSColor(red: 0.85, green: 0.25, blue: 0.2, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: 74, y: 77 + openAmount, width: 12, height: max(2, -openAmount)))
        }
    }

    // MARK: - SVG Eye Drawing Helper

    /// Draw one bird eye from exact SVG paths
    private func drawBirdEyeSVG(_ ctx: CGContext, left: Bool, eyeC: NSColor, highlightScale: CGFloat = 1.0) {
        if left {
            // Left eye white sclera
            let w = CGMutablePath()
            w.move(to: CGPoint(x: 55.1, y: 105.8))
            w.addCurve(to: CGPoint(x: 43.3, y: 93.5), control1: CGPoint(x: 48.3, y: 105.4), control2: CGPoint(x: 43.2, y: 99.1))
            w.addCurve(to: CGPoint(x: 55.0, y: 81.7), control1: CGPoint(x: 43.3, y: 86.6), control2: CGPoint(x: 48.6, y: 81.7))
            w.addCurve(to: CGPoint(x: 66.8, y: 93.5), control1: CGPoint(x: 61.5, y: 81.7), control2: CGPoint(x: 66.8, y: 87.7))
            w.addCurve(to: CGPoint(x: 55.1, y: 105.8), control1: CGPoint(x: 66.8, y: 99.6), control2: CGPoint(x: 61.4, y: 106.1))
            w.closeSubpath()
            ctx.setFillColor(NSColor.white.cgColor); ctx.addPath(w); ctx.fillPath()

            // Left eye dark iris
            let d = CGMutablePath()
            d.move(to: CGPoint(x: 57.4, y: 102.1))
            d.addCurve(to: CGPoint(x: 48.2, y: 92.8), control1: CGPoint(x: 51.8, y: 102.1), control2: CGPoint(x: 48.2, y: 97.4))
            d.addCurve(to: CGPoint(x: 57.1, y: 83.9), control1: CGPoint(x: 48.2, y: 87.4), control2: CGPoint(x: 52.4, y: 83.9))
            d.addCurve(to: CGPoint(x: 66.4, y: 93.0), control1: CGPoint(x: 62.5, y: 83.9), control2: CGPoint(x: 66.4, y: 88.8))
            d.addCurve(to: CGPoint(x: 57.4, y: 102.1), control1: CGPoint(x: 66.4, y: 98.1), control2: CGPoint(x: 62.3, y: 102.1))
            d.closeSubpath()
            ctx.setFillColor(eyeC.cgColor); ctx.addPath(d); ctx.fillPath()

            // Left eye highlight (scalable)
            let hx: CGFloat = 60.2, hy: CGFloat = 96.8
            let hr: CGFloat = 2.8 * highlightScale
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: hx - hr, y: hy - hr, width: hr * 2, height: hr * 2))
        } else {
            // Right eye white sclera
            let w = CGMutablePath()
            w.move(to: CGPoint(x: 104.8, y: 105.7))
            w.addCurve(to: CGPoint(x: 92.4, y: 92.8), control1: CGPoint(x: 97.9, y: 105.7), control2: CGPoint(x: 92.4, y: 99.3))
            w.addCurve(to: CGPoint(x: 104.1, y: 81.6), control1: CGPoint(x: 92.4, y: 86.6), control2: CGPoint(x: 97.8, y: 81.6))
            w.addCurve(to: CGPoint(x: 116.0, y: 93.5), control1: CGPoint(x: 110.9, y: 81.6), control2: CGPoint(x: 116.1, y: 87.9))
            w.addCurve(to: CGPoint(x: 104.8, y: 105.7), control1: CGPoint(x: 116.0, y: 99.9), control2: CGPoint(x: 111.0, y: 105.7))
            w.closeSubpath()
            ctx.setFillColor(NSColor.white.cgColor); ctx.addPath(w); ctx.fillPath()

            // Right eye dark iris
            let d = CGMutablePath()
            d.move(to: CGPoint(x: 103.0, y: 102.1))
            d.addCurve(to: CGPoint(x: 92.8, y: 92.3), control1: CGPoint(x: 97.4, y: 102.1), control2: CGPoint(x: 92.8, y: 97.4))
            d.addCurve(to: CGPoint(x: 101.8, y: 83.6), control1: CGPoint(x: 92.8, y: 87.2), control2: CGPoint(x: 97.2, y: 83.6))
            d.addCurve(to: CGPoint(x: 111.0, y: 92.7), control1: CGPoint(x: 107.2, y: 83.6), control2: CGPoint(x: 111.0, y: 88.5))
            d.addCurve(to: CGPoint(x: 103.0, y: 102.1), control1: CGPoint(x: 111.0, y: 97.8), control2: CGPoint(x: 106.6, y: 102.1))
            d.closeSubpath()
            ctx.setFillColor(eyeC.cgColor); ctx.addPath(d); ctx.fillPath()

            // Right eye highlight (scalable)
            let hx: CGFloat = 99.4, hy: CGFloat = 96.8
            let hr: CGFloat = 2.8 * highlightScale
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: hx - hr, y: hy - hr, width: hr * 2, height: hr * 2))
        }
    }
}
*/ // end of commented-out Rabbit & Bird Renderers

// MARK: - Kawaii Vector Items

class KawaiiItems {

    static func drawSparkle(_ ctx: CGContext, center: CGPoint, radius: CGFloat, color: NSColor, lineWidth: CGFloat = 1.2) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.move(to: CGPoint(x: center.x - radius, y: center.y))
        ctx.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: center.x, y: center.y - radius))
        ctx.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: center.x - radius * 0.7, y: center.y - radius * 0.7))
        ctx.addLine(to: CGPoint(x: center.x + radius * 0.7, y: center.y + radius * 0.7))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: center.x - radius * 0.7, y: center.y + radius * 0.7))
        ctx.addLine(to: CGPoint(x: center.x + radius * 0.7, y: center.y - radius * 0.7))
        ctx.strokePath()
    }

    /// Cute butterfly with wing flap animation (2 frames). Pink/purple wings, small body.
    static func butterfly(frame: Int) -> NSImage {
        let size: CGFloat = 36
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }

        let cx = size / 2
        let cy = size / 2
        let wingsUp = frame % 2 == 0

        // Body (small dark ellipse)
        ctx.setFillColor(NSColor(red: 0.25, green: 0.15, blue: 0.3, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 2, y: cy - 6, width: 4, height: 12))
        ctx.fillPath()

        // Antennae
        ctx.setStrokeColor(NSColor(red: 0.25, green: 0.15, blue: 0.3, alpha: 1).cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: cx - 1, y: cy + 6))
        ctx.addCurve(to: CGPoint(x: cx - 6, y: cy + 12),
                     control1: CGPoint(x: cx - 3, y: cy + 9),
                     control2: CGPoint(x: cx - 5, y: cy + 11))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: cx + 1, y: cy + 6))
        ctx.addCurve(to: CGPoint(x: cx + 6, y: cy + 12),
                     control1: CGPoint(x: cx + 3, y: cy + 9),
                     control2: CGPoint(x: cx + 5, y: cy + 11))
        ctx.strokePath()
        // Antenna tips
        ctx.setFillColor(NSColor(red: 0.25, green: 0.15, blue: 0.3, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 7.5, y: cy + 11, width: 3, height: 3))
        ctx.fillPath()
        ctx.addEllipse(in: CGRect(x: cx + 4.5, y: cy + 11, width: 3, height: 3))
        ctx.fillPath()

        // Wings
        let wingSpreadY: CGFloat = wingsUp ? 6 : 2
        let wingSpreadX: CGFloat = wingsUp ? 12 : 10

        // Upper wings (pink-purple gradient look)
        ctx.setFillColor(NSColor(red: 0.9, green: 0.4, blue: 0.7, alpha: 0.85).cgColor)
        // Left upper
        ctx.addEllipse(in: CGRect(x: cx - wingSpreadX - 8, y: cy + wingSpreadY - 4, width: 12, height: 10))
        ctx.fillPath()
        // Right upper
        ctx.addEllipse(in: CGRect(x: cx + wingSpreadX - 4, y: cy + wingSpreadY - 4, width: 12, height: 10))
        ctx.fillPath()

        // Lower wings (lighter purple)
        ctx.setFillColor(NSColor(red: 0.7, green: 0.4, blue: 0.9, alpha: 0.75).cgColor)
        // Left lower
        ctx.addEllipse(in: CGRect(x: cx - wingSpreadX - 5, y: cy - wingSpreadY - 6, width: 9, height: 8))
        ctx.fillPath()
        // Right lower
        ctx.addEllipse(in: CGRect(x: cx + wingSpreadX - 4, y: cy - wingSpreadY - 6, width: 9, height: 8))
        ctx.fillPath()

        // Wing pattern dots
        ctx.setFillColor(NSColor(red: 1, green: 0.7, blue: 0.85, alpha: 0.6).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - wingSpreadX - 4, y: cy + wingSpreadY - 1, width: 4, height: 4))
        ctx.fillPath()
        ctx.addEllipse(in: CGRect(x: cx + wingSpreadX, y: cy + wingSpreadY - 1, width: 4, height: 4))
        ctx.fillPath()

        img.unlockFocus()
        return img
    }

    /// Cute little robin/sparrow. Brown body, orange chest, small beak.
    static func bird() -> NSImage {
        let size: CGFloat = 30
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }

        let cx = size / 2
        let cy: CGFloat = 10

        ctx.setFillColor(NSColor.black.withAlphaComponent(0.12).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 9, y: cy - 5, width: 18, height: 4))
        ctx.fillPath()

        // Tail feathers
        ctx.setFillColor(NSColor(red: 0.45, green: 0.32, blue: 0.22, alpha: 1).cgColor)
        ctx.move(to: CGPoint(x: cx - 8, y: cy + 4))
        ctx.addLine(to: CGPoint(x: cx - 14, y: cy + 10))
        ctx.addLine(to: CGPoint(x: cx - 12, y: cy + 6))
        ctx.addLine(to: CGPoint(x: cx - 16, y: cy + 8))
        ctx.addLine(to: CGPoint(x: cx - 10, y: cy + 2))
        ctx.closePath()
        ctx.fillPath()

        // Body (brown)
        ctx.setFillColor(NSColor(red: 0.55, green: 0.38, blue: 0.26, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 8, y: cy - 2, width: 16, height: 14))
        ctx.fillPath()
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.18).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 4, y: cy + 3, width: 6, height: 4))
        ctx.fillPath()

        // Wing
        ctx.setFillColor(NSColor(red: 0.47, green: 0.31, blue: 0.23, alpha: 0.95).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 4, y: cy + 1, width: 9, height: 7))
        ctx.fillPath()

        // Chest (orange)
        ctx.setFillColor(NSColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 4, y: cy - 1, width: 10, height: 9))
        ctx.fillPath()

        // Head (brown, slightly smaller)
        ctx.setFillColor(NSColor(red: 0.55, green: 0.38, blue: 0.26, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 2, y: cy + 8, width: 12, height: 11))
        ctx.fillPath()

        // Eye (black dot with white highlight)
        ctx.setFillColor(NSColor(white: 0.1, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: cx + 4, y: cy + 12, width: 3.5, height: 3.5))
        ctx.fillPath()
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.addEllipse(in: CGRect(x: cx + 5, y: cy + 13.5, width: 1.5, height: 1.5))
        ctx.fillPath()

        // Beak (orange triangle)
        ctx.setFillColor(NSColor(red: 1, green: 0.65, blue: 0.1, alpha: 1).cgColor)
        ctx.move(to: CGPoint(x: cx + 10, y: cy + 13))
        ctx.addLine(to: CGPoint(x: cx + 14, y: cy + 12))
        ctx.addLine(to: CGPoint(x: cx + 10, y: cy + 11))
        ctx.closePath()
        ctx.fillPath()

        // Legs
        ctx.setStrokeColor(NSColor(red: 0.85, green: 0.55, blue: 0.15, alpha: 1).cgColor)
        ctx.setLineWidth(1.2)
        ctx.move(to: CGPoint(x: cx - 1, y: cy))
        ctx.addLine(to: CGPoint(x: cx - 2, y: cy - 4))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: cx + 3, y: cy))
        ctx.addLine(to: CGPoint(x: cx + 4, y: cy - 4))
        ctx.strokePath()

        ctx.setStrokeColor(NSColor(white: 0.2, alpha: 0.7).cgColor)
        ctx.setLineWidth(1)
        ctx.addEllipse(in: CGRect(x: cx - 8, y: cy - 2, width: 16, height: 14))
        ctx.strokePath()

        // Cheek blush
        ctx.setFillColor(NSColor(red: 1, green: 0.6, blue: 0.5, alpha: 0.4).cgColor)
        ctx.addEllipse(in: CGRect(x: cx + 1, y: cy + 10, width: 4, height: 3))
        ctx.fillPath()

        img.unlockFocus()
        return img
    }

    /// Kawaii gift box. Red box with yellow ribbon/bow on top, sparkle.
    static func gift() -> NSImage {
        let size: CGFloat = 40
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }

        let cx = size / 2
        let boxW: CGFloat = 28
        let boxH: CGFloat = 20
        let boxX = cx - boxW / 2
        let boxY: CGFloat = 4

        // Box shadow
        ctx.setFillColor(NSColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 0.3).cgColor)
        let shadowRect = CGRect(x: boxX + 2, y: boxY - 2, width: boxW, height: boxH)
        let shadowPath = CGPath(roundedRect: shadowRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        ctx.addPath(shadowPath)
        ctx.fillPath()

        // Box body (red)
        ctx.setFillColor(NSColor(red: 0.9, green: 0.2, blue: 0.25, alpha: 1).cgColor)
        let boxRect = CGRect(x: boxX, y: boxY, width: boxW, height: boxH)
        let boxPath = CGPath(roundedRect: boxRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        ctx.addPath(boxPath)
        ctx.fillPath()
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.16).cgColor)
        ctx.addPath(CGPath(roundedRect: CGRect(x: boxX + 3, y: boxY + boxH - 7, width: boxW - 10, height: 4), cornerWidth: 2, cornerHeight: 2, transform: nil))
        ctx.fillPath()

        // Box outline
        ctx.setStrokeColor(NSColor(red: 0.6, green: 0.1, blue: 0.12, alpha: 1).cgColor)
        ctx.setLineWidth(1.5)
        ctx.addPath(boxPath)
        ctx.strokePath()

        // Ribbon vertical stripe
        ctx.setFillColor(NSColor(red: 1, green: 0.84, blue: 0, alpha: 1).cgColor)
        ctx.fill(CGRect(x: cx - 2.5, y: boxY, width: 5, height: boxH))

        // Ribbon horizontal stripe
        ctx.fill(CGRect(x: boxX, y: boxY + boxH / 2 - 2.5, width: boxW, height: 5))

        // Lid (slightly wider, darker)
        let lidH: CGFloat = 6
        let lidRect = CGRect(x: boxX - 2, y: boxY + boxH, width: boxW + 4, height: lidH)
        ctx.setFillColor(NSColor(red: 0.85, green: 0.15, blue: 0.2, alpha: 1).cgColor)
        let lidPath = CGPath(roundedRect: lidRect, cornerWidth: 2, cornerHeight: 2, transform: nil)
        ctx.addPath(lidPath)
        ctx.fillPath()
        ctx.setStrokeColor(NSColor(red: 0.6, green: 0.1, blue: 0.12, alpha: 1).cgColor)
        ctx.setLineWidth(1.2)
        ctx.addPath(lidPath)
        ctx.strokePath()

        // Ribbon on lid
        ctx.setFillColor(NSColor(red: 1, green: 0.84, blue: 0, alpha: 1).cgColor)
        ctx.fill(CGRect(x: cx - 2.5, y: boxY + boxH, width: 5, height: lidH))

        // Bow on top
        let bowY = boxY + boxH + lidH
        ctx.setFillColor(NSColor(red: 1, green: 0.84, blue: 0, alpha: 1).cgColor)
        // Left loop
        ctx.addEllipse(in: CGRect(x: cx - 9, y: bowY - 1, width: 9, height: 7))
        ctx.fillPath()
        // Right loop
        ctx.addEllipse(in: CGRect(x: cx, y: bowY - 1, width: 9, height: 7))
        ctx.fillPath()
        // Center knot
        ctx.setFillColor(NSColor(red: 0.9, green: 0.7, blue: 0, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 2.5, y: bowY, width: 5, height: 5))
        ctx.fillPath()

        // Tiny hanging heart tag
        let tagX = cx + 11
        let tagY = boxY + boxH + 4
        ctx.setStrokeColor(NSColor(red: 0.85, green: 0.7, blue: 0.15, alpha: 0.9).cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: cx + 7, y: bowY + 1))
        ctx.addLine(to: CGPoint(x: tagX, y: tagY + 1))
        ctx.strokePath()
        ctx.setFillColor(NSColor(red: 1, green: 0.82, blue: 0.2, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: tagX - 3, y: tagY - 3, width: 6, height: 6))
        ctx.fillPath()
        ctx.setFillColor(NSColor(red: 1, green: 0.42, blue: 0.55, alpha: 0.95).cgColor)
        let heart = CGMutablePath()
        heart.move(to: CGPoint(x: tagX, y: tagY - 1))
        heart.addQuadCurve(to: CGPoint(x: tagX - 2, y: tagY + 1), control: CGPoint(x: tagX - 2, y: tagY - 1))
        heart.addQuadCurve(to: CGPoint(x: tagX, y: tagY + 3), control: CGPoint(x: tagX - 2, y: tagY + 3))
        heart.addQuadCurve(to: CGPoint(x: tagX + 2, y: tagY + 1), control: CGPoint(x: tagX + 2, y: tagY + 3))
        heart.addQuadCurve(to: CGPoint(x: tagX, y: tagY - 1), control: CGPoint(x: tagX + 2, y: tagY - 1))
        heart.closeSubpath()
        ctx.addPath(heart)
        ctx.fillPath()

        // Sparkle
        let sx: CGFloat = cx + 12, sy: CGFloat = boxY + boxH + 8
        drawSparkle(ctx, center: CGPoint(x: sx, y: sy), radius: 3, color: NSColor(red: 1, green: 1, blue: 0.7, alpha: 0.9))
        drawSparkle(ctx, center: CGPoint(x: boxX + 4, y: boxY + boxH + 12), radius: 2, color: NSColor.white.withAlphaComponent(0.7), lineWidth: 0.9)

        img.unlockFocus()
        return img
    }

    /// Cute glass/cup. Translucent blue, simple shape.
    static func glass() -> NSImage {
        let size: CGFloat = 30
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }

        let cx = size / 2

        ctx.setFillColor(NSColor.black.withAlphaComponent(0.12).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 7, y: 0, width: 14, height: 3))
        ctx.fillPath()

        // Glass body (trapezoid shape, wider at top)
        ctx.setFillColor(NSColor(red: 0.6, green: 0.8, blue: 1, alpha: 0.4).cgColor)
        ctx.move(to: CGPoint(x: cx - 6, y: 3))
        ctx.addLine(to: CGPoint(x: cx - 8, y: 22))
        ctx.addLine(to: CGPoint(x: cx + 8, y: 22))
        ctx.addLine(to: CGPoint(x: cx + 6, y: 3))
        ctx.closePath()
        ctx.fillPath()

        // Rim
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.65).cgColor)
        ctx.setLineWidth(1.1)
        ctx.addEllipse(in: CGRect(x: cx - 8, y: 20.5, width: 16, height: 3.5))
        ctx.strokePath()

        // Glass outline
        ctx.setStrokeColor(NSColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 0.8).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: cx - 6, y: 3))
        ctx.addLine(to: CGPoint(x: cx - 8, y: 22))
        ctx.addLine(to: CGPoint(x: cx + 8, y: 22))
        ctx.addLine(to: CGPoint(x: cx + 6, y: 3))
        ctx.closePath()
        ctx.strokePath()

        // Water inside
        ctx.setFillColor(NSColor(red: 0.4, green: 0.65, blue: 1, alpha: 0.35).cgColor)
        ctx.move(to: CGPoint(x: cx - 5.5, y: 3))
        ctx.addLine(to: CGPoint(x: cx - 7, y: 14))
        ctx.addLine(to: CGPoint(x: cx + 7, y: 14))
        ctx.addLine(to: CGPoint(x: cx + 5.5, y: 3))
        ctx.closePath()
        ctx.fillPath()

        // Water surface + bubbles
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.45).cgColor)
        ctx.setLineWidth(0.8)
        ctx.move(to: CGPoint(x: cx - 6.5, y: 14))
        ctx.addCurve(to: CGPoint(x: cx + 6.5, y: 14),
                     control1: CGPoint(x: cx - 2, y: 15.3),
                     control2: CGPoint(x: cx + 2, y: 12.7))
        ctx.strokePath()
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.32).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 2, y: 8, width: 2.2, height: 2.2))
        ctx.fillPath()
        ctx.addEllipse(in: CGRect(x: cx + 1.5, y: 11, width: 1.8, height: 1.8))
        ctx.fillPath()

        // Shine highlight
        ctx.setStrokeColor(NSColor(white: 1, alpha: 0.5).cgColor)
        ctx.setLineWidth(1.2)
        ctx.move(to: CGPoint(x: cx - 4, y: 7))
        ctx.addLine(to: CGPoint(x: cx - 5.5, y: 18))
        ctx.strokePath()

        // Bottom
        ctx.setFillColor(NSColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 0.5).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 6, y: 1, width: 12, height: 4))
        ctx.fillPath()

        img.unlockFocus()
        return img
    }

    /// Gray toy mouse with pink ears and string tail.
    static func mouseToy() -> NSImage {
        let size: CGFloat = 30
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }

        ctx.setFillColor(NSColor.black.withAlphaComponent(0.12).cgColor)
        ctx.addEllipse(in: CGRect(x: 5, y: 4, width: 18, height: 3))
        ctx.fillPath()

        // Tail (string)
        ctx.setStrokeColor(NSColor(red: 0.8, green: 0.5, blue: 0.5, alpha: 1).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: 3, y: 15))
        ctx.addCurve(to: CGPoint(x: 0, y: 24),
                     control1: CGPoint(x: 1, y: 18),
                     control2: CGPoint(x: -1, y: 21))
        ctx.strokePath()

        // Body (gray oval)
        ctx.setFillColor(NSColor(red: 0.65, green: 0.65, blue: 0.68, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: 3, y: 7, width: 20, height: 14))
        ctx.fillPath()
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.18).cgColor)
        ctx.addEllipse(in: CGRect(x: 8, y: 15, width: 7, height: 3.5))
        ctx.fillPath()
        // Body outline
        ctx.setStrokeColor(NSColor(white: 0.3, alpha: 1).cgColor)
        ctx.setLineWidth(1.2)
        ctx.addEllipse(in: CGRect(x: 3, y: 7, width: 20, height: 14))
        ctx.strokePath()

        // Head
        ctx.setFillColor(NSColor(red: 0.65, green: 0.65, blue: 0.68, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: 16, y: 9, width: 10, height: 10))
        ctx.fillPath()
        ctx.setStrokeColor(NSColor(white: 0.3, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: 16, y: 9, width: 10, height: 10))
        ctx.strokePath()

        // Ears (pink)
        ctx.setFillColor(NSColor(red: 1, green: 0.7, blue: 0.75, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: 19, y: 18, width: 6, height: 7))
        ctx.fillPath()
        ctx.addEllipse(in: CGRect(x: 23, y: 17, width: 6, height: 7))
        ctx.fillPath()
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.35).cgColor)
        ctx.addEllipse(in: CGRect(x: 20.5, y: 20.5, width: 2, height: 2))
        ctx.fillPath()
        ctx.addEllipse(in: CGRect(x: 24.5, y: 19.5, width: 2, height: 2))
        ctx.fillPath()

        // Eye
        ctx.setFillColor(NSColor(white: 0.1, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: 22, y: 13, width: 2.5, height: 2.5))
        ctx.fillPath()

        // Nose (pink dot)
        ctx.setFillColor(NSColor(red: 1, green: 0.5, blue: 0.55, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: 25, y: 12, width: 2, height: 2))
        ctx.fillPath()

        // Whiskers
        ctx.setStrokeColor(NSColor(white: 0.4, alpha: 0.6).cgColor)
        ctx.setLineWidth(0.6)
        for dy: CGFloat in [-2, 0, 2] {
            ctx.move(to: CGPoint(x: 25, y: 13 + dy))
            ctx.addLine(to: CGPoint(x: 29, y: 12 + dy))
            ctx.strokePath()
        }

        // Tiny stitched seam to make it feel like a plush toy
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.55).cgColor)
        ctx.setLineWidth(0.8)
        ctx.move(to: CGPoint(x: 10, y: 10))
        ctx.addLine(to: CGPoint(x: 15, y: 18))
        ctx.strokePath()

        img.unlockFocus()
        return img
    }

    /// Red yarn ball with thread lines.
    static func yarnBall() -> NSImage {
        let size: CGFloat = 30
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }

        let cx = size / 2
        let cy = size / 2
        let r: CGFloat = 11

        // Ball shadow
        ctx.setFillColor(NSColor(red: 0.6, green: 0.15, blue: 0.15, alpha: 0.3).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - r + 2, y: cy - r - 2, width: r * 2, height: r * 2))
        ctx.fillPath()

        // Ball body
        ctx.setFillColor(NSColor(red: 0.88, green: 0.25, blue: 0.25, alpha: 1).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        ctx.fillPath()
        ctx.setStrokeColor(NSColor(red: 0.68, green: 0.15, blue: 0.16, alpha: 0.9).cgColor)
        ctx.setLineWidth(1.1)
        ctx.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        ctx.strokePath()

        // Thread lines (curved)
        ctx.setStrokeColor(NSColor(red: 1, green: 0.5, blue: 0.5, alpha: 0.7).cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: cx - 6, y: cy + 5))
        ctx.addCurve(to: CGPoint(x: cx + 8, y: cy + 3),
                     control1: CGPoint(x: cx - 2, y: cy + 10),
                     control2: CGPoint(x: cx + 4, y: cy - 3))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: cx - 4, y: cy - 2))
        ctx.addCurve(to: CGPoint(x: cx + 6, y: cy - 4),
                     control1: CGPoint(x: cx, y: cy - 8),
                     control2: CGPoint(x: cx + 3, y: cy + 2))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: cx - 7, y: cy))
        ctx.addCurve(to: CGPoint(x: cx + 3, y: cy + 7),
                     control1: CGPoint(x: cx - 5, y: cy + 6),
                     control2: CGPoint(x: cx, y: cy + 8))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: cx - 8, y: cy - 6))
        ctx.addCurve(to: CGPoint(x: cx + 7, y: cy - 5),
                     control1: CGPoint(x: cx - 2, y: cy - 10),
                     control2: CGPoint(x: cx + 2, y: cy - 8))
        ctx.strokePath()

        // Highlight
        ctx.setFillColor(NSColor(red: 1, green: 0.7, blue: 0.7, alpha: 0.4).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 4, y: cy + 2, width: 5, height: 4))
        ctx.fillPath()
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.18).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 1, y: cy + 5, width: 3, height: 2))
        ctx.fillPath()

        // Dangling thread
        ctx.setStrokeColor(NSColor(red: 0.88, green: 0.25, blue: 0.25, alpha: 0.8).cgColor)
        ctx.setLineWidth(1.2)
        ctx.move(to: CGPoint(x: cx + r - 2, y: cy - 2))
        ctx.addCurve(to: CGPoint(x: cx + r + 5, y: cy - 10),
                     control1: CGPoint(x: cx + r + 2, y: cy - 4),
                     control2: CGPoint(x: cx + r + 4, y: cy - 8))
        ctx.strokePath()

        img.unlockFocus()
        return img
    }

    /// Red glowing dot with glow effect.
    static func laserDot() -> NSImage {
        let size: CGFloat = 30
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }

        let cx = size / 2
        let cy = size / 2

        // Outer glow
        ctx.setFillColor(NSColor(red: 1, green: 0, blue: 0, alpha: 0.15).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 12, y: cy - 12, width: 24, height: 24))
        ctx.fillPath()

        // Mid glow
        ctx.setFillColor(NSColor(red: 1, green: 0.1, blue: 0.1, alpha: 0.3).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 8, y: cy - 8, width: 16, height: 16))
        ctx.fillPath()

        // Inner glow
        ctx.setFillColor(NSColor(red: 1, green: 0.2, blue: 0.2, alpha: 0.5).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 5, y: cy - 5, width: 10, height: 10))
        ctx.fillPath()

        // Core dot
        ctx.setFillColor(NSColor(red: 1, green: 0.1, blue: 0, alpha: 0.95).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 3, y: cy - 3, width: 6, height: 6))
        ctx.fillPath()

        // Bright center
        ctx.setFillColor(NSColor(red: 1, green: 0.6, blue: 0.5, alpha: 0.8).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - 1.5, y: cy - 1.5, width: 3, height: 3))
        ctx.fillPath()

        drawSparkle(ctx, center: CGPoint(x: cx + 6, y: cy + 6), radius: 2.2, color: NSColor.white.withAlphaComponent(0.55), lineWidth: 0.9)
        drawSparkle(ctx, center: CGPoint(x: cx - 7, y: cy - 5), radius: 1.4, color: NSColor(red: 1, green: 0.7, blue: 0.7, alpha: 0.45), lineWidth: 0.7)

        img.unlockFocus()
        return img
    }

    /// Renders an accessory using its vectorDraw closure into an NSImage of given size.
    static func renderAccessory(_ acc: Accessory, size: CGFloat) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext, let draw = acc.vectorDraw {
            draw(ctx, size / 2, size / 2)
        }
        img.unlockFocus()
        return img
    }
}

// MARK: - Sound Engine

class SoundEngine {
    static let shared = SoundEngine()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var isSetup = false
    private var volume: Float = 0.3

    private func setup() {
        guard !isSetup else { return }
        engine.attach(playerNode)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = volume
        do {
            try engine.start()
            isSetup = true
        } catch {
            print("Sound engine failed: \(error)")
        }
    }

    func setVolume(_ v: Float) {
        volume = v
        if isSetup { engine.mainMixerNode.outputVolume = v }
    }

    // Generate a tone buffer
    private func makeBuffer(duration: Double, generator: (Int, Double) -> Float) -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            data[i] = generator(i, t)
        }
        return buffer
    }

    // Purring — low rumble with amplitude modulation
    func purr() {
        setup()
        guard let buffer = makeBuffer(duration: 1.2, generator: { _, t in
            let freq = 25.0 + sin(t * 3) * 5  // ~25Hz rumble
            let base = sin(2 * .pi * freq * t)
            let harmonic = sin(2 * .pi * freq * 2 * t) * 0.3
            let envelope = sin(.pi * t / 1.2) // fade in/out
            let am = (1.0 + sin(2 * .pi * 4 * t)) * 0.5 // amplitude modulation ~4Hz
            return Float((base + harmonic) * envelope * am * 0.4)
        }) else { return }
        playBuffer(buffer)
    }

    // Meow — rising then falling tone
    func meow() {
        setup()
        guard let buffer = makeBuffer(duration: 0.4, generator: { _, t in
            let progress = t / 0.4
            // Frequency rises then falls: 400 -> 800 -> 500
            let freq: Double
            if progress < 0.3 {
                freq = 400 + (progress / 0.3) * 400
            } else {
                freq = 800 - ((progress - 0.3) / 0.7) * 300
            }
            let base = sin(2 * .pi * freq * t)
            let h2 = sin(2 * .pi * freq * 2 * t) * 0.2
            let envelope = sin(.pi * progress)
            return Float((base + h2) * envelope * 0.3)
        }) else { return }
        playBuffer(buffer)
    }

    // Short chirp — quick rising tone
    func chirp() {
        setup()
        guard let buffer = makeBuffer(duration: 0.15, generator: { _, t in
            let freq = 600 + t * 3000  // quick sweep up
            let envelope = sin(.pi * t / 0.15)
            return Float(sin(2 * .pi * freq * t) * envelope * 0.25)
        }) else { return }
        playBuffer(buffer)
    }

    // Eating — crunchy repeating sound
    func eat() {
        setup()
        guard let buffer = makeBuffer(duration: 0.5, generator: { i, t in
            let crunch = (i % Int(44100 * 0.08) < Int(44100 * 0.03)) ? 1.0 : 0.0
            let noise = Double.random(in: -1...1)
            let tone = sin(2 * .pi * 200 * t)
            let envelope = sin(.pi * t / 0.5)
            return Float((noise * 0.6 + tone * 0.4) * crunch * envelope * 0.2)
        }) else { return }
        playBuffer(buffer)
    }

    // Happy sound — ascending notes
    func happy() {
        setup()
        guard let buffer = makeBuffer(duration: 0.3, generator: { _, t in
            let progress = t / 0.3
            let freq = 500 + progress * 500  // 500 -> 1000
            let envelope = sin(.pi * progress)
            return Float(sin(2 * .pi * freq * t) * envelope * 0.2)
        }) else { return }
        playBuffer(buffer)
    }

    // Sad sound — descending tone
    func sad() {
        setup()
        guard let buffer = makeBuffer(duration: 0.4, generator: { _, t in
            let progress = t / 0.4
            let freq = 500 - progress * 200  // 500 -> 300
            let envelope = sin(.pi * progress) * (1 - progress * 0.5)
            return Float(sin(2 * .pi * freq * t) * envelope * 0.2)
        }) else { return }
        playBuffer(buffer)
    }

    // Pop — gift opening, level up
    func pop() {
        setup()
        guard let buffer = makeBuffer(duration: 0.2, generator: { _, t in
            let freq = 800 + (1 - t / 0.2) * 600  // 1400 -> 800
            let envelope = exp(-t * 15)
            return Float(sin(2 * .pi * freq * t) * envelope * 0.35)
        }) else { return }
        playBuffer(buffer)
    }

    // Sleepy — soft low tone
    func sleepy() {
        setup()
        guard let buffer = makeBuffer(duration: 0.6, generator: { _, t in
            let freq = 180 + sin(t * 2) * 20
            let envelope = sin(.pi * t / 0.6) * 0.5
            return Float(sin(2 * .pi * freq * t) * envelope * 0.15)
        }) else { return }
        playBuffer(buffer)
    }

    private func playBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isSetup else { return }
        if playerNode.isPlaying { playerNode.stop() }
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
        playerNode.play()
    }
}

// MARK: - Particle Canvas View (overlay for effects)

class ParticleCanvasView: NSView {
    var particleSystem = ParticleSystem()

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()
        particleSystem.draw(in: self)
    }

    override var isOpaque: Bool { false }
}

// MARK: - Stats HUD View

class StatsHUDView: NSView {
    var stats: PetStats = PetStats()
    var showStartTime: Date = Date()

    override func draw(_ dirtyRect: NSRect) {
        let elapsed = Date().timeIntervalSince(showStartTime)

        // RPG-style floating stat column — tiny colored pips, no background box
        let items: [(String, Double, NSColor)] = [
            ("\u{1F356}", stats.hunger, NSColor(red: 1.0, green: 0.55, blue: 0.25, alpha: 1)),
            ("\u{2764}", stats.happiness, NSColor(red: 1.0, green: 0.35, blue: 0.5, alpha: 1)),
            ("\u{26A1}", stats.energy, NSColor(red: 0.3, green: 0.75, blue: 1.0, alpha: 1)),
            ("\u{1F465}", stats.social, NSColor(red: 0.65, green: 0.4, blue: 1.0, alpha: 1)),
            ("\u{2728}", stats.hygiene, NSColor(red: 0.25, green: 0.9, blue: 0.65, alpha: 1)),
            ("\u{1F49A}", stats.health, NSColor(red: 1.0, green: 0.3, blue: 0.35, alpha: 1)),
        ]

        // Each row: [icon] [5 tiny squares] [%]
        let pipCount = 5
        let pipSize: CGFloat = 5
        let pipGap: CGFloat = 2
        let rowH: CGFloat = 11

        for (i, item) in items.enumerated() {
            let delay = Double(i) * 0.05
            let t = max(0, min(1, (elapsed - delay) / 0.1))
            guard t > 0 else { continue }

            let y = bounds.maxY - CGFloat(i + 1) * rowH
            let alpha = CGFloat(t)
            let fillT = max(0, min(1, (elapsed - delay) / 0.25))

            // Icon
            let iconAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 7),
            ]
            (item.0 as NSString).draw(at: NSPoint(x: 0, y: y - 1), withAttributes: iconAttrs)

            // Pips
            let filledPips = Int(round(item.1 / 100.0 * Double(pipCount) * fillT))
            let pipX: CGFloat = 13
            for p in 0..<pipCount {
                let px = pipX + CGFloat(p) * (pipSize + pipGap)
                let rect = NSRect(x: px, y: y + 1, width: pipSize, height: pipSize)
                if p < filledPips {
                    item.2.withAlphaComponent(0.9 * alpha).set()
                    NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
                    // Glint on top-left pixel
                    NSColor.white.withAlphaComponent(0.3 * alpha).set()
                    NSRect(x: px, y: y + 1 + pipSize - 1.5, width: 1.5, height: 1.5).fill()
                } else {
                    NSColor(white: 0.2, alpha: 0.5 * alpha).set()
                    NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
                }
            }

            // Percentage
            let pctText = "\(Int(item.1 * fillT))%" as NSString
            let pctAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont(name: "Menlo", size: 6) ?? NSFont.monospacedSystemFont(ofSize: 6, weight: .regular),
                .foregroundColor: NSColor.white.withAlphaComponent(0.5 * alpha),
            ]
            let pctX = pipX + CGFloat(pipCount) * (pipSize + pipGap) + 2
            pctText.draw(at: NSPoint(x: pctX, y: y), withAttributes: pctAttrs)
        }

        // Level — bottom
        let lvlDelay = Double(items.count) * 0.05
        let lvlT = max(0, min(1, (elapsed - lvlDelay) / 0.1))
        if lvlT > 0 {
            let alpha = CGFloat(lvlT)
            let lvlAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont(name: "Menlo-Bold", size: 7) ?? NSFont.boldSystemFont(ofSize: 7),
                .foregroundColor: NSColor(red: 1, green: 0.85, blue: 0.3, alpha: 0.8 * alpha),
            ]
            var text = "Lv.\(stats.level)"
            if stats.isSick { text += " SICK" }
            (text as NSString).draw(at: NSPoint(x: 0, y: 0), withAttributes: lvlAttrs)
        }
    }

    override var isOpaque: Bool { false }
}

// MARK: - Main App Delegate

class MurchiDelegate: NSObject, NSApplicationDelegate {
    let currentVersion = "2.1.0"

    // Windows
    var petWindow: NSPanel!
    var bubbleWindow: NSPanel!
    var particleWindow: NSPanel!
    var statsWindow: NSPanel!
    var poopWindows: [NSPanel] = []
    var foodWindow: NSPanel?
    var toyWindow: NSPanel?
    var accessoryWindow: NSPanel!
    var nightGlowWindow: NSPanel!

    // Views
    var petImageView: NSImageView!
    var bubbleLabel: NSTextField!
    var particleCanvas: ParticleCanvasView!
    var statsHUD: StatsHUDView!
    var accessoryImageView: NSImageView!
    var nightGlowView: NSView!

    // State
    var stats = PetStats.load()
    var behavior: PetBehavior = .idle {
        didSet {
            if oldValue != behavior {
                previousBehavior = oldValue
                transitionFrame = 0
            }
        }
    }
    var previousBehavior: PetBehavior = .idle
    var transitionFrame: Int = 999  // high = no transition active
    var facingRight = true
    var animFrame = 0
    var petX: CGFloat = 400
    var petY: CGFloat = 100
    var walkTargetX: CGFloat? = nil
    var isDragging = false
    var dragOffset: NSPoint = .zero
    var dragStartScreenPoint: NSPoint = .zero
    var didDragPet = false
    var lastDragPos: NSPoint = .zero
    var dragShakeCount = 0
    var lastDragDirection: CGFloat = 0
    var lastDecay = Date()
    var lastBubble = Date()
    var bubbleHideTime: Date? = nil
    var behaviorDuration: TimeInterval = 0
    var behaviorStartTime = Date()
    var jumpBaseY: CGFloat = 100
    var isHoveringPet = false
    var lastLevel = 1
    var soundEnabled = true
    var petType: String = "cat"  // "cat", "rabbit", or "bird"
    let petTypes = ["cat", "rabbit", "bird"]
    var followingCursor = false
    var lastPetOrigin = NSPoint(x: -9999, y: -9999)
    var hadParticlesLastFrame = false
    var clickCount = 0
    var lastClickTime = Date()
    var breathOffset: CGFloat = 0  // idle breathing animation
    var isGentleDropping = false
    var gentleDropPhase: CGFloat = 0

    // Toy state
    var currentToy: Toy? = nil
    var toyImageView: NSImageView?

    // Accessory
    var currentAccessory: Accessory? = nil
    var accessoryCache: [String: NSImage] = [:]

    // Night glow
    var isNightMode = false

    // Cute event system
    var butterflyWindow: NSPanel?
    var butterflyPos: NSPoint = .zero
    var butterflyFrame = 0
    var birdWindow: NSPanel?
    var birdPos: NSPoint = .zero
    var birdFlyAwaySpeed: CGFloat = 0
    var birdFlyAwayFrame: Int = 0
    var giftWindow: NSPanel?
    var giftPos: NSPoint = .zero
    var giftPhase: Int = 0  // 0=falling, 1=landed/cat walking, 2=opened
    var pawPrintWindows: [NSPanel] = []
    var pawPrintTimers: [Timer] = []
    var speechTimer: Timer?
    var behaviorTimer: Timer?
    var glassWindow: NSPanel?
    var glassVelocityY: CGFloat = 0
    var lastPawPrint = Date()
    var consecutivePetTime: TimeInterval = 0
    var lastPetTimestamp = Date()

    // Zoomies
    var zoomiesDirection: CGFloat = 1
    var zoomiesBounces = 0

    // Drag trail
    var lastDragPositions: [(CGFloat, CGFloat)] = []

    // Notifications
    var lastHungerNotification = Date.distantPast
    var lastLonelyNotification = Date.distantPast

    // Global hotkey
    var hotKeyRef: EventHotKeyRef?

    // Gravity — Dock is a platform
    let floorY: CGFloat = 5

    // Cache dock rect to avoid flickering detection
    var cachedDockRect: NSRect = .zero
    var lastDockCheck: Date = .distantPast
    var smoothGroundY: CGFloat = 5

    var dockRect: NSRect {
        // Only re-detect every 2 seconds to avoid flicker
        if Date().timeIntervalSince(lastDockCheck) < 2.0 && cachedDockRect != .zero {
            return cachedDockRect
        }
        lastDockCheck = Date()
        detectDockBarBounds()

        // Use visibleFrame to detect Dock — most reliable method
        guard let screen = NSScreen.main else {
            if cachedDockRect != .zero { return cachedDockRect }
            return .zero
        }
        let dockH = screen.visibleFrame.origin.y - screen.frame.origin.y
        if dockH > 4 {
            // Dock takes full screen width, cat can walk across it
            cachedDockRect = NSRect(x: screen.frame.minX, y: screen.frame.minY, width: screen.frame.width, height: dockH)
            return cachedDockRect
        }
        // Dock might be hidden or on the side
        if cachedDockRect != .zero { return cachedDockRect }
        return .zero
    }

    var cachedDockBarLeft: CGFloat = 0
    var cachedDockBarRight: CGFloat = 0

    func detectDockBarBounds() {
        // Use CGWindowList to find the actual Dock bar window bounds
        guard let winList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else { return }
        let screenObj = NSScreen.main
        let screenFrame = screenObj?.frame ?? NSRect(x: 0, y: 0, width: screenW, height: screenH)
        let visibleFrame = screenObj?.visibleFrame ?? screenFrame
        let expectedDockHeight = max(0, visibleFrame.origin.y - screenFrame.origin.y)
        var bestRect: CGRect?
        var bestScore = -CGFloat.greatestFiniteMagnitude

        for win in winList {
            guard let owner = win[kCGWindowOwnerName as String] as? String, owner == "Dock",
                  let bounds = win[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: bounds) else { continue }

            let normalizedRect = rect.integral
            guard normalizedRect.width > 80,
                  normalizedRect.height > 18,
                  normalizedRect.height < 260 else { continue }

            // Only consider bottom Dock windows. This avoids desktop/wallpaper-owned Dock windows.
            let bottomDistance = abs(normalizedRect.minY - screenFrame.minY)
            guard bottomDistance < max(32, expectedDockHeight + 24) else { continue }

            let heightPenalty = expectedDockHeight > 0 ? abs(normalizedRect.height - expectedDockHeight) * 2.5 : 0
            let widthPenalty: CGFloat = normalizedRect.width >= screenFrame.width - 12 ? 220 : 0
            let score = normalizedRect.width - heightPenalty - bottomDistance * 3 - widthPenalty
            if score > bestScore {
                bestScore = score
                bestRect = normalizedRect
            }
        }

        if let rect = bestRect {
            cachedDockBarLeft = rect.minX
            cachedDockBarRight = rect.maxX
        }
    }

    func currentDockBarRect() -> NSRect? {
        let dock = dockRect
        guard dock.height > 4 else { return nil }

        let detectedWidth = cachedDockBarRight - cachedDockBarLeft
        if detectedWidth > petSize {
            let left = max(0, cachedDockBarLeft)
            let right = min(screenW, cachedDockBarRight)
            if right - left > petSize {
                return NSRect(x: left, y: dock.minY, width: right - left, height: dock.height)
            }
        }

        return dock
    }

    func groundY(at originX: CGFloat, width: CGFloat) -> CGFloat {
        guard let dockBar = currentDockBarRect() else { return floorY }
        let dockLift: CGFloat = 0  // sit right on top of Dock
        let centerX = originX + width / 2

        if centerX < dockBar.minX || centerX > dockBar.maxX {
            return floorY
        }

        return dockBar.maxY + dockLift
    }

    func groundYForPet() -> CGFloat {
        groundY(at: petX, width: petSize)
    }

    func dockWalkRange(allowFallZone: Bool = false) -> ClosedRange<CGFloat> {
        guard let dockBar = currentDockBarRect() else {
            return safeRange(20, screenW - petSize - 20)
        }

        let edgeOverflow = allowFallZone ? petSize * 0.35 : 12
        let lo = max(10, dockBar.minX - edgeOverflow)
        let hi = min(screenW - petSize - 10, dockBar.maxX - petSize + edgeOverflow)
        return safeRange(lo, hi)
    }

    func nearbyEventX(offset: CGFloat, width: CGFloat) -> CGFloat {
        let baseX = petX + offset

        if groundYForPet() > floorY, let dockBar = currentDockBarRect() {
            let lo = max(10, dockBar.minX + 8)
            let hi = min(screenW - width - 10, dockBar.maxX - width - 8)
            return min(max(baseX, lo), hi)
        }

        return min(max(baseX, 10), screenW - width - 10)
    }
    var velocityY: CGFloat = 0
    var isOnGround = true
    var landingSquashTimer: Int = 0  // frames remaining in landing squash

    // Status bar
    var statusBarItem: NSStatusItem!

    // Sprite cache
    var spriteCache: [String: NSImage] = [:]

    // Screen bounds
    var screenW: CGFloat { NSScreen.main?.frame.width ?? 1440 }
    var screenH: CGFloat { NSScreen.main?.frame.height ?? 900 }

    func safeRange(_ lo: CGFloat, _ hi: CGFloat) -> ClosedRange<CGFloat> {
        let l = min(lo, hi)
        let h = max(lo, hi)
        return l == h ? l...l : l...h
    }

    let petSize: CGFloat = 80

    // MARK: - App Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        let timeSinceSeen = Date().timeIntervalSince(stats.lastSeen)
        let shouldGreet = timeSinceSeen > 3600

        stats.lastSeen = Date()
        let offlineDecay = min(timeSinceSeen, 86400)
        stats.decay(seconds: offlineDecay)
        lastLevel = stats.level

        // Start position
        petX = screenW / 2 - petSize / 2
        petY = groundYForPet()

        setupStatusBar()
        setupPetWindow()
        setupBubbleWindow()
        setupParticleWindow()
        setupStatsWindow()
        setupAccessoryWindow()
        setupNightGlowWindow()
        setupGlobalHotkey()
        requestNotificationPermission()
        updateNightMode()
        updateAccessory()
        startTimers()

        if shouldGreet {
            let awayMinutes = Int(offlineDecay / 60)
            if awayMinutes > 60 {
                stats.addMilestone("Human came back after \(awayMinutes / 60) hours! I missed them so much!")
            }
            behavior = .greeting
            behaviorStartTime = Date()
            behaviorDuration = 3.0
            SoundEngine.shared.meow()
            showBubble(SpeechBubbles.greeting(petType).randomElement()!)
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2, y: petSize),
                type: .heart, count: 10
            )
        } else if let timeMsg = SpeechBubbles.timeGreeting() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showBubble(timeMsg)
            }
        }

        // Restore poops
        for _ in 0..<stats.poopCount {
            spawnPoopWindow(at: CGFloat.random(in: safeRange(50, screenW - 80)))
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        stats.lastSeen = Date()
        stats.save()
    }

    // MARK: - Status Bar

    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.title = "=^.^="

        let menu = NSMenu()

        let headerItem = NSMenuItem(title: "Murchi - Lv.\(stats.level) \(stats.evolutionStage)", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())

        // -- Feed submenu --
        let feedMenu = NSMenu()
        let fishItem = NSMenuItem(title: "\u{1F41F} Fish", action: #selector(feedPet), keyEquivalent: "f")
        fishItem.target = self
        feedMenu.addItem(fishItem)
        let milkItem = NSMenuItem(title: "\u{1F95B} Milk", action: #selector(feedMilkAction), keyEquivalent: "")
        milkItem.target = self
        feedMenu.addItem(milkItem)
        let treatItem = NSMenuItem(title: "\u{1F36A} Treat", action: #selector(feedTreatAction), keyEquivalent: "")
        treatItem.target = self
        feedMenu.addItem(treatItem)
        let feedMenuItem = NSMenuItem(title: "\u{1F356} Feed", action: nil, keyEquivalent: "")
        feedMenuItem.submenu = feedMenu
        menu.addItem(feedMenuItem)

        let playItem = NSMenuItem(title: "\u{1F3AE} Play", action: #selector(playWithPet), keyEquivalent: "p")
        playItem.target = self
        menu.addItem(playItem)

        let restItem = NSMenuItem(title: "\u{1F634} Rest", action: #selector(restPet), keyEquivalent: "r")
        restItem.target = self
        menu.addItem(restItem)

        let bathItem = NSMenuItem(title: "\u{1F6C1} Bath", action: #selector(bathePet), keyEquivalent: "b")
        bathItem.target = self
        menu.addItem(bathItem)

        let cleanItem = NSMenuItem(title: "\u{1F9F9} Clean Poop (\(stats.poopCount))", action: #selector(cleanPoopAction), keyEquivalent: "c")
        cleanItem.target = self
        menu.addItem(cleanItem)

        let healItem = NSMenuItem(title: "\u{1F48A} Medicine", action: #selector(healPet), keyEquivalent: "m")
        healItem.target = self
        healItem.isEnabled = stats.isSick
        menu.addItem(healItem)

        let walkItem = NSMenuItem(title: "\u{1F6B6} Walk", action: #selector(takeForWalk), keyEquivalent: "w")
        walkItem.target = self
        menu.addItem(walkItem)

        menu.addItem(NSMenuItem.separator())

        // -- Toys submenu --
        let toyMenu = NSMenu()
        let mouseItem = NSMenuItem(title: "\u{1F401} Mouse Toy", action: #selector(spawnMouseToy), keyEquivalent: "")
        mouseItem.target = self
        toyMenu.addItem(mouseItem)
        let yarnItem = NSMenuItem(title: "\u{1F9F6} Yarn Ball", action: #selector(spawnYarnBall), keyEquivalent: "")
        yarnItem.target = self
        toyMenu.addItem(yarnItem)
        let laserItem = NSMenuItem(title: "\u{1F534} Laser Dot", action: #selector(spawnLaserDot), keyEquivalent: "")
        laserItem.target = self
        toyMenu.addItem(laserItem)
        let toyMenuItem = NSMenuItem(title: "\u{1F9F8} Toys", action: nil, keyEquivalent: "t")
        toyMenuItem.submenu = toyMenu
        menu.addItem(toyMenuItem)

        // -- Accessories submenu --
        let accessoryMenu = NSMenu()
        let noneItem = NSMenuItem(title: "None", action: #selector(removeAccessory), keyEquivalent: "")
        noneItem.target = self
        accessoryMenu.addItem(noneItem)
        for acc in Accessory.available(for: stats.level) {
            let item = NSMenuItem(title: acc.name, action: #selector(equipAccessoryByName(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = acc.name
            accessoryMenu.addItem(item)
        }
        let accessoryMenuItem = NSMenuItem(title: "\u{1F451} Accessories", action: nil, keyEquivalent: "")
        accessoryMenuItem.submenu = accessoryMenu
        menu.addItem(accessoryMenuItem)

        menu.addItem(NSMenuItem.separator())

        let summonItem = NSMenuItem(title: "\u{2728} Summon (Cmd+Shift+M)", action: #selector(summonPet), keyEquivalent: "")
        summonItem.target = self
        menu.addItem(summonItem)

        let statsItem = NSMenuItem(title: "\u{1F4CA} Stats", action: #selector(showStats), keyEquivalent: "s")
        statsItem.target = self
        menu.addItem(statsItem)

        let cameraItem = NSMenuItem(title: "\u{1F4F7} Screenshot", action: #selector(screenshotPet), keyEquivalent: "")
        cameraItem.target = self
        menu.addItem(cameraItem)

        let diaryItem = NSMenuItem(title: "\u{1F4D3} Diary", action: #selector(showDiary), keyEquivalent: "d")
        diaryItem.target = self
        menu.addItem(diaryItem)

        menu.addItem(NSMenuItem.separator())

        let websiteItem = NSMenuItem(title: "murchi.pet", action: #selector(openWebsite), keyEquivalent: "")
        websiteItem.target = self
        menu.addItem(websiteItem)

        let updateItem = NSMenuItem(title: "\u{1F504} Check for Updates", action: #selector(checkForUpdates), keyEquivalent: "u")
        updateItem.target = self
        menu.addItem(updateItem)

        let aboutItem = NSMenuItem(title: "About Murchi", action: nil, keyEquivalent: "")
        aboutItem.attributedTitle = NSAttributedString(
            string: "Murchi v\(currentVersion) \u{00A9} 2026 murchi.pet",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]
        )
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let petMenu = NSMenu()
        let catItem = NSMenuItem(title: "🐱 Cat", action: nil, keyEquivalent: "")
        catItem.state = .on
        petMenu.addItem(catItem)
        let comingSoon = NSMenuItem(title: "🐰🐦 More pets coming soon!", action: nil, keyEquivalent: "")
        comingSoon.isEnabled = false
        petMenu.addItem(comingSoon)
        let petMenuItem = NSMenuItem(title: "🐾 Pet's", action: nil, keyEquivalent: "")
        petMenuItem.submenu = petMenu
        menu.addItem(petMenuItem)

        let soundItem = NSMenuItem(title: soundEnabled ? "\u{1F508} Mute Sounds" : "\u{1F50A} Enable Sounds", action: #selector(toggleSound), keyEquivalent: "")
        menu.addItem(soundItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusBarItem.menu = menu
    }

    // MARK: - Windows

    func setupPetWindow() {
        let frame = NSRect(x: petX, y: petY, width: petSize, height: petSize)
        petWindow = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        petWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        petWindow.backgroundColor = .clear
        petWindow.isOpaque = false
        petWindow.hasShadow = false
        petWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        petWindow.ignoresMouseEvents = false

        petImageView = NSImageView(frame: NSRect(x: 0, y: 0, width: petSize, height: petSize))
        petImageView.imageScaling = .scaleProportionallyUpOrDown
        petImageView.image = getSprite(for: .idle, frame: 0, right: true)

        let container = PetView(frame: NSRect(x: 0, y: 0, width: petSize, height: petSize))
        container.delegate = self
        container.addSubview(petImageView)
        petWindow.contentView = container
        petWindow.orderFront(nil)
    }

    func setupBubbleWindow() {
        let frame = NSRect(x: petX, y: petY + petSize + 5, width: 200, height: 40)
        bubbleWindow = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        bubbleWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        bubbleWindow.backgroundColor = .clear
        bubbleWindow.isOpaque = false
        bubbleWindow.hasShadow = false
        bubbleWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        bubbleWindow.ignoresMouseEvents = true

        let bgView = BubbleView(frame: NSRect(x: 0, y: 0, width: 200, height: 40))

        bubbleLabel = NSTextField(frame: NSRect(x: 12, y: 6, width: 176, height: 28))
        bubbleLabel.isEditable = false
        bubbleLabel.isBordered = false
        bubbleLabel.backgroundColor = .clear
        bubbleLabel.alignment = .center
        bubbleLabel.font = NSFont(name: "Menlo-Bold", size: 12) ?? NSFont.systemFont(ofSize: 12, weight: .bold)
        bubbleLabel.textColor = NSColor(white: 0.15, alpha: 1.0)
        bubbleLabel.stringValue = ""

        bgView.addSubview(bubbleLabel)
        bubbleWindow.contentView = bgView
        bubbleWindow.orderOut(nil)
    }

    func setupParticleWindow() {
        let frame = NSRect(x: petX - 40, y: petY - 20, width: petSize + 80, height: petSize + 60)
        particleWindow = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        particleWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        particleWindow.backgroundColor = .clear
        particleWindow.isOpaque = false
        particleWindow.hasShadow = false
        particleWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        particleWindow.ignoresMouseEvents = true

        particleCanvas = ParticleCanvasView(frame: NSRect(x: 0, y: 0, width: frame.width, height: frame.height))
        particleWindow.contentView = particleCanvas
        particleWindow.orderFront(nil)
    }

    func setupStatsWindow() {
        let w: CGFloat = 80
        let h: CGFloat = 78
        let frame = NSRect(x: petX, y: petY + petSize + 6, width: w, height: h)
        statsWindow = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        statsWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        statsWindow.backgroundColor = .clear
        statsWindow.isOpaque = false
        statsWindow.hasShadow = false
        statsWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        statsWindow.ignoresMouseEvents = true

        statsHUD = StatsHUDView(frame: NSRect(x: 0, y: 0, width: 80, height: 78))
        statsHUD.stats = stats
        statsWindow.contentView = statsHUD
        statsWindow.orderOut(nil) // hidden by default
    }

    func setupAccessoryWindow() {
        let frame = NSRect(x: petX, y: petY, width: petSize, height: petSize)
        accessoryWindow = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        accessoryWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        accessoryWindow.backgroundColor = .clear
        accessoryWindow.isOpaque = false
        accessoryWindow.hasShadow = false
        accessoryWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        accessoryWindow.ignoresMouseEvents = true

        accessoryImageView = NSImageView(frame: NSRect(x: 0, y: 0, width: petSize, height: petSize))
        accessoryImageView.imageScaling = .scaleAxesIndependently
        accessoryWindow.contentView = accessoryImageView
        accessoryWindow.orderOut(nil)
    }

    func setupNightGlowWindow() {
        // Night glow disabled — kept as no-op for compatibility
        let frame = NSRect(x: 0, y: 0, width: 1, height: 1)
        nightGlowWindow = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                                   backing: .buffered, defer: false)
        nightGlowWindow.orderOut(nil)
        nightGlowView = NSView(frame: frame)
    }

    func setupGlobalHotkey() {
        // Cmd+Shift+M to summon Murchi to cursor
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4D524348) // "MRCH"
        hotKeyID.id = 1

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return noErr }
            let delegate = Unmanaged<MurchiDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                delegate.summonPet()
            }
            return noErr
        }

        var eventHandler: EventHandlerRef?
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        // Cmd+Shift+M = keycode 46 (M)
        RegisterEventHotKey(UInt32(kVK_ANSI_M), UInt32(cmdKey | shiftKey), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    private var canUseNotifications: Bool {
        return Bundle.main.bundleIdentifier != nil
    }

    func requestNotificationPermission() {
        guard canUseNotifications else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendNotification(title: String, body: String) {
        guard canUseNotifications else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func updateNightMode() {
        let hour = Calendar.current.component(.hour, from: Date())
        let shouldBeNight = hour >= 21 || hour < 6
        if shouldBeNight != isNightMode {
            isNightMode = shouldBeNight
            if isNightMode {
                nightGlowWindow.orderFront(nil)
            } else {
                nightGlowWindow.orderOut(nil)
            }
        }
    }

    func updateAccessory() {
        guard let acc = currentAccessory else {
            accessoryWindow.orderOut(nil)
            return
        }
        let key = acc.name
        if accessoryCache[key] == nil {
            if acc.vectorDraw != nil {
                accessoryCache[key] = KawaiiItems.renderAccessory(acc, size: petSize)
            } else {
                accessoryCache[key] = Sprites.render(acc.sprite)
            }
        }
        accessoryImageView.image = accessoryCache[key]
        accessoryWindow.setFrameOrigin(currentDisplayOrigin())
        accessoryWindow.orderFront(nil)
    }

    func dismissLaserDotIfNeeded() {
        guard currentToy?.type == .laserDot else { return }
        removeToy()
        if behavior == .chasingToy {
            startBehavior(.idle, duration: 0.4)
        }
    }

    func currentDisplayOrigin() -> NSPoint {
        var displayX = petX
        let displayY = petY + breathOffset

        if behavior == .beingPet {
            displayX += CGFloat(sin(Double(frameCounter) * 0.5) * 2)
        }
        if isGentleDropping {
            displayX += CGFloat(sin(Double(gentleDropPhase)) * 3)
        }

        return NSPoint(x: displayX.rounded(), y: displayY.rounded())
    }

    @objc func openWebsite() {
        NSWorkspace.shared.open(URL(string: "https://murchi.pet")!)
    }

    @objc func checkForUpdates() {
        let urlString = "https://api.github.com/repos/egorfedorov/murchi/releases/latest"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    let alert = NSAlert()
                    alert.messageText = "Update Check Failed"
                    alert.informativeText = "Could not connect to GitHub: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    return
                }
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    let alert = NSAlert()
                    alert.messageText = "Update Check Failed"
                    alert.informativeText = "Could not parse the update information."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    return
                }
                let remoteVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                if self.isVersion(remoteVersion, newerThan: self.currentVersion) {
                    let alert = NSAlert()
                    alert.messageText = "Update Available!"
                    alert.informativeText = "Version \(remoteVersion) is available. You are running v\(self.currentVersion). Would you like to download it?"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "Download")
                    alert.addButton(withTitle: "Later")
                    if alert.runModal() == .alertFirstButtonReturn {
                        if let assets = json["assets"] as? [[String: Any]] {
                            for asset in assets {
                                if let name = asset["name"] as? String, name.hasSuffix(".dmg"),
                                   let downloadUrl = asset["browser_download_url"] as? String,
                                   let dlURL = URL(string: downloadUrl) {
                                    NSWorkspace.shared.open(dlURL)
                                    return
                                }
                            }
                        }
                        if let htmlUrl = json["html_url"] as? String, let pageURL = URL(string: htmlUrl) {
                            NSWorkspace.shared.open(pageURL)
                        }
                    }
                } else {
                    let alert = NSAlert()
                    alert.messageText = "You're up to date!"
                    alert.informativeText = "Murchi v\(self.currentVersion) is the latest version."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }.resume()
    }

    private func isVersion(_ a: String, newerThan b: String) -> Bool {
        let partsA = a.split(separator: ".").compactMap { Int($0) }
        let partsB = b.split(separator: ".").compactMap { Int($0) }
        let count = max(partsA.count, partsB.count)
        for i in 0..<count {
            let va = i < partsA.count ? partsA[i] : 0
            let vb = i < partsB.count ? partsB[i] : 0
            if va > vb { return true }
            if va < vb { return false }
        }
        return false
    }

    @objc func summonPet() {
        let mouse = NSEvent.mouseLocation
        petX = mouse.x - petSize / 2
        petY = mouse.y - petSize / 2
        velocityY = 5  // little bounce on arrival
        isOnGround = false
        showBubble("I'm here!")
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
            type: .poof, count: 8
        )
        NSSound(named: "Pop")?.play()
    }

    @objc func spawnMouseToy() {
        spawnToy(.mouseToy)
    }

    @objc func spawnYarnBall() {
        spawnToy(.yarnBall)
    }

    @objc func spawnLaserDot() {
        spawnToy(.laserDot)
    }

    func spawnToy(_ type: Toy.ToyType) {
        let tx = petX + (facingRight ? 150 : -150)
        let ty = groundYForPet()
        currentToy = Toy(x: tx, y: ty, type: type)

        let toySize: CGFloat = 30
        if toyWindow == nil {
            let frame = NSRect(x: tx, y: ty, width: toySize, height: toySize)
            toyWindow = NSPanel(
                contentRect: frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            toyWindow!.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
            toyWindow!.backgroundColor = .clear
            toyWindow!.isOpaque = false
            toyWindow!.hasShadow = false
            toyWindow!.collectionBehavior = [.canJoinAllSpaces, .stationary]
            toyWindow!.ignoresMouseEvents = true

            toyImageView = NSImageView(frame: NSRect(x: 0, y: 0, width: toySize, height: toySize))
            toyImageView!.imageScaling = .scaleProportionallyUpOrDown
            toyWindow!.contentView = toyImageView
        }

        // Draw toy using vector kawaii items
        let toyImg: NSImage
        switch type {
        case .mouseToy:
            toyImg = KawaiiItems.mouseToy()
        case .yarnBall:
            toyImg = KawaiiItems.yarnBall()
        case .laserDot:
            toyImg = KawaiiItems.laserDot()
        }
        toyImageView?.image = toyImg

        toyWindow!.setFrameOrigin(NSPoint(x: tx, y: ty))
        toyWindow!.orderFront(nil)

        startBehavior(.chasingToy, duration: 8.0)
        showBubble(SpeechBubbles.chasingToy(petType).randomElement()!)
        stats.play()
        stats.save()
    }

    func removeToy() {
        currentToy = nil
        toyWindow?.orderOut(nil)
    }

    @objc func removeAccessory() {
        currentAccessory = nil
        stats.accessory = nil
        stats.save()
        accessoryWindow.orderOut(nil)
    }

    @objc func equipAccessoryByName(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String,
              let acc = Accessory.all.first(where: { $0.name == name }) else { return }
        currentAccessory = acc
        stats.accessory = name
        stats.save()
        updateAccessory()
        showBubble(SpeechBubbles.accessoryReaction.randomElement()!)
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
            type: .sparkle, count: 6
        )
    }

    func spawnPoopWindow(at x: CGFloat) {
        let poopSize: CGFloat = 40
        let frame = NSRect(x: x, y: groundYForPet(), width: poopSize, height: poopSize)
        let poopWin = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        poopWin.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        poopWin.backgroundColor = .clear
        poopWin.isOpaque = false
        poopWin.hasShadow = false
        poopWin.collectionBehavior = [.canJoinAllSpaces, .stationary]
        poopWin.ignoresMouseEvents = true

        let img = Sprites.render(Sprites.poop, scale: 3)
        let iv = NSImageView(frame: NSRect(x: 0, y: 0, width: poopSize, height: poopSize))
        iv.image = img
        iv.imageScaling = .scaleProportionallyUpOrDown
        poopWin.contentView = iv
        poopWin.orderFront(nil)
        poopWindows.append(poopWin)
    }

    // MARK: - Bubble

    func showBubble(_ text: String) {
        bubbleLabel.stringValue = text

        let attrs: [NSAttributedString.Key: Any] = [.font: bubbleLabel.font!]
        let size = (text as NSString).size(withAttributes: attrs)
        let bubbleW = max(90, size.width + 34)
        let bubbleH: CGFloat = 38

        let x = petX + petSize / 2 - bubbleW / 2
        let y = petY + petSize + 10
        bubbleWindow.setFrame(NSRect(x: x, y: y, width: bubbleW, height: bubbleH), display: true)
        bubbleWindow.contentView?.frame = NSRect(x: 0, y: 0, width: bubbleW, height: bubbleH)
        bubbleLabel.frame = NSRect(x: 12, y: 6, width: bubbleW - 24, height: bubbleH - 10)
        bubbleWindow.contentView?.needsDisplay = true

        bubbleWindow.orderFront(nil)
        bubbleHideTime = Date().addingTimeInterval(3.5)
        lastBubble = Date()
    }

    // MARK: - Sprites

    func getSprite(for behavior: PetBehavior, frame: Int, right: Bool) -> NSImage {
        return CatRenderer.shared.getSprite(for: behavior, frame: frame, right: right)
    }

    // MARK: - Timers

    func startTimers() {
        // Main update loop — 30fps for smooth animation
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.update()
        }

        // Stats decay — every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            let elapsed = now.timeIntervalSince(self.lastDecay)
            let oldPoopCount = self.stats.poopCount
            self.stats.decay(seconds: elapsed)
            self.lastDecay = now

            // Check for new poop
            if self.stats.poopCount > oldPoopCount {
                let newPoops = self.stats.poopCount - oldPoopCount
                for _ in 0..<newPoops {
                    self.spawnPoopWindow(at: self.petX + CGFloat.random(in: -40...40))
                    self.showBubble(SpeechBubbles.poop.randomElement()!)
                }
            }

            // Check for level up
            if self.stats.level > self.lastLevel {
                self.lastLevel = self.stats.level
                self.showBubble(SpeechBubbles.levelUp.randomElement()!)
                SoundEngine.shared.pop()
                self.particleCanvas.particleSystem.emit(
                    at: NSPoint(x: self.petSize / 2 + 40, y: self.petSize + 20),
                    type: .star, count: 15
                )
                self.stats.addMilestone("Reached level \(self.stats.level) — \(self.stats.evolutionStage)!")
                self.stats.save()
            }

            // Dirty notification
            if self.stats.hygiene < 20 && Bool.random() {
                self.showBubble(SpeechBubbles.dirty.randomElement()!)
            }

            // Auto-diary entries for important events
            if self.stats.isSick && self.stats.sickSince != nil {
                let sickDuration = Date().timeIntervalSince(self.stats.sickSince!)
                if sickDuration < 35 {  // just got sick
                    self.stats.addMilestone("Got sick... feeling terrible")
                }
            }
            if self.stats.hunger < 10 {
                self.stats.addMilestone("Starving! Human hasn't fed me... hunger at \(Int(self.stats.hunger))%")
            }
            if self.stats.happiness < 10 {
                self.stats.addMilestone("Very sad today... nobody plays with me")
            }
            if self.stats.hygiene < 10 {
                self.stats.addMilestone("I'm so dirty... please give me a bath")
            }

            // macOS notifications when stats are critical
            if self.stats.hunger < 15 && Date().timeIntervalSince(self.lastHungerNotification) > 600 {
                self.lastHungerNotification = Date()
                self.sendNotification(title: "Murchi is STARVING!", body: "Please feed your cat! Hunger: \(Int(self.stats.hunger))%")
            }
            if self.stats.social < 15 && Date().timeIntervalSince(self.lastLonelyNotification) > 600 {
                self.lastLonelyNotification = Date()
                self.sendNotification(title: "Murchi is lonely...", body: "Your cat misses you! Come play!")
            }

            self.stats.save()
            self.updateStatusBar()
        }

        scheduleRandomSpeech()
        scheduleRandomBehavior()
    }

    func scheduleRandomSpeech() {
        speechTimer?.invalidate()
        let delay = TimeInterval.random(in: 25...70)
        speechTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.behavior != .sleeping && self.behavior != .lonelySitting && self.behavior != .dead {
                let msgs = SpeechBubbles.forMood(self.stats.mood, pet: self.petType)
                if let msg = msgs.randomElement() {
                    self.showBubble(msg)
                }
            }
            self.scheduleRandomSpeech()
        }
    }

    func scheduleRandomBehavior() {
        behaviorTimer?.invalidate()
        let delay = TimeInterval.random(in: 4...12)
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.stats.isDead { /* dead pet doesn't pick new behaviors */ }
            else if self.followingCursor { /* skip random behavior while following */ }
            else if !self.isDragging && self.behavior != .eating && self.behavior != .beingPet && self.behavior != .pooping && self.behavior != .chasingToy {
                self.pickRandomBehavior()
            }
            self.scheduleRandomBehavior()
        }
    }

    func pickRandomBehavior() {
        // Dead pet stays dead
        if stats.isDead {
            if behavior != .dead {
                startBehavior(.dead, duration: 999999)
                showBubble("...")
            }
            return
        }

        let mood = stats.mood
        let hour = Calendar.current.component(.hour, from: Date())

        // Late night override
        if (hour >= 23 || hour < 6) && stats.energy < 40 {
            startBehavior(.sleeping, duration: .random(in: 10...30))
            return
        }

        // Hygiene events
        if stats.hygiene > 60 && Double.random(in: 0...1) < 0.15 {
            startBehavior(.grooming, duration: .random(in: 3...6))
            showBubble(SpeechBubbles.grooming(petType).randomElement()!)
            return
        }

        var options: [(PetBehavior, Double)]
        switch mood {
        case .happy:
            options = [
                (.walking, 16), (.sitting, 8), (.idle, 6),
                (.lookingAtCursor, 8), (.jumping, 7),
                (.stretching, 4), (.chasingCursor, 7), (.playing, 7),
                (.running, 5), (.grooming, 4), (.tripping, 2),
                (.zoomies, 5), (.scratching, 4), (.promenade, 5), (.celebrating, 3),
            ]
            // Birds can fly!
            if petType == "bird" {
                options.append((.flying, 10))
            }
        case .neutral:
            options = [
                (.walking, 18), (.sitting, 22), (.idle, 18),
                (.lookingAtCursor, 12), (.stretching, 10),
                (.sleeping, 5), (.grooming, 8), (.tripping, 4), (.running, 3),
                (.lonelySitting, 8),
            ]
            if petType == "bird" {
                options.append((.flying, 6))
            }
        case .sad:
            options = [
                (.sitting, 20), (.idle, 15), (.sleeping, 18),
                (.walking, 8), (.lookingAtCursor, 8), (.tripping, 5), (.grooming, 3), (.crying, 8),
                (.lonelySitting, 25),
            ]
        case .sleepy:
            options = [
                (.sleeping, 45), (.sitting, 20), (.idle, 15),
                (.stretching, 10), (.walking, 5), (.grooming, 5),
            ]
        case .sick:
            options = [
                (.sick, 40), (.sitting, 25), (.idle, 20),
                (.sleeping, 10), (.walking, 5),
            ]
        }

        let total = options.reduce(0.0) { $0 + $1.1 }
        var roll = Double.random(in: 0..<total)
        for (b, w) in options {
            roll -= w
            if roll <= 0 {
                let dur: TimeInterval
                switch b {
                case .walking, .edgeWalking: dur = .random(in: 3...8)
                case .running, .chasingCursor: dur = .random(in: 2...5)
                case .zoomies: dur = .random(in: 2...4)
                case .scratching: dur = .random(in: 2...4)
                case .sitting, .idle: dur = .random(in: 4...12)
                case .sleeping: dur = .random(in: 8...25)
                case .jumping: dur = 2.5
                case .flying: dur = .random(in: 3...7)
                case .stretching: dur = 2.5
                case .tripping: dur = 2.5
                case .lookingAtCursor: dur = .random(in: 2...6)
                case .playing: dur = .random(in: 3...6)
                case .grooming: dur = .random(in: 3...6)
                case .celebrating: dur = .random(in: 3...5)
                case .crying: dur = .random(in: 4...8)
                case .lonelySitting: dur = .random(in: 8...20)
                default: dur = 3.0
                }
                startBehavior(b, duration: dur)
                return
            }
        }
    }

    func startBehavior(_ b: PetBehavior, duration: TimeInterval) {
        behavior = b
        behaviorStartTime = Date()
        behaviorDuration = duration
        animFrame = 0

        switch b {
        case .walking:
            // ~15% chance to walk to screen edge (triggers clinging)
            if isOnGround && groundYForPet() <= floorY + 5 && Double.random(in: 0...1) < 0.15 {
                walkTargetX = Bool.random() ? 0 : screenW - petSize
            } else {
                walkTargetX = CGFloat.random(in: dockWalkRange(allowFallZone: groundYForPet() > floorY))
            }
            facingRight = (walkTargetX ?? petX) > petX
        case .running:
            walkTargetX = CGFloat.random(in: dockWalkRange(allowFallZone: groundYForPet() > floorY))
            facingRight = (walkTargetX ?? petX) > petX
        case .chasingCursor:
            facingRight = NSEvent.mouseLocation.x > petX
        case .jumping:
            jumpBaseY = petY
            velocityY = 10
            isOnGround = false
        case .tripping:
            showBubble("Oops!")
        case .playing:
            if Int.random(in: 0...2) == 0 {
                showBubble(SpeechBubbles.playing(petType).randomElement()!)
            }
        case .zoomies:
            zoomiesDirection = Bool.random() ? 1 : -1
            zoomiesBounces = 0
            facingRight = zoomiesDirection > 0
            showBubble(SpeechBubbles.zoomies(petType).randomElement()!)
        case .scratching:
            showBubble(SpeechBubbles.scratching(petType).randomElement()!)
        case .flying:
            // Bird takes off! Launch upward and set a horizontal target
            jumpBaseY = petY
            velocityY = 6
            isOnGround = false
            walkTargetX = CGFloat.random(in: safeRange(100, screenW - 100))
            facingRight = (walkTargetX ?? petX) > petX
            showBubble(["Wheee!", "Up up!", "Freedom!", "Tweet tweet!"].randomElement()!)
        case .edgeWalking:
            // Walk along top of screen
            petY = screenH - petSize - 25  // menu bar area
            walkTargetX = CGFloat.random(in: safeRange(100, screenW - 100))
            facingRight = (walkTargetX ?? petX) > petX
        default:
            break
        }
    }

    // MARK: - Main Update

    var frameCounter = 0

    func update() {
        frameCounter += 1

        // Hide bubble
        if let hideTime = bubbleHideTime, Date() > hideTime {
            bubbleWindow.orderOut(nil)
            bubbleHideTime = nil
        }

        // Clean up stale event windows (safety net)
        if behavior != .openingGift, let gw = giftWindow, gw.isVisible {
            gw.orderOut(nil)
        }
        if behavior != .chasingButterfly, let bw = butterflyWindow, bw.isVisible {
            bw.orderOut(nil)
        }
        if behavior != .knockingGlass, let gw = glassWindow, gw.isVisible {
            gw.orderOut(nil)
        }

        // Lonely sitting → crying transition
        if behavior == .lonelySitting {
            let lonelyElapsed = Date().timeIntervalSince(behaviorStartTime)
            if lonelyElapsed > 15 && stats.mood == .sad {
                startBehavior(.crying, duration: .random(in: 4...8))
                showBubble(["*sniff*", "...", "Nobody loves me...", "*sobs*"].randomElement()!)
            }
        }

        // Death check
        if stats.isDead && behavior != .dead {
            startBehavior(.dead, duration: 999999)
            showBubble("💀")
            sendNotification(title: "\(stats.name) has died!", body: "Give medicine to revive your pet.")
        }

        // Behavior timeout
        let elapsed = Date().timeIntervalSince(behaviorStartTime)
        if followingCursor && behavior == .chasingCursor {
            // Keep following — don't timeout
        } else if elapsed > behaviorDuration && !isDragging && behavior != .idle {
            // Clean up event windows on behavior timeout
            if behavior == .openingGift, let gw = giftWindow, gw.isVisible {
                gw.orderOut(nil)
            }
            if behavior == .chasingButterfly, let bw = butterflyWindow, bw.isVisible {
                bw.orderOut(nil)
            }
            if behavior == .watchingBird, let bw = birdWindow, bw.isVisible {
                bw.orderOut(nil)
            }
            if behavior == .knockingGlass, let gw = glassWindow, gw.isVisible {
                gw.orderOut(nil)
            }
            // Wake-up stretch after sleeping
            if behavior == .sleeping {
                let wakeBubbles = ["*yaaawn* Good nap!", "*stretch stretch*", "Mmm... more sleep?", "*blinks sleepily*"]
                showBubble(wakeBubbles.randomElement()!)
                startBehavior(.stretching, duration: 2.5)
                return  // skip the idle reset below
            }
            // Satisfaction after eating
            if behavior == .eating {
                let satBubbles = ["Yummy!", "*burp*", "*licks lips*", "That was good!", "More?"]
                showBubble(satBubbles.randomElement()!)
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                    type: .heart, count: 3
                )
            }
            // When climbing times out, cat jumps off wall
            if behavior == .clingingEdge {
                showBubble(["*jumps!*", "Weee!", "Whoa!"].randomElement()!)
                behavior = .jumping
                behaviorStartTime = Date()
                behaviorDuration = 3.0
                jumpBaseY = groundYForPet()
                if facingRight {
                    petX = screenW - petSize - 25
                    facingRight = false
                } else {
                    petX = 25
                    facingRight = true
                }
                velocityY = 4
                isOnGround = false
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                    type: .star, count: 5
                )
                return  // skip the idle reset below
            }
            behavior = .idle
            animFrame = 0
        }

        // Animate every 2nd frame (15fps sprite animation at 30fps loop = 2x smoother than before)
        if frameCounter % 2 == 0 {
            animFrame += 1
            transitionFrame += 1
        }

        // Behavior-specific particles
        if frameCounter % 10 == 0 {
            let midX = petSize / 2
            let topY = petSize + 5
            switch behavior {
            case .crying:
                particleCanvas.particleSystem.emit(at: NSPoint(x: midX - 15, y: topY - 20), type: .tear, count: 1)
                particleCanvas.particleSystem.emit(at: NSPoint(x: midX + 15, y: topY - 20), type: .tear, count: 1)
            case .sleeping:
                particleCanvas.particleSystem.emit(at: NSPoint(x: midX + 25, y: topY + 5), type: .zzz, count: 1)
                if frameCounter % 30 == 0 {
                    particleCanvas.particleSystem.emit(at: NSPoint(x: midX + CGFloat.random(in: -10...20), y: topY + 10), type: .dream, count: 1)
                }
            case .celebrating:
                particleCanvas.particleSystem.emit(at: NSPoint(x: midX, y: topY + 10), type: .confetti, count: 3)
            case .dead:
                if frameCounter % 30 == 0 {
                    particleCanvas.particleSystem.emit(at: NSPoint(x: midX, y: topY), type: .poof, count: 2)
                }
            default: break
            }
        }

        // Ambient fireflies at night
        if isNightMode && frameCounter % 20 == 0 {
            let fx = CGFloat.random(in: 0...petSize + 60)
            let fy = CGFloat.random(in: 0...petSize + 40)
            particleCanvas.particleSystem.emit(at: NSPoint(x: fx, y: fy), type: .firefly, count: 1)
        }

        // Physics — gravity with Dock as platform (skip when stable on ground)
        let currentGround = groundYForPet()
        let needsPhysics = !isDragging && behavior != .sleeping && behavior != .edgeWalking && behavior != .flying && behavior != .clingingEdge
            && !(isOnGround && velocityY == 0 && abs(petY - currentGround) <= 2 && !isGentleDropping && behavior != .jumping)
        if needsPhysics {
            if isGentleDropping && petY > currentGround + 2 {
                gentleDropPhase += 0.35
                let distance = petY - currentGround
                let descent = min(3.0, max(1.2, distance * 0.045))
                petY -= descent
                if petY <= currentGround {
                    petY = currentGround
                    velocityY = 0
                    isOnGround = true
                    isGentleDropping = false
                    gentleDropPhase = 0
                    restoreSquareWindow()
                }
            } else if petY > currentGround + 2 {
                // Falling
                velocityY -= 0.8
                petY += velocityY
                if petY <= currentGround {
                    petY = currentGround
                    let impactSpeed = abs(velocityY)
                    velocityY = 0
                    isOnGround = true
                    isGentleDropping = false
                    gentleDropPhase = 0
                    restoreSquareWindow()
                    // Landing squash effect for big falls
                    if impactSpeed > 5 {
                        landingSquashTimer = 8
                    }
                }
            } else if petY < currentGround - 2 && isOnGround {
                // Ground rose (e.g. walked onto Dock) — snap up smoothly
                petY = currentGround
            } else if abs(petY - currentGround) <= 2 {
                // Close enough — land
                if !isOnGround {
                    petY = currentGround
                    velocityY = 0
                    isOnGround = true
                    isGentleDropping = false
                    gentleDropPhase = 0
                    restoreSquareWindow()
                }
            }
        }

        // Movement
        switch behavior {
        case .walking:
            if let target = walkTargetX {
                let speed: CGFloat = stats.mood == .happy ? 1.2 : 0.7
                if abs(petX - target) < speed * 2 {
                    petX = target
                    walkTargetX = nil
                    behavior = .idle
                } else {
                    petX += (target > petX) ? speed : -speed
                    facingRight = target > petX
                }
            }
        case .running:
            if let target = walkTargetX {
                let speed: CGFloat = 3.0
                if abs(petX - target) < speed * 2 {
                    petX = target
                    walkTargetX = nil
                    behavior = .idle
                } else {
                    petX += (target > petX) ? speed : -speed
                    facingRight = target > petX
                }
            }
        case .chasingCursor:
            let mousePos = NSEvent.mouseLocation
            let speed: CGFloat = 2.5
            let dx = mousePos.x - (petX + petSize / 2)
            if abs(dx) > petSize * 0.8 {
                petX += dx > 0 ? speed : -speed
                facingRight = dx > 0
            }
        case .jumping:
            velocityY -= 0.6
            petY += velocityY
            if petY <= jumpBaseY && velocityY < 0 {
                petY = jumpBaseY
                velocityY = 0
                isOnGround = true
                // Landing impact particles
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: petSize / 2 + 20, y: 5),
                    type: .poof, count: 3
                )
                if elapsed > behaviorDuration * 0.7 {
                    showBubble(["*thud*", "Landed!", "Nailed it!", "Ta-da!"].randomElement()!)
                    behavior = .idle
                } else {
                    // Bounce again (smaller each time)
                    let remaining = 1.0 - elapsed / behaviorDuration
                    velocityY = CGFloat(remaining * 8 + 3)
                    isOnGround = false
                }
            }
        case .flying:
            // Bird flies in a gentle arc toward the target
            let flyHeight: CGFloat = 120  // how high above ground
            let targetY = jumpBaseY + flyHeight
            // Hover with gentle sine wave
            let hoverY = targetY + sin(CGFloat(frameCounter) * 0.12) * 8
            // Smoothly approach hover height
            if petY < hoverY - 2 {
                petY += 2.5
            } else if petY > hoverY + 2 {
                petY -= 1.5
            }
            // Move horizontally toward target
            if let target = walkTargetX {
                let speed: CGFloat = 2.0
                if abs(petX - target) < speed * 2 {
                    // Reached target — pick new one or land
                    if elapsed > behaviorDuration * 0.7 {
                        // Start descending to land
                        velocityY = -1
                        isOnGround = false
                        behavior = .jumping  // reuse jump landing logic
                        jumpBaseY = groundYForPet()
                    } else {
                        walkTargetX = CGFloat.random(in: safeRange(50, screenW - 80))
                        facingRight = (walkTargetX ?? petX) > petX
                    }
                } else {
                    petX += (target > petX) ? speed : -speed
                    facingRight = target > petX
                }
            }
            // Sparkle particles while flying
            if frameCounter % 12 == 0 {
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                    type: .star, count: 1
                )
            }
        case .playing:
            // Little bounces
            if frameCounter % 10 == 0 {
                velocityY = 4
                isOnGround = false
                petX += CGFloat.random(in: -8...8)
            }
            if frameCounter % 20 == 0 {
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                    type: .star, count: 2
                )
            }
        case .chasingToy:
            if let toy = currentToy {
                let speed: CGFloat = 3.5
                let dx = toy.x - petX
                if abs(dx) < speed * 2 {
                    // Caught the toy!
                    showBubble("Got it!")
                    particleCanvas.particleSystem.emit(
                        at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                        type: .star, count: 8
                    )
                    removeToy()
                    behavior = .idle
                    stats.addXP(2)
                    stats.save()
                } else {
                    petX += dx > 0 ? speed : -speed
                    facingRight = dx > 0
                }
                // Laser dot moves randomly
                if toy.type == .laserDot && frameCounter % 30 == 0 {
                    currentToy?.x = CGFloat.random(in: safeRange(50, screenW - 80))
                    toyWindow?.setFrameOrigin(NSPoint(x: currentToy!.x, y: currentToy!.y))
                }
            }
        case .zoomies:
            let speed: CGFloat = 5.0
            petX += speed * zoomiesDirection
            // Bounce off walls
            if petX <= 10 || petX >= screenW - petSize - 10 {
                zoomiesDirection *= -1
                facingRight = zoomiesDirection > 0
                zoomiesBounces += 1
                // Bonk effect on wall hit
                let bonkX: CGFloat = petX <= 10 ? 5 : petSize + 35
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: bonkX, y: petSize / 2 + 30),
                    type: .star, count: 3
                )
                showBubble(["Bonk!", "*thud*", "Ow!", "Wheee!"].randomElement()!)
                if zoomiesBounces >= 4 {
                    behavior = .idle
                    showBubble("*pant pant*")
                }
            }
            // Speed lines particles
            if frameCounter % 4 == 0 {
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: petSize / 2 + 40, y: petSize / 2 + 20),
                    type: .poof, count: 1
                )
            }
        case .edgeWalking:
            if let target = walkTargetX {
                let speed: CGFloat = 1.0
                if abs(petX - target) < speed * 2 {
                    petX = target
                    walkTargetX = nil
                    // Fall back down
                    behavior = .jumping
                    jumpBaseY = groundYForPet()
                    velocityY = 0
                    isOnGround = false
                } else {
                    petX += (target > petX) ? speed : -speed
                    facingRight = target > petX
                }
            }
        case .promenade:
            if let target = walkTargetX {
                let speed: CGFloat = 1.5
                if abs(petX - target) < speed * 2 {
                    petX = target
                    walkTargetX = nil
                    // Walk back
                    let newTarget = facingRight ? 20.0 : screenW - petSize - 20
                    walkTargetX = newTarget
                    facingRight = newTarget > petX
                } else {
                    petX += (target > petX) ? speed : -speed
                    facingRight = target > petX
                }
                // Trail particles
                if frameCounter % 8 == 0 {
                    particleCanvas.particleSystem.emit(
                        at: NSPoint(x: petSize / 2 + 40, y: 15),
                        type: .sparkle, count: 1
                    )
                }
            }
        case .sick:
            // Wobble in place
            if frameCounter % 5 == 0 {
                petX += CGFloat.random(in: -0.5...0.5)
            }
        case .bathing:
            // Splash particles
            if frameCounter % 6 == 0 {
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: petSize / 2 + 40 + CGFloat.random(in: -15...15), y: petSize / 2 + 20),
                    type: .sparkle, count: 2
                )
            }
        case .openingGift:
            if let gw = giftWindow, gw.isVisible {
                switch giftPhase {
                case 0:
                    // Phase 0: Gift falling from sky
                    giftPos.y -= 6
                    gw.setFrameOrigin(NSPoint(x: giftPos.x, y: giftPos.y))
                    // Gift landed on ground
                    let giftLandingY = groundY(at: giftPos.x, width: gw.frame.width) + 10
                    if giftPos.y <= giftLandingY {
                        giftPos.y = giftLandingY
                        gw.setFrameOrigin(NSPoint(x: giftPos.x, y: giftPos.y))
                        giftPhase = 1
                        showBubble("A present!!")
                    }
                case 1:
                    // Phase 1: Cat walks to the gift
                    let dx = giftPos.x - petX
                    facingRight = dx > 0
                    if abs(dx) > 20 {
                        petX += dx > 0 ? 3 : -3
                    } else {
                        // Cat reached the gift — open it!
                        giftPhase = 2
                        showBubble("A PRESENT!! Yay!!")
                        SoundEngine.shared.pop()
                        particleCanvas.particleSystem.emit(
                            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                            type: .star, count: 15
                        )
                        particleCanvas.particleSystem.emit(
                            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                            type: .heart, count: 8
                        )
                        // Random reward
                        let rewards = ["XP boost", "full tummy", "happiness", "sparkles"]
                        let reward = rewards.randomElement()!
                        switch reward {
                        case "XP boost": stats.addXP(8)
                        case "full tummy": stats.hunger = min(100, stats.hunger + 30)
                        case "happiness": stats.happiness = min(100, stats.happiness + 25)
                        default: break
                        }
                        stats.addMilestone("Opened a gift: \(reward)!")
                        stats.save()
                    }
                default:
                    // Phase 2: Gift opened — fade out smoothly
                    gw.alphaValue -= 0.05
                    if gw.alphaValue <= 0 {
                        gw.orderOut(nil)
                        gw.alphaValue = 1.0  // reset for next time
                        behavior = .idle
                    }
                }
            }
        case .clingingEdge:
            // Cat climbs UP the screen edge!
            let climbSpeed: CGFloat = 1.8
            petY += climbSpeed  // climb upward

            // Keep cat pressed against the edge
            if facingRight {
                petX = screenW - petSize
            } else {
                petX = 0
            }

            // Paw scratch particles every few frames
            if frameCounter % 8 == 0 {
                let pawX: CGFloat = facingRight ? petSize + 30 : 10
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: pawX, y: petSize / 2 + 20),
                    type: .poof, count: 1
                )
            }

            // Reached high enough — jump off!
            let climbHeight = petY - groundYForPet()
            if climbHeight > 180 || petY > screenH - petSize - 80 {
                // Launch off the wall!
                showBubble(["Wheee!", "Geronimo!", "*jumps!*", "Banzai!"].randomElement()!)
                behavior = .jumping
                behaviorStartTime = Date()
                behaviorDuration = 3.0
                jumpBaseY = groundYForPet()
                // Push away from wall
                if facingRight {
                    petX = screenW - petSize - 30
                    facingRight = false
                } else {
                    petX = 30
                    facingRight = true
                }
                velocityY = 6  // launch upward a bit more
                isOnGround = false
                // Celebratory sparkles
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                    type: .star, count: 8
                )
            }
        case .scratching:
            // Slight vibration
            if frameCounter % 3 == 0 {
                petX += CGFloat.random(in: -1...1)
            }
        default:
            break
        }

        // Edge cling detection: when walking/running and hitting the screen edge (only on floor, not Dock)
        if (behavior == .walking || behavior == .running || behavior == .promenade) &&
           !isDragging && isOnGround && groundYForPet() <= floorY + 5 {
            let atLeftEdge = petX <= 2
            let atRightEdge = petX >= screenW - petSize - 2
            if atLeftEdge || atRightEdge {
                // Switch to clinging
                behavior = .clingingEdge
                behaviorStartTime = Date()
                behaviorDuration = Double.random(in: 4.0...7.0)  // longer duration for climbing
                facingRight = atRightEdge
                walkTargetX = nil
                showBubble(["Up I go!", "Climbing time!", "I'm a gecko!", "To the top!", "Wheee!"].randomElement()!)
            }
        }

        // Clamp
        petX = max(0, min(petX, screenW - petSize))
        petY = max(floorY, min(petY, screenH - petSize - 50))

        // Idle breathing animation — subtle vertical bob
        if isOnGround && !isGentleDropping && (behavior == .idle || behavior == .sitting || behavior == .lookingAtCursor) {
            breathOffset = CGFloat(sin(Double(frameCounter) * 0.08)) * 1.5
        } else {
            breathOffset = 0
        }

        // Landing squash countdown
        if landingSquashTimer > 0 {
            landingSquashTimer -= 1
        }

        let displayOrigin = currentDisplayOrigin()
        let positionChanged = abs(displayOrigin.x - lastPetOrigin.x) > 0.5 || abs(displayOrigin.y - lastPetOrigin.y) > 0.5

        // Update windows — only reposition if moved
        if positionChanged {
            petWindow.setFrameOrigin(displayOrigin)
            lastPetOrigin = displayOrigin

            updateBubblePosition()
            updateParticleWindow()

            if currentAccessory != nil {
                accessoryWindow.setFrameOrigin(displayOrigin)
            }

            if isNightMode {
                nightGlowWindow.setFrameOrigin(NSPoint(x: petX - 15, y: petY - 15))
            }
        }

        updateSprite()

        // Night glow pulse (cheap, always run)
        if isNightMode {
            let pulse = 0.02 + 0.02 * CGFloat(sin(Double(frameCounter) * 0.03))
            nightGlowView.layer?.backgroundColor = NSColor(red: 0.4, green: 0.6, blue: 1.0, alpha: pulse).cgColor
        }

        // Update night mode every 60 seconds (adjusted for 30fps)
        if frameCounter % 1800 == 0 {
            updateNightMode()
        }

        // Drag trail sparkles
        if isDragging && frameCounter % 3 == 0 {
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + 40, y: petSize / 2 + 20),
                type: .sparkle, count: 1
            )
        }

        // Update particles — only redraw when needed
        particleCanvas.particleSystem.update()
        let hasParticles = !particleCanvas.particleSystem.particles.isEmpty
        if hasParticles || hadParticlesLastFrame {
            particleCanvas.needsDisplay = true
        }
        hadParticlesLastFrame = hasParticles

        // Stats HUD
        if isHoveringPet && !isDragging {
            statsHUD.stats = stats
            statsHUD.needsDisplay = true
            let hudX = petX + petSize / 2 - statsWindow.frame.width / 2
            let hudY = petY + petSize + 14
            statsWindow.setFrameOrigin(NSPoint(x: hudX, y: hudY))
        }

        // ── Cute events ──

        // Paw prints when walking (doubled for 30fps)
        if (behavior == .walking || behavior == .running || behavior == .promenade) && frameCounter % 24 == 0 {
            spawnPawPrint(at: NSPoint(x: petX + (facingRight ? 10 : petSize - 20), y: petY - 2))
        }

        // Sleep Z particles (doubled for 30fps)
        if behavior == .sleeping && frameCounter % 40 == 0 {
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + 50, y: petSize + 15),
                type: .note, count: 1
            )
        }

        // Idle micro-animations (every ~10 seconds)
        if frameCounter % 300 == 0 && behavior == .idle {
            let microRoll = Int.random(in: 0..<100)
            if microRoll < 15 {
                // Sneeze!
                showBubble("Achoo!")
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: petSize / 2 + (facingRight ? 50 : -10), y: petSize / 2 + 30),
                    type: .sparkle, count: 4
                )
            } else if microRoll < 25 {
                // Yawn
                showBubble("*yaaawn*")
            } else if microRoll < 35 && stats.happiness > 70 {
                // Happy tail flick — small sparkle
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: petSize / 2 + (facingRight ? -15 : 55), y: petSize / 2 + 10),
                    type: .star, count: 2
                )
            } else if microRoll < 45 && stats.happiness < 40 {
                // Sad sigh
                showBubble("*sigh*...")
            }
        }

        // Mood aura particles
        if frameCounter % 45 == 0 {
            let midX = petSize / 2
            if stats.happiness > 85 {
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: midX + CGFloat.random(in: -20...60), y: CGFloat.random(in: 10...petSize)),
                    type: .sparkle, count: 1
                )
            }
        }

        // Continuous hearts while being petted
        if behavior == .beingPet && frameCounter % 8 == 0 {
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + CGFloat.random(in: 20...60), y: petSize + CGFloat.random(in: -5...15)),
                type: .heart, count: 1
            )
        }

        // Random cute events (every ~20 seconds, adjusted for 30fps)
        if frameCounter % 600 == 0 && behavior == .idle {
            let roll = Int.random(in: 0..<100)
            if roll < 8 && butterflyWindow == nil {
                spawnButterfly()
            } else if roll < 14 && birdWindow == nil {
                spawnBird()
            } else if roll < 18 && giftWindow == nil {
                spawnGift()
            } else if roll < 22 {
                startKnockingGlass()
            }
        }

        // Update butterfly
        updateButterfly()
        updateBird()
        updateGlass()

        // Birthday check (once a day)
        if frameCounter == 30 {
            checkBirthday()
        }
    }

    func updateSprite() {
        CatRenderer.shared.petScreenCenter = NSPoint(x: petX + petSize / 2, y: petY + petSize / 2)
        let sprite: NSImage
        if isDragging || isGentleDropping {
            sprite = getSprite(for: .beingPet, frame: animFrame, right: facingRight)
        } else {
            sprite = getSprite(for: behavior, frame: animFrame, right: facingRight)
        }

        // Apply transition squash/stretch for smooth behavior changes
        let transFrames = 6  // transition lasts 6 anim frames (~0.4s)
        if transitionFrame < transFrames && !isGentleDropping {
            let t = CGFloat(transitionFrame) / CGFloat(transFrames)
            var sx: CGFloat = 1.0, sy: CGFloat = 1.0

            let startedWalking = (previousBehavior == .idle || previousBehavior == .sitting) &&
                (behavior == .walking || behavior == .running)
            let stoppedWalking = (previousBehavior == .walking || previousBehavior == .running) &&
                (behavior == .idle || behavior == .sitting)
            let startedJumping = behavior == .jumping && previousBehavior != .jumping

            if startedWalking {
                // Lean forward: squash down then spring up
                if t < 0.5 {
                    sx = 1.0 + (1.0 - t * 2) * 0.06
                    sy = 1.0 - (1.0 - t * 2) * 0.05
                } else {
                    sx = 1.0 - (t - 0.5) * 2 * 0.03
                    sy = 1.0 + (t - 0.5) * 2 * 0.025
                }
            } else if stoppedWalking {
                // Settle bounce: slight squash
                let bounce = (1.0 - t) * 0.06
                sx = 1.0 + bounce
                sy = 1.0 - bounce * 0.8
            } else if startedJumping {
                // Wind-up squash then stretch
                if t < 0.4 {
                    sx = 1.0 + (1.0 - t / 0.4) * 0.1
                    sy = 1.0 - (1.0 - t / 0.4) * 0.12
                } else {
                    sx = 1.0 - (t - 0.4) / 0.6 * 0.06
                    sy = 1.0 + (t - 0.4) / 0.6 * 0.08
                }
            }

            if sx != 1.0 || sy != 1.0 {
                let sz = sprite.size
                let output = NSImage(size: sz)
                output.lockFocus()
                if let ctx = NSGraphicsContext.current?.cgContext {
                    ctx.translateBy(x: sz.width / 2, y: 0)
                    ctx.scaleBy(x: sx, y: sy)
                    ctx.translateBy(x: -sz.width / 2, y: 0)
                    sprite.draw(in: NSRect(origin: .zero, size: sz),
                                from: NSRect(origin: .zero, size: sz),
                                operation: .sourceOver, fraction: 1.0)
                }
                output.unlockFocus()
                petImageView.image = output
                return
            }
        }

        // Landing squash effect
        if landingSquashTimer > 0 {
            let t = CGFloat(landingSquashTimer) / 8.0
            let lsx: CGFloat = 1.0 + t * 0.15   // widen on impact
            let lsy: CGFloat = 1.0 - t * 0.12   // flatten on impact
            let sz = sprite.size
            let output = NSImage(size: sz)
            output.lockFocus()
            if let ctx = NSGraphicsContext.current?.cgContext {
                ctx.translateBy(x: sz.width / 2, y: 0)
                ctx.scaleBy(x: lsx, y: lsy)
                ctx.translateBy(x: -sz.width / 2, y: 0)
                sprite.draw(in: NSRect(origin: .zero, size: sz),
                            from: NSRect(origin: .zero, size: sz),
                            operation: .sourceOver, fraction: 1.0)
            }
            output.unlockFocus()
            petImageView.image = output
            return
        }

        petImageView.image = sprite
    }

    // MARK: - Cute Events

    func spawnPawPrint(at point: NSPoint) {
        let size: CGFloat = 12
        let img = Sprites.render(Sprites.pawPrint, scale: 2)
        let win = NSPanel(contentRect: NSRect(x: point.x, y: point.y, width: size, height: size),
                          styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = false
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]
        win.ignoresMouseEvents = true
        win.alphaValue = 0.4
        let iv = NSImageView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        iv.image = img
        iv.imageScaling = .scaleProportionallyUpOrDown
        win.contentView = iv
        win.orderFront(nil)
        pawPrintWindows.append(win)

        // Fade out and remove after 3 seconds
        let timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            win.orderOut(nil)
            self?.pawPrintWindows.removeAll { $0 === win }
        }
        pawPrintTimers.append(timer)

        // Clean up old ones (max 12)
        while pawPrintWindows.count > 12 {
            pawPrintWindows[0].orderOut(nil)
            pawPrintWindows.removeFirst()
            if !pawPrintTimers.isEmpty {
                pawPrintTimers[0].invalidate()
                pawPrintTimers.removeFirst()
            }
        }
    }

    func spawnButterfly() {
        let size: CGFloat = 30
        butterflyPos = NSPoint(x: CGFloat.random(in: safeRange(100, screenW - 100)),
                               y: CGFloat.random(in: safeRange(200, screenH - 200)))
        let frame = NSRect(x: butterflyPos.x, y: butterflyPos.y, width: size, height: size)

        if butterflyWindow == nil {
            butterflyWindow = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                                      backing: .buffered, defer: false)
            butterflyWindow!.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
            butterflyWindow!.backgroundColor = .clear
            butterflyWindow!.isOpaque = false
            butterflyWindow!.hasShadow = false
            butterflyWindow!.collectionBehavior = [.canJoinAllSpaces, .stationary]
            butterflyWindow!.ignoresMouseEvents = true
            let iv = NSImageView(frame: NSRect(x: 0, y: 0, width: size, height: size))
            iv.imageScaling = .scaleProportionallyUpOrDown
            iv.image = KawaiiItems.butterfly(frame: 0)
            butterflyWindow!.contentView = iv
        }

        butterflyWindow!.setFrameOrigin(NSPoint(x: butterflyPos.x, y: butterflyPos.y))
        butterflyWindow!.orderFront(nil)
        butterflyFrame = 0

        showBubble("A butterfly!!")
        startBehavior(.chasingButterfly, duration: 8.0)
    }

    func updateButterfly() {
        guard let bw = butterflyWindow, bw.isVisible else { return }
        butterflyFrame += 1

        // Flutter movement — sine wave
        butterflyPos.x += CGFloat(sin(Double(butterflyFrame) * 0.08)) * 2 + 0.5
        butterflyPos.y += CGFloat(cos(Double(butterflyFrame) * 0.06)) * 1.5

        // Update sprite (wing flap)
        if butterflyFrame % 6 == 0 {
            let wingFrame = butterflyFrame % 12 < 6 ? 0 : 1
            (bw.contentView as? NSImageView)?.image = KawaiiItems.butterfly(frame: wingFrame)
        }

        bw.setFrameOrigin(NSPoint(x: butterflyPos.x, y: butterflyPos.y))

        // Cat chases it
        if behavior == .chasingButterfly {
            let speed: CGFloat = 2.0
            let dx = butterflyPos.x - petX
            petX += dx > 0 ? speed : -speed
            facingRight = dx > 0
        }

        // Disappear after a while or off screen
        if butterflyPos.x > screenW + 20 || butterflyPos.y > screenH + 20 || butterflyFrame > 150 {
            bw.orderOut(nil)
            if behavior == .chasingButterfly {
                showBubble("It got away...")
                behavior = .idle
            }
        }

        // Cat caught it!
        if behavior == .chasingButterfly && abs(petX - butterflyPos.x) < 30 && abs(petY - butterflyPos.y) < 50 {
            bw.orderOut(nil)
            showBubble("I caught it! *lets go*")
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                type: .sparkle, count: 10
            )
            stats.addXP(3)
            stats.happiness = min(100, stats.happiness + 10)
            stats.addMilestone("Caught a butterfly!")
            stats.save()
            behavior = .idle
        }
    }

    func spawnBird() {
        let size: CGFloat = 30
        let birdX = nearbyEventX(offset: facingRight ? 150 : -150, width: size)
        birdPos = NSPoint(x: birdX, y: groundY(at: birdX, width: size))
        let frame = NSRect(x: birdPos.x, y: birdPos.y, width: size, height: size)

        if birdWindow == nil {
            birdWindow = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                                  backing: .buffered, defer: false)
            birdWindow!.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
            birdWindow!.backgroundColor = .clear
            birdWindow!.isOpaque = false
            birdWindow!.hasShadow = false
            birdWindow!.collectionBehavior = [.canJoinAllSpaces, .stationary]
            birdWindow!.ignoresMouseEvents = true
            let iv = NSImageView(frame: NSRect(x: 0, y: 0, width: size, height: size))
            iv.imageScaling = .scaleProportionallyUpOrDown
            iv.image = KawaiiItems.bird()
            birdWindow!.contentView = iv
        }

        birdWindow!.setFrameOrigin(NSPoint(x: birdPos.x, y: birdPos.y))
        birdWindow!.orderFront(nil)
        birdFlyAwaySpeed = 0
        birdFlyAwayFrame = 0

        showBubble("*stares at bird*")
        startBehavior(.watchingBird, duration: 6.0)
    }

    func updateBird() {
        guard let bw = birdWindow, bw.isVisible else { return }

        // Cat watches intently while behavior is active
        if behavior == .watchingBird {
            // Bird hops slightly on the ground
            if frameCounter % 30 == 0 {
                birdPos.x += CGFloat.random(in: -5...5)
                birdPos.x = nearbyEventX(offset: birdPos.x - petX, width: bw.frame.width)
                birdPos.y = groundY(at: birdPos.x, width: bw.frame.width)
                bw.setFrameOrigin(NSPoint(x: birdPos.x, y: birdPos.y))
            }
            facingRight = birdPos.x > petX
            // Butt wiggle (getting ready to pounce)
            if frameCounter % 4 == 0 {
                petX += CGFloat.random(in: -0.5...0.5)
            }
        }

        // Bird flies away smoothly when behavior ends
        if behavior != .watchingBird && bw.isVisible {
            birdFlyAwayFrame += 1
            // Accelerate upward and to the side over ~2 seconds (~120 frames at 60fps)
            birdFlyAwaySpeed += 0.15  // gradual acceleration
            let sideDir: CGFloat = birdPos.x > petX ? 1 : -1
            birdPos.y += birdFlyAwaySpeed
            birdPos.x += sideDir * (1.0 + birdFlyAwaySpeed * 0.3)

            // Wing flap animation during fly-away
            if birdFlyAwayFrame % 4 == 0 {
                // Create a flapping bird image by re-rendering with slight vertical offset
                let flapOffset: CGFloat = birdFlyAwayFrame % 8 < 4 ? 2 : -2
                let birdSize: CGFloat = 30
                let flapImg = NSImage(size: NSSize(width: birdSize, height: birdSize))
                flapImg.lockFocus()
                if let ctx = NSGraphicsContext.current?.cgContext {
                    // Translate for flap effect
                    ctx.translateBy(x: 0, y: flapOffset)
                    let baseImg = KawaiiItems.bird()
                    baseImg.draw(in: NSRect(x: 0, y: 0, width: birdSize, height: birdSize))
                }
                flapImg.unlockFocus()
                (bw.contentView as? NSImageView)?.image = flapImg
            }

            bw.setFrameOrigin(NSPoint(x: birdPos.x, y: birdPos.y))

            if birdPos.y > screenH + 50 {
                bw.orderOut(nil)
                showBubble("*chirp chirp* Bye birdie!")
            }
        }
    }

    func spawnGift() {
        let size: CGFloat = 40
        let gx = nearbyEventX(offset: CGFloat.random(in: -100...100), width: size)
        giftPos = NSPoint(x: gx, y: screenH)
        let frame = NSRect(x: giftPos.x, y: giftPos.y, width: size, height: size)

        if giftWindow == nil {
            giftWindow = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                                  backing: .buffered, defer: false)
            giftWindow!.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
            giftWindow!.backgroundColor = .clear
            giftWindow!.isOpaque = false
            giftWindow!.hasShadow = false
            giftWindow!.collectionBehavior = [.canJoinAllSpaces, .stationary]
            giftWindow!.ignoresMouseEvents = true
            let iv = NSImageView(frame: NSRect(x: 0, y: 0, width: size, height: size))
            iv.imageScaling = .scaleProportionallyUpOrDown
            iv.image = KawaiiItems.gift()
            giftWindow!.contentView = iv
        }

        giftWindow!.setFrameOrigin(NSPoint(x: giftPos.x, y: giftPos.y))
        giftWindow!.orderFront(nil)
        giftPhase = 0  // start with falling phase

        startBehavior(.openingGift, duration: 12.0)
    }

    func startKnockingGlass() {
        let size: CGFloat = 30
        let glassX = nearbyEventX(offset: facingRight ? 110 : -110, width: size)
        let glassY = groundY(at: glassX, width: size)
        let frame = NSRect(x: glassX, y: glassY, width: size, height: size)

        if glassWindow == nil {
            glassWindow = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                                   backing: .buffered, defer: false)
            glassWindow!.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
            glassWindow!.backgroundColor = .clear
            glassWindow!.isOpaque = false
            glassWindow!.hasShadow = false
            glassWindow!.collectionBehavior = [.canJoinAllSpaces, .stationary]
            glassWindow!.ignoresMouseEvents = true
            let iv = NSImageView(frame: NSRect(x: 0, y: 0, width: size, height: size))
            iv.imageScaling = .scaleProportionallyUpOrDown
            iv.image = KawaiiItems.glass()
            glassWindow!.contentView = iv
        }

        glassWindow!.setFrameOrigin(NSPoint(x: glassX, y: glassY))
        glassWindow!.orderFront(nil)
        glassVelocityY = 0

        showBubble("*eyes glass*")
        facingRight = glassX > petX
        walkTargetX = min(max(glassX + (facingRight ? -30 : 30), 0), screenW - petSize)
        startBehavior(.knockingGlass, duration: 6.0)
    }

    func updateGlass() {
        guard let gw = glassWindow, gw.isVisible else { return }

        let glassFrame = gw.frame
        // Cat reached the glass — knock it!
        if behavior == .knockingGlass && abs(petX - glassFrame.origin.x) < 50 {
            if glassVelocityY == 0 {
                showBubble("*boop*")
                glassVelocityY = 6  // launch it up
            }
        }

        if glassVelocityY != 0 {
            glassVelocityY -= 0.5
            var newY = glassFrame.origin.y + glassVelocityY
            let newX = glassFrame.origin.x + (facingRight ? 2 : -2)

            if newY < -50 {
                // Fell off screen — poof
                gw.orderOut(nil)
                showBubble("Oops! *innocent face*")
                particleCanvas.particleSystem.emit(
                    at: NSPoint(x: petSize / 2 + 40, y: 10),
                    type: .poof, count: 8
                )
                stats.happiness = min(100, stats.happiness + 5)
                stats.addXP(1)
                stats.addMilestone("Knocked a glass off the table!")
                stats.save()
                glassVelocityY = 0
                behavior = .idle
                return
            }
            newY = max(-50, newY)
            gw.setFrameOrigin(NSPoint(x: newX, y: newY))
            // Rotate effect — slight wobble via alpha
            gw.alphaValue = 0.7 + CGFloat(sin(Double(frameCounter) * 0.5)) * 0.3
        }
    }

    func checkBirthday() {
        let cal = Calendar.current
        let today = Date()
        let birthMonth = cal.component(.month, from: stats.birthDate)
        let birthDay = cal.component(.day, from: stats.birthDate)
        let todayMonth = cal.component(.month, from: today)
        let todayDay = cal.component(.day, from: today)

        if birthMonth == todayMonth && birthDay == todayDay {
            showBubble("It's my BIRTHDAY!!!")
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + 40, y: petSize + 20),
                type: .heart, count: 20
            )
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + 40, y: petSize + 20),
                type: .star, count: 20
            )
            stats.addMilestone("Celebrated birthday!")
            stats.addXP(20)
            stats.save()
        }
    }

    func updateBubblePosition() {
        if bubbleWindow.isVisible {
            let bw = bubbleWindow.frame.width
            let x = petX + petSize / 2 - bw / 2
            let y = petY + petSize + 10
            bubbleWindow.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func updateParticleWindow() {
        let pw: CGFloat = petSize + 80
        let ph: CGFloat = petSize + 60
        particleWindow.setFrame(
            NSRect(x: petX - 40, y: petY - 20, width: pw, height: ph),
            display: false
        )
        particleCanvas.frame = NSRect(x: 0, y: 0, width: pw, height: ph)
    }

    func updateStatusBar() {
        let mood = stats.mood
        let emoji: String
        switch mood {
        case .happy: emoji = "=^.^="
        case .neutral: emoji = "=^-^="
        case .sad: emoji = "=;.;="
        case .sleepy: emoji = "=^~^="
        case .sick: emoji = "=x.x="
        }

        // Blink attention indicator when pet needs care
        if stats.needsAttention {
            let blink = frameCounter % 30 < 15
            statusBarItem.button?.title = blink ? "\u{26A0}\u{FE0F} \(emoji)" : emoji
        } else {
            statusBarItem.button?.title = emoji
        }

        // Update menu header
        if let menu = statusBarItem.menu, let header = menu.items.first {
            header.title = "Murchi - Lv.\(stats.level) \(stats.evolutionStage)"
        }
    }

    // MARK: - User Interactions

    @objc func feedPet() {
        stats.feed()
        if stats.totalFeedings == 1 { stats.addMilestone("Had my first meal ever! Yummy fish!") }
        if stats.totalFeedings % 50 == 0 { stats.addMilestone("Eaten \(stats.totalFeedings) meals! I'm a foodie \u{1F41F}") }
        startBehavior(.eating, duration: 3.0)
        showBubble(SpeechBubbles.eating(petType).randomElement()!)
        SoundEngine.shared.eat()
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
            type: .sparkle, count: 5
        )
        stats.save()

        // Drop a fish sprite briefly
        showFoodAnimation()
    }

    @objc func playWithPet() {
        stats.play()
        if stats.totalPlays == 1 { stats.addMilestone("Played for the first time! So much fun!") }
        if stats.totalPlays % 25 == 0 { stats.addMilestone("Play session #\(stats.totalPlays)! I love games!") }
        startBehavior(.playing, duration: 5.0)
        showBubble(SpeechBubbles.playing(petType).randomElement()!)
        SoundEngine.shared.happy()
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
            type: .star, count: 8
        )
        stats.save()
    }

    @objc func restPet() {
        stats.rest()
        startBehavior(.sleeping, duration: 12.0)
        showBubble("*purrs and curls up*")
        SoundEngine.shared.sleepy()
        stats.save()
    }

    @objc func bathePet() {
        stats.bathe()
        if stats.totalBaths == 1 { stats.addMilestone("First bath! I hated every second of it!") }
        if stats.totalBaths % 10 == 0 { stats.addMilestone("Bath #\(stats.totalBaths)... I'm starting to accept it") }
        startBehavior(.bathing, duration: 4.0)
        showBubble(SpeechBubbles.bathBubbles(petType).randomElement()!)
        SoundEngine.shared.meow()
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
            type: .sparkle, count: 10
        )
        stats.save()
    }

    @objc func feedMilkAction() {
        stats.feedMilk()
        startBehavior(.eating, duration: 3.0)
        showBubble(SpeechBubbles.milkBubbles(petType).randomElement()!)
        SoundEngine.shared.eat()
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
            type: .sparkle, count: 5
        )
        showFoodAnimation(sprite: Sprites.milk)
        stats.save()
    }

    @objc func feedTreatAction() {
        stats.feedTreat()
        startBehavior(.eating, duration: 2.0)
        showBubble(SpeechBubbles.treatBubbles.randomElement()!)
        SoundEngine.shared.eat()
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
            type: .star, count: 6
        )
        showFoodAnimation(sprite: Sprites.treat)
        stats.save()
    }

    @objc func toggleSound() {
        soundEnabled.toggle()
        SoundEngine.shared.setVolume(soundEnabled ? 0.3 : 0)
        // Update menu item title
        if let menu = statusBarItem.menu {
            for item in menu.items {
                if item.title.contains("Mute") || item.title.contains("Enable") {
                    item.title = soundEnabled ? "\u{1F508} Mute Sounds" : "\u{1F50A} Enable Sounds"
                }
            }
        }
    }

    @objc func selectPetType(_ sender: NSMenuItem) {
        guard let newType = sender.representedObject as? String, newType != petType else { return }
        petType = newType
        // Update checkmarks in submenu
        if let menu = statusBarItem.menu {
            for item in menu.items {
                if let sub = item.submenu {
                    for subItem in sub.items {
                        subItem.state = (subItem.representedObject as? String) == petType ? .on : .off
                    }
                }
            }
        }
        // Re-render current sprite
        updateSprite()
    }

    @objc func toggleFollowCursor() {
        followingCursor.toggle()
        if followingCursor {
            startBehavior(.chasingCursor, duration: 999999)
            showBubble("I'll follow you! 🐾")
        } else {
            startBehavior(.idle, duration: 2.0)
            showBubble("Ok, I'll chill~")
        }
    }

    @objc func healPet() {
        guard stats.isSick else {
            showBubble("I'm not sick!")
            return
        }
        stats.heal()
        startBehavior(.idle, duration: 2.0)
        showBubble(SpeechBubbles.healBubbles.randomElement()!)
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
            type: .sparkle, count: 12
        )
        showFoodAnimation(sprite: Sprites.medicine)
        stats.addMilestone("Recovered from sickness!")
        stats.save()
    }

    @objc func takeForWalk() {
        stats.walk()
        startBehavior(.promenade, duration: 15.0)
        showBubble(SpeechBubbles.promenadeBubbles(petType).randomElement()!)
        // Walk across entire screen
        walkTargetX = facingRight ? screenW - petSize - 20 : 20
        stats.addMilestone("Went for a walk!")
        stats.save()
    }

    @objc func screenshotPet() {
        // Render current sprite at high res and copy to clipboard
        let sprite = getSprite(for: behavior, frame: animFrame, right: facingRight)
        let hiRes = NSImage(size: NSSize(width: 320, height: 320))
        hiRes.lockFocus()
        NSColor.clear.set()
        NSRect(x: 0, y: 0, width: 320, height: 320).fill()
        sprite.draw(in: NSRect(x: 0, y: 0, width: 320, height: 320),
                    from: .zero, operation: .sourceOver, fraction: 1.0)
        hiRes.unlockFocus()

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([hiRes])
        showBubble("Screenshot copied! \u{1F4F8}")
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
            type: .sparkle, count: 8
        )
        NSSound(named: "Tink")?.play()
    }

    @objc func showDiary() {
        let w: CGFloat = 420
        let h: CGFloat = 520
        let screenCenter = NSPoint(
            x: (NSScreen.main?.frame.width ?? 1440) / 2 - w / 2,
            y: (NSScreen.main?.frame.height ?? 900) / 2 - h / 2
        )

        let diaryWin = NSWindow(
            contentRect: NSRect(x: screenCenter.x, y: screenCenter.y, width: w, height: h),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        diaryWin.title = "\u{1F4D3} Murchi's Diary"
        diaryWin.isReleasedWhenClosed = true
        diaryWin.level = .floating

        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: w, height: h))
        scroll.hasVerticalScroller = true
        scroll.autoresizingMask = [.width, .height]

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: w - 20, height: h))
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = NSColor(red: 0.06, green: 0.05, blue: 0.12, alpha: 1)
        textView.textContainerInset = NSSize(width: 16, height: 16)

        // Build diary content
        let content = NSMutableAttributedString()

        func addText(_ str: String, size: CGFloat = 13, bold: Bool = false, color: NSColor = .white, spacing: CGFloat = 4) {
            let font = bold
                ? (NSFont(name: "Menlo-Bold", size: size) ?? NSFont.boldSystemFont(ofSize: size))
                : (NSFont(name: "Menlo", size: size) ?? NSFont.systemFont(ofSize: size))
            let para = NSMutableParagraphStyle()
            para.paragraphSpacing = spacing
            content.append(NSAttributedString(string: str, attributes: [
                .font: font, .foregroundColor: color, .paragraphStyle: para
            ]))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let shortFormatter = DateFormatter()
        shortFormatter.dateFormat = "MMM d"

        // Header
        addText("\u{1F431} \(stats.name)'s Blog\n", size: 20, bold: true, color: NSColor(red: 1, green: 0.85, blue: 0.3, alpha: 1))
        addText("\(stats.evolutionStage) \u{2022} Level \(stats.level)\n\n", size: 11, color: NSColor(red: 0.7, green: 0.6, blue: 1, alpha: 0.8))

        // Bio card
        let age = max(1, Int(Date().timeIntervalSince(stats.birthDate) / 86400))
        addText("\u{1F382} Born: \(shortFormatter.string(from: stats.birthDate)) (\(age) days old)\n", size: 11, color: NSColor(red: 0.6, green: 0.8, blue: 1, alpha: 1))

        // Stats summary as cute text
        addText("\n\u{1F4CA} My Life in Numbers\n", size: 14, bold: true, color: NSColor(red: 0.4, green: 1, blue: 0.7, alpha: 1))
        addText("\u{1F41F} Meals eaten: \(stats.totalFeedings)\n", size: 11, color: NSColor(white: 0.8, alpha: 1))
        addText("\u{1F49C} Times petted: \(stats.totalPets)\n", size: 11, color: NSColor(white: 0.8, alpha: 1))
        addText("\u{1F3AE} Play sessions: \(stats.totalPlays)\n", size: 11, color: NSColor(white: 0.8, alpha: 1))
        addText("\u{1F6C1} Baths taken: \(stats.totalBaths) (ugh)\n", size: 11, color: NSColor(white: 0.8, alpha: 1))
        addText("\u{1F6B6} Walks: \(stats.totalWalks)\n", size: 11, color: NSColor(white: 0.8, alpha: 1))
        addText("\u{1F48A} Times healed: \(stats.totalHeals)\n", size: 11, color: NSColor(white: 0.8, alpha: 1))

        // Current mood
        addText("\n\u{1F4AD} Current Mood\n", size: 14, bold: true, color: NSColor(red: 1, green: 0.5, blue: 0.7, alpha: 1))
        let moodEmoji: String
        let moodText: String
        switch stats.mood {
        case .happy: moodEmoji = "\u{1F60A}"; moodText = "I'm feeling great! Life is good~"
        case .neutral: moodEmoji = "\u{1F610}"; moodText = "I'm okay I guess. Could use some attention..."
        case .sad: moodEmoji = "\u{1F622}"; moodText = "I'm not doing so well... please take care of me..."
        case .sleepy: moodEmoji = "\u{1F634}"; moodText = "So... tired... need... nap..."
        case .sick: moodEmoji = "\u{1F912}"; moodText = "I feel terrible... need medicine please..."
        }
        addText("\(moodEmoji) \(moodText)\n", size: 12, color: NSColor(white: 0.9, alpha: 1))

        // Complaints / needs
        var needs: [String] = []
        if stats.hunger < 30 { needs.append("\u{1F356} I haven't been fed in a while... my tummy is growling") }
        if stats.happiness < 30 { needs.append("\u{1F494} I'm sad... nobody plays with me") }
        if stats.energy < 20 { needs.append("\u{1F4A4} I'm exhausted, let me sleep...") }
        if stats.hygiene < 30 { needs.append("\u{1F9FC} I kinda need a bath... don't tell anyone") }
        if stats.social < 30 { needs.append("\u{1F465} I'm lonely... pet me please?") }
        if stats.health < 40 { needs.append("\u{1F915} My health isn't great...") }
        if stats.poopCount > 0 { needs.append("\u{1F4A9} There are \(stats.poopCount) poop(s) that need cleaning...") }

        if !needs.isEmpty {
            addText("\n\u{26A0}\u{FE0F} What I Need Right Now\n", size: 14, bold: true, color: NSColor(red: 1, green: 0.4, blue: 0.4, alpha: 1))
            for need in needs {
                addText("\(need)\n", size: 11, color: NSColor(red: 1, green: 0.7, blue: 0.7, alpha: 1))
            }
        }

        // Diary entries (milestones)
        addText("\n\u{1F4D6} Diary Entries\n", size: 14, bold: true, color: NSColor(red: 1, green: 0.85, blue: 0.3, alpha: 1))
        addText("─────────────────────────────\n", size: 10, color: NSColor(white: 0.3, alpha: 1))

        if stats.milestones.isEmpty {
            addText("\nNo entries yet... my story is just beginning!\n", size: 12, color: NSColor(white: 0.5, alpha: 1))
        } else {
            for entry in stats.milestones.reversed() {
                // Parse date from [YYYY-MM-DD] prefix
                if entry.hasPrefix("[") {
                    let dateEnd = entry.firstIndex(of: "]") ?? entry.startIndex
                    let dateStr = String(entry[entry.index(after: entry.startIndex)..<dateEnd])
                    let msgStr = String(entry[entry.index(after: dateEnd)...]).trimmingCharacters(in: .whitespaces)
                    addText("\(dateStr) ", size: 9, color: NSColor(red: 0.5, green: 0.5, blue: 0.7, alpha: 1))
                    addText("\(msgStr)\n", size: 12, color: NSColor(white: 0.85, alpha: 1), spacing: 8)
                } else {
                    addText("\(entry)\n", size: 12, color: NSColor(white: 0.85, alpha: 1), spacing: 8)
                }
            }
        }

        // Fun facts
        addText("\n\u{2728} Fun Facts\n", size: 14, bold: true, color: NSColor(red: 0.6, green: 0.8, blue: 1, alpha: 1))
        addText("─────────────────────────────\n", size: 10, color: NSColor(white: 0.3, alpha: 1))

        let favActivity = stats.totalPlays > stats.totalPets ? "playing" : "being petted"
        addText("\u{1F3AF} Favorite activity: \(favActivity)\n", size: 11, color: NSColor(white: 0.7, alpha: 1))

        let xpTotal = stats.level * 80 + stats.xp
        addText("\u{2B50} Total XP earned: ~\(xpTotal)\n", size: 11, color: NSColor(white: 0.7, alpha: 1))

        if stats.totalBaths > 5 {
            addText("\u{1F6BF} Surprisingly clean for a cat!\n", size: 11, color: NSColor(white: 0.7, alpha: 1))
        }
        if stats.totalFeedings > 50 {
            addText("\u{1F37D} Quite the foodie...\n", size: 11, color: NSColor(white: 0.7, alpha: 1))
        }
        if age > 7 {
            addText("\u{1F3E0} Been living here for \(age) days!\n", size: 11, color: NSColor(white: 0.7, alpha: 1))
        }

        addText("\n\n\u{1F43E} End of diary. Meow~\n", size: 11, color: NSColor(white: 0.4, alpha: 1))

        textView.textStorage?.setAttributedString(content)
        scroll.documentView = textView
        diaryWin.contentView = scroll
        diaryWin.makeKeyAndOrderFront(nil)
    }

    @objc func cleanPoopAction() {
        if stats.poopCount > 0 {
            stats.cleanPoop()
            for w in poopWindows {
                w.orderOut(nil)
            }
            poopWindows.removeAll()
            showBubble("Thank you!")
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                type: .poof, count: 8
            )
            stats.save()
        } else {
            showBubble("No mess here!")
        }
    }

    func petTapped() {
        dismissLaserDotIfNeeded()

        // Multi-click detection
        let now = Date()
        if now.timeIntervalSince(lastClickTime) < 0.4 {
            clickCount += 1
        } else {
            clickCount = 1
        }
        lastClickTime = now

        stats.pet()
        if stats.totalPets == 1 { stats.addMilestone("Got my first pet! I feel loved \u{1F49C}") }
        if stats.totalPets == 100 { stats.addMilestone("100 pets! My human really loves me!") }
        if stats.totalPets == 500 { stats.addMilestone("500 pets! I'm the most loved cat ever!") }

        if clickCount >= 3 {
            // Triple click — extra love!
            showBubble("SO MUCH LOVE!!!")
            SoundEngine.shared.purr()
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                type: .heart, count: 15
            )
            stats.happiness = min(100, stats.happiness + 10)
            stats.addXP(2)
        } else {
            startBehavior(.beingPet, duration: 2.5)
            showBubble(SpeechBubbles.petted(petType).randomElement()!)
            SoundEngine.shared.chirp()
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                type: .heart, count: 5
            )
        }
        stats.save()

        // Play system sound
        NSSound(named: "Pop")?.play()
    }

    func showFoodAnimation(sprite: [[UInt32]] = Sprites.fish) {
        let fishImg = Sprites.render(sprite, scale: 4)
        let foodSize: CGFloat = 40
        let fx = petX + petSize / 2 - foodSize / 2
        let fy = petY + petSize + 20

        if foodWindow == nil {
            let frame = NSRect(x: fx, y: fy, width: foodSize, height: foodSize)
            foodWindow = NSPanel(
                contentRect: frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            foodWindow!.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
            foodWindow!.backgroundColor = .clear
            foodWindow!.isOpaque = false
            foodWindow!.hasShadow = false
            foodWindow!.collectionBehavior = [.canJoinAllSpaces, .stationary]
            foodWindow!.ignoresMouseEvents = true

            let iv = NSImageView(frame: NSRect(x: 0, y: 0, width: foodSize, height: foodSize))
            iv.image = fishImg
            iv.imageScaling = .scaleProportionallyUpOrDown
            foodWindow!.contentView = iv
        }

        foodWindow!.setFrameOrigin(NSPoint(x: fx, y: fy))
        foodWindow!.orderFront(nil)

        // Animate fish falling to cat
        var step = 0
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            step += 1
            let progress = CGFloat(step) / 20.0
            let currentY = fy - (fy - self.petY) * progress
            self.foodWindow?.setFrameOrigin(NSPoint(x: fx, y: currentY))
            if step >= 20 {
                timer.invalidate()
                self.foodWindow?.orderOut(nil)
            }
        }
    }

    @objc func showStats() {
        let age = Int(Date().timeIntervalSince(stats.birthDate) / 86400)
        let msg = """
        \(stats.name)'s Stats:

        Hunger: \(Int(stats.hunger))%
        Happiness: \(Int(stats.happiness))%
        Energy: \(Int(stats.energy))%
        Social: \(Int(stats.social))%
        Hygiene: \(Int(stats.hygiene))%

        Mood: \(stats.mood.rawValue.capitalized)
        Level: \(stats.level) (\(stats.evolutionStage))
        XP: \(stats.xp)/\(stats.xpForNextLevel)
        Age: \(age) days

        Total Pets: \(stats.totalPets)
        Total Feedings: \(stats.totalFeedings)
        Total Plays: \(stats.totalPlays)
        """

        let alert = NSAlert()
        alert.messageText = stats.name
        alert.informativeText = msg
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Mouse handling

    let heldWindowHeight: CGFloat = 120  // taller window when held (= heldHeight/2 for retina)

    func handleMouseDown(_ event: NSEvent) {
        dismissLaserDotIfNeeded()
        isDragging = true
        // Hide stats HUD while dragging
        statsWindow.orderOut(nil)
        didDragPet = false
        isGentleDropping = false
        gentleDropPhase = 0
        breathOffset = 0
        dragOffset = NSPoint(
            x: event.locationInWindow.x,
            y: event.locationInWindow.y
        )
        dragStartScreenPoint = NSEvent.mouseLocation
        // Grab reaction
        let grabBubbles = ["Mew?!", "*grabbed!*", "Hey!", "Wah!", "Eep!"]
        showBubble(grabBubbles.randomElement()!)

        // Resize window to tall held format (body hangs below cursor)
        let newFrame = NSRect(x: petWindow.frame.origin.x, y: petWindow.frame.origin.y,
                              width: petSize, height: heldWindowHeight)
        petWindow.setFrame(newFrame, display: false)
        petImageView.frame = NSRect(x: 0, y: 0, width: petSize, height: heldWindowHeight)
        (petWindow.contentView as? PetView)?.frame = NSRect(x: 0, y: 0, width: petSize, height: heldWindowHeight)
    }

    func handleMouseDragged(_ event: NSEvent) {
        guard isDragging else { return }
        let screenPoint = NSEvent.mouseLocation
        let moved = abs(screenPoint.x - dragStartScreenPoint.x) + abs(screenPoint.y - dragStartScreenPoint.y)
        if moved > 4 {
            didDragPet = true
        }
        // Position: cursor is at the scruff (top), body hangs below
        // Head is about 20% from top of the held image
        let scruffOffsetY = heldWindowHeight * 0.8  // scruff near top
        petX = screenPoint.x - petSize / 2
        petY = screenPoint.y - scruffOffsetY
        let dragOrigin = NSPoint(x: petX.rounded(), y: petY.rounded())
        petWindow.setFrameOrigin(dragOrigin)
        if currentAccessory != nil {
            accessoryWindow.setFrameOrigin(dragOrigin)
        }
        updateBubblePosition()
        updateParticleWindow()

        // Detect shaking
        let dx = screenPoint.x - lastDragPos.x
        if abs(dx) > 8 {
            let newDir = dx > 0 ? 1.0 : -1.0 as CGFloat
            if newDir != lastDragDirection && lastDragDirection != 0 {
                dragShakeCount += 1
                if dragShakeCount >= 4 {
                    let shakeBubbles = ["AAAA!", "*dizzy*", "Stop shaking!", "Meooow!", "I'm gonna hurl!"]
                    showBubble(shakeBubbles.randomElement()!)
                    particleCanvas.particleSystem.emit(
                        at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                        type: .star, count: 6
                    )
                    stats.happiness = max(0, stats.happiness - 2)
                    dragShakeCount = 0
                }
            }
            lastDragDirection = newDir
        }
        lastDragPos = screenPoint

        // Show cat held by scruff when dragged
        petImageView.image = getSprite(for: .beingPet, frame: animFrame, right: facingRight)

        // Dangling sparkle trail while dragged
        if frameCounter % 5 == 0 {
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + CGFloat.random(in: 10...50), y: CGFloat.random(in: 5...20)),
                type: .sparkle, count: 1
            )
        }
    }

    private func restoreSquareWindow() {
        let restoreFrame = NSRect(x: petWindow.frame.origin.x,
                                   y: petWindow.frame.origin.y,
                                   width: petSize, height: petSize)
        petWindow.setFrame(restoreFrame, display: false)
        petImageView.frame = NSRect(x: 0, y: 0, width: petSize, height: petSize)
        (petWindow.contentView as? PetView)?.frame = NSRect(x: 0, y: 0, width: petSize, height: petSize)
    }

    func handleMouseUp(_ event: NSEvent) {
        if isDragging {
            isDragging = false

            let screenPoint = NSEvent.mouseLocation
            let moved = abs(screenPoint.x - dragStartScreenPoint.x) + abs(screenPoint.y - dragStartScreenPoint.y)
            if !didDragPet || moved < 5 {
                restoreSquareWindow()
                petTapped()
            } else {
                let dropBubbles = ["Wheee!", "*flop*", "Freedom!", "Whoa!", "Put me down— oh wait!"]
                showBubble(dropBubbles.randomElement()!)
                // Cat falls after being dropped — keep tall window during fall
                if petY > groundYForPet() + 5 {
                    velocityY = 0
                    isOnGround = false
                    isGentleDropping = true
                    gentleDropPhase = 0
                } else {
                    restoreSquareWindow()
                }
            }
        }
    }

    func handleMouseEntered() {
        isHoveringPet = true
        guard !isDragging else { return }
        statsHUD.stats = stats
        statsHUD.showStartTime = Date()
        statsHUD.needsDisplay = true
        statsWindow.orderFront(nil)
    }

    func handleMouseExited() {
        isHoveringPet = false
        statsWindow.orderOut(nil)
    }

    var lastTickleTime = Date.distantPast
    var tickleCount = 0

    func handleScrollWheel(_ event: NSEvent) {
        let scrollMagnitude = abs(event.deltaY) + abs(event.deltaX)
        guard scrollMagnitude > 1 else { return }
        guard !stats.isDead else { return }

        let now = Date()
        if now.timeIntervalSince(lastTickleTime) < 2 {
            tickleCount += 1
        } else {
            tickleCount = 1
        }
        lastTickleTime = now

        // Wiggle the pet
        let wiggle: CGFloat = CGFloat.random(in: -3...3)
        petX += wiggle

        // Emit sparkles
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + CGFloat.random(in: 10...50), y: petSize / 2 + CGFloat.random(in: 0...30)),
            type: .sparkle, count: 2
        )

        if tickleCount == 3 {
            let tickleBubbles = ["Hehehe!", "That tickles!", "*giggles*", "Stoooop!", "Haha!"]
            showBubble(tickleBubbles.randomElement()!)
            stats.happiness = min(100, stats.happiness + 3)
            stats.social = min(100, stats.social + 2)
            SoundEngine.shared.chirp()
            tickleCount = 0
        } else if tickleCount == 1 {
            showBubble("Eep!")
        }
    }

    func handleRightClick(_ event: NSEvent) {
        let menu = NSMenu()

        // Feed submenu
        let feedMenu = NSMenu()
        let f1 = NSMenuItem(title: "\u{1F41F} Fish", action: #selector(feedPet), keyEquivalent: "")
        f1.target = self; feedMenu.addItem(f1)
        let f2 = NSMenuItem(title: "\u{1F95B} Milk", action: #selector(feedMilkAction), keyEquivalent: "")
        f2.target = self; feedMenu.addItem(f2)
        let f3 = NSMenuItem(title: "\u{1F36A} Treat", action: #selector(feedTreatAction), keyEquivalent: "")
        f3.target = self; feedMenu.addItem(f3)
        let feedItem = NSMenuItem(title: "\u{1F356} Feed", action: nil, keyEquivalent: "")
        feedItem.submenu = feedMenu
        menu.addItem(feedItem)

        let playItem = NSMenuItem(title: "\u{1F3AE} Play", action: #selector(playWithPet), keyEquivalent: "")
        playItem.target = self
        menu.addItem(playItem)

        let restItem = NSMenuItem(title: "\u{1F634} Rest", action: #selector(restPet), keyEquivalent: "")
        restItem.target = self
        menu.addItem(restItem)

        let bathItem = NSMenuItem(title: "\u{1F6C1} Bath", action: #selector(bathePet), keyEquivalent: "")
        bathItem.target = self
        menu.addItem(bathItem)

        let walkItem = NSMenuItem(title: "\u{1F6B6} Walk", action: #selector(takeForWalk), keyEquivalent: "")
        walkItem.target = self
        menu.addItem(walkItem)

        if stats.isSick {
            let healItem = NSMenuItem(title: "\u{1F48A} Medicine", action: #selector(healPet), keyEquivalent: "")
            healItem.target = self
            menu.addItem(healItem)
        }

        if stats.poopCount > 0 {
            let cleanItem = NSMenuItem(title: "\u{1F9F9} Clean Poop (\(stats.poopCount))", action: #selector(cleanPoopAction), keyEquivalent: "")
            cleanItem.target = self
            menu.addItem(cleanItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Toys
        let toyMenu = NSMenu()
        let m1 = NSMenuItem(title: "\u{1F401} Mouse Toy", action: #selector(spawnMouseToy), keyEquivalent: "")
        m1.target = self; toyMenu.addItem(m1)
        let m2 = NSMenuItem(title: "\u{1F9F6} Yarn Ball", action: #selector(spawnYarnBall), keyEquivalent: "")
        m2.target = self; toyMenu.addItem(m2)
        let m3 = NSMenuItem(title: "\u{1F534} Laser Dot", action: #selector(spawnLaserDot), keyEquivalent: "")
        m3.target = self; toyMenu.addItem(m3)
        let toyItem = NSMenuItem(title: "\u{1F9F8} Toys", action: nil, keyEquivalent: "")
        toyItem.submenu = toyMenu
        menu.addItem(toyItem)

        // Accessories
        let accMenu = NSMenu()
        let noneAcc = NSMenuItem(title: "None", action: #selector(removeAccessory), keyEquivalent: "")
        noneAcc.target = self; accMenu.addItem(noneAcc)
        for acc in Accessory.available(for: stats.level) {
            let item = NSMenuItem(title: acc.name, action: #selector(equipAccessoryByName(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = acc.name
            accMenu.addItem(item)
        }
        let accItem = NSMenuItem(title: "\u{1F451} Accessories", action: nil, keyEquivalent: "")
        accItem.submenu = accMenu
        menu.addItem(accItem)

        menu.addItem(NSMenuItem.separator())

        let followItem = NSMenuItem(title: followingCursor ? "🛑 Stop Following" : "🐾 Follow Cursor", action: #selector(toggleFollowCursor), keyEquivalent: "")
        followItem.target = self
        menu.addItem(followItem)

        let cameraItem = NSMenuItem(title: "\u{1F4F7} Screenshot", action: #selector(screenshotPet), keyEquivalent: "")
        cameraItem.target = self
        menu.addItem(cameraItem)

        let diaryItem = NSMenuItem(title: "\u{1F4D3} Diary", action: #selector(showDiary), keyEquivalent: "")
        diaryItem.target = self
        menu.addItem(diaryItem)

        let statsItem = NSMenuItem(title: "\u{1F4CA} Stats", action: #selector(showStats), keyEquivalent: "")
        statsItem.target = self
        menu.addItem(statsItem)

        menu.addItem(NSMenuItem.separator())

        let updateItem = NSMenuItem(title: "\u{1F504} Check for Updates", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

        NSMenu.popUpContextMenu(menu, with: event, for: petImageView)
    }
}

// MARK: - Bubble View (custom draw for speech bubble shape)

class BubbleView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 2, dy: 4)
        let bubbleRect = NSRect(x: rect.origin.x, y: rect.origin.y + 6, width: rect.width, height: rect.height - 6)

        // Shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.15)
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        shadow.shadowBlurRadius = 4
        shadow.set()

        // Bubble body
        let path = NSBezierPath(roundedRect: bubbleRect, xRadius: 12, yRadius: 12)
        NSColor(white: 0.97, alpha: 0.95).set()
        path.fill()

        // Border
        NSColor(white: 0.75, alpha: 0.8).set()
        path.lineWidth = 1.2
        path.stroke()

        // Little triangle pointer at bottom
        let triPath = NSBezierPath()
        let cx = bounds.width / 2
        triPath.move(to: NSPoint(x: cx - 6, y: bubbleRect.origin.y))
        triPath.line(to: NSPoint(x: cx, y: bubbleRect.origin.y - 5))
        triPath.line(to: NSPoint(x: cx + 6, y: bubbleRect.origin.y))
        triPath.close()
        NSColor(white: 0.97, alpha: 0.95).set()
        triPath.fill()
        NSColor(white: 0.75, alpha: 0.8).set()
        triPath.lineWidth = 1.2
        triPath.stroke()
    }

    override var isOpaque: Bool { false }
}

// MARK: - Pet View (mouse events)

class PetView: NSView {
    weak var delegate: MurchiDelegate?
    var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseDown(with event: NSEvent) {
        delegate?.handleMouseDown(event)
    }

    override func mouseDragged(with event: NSEvent) {
        delegate?.handleMouseDragged(event)
    }

    override func mouseUp(with event: NSEvent) {
        delegate?.handleMouseUp(event)
    }

    override func rightMouseDown(with event: NSEvent) {
        delegate?.handleRightClick(event)
    }

    override func mouseEntered(with event: NSEvent) {
        delegate?.handleMouseEntered()
    }

    override func mouseExited(with event: NSEvent) {
        delegate?.handleMouseExited()
    }

    override func scrollWheel(with event: NSEvent) {
        delegate?.handleScrollWheel(event)
    }

    override var acceptsFirstResponder: Bool { true }
}

// MARK: - App Entry Point

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = MurchiDelegate()
app.delegate = delegate
app.run()
