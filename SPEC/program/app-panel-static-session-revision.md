# App panel static session revision SoT

**SPEC/program** — Single owner of the panel/overlay `{gameId, turnNumber, worldRevision}` triple and shared topology-node hash under `app/lib/`. Behavior of session caches is unchanged (Refs #4687 / #4688 / #4720). Lint: `repo.app_panel_static_session_revision`.

## Canonical module

`app/lib/providers/panel_session_revision.dart` owns:

- `PanelStaticSessionRevision` and `panelStaticSessionRevision(Game)`
- `panelWorldRevision` / `panelOrdersRevision` (unchanged hash inputs from wave 24)
- `panelTopologyRevision(MapTopology)` — hashes `topology.nodes` in list order

Identical 3-field typedefs elsewhere are aliases of `PanelStaticSessionRevision`. Larger per-panel records may stay flattened but must copy `gameId` / `turnNumber` / `worldRevision` from `panelStaticSessionRevision` (not re-read `Game`).

## Forbidden outside the canonical module

Under `app/lib/**` (generated suffixes excluded):

- Combined idiom `gameId: game.id` + `turnNumber: game.worldState.turnState.turnNumber` + `worldRevision: panelWorldRevision`
- A local `provinceOverlayWorldRevision` declaration
- A duplicate `Object.hash` of the four world operands (`turnNumber`, `purchasedTilesByTileKey.length`, `tileKeysByRegionAndProvince.length`, `players.length`)

A bare `worldRevision: panelWorldRevision(game)` read without the other two fields is reuse, not a violation.

## Relation to open-path caches

Empire-rail and MAP20001 reopen caches continue to key on static revision; see [app-ui-wiring.md](app-ui-wiring.md) § Empire-rail panel open path. This SoT does not change hit/miss semantics or the 1 s surface budget.

## Acceptance criteria

- Given a temporary `app/lib` Dart file outside `panel_session_revision.dart` that inlines `gameId: game.id`, `turnNumber: game.worldState.turnState.turnNumber`, and `worldRevision: panelWorldRevision(game)`, when the System runs `runCheckAppPanelStaticSessionRevisionSot`, then the checker exits non-zero and names that file (Refs #4734).
- Given `app/lib/providers/panel_session_revision.dart` is the only owner of that idiom on the workspace, when `dart run tool/ct_repo_lint.dart` runs rule `repo.app_panel_static_session_revision`, then the rule passes and exits `0` (Refs #4734).
