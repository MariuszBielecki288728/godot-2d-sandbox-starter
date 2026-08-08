# Contributing

Install Godot **4.7.1 stable**, `uv`, and `just`; then run `just bootstrap` and `just check`. The locked `tools/` environment and root `dependencies.json` remain the sources of truth for tooling and Godot dependencies. Do not commit generated `addons/gut/`, `.godot/`, reports, or build output, and do not manually edit `tools/uv.lock`.

## Layer-2 contribution rules

- Inspect adjacent domain code and GUT tests before editing. Use TDD for deterministic behavior and regression fixes where practical.
- Keep authoritative shared state in `src/domain/`/`src/game/`, not `TileMapLayer`, Nodes, UI, or renderer state. Presentation observes and renders it.
- Clients submit intents. Only the host/local authority validates mutations, inventory results, crafting, persistence, and weather.
- Use explicit seeds and stable logical IDs for generated, saved, and networked data. Avoid global randomness and instance IDs in persistent contracts.
- Keep dependencies pinned; do not silently upgrade Godot, GUT, gdtoolkit, or Python tooling.
- Run `just check`; run `just export-windows` for release-facing changes. Network changes must also keep `just network-smoke` green.

Avoid speculative frameworks, global event buses, ECS/DI systems, and empty extension points. This template intentionally excludes enemies, combat, quests, technology trees, and production content until a derived game has a concrete requirement.
