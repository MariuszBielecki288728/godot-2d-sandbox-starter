# ADR 0003: Host-authoritative sandbox actions

## Status

Accepted.

## Decision

Clients submit intents; the host owns canonical mutations, inventory/crafting outcomes, weather, and persistence. Single-player invokes the same `SandboxAuthority` locally. ENet is used for the starter loopback transport smoke.

## Consequences

The project does not use deterministic lockstep: deterministic generation benefits saves and tests, but replication is authoritative host state/results. Steam, matchmaking, NAT traversal, and dedicated-server infrastructure remain intentionally out of scope.
