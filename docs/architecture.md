# Architecture

## Ownership and boundaries

The canonical finite world, inventory, recipes, and weather are `RefCounted` domain values. `WorldState` stores semantic IDs in chunk-keyed foreground and background-wall dictionaries; it never knows about Nodes, atlas coordinates, or cosmetic variants. Stable serialized/transport layer IDs are `world_layer:foreground` and `world_layer:background`, not enum ordinals. `WorldCoordinates` is the conversion boundary between tile coordinates and the starter's 16px world-space cells.

Presentation is project-owned data: `assets/tiles/placeholder_tiles.svg`, `resources/tiles/sandbox_tileset.tres`, and `resources/tiles/tile_presentations.tres`. `TilePresentationCatalog` maps semantic ID + layer to TileSet cells. Its explicit local mixer selects a cosmetic variant from world seed, tile coordinate, semantic ID, and layer, without using global RNG. Variants are neither saved nor replicated: equivalent worlds rebuild the same appearance. `WorldView` has separate background-wall and foreground `TileMapLayer` projections; one mutation updates only its affected projection cell. Full foreground cells own centered collision polygons; background cells intentionally have none.

`SandboxAuthority` is the narrow application boundary for mine, place, and craft operations. It checks bounds, reach, tile rules, available inventory, and station capability before making an atomic mutation. Item behavior chooses a layer (`item:stone_wall` places only a background wall); background removal is an explicit layer-aware operation. A local player calls that same authority. A multiplayer client sends an intent to the host; the host applies the authority operation and replicates its result.

## World and generation

`WorldConfig` owns dimensions, chunk size (16), and the current 16px starter render scale. `WorldGenerator` uses explicit seed/configuration and versioned coordinate-derived values, so generation is repeatable regardless of unrelated runtime randomness. It generates only foreground terrain; new worlds begin with empty background walls. The small playable world is fully resident; chunking is a future finite-world storage/render/synchronization seam, not streaming.

Background walls are persistent buildable sandbox cells behind foreground terrain. They may coexist with foreground at the same coordinate, do not collide, and never shelter rain. They are not future scenic/parallax backgrounds (sky, clouds, distant terrain), which remain presentation-only and outside `WorldState`.

## Persistence and multiplayer

`SaveStore` version 2 writes inspectable JSON containing world configuration/seed/layered tile records, spawn, inventory, and weather. It validates the complete schema and semantics before construction: bounds, stable layer/tile/item/weather IDs, layer-compatible IDs, duplicate layer-coordinate records, and inventory limits. Foreground and background records may intentionally share coordinates. There is no migration for transient pre-release version-1 saves.

`WorldState.is_exposed_to_sky(tile)` applies the starter shelter rule using foreground solid tiles only. `WeatherView` observes foreground mutations, reconnects when a loaded world replaces the old one, and invalidates when the canvas transform changes. It remains screen-space presentation and owns no physics.

Layer-aware ENet intents and authoritative tile updates carry stable semantic layer IDs. The two-process smoke converges a foreground mutation and a background mutation using the same production codec and transport adapter. This is a transport proof, not lockstep, matchmaking, or Internet multiplayer.

Future adjacency-aware/autotile art belongs behind the presentation resolver, so it can inspect neighbors without changing semantic state, saves, networking, or gameplay. Large props and scenic environments remain separate future systems.
