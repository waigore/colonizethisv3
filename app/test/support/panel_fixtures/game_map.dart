// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game shaped for the `victory_overlay_*` family.
///
/// `VictoryOverlay` / `VictoryPanel` only read `game.playerById(winnerId)` with
/// a `game.players.first` fallback, so the fixture just needs a deterministic
/// players list: the human ([kPanelTestHumanPlayerId]) first (used as the
/// `winnerPlayerId` and the unknown-winner fallback name) plus one AI opponent
/// so the winner-lookup path is non-vacuous. No map/topology data is required.
Game buildVictoryPanelTestGame() {
  return buildPanelTestGame(
    id: 'victory-panel-widget-test',
    players: [
      panelTestHumanPlayer(),
      Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
    ],
  );
}

/// Lightweight game shaped for the `game_map_players_bar_test` standalone
/// widget contract.
///
/// `GameMapPlayersBar` reads only `game.players` (via
/// `GameMapPlayersBar.greatPowerRoster`, which excludes `game.tribes` ids and
/// sorts by `Player.id`), `game.worldState.oldWorld.provinces[].ownerId` (the
/// chip score), and `factionOwnershipColorMapForOldWorld(game)` (which colours
/// every `game.players` id regardless of province ownership). None of that
/// needs generated map/topology data.
///
/// The fixture provides:
/// - **three** great powers (`gp1` human, `gp2`/`gp3` AI) so the id-sorted chip
///   order and the "further GPs own 0 provinces" assertions are non-vacuous;
/// - **six** unowned Old World provinces — the suite's `gameWithOwnership`
///   helper clears ownership and reassigns province 0 → `gp1` and provinces
///   1–4 → `gp2`, so it requires `provinces.length >= 6`;
/// - one **tribe** (`t1`) so the tribe-exclusion and empty-roster assertions
///   (which derive a tribe-only player list from `game.tribes`) stay meaningful.
Game buildPlayersBarTestGame() {
  return buildPanelTestGame(
    id: 'players-bar-widget-test',
    players: [
      panelTestHumanPlayer(),
      const Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
      const Player(id: 'gp3', displayName: 'Third Power', isHuman: false),
    ],
    oldWorldProvinces: const [
      Province(id: 'oldWorld|p0', regionId: 'oldWorld', displayName: 'Alpha'),
      Province(id: 'oldWorld|p1', regionId: 'oldWorld', displayName: 'Beta'),
      Province(id: 'oldWorld|p2', regionId: 'oldWorld', displayName: 'Gamma'),
      Province(id: 'oldWorld|p3', regionId: 'oldWorld', displayName: 'Delta'),
      Province(id: 'oldWorld|p4', regionId: 'oldWorld', displayName: 'Epsilon'),
      Province(id: 'oldWorld|p5', regionId: 'oldWorld', displayName: 'Zeta'),
    ],
    tribes: const [Tribe(id: 't1', displayName: 'Tribe One')],
  );
}

/// Lightweight game shaped for the in-game side/pause-menu chrome family
/// (`game_side_menu_test`, `game_side_menu_320dp_min_viewport_test`,
/// `pause_menu_side_menu_specs_test`).
///
/// `GameSideMenu` reads only the active `Game` from `currentGameProvider` and,
/// for the read-only Game Parameters dialog, `game.infiniteMode`
/// (`GameParametersDialog` takes just that bool). The pause menu reads no game
/// state at all. None of these surfaces touch generated map/topology data, so a
/// single-human default game is the full shape they need.
///
/// Suites that assert the "Infinite mode: On" line apply
/// `game.copyWith(infiniteMode: true)` themselves; the base fixture leaves
/// `infiniteMode` at its default (`false`).
Game buildSideMenuTestGame() {
  return buildPanelTestGame(
    id: 'side-menu-widget-test',
    players: [panelTestHumanPlayer()],
  );
}

/// Lightweight game shaped for the shell/game-screen chrome specs
/// (`shell_game_screen_specs_test`; Refs #3656).
///
/// The `GameScreen` group pumps the screen with `mapViewDataProvider`
/// overridden to `null`, so the map canvas is never mounted and no generated
/// map/topology data is read. The assertions gate only on chrome that derives
/// from a `Game` plus provider overrides the suite supplies itself: the pause
/// (`Icons.menu`) icon, exactly one Next-turn `CtNinePatchButton`, the
/// `VictoryOverlay` (the victory case applies `game.copyWith(victory:)` keyed on
/// `game.players.first.id`), the turn-resolution-blocking disable, and the
/// game-start intro overlay.
///
/// A single human ([kPanelTestHumanPlayerId]) is therefore the full shape these
/// specs need; `game.players.first` resolves the synthetic victory winner.
Game buildGameScreenSpecsTestGame() {
  return buildPanelTestGame(
    id: 'game-screen-specs-widget-test',
    players: [panelTestHumanPlayer()],
  );
}

/// Lightweight game shaped for the `GameMapArea` shell-entry auto-center widget
/// suite (`game_map_area_shell_entry_center_test`; Refs #3656).
///
/// The widget group asserts only shell-entry chrome derived from `game.players`
/// plus observe state: on mount the secondary highlight equals the current
/// player's `capitalTile.toTileKey()`, the province overlay stays closed, and
/// the home-to-capital corner control enables/disables purely from
/// `shell.viewingPlayerId != null` (normal play / player observe → enabled;
/// global observe → disabled). None of that reads generated map/topology data:
/// `_applyCapitalCenter` (`game_map_area_view.dart`) sets the highlight
/// unconditionally, and both the camera move (`ct_region_map_game.dart`
/// `centerOnTileKey`) and the highlight ring paint
/// (`region_map_component_render_markers.dart` `_paintTileOutlineRing`) safely
/// no-op when the capital tile falls outside the mounted region bounds.
///
/// The fixture provides a single human ([kPanelTestHumanPlayerId]) so
/// `players.first`, `firstWhere((p) => p.isHuman)`, and the player-observe
/// (`setModePlayer(players.first.id)`) lookups all resolve it. Its old-world
/// `capitalTile` drives the highlight assertion. Pair it with
/// `buildLightweightMapViewData()` so the canvas mounts without the ~7-11s
/// `getDebugInitGameResult()` map generation.
Game buildShellEntryCenterTestGame() {
  return buildPanelTestGame(
    id: 'shell-entry-center-widget-test',
    players: const [
      Player(
        id: kPanelTestHumanPlayerId,
        displayName: 'Test Human',
        isHuman: true,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'cap',
          x: 2,
          y: 3,
        ),
      ),
    ],
  );
}

/// Lightweight game shaped for the work-target selection-prompt overlay suites
/// that mount a full `GameMapArea` purely to assert banner chrome
/// (`game_map_selection_prompt_dark_tokens_test`,
/// the explore-prompt cases in `game_map_area_selection_mode_test`; Refs #3656).
///
/// Entering explore selection mode (`StartCivilianWorkTargetSelectionEvent`)
/// only requires the referenced unit to exist: `_startWorkTargetSelection`
/// (`game_map_area_selection.dart`) looks the unit up, sets a non-null
/// `_cachedValidTileKeys` (possibly empty) via
/// `resolveValidTileKeysForCivilianWorkSelection`, and the canvas stack mounts
/// the "Select a tile, or click cancel" banner whenever
/// `validTileKeysForSelection != null` (`game_map_canvas_stack.dart`
/// `inWorkTargetSelectionMode`). The banner chrome (dark tokens, the
/// `CtNinePatchButton` cancel control) never reads generated map/topology data,
/// so an off-map explorer on the 1×1 lightweight map is sufficient.
///
/// The fixture provides a single human ([kPanelTestHumanPlayerId]) owning one
/// Explorer civilian in the old world so
/// `game.worldState.oldWorld.units.first.id` resolves the sample unit those
/// suites pass to the selection event. Pair it with
/// `buildLightweightMapViewData()` so the canvas mounts without the ~7-11s
/// `getDebugInitGameResult()` map generation.
Game buildSelectionPromptTestGame() {
  const human = kPanelTestHumanPlayerId;
  const province = 'oldWorld|p1';
  return buildPanelTestGame(
    id: 'selection-prompt-widget-test',
    oldWorldProvinces: const [
      Province(
        id: province,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Alpha',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'civ_explorer',
        type: kUnitTypeExplorer,
        ownerId: human,
        locationProvinceId: province,
        tileKey: 'oldWorld|p1|0|0',
      ),
    ],
  );
}

/// Lightweight game shaped for the `game_map_area_event_feed_test` suite, which
/// mounts a full `GameMapArea` and asserts only on the player-turn event-feed
/// chrome driven by `AppEventBus` events (Refs #3656).
///
/// Every feed line is produced from the emitted event payload, not generated
/// map data (`game_map_area_turn_feed.dart`): research/diplomacy/discovery lines
/// read only player display names, the work-completed line locates the tile key
/// carried by the event, and the naval-battle line resolves its locate tile via
/// `portsByProvinceSeaboard` (`tileKeyForSeaZoneLocation`) when no
/// `gameServiceProvider` map data is registered — so a port-seaboard entry is
/// the only map-shaped data needed.
///
/// The fixture provides:
/// - the human ([kPanelTestHumanPlayerId]) plus one AI great power (`gp2`), both
///   with display names, so `firstWhere((p) => p.isHuman)`, the opponent
///   `firstWhere((p) => p.id != humanId)`, and the diplomacy war-copy name
///   lookups all resolve;
/// - one old-world Explorer civilian so the dispose test's
///   `oldWorld.units.first.id` sample unit exists;
/// - a single `portsByProvinceSeaboard` entry mapping the `sz0` seaboard to a
///   port tile, so the naval feed line resolves a non-empty anchor tile key
///   (`oldWorld|sz0` → `oldWorld|cap|0|0`) while an unknown sea zone stays
///   unresolved (the non-tappable-anchor case).
Game buildMapAreaEventFeedTestGame() {
  const human = kPanelTestHumanPlayerId;
  const capProvince = 'oldWorld|cap';
  const seaZoneId = 'sz0';
  return buildPanelTestGame(
    id: 'map-area-event-feed-widget-test',
    players: const [
      Player(id: human, displayName: 'Test Human', isHuman: true),
      Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
    ],
    // The province is intentionally left unowned: the event-feed suite mounts
    // the players bar, whose per-player score chip renders the owned-province
    // count. Owning exactly one province here would render a "1" chip that
    // collides with the news-feed badge's "1" count
    // (`find.text('1')` findsOneWidget).
    oldWorldProvinces: const [
      Province(
        id: capProvince,
        regionId: 'oldWorld',
        displayName: 'Capital',
        townTileKey: 'oldWorld|cap|0|0',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'civ_explorer',
        type: kUnitTypeExplorer,
        ownerId: human,
        locationProvinceId: capProvince,
        tileKey: 'oldWorld|cap|0|0',
      ),
    ],
    portsByProvinceSeaboard: const {
      'oldWorld|cap|$seaZoneId': 'oldWorld|cap|0|0',
    },
    seaZoneDisplayNameById: const {'oldWorld|$seaZoneId': 'Northern Sea'},
  );
}

/// Lightweight game shaped for the `player_turn_event_feed_narrow_inset_test`
/// suite, which mounts a full **narrow** `GameMapArea` purely to assert the
/// floating `PlayerTurnEventFeedCard`'s `Positioned.right` inset contract
/// (Refs #2870 S3 / Req 11, Refs #3656).
///
/// The suite (a) toggles `mapViewState.showPlayerTurnEventsFeed` on via
/// `copyWith` so the narrow feed card mounts, and (b) opens the province bottom
/// sheet by feeding `mapProvincePanelProvider.reportMapTileTapped` a tile key
/// pulled from `tileKeysByRegionAndProvince['oldWorld']`. The narrow inset
/// contract is independent of generated map/topology data: the feed card sits
/// at `kMapOverlayEdgeInset` whether the province panel is open or closed (the
/// narrow code path never applies the wide `gameMapWideOverlayRightInset`), and
/// `reportMapTileTapped` only stores the tapped tile key (no province geometry
/// lookup — see `map_province_panel_provider.dart`).
///
/// The fixture therefore provides a single human ([kPanelTestHumanPlayerId])
/// owning one old-world province whose `tileKeysByRegionAndProvince` entry
/// supplies the `_firstOldWorldTileKey` the suite taps; that tile key maps back
/// to the seeded province so the opened narrow province overlay resolves real
/// (if minimal) province data rather than an unknown id. Pair it with
/// `buildLightweightMapViewData()` so the canvas mounts without the ~7-11s
/// `getDebugInitGameResult()` map generation.
Game buildEventFeedNarrowInsetTestGame() {
  const human = kPanelTestHumanPlayerId;
  const capProvince = 'oldWorld|cap';
  return buildPanelTestGame(
    id: 'event-feed-narrow-inset-widget-test',
    oldWorldProvinces: const [
      Province(
        id: capProvince,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Capital',
        townTileKey: 'oldWorld|cap|0|0',
      ),
    ],
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        capProvince: ['oldWorld|cap|0|0'],
      },
    },
  );
}
