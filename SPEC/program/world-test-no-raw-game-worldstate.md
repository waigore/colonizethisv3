# World fog/capital/connectivity/ownership/player-view tests — no raw Game/WorldState (repo lint)

**SPEC/program** — repository lint gate that forbids concern-scoped tests under
`packages/colonizethis_world/test/` from constructing `Game(...)` or
`WorldState(...)` outside `world_test_support/` (Refs #3978, #4038).
Companion to `SPEC/program/world-fog-connectivity-ownership-sot.md` and the
inline-topology gate (`repo.world_test_no_inline_topology_builder`).

## Motivation

Wave 4 migrated distant-sea, fog-decay, capital, and connectivity suites onto
shared `world_test_support` builders (and `TestFixtures` where appropriate).
Wave 5 (#4038) widens the same gate to ownership-transfer and player-view
orphans after those suites call builders/`TestFixtures` only. This keeps
concern-scoped test files from re-introducing hand-rolled `Game` / `WorldState`
blocks that drift from the shared factories.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_world_test_no_raw_game_worldstate.dart` | Checker and CLI |
| `tool/ct_repo_lint_manifest.yaml` (`repo.world_test_no_raw_game_worldstate`) | Rule registration |

## Scan scope

In-scope files under `packages/colonizethis_world/test/` whose basename contains
`fog`, `capital`, `connectivity`, `ownership`, or `player_view`, excluding
`world_test_support/`. Naval, army, province-traversal, and other world tests
stay out of scope until migrated (grandfather shrink-only only if temporarily
required).

## Acceptance criteria

- Given an in-scope fog, capital, connectivity, ownership, or player_view test
  file that contains a call `Game(...)` or `WorldState(...)` outside a line
  comment, when the checker runs, then the checker fails and the violation text
  names that file's repo-relative path.
- Given an in-scope file in that basename set that constructs games only via
  `world_test_support` builders or `TestFixtures` and does not call `Game(` or
  `WorldState(`, when the checker runs, then the checker does not fail for that
  file.
- Given `Game(` or `WorldState(` only inside `world_test_support/` or in a
  world test whose basename is outside the in-scope set, when the checker runs,
  then the checker does not fail because of that file.
