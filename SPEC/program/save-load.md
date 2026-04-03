# Save/Load — Technical Design

**SPEC/program** — Contract, storage backend, required map data, and acceptance criteria for game save/load. Province and region identity in saved state follows [world-model-identity.md](../game/world-model-identity.md) (prefixed ids, region-scoped lookup).

---

## Responsibility

- Define the save/load contract implemented by `colonizethis_save` (GameSaveAdapter): storage backend, key convention, schema, required map data, and behaviour on load for the current schema.
- Cross-referenced by: [world-model.md](../game/world-model.md) (serialization), [ctdev-app.md](ctdev-app.md) (Load Savegame flow), [init-game-tool.md](init-game-tool.md) (save output), [turn-resolution.md](turn-resolution.md) (persist after resolve), [game-setup-pipeline.md](game-setup-pipeline.md) (persist or pass), [plan-update-gp-colours-save-load.md](../project/plan-update-gp-colours-save-load.md) (GP colour override persisted on Game).

---

## Contract

- **Storage backend:** Hive box. One box per store; keys are strings. Hive uses a **lock file** (e.g. `games.lock`) in the store directory so only one process has the box open at a time. Clients that open the box (e.g. ctterm) must handle lock failure appropriately; ctterm does so by showing a lock-prompt screen and deleting the lock only if the user agrees (see [SPEC/tui/ctterm.md](../tui/ctterm.md) §5.1).
- **Key convention:**
  - **Game:** key = `gameId`; value = `Game.toJson()`. Schema is the Game model (no separate version field in MVP). `Game.toJson()` includes all core fields, including `politicalGlyphByPlayerId` (1-character political owner glyphs) so that ownership glyphs on political maps are stable across loads.
  - **gameId constraints:** The `gameId` must be a non-empty string. It may contain any characters except those that would create ambiguity with map-data keys (see below). For clarity, avoid gameIds that end with `_tileMapByRegion`, `_topologyByRegion`, or `_combinedTopology` unless you intentionally want the game to be treated as a potential map-data key (see listGameIds behavior).
  - **Required map data:** keys = `gameId + suffix`; suffixes: `_tileMapByRegion`, `_topologyByRegion`, `_combinedTopology`. Values = JSON produced by the respective model `toJson()` (e.g. `TileMapResult`, `MapTopology`).
- **Province/region identity:** Province and region ids stored in the saved payload are whatever the model stores; for consistency with [world-model-identity.md](../game/world-model-identity.md), any province or region id in saved state follows the same prefixed form and lookup rules as at runtime (no separate serialization format).

---

## Versioning and compatibility

- **MVP:** The persisted payload has **no version field**. Schema is the Game model (and optional map-data models); readers do not branch on a save-format version.
- **No legacy migration guarantee:** The project does not support migration from historical schemas. Loads are expected to target saves created by the current model set.
- **Future option:** The project may introduce a **save-format version** (e.g. a `saveFormatVersion` field in the persisted payload or in a small envelope) and document a migration policy.

---

## Required map data

- Map data (tile maps per region, topology per region, combined topology) is required for playable saves. Tile map structure and semantics are defined in [map-data.md](map-data.md) § Tile map format.
- **saveMapData:** Writes the three map-data keys for the given `gameId`. Caller supplies `tileMapByRegion`, `topologyByRegion`, `combinedTopology`.
- **loadMapData:** Returns the three maps for `gameId` when all required map-data keys are present and valid. If any required key is missing or invalid, load fails with an explicit error; gameplay entry points must reject the save.

---

## Cross-references

| Concern | Spec |
|--------|------|
| Game/WorldState serialization | [world-model.md](../game/world-model.md) |
| Load Savegame flow | [ctdev-app.md](ctdev-app.md) |
| init_game save output (`--output-game`) | [init-game-tool.md](init-game-tool.md) |
| Persist after turn resolve | [turn-resolution.md](turn-resolution.md) |
| Persist or pass after game setup | [game-setup-pipeline.md](game-setup-pipeline.md) |
| GP colour override on Game | [plan-update-gp-colours-save-load.md](../project/plan-update-gp-colours-save-load.md) |

---

## Acceptance criteria

- **Save Game.** Given a Hive box and a Game with id `gameId`, when the system saves the game, then the system writes one entry with key `gameId` and value `Game.toJson()`, and the system logs with prefix `save:` including `gameId` and success (per [ctdev-logging.md](ctdev-logging.md)).
- **Load Game.** Given a Hive box and a `gameId`, when the system loads the game, then the system returns a Game instance from the stored JSON, or null if the key is not found or deserialization fails; on failure the system logs with prefix `save:` including `gameId` and error (per [ctdev-logging.md](ctdev-logging.md)).
- **List game ids.** Given a Hive box, when the system lists game ids, then the system returns only keys that are game ids. Keys ending with `_tileMapByRegion`, `_topologyByRegion`, or `_combinedTopology` are excluded ONLY if their prefix (gameId) exists as a separate key in the box (proving they are map data). This ensures game IDs that happen to end with these suffixes are not incorrectly excluded.
- **Required map data — save/load round-trip.** Given a Hive box, a `gameId`, and valid `tileMapByRegion`, `topologyByRegion`, and `combinedTopology`, when the system calls saveMapData and then loadMapData for that `gameId`, then loadMapData returns the same three maps (round-trip preserves data).
- **Required map data missing.** Given a Hive box and a `gameId` for which any required map-data key is missing, when the system calls `loadMapData` for that `gameId`, then `loadMapData` fails with an explicit error that identifies missing required map data.
- **Delete.** Given a Hive box and a `gameId`, when the system deletes the game, then the system removes the key `gameId` and the three map-data keys (`gameId + _tileMapByRegion`, etc.); no-op if the game key is not present.
- **Round-trip Game fields.** Given a Game with worldState, players, greatPowerColorOverride, turnTimeMapping, and other serialized fields, when the system saves and then loads by the same game id, then the loaded Game equals the original for all fields covered by `Game.toJson()`/`fromJson()` (as covered by existing game_save_adapter_test.dart).
- **Logging.** Save/load operations use the `save:` prefix and log gameId and success or failure per [ctdev-logging.md](ctdev-logging.md).
