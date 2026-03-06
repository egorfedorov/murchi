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
    <img src="https://img.shields.io/badge/DOWNLOAD_MURCHI.DMG-34d399?style=for-the-badge&logo=apple&logoColor=white&labelColor=0a0a1a" alt="Download DMG" height="48">
  </a>
</p>
<p align="center">
  <sub>Open DMG &rarr; drag to Applications &rarr; done. macOS 12+ required.</sub>
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

<h2 align="center">How it works</h2>

<p align="center"><sub>Everything lives in <strong>one file</strong> &mdash; Murchi.swift (~4000 lines)</sub></p>

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
<img width="30" src="https://em-content.zobj.net/source/apple/391/rocket_1f680.png"><br>
<strong>v2.1 &mdash; Soon</strong><br><br>
<sub>15+ new accessories<br>New food types<br>Mini-games<br>Seasonal events</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<img width="30" src="https://em-content.zobj.net/source/apple/391/globe-showing-americas_1f30e.png"><br>
<strong>v2.2 &mdash; Next</strong><br><br>
<sub>Visit friends' cats<br>Room decorations<br>Cat furniture<br>Photo sharing</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<img width="30" src="https://em-content.zobj.net/source/apple/391/crystal-ball_1f52e.png"><br>
<strong>v3.0 &mdash; Future</strong><br><br>
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
  <code>4000+</code> lines of Swift &nbsp;&bull;&nbsp;
  <code>25+</code> behaviors &nbsp;&bull;&nbsp;
  <code>6</code> stats &nbsp;&bull;&nbsp;
  <code>5</code> evolution stages &nbsp;&bull;&nbsp;
  <code>0</code> dependencies
</p>

<p align="center">
  <sub>
    Murchi remembers everything between launches &nbsp;&#x1f4be;<br>
    Murchi writes a personal diary about its day &nbsp;&#x1f4d6;<br>
    Murchi celebrates its birthday with confetti &nbsp;&#x1f389;<br>
    Murchi knocks your glass off the table if bored &nbsp;&#x1f610;<br>
    Murchi poops if you forget to feed it &nbsp;&#x1f4a9;
  </sub>
</p>

<br>

---

<br>

<h2 align="center">Star history</h2>

<p align="center">
  <sub>If you enjoy Murchi, give it a star &mdash; it helps a lot!</sub>
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

---

<br>

## License

**CC BY-NC-ND 4.0** — View source and build for personal use. Cannot commercially distribute, modify, or create derivative works. See [LICENSE](LICENSE).

---

<p align="center">
  <sub>Made with love for cats everywhere</sub><br>
  <a href="https://murchi.pet"><strong>murchi.pet</strong></a><br>
  <sub>&copy; 2026 Egor Fedorov</sub>
</p>
