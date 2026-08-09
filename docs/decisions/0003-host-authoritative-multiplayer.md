# ADR 0003: Host-authoritative sandbox actions

## Status

Accepted.

## Decision

Clients submit intents; the host owns canonical mutations, inventory/crafting outcomes, weather, and persistence. Intent packets never provide player position or any other value used to validate that sender's own action. The host/session resolves those values from host-owned state and supplies them to `SandboxAuthority`; single-player invokes that same authority locally. ENet is used for the starter loopback transport smoke with a fixed host-owned player tile, intentionally without player replication.

## Consequences

The project does not use deterministic lockstep: deterministic generation benefits saves and tests, but replication is authoritative host state/results. Steam, matchmaking, NAT traversal, and dedicated-server infrastructure remain intentionally out of scope.
