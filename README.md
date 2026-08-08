# Godot 2D Sandbox Starter

An AI-friendly reusable GitHub template for finite, side-view, tile-based 2D sandbox games. It proves a small vertical slice: deterministic terrain, character movement, mining, building, inventory, station-gated crafting, versioned saves, weather presentation, and an authoritative loopback multiplayer mutation.

It is an engineering foundation, not a finished game or content pack. All tile visuals and content (`dirt`, `stone`, `ore`, and `workbench`) are deliberately generic placeholders. This repository deliberately does not include combat, enemies, quests, a technology tree, lore, production artwork, or online-service infrastructure.

## Quick start

```text
just bootstrap
just check
just run
```

Requirements are Godot **4.7.1 stable** (standard GDScript build), `uv`, and `just`. Set `GODOT_BIN` if Godot is not on PATH. `just bootstrap` installs the locked Python developer tools and the SHA-256-verified GUT dependency declared by `dependencies.json`.

## Playable slice controls

| Input | Action |
| --- | --- |
| A / D | Move left / right |
| Space | Jump |
| Left mouse | Mine a nearby tile |
| Right mouse | Place the selected placeable item |
| C | Craft a stone block when beside a workbench |
| Q | Cycle the selected placeable inventory item |
| F5 / F9 | Save / load `user://sandbox-save.json` |

The initial weather is rain so the boundary is visible. `Q` cycles placeable items currently held. Workbenches and crafted stone blocks can both be placed and recovered; natural stone remains raw stone when mined. Rain uses a simple vertical shelter rule: a solid tile above blocks it, so rain is visible outside but not beneath roofs or terrain. The HUD is only a view of the domain inventory and weather; it does not own any gameplay state.

## Architecture

`src/domain/` contains `RefCounted` state and deterministic rules independent of the scene tree: the finite chunk-aware `WorldState`, tile definitions, inventory, recipes, and weather. `src/game/` contains the host-authoritative actions. `src/presentation/` draws state and accepts input; it is never the authority. `src/persistence/` encodes an inspectable JSON save with an explicit format version. Pixel size is centralized in `WorldConfig.TILE_SIZE_PIXELS` (16), while world/chunk coordinates remain integer tile coordinates.

World generation uses the explicit seed, configuration, and a versioned deterministic generator. Chunk coordinates are a storage concern now and a future render/persistence/network partition seam; no streaming system is implied. See [docs/architecture.md](docs/architecture.md) and the ADRs for the fuller rationale.

## Commands

| Command | Purpose |
| --- | --- |
| `just format` / `just format-check` | Format or check first-party Python and GDScript. |
| `just lint` | Run Ruff and gdtoolkit linting. |
| `just test` | Run Pytest and GUT unit, integration, and simulation tests. |
| `just network-smoke` | Start headless host and client processes using real local ENet transport, then prove a client intent is host-validated and replicated. |
| `just check` | Standard local gate: formatting, lint, tests, import, scene smoke, and network smoke. |
| `just export-windows` | Create an ignored Windows debug export. |

`just check` is expected before a PR; CI runs the same checks and a Windows export. The network smoke is intentionally small: it tests two real Godot processes, ENet transport, and a representative tile mutation, not matchmaking or Internet deployment.

## Template use

Use GitHub's **Use this template** action, keep the stable IDs in save/network contracts, and replace placeholder presentation in a derived game. Add game-specific content outside this template's generic domain rules. Read [AGENTS.md](AGENTS.md) and [CONTRIBUTING.md](CONTRIBUTING.md) before assigning changes to an agent.
