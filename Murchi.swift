import AppKit
import Foundation
import AVFoundation
import Carbon.HIToolbox
import UserNotifications

// ═══════════════════════════════════════════════════════════════
// MURCHI — Desktop Tamagotchi Cat for macOS
// A pixel-art cat that lives on your desktop, walks around,
// reacts to you, and needs love & care.
// ═══════════════════════════════════════════════════════════════

// MARK: - Pixel Sprite Data

struct Sprites {
    static let T: UInt32 = 0 // transparent

    // ── Color palette ──
    // B=outline, G=gray body, GD=darker gray, W=white, P=pink
    // GR=green eyes, Y=yellow collar, BL=blue bell

    // Walk frame 1 — standing, tail up
    static let walk1: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,G,G,G,W,W,G,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,B,T,T,T,T,T,T,B,B,T,T,T],
            [T,T,T,B,W,B,T,T,T,T,B,W,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,B,G,GD,B],
        ]
    }()

    // Walk frame 2 — legs swapped, tail other side
    static let walk2: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,GR,B,G,G,G,G,B,GR,G,G,B,T],
            [T,B,G,G,GR,B,G,G,G,G,B,GR,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,G,G,G,W,W,G,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,T,B,B,T,T,T,B,B,T,T,T,T,T],
            [T,T,T,T,B,W,B,T,B,W,B,T,T,T,T,T],
            [B,GD,G,B,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Sit — compact pose
    static let sit: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,G,G,G,W,W,G,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,W,W,G,G,G,G,G,G,W,W,B,T,T],
            [T,T,T,B,B,B,B,B,B,B,B,B,B,T,T,T],
            [T,B,G,GD,G,B,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Sleep — curled up ball with Zzz
    static let sleep1: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, P: UInt32 = 0xFFAABB, Z: UInt32 = 0x88AAFF
        return [
            [T,T,T,T,T,T,T,T,T,T,T,T,Z,Z,Z,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,Z,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,Z,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,Z,Z,Z,T],
            [T,T,B,B,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,B,G,G,B,B,B,B,B,B,B,B,T,T,T,T],
            [T,B,G,B,B,G,G,G,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,P,P,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,B,B,B,B,B,B,B,B,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Sleep frame 2 — Zzz shifted
    static let sleep2: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, P: UInt32 = 0xFFAABB, Z: UInt32 = 0x88AAFF
        return [
            [T,T,T,T,T,T,T,T,T,T,T,T,T,Z,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,Z,Z,Z,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,Z,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,Z,T,T],
            [T,T,B,B,T,T,T,T,T,T,T,T,Z,Z,Z,T],
            [T,B,G,G,B,B,B,B,B,B,B,B,T,T,T,T],
            [T,B,G,B,B,G,G,G,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,P,P,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,B,B,B,B,B,B,B,B,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Blink
    static let blink: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,B,B,G,G,G,G,B,B,G,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,G,G,G,W,W,G,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,B,T,T,T,T,T,T,B,B,T,T,T],
            [T,T,T,B,W,B,T,T,T,T,B,W,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,B,G,GD,B],
        ]
    }()

    // Happy — ^_^ eyes, big smile
    static let happy: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,T,B,G,G,G,G,B,T,G,G,B,T],
            [T,B,G,G,B,T,G,G,G,G,T,B,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,B,B,B,B,B,B,G,G,B,T,T],
            [T,T,T,B,G,G,G,W,W,G,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,B,T,T,T,T,T,T,B,B,T,T,T],
            [T,T,T,B,W,B,T,T,T,T,B,W,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,B,G,GD,B],
        ]
    }()

    // Sad — droopy eyes, tears
    static let sad: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF, BK: UInt32 = 0x5599DD
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,T,B,G,BK,G,G,W,W,G,G,BK,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,G,G,B,B,B,B,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,B,T,T,T,T,T,T,B,B,T,T,T],
            [T,T,T,B,W,B,T,T,T,T,B,W,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Eating — mouth open with food
    static let eating: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF, F: UInt32 = 0xFF6B6B
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,B,F,F,B,G,G,G,B,T,T],
            [T,T,T,B,G,G,B,F,F,B,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,B,T,T,T,T,T,T,B,B,T,T,T],
            [T,T,T,B,W,B,T,T,T,T,B,W,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Jump
    static let jump: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,Y,Y,Y,Y,Y,Y,Y,Y,B,T,T,T],
            [T,T,B,G,G,G,G,BL,G,G,G,G,G,B,T,T],
            [T,B,W,B,G,G,G,G,G,G,G,G,B,W,B,T],
            [T,T,B,B,G,G,G,G,G,G,G,G,B,B,T,T],
            [T,T,T,T,B,B,B,B,B,B,B,B,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Love — hearts around
    static let love: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, H: UInt32 = 0xFF4466
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,H,H,T,T,T,T,T,T,T,T,T,T,H,H,T],
            [H,H,H,H,T,T,T,T,T,T,T,T,H,H,H,H],
            [T,H,H,B,B,T,T,T,T,T,T,B,B,H,H,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,T,B,G,G,G,G,B,T,G,G,B,T],
            [T,B,G,G,B,T,G,G,G,G,T,B,G,G,B,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,Y,Y,Y,Y,Y,Y,Y,Y,B,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,B,T,T,T,T,T,T,B,B,T,T,T],
            [T,T,T,B,W,B,T,T,T,T,B,W,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,B,G,GD,B],
        ]
    }()

    // Stretch/yawn
    static let stretch: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,B,B,G,G,G,G,B,B,G,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,T,B,G,G,G,B,B,B,B,G,G,G,B,T,T],
            [T,T,B,G,G,B,P,P,P,P,B,G,G,B,T,T],
            [T,T,T,B,G,G,B,B,B,B,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,B,W,B,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,T,T,T,T,T,T,T,T,B,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,B,W,B,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,B,G,GD,B],
        ]
    }()

    // Trip/fall with stars
    static let trip: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, S: UInt32 = 0xFFDD44
        let Y: UInt32 = 0xFFD700
        return [
            [T,T,T,T,T,T,T,T,T,T,S,T,T,S,T,T],
            [T,T,T,T,T,T,T,T,T,S,T,S,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,S,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,B,B,T,T,T,T,B,B,T,T],
            [T,T,T,T,T,B,G,G,B,T,T,B,G,G,B,T],
            [T,T,T,T,T,B,G,P,G,B,B,G,P,G,B,T],
            [T,T,T,T,T,B,G,G,G,G,G,G,G,G,B,T],
            [T,T,T,T,T,B,G,B,B,G,G,B,B,G,B,T],
            [T,T,T,T,T,B,G,B,B,G,G,B,B,G,B,T],
            [T,T,T,T,T,T,B,G,G,W,W,G,G,B,T,T],
            [T,T,T,T,T,T,B,G,W,P,P,W,G,B,T,T],
            [T,T,B,B,B,T,T,B,Y,Y,Y,Y,B,T,T,T],
            [T,B,G,G,G,B,B,G,G,G,G,G,G,B,T,T],
            [T,B,W,W,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,T,B,B,B,B,B,B,B,B,B,B,B,B,T,T],
        ]
    }()

    // Look right
    static let lookRight: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,G,B,GR,G,G,G,B,GR,G,G,B,T],
            [T,B,G,G,G,B,GR,G,G,G,B,GR,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,G,G,G,W,W,G,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,B,T,T,T,T,T,T,B,B,T,T,T],
            [T,T,T,B,W,B,T,T,T,T,B,W,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,B,G,GD,B],
        ]
    }()

    static let lookLeft: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,GR,B,G,G,G,GR,B,G,G,G,B,T],
            [T,B,G,G,GR,B,G,G,G,GR,B,G,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,G,G,G,W,W,G,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,B,T,T,T,T,T,T,B,B,T,T,T],
            [T,T,T,B,W,B,T,T,T,T,B,W,B,T,T,T],
            [B,GD,G,B,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Lick paw — grooming animation
    static let lickPaw: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,B,B,G,G,G,G,GR,B,G,G,B,T],  // one eye closed
            [T,B,G,G,G,G,G,G,G,G,GR,B,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,G,G,G,W,W,G,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,B,W,G,G,G,BL,G,G,G,G,B,T,T,T],  // paw up to face
            [T,T,B,W,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,B,T,T,T,T,T,T,B,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,B,W,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,B,G,GD,B],
        ]
    }()

    // Run frame 1 — fast walk, body stretched
    static let run1: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,Y,Y,Y,Y,Y,Y,Y,Y,B,T,T,T],
            [T,T,B,G,G,G,G,BL,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,B,W,T,T,B,G,G,G,G,B,T,T,W,B,T],  // legs spread wide
            [T,T,B,T,T,T,B,B,B,B,T,T,T,B,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Run frame 2 — legs together
    static let run2: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,GR,B,G,G,G,G,B,GR,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,Y,Y,Y,Y,Y,Y,Y,Y,B,T,T,T],
            [T,T,B,G,G,G,G,BL,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,T,T,B,W,B,B,W,B,T,T,T,T,T],  // legs together
            [T,T,T,T,T,T,B,T,T,B,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Poop sprite
    static let poop: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x3B2714
        let P: UInt32 = 0x8B6914, L: UInt32 = 0xA0822A, S: UInt32 = 0x6B9B3A
        return [
            [T,T,T,T,T,S,T,T,S,T,T,T],
            [T,T,T,T,S,T,T,S,T,T,T,T],
            [T,T,T,T,T,B,B,T,T,T,T,T],
            [T,T,T,T,B,L,L,B,T,T,T,T],
            [T,T,T,T,T,B,B,T,T,T,T,T],
            [T,T,T,B,B,P,P,B,B,T,T,T],
            [T,T,B,L,P,P,P,P,L,B,T,T],
            [T,T,B,P,P,P,P,P,P,B,T,T],
            [T,B,L,P,P,P,P,P,P,L,B,T],
            [T,B,P,P,P,P,P,P,P,P,B,T],
            [T,T,B,B,B,B,B,B,B,B,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Sick — spiral eyes, droopy
    static let sick: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B9B70, GD: UInt32 = 0x7A8A60, W: UInt32 = 0xE8E8F0  // greenish body
        let P: UInt32 = 0xDDAA99, SP: UInt32 = 0xAA55AA  // spiral eyes
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,SP,SP,G,G,G,SP,SP,G,G,G,B,T],
            [T,B,G,G,SP,B,SP,G,SP,B,SP,G,G,G,B,T],
            [T,T,B,G,G,SP,G,W,W,G,SP,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,G,G,W,W,W,W,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,Y,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,T,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,T],
            [T,T,T,B,GD,B,T,T,T,T,B,GD,B,T,T],
            [T,T,T,T,B,T,T,T,T,T,T,T,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Bath — cat with bubbles
    static let bath: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let BU: UInt32 = 0xAADDFF, BL: UInt32 = 0x88CCEE  // bubbles
        let WA: UInt32 = 0x6699CC  // water
        return [
            [T,T,B,B,T,BU,T,T,BU,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,BU,T,T,BU,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,B,G,G,W,W,G,G,G,G,W,W,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [BU,T,T,B,G,G,G,G,G,G,G,G,B,T,T,BU],
            [T,B,B,B,B,B,B,B,B,B,B,B,B,B,B,T],
            [B,WA,WA,WA,WA,WA,WA,WA,WA,WA,WA,WA,WA,WA,WA,B],
            [B,WA,BL,WA,WA,WA,BL,WA,WA,BL,WA,WA,WA,BL,WA,B],
            [B,WA,WA,WA,BL,WA,WA,WA,WA,WA,WA,BL,WA,WA,WA,B],
            [B,WA,WA,WA,WA,WA,WA,WA,WA,WA,WA,WA,WA,WA,WA,B],
            [T,B,B,B,B,B,B,B,B,B,B,B,B,B,B,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Walking with leash — promenade mode
    static let walkLeash: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let G: UInt32 = 0x8B8BA0, GD: UInt32 = 0x6E6E85, W: UInt32 = 0xE8E8F0
        let P: UInt32 = 0xFFAABB, GR: UInt32 = 0x7BCE7B
        let Y: UInt32 = 0xFFD700, BL: UInt32 = 0x4488FF
        let R: UInt32 = 0xFF4444  // leash
        return [
            [T,T,B,B,T,T,T,T,T,T,T,T,B,B,T,T],
            [T,B,G,G,B,T,T,T,T,T,T,B,G,G,B,T],
            [T,B,G,P,G,B,B,B,B,B,B,G,P,G,B,T],
            [T,B,G,G,G,G,G,G,G,G,G,G,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,B,G,G,B,GR,G,G,G,G,GR,B,G,G,B,T],
            [T,T,B,G,G,G,G,W,W,G,G,G,G,B,T,T],
            [T,T,B,G,G,G,W,P,P,W,G,G,G,B,T,T],
            [T,T,T,B,G,G,G,W,W,G,G,G,B,T,T,T],
            [T,T,T,T,B,Y,Y,R,Y,Y,Y,B,T,T,T,T],
            [T,T,T,B,G,G,G,BL,G,G,G,G,B,R,T,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,R,T],
            [T,T,B,G,G,G,G,G,G,G,G,G,G,B,T,R],
            [T,T,T,B,B,T,T,T,T,T,T,B,B,T,T,R],
            [T,T,T,B,W,B,T,T,T,T,B,W,B,T,T,R],
            [T,T,T,T,T,T,T,T,T,T,T,T,B,G,GD,B],
        ]
    }()

    // Medicine pill
    static let medicine: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let W: UInt32 = 0xF0F0F8, R: UInt32 = 0xFF5555, P: UInt32 = 0xFF88AA
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

    // Milk bowl
    static let milk: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let W: UInt32 = 0xF5F5FF, M: UInt32 = 0xFFFDE8
        let BW: UInt32 = 0xCC4444  // bowl red
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

    // Treat / cookie
    static let treat: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let C: UInt32 = 0xDDA860, CD: UInt32 = 0xBB8840  // cookie
        let CH: UInt32 = 0x553322  // chocolate chip
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

    // Fish food item
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

    // Butterfly — cute little pixel butterfly
    static let butterfly1: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let M: UInt32 = 0xFF88DD, L: UInt32 = 0xFFAAEE  // magenta wings
        let O: UInt32 = 0xFFAA44  // orange accent
        let W: UInt32 = 0xFFFFFF
        return [
            [T,T,T,T,T,T,T,T],
            [T,M,T,T,T,T,M,T],
            [M,L,M,T,T,M,L,M],
            [M,W,L,B,B,L,W,M],
            [M,O,M,B,B,M,O,M],
            [T,M,T,B,B,T,M,T],
            [T,T,T,T,B,T,T,T],
            [T,T,T,T,T,T,T,T],
        ]
    }()

    static let butterfly2: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let M: UInt32 = 0xFF88DD, L: UInt32 = 0xFFAAEE
        return [
            [T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T],
            [T,M,T,T,T,T,M,T],
            [T,L,M,B,B,M,L,T],
            [T,M,T,B,B,T,M,T],
            [T,T,T,B,B,T,T,T],
            [T,T,T,T,B,T,T,T],
            [T,T,T,T,T,T,T,T],
        ]
    }()

    // Bird visitor
    static let bird: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let R: UInt32 = 0xFF6644  // robin breast
        let BR: UInt32 = 0x886644  // brown
        let W: UInt32 = 0xFFFFFF, Y: UInt32 = 0xFFCC00
        return [
            [T,T,T,T,T,T,T,T],
            [T,T,T,B,B,T,T,T],
            [T,T,B,BR,BR,B,T,T],
            [T,B,BR,W,BR,BR,B,T],
            [B,BR,R,R,R,BR,T,T],
            [T,B,R,R,R,B,T,T],
            [T,T,B,B,B,T,T,T],
            [T,T,B,T,B,T,T,T],
        ]
    }()

    // Gift box
    static let gift: [[UInt32]] = {
        let T: UInt32 = 0, B: UInt32 = 0x2D2D3F
        let R: UInt32 = 0xFF4466, RD: UInt32 = 0xDD3355
        let Y: UInt32 = 0xFFDD44, S: UInt32 = 0xFFEE88  // star sparkle
        return [
            [T,T,T,S,T,T,T,T,T,T],
            [T,T,T,T,S,T,T,T,T,T],
            [T,T,B,B,Y,B,B,T,T,T],
            [T,B,R,R,Y,R,R,B,T,T],
            [T,B,R,R,Y,R,R,B,T,T],
            [T,B,Y,Y,Y,Y,Y,B,T,T],
            [T,B,RD,RD,Y,RD,RD,B,T,T],
            [T,B,RD,RD,Y,RD,RD,B,T,T],
            [T,T,B,B,B,B,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T],
        ]
    }()

    // Paw print (tiny)
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

    // Glass/mug that cat knocks off
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

    // Render pixel sprite to NSImage
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

    // Render mirrored (facing left)
    static func renderMirrored(_ sprite: [[UInt32]], scale: Int = 5) -> NSImage {
        let mirrored = sprite.map { Array($0.reversed()) }
        return render(mirrored, scale: scale)
    }
}

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
        case heart, star, sparkle, note, poof
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
            }
            particles.append(Particle(
                x: point.x + CGFloat.random(in: -10...10),
                y: point.y + CGFloat.random(in: -5...15),
                vx: cos(angle) * speed,
                vy: sin(angle) * speed + 2,  // upward bias
                life: 1.0,
                decay: CGFloat.random(in: 0.015...0.035),
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
            particles[i].vy -= 0.05  // gravity
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
}

// MARK: - Speech Bubbles

struct SpeechBubbles {
    static let idle = ["...", "*purrrr*", "*licks paw*", "*looks around*", "*tail swish*"]

    static let happy = [
        "Mrrrow~!", "You're the best!", "I love you!", "*purrs loudly*",
        "Best human ever!", "Play with me!", "Life is good~",
        "*happy chirp*", "Meow meow!", "Feeling great!",
    ]

    static let neutral = [
        "Meow.", "*yawn*", "Hey there.", "*stretches*", "Hm...",
        "What's up?", "*stares*", "Feed me?", "Bored...",
    ]

    static let sad = [
        "I'm hungry...", "I'm lonely...", "Pay attention to me...",
        "*sad meow*", "Don't forget me...", "I'm not okay...",
        "*whimpers*", "Why so long...", "Miss you...",
    ]

    static let sleepy = [
        "So tired...", "*yawn*", "zzz...", "Sleepy...",
        "Five more minutes...", "*nods off*", "Need nap...",
    ]

    static let eating = [
        "Nom nom nom!", "Yummy!", "Mmmm fish!", "*happy munching*",
        "SO GOOD!", "*crunch crunch*", "More please!",
    ]

    static let petted = [
        "*PURRRR*", "More pets please!", "Right there!",
        "I love scratches!", "Mrrrow~", "Don't stop!",
        "*melts*", "Purrfect~", "Yes yes yes!",
    ]

    static let greeting = [
        "You're back!!!", "I missed you!", "FINALLY!",
        "Where were you?!", "Meow meow meow!", "DON'T LEAVE AGAIN!",
        "*runs in circles*", "SO HAPPY!",
    ]

    static let morning = ["Good morning!", "Rise and shine!", "New day, new naps!", "Breakfast time!"]
    static let evening = ["Good evening~", "Cozy time!", "Getting sleepy...", "Dinner?"]
    static let lateNight = ["Go to sleep...", "It's so late...", "zzz... you too...", "Bed time?"]

    static let playing = [
        "Wheee!", "Catch me!", "So fun!", "*zoomies*",
        "FASTER!", "Can't catch me!", "*pounce*",
    ]

    static let grooming = [
        "*lick lick*", "Must stay clean!", "Looking good~",
        "*grooms fur*", "Purrfect fur!",
    ]

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

    static let bathBubbles = [
        "*splash splash*", "Water! Nooo!", "I hate baths!",
        "Okay... it's warm...", "*bubbles*", "Almost done?",
    ]

    static let promenadeBubbles = [
        "Nice walk!", "Fresh air!", "Adventure!",
        "Look, a bird!", "Exploring!", "This is fun!",
        "New smells!", "What's over there?",
    ]

    static let healBubbles = [
        "Medicine time... *gulp*", "I feel better!",
        "Thank you doctor!", "Bleh, but it helps!",
    ]

    static let milkBubbles = [
        "Milk! Yummy!", "*lap lap lap*", "Creamy!",
        "Mmmm warm milk~",
    ]

    static let treatBubbles = [
        "A TREAT!", "Yay cookies!", "SO TASTY!",
        "*happy crunch*", "Best snack ever!",
    ]

    static let butterflyBubbles = [
        "A butterfly!!", "Must catch!!", "*wiggles butt*",
        "Come here little friend!", "SO PRETTY!",
    ]

    static let birdBubbles = [
        "*stares at bird*", "Chirp?", "Must... not... pounce...",
        "*intense staring*", "*tail twitching*", "Birdie!",
    ]

    static let giftBubbles = [
        "A PRESENT!!", "What's inside?!", "For ME?!",
        "Best day ever!", "Yay yay yay!!",
    ]

    static let knockBubbles = [
        "*eyes glass*", "Should I...?", "*boop*",
        "Oops! *innocent face*", "It was like that!",
        "*pushes slowly*", "Physics experiment!",
    ]

    static func forMood(_ mood: PetStats.Mood) -> [String] {
        switch mood {
        case .happy: return happy
        case .neutral: return neutral
        case .sad: return sad
        case .sleepy: return sleepy
        case .sick: return sickBubbles
        }
    }

    static let zoomies = [
        "*NYOOOM*", "CAN'T STOP!", "ZOOOOM!", "*crashes into wall*",
        "MAXIMUM SPEED!", "Turbo mode!", "WHEEEEE!",
    ]

    static let scratching = [
        "*scratch scratch*", "Gotta sharpen!", "My claws~",
        "*shreds everything*", "DESTROY!",
    ]

    static let chasingToy = [
        "MOUSE!", "I'll get it!", "Come here!", "*pounce!*",
        "Almost got it!", "MINE!", "So fast!",
    ]

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
    let sprite: [[UInt32]]  // overlay sprite

    // Hat — yellow party hat
    static let partyHat: Accessory = {
        let T: UInt32 = 0, Y: UInt32 = 0xFFD700, R: UInt32 = 0xFF4444, B: UInt32 = 0x2D2D3F
        let sprite: [[UInt32]] = [
            [T,T,T,T,T,T,T,R,R,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,R,Y,Y,R,T,T,T,T,T,T],
            [T,T,T,T,T,R,Y,Y,Y,Y,R,T,T,T,T,T],
            [T,T,T,T,R,Y,Y,Y,Y,Y,Y,R,T,T,T,T],
            [T,T,T,R,Y,Y,Y,Y,Y,Y,Y,Y,R,T,T,T],
            [T,T,T,B,B,B,B,B,B,B,B,B,B,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
        return Accessory(name: "\u{1F389} Party Hat", minLevel: 1, sprite: sprite)
    }()

    // Bow tie — red
    static let bowTie: Accessory = {
        let T: UInt32 = 0, R: UInt32 = 0xFF3355, RD: UInt32 = 0xCC2244, B: UInt32 = 0x2D2D3F
        let sprite: [[UInt32]] = [
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,R,R,T,T,B,B,T,T,R,R,T,T,T],  // bow at collar
            [T,T,R,R,RD,R,B,RD,RD,B,R,RD,R,R,T,T],
            [T,T,T,R,R,T,T,B,B,T,T,R,R,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
        return Accessory(name: "\u{1F380} Bow Tie", minLevel: 2, sprite: sprite)
    }()

    // Crown — gold
    static let crown: Accessory = {
        let T: UInt32 = 0, Y: UInt32 = 0xFFD700, YD: UInt32 = 0xDDB800, R: UInt32 = 0xFF4444, B: UInt32 = 0x2D2D3F
        let sprite: [[UInt32]] = [
            [T,T,T,Y,T,T,T,Y,T,T,T,Y,T,T,T,T],
            [T,T,T,Y,Y,T,T,Y,T,T,Y,Y,T,T,T,T],
            [T,T,T,Y,Y,Y,Y,Y,Y,Y,Y,Y,T,T,T,T],
            [T,T,T,YD,R,YD,YD,R,YD,YD,R,YD,T,T,T,T],
            [T,T,T,B,B,B,B,B,B,B,B,B,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
        return Accessory(name: "\u{1F451} Crown", minLevel: 5, sprite: sprite)
    }()

    // Sunglasses
    static let sunglasses: Accessory = {
        let T: UInt32 = 0, B: UInt32 = 0x1A1A2E, G: UInt32 = 0x222244, R: UInt32 = 0x333355
        let sprite: [[UInt32]] = [
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,B,B,B,B,B,B,B,B,B,B,B,B,T,T],
            [T,T,B,G,G,B,B,B,B,B,B,G,G,B,T,T],
            [T,T,B,B,B,B,T,T,T,T,B,B,B,B,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
        return Accessory(name: "\u{1F576} Sunglasses", minLevel: 3, sprite: sprite)
    }()

    // Halo — for cosmic level
    static let halo: Accessory = {
        let T: UInt32 = 0, H: UInt32 = 0xFFEE88, HG: UInt32 = 0xFFDD44
        let sprite: [[UInt32]] = [
            [T,T,T,T,HG,HG,HG,HG,HG,HG,HG,T,T,T,T,T],
            [T,T,T,HG,H,H,H,H,H,H,H,HG,T,T,T,T],
            [T,T,T,T,HG,HG,HG,HG,HG,HG,HG,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
            [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        ]
        return Accessory(name: "\u{1F607} Halo", minLevel: 10, sprite: sprite)
    }()

    static let all: [Accessory] = [partyHat, bowTie, sunglasses, crown, halo]

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
    var behavior: PetBehavior = .idle
    var facingRight = true
    var animFrame = 0
    var petX: CGFloat = 400
    var petY: CGFloat = 100
    var walkTargetX: CGFloat? = nil
    var isDragging = false
    var dragOffset: NSPoint = .zero
    var lastDecay = Date()
    var lastBubble = Date()
    var bubbleHideTime: Date? = nil
    var behaviorDuration: TimeInterval = 0
    var behaviorStartTime = Date()
    var jumpBaseY: CGFloat = 100
    var isHoveringPet = false
    var lastLevel = 1
    var clickCount = 0
    var lastClickTime = Date()
    var breathOffset: CGFloat = 0  // idle breathing animation

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
    var giftWindow: NSPanel?
    var giftPos: NSPoint = .zero
    var pawPrintWindows: [NSPanel] = []
    var pawPrintTimers: [Timer] = []
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

        // Use visibleFrame to detect Dock — most reliable method
        guard let screen = NSScreen.main else {
            if cachedDockRect != .zero { return cachedDockRect }
            return .zero
        }
        let dockH = screen.visibleFrame.origin.y - screen.frame.origin.y
        if dockH > 4 {
            // Dock takes full screen width, cat can walk across it
            cachedDockRect = NSRect(x: screen.frame.minX, y: 0, width: screen.frame.width, height: dockH)
            return cachedDockRect
        }
        // Dock might be hidden or on the side
        if cachedDockRect != .zero { return cachedDockRect }
        return .zero
    }

    func groundYForPet() -> CGFloat {
        let dock = dockRect
        guard dock.height > 4 else { return floorY }
        // Cat walks on top of the Dock — add offset so cat is above icons
        let dockTop = dock.maxY + 8
        return min(dockTop, 200)
    }
    var velocityY: CGFloat = 0
    var isOnGround = true

    // Status bar
    var statusBarItem: NSStatusItem!

    // Sprite cache
    var spriteCache: [String: NSImage] = [:]

    // Screen bounds
    var screenW: CGFloat { NSScreen.main?.frame.width ?? 1440 }
    var screenH: CGFloat { NSScreen.main?.frame.height ?? 900 }

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
            showBubble(SpeechBubbles.greeting.randomElement()!)
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
            spawnPoopWindow(at: CGFloat.random(in: 50...(screenW - 80)))
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

        let aboutItem = NSMenuItem(title: "About Murchi", action: nil, keyEquivalent: "")
        aboutItem.attributedTitle = NSAttributedString(
            string: "Murchi v2.0 \u{00A9} 2026 murchi.pet",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]
        )
        menu.addItem(aboutItem)

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
        accessoryImageView.imageScaling = .scaleProportionallyUpOrDown
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

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendNotification(title: String, body: String) {
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
            accessoryCache[key] = Sprites.render(acc.sprite)
        }
        accessoryImageView.image = accessoryCache[key]
        accessoryWindow.setFrameOrigin(NSPoint(x: petX, y: petY))
        accessoryWindow.orderFront(nil)
    }

    @objc func openWebsite() {
        NSWorkspace.shared.open(URL(string: "https://murchi.pet")!)
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

        // Draw toy
        let toyImg = NSImage(size: NSSize(width: toySize, height: toySize))
        toyImg.lockFocus()
        switch type {
        case .mouseToy:
            NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1).set()
            NSBezierPath(ovalIn: NSRect(x: 5, y: 8, width: 20, height: 14)).fill()
            NSColor(red: 0.7, green: 0.4, blue: 0.4, alpha: 1).set()
            NSBezierPath(ovalIn: NSRect(x: 18, y: 16, width: 8, height: 8)).fill()
            NSBezierPath(ovalIn: NSRect(x: 18, y: 8, width: 8, height: 8)).fill()
            NSColor(red: 0.8, green: 0.5, blue: 0.5, alpha: 1).set()
            let tail = NSBezierPath()
            tail.move(to: NSPoint(x: 5, y: 15))
            tail.curve(to: NSPoint(x: 0, y: 25), controlPoint1: NSPoint(x: 2, y: 18), controlPoint2: NSPoint(x: -2, y: 22))
            tail.lineWidth = 2
            tail.stroke()
        case .yarnBall:
            NSColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1).set()
            NSBezierPath(ovalIn: NSRect(x: 3, y: 3, width: 24, height: 24)).fill()
            NSColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1).set()
            let yarn = NSBezierPath()
            yarn.move(to: NSPoint(x: 8, y: 15))
            yarn.curve(to: NSPoint(x: 22, y: 15), controlPoint1: NSPoint(x: 12, y: 25), controlPoint2: NSPoint(x: 18, y: 5))
            yarn.lineWidth = 1.5
            yarn.stroke()
        case .laserDot:
            NSColor(red: 1, green: 0, blue: 0, alpha: 0.9).set()
            NSBezierPath(ovalIn: NSRect(x: 10, y: 10, width: 10, height: 10)).fill()
            NSColor(red: 1, green: 0.3, blue: 0.3, alpha: 0.4).set()
            NSBezierPath(ovalIn: NSRect(x: 5, y: 5, width: 20, height: 20)).fill()
        }
        toyImg.unlockFocus()
        toyImageView?.image = toyImg

        toyWindow!.setFrameOrigin(NSPoint(x: tx, y: ty))
        toyWindow!.orderFront(nil)

        startBehavior(.chasingToy, duration: 8.0)
        showBubble(SpeechBubbles.chasingToy.randomElement()!)
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
        let key = "\(behavior.rawValue)_\(frame % 16)_\(right)"
        if behavior != .lookingAtCursor, let cached = spriteCache[key] { return cached }

        let spriteData: [[UInt32]]
        switch behavior {
        case .walking:
            spriteData = frame % 2 == 0 ? Sprites.walk1 : Sprites.walk2
        case .running, .chasingCursor, .chasingToy, .zoomies:
            spriteData = frame % 2 == 0 ? Sprites.run1 : Sprites.run2
        case .sitting:
            spriteData = Sprites.sit
        case .sleeping:
            spriteData = frame % 2 == 0 ? Sprites.sleep1 : Sprites.sleep2
        case .eating:
            spriteData = Sprites.eating
        case .beingPet, .greeting:
            spriteData = Sprites.love
        case .playing:
            spriteData = frame % 3 == 0 ? Sprites.happy : (frame % 3 == 1 ? Sprites.jump : Sprites.happy)
        case .jumping:
            spriteData = Sprites.jump
        case .stretching:
            spriteData = Sprites.stretch
        case .tripping:
            spriteData = Sprites.trip
        case .grooming:
            spriteData = Sprites.lickPaw
        case .scratching:
            spriteData = frame % 2 == 0 ? Sprites.stretch : Sprites.lickPaw
        case .edgeWalking:
            spriteData = frame % 2 == 0 ? Sprites.walk1 : Sprites.walk2
        case .pooping:
            spriteData = Sprites.sit  // sitting while pooping
        case .sick:
            spriteData = Sprites.sick
        case .bathing:
            spriteData = Sprites.bath
        case .promenade:
            spriteData = frame % 2 == 0 ? Sprites.walkLeash : Sprites.walk2
        case .chasingButterfly:
            spriteData = frame % 2 == 0 ? Sprites.run1 : Sprites.run2
        case .watchingBird:
            spriteData = Sprites.sit  // sitting and watching
        case .knockingGlass:
            spriteData = frame % 2 == 0 ? Sprites.walk1 : Sprites.walk2
        case .openingGift:
            spriteData = frame % 3 == 0 ? Sprites.happy : Sprites.jump
        case .lookingAtCursor:
            let mousePos = NSEvent.mouseLocation
            if mousePos.x > petX + petSize / 2 {
                return Sprites.render(Sprites.lookRight)
            } else {
                return Sprites.render(Sprites.lookLeft)
            }
        case .idle:
            if frame % 12 == 0 {
                spriteData = Sprites.blink
            } else {
                spriteData = Sprites.walk1
            }
        }

        let img = right ? Sprites.render(spriteData) : Sprites.renderMirrored(spriteData)
        spriteCache[key] = img
        return img
    }

    // MARK: - Timers

    func startTimers() {
        // Main update loop — 15fps
        Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in
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
        let delay = TimeInterval.random(in: 25...70)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            if self.behavior != .sleeping {
                let msgs = SpeechBubbles.forMood(self.stats.mood)
                if let msg = msgs.randomElement() {
                    self.showBubble(msg)
                }
            }
            self.scheduleRandomSpeech()
        }
    }

    func scheduleRandomBehavior() {
        let delay = TimeInterval.random(in: 4...12)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            if !self.isDragging && self.behavior != .eating && self.behavior != .beingPet && self.behavior != .pooping && self.behavior != .chasingToy {
                self.pickRandomBehavior()
            }
            self.scheduleRandomBehavior()
        }
    }

    func pickRandomBehavior() {
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
            showBubble(SpeechBubbles.grooming.randomElement()!)
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
                (.zoomies, 5), (.scratching, 4), (.edgeWalking, 5),
            ]
        case .neutral:
            options = [
                (.walking, 18), (.sitting, 22), (.idle, 18),
                (.lookingAtCursor, 12), (.stretching, 10),
                (.sleeping, 5), (.grooming, 8), (.tripping, 4), (.running, 3),
            ]
        case .sad:
            options = [
                (.sitting, 28), (.idle, 22), (.sleeping, 18),
                (.walking, 10), (.lookingAtCursor, 10), (.tripping, 7), (.grooming, 5),
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
                case .jumping: dur = 1.2
                case .stretching: dur = 2.5
                case .tripping: dur = 2.5
                case .lookingAtCursor: dur = .random(in: 2...6)
                case .playing: dur = .random(in: 3...6)
                case .grooming: dur = .random(in: 3...6)
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
            walkTargetX = CGFloat.random(in: 50...(screenW - 50))
            facingRight = (walkTargetX ?? petX) > petX
        case .running:
            walkTargetX = CGFloat.random(in: 50...(screenW - 50))
            facingRight = (walkTargetX ?? petX) > petX
        case .chasingCursor:
            facingRight = NSEvent.mouseLocation.x > petX
        case .jumping:
            jumpBaseY = petY
            velocityY = 8
            isOnGround = false
        case .tripping:
            showBubble("Oops!")
        case .playing:
            if Int.random(in: 0...2) == 0 {
                showBubble(SpeechBubbles.playing.randomElement()!)
            }
        case .zoomies:
            zoomiesDirection = Bool.random() ? 1 : -1
            zoomiesBounces = 0
            facingRight = zoomiesDirection > 0
            showBubble(SpeechBubbles.zoomies.randomElement()!)
        case .scratching:
            showBubble(SpeechBubbles.scratching.randomElement()!)
        case .edgeWalking:
            // Walk along top of screen
            petY = screenH - petSize - 25  // menu bar area
            walkTargetX = CGFloat.random(in: 100...(screenW - 100))
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

        // Behavior timeout
        let elapsed = Date().timeIntervalSince(behaviorStartTime)
        if elapsed > behaviorDuration && !isDragging && behavior != .idle {
            behavior = .idle
            animFrame = 0
        }

        // Animate every other frame
        if frameCounter % 2 == 0 {
            animFrame += 1
        }

        // Physics — gravity with Dock as platform
        let currentGround = groundYForPet()
        if !isDragging && behavior != .sleeping && behavior != .jumping {
            // Safety clamp: cat should never be above 250px naturally
            if petY > 250 {
                petY = currentGround
                velocityY = 0
                isOnGround = true
            } else if petY > currentGround + 2 {
                // Falling
                velocityY -= 0.8
                petY += velocityY
                if petY <= currentGround {
                    petY = currentGround
                    velocityY = 0
                    isOnGround = true
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
            if petY <= jumpBaseY {
                petY = jumpBaseY
                velocityY = 0
                if elapsed > behaviorDuration * 0.8 {
                    behavior = .idle
                }
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
                    currentToy?.x = CGFloat.random(in: 50...(screenW - 80))
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
            // Gift falls down
            if let gw = giftWindow, gw.isVisible {
                giftPos.y -= 3
                gw.setFrameOrigin(NSPoint(x: giftPos.x, y: giftPos.y))
                // Cat runs to gift
                let dx = giftPos.x - petX
                if abs(dx) > 20 {
                    petX += dx > 0 ? 2 : -2
                    facingRight = dx > 0
                }
                // Gift landed — open it!
                if giftPos.y <= groundYForPet() + 10 {
                    gw.orderOut(nil)
                    showBubble("A PRESENT!! Yay!!")
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
                    behavior = .idle
                }
            }
        case .scratching:
            // Slight vibration
            if frameCounter % 3 == 0 {
                petX += CGFloat.random(in: -1...1)
            }
        default:
            break
        }

        // Clamp
        petX = max(0, min(petX, screenW - petSize))
        petY = max(floorY, min(petY, screenH - petSize - 50))

        // Update windows
        petWindow.setFrameOrigin(NSPoint(x: petX, y: petY))

        // Wobble for purring when being pet
        if behavior == .beingPet {
            let wobble = sin(Double(frameCounter) * 0.5) * 2
            petWindow.setFrameOrigin(NSPoint(x: petX + CGFloat(wobble), y: petY))
        }

        // Idle breathing animation — subtle vertical bob
        if behavior == .idle || behavior == .sitting || behavior == .lookingAtCursor {
            breathOffset = CGFloat(sin(Double(frameCounter) * 0.08)) * 1.5
            petWindow.setFrameOrigin(NSPoint(x: petX, y: petY + breathOffset))
        }

        updateBubblePosition()
        updateParticleWindow()
        updateSprite()

        // Update accessory position
        if currentAccessory != nil {
            accessoryWindow.setFrameOrigin(NSPoint(x: petX, y: petY + breathOffset))
        }

        // Night glow follows pet
        if isNightMode {
            nightGlowWindow.setFrameOrigin(NSPoint(x: petX - 15, y: petY - 15))
            // Pulse glow
            let pulse = 0.02 + 0.02 * CGFloat(sin(Double(frameCounter) * 0.03))
            nightGlowView.layer?.backgroundColor = NSColor(red: 0.4, green: 0.6, blue: 1.0, alpha: pulse).cgColor
        }

        // Update night mode every 60 seconds
        if frameCounter % 900 == 0 {
            updateNightMode()
        }

        // Drag trail sparkles
        if isDragging && frameCounter % 3 == 0 {
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + 40, y: petSize / 2 + 20),
                type: .sparkle, count: 1
            )
        }

        // Update particles
        particleCanvas.particleSystem.update()
        particleCanvas.needsDisplay = true

        // Stats HUD
        if isHoveringPet {
            statsHUD.stats = stats
            statsHUD.needsDisplay = true
            let hudX = petX + petSize / 2 - statsWindow.frame.width / 2
            let hudY = petY + petSize + 14
            statsWindow.setFrameOrigin(NSPoint(x: hudX, y: hudY))
        }

        // ── Cute events ──

        // Paw prints when walking
        if (behavior == .walking || behavior == .running || behavior == .promenade) && frameCounter % 12 == 0 {
            spawnPawPrint(at: NSPoint(x: petX + (facingRight ? 10 : petSize - 20), y: petY - 2))
        }

        // Sleep Z particles
        if behavior == .sleeping && frameCounter % 20 == 0 {
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + 50, y: petSize + 15),
                type: .note, count: 1
            )
        }

        // Random cute events (every ~20 seconds on average)
        if frameCounter % 300 == 0 && behavior == .idle {
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
        petImageView.image = getSprite(for: behavior, frame: animFrame, right: facingRight)
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
        butterflyPos = NSPoint(x: CGFloat.random(in: 100...(screenW - 100)),
                               y: CGFloat.random(in: 200...(screenH - 200)))
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
            iv.image = Sprites.render(Sprites.butterfly1, scale: 3)
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
            let sprite = butterflyFrame % 12 < 6 ? Sprites.butterfly1 : Sprites.butterfly2
            (bw.contentView as? NSImageView)?.image = Sprites.render(sprite, scale: 3)
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
        birdPos = NSPoint(x: petX + (facingRight ? 200 : -200), y: groundYForPet())
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
            iv.image = Sprites.render(Sprites.bird, scale: 3)
            birdWindow!.contentView = iv
        }

        birdWindow!.setFrameOrigin(NSPoint(x: birdPos.x, y: birdPos.y))
        birdWindow!.orderFront(nil)

        showBubble("*stares at bird*")
        startBehavior(.watchingBird, duration: 6.0)
    }

    func updateBird() {
        guard let bw = birdWindow, bw.isVisible else { return }

        // Bird hops slightly
        if frameCounter % 30 == 0 {
            birdPos.x += CGFloat.random(in: -5...5)
            bw.setFrameOrigin(NSPoint(x: birdPos.x, y: birdPos.y))
        }

        // Cat watches intently
        if behavior == .watchingBird {
            facingRight = birdPos.x > petX
            // Butt wiggle (getting ready to pounce)
            if frameCounter % 4 == 0 {
                petX += CGFloat.random(in: -0.5...0.5)
            }
        }

        // Bird flies away when behavior ends
        if behavior != .watchingBird && bw.isVisible {
            // Fly away animation
            birdPos.y += 4
            birdPos.x += 3
            bw.setFrameOrigin(NSPoint(x: birdPos.x, y: birdPos.y))
            if birdPos.y > screenH {
                bw.orderOut(nil)
                showBubble("*chirp chirp* Bye birdie!")
            }
        }
    }

    func spawnGift() {
        let size: CGFloat = 40
        giftPos = NSPoint(x: petX + CGFloat.random(in: -100...100), y: screenH)
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
            iv.image = Sprites.render(Sprites.gift, scale: 4)
            giftWindow!.contentView = iv
        }

        giftWindow!.setFrameOrigin(NSPoint(x: giftPos.x, y: giftPos.y))
        giftWindow!.orderFront(nil)

        startBehavior(.openingGift, duration: 6.0)
    }

    func startKnockingGlass() {
        let size: CGFloat = 30
        // Glass at screen edge
        let glassX = facingRight ? screenW - size - 10 : 10.0
        let glassY = groundYForPet()
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
            iv.image = Sprites.render(Sprites.glass, scale: 3)
            glassWindow!.contentView = iv
        }

        glassWindow!.setFrameOrigin(NSPoint(x: glassX, y: glassY))
        glassWindow!.orderFront(nil)
        glassVelocityY = 0

        showBubble("*eyes glass*")
        walkTargetX = glassX - (facingRight ? 30 : -30)
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
        showBubble(SpeechBubbles.eating.randomElement()!)
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
        showBubble(SpeechBubbles.playing.randomElement()!)
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
        stats.save()
    }

    @objc func bathePet() {
        stats.bathe()
        if stats.totalBaths == 1 { stats.addMilestone("First bath! I hated every second of it!") }
        if stats.totalBaths % 10 == 0 { stats.addMilestone("Bath #\(stats.totalBaths)... I'm starting to accept it") }
        startBehavior(.bathing, duration: 4.0)
        showBubble(SpeechBubbles.bathBubbles.randomElement()!)
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
            type: .sparkle, count: 10
        )
        stats.save()
    }

    @objc func feedMilkAction() {
        stats.feedMilk()
        startBehavior(.eating, duration: 3.0)
        showBubble(SpeechBubbles.milkBubbles.randomElement()!)
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
        particleCanvas.particleSystem.emit(
            at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
            type: .star, count: 6
        )
        showFoodAnimation(sprite: Sprites.treat)
        stats.save()
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
        showBubble(SpeechBubbles.promenadeBubbles.randomElement()!)
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
            particleCanvas.particleSystem.emit(
                at: NSPoint(x: petSize / 2 + 40, y: petSize + 10),
                type: .heart, count: 15
            )
            stats.happiness = min(100, stats.happiness + 10)
            stats.addXP(2)
        } else {
            startBehavior(.beingPet, duration: 2.5)
            showBubble(SpeechBubbles.petted.randomElement()!)
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

    func handleMouseDown(_ event: NSEvent) {
        isDragging = true
        dragOffset = NSPoint(
            x: event.locationInWindow.x,
            y: event.locationInWindow.y
        )
    }

    func handleMouseDragged(_ event: NSEvent) {
        guard isDragging else { return }
        let screenPoint = NSEvent.mouseLocation
        petX = screenPoint.x - dragOffset.x
        petY = screenPoint.y - dragOffset.y
        petWindow.setFrameOrigin(NSPoint(x: petX, y: petY))
        updateBubblePosition()
        updateParticleWindow()

        // Show cat reaction when dragged
        if behavior != .beingPet {
            petImageView.image = getSprite(for: .jumping, frame: animFrame, right: facingRight)
        }
    }

    func handleMouseUp(_ event: NSEvent) {
        if isDragging {
            isDragging = false
            let moved = abs(event.locationInWindow.x - dragOffset.x) + abs(event.locationInWindow.y - dragOffset.y)
            if moved < 5 {
                petTapped()
            } else {
                showBubble("Wheee!")
                // Cat falls after being dropped
                if petY > groundYForPet() + 5 {
                    velocityY = 0
                    isOnGround = false
                }
            }
        }
    }

    func handleMouseEntered() {
        isHoveringPet = true
        statsHUD.stats = stats
        statsHUD.showStartTime = Date()
        statsHUD.needsDisplay = true
        statsWindow.orderFront(nil)
    }

    func handleMouseExited() {
        isHoveringPet = false
        statsWindow.orderOut(nil)
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

        let cameraItem = NSMenuItem(title: "\u{1F4F7} Screenshot", action: #selector(screenshotPet), keyEquivalent: "")
        cameraItem.target = self
        menu.addItem(cameraItem)

        let diaryItem = NSMenuItem(title: "\u{1F4D3} Diary", action: #selector(showDiary), keyEquivalent: "")
        diaryItem.target = self
        menu.addItem(diaryItem)

        let statsItem = NSMenuItem(title: "\u{1F4CA} Stats", action: #selector(showStats), keyEquivalent: "")
        statsItem.target = self
        menu.addItem(statsItem)

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

    override var acceptsFirstResponder: Bool { true }
}

// MARK: - App Entry Point

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = MurchiDelegate()
app.delegate = delegate
app.run()
