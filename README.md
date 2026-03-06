<p align="center">
  <a href="https://murchi.pet">
    <img src="https://raw.githubusercontent.com/egorfedorov/murchi/main/.github/banner.svg" alt="Murchi — Desktop Tamagotchi Cat" width="700">
  </a>
</p>

<p align="center">
  <a href="https://murchi.pet"><img src="https://img.shields.io/badge/website-murchi.pet-a78bfa?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiI+PHRleHQgeT0iMTQiIGZvbnQtc2l6ZT0iMTQiPvCfkLE8L3RleHQ+PC9zdmc+" alt="Website"></a>
  <a href="https://github.com/egorfedorov/murchi/releases/latest"><img src="https://img.shields.io/github/v/release/egorfedorov/murchi?style=for-the-badge&color=34d399&label=download" alt="Download"></a>
  <img src="https://img.shields.io/badge/platform-macOS_12+-0a0a1a?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 12+">
  <img src="https://img.shields.io/badge/swift-single_file-f97316?style=for-the-badge&logo=swift&logoColor=white" alt="Swift">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-CC_BY--NC--ND_4.0-64748b?style=for-the-badge" alt="License"></a>
</p>

<br>

<table>
<tr>
<td width="60%" valign="top">

## What is Murchi?

A **single-file Swift app** that puts a pixel-art Tamagotchi cat on your macOS desktop. No Xcode, no dependencies — one `.swift` file, compiled with `swiftc`.

The cat walks around, sleeps, plays, gets hungry, chases butterflies, knocks glasses off tables, writes a diary, and lives on top of your Dock.

**Think classic Tamagotchi, but on your Mac.**

</td>
<td width="40%" align="center">

```
    ╱╲╱╲
   ╱ ◉◉ ╲
   │ ▼▼  │    ← Murchi
   ╰┬──┬─╯
    │▓▓│  ♥ ♥
   ╱╰──╯╲
  ╱ ╱  ╲ ╲
```

</td>
</tr>
</table>

---

<br>

<h2 align="center">Features</h2>

<br>

<table>
<tr>
<td align="center" width="33%">
<br>
<img width="40" src="https://em-content.zobj.net/source/apple/391/video-game_1f3ae.png"><br><br>
<strong>25+ Behaviors</strong><br>
<sub>Walk, sleep, zoomies, groom, chase butterflies, watch birds, knock glasses off tables</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<img width="40" src="https://em-content.zobj.net/source/apple/391/meat-on-bone_1f356.png"><br><br>
<strong>Feed & Care</strong><br>
<sub>Fish, milk, treats. 6 stats: hunger, happiness, energy, social, hygiene, health</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<img width="40" src="https://em-content.zobj.net/source/apple/391/yarn_1f9f6.png"><br><br>
<strong>Toys & Accessories</strong><br>
<sub>Mouse, yarn, laser. Hats, bow ties, crowns, glasses, flowers</sub><br><br>
</td>
</tr>
<tr>
<td align="center" width="33%">
<br>
<img width="40" src="https://em-content.zobj.net/source/apple/391/open-book_1f4d6.png"><br><br>
<strong>Cat Diary</strong><br>
<sub>Personal blog about meals, play, sickness, butterflies, birthdays</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<img width="40" src="https://em-content.zobj.net/source/apple/391/sparkles_2728.png"><br><br>
<strong>Particle Magic</strong><br>
<sub>Hearts, stars, sparkles, paw prints, sleep Z particles, confetti</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<img width="40" src="https://em-content.zobj.net/source/apple/391/desktop-computer_1f5a5-fe0f.png"><br><br>
<strong>Lives on Your Dock</strong><br>
<sub>Walks on macOS Dock as a physical platform with gravity</sub><br><br>
</td>
</tr>
<tr>
<td align="center" width="33%">
<br>
<img width="40" src="https://em-content.zobj.net/source/apple/391/chart-increasing_1f4c8.png"><br><br>
<strong>Level Up</strong><br>
<sub>XP system, 5 evolution stages: Baby to Cosmic Murchi</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<img width="40" src="https://em-content.zobj.net/source/apple/391/speech-balloon_1f4ac.png"><br><br>
<strong>Speech Bubbles</strong><br>
<sub>Murchi talks, reacts to petting, greets you when you return</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<img width="40" src="https://em-content.zobj.net/source/apple/391/butterfly_1f98b.png"><br><br>
<strong>Cute Events</strong><br>
<sub>Butterflies, birds, gifts, glass knocking, birthday celebrations</sub><br><br>
</td>
</tr>
</table>

<br>

---

<br>

## Download

[**Download Murchi.dmg**](https://github.com/egorfedorov/murchi/releases/latest/download/Murchi.dmg) — open, drag to Applications, done. Requires **macOS 12+**.

<br>

## Architecture

Everything lives in **one file**: `Murchi.swift` (~4000 lines)

```
Murchi.swift            the entire app
generate-icon.swift     pixel-art icon generator
build-app.sh            .app bundle + .dmg builder
run.sh                  compile & launch
docs/                   murchi.pet website (GitHub Pages)
```

| Layer | Tech |
|-------|------|
| Rendering | Pixel art as `[[UInt32]]` → `NSImage` |
| Window | `NSPanel` borderless, above Dock level |
| Physics | Custom gravity + platform detection |
| Particles | Hearts, stars, sparkles system |
| Persistence | `Codable` JSON → `~/.murchi/stats.json` |
| Hotkey | Carbon `EventHotKeyID` (Cmd+Shift+M) |
| Diary | `NSAttributedString` styled window |
| Website | Single HTML + vanilla JS, 10 languages |

<br>

## License

**CC BY-NC-ND 4.0** — View source and build for personal use. Cannot commercially distribute, modify, or create derivative works. See [LICENSE](LICENSE).

---

<p align="center">
  <sub>Made with love for cats everywhere</sub><br>
  <a href="https://murchi.pet"><strong>murchi.pet</strong></a><br>
  <sub>&copy; 2026 Egor Fedorov</sub>
</p>
