// Table-driven resolveDiplomacyPhase scenarios (Refs #3837 / #4028).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';

import 'diplomacy_game_fixtures.dart';
import 'diplomacy_phase_scenarios.dart';
import 'diplomacy_resolver_phase_test_support.dart';

/// One phase-resolver integration row with preserved [label].
class DiplomacyPhaseScenario {
  const DiplomacyPhaseScenario({required this.label, required this.run});

  final String label;
  final void Function() run;
}

void runDiplomacyPhaseScenario(DiplomacyPhaseScenario scenario) => scenario.run();

DiplomacyPhaseScenario _row(String label, void Function() run) =>
    DiplomacyPhaseScenario(label: label, run: run);

const _gp1 = Player(id: 'gp1', displayName: 'GP1', isHuman: true);
const _gp1Rich = Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 15000);
const _gp2 = Player(id: 'gp2', displayName: 'GP2', isHuman: true);
const _ow = 'oldWorld';

const _minorNapOverture = OvertureState(
  gpId: 'gp1',
  targetId: 'minor1',
  stage: OvertureStage.nap,
  sinceTurn: 0,
);

const _overtureConsulateEmbassy = [
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: 'minor1',
    overtureStage: OvertureStage.tradeConsulate,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: 'minor1',
    overtureStage: OvertureStage.embassy,
  ),
];

const _declareWarMinor1 = [
  DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'minor1'),
];

const _peaceMinor1 = [
  DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: 'minor1'),
];

const _joinEmpireMinor1 = [
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: 'minor1',
    overtureStage: OvertureStage.joinEmpire,
  ),
];

Orders _dip(String gp, List<DiplomaticOrder> orders) =>
    Orders(diplomaticOrdersByPlayerId: {gp: orders});

Game _resolve(Game g, Orders o) => resolveDiplomacyPhase(g, o).game;

Province _owProv(String localId) =>
    Province(id: '$_ow|$localId', regionId: _ow, ownerId: 'minor1');

Game _grantAidGame() => diplomacyResolverPhaseTestBaseGame().copyWith(
      overtureStates: const [gpMinorEmbassyOverture],
      diplomacyRelations: [gpMinorNeutralRelation()],
    );

Game _joinEmpireGame(WorldState worldState) =>
    diplomacyResolverPhaseTestBaseGame().copyWith(
      players: const [_gp1Rich],
      worldState: worldState,
      overtureStates: const [_minorNapOverture],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'minor1',
          score: 60,
          level: RelationLevel.friendly,
        ),
      ],
    );

String? _owOwner(Game g, String localId) =>
    g.worldState.oldWorld.provinces.where((p) => p.id == '$_ow|$localId').firstOrNull?.ownerId;

/// Overture, alliance, and war/peace scenarios from part 1 integration tests.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1WarPeaceScenarios() => [
  _row('overture payments create consulate and embassy when treasury allows', () {
    final after = _resolve(diplomacyResolverPhaseTestBaseGame(), _dip('gp1', _overtureConsulateEmbassy));
    final overture = getOverture(after, 'gp1', 'minor1');
    expect(overture, isNotNull);
    expect(overture!.hasEmbassy, isTrue);
    expect(after.playerById('gp1')!.treasury, lessThan(2000));
  }),
  _row('alliance order sets relation to allied', () {
    final after = _resolve(
      diplomacyGame(id: 'g1', players: const [_gp1, _gp2]),
      _dip('gp1', const [
        DiplomaticOrder(type: DiplomaticOrderType.alliance, targetFactionId: 'gp2'),
      ]),
    );
    final rel = getRelation(after, 'gp1', 'gp2');
    expect(rel, isNotNull);
    expect(rel!.level, RelationLevel.allied);
    expect(rel.score, 76);
  }),
  _row('declare war and offer peace update relation state', () {
    final game = diplomacyResolverPhaseTestBaseGame();
    final afterWar = _resolve(game, _dip('gp1', _declareWarMinor1));
    expect(getRelation(afterWar, 'gp1', 'minor1')!.atWar, isTrue);
    final afterPeace = _resolve(afterWar, _dip('gp1', _peaceMinor1));
    expect(getRelation(afterPeace, 'gp1', 'minor1')!.atPeace, isTrue);
  }),
  _row('declare war when already at peace updates existing relation', () {
    final after = _resolve(
      diplomacyResolverPhaseTestBaseGame().copyWith(diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'minor1',
          score: 60,
          level: RelationLevel.friendly,
          state: RelationState.atPeace,
        ),
      ]),
      _dip('gp1', _declareWarMinor1),
    );
    final rel = getRelation(after, 'gp1', 'minor1')!;
    expect(rel.atWar, isTrue);
    expect(rel.score, lessThan(60));
  }),
];

/// Grant-aid scenarios from part 1 integration tests.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1GrantAidScenarios() => [
  _row('grantAid requires embassy and improves relations', () {
    final initialRel = gpMinorNeutralRelation();
    final after = _resolve(
      _grantAidGame(),
      _dip('gp1', const [
        DiplomaticOrder(
          type: DiplomaticOrderType.grantAid,
          targetFactionId: 'minor1',
          amount: 1000,
        ),
      ]),
    );
    final rel = getRelation(after, 'gp1', 'minor1')!;
    expect(rel.score, greaterThan(initialRel.score));
    expect(tradeSlotsForGp(after, 'gp1', 'minor1'), 3);
    expect(after.playerById('gp1')!.treasury, 2000 - 1000);
  }),
  _row('grantAid at resolution with wrong multiple throws StateError', () {
    expect(
      () => _resolve(
        _grantAidGame(),
        _dip('gp1', const [
          DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'minor1',
            amount: 500,
          ),
        ]),
      ),
      throwsStateError,
    );
  }),
];

/// Join-empire scenarios from part 1 integration tests.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1JoinEmpireScenarios() => [
  _row(
    'join empire absorbs minor: provinces transfer, minor removed, cost deducted',
    () {
      final after = _resolve(
        _joinEmpireGame(WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [_owProv('m1'), _owProv('m2')], units: []),
          newWorld: const RegionData(),
        )),
        _dip('gp1', _joinEmpireMinor1),
      );
      expect(after.minorNations.any((m) => m.id == 'minor1'), isFalse);
      expect(getOverture(after, 'gp1', 'minor1'), isNull);
      expect(_owOwner(after, 'm1'), 'gp1');
      expect(_owOwner(after, 'm2'), 'gp1');
      expect(after.playerById('gp1')!.treasury, 15000 - 9000);
    },
  ),
  _row('join empire clears Spy timers for provinces that become owned by GP', () {
    final after = _resolve(
      _joinEmpireGame(const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [Province(id: '$_ow|m1', regionId: _ow, ownerId: 'minor1')],
          units: [],
        ),
        newWorld: RegionData(),
        playerVisibilityByTile: {'gp1': {'oldWorld|m1|0|0': 'fullyVisible'}},
        spyRevealTurnsByPlayer: {'gp1': {'$_ow|m1': 3}},
        tileKeysByRegionAndProvince: {_ow: {'$_ow|m1': ['oldWorld|m1|0|0']}},
      )),
      _dip('gp1', _joinEmpireMinor1),
    );
    expect(_owOwner(after, 'm1'), 'gp1');
    expect(after.worldState.spyRevealTurnsByPlayer['gp1'], isNull);
    expect(
      after.worldState.playerVisibilityByTile['gp1']?['oldWorld|m1|0|0'],
      'fullyVisible',
    );
  }),
];

/// Part 1 scenarios from `diplomacy_resolver_phase_test_part1_test.dart`.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1Scenarios() => [
  ...diplomacyResolverPhasePart1WarPeaceScenarios(),
  ...diplomacyResolverPhasePart1GrantAidScenarios(),
  ...diplomacyResolverPhasePart1JoinEmpireScenarios(),
];

void _expectSubsidyResolution(int amount, {required bool valid}) {
  final after = _resolve(
    gpMinorEmbassyNeutralPhaseGame(),
    _dip('gp1', [
      DiplomaticOrder(
        type: DiplomaticOrderType.setSubsidy,
        targetFactionId: 'minor1',
        amount: amount,
      ),
    ]),
  );
  if (valid) {
    expect(after.subsidyStates, hasLength(1));
    expect(after.subsidyStates.single.percent, amount);
    expect(after.subsidyStates.single.targetId, 'minor1');
  } else {
    expect(after.subsidyStates, isEmpty);
  }
}

/// Part 2 scenarios from `diplomacy_resolver_phase_test_part2_test.dart`.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart2Scenarios() => [
  _row('returns game when there are no diplomatic orders', () {
    final game = diplomacyResolverPhaseTestBaseGame();
    expect(_resolve(game, const Orders()).id, game.id);
  }),
  _row(
    'setSubsidy at resolution with invalid percent is skipped, not thrown '
    '(Refs #3753 R3)',
    () => _expectSubsidyResolution(7, valid: false),
  ),
  _row(
    'setSubsidy at resolution with valid percent records SubsidyState '
    '(Refs #3753 R3)',
    () => _expectSubsidyResolution(10, valid: true),
  ),
];
