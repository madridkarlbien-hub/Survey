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
| Enemies | Karl's 8 "Evil" designs (corrupted versions of the heroes, red glowing cracks): Tyanak, Tikbalang, Kapre, Manananggal, White Lady, Nuno sa Punso, Diwata, Berberoka. Boss: serpent Bakunawa. ("Evil Bakunawa.png" upload is really Evil Berberoka.) |
| Playable roster (later) | Karl's non-Evil designs: Aswang (Agila / Baboy Ramo / Lobo forms), Bakunawa, Berberoka, Bungisngis, Diwata, Kapre, Manananggal, Nuno sa Punso, Santelmo, Sarimanok, Sigbin, Tikbalang, Tyanak, White Lady |
| Character designs | Initial designs finished |

## Art
- **Tool:** ChatGPT image generation
- **Target style:** Inspired by Hades 1/2
- **Status:** Initial sprites were made in ChatGPT; they will be redone in the Hades-inspired style
- **Uploads:** 25 originals sit in the repo's top folder (to move into `game/art/` during the art pass). Two styles: chibi stickers with transparency (8 heroes + all 8 Evil versions) and painterly concept sheets with backgrounds (Aswang forms, Bakunawa, Bungisngis, Santelmo, Sarimanok, Sigbin) that need redrawing
- **In game now:** the 8 Evil sprites, shrunk to 192 px by `tools/import_enemy_art.py` into `art/enemies/`

## Technical
| Item | Decision |
|---|---|
| Engine | **Godot 4.7.2 stable** |
| Language | **GDScript** (Godot 4 syntax only, never Godot 3) |
| Platform | **PC / Steam (Windows) first** |
| Dev machine | Windows company laptop for now; project moves to a personal laptop later (Karl owns the Godot/GitHub accounts) |
| Renderer | Compatibility (light on older laptop GPUs) |
| Camera | **Straight top-down, like Vampire Survivors** (not Hades' angled 3/4 view) |
| Graphics | **2D, Hades-like** (decided 2026-10-21; 3D rejected for art-pipeline, laptop and token cost). Finish gameplay with placeholders first, then a 2D art pass (sprites, lighting, glow, particles) |
| Constraint | The build approach should not use a lot of tokens |

## Rules for Claude (token-efficient workflow)
- Write Godot 4 / GDScript 2.0 code only (`@export`, `@onready`, `super()`, typed variables, `CharacterBody2D` + `velocity`)
- Content is data-driven: characters, boons, enemies and waves live in small `Resource` (`.tres`) files, so new content needs no new code
- One small, focused task per request; edit only the files the task needs
- Keep scripts short and single-purpose; prefer text-editable scenes (`.tscn`) over editor-only steps
- When a step must happen in the Godot editor, give Karl short numbered click-by-click instructions
- Karl is NOT play-testing for now (company laptop). Claude verifies every change itself:
  1. `bash tools/run_tests.sh` - all tests must pass (also runs on GitHub on every push)
  2. `bash tools/take_screenshots.sh` - a bot plays a full run (unbeatable player), prints each room's time, and saves `screenshots/*.png`; look at them and report what they show
- Gotcha: scripts run with `-s` can't compile anything that names autoloads (`RunState`, `SaveData`), and almost all game scripts do. So `-s` entry points stay tiny and load the real code one frame later: the test runner keeps tests untyped, and `tools/screenshots.gd` loads `tools/screenshot_bot.gd` deferred
- Gotcha: don't `preload()` scenes whose scripts refer to Player/Enemy from Player/Enemy scripts (preload loop -> empty PackedScene at runtime). Use `load(path)` when needed instead
- Add or update tests in `tests/` with every new feature
- Claude can check logic and bugs; only Karl can judge fun, feel, and difficulty - flag those as open questions

## Project Layout
| Path | What it holds |
|---|---|
| `project.godot` | Engine settings, autoloads, input map (`move_*`: WASD, arrows, gamepad left stick; `interact`: E, gamepad A) |
| `data/characters/` | `CharacterData` script + one `.tres` per playable creature |
| `data/enemies/` | `EnemyData` script + one `.tres` per enemy type |
| `data/upgrades/` | `UpgradeData` (adds `amount` to a stat by name) + `basic_upgrades.tres` pool |
| `data/waves/` | `WaveData` / `WaveSet` scripts (rooms embed their own wave lists) |
| `data/rooms/` | `RoomData` (size, waves, clear mode DEFEAT_ALL or SURVIVE, min/max depth) + 7 rooms and `boss_lair.tres` |
| `data/rewards/` | `RewardData` (UPGRADE, HEAL, BONUS_XP, BOON + deity) shown on doors, granted when the next room is cleared |
| `data/deities/` | `DeityData` + `BoonData`; one `.tres` per deity (Apolaki, Mayari, Amanikable, Anitun Tabu), 3 boons each. Boon `effect` names map to code in `Shockwave`/`Enemy`/`Player`; all owned boons stack |
| `data/runs/` | `RunData`: room pool, 6 rooms before boss, reward pool, +20% enemies per room, 2-3 doors |
| `autoload/run_state.gd` | `RunState` autoload: current room number, pending reward, player stats carried between rooms, Diwa this run, Second Life used |
| `autoload/save_data.gd` | `SaveData` autoload: Diwa, shrine upgrade levels, runs/wins; JSON at `user://save.json` (tests use `user://test_save.json`, the bot `user://bot_save.json`) |
| `data/meta/` | `MetaUpgradeData` (effect, amount per level, cost per level) + `shrine_upgrades.tres` (Tibay, Lakas, Bilis, Biyaya, Kapalaran, Pangalawang Buhay) |
| `scenes/hub/` | `hub` (main scene, Kaluwalhatian): deity statues, Bathala's shrine (`ShrineMenu`, press E / gamepad A nearby), `RunGate` to start a run |
| `scenes/enemies/` | `Enemy` (behaviors from `EnemyData.behavior`: chase, leap, charge, ranged, spread, homing, teleport, vortex; plus split_into; every move has a wind-up telegraph), `EnemyProjectile`, `BakunawaBoss` (bite / moonfire rings / summon Tyanak, enraged below 50%), `WaveSpawner` (spawns just off-screen, capped at 300) |
| `scenes/attacks/` | `Shockwave` (Tikbalang's stomp; `make_hit` adds boon effects, echo, undertow, lightning), `Hit` (damage + push + burn/slow/wall damage), `FirePatch` (Blazing Trail) |
| `scenes/pickups/` | `XpOrb` (dropped by enemies, flies to the player within `pickup_radius`) and `DiwaGem` (extends XpOrb; adds to SaveData) |
| `scenes/ui/` | HUD (XP bar top, level + room top-left, HP bar bottom-left, owned boons bottom-right, objective, banner) and `LevelUpMenu` (pauses; queues level-ups, Upgrade rewards and deity boon picks; never re-offers owned boons) |
| `tests/` | Automated tests: `test_*.gd` files, base class in `tests/framework/test_case.gd`, test-only data in `tests/fixtures/` |
| `tools/` | `run_tests.sh`, `take_screenshots.sh`, `get_godot.sh` (Linux/cloud only) |
| `screenshots/` | Latest screenshots of key moments (has `.gdignore`, so Godot skips it) |
| `scenes/player/` | Player scene and movement script |
| `scenes/rooms/` | `arena_room`: builds walls (`RoomWalls`) from RoomData, checks clear rule, grants reward (+ Biyaya heal), opens `Door`s, wins on boss clear, Second Life on first death, returns to the hub when the run ends |

**Collision layers:** 1 = world/walls, 2 = player, 3 = enemies (bit value 4). The player's `Hurtbox` Area2D detects enemies for contact damage.

## Milestones
1. [x] One playable creature (Tikbalang, placeholder circle) walks around a walled test room
2. [x] Enemies spawn in waves and chase the player (placeholder "Corrupted Spirit"), with contact damage, HUD, and restart on death
3. [x] Auto-attack (Tikbalang shockwave), XP orbs, and level-ups (pick 1 of 3 upgrades)
4. [x] Rooms: 6 rooms + boss per run, DEFEAT_ALL or SURVIVE clear rules, 2-3 reward doors, stats carry over, victory on boss clear
5. [x] Boons: 4 Filipino deities x 3 boons, offered by boon doors; elements stack
6. [x] Hub: Kaluwalhatian (realm of the gods), Bathala's shrine with 6 permanent upgrades, Diwa currency, saved progress
7. [x] Real enemies: Karl's 8 Evil creatures with distinct behaviors and sprites; Bakunawa boss
8. [ ] Balance pass (run is easy and short)
9. [ ] Start the 2D art pass (Hades-style sprites, lighting, particles)
10. [ ] More playable characters (from Karl's finished designs)
11. [ ] Deity dialogue in the hub
(Order set by Karl on 2026-10-21.)

## Balance Notes (untested by a human)
- XP to next level: 5, 8, 11, 14... (`Player.xp_to_next_level`)
- Shockwave: 10 damage, 110 radius, every 1.5 s (floor 0.3 s); placeholder enemy has 10 HP, so it dies in one hit
- Boss: 300 HP, 15 contact damage, 85% knockback resistance; boss room doesn't scale with depth
- Rewards: Heal 30 HP, Bonus XP 12, Upgrade = 1 free pick
- Diwa: placeholder enemy 8% chance for 1 (+10% per Kapalaran level), boss always 25
- Bot full run (unbeatable player standing still, always first upgrade/door): rooms ~42-45 s each, whole run ~5:15, reached Lv 18. Leveling looks fast and room times look flat across depth; needs a human to judge

## Cultural Accuracy (before release)
- Deities are mostly from Tagalog tradition; names, domains and stories vary by source and region. Verify against good sources (or a folklore expert) and depict them respectfully. Bathala (rare boon / hub) and Tala (5th deity) are saved for later.

## Open Decisions
1. [x] Choose the game engine and programming language: Godot 4 + GDScript
2. [ ] Define a token-efficient build workflow with Claude Code (draft rules above)
3. [ ] Finalize the pipeline for redoing sprites in the Hades style
