# Architecture

## Ownership and boundaries

The canonical finite world, inventory, recipes, and weather are `RefCounted` domain values. A `WorldState` stores tiles in chunk-keyed dictionaries and exposes integer tile coordinates. It does not know about Nodes or rendering. `WorldView` and `WeatherView` observe that state and draw placeholder pixels; the view is replaceable and never queried for truth.

`SandboxAuthority` is the narrow application boundary for mine, place, and craft operations. It checks bounds, reach, tile rules, available inventory, and station capability before making an atomic mutation. A local player calls that same authority. A multiplayer client sends an intent to the host; the host applies the authority operation and replicates its result.

## World and generation

`WorldConfig` owns dimensions, chunk size (16), and the starter 16px render scale. `WorldGenerator` uses explicit seed/configuration and versioned coordinate-derived values, so generation is repeatable regardless of unrelated runtime randomness. The small playable world is fully resident; the chunk boundary is a future finite-world storage/render/synchronization seam, not streaming.

## Persistence and multiplayer

`SaveStore` writes versioned inspectable JSON containing world configuration/seed/tile records, spawn, inventory, and weather. It rejects corrupt and unsupported data without instantiating scenes. The initial implementation saves full tile records for clarity; future chunk-delta persistence may replace that representation while retaining stable IDs and version migration.

The loopback ENet smoke starts separate headless host and client processes. The client requests a mine action, the host validates/mutates it, and the client applies the replicated tile result before acknowledging convergence. It is deliberately a minimal transport adapter proof, not lockstep, matchmaking, or an Internet multiplayer solution.
