// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// These avoid the ~7-11s procedural map generation paid by
// `getDebugInitGameResult()` once per test isolate (Refs #3656). Panels that
// only render from a `Game` (no generated map/topology data) can build the
// minimum shape their assertions read instead of generating a full game.
//
// Modeled on `app/test/production_panel_test_fixtures.dart`; generalize
// incrementally per family rather than adding a monolithic config up front.

import 'package:colonizethis_data/colonizethis_data.dart'
    show unlockingTechByRegimentId, unlockingTechByShipId;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement, homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Default human great-power id used by the lightweight panel fixtures.
const String kPanelTestHumanPlayerId = 'gp1';

/// A single human [Player] with no stockpile/worker customization.
Player panelTestHumanPlayer({
  String id = kPanelTestHumanPlayerId,
  String displayName = 'Test Human',
}) {
  return Player(id: id, displayName: displayName, isHuman: true);
}

/// Builds a lightweight [Game] with explicit per-region provinces/units and
/// fleets. No map generation, topology, or tile data is produced; route any
/// test that needs real generated map/topology data to the serialized-fixture
/// path or the documented `getDebugInitGameResult()` allowlist instead.
Game buildPanelTestGame({
  List<Player>? players,
  List<Province> oldWorldProvinces = const [],
  List<Unit> oldWorldUnits = const [],
  List<Province> newWorldProvinces = const [],
  List<Unit> newWorldUnits = const [],
  List<Fleet> fleets = const [],
  List<Army> armies = const [],
  Map<String, String> portsByProvinceSeaboard = const {},
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
      const {},
  Map<String, String> seaZoneDisplayNameById = const {},
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
  String id = 'panel-widget-test',
  TurnState turnState = const TurnState(
    phase: TurnPhase.orders,
    turnNumber: 1,
  ),
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: turnState,
      oldWorld: RegionData(
        provinces: oldWorldProvinces,
        units: oldWorldUnits,
      ),
      newWorld: RegionData(
        provinces: newWorldProvinces,
        units: newWorldUnits,
      ),
      fleets: fleets,
      armies: armies,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      seaZoneDisplayNameById: seaZoneDisplayNameById,
    ),
    players: players ?? [panelTestHumanPlayer()],
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Lightweight game shaped for the `civilian_units_panel_part*` family.
///
/// Covers what those parts read from `game`:
/// - one human player ([kPanelTestHumanPlayerId]) owning idle civilians of the
///   types the panel groups/labels (Builder, Explorer, Engineer, Merchant), in
///   **both** regions, each with a `tileKey` and a `locationProvinceId`;
/// - allowed work targets exist for those types so the assign-menu assertions
///   run;
/// - one in-progress (working) civilian so the in-progress cancel path renders.
///
/// A non-owning player id (e.g. `'no-such-player'`) exercises the empty state.
Game buildCivilianPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const p1 = 'oldWorld|p1';
  const np1 = 'newWorld|np1';
  return buildPanelTestGame(
    id: 'civilian-panel-widget-test',
    oldWorldProvinces: const [
      Province(
        id: p1,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Alpha',
      ),
      Province(
        id: 'oldWorld|p2',
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Beta',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'civ_builder',
        type: kUnitTypeBuilder,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|0|0',
      ),
      Unit(
        id: 'civ_explorer',
        type: kUnitTypeExplorer,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|0|1',
      ),
      Unit(
        id: 'civ_engineer',
        type: kUnitTypeEngineer,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|1|0',
      ),
      Unit(
        id: 'civ_merchant',
        type: kUnitTypeMerchant,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|1|1',
      ),
      Unit(
        id: 'civ_working',
        type: kUnitTypeBuilder,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: 'oldWorld|p1|2|0',
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetBuildImprovement,
          tileKey: 'oldWorld|p1|2|0',
          totalTurns: 5,
          remainingTurns: 2,
        ),
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: np1,
        regionId: 'newWorld',
        ownerId: human,
        displayName: 'Gamma',
      ),
    ],
    newWorldUnits: [
      Unit(
        id: 'civ_explorer_nw',
        type: kUnitTypeExplorer,
        ownerId: human,
        locationProvinceId: np1,
        tileKey: 'newWorld|np1|0|0',
      ),
    ],
  );
}

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

/// Lightweight game shaped for the in-game Diplomacy *screen* family
/// (`diplomacy_screen_test`, `diplomacy_screen_top_bar_test`,
/// `diplomacy_screen_320dp_min_viewport_test`, `diplomacy_dialogs_test`).
///
/// These suites exercise the `DiplomacyScreen` chrome (`CtTopBar` + back
/// affordance + min-viewport overflow) and the `GrantOrSubsidyDialog`, none of
/// which read generated map/topology data. `DiplomacyScreen` derives its
/// `MapTopology` from `gameServiceProvider.getMapData(...)` inside a `try`
/// (which is absent in widget tests, so the panel falls back to an empty
/// topology), and the `DiplomacyPanel` always renders the three faction-section
/// headings (`Great Powers` / `Minor Nations` / `Tribes`) even with no
/// discovered factions — so the screen suites' `find.text('Great Powers')`
/// pins hold without a generated game.
///
/// The fixture provides:
/// - the human ([kPanelTestHumanPlayerId]) as `players.first` with a non-zero
///   `treasury` so the grant-aid dialog's default amount is affordable (suites
///   override the treasury via `copyWith` for the disabled/warning cases);
/// - one AI great power (`gp2`) so `players[1]` resolves as a grant/subsidy
///   target faction. The opponent is intentionally **not** seeded with a
///   `DiplomacyRelation`, so it stays undiscovered and the GP section heading
///   still renders without a row (the screen suites only assert the heading).
Game buildDiplomacyScreenTestGame() {
  return buildPanelTestGame(
    id: 'diplomacy-screen-widget-test',
    players: const [
      Player(
        id: kPanelTestHumanPlayerId,
        displayName: 'Test Human',
        isHuman: true,
        treasury: 5000,
      ),
      Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
    ],
  );
}

/// Lightweight game shaped for the in-game Diplomacy *panel* widget family
/// (`diplomacy_panel_orders_test`, `diplomacy_panel_chrome_test`,
/// `diplomacy_panel_narrow_layout_test`).
///
/// Unlike [buildDiplomacyScreenTestGame] (which only asserts the always-present
/// section headings and so leaves opponents undiscovered), these suites need at
/// least one **discovered** other Great Power so the panel renders a real
/// faction row with relation badges and diplomatic action buttons. Discovery
/// follows `buildDiplomacyRows` → `buildPlayerView`, which indexes a faction as
/// discovered when a persisted [DiplomacyRelation] involving the human exists
/// (`PlayerView.diplomacyByOtherId`) — no generated map/topology data is read.
///
/// The fixture provides:
/// - the human ([kPanelTestHumanPlayerId]) as `players.first` (the suites read
///   `players.first.id` as the human id) with a non-zero `treasury` so the
///   economic actions render;
/// - one AI great power (`gp2`) seeded with an **at-peace** GP↔GP relation, so
///   the panel surfaces a discovered GP row whose `Declare War` action is
///   enabled (chrome danger-variant + orders confirm/cancel assertions) and
///   whose `PEACE` badge renders. Chrome suites that need a `WAR` badge swap in
///   an at-war relation via `copyWith` themselves.
Game buildDiplomacyPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const rival = 'gp2';
  return buildPanelTestGame(
    id: 'diplomacy-panel-widget-test',
    players: const [
      Player(
        id: human,
        displayName: 'Test Human',
        isHuman: true,
        treasury: 5000,
      ),
      Player(id: rival, displayName: 'Rival Power', isHuman: false),
    ],
  ).copyWith(
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: human,
        factionId2: rival,
        state: RelationState.atPeace,
        score: 50,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
    ],
  );
}

/// Lightweight game shaped for the full diplomacy-*panel* suites that
/// previously paid `getDebugInitGameResult()` for a game seeded with multiple
/// discovered Great Powers, a Minor Nation offering overture stages, and a
/// discovered Tribe (`diplomacy_panel_test`, `diplomacy_panel_rows_test`;
/// Refs #3656).
///
/// Unlike [buildDiplomacyPanelTestGame] (a single discovered GP for the
/// orders/chrome/narrow suites), these suites assert GP-section sorting, the
/// relative-power line colours, the minor overture matrix, and the Tribes
/// section, so the fixture seeds **three** Great Powers, **one** Minor Nation,
/// and **one** Tribe — all discovered through persisted [DiplomacyRelation]s
/// involving the human (`buildDiplomacyRows` → `buildPlayerView` indexes each
/// opponent in `PlayerView.diplomacyByOtherId`). No generated map/topology
/// data is read; pass `const MapTopology()` as the panel topology.
///
/// Shape:
/// - the human ([kPanelTestHumanPlayerId] = `gp1`, `players.first`) with a
///   non-zero `treasury` (so the economic/overture actions render) and one
///   regiment, so its power score is non-vacuous;
/// - `gp2` **at peace** (score 50 → "Neutral" one-word label + `PEACE` badge)
///   with **two** regiments, so it sorts ahead of `gp3` by military strength
///   and reads as the stronger GP (relative-power line → `--danger`);
/// - `gp3` **at war** (score 20 → "Distrustful" one-word label + `WAR` badge) with
///   **one** regiment, so it is roughly equal to the human (relative-power line
///   → `--success`) and the GP rows are a non-vacuous two-element sort;
/// - one Minor Nation `m1` at peace, so the minor row enumerates all four
///   overture stages (Consulate/Embassy/NAP/Join Empire) with the
///   disabled-with-reason states the AC-6 assertions read;
/// - one Tribe `t1` at peace, so the Tribes section renders a discovered row
///   (badge + minors-only filter assertions).
///
/// `gp1` is a defensive power floor for the relative-power maths; regiments use
/// [kPanelTestRegimentType] so `regimentStatsById`/`unitStrength` resolve
/// identically to a generated game.
Game buildDiplomacyRichPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const gp2 = 'gp2';
  const gp3 = 'gp3';
  const minorId = 'm1';
  const tribeId = 't1';
  const type = kPanelTestRegimentType;
  const dummyProvince = 'oldWorld|p1';
  return buildPanelTestGame(
    id: 'diplomacy-rich-panel-widget-test',
    players: [
      const Player(
        id: human,
        displayName: 'Test Human',
        isHuman: true,
        treasury: 5000,
      ),
      const Player(id: gp2, displayName: 'Rival Power', isHuman: false),
      const Player(id: gp3, displayName: 'Third Power', isHuman: false),
    ],
    minorNations: const [MinorNation(id: minorId, displayName: 'Free City')],
    tribes: const [Tribe(id: tribeId, displayName: 'Tribe One')],
    oldWorldUnits: [
      Unit(
        id: 'reg_gp1',
        type: type,
        ownerId: human,
        locationProvinceId: dummyProvince,
      ),
      Unit(
        id: 'reg_gp2_a',
        type: type,
        ownerId: gp2,
        locationProvinceId: dummyProvince,
      ),
      Unit(
        id: 'reg_gp2_b',
        type: type,
        ownerId: gp2,
        locationProvinceId: dummyProvince,
      ),
      Unit(
        id: 'reg_gp3',
        type: type,
        ownerId: gp3,
        locationProvinceId: dummyProvince,
      ),
    ],
  ).copyWith(
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: human,
        factionId2: gp2,
        state: RelationState.atPeace,
        score: 50,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
      DiplomacyRelation(
        factionId1: human,
        factionId2: gp3,
        state: RelationState.atWar,
        score: 20,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
      DiplomacyRelation(
        factionId1: human,
        factionId2: minorId,
        state: RelationState.atPeace,
        score: 50,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
      DiplomacyRelation(
        factionId1: human,
        factionId2: tribeId,
        state: RelationState.atPeace,
        score: 50,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
    ],
  );
}

/// Lightweight game shaped for the `technology_panel_*` family
/// (`technology_panel_test`, `technology_panel_dark_chrome_test`,
/// `technology_panel_funding_toggles_test`,
/// `technology_panel_choose_tech_dialog_test`,
/// `technology_panel_interaction_test`).
///
/// `TechnologyPanel` reads only `game.players` — its `player` argument and the
/// `game.copyWith(players: …)` overrides each suite applies. Research slots,
/// researched chips, and the choose-tech options derive from `player` tech state
/// plus the static `techCatalog`; no generated map/topology data is consumed.
///
/// The single human starts with no researched tech and the default research-slot
/// count (`player.researchSlots ?? 3` → three active + one locked), so the base
/// "None yet" / all-techs-available assertions hold. Suites override
/// `techUnlocked`, `researchSlots`, `researchProgressByTechId`, etc. via
/// `copyWith`; `game.players.skip(1)` is empty for the single-player shape, which
/// the panel handles since it only renders the supplied `player`.
Game buildTechnologyPanelTestGame() {
  return buildPanelTestGame(
    id: 'technology-panel-widget-test',
    players: [panelTestHumanPlayer()],
  );
}

/// Lightweight game shaped for the `trade_screen_*` scaffold/viewport family
/// (`trade_screen_scaffold_test`, `trade_screen_320dp_min_viewport_test`,
/// `trade_screen_issue_acceptance_criteria_e8_test` route-host tests).
///
/// `TradeScreen` (via `CtGameFeatureScreenShell`) reads only `game.players` for
/// the supplied `player`, the static `CommodityCatalog` for the read-only
/// market table, and `game.worldMarketState` (default-empty here) for the Deal
/// Book panels — no generated map/topology data. With the default empty
/// `WorldMarketState`, the Deal Book renders its empty bids/offers panels and
/// the market table renders its catalog-derived rows, so the scaffold/chrome
/// and minimum-viewport assertions hold without procedural map generation.
Game buildTradePanelTestGame() {
  return buildPanelTestGame(
    id: 'trade-panel-widget-test',
    players: [panelTestHumanPlayer()],
  );
}

/// Military regiment type id used by the lightweight military fixture. Matches
/// the regiment ids the `military_units_panel_*` mini-games use, so
/// `isMilitaryUnit`/`regimentTypeDisplayName` resolve identically.
const String kPanelTestRegimentType = 'musketeers';

/// Lightweight game shaped for the `military_units_panel_*` family.
///
/// Covers what those parts read from `game` / `humanPlayerIdWithUnits`:
/// - one human player ([kPanelTestHumanPlayerId]) owning military regiments in
///   **both** regions, each grouped under a non-home [Army] stationed in a
///   province that carries a `displayName` and a `townTileKey` (so region
///   headers, "N regiments · province" subtitles, Move/Split actions, and the
///   Locate tile-key all render exactly as with a generated map);
/// - the old-world army has two regiments so Split renders; the new-world army
///   keeps a single regiment to exercise the minimal block.
///
/// A non-owning player id (e.g. `'no-such-player'`) exercises the empty state.
/// No fleets are included: the part-family assertions only gate on land
/// military presence, so the lighter shape keeps coverage intact.
Game buildMilitaryPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const oldProvince = 'oldWorld|p1';
  const newProvince = 'newWorld|np1';
  const type = kPanelTestRegimentType;
  return buildPanelTestGame(
    id: 'military-panel-widget-test',
    oldWorldProvinces: const [
      Province(
        id: oldProvince,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Alpha',
        townTileKey: 'oldWorld|p1|0|0',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'reg_old_1',
        type: type,
        ownerId: human,
        locationProvinceId: oldProvince,
        medals: 1,
      ),
      Unit(
        id: 'reg_old_2',
        type: type,
        ownerId: human,
        locationProvinceId: oldProvince,
        medals: 2,
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: newProvince,
        regionId: 'newWorld',
        ownerId: human,
        displayName: 'Gamma',
        townTileKey: 'newWorld|np1|0|0',
      ),
    ],
    newWorldUnits: [
      Unit(
        id: 'reg_new_1',
        type: type,
        ownerId: human,
        locationProvinceId: newProvince,
        medals: 0,
      ),
    ],
    armies: const [
      Army(
        id: 'army_old',
        ownerId: human,
        regionId: 'oldWorld',
        stationedProvinceId: oldProvince,
        regimentUnitIds: ['reg_old_1', 'reg_old_2'],
        isHomeArmy: false,
      ),
      Army(
        id: 'army_new',
        ownerId: human,
        regionId: 'newWorld',
        stationedProvinceId: newProvince,
        regimentUnitIds: ['reg_new_1'],
        isHomeArmy: false,
      ),
    ],
  );
}

/// Lightweight game shaped for the `naval_units_panel_part*` family.
///
/// Covers what those parts read from `game` / `humanPlayerIdWithFleets`:
/// - one human player ([kPanelTestHumanPlayerId]) with a defined
///   `capitalProvinceId` + `capitalTile` in the **old world** (so the panel can
///   resolve and label the Home Fleet);
/// - a Home Fleet ([homeFleetIdFor]) in port at the capital carrying two ships,
///   so the Split action and split flow render for the home row;
/// - a **non-home** fleet (`fleet_nh1`) at sea in the old world with two ships,
///   so the `Fleet <id>` row renders with Move/Split actions and the empty
///   `humanPlayerIdWithFleets` fleet filters are non-vacuous;
/// - provinces in **both** regions carrying `townTileKey`, plus
///   `portsByProvinceSeaboard` / `tileKeysByRegionAndProvince` entries so
///   sea-zone and port locate tile keys resolve like a generated map.
///
/// A non-owning player id (e.g. `'no-such-player'`) exercises the empty state.
/// This is the shape the heavier `naval_units_panel_part1` map-derived
/// assertions need; lighter parts simply ignore the unused richness.
Game buildNavalPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const capProvince = 'oldWorld|cap';
  const oldPort = 'oldWorld|p2';
  const newPort = 'newWorld|np1';
  const seaZoneId = 'sz0';
  final homeFleetId = homeFleetIdFor(human);
  return buildPanelTestGame(
    id: 'naval-panel-widget-test',
    oldWorldProvinces: const [
      Province(
        id: capProvince,
        regionId: ow,
        ownerId: human,
        displayName: 'Capital',
        townTileKey: 'oldWorld|cap|0|0',
      ),
      Province(
        id: oldPort,
        regionId: ow,
        ownerId: human,
        displayName: 'Porto',
        townTileKey: 'oldWorld|p2|0|0',
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: newPort,
        regionId: nw,
        ownerId: human,
        displayName: 'Newhaven',
        townTileKey: 'newWorld|np1|0|0',
      ),
    ],
    fleets: [
      Fleet(
        id: homeFleetId,
        ownerId: human,
        regionId: ow,
        inPortAtProvinceId: capProvince,
        ships: const [
          ShipInstance(id: 'h1', typeId: 'carrack'),
          ShipInstance(id: 'h2', typeId: 'galleon'),
        ],
      ),
      Fleet(
        id: 'fleet_nh1',
        ownerId: human,
        regionId: ow,
        seaZoneId: seaZoneId,
        ships: const [
          ShipInstance(id: 'n1', typeId: 'carrack'),
          ShipInstance(id: 'n2', typeId: 'carrack'),
        ],
      ),
    ],
    portsByProvinceSeaboard: const {
      'oldWorld|cap|$seaZoneId': 'oldWorld|cap|0|0',
    },
    tileKeysByRegionAndProvince: const {
      ow: {
        capProvince: ['oldWorld|cap|0|0'],
        oldPort: ['oldWorld|p2|0|0'],
      },
      nw: {
        newPort: ['newWorld|np1|0|0'],
      },
    },
    seaZoneDisplayNameById: const {'oldWorld|$seaZoneId': 'Northern Sea'},
    players: const [
      Player(
        id: human,
        displayName: 'Test Human',
        isHuman: true,
        capitalProvinceId: capProvince,
        capitalTile: CapitalTile(
          regionId: ow,
          provinceId: capProvince,
          x: 0,
          y: 0,
        ),
      ),
    ],
  );
}

/// Lightweight game shaped for the train-at-capital dialog family
/// (`train_military_dialog_test`, `train_naval_dialog_test`,
/// `train_civilians_dialog_test`, `train_dialog_base_test`,
/// `train_dialog_inline_cost_tooltip_test`,
/// `train_dialogs_320dp_min_viewport_test`).
///
/// The train dialogs and the unit panels that open them read only `game.players`
/// (the human with a **capital**, plus the owning player's units/fleets) — no
/// generated map/topology data. The human player is pre-equipped so the dialogs
/// render full trainable rows even when a test passes the base game directly
/// (the cost-tooltip and 320 dp suites build the dialog without a rich
/// `copyWith`):
/// - a **capital** in the old world ([CapitalTile] + `capitalProvinceId`) so
///   `hasCapital` is true and the resource bar / steppers render;
/// - **all regiment and ship unlocking tech** so every Train Military / Train
///   Naval row (and its commodity cost icons/tooltips) renders;
/// - generous `treasury`, `peasants`, and `stockpile` so rows are affordable by
///   default (suites that need a deficit override via `copyWith`).
///
/// It also carries an old-world [Army] (two regiments), a home [Fleet] in port
/// at the capital plus a non-home fleet at sea, and idle civilians at the
/// capital, so the Military / Naval / Civilian panels render their Train pill
/// and open the matching dialog. A non-human opponent (`gp2`) keeps
/// "other players" filters non-vacuous.
Game buildTrainPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const ow = 'oldWorld';
  const nw = 'newWorld';
  const capProvince = 'oldWorld|cap';
  const oldPort = 'oldWorld|p2';
  const newPort = 'newWorld|np1';
  const seaZoneId = 'sz0';
  const type = kPanelTestRegimentType;
  final homeFleetId = homeFleetIdFor(human);
  final techUnlocked = <String, bool>{
    for (final techId in unlockingTechByRegimentId.values) techId: true,
    for (final techId in unlockingTechByShipId.values) techId: true,
  };
  const stockpile = Stockpile(
    quantities: {
      'fabric': 1000,
      'castIron': 1000,
      'lumber': 1000,
      'horses': 1000,
      'steel': 1000,
      'bronze': 1000,
      'coal': 1000,
      'paper': 1000,
    },
  );
  return buildPanelTestGame(
    id: 'train-panel-widget-test',
    oldWorldProvinces: const [
      Province(
        id: capProvince,
        regionId: ow,
        ownerId: human,
        displayName: 'Capital',
        townTileKey: 'oldWorld|cap|0|0',
      ),
      Province(
        id: oldPort,
        regionId: ow,
        ownerId: human,
        displayName: 'Porto',
        townTileKey: 'oldWorld|p2|0|0',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'reg_old_1',
        type: type,
        ownerId: human,
        locationProvinceId: capProvince,
        medals: 1,
      ),
      Unit(
        id: 'reg_old_2',
        type: type,
        ownerId: human,
        locationProvinceId: capProvince,
        medals: 2,
      ),
      Unit(
        id: 'civ_builder',
        type: kUnitTypeBuilder,
        ownerId: human,
        locationProvinceId: capProvince,
        tileKey: 'oldWorld|cap|1|0',
      ),
      Unit(
        id: 'civ_explorer',
        type: kUnitTypeExplorer,
        ownerId: human,
        locationProvinceId: capProvince,
        tileKey: 'oldWorld|cap|1|1',
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: newPort,
        regionId: nw,
        ownerId: human,
        displayName: 'Newhaven',
        townTileKey: 'newWorld|np1|0|0',
      ),
    ],
    armies: const [
      Army(
        id: 'army_old',
        ownerId: human,
        regionId: ow,
        stationedProvinceId: capProvince,
        regimentUnitIds: ['reg_old_1', 'reg_old_2'],
        isHomeArmy: false,
      ),
    ],
    fleets: [
      Fleet(
        id: homeFleetId,
        ownerId: human,
        regionId: ow,
        inPortAtProvinceId: capProvince,
        ships: const [
          ShipInstance(id: 'h1', typeId: 'carrack'),
          ShipInstance(id: 'h2', typeId: 'galleon'),
        ],
      ),
      Fleet(
        id: 'fleet_nh1',
        ownerId: human,
        regionId: ow,
        seaZoneId: seaZoneId,
        ships: const [
          ShipInstance(id: 'n1', typeId: 'carrack'),
          ShipInstance(id: 'n2', typeId: 'carrack'),
        ],
      ),
    ],
    portsByProvinceSeaboard: const {
      'oldWorld|cap|$seaZoneId': 'oldWorld|cap|0|0',
    },
    tileKeysByRegionAndProvince: const {
      ow: {
        capProvince: ['oldWorld|cap|0|0'],
        oldPort: ['oldWorld|p2|0|0'],
      },
      nw: {
        newPort: ['newWorld|np1|0|0'],
      },
    },
    seaZoneDisplayNameById: const {'oldWorld|$seaZoneId': 'Northern Sea'},
    players: [
      Player(
        id: human,
        displayName: 'Test Human',
        isHuman: true,
        capitalProvinceId: capProvince,
        capitalTile: const CapitalTile(
          regionId: ow,
          provinceId: capProvince,
          x: 0,
          y: 0,
        ),
        treasury: 50000,
        techUnlocked: techUnlocked,
        workerPool: const WorkerPool(peasants: 20),
        stockpile: stockpile,
      ),
      const Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
    ],
  );
}

/// Lightweight game shaped for the in-game unit-panel chrome family
/// (`unit_panels_320dp_min_viewport_test`,
/// `unit_panels_widgetbook_dark_chrome_test`).
///
/// These suites mount the Civilian / Military / Naval `UnitsPanelShell` (and the
/// Widgetbook Train dialogs) together and assert **chrome only** — the panel
/// title text, the absence of banned Material chrome, no `RenderFlex` overflow,
/// and the editorial-monocle dark theme — never reading generated
/// map/topology data. The combined train fixture already carries a single human
/// (with a capital, all train tech, and treasury/stockpile) plus civilians, an
/// army with regiments, and home/non-home fleets across both regions, so it is
/// exactly the multi-family shape these panels render. A `const MapTopology()`
/// replaces the debug-init `combinedTopology` the assertions never inspect.
Game buildUnitPanelsTestGame() => buildTrainPanelTestGame();

/// Lightweight game shaped for the structural `ProductionCommodityBreakdownDialog`
/// (PROD20001) suites that only pin **dialog chrome / table layout**
/// (`production_commodity_breakdown_dialog_320dp_min_viewport_test`,
/// `production_commodity_breakdown_dialog_wide_full_width_test`).
///
/// Those suites assert structure only — the localized title, the `Close`
/// `CtNinePatchButton`, the 7-column `DataTable` (commodity + per-phase +
/// total), the wide-path full-width column distribution / no-scrollbar, the
/// narrow-path horizontal `Scrollbar`, and at least one catalog-derived section
/// header (`FOOD` / `RAW MATERIALS` / `MANUFACTURED`). None of that depends on
/// generated map/topology data: the section rows come from the static
/// `CommodityCatalog`, and the per-phase deltas are driven by the
/// `productionDesiredOutputProvider` recipe assignments, not owned tiles. Tests
/// pass `topology: const MapTopology()` and `tileMapByRegion: null`; the
/// economy-preview pipeline returns empty (zero) deltas for a tile-less game, so
/// every commodity renders its `0` cells and the layout assertions hold without
/// the ~7-11 s `getDebugInitGameResult()` map generation.
///
/// The committed wide golden stays on the `getDebugInitGameResult()` allowlist —
/// its pixel baseline was captured against the generated debug-init content, so
/// it cannot move to a hand-built game without re-baselining. The delta-colour
/// pins (positive/negative/zero cell colours) move to
/// [buildProductionBreakdownDeltaTestGame] instead (Refs #3656).
Game buildProductionBreakdownPanelTestGame() =>
    buildPanelTestGame(id: 'production-breakdown-widget-test');

/// Lightweight game shaped for the `production_commodity_breakdown_dialog_spec`
/// **delta-colour** pins (PROD20001): the zero-delta `muted` cells, the
/// positive-delta `success` cells, and the negative-delta `danger` cells.
///
/// The economy-preview pipeline that feeds the dialog
/// (`previewStockpilePhaseDeltasByCommodityForPlayer`) runs its Consumption and
/// Production phases off the player's `workerPool` labour and `stockpile`
/// commodities — **not** owned tiles — so non-zero deltas are reproducible
/// without the ~7-11 s `getDebugInitGameResult()` map generation:
/// - `peasants` are fed `grain` in Consumption (a guaranteed negative `grain`
///   delta) and become idle labour;
/// - that idle labour runs the `lumber_from_timber` recipe when the dialog's
///   `productionDesiredOutputProvider` override assigns it, producing a positive
///   `lumber` delta and consuming `timber` (a negative `timber` delta);
/// - every other commodity stays at `0`, giving the muted zero cells.
///
/// Tests pass `topology: const MapTopology()` and `tileMapByRegion: null`; the
/// Extraction and Riches-to-treasury phases contribute nothing for a tile-less,
/// riches-less game, so only the recipe/consumption deltas above appear.
Game buildProductionBreakdownDeltaTestGame() => buildPanelTestGame(
  id: 'production-breakdown-delta-widget-test',
  players: const [
    Player(
      id: kPanelTestHumanPlayerId,
      displayName: 'Test Human',
      isHuman: true,
      workerPool: WorkerPool(peasants: 20),
      stockpile: Stockpile(
        quantities: {
          'grain': 100,
          'timber': 100,
        },
      ),
    ),
    Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
  ],
);

/// Lightweight game shaped for `grant_or_subsidy_listener_test`.
///
/// `GrantOrSubsidyListener` reads only `game.playerById(targetFactionId)` (and
/// `minorNations` / `tribes` fallbacks) for the confirmation-dialog target name,
/// plus `game.worldState.turnState.turnNumber` and `game.globalGameSeed` for the
/// negotiation-mood event seed — never any generated map/topology data. The
/// fixture provides one human ([kPanelTestHumanPlayerId]) and one AI great power
/// so the suite can resolve a human payer and a non-human grant/subsidy target.
Game buildGrantOrSubsidyListenerTestGame() => buildPanelTestGame(
  id: 'grant-subsidy-listener-widget-test',
  players: [
    panelTestHumanPlayer(),
    const Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
  ],
);
