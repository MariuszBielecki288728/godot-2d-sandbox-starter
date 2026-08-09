# 0005: Semantic tiles are separated from art-driven presentation

## Context

Hand-authored atlases need multiple visual cells for one gameplay tile, while saves and multiplayer must remain independent of replaceable art.

## Decision

`WorldState` stores stable semantic tile IDs on stable foreground/background layer IDs. `TilePresentationCatalog` Resource data maps those IDs to project-owned TileSet atlas cells. It deterministically resolves cosmetic variants from seed, coordinate, semantic ID, and layer without recording or transmitting a variant.

## Consequences

Artists can change the atlas, TileSet, and catalog without changing mining, crafting, saves, or protocol identities. Invalid catalog definitions fail validation during development. Semantic solidity remains owned by `TileCatalog`; TileSet collision is its projection. Every mapped visual variant must have effective collision if and only if its semantic tile is solid, and catalog validation rejects mismatches. Background wall variants are semantic non-solids and therefore must not carry collision.

## Non-goals

This does not implement autotiling, parallax/scenic backgrounds, multi-cell props, or an asset/modding framework. Those systems must remain outside authoritative tile identity.
