<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-murchi-icon.png" width="128" alt="Murchi">
</p>

<h1 align="center">Murchi</h1>

<p align="center">
  <strong>A desktop Tamagotchi cat for macOS</strong><br>
  Pixel-art virtual pet that lives on your screen, walks on your Dock, and keeps a personal diary.
</p>

<p align="center">
  <a href="https://murchi.pet">murchi.pet</a> &middot;
  <a href="https://murchi.pet/Murchi.dmg">Download DMG</a> &middot;
  macOS 12+
</p>

---

## What is Murchi?

Murchi is a single-file macOS app written entirely in Swift. No Xcode project, no storyboards, no dependencies — just one `.swift` file compiled with `swiftc`. A pixel-art cat appears on your desktop, walks around, reacts to your mouse, and lives its own little life.

Think classic Tamagotchi, but on your Mac.

## Features

**Life simulation**
- 6 stats: hunger, happiness, energy, social, hygiene, health
- Gets sick if neglected, needs medicine to heal
- Poops, needs bath, gets sleepy at night
- Ages and evolves through 5 stages (Baby → Cosmic Murchi)

**25+ behaviors**
- Walking, sleeping, running, grooming, zoomies
- Chasing butterflies, watching birds
- Knocking glasses off tables (it's a cat)
- Promenading on a leash, opening gifts

**Dock as a platform**
- The cat walks ON TOP of your macOS Dock
- Full physics: gravity, jumping, landing

**Toys & accessories**
- Mouse toy, yarn ball, laser pointer
- Hats, bow ties, crowns, glasses, flowers
- Unlock more as you level up

**Cat diary**
- Murchi writes a personal blog about its day
- Entries about meals, play, sickness, butterflies, birthdays
- Full scrollable diary window with timestamps

**Particles & effects**
- Hearts, stars, sparkles, poof clouds
- Paw prints when walking
- Sleep Z particles
- Birthday confetti

**Interactions**
- Click to pet (multi-click for extra love)
- Right-click for full action menu: feed, play, bathe, heal, walk, toys, accessories
- Drag the cat around your screen
- Cmd+Shift+M to summon to cursor
- Hover to see animated stat bars

## Build

No Xcode needed. Just:

```bash
# Quick run (compile + launch)
bash run.sh

# Build .app bundle + DMG
bash build-app.sh
```

Requires macOS 12+ and Xcode Command Line Tools (`xcode-select --install`).

## Architecture

Everything is in **one file**: `Murchi.swift` (~4000 lines).

- Pixel art sprites as `[[UInt32]]` arrays
- `NSPanel` with borderless style for desktop overlay
- Window level above the Dock
- Physics engine with gravity and platform detection
- Particle system for visual effects
- `Codable` JSON persistence to `~/.murchi/stats.json`
- Carbon `EventHotKeyID` for global hotkey
- `NSAttributedString` styled diary window
- Auto-milestone system for diary entries
- 10-language website at `docs/index.html`

## Project structure

```
Murchi.swift          — the entire app (single file)
generate-icon.swift   — generates AppIcon.icns from pixel art
build-app.sh          — builds .app bundle and .dmg
run.sh                — quick compile and run
docs/                 — website (murchi.pet via GitHub Pages)
  index.html          — landing page with interactive demo
  CNAME               — custom domain config
```

## Website

The landing page at [murchi.pet](https://murchi.pet) includes an interactive demo where a pixel cat walks around inside a fake macOS desktop. Click it to see hearts and stat bars. Built as a single HTML file with vanilla JS.

Hosted via GitHub Pages from the `docs/` folder.

## Domain setup

To connect `murchi.pet` to GitHub Pages:

1. In your domain registrar, add DNS records:
   - **A records** pointing to GitHub Pages IPs:
     ```
     185.199.108.153
     185.199.109.153
     185.199.110.153
     185.199.111.153
     ```
   - **CNAME** for `www` → `egorfedorov.github.io`
2. In GitHub repo Settings → Pages → Custom domain: enter `murchi.pet`
3. Enable "Enforce HTTPS"

The `docs/CNAME` file is already configured.

## License

**CC BY-NC-ND 4.0** — You can view the source and build for personal use, but you cannot commercially distribute, modify, or create derivative works. See [LICENSE](LICENSE).

---

<p align="center">
  <sub>Made with love for cats everywhere &middot; <a href="https://murchi.pet">murchi.pet</a> &middot; &copy; 2026 Egor Fedorov</sub>
</p>
