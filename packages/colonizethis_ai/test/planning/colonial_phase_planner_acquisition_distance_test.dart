// Unit tests for the adjacency-distance iteration order in
// `planColonialAcquisition` in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 § COLONIAL phase planner § planColonialAcquisition,
// "sorted by adjacency distance to owned territory").
//
// The planner walks `ColonialSummary.invadableNewWorldProvinceIdsByDistance`
// (the BFS-distance-ordered list populated by the perception-snapshot
// builder via `reachableNonOwnedProvinceDistancesViaSeas`) when it is
// non-empty, falling back to the lex-sorted
// `invadableNewWorldProvinceIdsSorted` field for synthetic fixtures
// built without a topology. These tests pin both branches plus the
// determinism contract on the distance-ordered iteration.
//
// Fixtures keep the spec's three-method priority (Join Empire ->
// purchase_land -> declareWar) untouched — only the iteration over
// the candidate NW invadable list is being exercised here. Both
// candidate tribes share identical Join-Empire gate state so the
// iteration order is the only thing that picks one tribe over the
// other.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _nearTribe = 'tribeNear';
const String _farTribe = 'tribeFar';

// `_farProvince` sorts ascending before `_nearProvince` so the
// lex-sorted iteration picks the far tribe and the distance-sorted
// iteration picks the near tribe -- making the iteration-order
// divergence directly observable in the planner output.
const String _nearProvince = 'newWorld|near_a';
const String _farProvince = 'newWorld|far_b';

Game _acquisitionGame({
  int activePlayerTreasury = 100000,
  List<Province> newWorldProvinces = const [
    Province(id: _nearProvince, regionId: 'newWorld', ownerId: _nearTribe),
    Province(id: _farProvince, regionId: 'newWorld', ownerId: _farTribe),
  ],
}) {
  return Game(
    id: 'g-2509-colonial-acquisition-distance',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 130, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: newWorldProvinces),
    ),
    players: [
      Player(
        id: _gp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: activePlayerTreasury,
      ),
      const Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
    tribes: const [
      Tribe(id: _nearTribe, displayName: 'Near'),
      Tribe(id: _farTribe, displayName: 'Far'),
    ],
    overtureStates: const [
      OvertureState(
        gpId: _gp1,
        targetId: _nearTribe,
        stage: OvertureStage.nap,
        sinceTurn: 100,
      ),
      OvertureState(
        gpId: _gp1,
        targetId: _farTribe,
        stage: OvertureStage.nap,
        sinceTurn: 100,
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _gp1,
        factionId2: _nearTribe,
        score: 60,
        level: RelationLevel.friendly,
      ),
      DiplomacyRelation(
        factionId1: _gp1,
        factionId2: _farTribe,
        score: 60,
        level: RelationLevel.friendly,
      ),
    ],
  );
}

AIWorldSnapshot _acquisitionSnapshot({
  required List<String> invadableNwLex,
  List<String> invadableNwByDistance = const [],
  String playerId = _gp1,
  int treasury = 100000,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: 10,
      provincesToVictory: 31,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNwLex,
      invadableNewWorldProvinceIdsByDistance: invadableNwByDistance,
    ),
    economy: EconomySummary(treasury: treasury),
    relations: const {},
  );
}

void main() {
  group('planColonialAcquisition iteration order', () {
    test('distance-sorted invadable list overrides lex order when '
        'distance field is non-empty', () {
      // Both `_nearProvince` and `_farProvince` satisfy the Join
      // Empire gates. Lex order would pick `_farProvince` (sorts
      // first), but the distance-sorted list lists `_nearProvince`
      // first because it is closer to owned territory. The planner
      // must surface the near tribe per the spec wording "sorted
      // by adjacency distance to owned territory".
      final game = _acquisitionGame();
      final snapshot = _acquisitionSnapshot(
        invadableNwLex: const [_farProvince, _nearProvince],
        invadableNwByDistance: const [_nearProvince, _farProvince],
      );

      final target = planColonialAcquisition(game: game, snapshot: snapshot);

      expect(target, isNotNull);
      expect(target!.targetFactionId, _nearTribe);
      expect(target.method, AcquisitionMethod.joinEmpire);
    });

    test('falls back to lex-sorted invadable list when distance field is '
        'empty (synthetic snapshots without topology)', () {
      // The `invadableNewWorldProvinceIdsByDistance` field is empty
      // (the default for snapshots built without a topology, e.g.
      // legacy unit-test fixtures). The planner must fall back to
      // the lex-sorted iteration over
      // `invadableNewWorldProvinceIdsSorted` to keep existing
      // synthetic fixtures deterministic.
      final game = _acquisitionGame();
      final snapshot = _acquisitionSnapshot(
        invadableNwLex: const [_farProvince, _nearProvince],
        // intentionally empty
      );

      final target = planColonialAcquisition(game: game, snapshot: snapshot);

      expect(target, isNotNull);
      expect(
        target!.targetFactionId,
        _farTribe,
        reason:
            'With the distance list empty, the planner walks the '
            'lex-sorted invadable list. _farProvince sorts first.',
      );
      expect(target.method, AcquisitionMethod.joinEmpire);
    });

    test('determinism (Must-have #7): identical distance-sorted inputs '
        'produce identical targets across repeated calls', () {
      final game = _acquisitionGame();
      final snapshot = _acquisitionSnapshot(
        invadableNwLex: const [_farProvince, _nearProvince],
        invadableNwByDistance: const [_nearProvince, _farProvince],
      );

      final first = planColonialAcquisition(game: game, snapshot: snapshot);
      final second = planColonialAcquisition(game: game, snapshot: snapshot);

      expect(first, isNotNull);
      expect(first, second);
    });

    test('distance iteration carries through the declareWar arm '
        '(neither Join Empire nor purchase_land reachable)', () {
      // Strip overture state from the base game so Join Empire and
      // purchase_land both fail, forcing the declareWar arm. Both
      // tribes are sea-reachable per the snapshot's invadable list;
      // both pass the outer treasury + regiment gates (Home army
      // with one regiment unit id). Distance order picks
      // `_nearTribe`.
      final homeArmy = Army(
        id: 'home_army:$_gp1',
        ownerId: _gp1,
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|capital_$_gp1',
        isHomeArmy: true,
        regimentUnitIds: const <String>['reg_${_gp1}_0'],
      );
      final game = Game(
        id: 'g-2509-acquisition-distance-declare-war',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 130, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: const RegionData(
            provinces: [
              Province(
                id: _nearProvince,
                regionId: 'newWorld',
                ownerId: _nearTribe,
              ),
              Province(
                id: _farProvince,
                regionId: 'newWorld',
                ownerId: _farTribe,
              ),
            ],
          ),
          armies: [homeArmy],
        ),
        players: const [
          Player(
            id: _gp1,
            displayName: 'GP1',
            isHuman: false,
            treasury: 100000,
          ),
        ],
        tribes: const [
          Tribe(id: _nearTribe, displayName: 'Near'),
          Tribe(id: _farTribe, displayName: 'Far'),
        ],
      );
      final snapshot = _acquisitionSnapshot(
        invadableNwLex: const [_farProvince, _nearProvince],
        invadableNwByDistance: const [_nearProvince, _farProvince],
      );

      final target = planColonialAcquisition(game: game, snapshot: snapshot);

      expect(target, isNotNull);
      expect(
        target!.method,
        AcquisitionMethod.declareWar,
        reason:
            'No overture state -> Join Empire and purchase_land '
            'both fail; the planner falls through to the declareWar '
            'arm.',
      );
      expect(
        target.targetFactionId,
        _nearTribe,
        reason:
            'Distance iteration order picks the near tribe (which '
            'comes first in the distance-sorted list) even though '
            'the lex-sorted list has the far tribe first.',
      );
    });
  });
}
