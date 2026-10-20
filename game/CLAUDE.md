# ROUGELIKE GAME — Project Context

> Author: Karl Bien Madrid
> Source: claude.ai Project "ROUGELIKE" memory export (2026-10-18)

## Owner
- **Name:** Karl Bien A. Madrid (Philippines)
- **Coding experience:** None. Explain things in plain language and avoid assuming prior knowledge.
- **Working style:**
  - Ask clarifying questions before major decisions
  - Explain the reasoning before making revisions
  - Use tables and structured formats, with short bullets and detail where needed
  - Keep a warm, conversational tone
  - Include caveats when they matter; flag only real risks and errors
  - Author every generated file under the name **Karl Bien Madrid**

## Project
| Item | Detail |
|---|---|
| Name | ROUGELIKE GAME |
| Status | Brainstorming / pre-production |
| Team | Solo developer |
| Goal | Eventual commercial release |
| Genre | Action roguelite + survivor-like (bullet heaven) hybrid |
| Inspiration | Hades 1 / Hades 2 |
| Structure | Hades structure (hub, rooms, boons, bosses) plus larger survivor-like enemy waves |
| Setting | Filipino mythology and folklore |
| Playable characters | Filipino mythological/folklore creatures (the playable characters, not the enemies) |
| Enemies | Leaning toward corrupted/evil folklore beings (not final); placeholder enemy for now |
| Character designs | Initial designs finished |

## Art
- **Tool:** ChatGPT image generation
- **Target style:** Inspired by Hades 1/2
- **Status:** Initial sprites were made in ChatGPT; they will be redone in the Hades-inspired style

## Technical
| Item | Decision |
|---|---|
| Engine | **Godot 4.7.2 stable** |
| Language | **GDScript** (Godot 4 syntax only, never Godot 3) |
| Platform | **PC / Steam (Windows) first** |
| Dev machine | Windows company laptop for now; project moves to a personal laptop later (Karl owns the Godot/GitHub accounts) |
| Renderer | Compatibility (light on older laptop GPUs) |
| Camera | **Straight top-down, like Vampire Survivors** (not Hades' angled 3/4 view) |
| Constraint | The build approach should not use a lot of tokens |

## Rules for Claude (token-efficient workflow)
- Write Godot 4 / GDScript 2.0 code only (`@export`, `@onready`, `super()`, typed variables, `CharacterBody2D` + `velocity`)
- Content is data-driven: characters, boons, enemies and waves live in small `Resource` (`.tres`) files, so new content needs no new code
- One small, focused task per request; edit only the files the task needs
- Keep scripts short and single-purpose; prefer text-editable scenes (`.tscn`) over editor-only steps
- When a step must happen in the Godot editor, give Karl short numbered click-by-click instructions
- Karl is NOT play-testing for now (company laptop). Claude verifies every change itself:
  1. `bash tools/run_tests.sh` - all tests must pass (also runs on GitHub on every push)
  2. `bash tools/take_screenshots.sh` - then look at `screenshots/*.png` and report what they show
- Add or update tests in `tests/` with every new feature
- Claude can check logic and bugs; only Karl can judge fun, feel, and difficulty - flag those as open questions

## Project Layout
| Path | What it holds |
|---|---|
| `project.godot` | Engine settings, input map (`move_*`: WASD, arrows, gamepad left stick) |
| `data/characters/` | `CharacterData` script + one `.tres` per playable creature |
| `data/enemies/` | `EnemyData` script + one `.tres` per enemy type |
| `data/upgrades/` | `UpgradeData` (adds `amount` to a stat by name) + `basic_upgrades.tres` pool |
| `data/waves/` | `WaveData` / `WaveSet` scripts; `test_waves.tres` lists the waves in order (last one repeats) |
| `scenes/enemies/` | Enemy scene (chases the player) and `WaveSpawner` (spawns just off-screen, capped at 300) |
| `scenes/attacks/` | `Shockwave`: Tikbalang's stomp, uses the `attack_*` stats |
| `scenes/pickups/` | `XpOrb`: dropped by enemies, flies to the player within `pickup_radius` |
| `scenes/ui/` | HUD (XP bar, level, HP, wave, time, "Defeated") and `LevelUpMenu` (pauses, pick 1 of 3) |
| `tests/` | Automated tests: `test_*.gd` files, base class in `tests/framework/test_case.gd` |
| `tools/` | `run_tests.sh`, `take_screenshots.sh`, `get_godot.sh` (Linux/cloud only) |
| `screenshots/` | Latest screenshots of key moments (has `.gdignore`, so Godot skips it) |
| `scenes/player/` | Player scene and movement script |
| `scenes/rooms/` | Rooms; `test_room` is the main scene for now (walls, starts waves, restarts on death) |

**Collision layers:** 1 = world/walls, 2 = player, 3 = enemies (bit value 4). The player's `Hurtbox` Area2D detects enemies for contact damage.

## Milestones
1. [x] One playable creature (Tikbalang, placeholder circle) walks around a walled test room
2. [x] Enemies spawn in waves and chase the player (placeholder "Corrupted Spirit"), with contact damage, HUD, and restart on death
3. [x] Auto-attack (Tikbalang shockwave), XP orbs, and level-ups (pick 1 of 3 upgrades)
4. [ ] Boons, rooms, and the hub

## Balance Notes (untested by a human)
- XP to next level: 5, 8, 11, 14... (`Player.xp_to_next_level`)
- Shockwave: 10 damage, 110 radius, every 1.5 s (floor 0.3 s); placeholder enemy has 10 HP, so it dies in one hit

## Open Decisions
1. [x] Choose the game engine and programming language: Godot 4 + GDScript
2. [ ] Define a token-efficient build workflow with Claude Code (draft rules above)
3. [ ] Finalize the pipeline for redoing sprites in the Hades style
