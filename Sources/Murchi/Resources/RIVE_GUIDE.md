# Murchi — Rive Character Design Guide

## Quick Start

1. Go to https://rive.app (free account, unlimited personal files)
2. Create two characters: `cat.riv` and `bear.riv`
3. Drop them into this `Resources/` folder
4. Run `./build-rive-app.sh`

## Community Shortcuts

Instead of drawing from scratch, remix these community files:

- **Cat**: https://rive.app/community/files/3920-8202-cat-following-the-mouse/
- **Cat interactive**: https://rive.app/community/files/11564-22141-cat-interaction/
- **Bouncy Cat**: https://rive.app/community/files/7964-15333-bouncy-cat/

Remix → add the state machine inputs below → export as .riv

---

## State Machine Specification

Each .riv file MUST have a state machine named **"PetState"** with these inputs:

### Number Inputs

| Name | Values | Description |
|------|--------|-------------|
| `pose` | 0-7 | Character pose (see table below) |
| `expression` | 0-11 | Facial expression (see table below) |
| `lookX` | 0.0-1.0 | Horizontal cursor position on screen |

### Boolean Inputs

| Name | Description |
|------|-------------|
| `lookRight` | `true` = facing right, `false` = facing left |
| `isDragging` | `true` while user drags the pet |

### Trigger Inputs

| Name | When it fires |
|------|--------------|
| `pet` | User clicks/pets the character |
| `eat` | Character starts eating |
| `jump` | Character jumps |
| `levelUp` | Character levels up (celebration!) |

---

## Pose Values

| Value | Pose | Description |
|-------|------|-------------|
| 0 | Standing | Default idle pose |
| 1 | WalkL | Left foot forward |
| 2 | WalkR | Right foot forward |
| 3 | Sitting | Sitting down |
| 4 | LyingDown | Lying down (frame 1) |
| 5 | LyingDown2 | Lying down (frame 2, for breathing animation) |
| 6 | Jump | In the air |
| 7 | Stretch | Stretching pose |

## Expression Values

| Value | Expression | Description |
|-------|-----------|-------------|
| 0 | Neutral | Default face |
| 1 | Happy | Smiling |
| 2 | Love | Heart eyes |
| 3 | Excited | Wide eyes, big smile |
| 4 | Sleeping | Eyes closed, peaceful |
| 5 | Blink | Quick blink |
| 6 | Eating | Chewing/munching |
| 7 | Annoyed | Slightly grumpy |
| 8 | Shocked | Surprised! |
| 9 | Sick | Feeling unwell |
| 10 | Straining | Effort face (for... pooping) |
| 11 | Curious | Looking at something |

---

## Design Tips for Duolingo-Style Characters

1. **Big head, small body** — head should be ~60% of character
2. **White sclera eyes** — white oval background + dark iris + white highlight
3. **No outlines** — use color contrast and subtle shadows for definition
4. **Chunky proportions** — round, soft shapes everywhere
5. **Pastel colors** — warm orange for cat, soft white/gray for bear
6. **Smooth gradients** — use Rive's gradient fills for volume
7. **Squash & stretch** — add to walk cycle and jump for life

## Artboard Size

- Design at **160×160px** (displayed at 80×80 on screen)
- This matches the CGContext fallback resolution

## State Machine Architecture in Rive

Recommended layer structure:
```
PetState (state machine)
├── Idle (blend state)
│   ├── Standing → blends with expression
│   └── Blink (timeline, triggered randomly)
├── Walking (blend state)
│   ├── WalkL ↔ WalkR (alternating)
│   └── Synced with pose input
├── Sitting
├── Sleeping
│   ├── LyingDown1 ↔ LyingDown2 (slow breathing)
├── Jump (timeline)
├── Stretch (timeline)
└── Reactions (overlay layer)
    ├── Pet reaction (hearts, happy squish)
    ├── Eat reaction (chomp animation)
    └── Level up (celebration, sparkles)
```

Use **blend states** driven by the `pose` number input to smoothly
transition between poses. Use the `expression` input to blend
facial features.
