# Agent guidance

## Before editing

Inspect relevant files, nearby tests, and existing patterns first. Make focused changes; do not refactor unrelated code. For deterministic behavior, add or adjust a meaningful test, observe its failure when practical, make the smallest coherent change, and re-run focused then full checks.

## Sandbox architecture

`src/domain/` is typed, deterministic, scene-tree-independent state. The authoritative world is `WorldState`, not a `TileMapLayer`, Node, sprite, or UI. `src/game/` validates player intents and applies canonical mutations; `src/presentation/` receives input and renders observed state; `src/persistence/` owns versioned serialization. Keep tile, pixel, and chunk coordinates distinct; the 16px starter tile size belongs only in `WorldConfig`.

Terrain visual cells and terrain physics cells are both projections of `WorldState`; never add an independent terrain collider. A tile mutation is incomplete until every relevant presentation projection is updated. Changes to mining, placement, or collision require scene/physics integration coverage, not only domain tests. Transport smoke tests must call reusable production adapters rather than carrying production protocol rules only in test scripts.

Tile collision polygons must use the same documented cell-center convention as visuals; boundary integration tests must detect geometry translation, not merely collider presence. Tile/pixel conversion goes through the canonical coordinate helper rather than duplicated arithmetic. Save loading validates semantically complete persistent state before construction and never silently normalizes unknown IDs or invalid limits. Weather exposure/shelter belongs in deterministic domain state; precipitation rendering remains presentation-only.

Presentation depending on mutable `WorldState` must observe relevant state changes; query-only tests do not prove runtime invalidation. Manual-QA controls must avoid editor-reserved shortcuts when embedded Godot play is supported. Weather occlusion calculations use canonical world/tile coordinates and explicitly convert to screen space.

Any screen-space presentation derived from world coordinates must invalidate or recompute when the camera/canvas transform changes, not only when domain state changes. Hard player teleports and reloads must explicitly define camera behavior; never leave smoothing to interpolate from stale presentation state accidentally.

The host owns shared world, inventory/crafting results, weather, and saves. Clients request intents and never declare a mutation authoritative. Never trust client-provided player position, inventory contents, capabilities, reach, cooldowns, permissions, or any other value used to validate that client's own intent; resolve those inputs from host-owned state. Single-player goes through the same authority path. Randomness must be explicitly seeded or derived deterministically. IDs in saves and network messages must be stable semantic IDs, never array ordinals, resource paths alone, or instance IDs.

Never encode atlas cells or cosmetic variant IDs in authoritative state; presentation mapping is Resource-driven and variants are deterministic, local-only resolution. Foreground and background-wall mutations are separate authoritative operations. Background walls never create physics or shelter and are distinct from scenic/parallax backgrounds. Keep future autotiling behind the presentation resolver, never in domain state or renderer match statements.

Prefer small typed `RefCounted`/`Resource` values over scene objects for domain logic. Do not add an ECS, DI container, service locator, generic event bus, plugin framework, or speculative system. Do not add enemies, combat, quests, technology trees, or production art without explicit request.

## Tooling and validation

Do not broaden CI to every feature-branch push when PR CI already covers those branches. Preserve full PR validation; save runner time through cancellation, cache keys tied to immutable versions/locks/manifests, cheap-first ordering, and short-lived failure artifactsâ€”never skipped checks. Keep ordinary validation on the pinned Linux runner and cross-export Windows from Linux unless a real Windows-specific test requires otherwise. Do not add CI matrices or extra hosted-runner jobs without measurement, and never treat a cache as integrity validation.

Gameplay/project code belongs outside `tools/`; `tools/` is the isolated Python development subsystem. `dependencies.json` is the source of truth for manifest-managed dependencies, while `tools/pyproject.toml` plus generated `tools/uv.lock` define Python tooling. Never manually edit `uv.lock`, silently upgrade Godot/GUT/gdtoolkit, or commit generated dependency/cache/build output.

Run `just check` before declaring normal implementation work complete; it includes GUT, scene, and loopback ENet smoke validation. Run `just export-windows` when the task requires export validation. Fix root causes—never disable tests, weaken linting, blanket-suppress warnings, or remove assertions merely to obtain green CI.
