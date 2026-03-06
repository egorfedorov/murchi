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

<p align="center">
  <sub>A pixel-art Tamagotchi cat that lives on your macOS desktop. One Swift file. Zero dependencies.</sub>
</p>

<br>

<p align="center">
  <a href="https://github.com/egorfedorov/murchi/releases/latest/download/Murchi.dmg">
    <img src="https://img.shields.io/badge/%E2%AC%87%EF%B8%8F_DOWNLOAD_MURCHI.DMG-34d399?style=for-the-badge&logoColor=white&labelColor=0a0a1a" alt="Download DMG" height="48">
  </a>
</p>
<p align="center">
  <sub>Open DMG &rarr; drag to Applications &rarr; done. macOS 12+ required.</sub>
</p>

<br>

---

<br>

<p align="center">
  <img src="https://raw.githubusercontent.com/egorfedorov/murchi/main/.github/demo.svg" alt="Murchi Demo — cat on desktop with speech bubble, hearts, stats" width="700">
</p>

<br>

---

<br>

<h2 align="center">What can Murchi do?</h2>

<p align="center"><sub>Your cat has a full life on your desktop</sub></p>

<br>

<table>
<tr>
<td align="center" width="33%">
<br>
<h3>🎮 25+ Behaviors</h3>
<sub>Walk, sleep, zoomies, groom, chase butterflies, watch birds, knock glasses off tables</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>🍖 Feed & Care</h3>
<sub>Fish, milk, treats. 6 stats: hunger, happiness, energy, social, hygiene, health</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>🧶 Toys & Accessories</h3>
<sub>Mouse, yarn, laser. Hats, bow ties, crowns, glasses, flowers</sub><br><br>
</td>
</tr>
<tr>
<td align="center" width="33%">
<br>
<h3>📖 Cat Diary</h3>
<sub>Personal blog about meals, play, sickness, butterflies, birthdays</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>✨ Particle Magic</h3>
<sub>Hearts, stars, sparkles, paw prints, sleep Z particles, confetti</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>🖥️ Lives on Your Dock</h3>
<sub>Walks on macOS Dock as a physical platform with gravity</sub><br><br>
</td>
</tr>
<tr>
<td align="center" width="33%">
<br>
<h3>📈 Level Up</h3>
<sub>XP system, 5 evolution stages: Baby to Cosmic Murchi</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>💬 Speech Bubbles</h3>
<sub>Murchi talks, reacts to petting, greets you when you return</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>🦋 Cute Events</h3>
<sub>Butterflies, birds, gifts, glass knocking, birthday celebrations</sub><br><br>
</td>
</tr>
</table>

<br>

---

<br>

<h2 align="center">How it works</h2>

<p align="center"><sub>Everything lives in <strong>one file</strong> — Murchi.swift (~4000 lines)</sub></p>

<br>

<table>
<tr>
<td width="50%">

```
Murchi.swift            the entire app
generate-icon.swift     pixel-art icon generator
build-app.sh            .app bundle + .dmg builder
run.sh                  compile & launch
docs/                   murchi.pet website
```

</td>
<td width="50%">

| Layer | Tech |
|-------|------|
| Rendering | Pixel art `[[UInt32]]` &rarr; `NSImage` |
| Window | `NSPanel` borderless, above Dock |
| Physics | Custom gravity + dock detection |
| Particles | Hearts, stars, sparkles, paws |
| Persistence | `Codable` JSON &rarr; `~/.murchi/` |
| Hotkey | `Cmd+Shift+M` global shortcut |

</td>
</tr>
</table>

<br>

---

<br>

<h2 align="center">Roadmap</h2>

<p align="center"><sub>Murchi is just getting started</sub></p>

<br>

<table>
<tr>
<td align="center" width="33%">
<br>
<h3>🚀 v2.1 — Soon</h3>
<sub>15+ new accessories<br>New food types<br>Mini-games<br>Seasonal events</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>🌍 v2.2 — Next</h3>
<sub>Visit friends' cats<br>Room decorations<br>Cat furniture<br>Photo sharing</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>🔮 v3.0 — Future</h3>
<sub>Dogs, hamsters, birds<br>Worlds &amp; biomes<br>Multiplayer<br>App Store release</sub><br><br>
</td>
</tr>
</table>

<p align="center">
  <a href="https://github.com/egorfedorov/murchi/issues"><img src="https://img.shields.io/badge/VIEW_FULL_ROADMAP-issues-a78bfa?style=for-the-badge" alt="Roadmap"></a>
</p>

<br>

---

<br>

<h2 align="center">Fun facts</h2>

<br>

<p align="center">
  <code>4000+</code> lines of Swift &nbsp;•&nbsp;
  <code>25+</code> behaviors &nbsp;•&nbsp;
  <code>6</code> stats &nbsp;•&nbsp;
  <code>5</code> evolution stages &nbsp;•&nbsp;
  <code>0</code> dependencies
</p>

<p align="center">
  <sub>
    💾 Murchi remembers everything between launches<br>
    📖 Murchi writes a personal diary about its day<br>
    🎉 Murchi celebrates its birthday with confetti<br>
    😐 Murchi knocks your glass off the table if bored<br>
    💩 Murchi poops if you forget to feed it
  </sub>
</p>

<br>

---

<br>

<p align="center">
  <sub>If you enjoy Murchi, give it a ⭐ — it helps a lot!</sub>
</p>

<p align="center">
  <a href="https://github.com/egorfedorov/murchi/stargazers">
    <img src="https://img.shields.io/github/stars/egorfedorov/murchi?style=for-the-badge&color=fbbf24&logo=github&label=stars" alt="Stars">
  </a>
  &nbsp;
  <a href="https://github.com/egorfedorov/murchi/network/members">
    <img src="https://img.shields.io/github/forks/egorfedorov/murchi?style=for-the-badge&color=64748b&logo=github&label=forks" alt="Forks">
  </a>
</p>

<br>

## License

**CC BY-NC-ND 4.0** — View source and build for personal use. Cannot commercially distribute, modify, or create derivative works. See [LICENSE](LICENSE).

---

<p align="center">
  <sub>Made with love for cats everywhere</sub><br>
  <a href="https://murchi.pet"><strong>murchi.pet</strong></a><br>
  <sub>&copy; 2026 Egor Fedorov</sub>
</p>
