# Plan update: persist and load GP colour override (point 7)

Replace **Section 7 (Load Savegame flow)** and extend implementation so that overridden GP colours are part of the game setup and are saved/loaded with the game. GDD colours remain the default when no override is present; game setup choices (including colour overrides) must be respected on load.

---

## Revised Section 7: Save and load GP colour override

- **Persist on Game:** Add an optional field on the `Game` model, e.g. `greatPowerColorOverride`, of type `Map<String, List<int>>?` (GP id → `[r, g, b]`) so it is serialized with `game.toJson()` and deserialized in `Game.fromJson()`. When present, it represents the setup-time choice of map colours for Great Powers; when null or empty, map rendering uses GDD defaults.
- **Set at game creation:** In `runInitGame`, when building the initial `Game` (e.g. in `createGameFromGeneratedMaps` or in the orchestrator after setup), set `greatPowerColorOverride` from `options.greatPowerColorOverride` so the game carries the user’s choices from the Init Game Config screen.
- **Save:** No change to save adapter; the new field is part of `Game.toJson()` / `Game.fromJson()`, so existing save/load continues to persist it.
- **Load Savegame flow:** When building `InitGameMapViewData` from a **loaded** game (ctdev Load Savegame), pass `greatPowerColorOverride: loadedGame.greatPowerColorOverride` into `buildInitGameMapViewData(...)`. Thus the map and Running Game view use the same colours that were chosen at setup when the game was created. If the save has no override (legacy or default setup), `greatPowerColorOverride` is null and the map uses GDD defaults.
- **Principle:** GDD default colours are the fallback; any game setup choices (including ctdev Init form colour dropdowns) are stored on the game and restored on load so that the map always reflects the setup that was used for that game.

---

## Additional implementation steps

- **colonizethis_models (Game):**
  - Add `final Map<String, List<int>>? greatPowerColorOverride;` to `Game` (e.g. GP id → `[r, g, b]`). Default `null` in constructor and in `copyWith`.
  - In `toJson()`, encode as e.g. `'greatPowerColorOverride': greatPowerColorOverride?.map((k, v) => MapEntry(k, v))` (Map<String, List<int>> serializes to JSON object of arrays).
  - In `fromJson()`, read optional `greatPowerColorOverride` and convert value lists to `List<int>`; when absent, use `null`.

- **colonizethis_logic (runInitGame):**
  - After creating the game (e.g. `setupResult.game`), set `game = game.copyWith(greatPowerColorOverride: options.greatPowerColorOverride)` before returning (and when writing PNG, etc.). Store the same override in `InitGameResult.greatPowerColorOverride` for ctdev so the debug map and Running Game screen can use it without reading from the game if they already have the result; when building view from a **loaded** game, ctdev (and any other consumer) must use `loadedGame.greatPowerColorOverride`.

- **ctdev Load Savegame:**
  - When loading a game and building `InitGameMapViewData` for the Init Game Map Debug screen (and later for Running Game if applicable), call `buildInitGameMapViewData(..., greatPowerColorOverride: _game.greatPowerColorOverride)`. Convert `Map<String, List<int>>?` to `Map<String, (int r, int g, int b)>?` at the call site if the builder expects the tuple form.

- **Spec (ctdev-app.md) Load Savegame bullet:**
  - State that when building the map view from a loaded game, ctdev passes the game’s `greatPowerColorOverride` (if any) so that ownership colours match the setup that was used when the game was created; when the save has no override, GDD default colours are used.

- **Spec (map-data.md or game/world-model):**
  - Optionally note that `Game` may carry an optional `greatPowerColorOverride` (setup-time GP map colours) for display; when present it is used by map visualizers and ctdev, and when absent GDD defaults apply.

---

## Acceptance criteria

- **Override persist and load:** Save a game created with GP colour overrides (Init Game Config) → load savegame → Init Game Map Debug shows the same colours; Start Game → Running Game map shows the same colours (not GDD defaults).
- **Legacy / no override:** Load a save with no override (legacy or default setup) → both Init Game Map Debug and Running Game use GDD default colours.
- **Serialization round-trip:** `greatPowerColorOverride` round-trips in `Game.toJson` / `Game.fromJson` (optional unit test in colonizethis_models or save package).
