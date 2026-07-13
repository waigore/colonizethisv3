// Topic-split case module (Refs #3997 Phase 8).
// Pin/row coverage preserved 1:1 from the former combined cases file.

// ignore_for_file: unused_element, unused_element_parameter

// EXPAND peace matrix case module (Refs #3749 / #3941).
// Registered from `expand_phase_peace_matrix_test.dart` — the single contract
// file for all four former `expand_phase_planner_*_peace_*_matrix_test.dart`
// shards. Row coverage is preserved 1:1.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

typedef _SoleGpPeaceTargetFn = String? Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

/// Shared snapshot skeleton for the sole-GP peace-target deciders. Only the
/// `playerId`, at-war set, own OW count, and invadable OW frontier matter to
/// these deciders; every other summary stays empty.
AIWorldSnapshot _snapshot({
  required String playerId,
  required List<String> atWarWith,
  int oldWorldProvincesOwned = 0,
  List<String> invadableProvinceIdsSorted = const [],
}) => AIWorldSnapshot(
  playerId: playerId,
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

/// One byte-equivalent branch row transcribed from a source `*_branches_test`.
/// The `game` + `snapshot` are pre-built per row by the decider-appropriate
/// helper below so the matrix runner stays decider-agnostic.
class _Case {
  _Case({
    required this.name,
    required this.game,
    required this.snapshot,
    this.expected,
    this.reason,
  });

  final String name;
  final Game game;
  final AIWorldSnapshot snapshot;

  /// Expected target id; `null` asserts `isNull` (matches the source suites'
  /// `isNull` matcher exactly).
  final String? expected;
  final String? reason;
}

void _runDecider(String label, _SoleGpPeaceTargetFn fn, List<_Case> cases) {
  group(label, () {
    for (final c in cases) {
      test(c.name, () {
        final result = fn(game: c.game, snapshot: c.snapshot);
        if (c.expected == null) {
          expect(result, isNull, reason: c.reason);
        } else {
          expect(result, c.expected, reason: c.reason);
        }
      });
    }
  });
}

// --- soleAtWarGreatPowerId fixtures (plain roster). ---

Game _gameWithGpsAndMinors({
  List<String> playerIds = const [_gp1, _gp2, _gp3],
  List<String> minorIds = const [_minor1],
}) {
  return Game(
    id: 'g-2509-sole-at-war-gp-branches',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 60, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      for (final id in playerIds)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
    minorNations: [
      for (final id in minorIds) MinorNation(id: id, displayName: id),
    ],
  );
}

// --- consolidateGainsSoleGpPeaceTarget fixtures (two-GP OW counts). ---

/// Builds a Game with two GPs (`focus` and `enemy`) whose OW holdings are
/// exactly [focusOw] and [enemyOw] respectively, optionally including
/// additional GP players from [extraGpIds].
Game _twoGpGame({
  required int focusOw,
  required int enemyOw,
  List<String> extraGpIds = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-consolidate-${focusOw}_$enemyOw',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < focusOw; i++)
            Province(
              id: 'oldWorld|focus_$i',
              regionId: 'oldWorld',
              ownerId: 'focus',
            ),
          for (var i = 0; i < enemyOw; i++)
            Province(
              id: 'oldWorld|enemy_$i',
              regionId: 'oldWorld',
              ownerId: 'enemy',
            ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: [
      const Player(
        id: 'focus',
        displayName: 'Focus',
        isHuman: false,
        leaderKey: 'victoria',
      ),
      const Player(
        id: 'enemy',
        displayName: 'Enemy',
        isHuman: false,
        leaderKey: 'napoleon',
      ),
      for (final extra in extraGpIds)
        Player(id: extra, displayName: extra.toUpperCase(), isHuman: false),
    ],
    minorNations: minorNations,
    diplomacyRelations: diplomacyRelations,
  );
}

// --- unwinnableSoleGpFrontierPeaceTarget fixtures (own-vs-partner frontier). ---

/// Builds a minimal `Game` where `gp_own` holds [ownProvinces] OW provinces,
/// the at-war partner `partnerId` holds [partnerProvinces] OW provinces, and
/// the OW map optionally carries a [minorId]-owned province and/or
/// [extraInvadableMinorOwnerId]-owned invadable province.
Game _ownVsPartnerGame({
  required int ownProvinces,
  required int partnerProvinces,
  required String partnerId,
  String? extraGpId,
  int extraGpProvinces = 0,
  String? minorId,
  int minorProvinces = 0,
  String? extraInvadableMinorOwnerId,
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
    if (minorId != null)
      for (var i = 1; i <= minorProvinces; i++)
        Province(
          id: 'oldWorld|${minorId}_$i',
          regionId: 'oldWorld',
          ownerId: minorId,
        ),
    if (extraInvadableMinorOwnerId != null)
      Province(
        id: 'oldWorld|invadable_minor',
        regionId: 'oldWorld',
        ownerId: extraInvadableMinorOwnerId,
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
    if (extraInvadableMinorOwnerId != null)
      MinorNation(
        id: extraInvadableMinorOwnerId,
        displayName: extraInvadableMinorOwnerId,
      ),
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
    id: 'g-unwinnable-sole-gp-${ownProvinces}_vs_$partnerProvinces',
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

void registerExpandPeaceSoleGpIdentityCases() {
  // --- soleAtWarGreatPowerId (plain roster, snapshot at-war set only). ---
  _runDecider('soleAtWarGreatPowerId (truth table)', soleAtWarGreatPowerId,
      <_Case>[
    _Case(
      name: 'empty atWarWith returns null (B1)',
      game: _gameWithGpsAndMinors(),
      snapshot: _snapshot(playerId: _gp1, atWarWith: const []),
      reason:
          'No active wars means no sole-GP foe; both '
          'unwinnableSoleGpFrontierPeaceTarget and '
          'consolidateGainsSoleGpPeaceTarget must short-circuit. A '
          'regression that treated an empty `atWarWith` as a sole-GP '
          'foe would conjure a peace candidate on a peaceful turn.',
    ),
    _Case(
      name: 'atWarWith contains only one minor returns null (B2)',
      game: _gameWithGpsAndMinors(),
      snapshot: _snapshot(playerId: _gp1, atWarWith: const [_minor1]),
      reason:
          '`playerById` filters minor ids out of `gpWars`, so a '
          'minor-only at-war state collapses the resulting list '
          'length to 0. A regression that dropped the `playerById` '
          'filter would treat the minor as a sole GP foe.',
    ),
    _Case(
      name: 'atWarWith contains only an unknown tribe id returns null (B3)',
      // Tribes / removed players are not in `game.players`; `playerById`
      // returns null and the id is excluded from `gpWars`.
      game: _gameWithGpsAndMinors(minorIds: const []),
      snapshot: _snapshot(playerId: _gp1, atWarWith: const [_tribe1]),
      reason:
          'Unknown-faction at-war entries (e.g. NW tribes, removed '
          'players) must be filtered out so the predicate only ever '
          'returns a current Great Power id.',
    ),
    _Case(
      name: 'atWarWith with exactly one GP returns that GP (B4)',
      game: _gameWithGpsAndMinors(),
      snapshot: _snapshot(playerId: _gp1, atWarWith: const [_gp2]),
      expected: _gp2,
      reason:
          'The canonical sole-GP-foe happy path: one entry in '
          '`atWarWith`, that entry resolves to a current Great Power, '
          'and the predicate returns that GP id.',
    ),
    _Case(
      name: 'atWarWith with one GP and one minor returns only the GP (B5)',
      // Minor wars are deliberately ignored when counting GP foes;
      // the resulting `gpWars` list is length 1 and the GP wins.
      game: _gameWithGpsAndMinors(),
      snapshot: _snapshot(playerId: _gp1, atWarWith: const [_gp2, _minor1]),
      expected: _gp2,
      reason:
          'Minor wars are filtered out before the length check, so '
          'a GP + minor mix is treated as a sole-GP foe. A '
          'regression that included minors in `gpWars` would refuse '
          'to elect the GP whenever a concurrent minor war existed.',
    ),
    _Case(
      name: 'atWarWith with two GPs returns null (B6 length guard)',
      game: _gameWithGpsAndMinors(),
      snapshot: _snapshot(playerId: _gp1, atWarWith: const [_gp2, _gp3]),
      reason:
          'The `length != 1` guard refuses to elect a sole-GP foe '
          'when more than one GP is at war. A regression that '
          'returned `gpWars.first` here would peace the wrong GP on '
          'a multi-front war turn (Refs #2509 turn-100 verify exit '
          'code 5).',
    ),
    _Case(
      name: 'atWarWith with two GPs and a minor returns null '
          '(B6 with minor filter)',
      // The minor is filtered, but `gpWars.length` is 2; the null
      // exit stands. Pins that the minor filter does not collapse a
      // two-GP war into a "sole GP plus filtered minor" outcome.
      game: _gameWithGpsAndMinors(),
      snapshot:
          _snapshot(playerId: _gp1, atWarWith: const [_gp2, _gp3, _minor1]),
      reason:
          'Filtering the minor must not turn a two-GP war into a '
          'sole-GP-foe outcome; the predicate must still see two '
          'GPs and return null.',
    ),
  ]);

  test(
    'soleAtWarGreatPowerId determinism: identical inputs produce identical '
    'outputs (must-have #7)',
    () {
      final game = _gameWithGpsAndMinors();
      final snapshot =
          _snapshot(playerId: _gp1, atWarWith: const [_gp2, _minor1]);
      final first = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
      final second = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
      final third = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
      expect(first, _gp2);
      expect(second, first);
      expect(third, first);
    },
  );

  // --- consolidateGainsSoleGpPeaceTarget (two-GP OW counts). ---
  _runDecider(
      'consolidateGainsSoleGpPeaceTarget (truth table)',
      consolidateGainsSoleGpPeaceTarget, <_Case>[
    _Case(
      name: 'returns null when no Great Powers are at war (only minors)',
      game: _twoGpGame(
        focusOw: 20,
        enemyOw: 5,
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'focus',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 10,
          ),
        ],
      ),
      snapshot: _snapshot(
        playerId: 'focus',
        atWarWith: const ['minor1'],
        oldWorldProvincesOwned: 20,
      ),
      reason:
          'soleAtWarGreatPowerId is null when only a minor is at war, so '
          'consolidateGainsSoleGpPeaceTarget must short-circuit before '
          'evaluating OW counts. Otherwise a stray minor war could silently '
          'unlock the consolidate peace for a GP that has no sole-GP enemy '
          'to peace at all.',
    ),
    _Case(
      name: 'returns null when two or more Great Powers are at war',
      game: _twoGpGame(
        focusOw: 20,
        enemyOw: 5,
        extraGpIds: const ['gp3'],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'focus',
            factionId2: 'enemy',
            state: RelationState.atWar,
            score: 10,
          ),
          DiplomacyRelation(
            factionId1: 'focus',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 10,
          ),
        ],
      ),
      snapshot: _snapshot(
        playerId: 'focus',
        atWarWith: const ['enemy', 'gp3'],
        oldWorldProvincesOwned: 20,
      ),
      reason:
          'consolidate peace is scoped to the *sole* GP enemy; with two GP '
          'wars active soleAtWarGreatPowerId returns null and this helper '
          'must defer to nearQuotaHoldPeaceTargets / multi-front peace '
          'paths rather than picking an arbitrary one to peace here.',
    ),
    _Case(
      name: 'returns null at own == consolidate-min - 1 even with a huge lead',
      game: _twoGpGame(focusOw: 11, enemyOw: 1),
      snapshot: _snapshot(
        playerId: 'focus',
        atWarWith: const ['enemy'],
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces - 1,
      ),
      reason:
          'One province below kObserverConquestConsolidateMinOwProvinces '
          '(11 OW today) must defer consolidate peace regardless of how '
          'large the enemy lead is. A regression that flipped `<` to `<=` '
          'here would silently peace one province earlier than SPEC.',
    ),
    _Case(
      name: 'returns enemy at exact consolidate-min boundary with sufficient '
          'lead',
      game: _twoGpGame(focusOw: 12, enemyOw: 1),
      snapshot: _snapshot(
        playerId: 'focus',
        atWarWith: const ['enemy'],
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
      ),
      expected: 'enemy',
      reason:
          'Exactly at kObserverConquestConsolidateMinOwProvinces (12 OW) '
          'with a sufficient lead the consolidate peace must fire. A '
          'regression that flipped `<` to `<` or moved the threshold up '
          'would silently delay locking in observer gains.',
    ),
    _Case(
      name: 'returns null at own == enemyOw + (lead - 1) with consolidate-min '
          'met',
      // enemyOw = 10, focusOw = 12 -> lead = 2 == 3 - 1. Consolidate-min
      // (12) is met, so the lead guard is the only thing keeping this null.
      game: _twoGpGame(focusOw: 12, enemyOw: 10),
      snapshot: _snapshot(
        playerId: 'focus',
        atWarWith: const ['enemy'],
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
      ),
      reason:
          'Lead of exactly (kConsolidateGainsSoleGpProvinceLead - 1) is '
          'one province short of the required gap. The consolidate peace '
          'must defer so the focus GP keeps pressing the war rather than '
          'lock in a marginal lead that a counter-offensive could erase.',
    ),
    _Case(
      name: 'returns enemy at own == enemyOw + lead boundary',
      // enemyOw = 9, focusOw = 12 -> lead = 3 == required. Consolidate-min
      // (12) is met, so the lead boundary is the only deciding guard.
      game: _twoGpGame(focusOw: 12, enemyOw: 9),
      snapshot: _snapshot(
        playerId: 'focus',
        atWarWith: const ['enemy'],
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
      ),
      expected: 'enemy',
      reason:
          'Lead of exactly kConsolidateGainsSoleGpProvinceLead (3) at the '
          'consolidate-min boundary must fire the peace. A regression that '
          'tightened the gap to `>` would silently delay consolidate peace '
          'past the SPEC-authorized "lock observer gains" trigger.',
    ),
  ]);

  // --- unwinnableSoleGpFrontierPeaceTarget (own-vs-partner OW frontier). ---
}
