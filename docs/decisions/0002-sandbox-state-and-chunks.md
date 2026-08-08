# ADR 0002: Domain-owned finite sandbox state

## Status

Accepted.

## Decision

Keep canonical tiles in a chunk-aware `WorldState` domain object, separate tile definitions from tile instances, and render via a presentation observer. Ordinary terrain tiles are not Nodes.

## Consequences

Tests, saves, and host validation can operate headlessly. Chunk coordinates provide a stable future partition for a large finite world without adding streaming or a general engine abstraction now.
