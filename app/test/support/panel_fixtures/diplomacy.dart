// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

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
