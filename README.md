<p align="center">
  <a href="https://murchi.pet">
    <img src="https://raw.githubusercontent.com/egorfedorov/murchi/main/.github/banner.svg" alt="Murchi & Kuma — Kawaii Desktop Pets for macOS" width="800">
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
  <sub>Two kawaii vector pets that live on your macOS desktop. One Swift file. Zero dependencies.</sub>
</p>

<br>

<p align="center">
  <a href="https://murchi.pet">
    <img src="https://img.shields.io/badge/%F0%9F%90%B1_GET_MURCHI_&_KUMA-34d399?style=for-the-badge&logoColor=white&labelColor=0a0a1a" alt="Get Murchi & Kuma" height="52">
  </a>
</p>
<p align="center">
  <sub>Pay what you want (even $0). 50% goes to animal shelters.</sub><br>
  <sub>Open DMG &rarr; drag to Applications &rarr; done. macOS 12+ required.</sub>
</p>

<br>

---

<br>

<h2 align="center">Meet the Friends</h2>

<p align="center"><sub>Two characters, two personalities, one desktop</sub></p>

<br>

<table>
<tr>
<td align="center" width="50%">
<br>

### Murchi

**The Curious Cat**

<sub>Playful &bull; Curious &bull; Loves Fish</sub>

<sub>Gray-blue fur, green eyes, yellow collar with a blue bell. Chases butterflies, knocks glasses off tables, writes diary entries about birds.</sub>

<br>
</td>
<td align="center" width="50%">
<br>

### Kuma

**The Gentle Bear**

<sub>Calm &bull; Cuddly &bull; Loves Honey</sub>

<sub>Warm brown fur, rosy cheeks, cute red bow tie. Gentle and cozy, loves napping and being pet. Dreams about honey.</sub>

<br>
</td>
</tr>
</table>

<br>

---

<br>

<p align="center">
  <img src="https://raw.githubusercontent.com/egorfedorov/murchi/main/.github/demo.svg" alt="Murchi & Kuma Demo — pets on desktop with speech bubble, hearts, stats" width="700">
</p>

<br>

---

<br>

<h2 align="center">What can they do?</h2>

<p align="center"><sub>Your pets have a full life on your desktop</sub></p>

<br>

<table>
<tr>
<td align="center" width="33%">
<br>
<h3>25+ Behaviors</h3>
<sub>Walk, sleep, zoomies, groom, chase butterflies, watch birds, knock glasses off tables, follow your cursor</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>Feed & Care</h3>
<sub>Fish, milk, treats, honey. 6 stats: hunger, happiness, energy, social, hygiene, health</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>Toys & Accessories</h3>
<sub>Mouse, yarn, laser. Hats, bow ties, crowns, glasses, flowers</sub><br><br>
</td>
</tr>
<tr>
<td align="center" width="33%">
<br>
<h3>Pet Diary</h3>
<sub>Personal blog about meals, play, sickness, butterflies, birthdays</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>Particle Effects</h3>
<sub>Hearts, stars, sparkles, paw prints, sleep Z particles, confetti</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>Lives on Your Dock</h3>
<sub>Walks on macOS Dock as a physical platform with gravity</sub><br><br>
</td>
</tr>
<tr>
<td align="center" width="33%">
<br>
<h3>Level Up</h3>
<sub>XP system, 5 evolution stages: Baby to Cosmic</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>Speech Bubbles</h3>
<sub>Your pet talks, reacts to petting, greets you when you return</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>Auto-Update</h3>
<sub>One-click update check from menu. Always the latest version</sub><br><br>
</td>
</tr>
</table>

<br>

---

<br>

<h2 align="center">How it works</h2>

<p align="center"><sub>Everything lives in <strong>one file</strong> — Murchi.swift (~5000 lines)</sub></p>

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
| Rendering | Kawaii vector `CGContext` &rarr; `NSImage` |
| Characters | CatRenderer + BearRenderer |
| Window | `NSPanel` borderless, above Dock |
| Physics | Custom gravity + dock detection |
| Particles | Hearts, stars, sparkles, paws |
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

# Build .app + .dmg
./build-app.sh
```

Requires Xcode command-line tools (`xcode-select --install`).

<br>

---

<br>

<h2 align="center">Pay What You Want</h2>

<p align="center"><sub>Murchi & Kuma are free forever. If you'd like to support development and help real animals — name your price.</sub></p>

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

### Crypto Payments

We accept crypto — send any amount to these addresses:

| Network | Address |
|---------|---------|
| **BTC** (Bitcoin) | `bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh` |
| **ERC-20** (ETH, USDT, USDC & tokens) | `0x71C7656EC7ab88b098defB751B7401B5f6d8976F` |
| **Solana** (SOL, SPL tokens) | `DRpbCBMxVnDK7maPMoGQfFaCRJNen4STmkF7Rexz1UV6` |

<br>

### Where Your Money Goes

50% of all payments go directly to these organizations:

| Organization | Mission |
|-------------|---------|
| [**Best Friends Animal Society**](https://bestfriends.org) | Leading the no-kill movement for cats and dogs across the USA |
| [**ASPCA**](https://aspca.org) | Fighting animal cruelty since 1866. Rescue, adoption, veterinary care |
| [**Alley Cat Allies**](https://alleycat.org) | Protecting cats through TNR (Trap-Neuter-Return) programs worldwide |
| [**IFAW**](https://ifaw.org) | International Fund for Animal Welfare. Rescuing animals in crisis globally |
| [**World Animal Protection**](https://worldanimalprotection.org) | Ending animal suffering. Better laws and disaster response |
| [**Feline Friends**](https://felinefriends.org.uk) | Finding loving homes for stray and abandoned cats through foster care |

<br>

---

<br>

<h2 align="center">Roadmap</h2>

<p align="center"><sub>Murchi & Kuma are just getting started</sub></p>

<br>

<table>
<tr>
<td align="center" width="33%">
<br>
<h3>v2.2 — Soon</h3>
<sub>15+ new accessories<br>New food types<br>Mini-games<br>Seasonal events</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>v2.3 — Next</h3>
<sub>Visit friends' pets<br>Room decorations<br>Pet furniture<br>Photo sharing</sub><br><br>
</td>
<td align="center" width="33%">
<br>
<h3>v3.0 — Future</h3>
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
  <code>5000+</code> lines of Swift &nbsp;&bull;&nbsp;
  <code>25+</code> behaviors &nbsp;&bull;&nbsp;
  <code>6</code> stats &nbsp;&bull;&nbsp;
  <code>5</code> evolution stages &nbsp;&bull;&nbsp;
  <code>2</code> characters &nbsp;&bull;&nbsp;
  <code>0</code> dependencies
</p>

<p align="center">
  <sub>
    Murchi remembers everything between launches<br>
    Murchi writes a personal diary about its day<br>
    Murchi celebrates its birthday with confetti<br>
    Murchi knocks your glass off the table if bored<br>
    Kuma dreams about honey when sleeping<br>
    Switch between cat and bear anytime
  </sub>
</p>

<br>

---

<br>

<p align="center">
  <sub>If you enjoy Murchi & Kuma, give it a star — it helps a lot!</sub>
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
  <sub>Made with love for animals everywhere</sub><br>
  <a href="https://murchi.pet"><strong>murchi.pet</strong></a><br>
  <sub>&copy; 2026 Egor Fedorov</sub>
</p>
