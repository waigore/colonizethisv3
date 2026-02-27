# Save/Load — Technical Design

**SPEC/program** — Contract, storage backend, optional map data, and acceptance criteria for game save/load. Province and region identity in saved state follows [world-model-identity.md](../game/world-model-identity.md) (prefixed ids, region-scoped lookup).

---

## Responsibility

- Define the save/load contract implemented by `colonizethis_save` (GameSaveAdapter): storage backend, key convention, schema, optional map data, and behaviour on load (including legacy saves).
- Cross-referenced by: [world-model.md](../game/world-model.md) (serialization), [ctdev-app.md](ctdev-app.md) (Load Savegame flow), [init-game-tool.md](init-game-tool.md) (save output), [turn-resolution.md](turn-resolution.md) (persist after resolve), [game-setup-pipeline.md](game-setup-pipeline.md) (persist or pass), [plan-update-gp-colours-save-load.md](../project/plan-update-gp-colours-save-load.md) (GP colour override persisted on Game).

---

## Contract

- **Storage backend:** Hive box. One box per store; keys are strings.
- **Key convention:**
  - **Game:** key = `gameId`; value = `Game.toJson()`. Schema is the Game model (no separate version field in MVP).
  - **Optional map data:** keys = `gameId + suffix`; suffixes: `_tileMapByRegion`, `_topologyByRegion`, `_combinedTopology`. Values = JSON produced by the respective model `toJson()` (e.g. `TileMapResult`, `MapTopology`).
- **Province/region identity:** Province and region ids stored in the saved payload are whatever the model stores; for consistency with [world-model-identity.md](../game/world-model-identity.md), any province or region id in saved state follows the same prefixed form and lookup rules as at runtime (no separate serialization format).

---

## Versioning and backward compatibility

- **MVP:** The persisted payload has **no version field**. Schema is the Game model (and optional map-data models); readers do not branch on a save-format version.
- **Legacy:** A *legacy* save is one that (a) has no map-data keys for the game id, and/or (b) has Game JSON that omits fields added in later releases (e.g. `greatPowerColorOverride`, `turnTimeMapping`). Current reader behaviour: missing map-data keys → `loadMapData` returns null; missing Game fields → `Game.fromJson()` yields null or the model’s default for those fields. Backward compatibility is **best-effort**: there is no guarantee that a reader can load saves produced by arbitrarily old formats; the project does not maintain readers for every historical schema.
- **Future option:** The project may introduce a **save-format version** (e.g. a `saveFormatVersion` field in the persisted payload or in a small envelope) and document a **migration strategy**. Future readers could then branch on version, apply migrations for supported versions, or reject unsupported versions explicitly. Scope (MVP vs. add version and migration) is an owner decision; this section records current behaviour and the option.

---

## Optional map data

- Map data (tile maps per region, topology per region, combined topology) is optional. Saves created by ctdev Init Game or init_game with map output include it; legacy saves may have none. Tile map structure and semantics are defined in [map-data.md](map-data.md) § Tile map format; this serialization is for **ctdev/init tooling** (e.g. Load Savegame map view). The main game does not require map data to load.
- **saveMapData:** Writes the three map-data keys for the given `gameId`. Caller supplies `tileMapByRegion`, `topologyByRegion`, `combinedTopology`.
- **loadMapData:** Returns the three maps for `gameId`, or **null** if any of the three keys is missing (legacy save). Ctdev Load Savegame shows a message when map data is absent and cannot open the map view; see [ctdev-app.md](ctdev-app.md) § Load Savegame.

---

## Cross-references

| Concern | Spec |
|--------|------|
| Game/WorldState serialization | [world-model.md](../game/world-model.md) |
| Load Savegame flow, map data absent | [ctdev-app.md](ctdev-app.md) |
| init_game save output (`--output-game`) | [init-game-tool.md](init-game-tool.md) |
| Persist after turn resolve | [turn-resolution.md](turn-resolution.md) |
| Persist or pass after game setup | [game-setup-pipeline.md](game-setup-pipeline.md) |
| GP colour override on Game | [plan-update-gp-colours-save-load.md](../project/plan-update-gp-colours-save-load.md) |

---

## Acceptance criteria

- **Save Game.** Given a Hive box and a Game with id `gameId`, when the system saves the game, then the system writes one entry with key `gameId` and value `Game.toJson()`, and the system logs with prefix `save:` including `gameId` and success (per [ctdev-logging.md](ctdev-logging.md)).
- **Load Game.** Given a Hive box and a `gameId`, when the system loads the game, then the system returns a Game instance from the stored JSON, or null if the key is not found or deserialization fails; on failure the system logs with prefix `save:` including `gameId` and error (per [ctdev-logging.md](ctdev-logging.md)).
- **List game ids.** Given a Hive box, when the system lists game ids, then the system returns only keys that are game ids. Keys ending with `_tileMapByRegion`, `_topologyByRegion`, or `_combinedTopology` are excluded ONLY if their prefix (gameId) exists as a separate key in the box (proving they are map data). This ensures game IDs that happen to end with these suffixes are not incorrectly excluded.
- **Optional map data — save/load round-trip.** Given a Hive box, a `gameId`, and valid `tileMapByRegion`, `topologyByRegion`, and `combinedTopology`, when the system calls saveMapData and then loadMapData for that `gameId`, then loadMapData returns the same three maps (round-trip preserves data).
- **Optional map data — legacy.** Given a Hive box and a `gameId` for which no map-data key exists (or any one of the three keys is missing), when the system calls loadMapData for that `gameId`, then loadMapData returns null.
- **Backward compatibility — missing Game fields.** Given a Hive box and a `gameId` whose stored value is valid Game JSON but omits a field that the current Game model defines (e.g. a field added in a later release), when the system loads the game, then the system returns a Game instance with that field set to null or the model’s default; the system does not fail deserialization solely due to the missing field.
- **Delete.** Given a Hive box and a `gameId`, when the system deletes the game, then the system removes the key `gameId` and the three map-data keys (`gameId + _tileMapByRegion`, etc.); no-op if the game key is not present.
- **Round-trip Game fields.** Given a Game with worldState, players, greatPowerColorOverride, turnTimeMapping, and other serialized fields, when the system saves and then loads by the same game id, then the loaded Game equals the original for all fields covered by `Game.toJson()`/`fromJson()` (as covered by existing game_save_adapter_test.dart).
- **Logging.** Save/load operations use the `save:` prefix and log gameId and success or failure per [ctdev-logging.md](ctdev-logging.md).
