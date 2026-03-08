// ═══════════════════════════════════════════════════════════════
// MURCHI — Lottie Animation Integration
// Replaces CGContext-based CatRenderer/BearRenderer with
// GPU-accelerated Lottie vector animations.
// Falls back to CGContext rendering when .json files are missing.
//
// Frame segments in each animation:
//   0-59:   Idle (breathing + blink)
//   60-89:  Walk cycle
//   90-119: Sleeping
// ═══════════════════════════════════════════════════════════════

import AppKit
import Lottie

// MARK: - Animation Segments

/// Frame ranges for different pet states within the Lottie animation
struct AnimSegment {
    let start: CGFloat
    let end: CGFloat

    static let idle    = AnimSegment(start: 0, end: 59)
    static let walk    = AnimSegment(start: 60, end: 89)
    static let sleep   = AnimSegment(start: 90, end: 119)

    // Behaviors that don't have dedicated segments use these fallbacks:
    // sitting → idle (standing still)
    // jumping → uses idle with Y offset handled by physics
    // eating → idle (animation is handled by particles)
}

// MARK: - Lottie Character Manager

/// Manages a LottieAnimationView for rendering a pet character.
/// Provides behavior-to-animation mapping with segment playback.
class LottieCharacterManager {

    /// The Lottie view (NSView on macOS) that renders the animation
    let animationView: LottieAnimationView

    /// Currently playing segment
    private var currentSegment: AnimSegment? = nil

    /// Is the animation flipped (facing left)
    private var isFlipped = false

    /// Try to create a Lottie character. Returns nil if no .json file found.
    init?(characterName: String, frame: NSRect) {
        // Search for the animation JSON file
        var lottieAnimation: LottieAnimation? = nil

        // Try SPM bundle first
        #if SWIFT_PACKAGE
        if let anim = LottieAnimation.named(characterName, bundle: Bundle.module) {
            lottieAnimation = anim
        } else if let anim = LottieAnimation.named("Resources/\(characterName)", bundle: Bundle.module) {
            lottieAnimation = anim
        }
        #endif

        // Try main bundle
        if lottieAnimation == nil {
            if let anim = LottieAnimation.named(characterName, bundle: Bundle.main) {
                lottieAnimation = anim
            }
        }

        // Try loading from file path next to executable
        if lottieAnimation == nil, let execURL = Bundle.main.executableURL {
            let jsonPath = execURL.deletingLastPathComponent()
                .appendingPathComponent("\(characterName).json").path
            lottieAnimation = LottieAnimation.filepath(jsonPath)
        }

        guard let animation = lottieAnimation else {
            return nil
        }

        // Create the LottieAnimationView
        self.animationView = LottieAnimationView(animation: animation)
        self.animationView.frame = frame
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.backgroundBehavior = .pauseAndRestore
        self.animationView.respectAnimationFrameRate = true

        // Transparent background for desktop pet
        self.animationView.wantsLayer = true
        self.animationView.layer?.backgroundColor = NSColor.clear.cgColor

        // Start with idle
        playSegment(.idle, loop: true)

        print("[Lottie] Loaded \(characterName).json animation")
    }

    // MARK: - Segment Playback

    /// Play a specific animation segment
    func playSegment(_ segment: AnimSegment, loop: Bool = true) {
        // Don't restart if already playing this segment
        if let current = currentSegment,
           current.start == segment.start && current.end == segment.end {
            return
        }

        currentSegment = segment
        animationView.play(
            fromFrame: segment.start,
            toFrame: segment.end,
            loopMode: loop ? .loop : .playOnce
        )
    }

    /// Set facing direction (flips the view horizontally)
    func setFacingRight(_ right: Bool) {
        let shouldFlip = !right
        if shouldFlip != isFlipped {
            isFlipped = shouldFlip
            if shouldFlip {
                animationView.layer?.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
            } else {
                animationView.layer?.setAffineTransform(.identity)
            }
        }
    }

    // MARK: - Behavior Mapping

    /// Map current pet behavior to the appropriate animation segment
    func update(behavior: PetBehavior, frame: Int, facingRight: Bool) {
        setFacingRight(facingRight)

        switch behavior {
        case .sleeping:
            playSegment(.sleep, loop: true)

        case .walking, .running, .chasingCursor, .chasingToy, .zoomies,
             .chasingButterfly, .promenade, .edgeWalking, .knockingGlass:
            playSegment(.walk, loop: true)

        case .idle, .sitting, .watchingBird, .eating, .beingPet,
             .greeting, .playing, .jumping, .stretching, .tripping,
             .grooming, .bathing, .scratching, .pooping, .sick,
             .openingGift, .lookingAtCursor, .dancing, .hatingMusic:
            playSegment(.idle, loop: true)
        }
    }

    /// Set animation speed (1.0 = normal, 2.0 = double speed)
    func setSpeed(_ speed: CGFloat) {
        animationView.animationSpeed = speed
    }
}

// MARK: - Lottie Availability Check

func isLottieAvailable(for petType: String) -> Bool {
    // Check SPM bundle
    #if SWIFT_PACKAGE
    if LottieAnimation.named(petType, bundle: Bundle.module) != nil { return true }
    if LottieAnimation.named("Resources/\(petType)", bundle: Bundle.module) != nil { return true }
    #endif

    // Check main bundle
    if LottieAnimation.named(petType, bundle: Bundle.main) != nil { return true }

    // Check next to executable
    if let execURL = Bundle.main.executableURL {
        let jsonPath = execURL.deletingLastPathComponent()
            .appendingPathComponent("\(petType).json").path
        return FileManager.default.fileExists(atPath: jsonPath)
    }
    return false
}
