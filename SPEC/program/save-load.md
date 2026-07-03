# Save/Load — Technical Design

**SPEC/program** — Contract, storage backend, required map data, and acceptance criteria for game save/load. Province and region identity in saved state follows [world-model-identity.md](../game/world-model-identity.md) (prefixed ids, region-scoped lookup).

---

## Responsibility

- Define the save/load contract implemented by `colonizethis_save` (GameSaveAdapter): storage backend, key convention, schema, required map data, and behaviour on load for the current schema.
- Cross-referenced by: [world-model.md](../game/world-model.md) (serialization), [ctdev-app.md](ctdev-app.md) (Load Savegame flow), [init-game-tool.md](init-game-tool.md) (save output), [turn-resolution.md](turn-resolution.md) (persist after resolve; auto-save mirror on complete), [game-setup-pipeline.md](game-setup-pipeline.md) (persist or pass), [plan-update-gp-colours-save-load.md](../project/plan-update-gp-colours-save-load.md) (GP colour override persisted on Game), [main-menu.md](../ui/main-menu.md) (Resume game).

---

## Contract

- **Storage backend:** Hive box. One box per store; keys are strings. Hive uses a **lock file** (e.g. `games.lock`) in the store directory so only one process has the box open at a time. Human-facing clients that open the box (**Flutter app** and **ctdev**) must handle lock failure in a user-visible way (e.g. explain that another instance may hold the store, offer retry or safe exit) and must not delete the lock file without explicit user consent.
- **Key convention:**
  - **Game:** key = `gameId`; value = envelope JSON `{ saveFormatVersion, game }`.
    - `saveFormatVersion`: integer persisted by `colonizethis_save` as a hardcoded program constant.
    - `game`: `Game.toJson()` payload. `Game.toJson()` includes all core fields, including `politicalGlyphByPlayerId` (1-character political owner glyphs) so that ownership glyphs on political maps are stable across loads, and `mapViewState` (Empire overview map zoom + map display toggles) so map UI state restores across load. Diplomacy persistence includes `diplomacyRelations[].formalAlliance` (treaty flag; normalized to `false` on load when `state = atWar`) and `allianceBreakCooldowns` (bilateral post-break overture cooldown records keyed by sorted faction pair + `sinceTurn`; Refs #3811).
  - **gameId constraints:** The `gameId` must be a non-empty string. It may contain any characters except those that would create ambiguity with map-data keys (see below). For clarity, avoid gameIds that end with `_tileMapByRegion`, `_topologyByRegion`, or `_combinedTopology` unless you intentionally want the game to be treated as a potential map-data key (see listGameIds behavior).
  - **Required map data:** keys = `gameId + suffix`; suffixes: `_tileMapByRegion`, `_topologyByRegion`, `_combinedTopology`. Values = JSON produced by the respective model `toJson()` (e.g. `TileMapResult`, `MapTopology`).
- **Province/region identity:** Province and region ids stored in the saved payload are whatever the model stores; for consistency with [world-model-identity.md](../game/world-model-identity.md), any province or region id in saved state follows the same prefixed form and lookup rules as at runtime (no separate serialization format).

### Auto-save slot (Flutter app)

- **Purpose:** One **crash-recovery** slot written in addition to the normal game entry. The in-memory `Game.id` inside the JSON is the real session id; Hive keys for the slot use a **fixed stem** only for storage.
- **Stem:** Constant `kAutoSaveSlotId` = `__colonizethis_autosave` (implementation in `colonizethis_save`). Same layout as a normal game: one JSON key = stem, plus `stem +` map suffixes (`_tileMapByRegion`, `_topologyByRegion`, `_combinedTopology`, optional `_warpLinks`).
- **Listing:** `listGameIds` **never** returns the auto-save stem. Orphan-detection for map suffixes **ignores** keys whose prefix equals `kAutoSaveSlotId` so map-data keys for the slot are never mistaken for user saves.
- **When written:** After a **playable** state is persisted at **turn boundary**: immediately after new-game setup save, and after each **completed** turn resolution (`TurnResolutionComplete`). The app also saves the real `gameId` entry as today; auto-save **mirrors** that state into the slot.
- **Validation / corruption:** If the slot is unreadable (bad JSON, missing map data, or invalid map JSON), the implementation **clears** the slot (all stem keys) and logs with prefix `save:` at warning (or error where appropriate). The main-menu **Resume game** control is hidden until a valid slot exists again.

---

## Versioning and compatibility

- **Required save envelope:** Game payloads must include a `saveFormatVersion` integer and a `game` object.
- **Compatibility check before deserialize:** Load must validate `saveFormatVersion` before calling `Game.fromJson`.
- **Incompatible version behavior:** If `saveFormatVersion` is missing, malformed, or unsupported, load must fail with an explicit incompatibility error outcome and must not return a partially loaded `Game`.
- **Supported versions policy:** `colonizethis_save` owns a hardcoded supported-version set. Versions outside that set are incompatible by definition.
- **Strict API:** `GameSaveAdapter.loadStrict` throws `IncompatibleSaveFormatException` when `saveFormatVersion` is missing or unsupported (or the payload is not a map); it returns null only when the Hive key is absent. Callers that need a typed failure path use `loadStrict`; `load` continues to return null and log for backward compatibility.

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
- **Versioned save envelope.** Given a Hive box and a Game with id `gameId`, when the system saves the game, then the stored value at key `gameId` contains `saveFormatVersion` and `game`, where `game` equals `Game.toJson()` for that Game.
- **Incompatible save version fails load.** Given a Hive box and a `gameId` where the stored payload has missing, malformed, or unsupported `saveFormatVersion`, when the system loads that `gameId`, then the system rejects the payload as incompatible, returns no `Game`, and logs an explicit incompatibility error with prefix `save:`.
- **List game ids.** Given a Hive box, when the system lists game ids, then the system returns only keys that are game ids. Keys ending with `_tileMapByRegion`, `_topologyByRegion`, or `_combinedTopology` are excluded ONLY if their prefix (gameId) exists as a separate key in the box (proving they are map data). This ensures game IDs that happen to end with these suffixes are not incorrectly excluded.
- **Required map data — save/load round-trip.** Given a Hive box, a `gameId`, and valid `tileMapByRegion`, `topologyByRegion`, and `combinedTopology`, when the system calls saveMapData and then loadMapData for that `gameId`, then loadMapData returns the same three maps (round-trip preserves data).
- **Required map data missing.** Given a Hive box and a `gameId` for which any required map-data key is missing, when the system calls `loadMapData` for that `gameId`, then `loadMapData` fails with an explicit error that identifies missing required map data.
- **Delete.** Given a Hive box and a `gameId`, when the system deletes the game, then the system removes the key `gameId` and the three map-data keys (`gameId + _tileMapByRegion`, etc.); no-op if the game key is not present.
- **Round-trip Game fields.** Given a Game with worldState, players, greatPowerColorOverride, turnTimeMapping, and other serialized fields, when the system saves and then loads by the same game id, then the loaded Game equals the original for all fields covered by `Game.toJson()`/`fromJson()` (as covered by existing game_save_adapter_test.dart).
- **Round-trip map view state fields.** Given a Game with `mapViewState.zoomMultiplier`, `mapViewState.showProvinceOverlay`, `mapViewState.showProvinceOwnershipTint`, `mapViewState.showProvinceNamesLayer`, and `mapViewState.showPlayerTurnEventsFeed` set to non-default values, when the system saves and then loads by the same game id, then the loaded Game preserves those map view fields exactly.
- **Legacy save default map view state.** Given a current-envelope save payload where `mapViewState` is absent (legacy save), when the system loads the game, then the loaded Game uses default map view state values (`zoomMultiplier = 1.0`, `showProvinceOverlay = true`, `showProvinceOwnershipTint = false`, `showProvinceNamesLayer = true`, `showPlayerTurnEventsFeed = false`) and gameplay remains functional.
- **Round-trip civilian assignment placement fields.** Given a Game where a civilian `Unit` has `tileKey`, `originTileKey`, and `assignedTileKey` set while work is in progress, when the system saves and then loads by the same game id, then the loaded unit preserves those three fields exactly.
- **Logging.** Save/load operations use the `save:` prefix and log gameId and success or failure per [ctdev-logging.md](ctdev-logging.md).

- **Auto-save round-trip.** Given a Hive box, when the system writes `saveAutoSave` with a valid `Game` and map data for stem `kAutoSaveSlotId`, then `load` with that stem returns an equal `Game` and `loadMapData` returns the same map bundle (as exercised in `game_save_adapter_test.dart`).

- **Auto-save excluded from list.** Given a Hive box that contains only the auto-save stem and its map keys, when the system lists game ids, then the returned list is empty.

- **Auto-save corrupt cleared.** Given a Hive box where the auto-save stem key holds invalid JSON or map data is missing/invalid, when the system validates the slot (e.g. `hasValidAutoSave`), then the system removes all keys for that stem and logs with prefix `save:`; subsequent listing still excludes the stem.
