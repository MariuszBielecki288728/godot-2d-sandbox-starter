# ADR 0004: Stable IDs, seeded generation, and versioned saves

## Status

Accepted.

## Decision

Use explicit stable `StringName` identifiers for tiles, items, recipes, capabilities, and weather. Generate from explicit seed/configuration and serialize a format version plus semantic state.

## Consequences

Save and network contracts avoid scene IDs and enum ordinals. Corrupt/unsupported saves fail gracefully. A future migration may optimize full tile records into generated-base-world deltas while preserving the schema version boundary.
