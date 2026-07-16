# World faction capital projection (SoT)

**SPEC/program** — Single player → minor → tribe capital lookup for
`packages/colonizethis_world` (Refs #4038). Companion to
`SPEC/game/capital-and-connectivity.md` (capital identity semantics) without
changing those game rules.

## Motivation

Town connectivity and civilian legality previously each walked
players/minors/tribes for capital tile / province id. Parallel walks drift.
Wave 5 keeps one projection module and routes callers through it.

## Source of truth

| Artifact | Role |
|----------|------|
| `packages/colonizethis_world/lib/src/world/faction_capital.dart` | `capitalTileForFaction`, `capitalProvinceIdForFaction` |
| `civilian_ownership_legality.dart` | Re-exports `capitalTileForFaction` for existing deep importers |
| `town_connectivity.dart` | Uses both helpers; no private capital twins |

Lookup order is always: matching `Game` player (via `playerById`), then
`minorNations`, then `tribes`. When a player exists, minor/tribe walks do not
run even if that player's capital fields are null.

## Visibility downgrade (related SoT)

Spy timer expiry FV→fogged mutation calls
`downgradeFullyVisibleToFogged` in `visibility_map_helpers.dart`. The spy
decay name `downgradeFullyVisibleTilesToFoggedAfterSpyTimerExpiry` is a thin
wrapper only (Refs #4038).

## Acceptance criteria

- Given a `Game` with a player capital tile for faction id `gp1`, when the
  system calls `capitalTileForFaction(game, 'gp1')`, then the system returns
  that player's `capitalTile` and does not consult minors or tribes.
- Given a `Game` with no matching player but a minor nation id `m1` with a
  capital province id, when the system calls
  `capitalProvinceIdForFaction(game, 'm1')`, then the system returns that
  minor's `capitalProvinceId`.
- Given town connectivity resolution for an owned province, when the system
  resolves the owner's capital tile and province id, then the system calls
  `capitalTileForFaction` / `capitalProvinceIdForFaction` and does not define
  a private `_capitalTileForOwner` / `_capitalProvinceIdForOwner` twin in
  `town_connectivity.dart`.
- Given a player visibility map with fullyVisible and fogged tiles, when spy
  timer expiry downgrade runs, then the system mutates only fullyVisible
  listed tiles to fogged via `downgradeFullyVisibleToFogged` (same observable
  outcome as the former inline spy loop).
