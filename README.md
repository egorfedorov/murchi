<p align="center">
  <a href="https://murchi.pet">
    <img src="https://raw.githubusercontent.com/egorfedorov/murchi/main/.github/banner.svg" alt="Murchi — Desktop Tamagotchi for macOS" width="800">
  </a>
</p>

<p align="center">
  <a href="https://murchi.pet"><img src="https://img.shields.io/badge/website-murchi.pet-a78bfa?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiI+PHRleHQgeT0iMTQiIGZvbnQtc2l6ZT0iMTQiPvCfkLE8L3RleHQ+PC9zdmc+" alt="Website"></a>
  <a href="https://github.com/egorfedorov/murchi/releases/latest"><img src="https://img.shields.io/github/v/release/egorfedorov/murchi?style=for-the-badge&color=34d399&label=download" alt="Download"></a>
  <img src="https://img.shields.io/badge/platform-macOS_12+-0a0a1a?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 12+">
  <img src="https://img.shields.io/badge/swift-single_file-f97316?style=for-the-badge&logo=swift&logoColor=white" alt="Swift">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-CC_BY--NC--ND_4.0-64748b?style=for-the-badge" alt="License"></a>
</p>

<p align="center">
  <sub>Your desktop tamagotchi for macOS. Lives on your screen. Needs your love.</sub>
</p>

<br>

<p align="center">
  <a href="https://murchi.pet">
    <img src="https://img.shields.io/badge/%F0%9F%90%B1_GET_MURCHI-34d399?style=for-the-badge&logoColor=white&labelColor=0a0a1a" alt="Get Murchi" height="52">
  </a>
</p>
<p align="center">
  <sub>Pay what you want (even $0). 50% goes to animal shelters.</sub><br>
  <sub>Open DMG &rarr; drag to Applications &rarr; done. macOS 12+ required.</sub><br>
  <sub>App Store coming soon!</sub>
</p>

<br>

---

<br>

<h2 align="center">What is Murchi?</h2>

<p align="center"><sub>A desktop tamagotchi with full SVG vector art, physics, emotions, and a life of its own</sub></p>

<br>

Murchi is a desktop tamagotchi that lives on your macOS screen. It walks on your Dock, climbs screen edges, chases your cursor, reacts to music, writes diary entries, and has real emotions. Everything is rendered as smooth SVG vector art with 16-frame animations for every pose.

The entire app is a **single Swift file** — no Xcode project, no dependencies, no storyboards. Just compile and run.

<br>

---

<br>

<h2 align="center">Features</h2>

<br>

<table>
<tr>
<td align="center" width="33%">
<br>
<h3>&#x1F3C3; 30+ Behaviors</h3>
<sub>Walk, run, sleep, zoomies, climb edges, chase butterflies, watch birds, knock glasses, follow cursor, hide, poop, dance to music</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>&#x1F3B5; Music Detection</h3>
<sub>Detects when you play music in Apple Music or Spotify. Cat puts on headphones and vibes &mdash; or gets angry if it hates the song</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>&#x2693; Dock Physics</h3>
<sub>Walks on macOS Dock as a physical platform. Real gravity, edge climbing, jumping off walls</sub><br><br>
</td>
</tr>
<tr>
<td align="center" width="33%">
<br>
<h3>&#x1F3A8; SVG Vector Art</h3>
<sub>Every pose is hand-crafted SVG with smooth 16-frame animation cycles. Breathing, tail wag, blinking, trembling, strain</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>&#x1F49B; Emotions &amp; Stats</h3>
<sub>6 stats: hunger, happiness, energy, social, hygiene, health. 4 moods. Gets sick, sad, or ecstatic based on care</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>&#x2728; Particle Effects</h3>
<sub>Music notes, hearts, stars, sparkles, tears, confetti, sleep Zs, dream bubbles, soap bubbles</sub><br><br>
</td>
</tr>
<tr>
<td align="center" width="33%">
<br>
<h3>&#x1F381; Toys &amp; Accessories</h3>
<sub>Mouse toy, yarn ball, laser dot. Party hat, bow tie, crown, sunglasses, flower, halo &mdash; unlock with XP</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>&#x1F4D6; Pet Diary</h3>
<sub>Cat writes a personal journal about its day. Meals, play, butterflies, sickness, milestones</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>&#x1F622; Sit in Corner</h3>
<sub>Send the cat to the corner as punishment. It walks to the edge, sits facing the room, and cries until you forgive it</sub><br><br>
</td>
</tr>
</table>

<br>

---

<br>

<h2 align="center">All Poses</h2>

<p align="center"><sub>15 unique SVG poses, each with 16-frame animation</sub></p>

<br>

| Pose | Animation | Trigger |
|------|-----------|---------|
| **Sitting** | Breathing bob, tail wag, blinking | Idle, grooming, looking at cursor |
| **Walking** | 4-frame walk cycle, bounce | Walking, running, chasing |
| **Sleeping** | Slow breathing, Zzz particles | Low energy / nighttime |
| **Eating** | Chomping animation | Feed from menu |
| **Held** | Dangling by scruff, sway | Click and drag |
| **Angry** | Trembling, arched back | Scratching furniture |
| **Jumping** | Squash & stretch | Random jump, stretch |
| **Playing** | Bouncy, energetic | Toys, play behavior |
| **Climbing** | Rotated 90°, paw scramble | Reaches screen edge |
| **Bathing** | Wobble, soap bubbles | Bath from menu |
| **Music Happy** | Headphones, half-closed eyes, sway | Music playing (75% chance) |
| **Music Angry** | Headphones, angry brows, tremble | Music playing (25% chance) |
| **Hiding** | Paw overlay, worried brows, sweat | Random shy behavior |
| **Squatting** | ^_^ eyes, strain lines, blush | Pooping |
| **Crying** | Sobbing bob, tilt, tears | Sad mood, corner punishment |

Plus: standing, lonely sitting, sick, dead, celebrating poses.

<br>

---

<br>

<h2 align="center">How it works</h2>

<p align="center"><sub>Everything lives in <strong>one file</strong> — Murchi.swift (9000+ lines)</sub></p>

<br>

<table>
<tr>
<td width="50%">

```
Murchi.swift            the entire app
generate-icon.swift     icon generator
build-app.sh            .app bundle + .dmg builder
run.sh                  compile & launch
```

</td>
<td width="50%">

| Layer | Tech |
|-------|------|
| Rendering | SVG &rarr; `NSImage` (16-frame cycles) |
| Window | `NSPanel` borderless, above Dock |
| Physics | Custom gravity + Dock platform detection |
| Particles | 10 types, custom drawing per type |
| Music | AppleScript &rarr; Music.app / Spotify |
| Persistence | `Codable` JSON &rarr; `~/.murchi/` |
| Hotkey | `Cmd+Shift+M` global shortcut |

</td>
</tr>
</table>

<br>

### Build from source

```bash
# Quick run (compile + launch)
./run.sh

# Or compile manually
swiftc -O -whole-module-optimization -o Murchi Murchi.swift \
  -framework AppKit -framework Foundation -framework AVFoundation \
  -framework Carbon -framework UserNotifications
./Murchi

# Build .app + .dmg
./build-app.sh
```

Requires Xcode command-line tools (`xcode-select --install`).

> **Note:** If macOS says the app is "damaged and can't be opened", run:
> ```bash
> xattr -cr /Applications/Murchi.app
> ```
> This removes the quarantine flag added to apps downloaded from the internet.

> **App Store:** Coming soon! For now — download the DMG and install manually.

<br>

---

<br>

<h2 align="center">Pay What You Want</h2>

<p align="center"><sub>Murchi is free forever. If you'd like to support development and help real animals — name your price.</sub></p>

<br>

<p align="center">
  <a href="https://murchi.pet#get">
    <img src="https://img.shields.io/badge/%F0%9F%92%B3_PAY_WHAT_YOU_WANT-a78bfa?style=for-the-badge&labelColor=0a0a1a" alt="Pay what you want" height="44">
  </a>
</p>

<p align="center">
  <sub><strong>50%</strong> of all payments go to animal welfare organizations &bull; <strong>50%</strong> supports development</sub>
</p>

<br>

---

<br>

<p align="center">
  <code>9000+</code> lines of Swift &nbsp;&bull;&nbsp;
  <code>30+</code> behaviors &nbsp;&bull;&nbsp;
  <code>15+</code> animated poses &nbsp;&bull;&nbsp;
  <code>10</code> particle types &nbsp;&bull;&nbsp;
  <code>6</code> stats &nbsp;&bull;&nbsp;
  <code>5</code> evolution stages &nbsp;&bull;&nbsp;
  <code>1</code> file &nbsp;&bull;&nbsp;
  <code>0</code> dependencies
</p>

<br>

---

<br>

<p align="center">
  <sub>If you enjoy Murchi, give it a star!</sub>
</p>

<p align="center">
  <a href="https://github.com/egorfedorov/murchi/stargazers">
    <img src="https://img.shields.io/github/stars/egorfedorov/murchi?style=for-the-badge&color=fbbf24&logo=github&label=stars" alt="Stars">
  </a>
</p>

<br>

## License

**CC BY-NC-ND 4.0** — View source and build for personal use. Cannot commercially distribute, modify, or create derivative works. See [LICENSE](LICENSE).

---

<p align="center">
  <sub>Made with love for animals everywhere</sub><br>
  <a href="https://murchi.pet"><strong>murchi.pet</strong></a><br>
  <sub>&copy; 2026 Egor Fedorov</sub>
</p>
