// Shared scaffolding for the table-driven matrix consolidation of the
// observer-phase GP-blocker / peace-target branch-pin suites (Refs #3749).
//
// This standalone library (explicit imports, not a `part` fragment — see
// `SPEC/program/dart-file-non-comment-line-size.md` § Extraction shape)
// hosts the fixture families and the truth-table / guard-branch runners
// shared by the matrix test files:
//
//   - `observer_goal_phase_gp_blocker_peace_matrix_test.dart`
//     (GP-blocker contracts: `primaryColonialGpBlocker` +
//     `primaryInvadableOldWorldGpBlocker`).
//   - `observer_goal_phase_gp_blocker_peace_matrix_part2_test.dart`
//     (COLONIAL + EXPAND peace-target guard ladders).
//   - `observer_goal_phase_gp_blocker_peace_matrix_part3_test.dart`
//     (DEVELOP + stalled-below-quota peace-target guard ladders).
//
// All six functions under test share the exact signature
// `({required Game game, required AIWorldSnapshot snapshot})` returning
// `String?` (blocker) or `List<String>` (peace targets), so the two
// blocker contracts collapse into one shared truth-table runner
// ([runBlocker]) and the four peace-target guard ladders collapse into one
// shared case runner ([runPeace]). Coverage is preserved 1:1 — every former
// `test(...)` becomes one matrix row with the same fixture and the verbatim
// regression `reason` — while the duplicated per-file fixtures and
// scaffolding collapse into four shared fixture families (COLONIAL/NW,
// EXPAND/OW, DEVELOP, and the own-vs-partner stalled-lead family).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String gp1 = 'gp1';
const String gp2 = 'gp2';
const String gp3 = 'gp3';
const String gp4 = 'gp4';
const String tribe1 = 'tribe1';
const String tribe2 = 'tribe2';
const String minor1 = 'minor1';
const String minor2 = 'minor2';

// --- COLONIAL / NEW-WORLD fixture family --------------------------------

/// Game with NW provinces enumerated by `(id, ownerId)` pairs.
Game gameWithNwProvinces({
  required int turnNumber,
  required List<Province> nwProvinces,
  List<Player> players = const [
    Player(id: gp1, displayName: 'GP1', isHuman: false),
    Player(id: gp2, displayName: 'GP2', isHuman: false),
    Player(id: gp3, displayName: 'GP3', isHuman: false),
    Player(id: gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [
    Tribe(id: tribe1, displayName: 'T1'),
    Tribe(id: tribe2, displayName: 'T2'),
  ],
  List<MinorNation> minorNations = const [
    MinorNation(id: minor1, displayName: 'M1'),
  ],
}) {
  return Game(
    id: 'g-2509-colonial-peace-blocker-branches-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: nwProvinces),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot fixing the GP at the OW quota (10) with COLONIAL acquisition
/// targets visible — keeps `observerGoalPhaseFor` on COLONIAL so the
/// peace-target helper runs.
AIWorldSnapshot colonialSnapshot({
  required List<String> atWarWith,
  required List<String> invadableNw,
  List<String> adjacentNw = const [],
  String playerId = gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: 21,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
      adjacentNewWorldOwnerFactionIdsSorted: adjacentNw.isEmpty
          ? (invadableNw.isEmpty ? const [tribe1] : const [])
          : adjacentNw,
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

// --- EXPAND / OLD-WORLD fixture family ----------------------------------

/// Game with OW provinces enumerated by `(id, ownerId)` pairs.
///
/// Uses default 4-GP roster + 2 tribes (no minors mounted) so single
/// fixtures can flip ownership without rewiring the roster. Tests that
/// want the minor-first branch supply their own minor list.
Game gameWithOwProvinces({
  required int turnNumber,
  required List<Province> owProvinces,
  List<Player> players = const [
    Player(id: gp1, displayName: 'GP1', isHuman: false),
    Player(id: gp2, displayName: 'GP2', isHuman: false),
    Player(id: gp3, displayName: 'GP3', isHuman: false),
    Player(id: gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [
    Tribe(id: tribe1, displayName: 'T1'),
    Tribe(id: tribe2, displayName: 'T2'),
  ],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-expand-peace-blocker-branches-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: RegionData(provinces: owProvinces),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot fixing the GP below the OW quota (8 / 10) so
/// `observerGoalPhaseFor` returns EXPAND when the game does not also
/// satisfy the COLONIAL-lite turn / NW-ownership preconditions.
AIWorldSnapshot expandSnapshot({
  required List<String> atWarWith,
  required List<String> invadableOw,
  int oldWorldProvincesOwned = 8,
  String playerId = gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

// --- DEVELOP fixture family ---------------------------------------------

/// Game scaffold with a configurable turn number and roster.
///
/// Defaults to a 4-GP roster (no minors / tribes mounted) so tests can
/// freely add `atWarWith` entries that resolve to GP players for the
/// inline `game.playerById(factionId) != null` filter. Tests that need
/// minor / tribe filtering supply their own minor / tribe lists.
Game developGame({
  required int turnNumber,
  List<Player> players = const [
    Player(id: gp1, displayName: 'GP1', isHuman: false),
    Player(id: gp2, displayName: 'GP2', isHuman: false),
    Player(id: gp3, displayName: 'GP3', isHuman: false),
    Player(id: gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-develop-peace-target-branches-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot fixing the GP **at** the OW quota (10) with an empty
/// colonial summary -- no invadable NW, no adjacent NW owners -- so
/// `observerGoalPhaseFor` returns DEVELOP and
/// `developPhaseGpPeaceTargets` is the helper under test.
AIWorldSnapshot developSnapshot({
  required List<String> atWarWith,
  int oldWorldProvincesOwned = kObserverConquestMinOwProvincesPerGp,
  String playerId = gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

// --- Stalled below-quota lead fixture family ----------------------------

/// Own-vs-partner OW roster fixture for `stalledBelowQuotaGpLeadPeaceTargets`.
///
/// `gp_own` holds [ownProvinces]; [partnerId] holds [partnerProvinces].
/// Optional [extraGpId] / [invadableOwnerId] / [minorId] layer in the
/// multi-GP, GP-only-blocker, and collection-guard branches.
Game ownVsPartnerGame({
  required int ownProvinces,
  required int partnerProvinces,
  required String partnerId,
  String? extraGpId,
  int extraGpProvinces = 0,
  String? invadableOwnerId,
  String? minorId,
  bool atWarWithPartner = true,
  bool atWarWithExtraGp = true,
  bool atWarWithMinor = false,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|gp_own_$i',
        regionId: 'oldWorld',
        ownerId: 'gp_own',
      ),
    for (var i = 1; i <= partnerProvinces; i++)
      Province(
        id: 'oldWorld|${partnerId}_$i',
        regionId: 'oldWorld',
        ownerId: partnerId,
      ),
    if (extraGpId != null)
      for (var i = 1; i <= extraGpProvinces; i++)
        Province(
          id: 'oldWorld|${extraGpId}_$i',
          regionId: 'oldWorld',
          ownerId: extraGpId,
        ),
    if (invadableOwnerId != null)
      Province(
        id: 'oldWorld|frontier',
        regionId: 'oldWorld',
        ownerId: invadableOwnerId,
      ),
    if (minorId != null)
      const Province(
        id: 'oldWorld|minor_hold',
        regionId: 'oldWorld',
        ownerId: 'minor1',
      ),
  ];

  final players = <Player>[
    const Player(id: 'gp_own', displayName: 'GP_OWN', isHuman: false),
    Player(id: partnerId, displayName: partnerId, isHuman: false),
    if (extraGpId != null)
      Player(id: extraGpId, displayName: extraGpId, isHuman: false),
  ];

  final minorNations = <MinorNation>[
    if (minorId != null) MinorNation(id: minorId, displayName: minorId),
  ];

  final relations = <DiplomacyRelation>[
    if (atWarWithPartner)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: partnerId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (extraGpId != null && atWarWithExtraGp)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: extraGpId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (minorId != null && atWarWithMinor)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: minorId,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id: 'g-stalled-below-quota-${ownProvinces}_vs_$partnerProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    diplomacyRelations: relations,
  );
}

AIWorldSnapshot ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: 'gp_own',
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

// --- Blocker-contract truth-table runner --------------------------------

typedef BlockerFn = String? Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

/// One blocker-contract branch row transcribed from a source
/// `*_branches_test`. [matcher] is the verbatim expected blocker (a faction
/// id or `isNull`) and [reason] the verbatim regression rationale.
class BlockerCase {
  const BlockerCase({
    required this.label,
    required this.build,
    required this.matcher,
    required this.reason,
  });

  final String label;
  final (Game, AIWorldSnapshot) Function() build;
  final Object matcher;
  final String reason;
}

void runBlocker(String groupLabel, BlockerFn fn, List<BlockerCase> cases) {
  group(groupLabel, () {
    for (final c in cases) {
      test(c.label, () {
        final (game, snapshot) = c.build();
        expect(fn(game: game, snapshot: snapshot), c.matcher, reason: c.reason);
      });
    }
  });
}

// --- Peace-target guard-branch runner -----------------------------------

typedef PeaceFn = List<String> Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

/// One peace-target guard-branch row transcribed from a source
/// `*_branches_test`. The optional [expectedPhase] re-asserts the shared
/// phase fixture control (skipped for the rows whose source test did not
/// assert the phase), and the optional blocker sanity check mirrors the
/// source rows that first pinned `primary*GpBlocker` before the peace list.
class PeaceCase {
  const PeaceCase({
    required this.label,
    required this.gameBuilder,
    required this.snapshot,
    required this.expectedPeace,
    this.peaceReason,
    this.expectedPhase,
    this.phaseReason,
    this.blockerFn,
    this.blockerExpected,
    this.blockerReason,
  });

  final String label;
  final Game Function() gameBuilder;
  final AIWorldSnapshot snapshot;
  final Object expectedPeace;
  final String? peaceReason;
  final ObserverGoalPhase? expectedPhase;
  final String? phaseReason;
  final BlockerFn? blockerFn;
  final Object? blockerExpected;
  final String? blockerReason;
}

void runPeace(String groupLabel, PeaceFn fn, List<PeaceCase> cases) {
  group(groupLabel, () {
    for (final c in cases) {
      test(c.label, () {
        final game = c.gameBuilder();
        final expectedPhase = c.expectedPhase;
        if (expectedPhase != null) {
          expect(
            observerGoalPhaseFor(snapshot: c.snapshot, game: game),
            expectedPhase,
            reason: c.phaseReason,
          );
        }
        final blockerFn = c.blockerFn;
        if (blockerFn != null) {
          expect(
            blockerFn(game: game, snapshot: c.snapshot),
            c.blockerExpected,
            reason: c.blockerReason,
          );
        }
        expect(
          fn(game: game, snapshot: c.snapshot),
          c.expectedPeace,
          reason: c.peaceReason,
        );
      });
    }
  });
}
