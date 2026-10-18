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
- Karl play-tests on the laptop and reports back; Claude does not assume the game was run

## Project Layout
| Path | What it holds |
|---|---|
| `project.godot` | Engine settings, input map (`move_*`: WASD, arrows, gamepad left stick) |
| `data/characters/` | `CharacterData` script + one `.tres` per playable creature |
| `scenes/player/` | Player scene and movement script |
| `scenes/rooms/` | Rooms; `test_room` is the main scene for now |

## Milestones
1. [x] One playable creature (Tikbalang, placeholder circle) walks around a walled test room
2. [ ] Enemies spawn in waves and chase the player
3. [ ] Auto-attack, then XP and level-ups
4. [ ] Boons, rooms, and the hub

## Open Decisions
1. [x] Choose the game engine and programming language: Godot 4 + GDScript
2. [ ] Define a token-efficient build workflow with Claude Code (draft rules above)
3. [ ] Finalize the pipeline for redoing sprites in the Hades style
