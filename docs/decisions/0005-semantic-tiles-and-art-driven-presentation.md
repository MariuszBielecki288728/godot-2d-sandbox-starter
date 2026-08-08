# 0005: Semantic tiles are separated from art-driven presentation

## Context

Hand-authored atlases need multiple visual cells for one gameplay tile, while saves and multiplayer must remain independent of replaceable art.

## Decision

`WorldState` stores stable semantic tile IDs on stable foreground/background layer IDs. `TilePresentationCatalog` Resource data maps those IDs to project-owned TileSet atlas cells. It deterministically resolves cosmetic variants from seed, coordinate, semantic ID, and layer without recording or transmitting a variant.

## Consequences

Artists can change the atlas, TileSet, and catalog without changing mining, crafting, saves, or protocol identities. Invalid catalog definitions fail validation during development. A TileSet owns foreground full-cell collision; background variants intentionally have none.

## Non-goals

This does not implement autotiling, parallax/scenic backgrounds, multi-cell props, or an asset/modding framework. Those systems must remain outside authoritative tile identity.
