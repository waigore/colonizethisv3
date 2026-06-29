import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _gpMinorGame() {
  const ow = 'oldWorld';
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
          Province(id: '$ow|m1', regionId: ow, ownerId: 'minor1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'A',
        isHuman: true,
        treasury: 5000,
        techUnlocked: const {kTechIdDiplomaticExpertise: true},
      ),
      const Player(id: 'gp2', displayName: 'B', isHuman: false, treasury: 5000),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Bavaria')],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 50,
      ),
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'minor1',
        score: 50,
      ),
    ],
  );
}

const _topology = MapTopology(
  nodes: [],
  edges: [],
);

void main() {
  suppressLogsForTests();

  group('diplomaticPanelActionCandidates', () {
    test('GP row includes alliance, FTP, and four overture stages', () {
      final candidates = diplomaticPanelActionCandidates(
        game: _gpMinorGame(),
        playerId: 'gp1',
        targetId: 'gp2',
      );
      expect(
        candidates.map((o) => o.type).toSet(),
        containsAll(<DiplomaticOrderType>{
          DiplomaticOrderType.declareWar,
          DiplomaticOrderType.offerPeace,
          DiplomaticOrderType.alliance,
          DiplomaticOrderType.establishOverture,
          DiplomaticOrderType.establishFtp,
          DiplomaticOrderType.grantAid,
          DiplomaticOrderType.setSubsidy,
        }),
      );
      expect(
        candidates
            .where((o) => o.type == DiplomaticOrderType.establishOverture)
            .map((o) => o.overtureStage)
            .toSet(),
        equals(kDiplomaticPanelOvertureStages.toSet()),
      );
    });

    test('Minor row omits alliance and FTP', () {
      final candidates = diplomaticPanelActionCandidates(
        game: _gpMinorGame(),
        playerId: 'gp1',
        targetId: 'minor1',
      );
      expect(candidates.map((o) => o.type), isNot(contains(DiplomaticOrderType.alliance)));
      expect(candidates.map((o) => o.type), isNot(contains(DiplomaticOrderType.establishFtp)));
    });

    test('GP row includes boycott + revoke boycott (Refs #3753 S14)', () {
      final candidates = diplomaticPanelActionCandidates(
        game: _gpMinorGame(),
        playerId: 'gp1',
        targetId: 'gp2',
      );
      expect(
        candidates.map((o) => o.type).toSet(),
        containsAll(<DiplomaticOrderType>{
          DiplomaticOrderType.boycott,
          DiplomaticOrderType.revokeBoycott,
        }),
      );
    });

    test('Minor/Tribe row omits boycott + revoke boycott (Refs #3753 S14)', () {
      final candidates = diplomaticPanelActionCandidates(
        game: _gpMinorGame(),
        playerId: 'gp1',
        targetId: 'minor1',
      );
      expect(
        candidates.map((o) => o.type),
        isNot(contains(DiplomaticOrderType.boycott)),
      );
      expect(
        candidates.map((o) => o.type),
        isNot(contains(DiplomaticOrderType.revokeBoycott)),
      );
    });
  });

  group('enumerateDiplomaticPanelActionsForTarget', () {
    test('AC-6: minor at none shows all overture stages; only consulate enabled', () {
      final actions = enumerateDiplomaticPanelActionsForTarget(
        game: _gpMinorGame(),
        topology: _topology,
        playerId: 'gp1',
        targetId: 'minor1',
        currentOrders: const Orders(),
      );
      final overture = actions
          .where((a) => a.order.type == DiplomaticOrderType.establishOverture)
          .toList();
      expect(overture, hasLength(4));
      expect(
        overture.map((a) => diplomacyOvertureStageShortLabel(a.order.overtureStage!)),
        containsAll(<String>['Consulate', 'Embassy', 'NAP', 'Join Empire']),
      );
      final consulate = overture.firstWhere(
        (a) => a.order.overtureStage == OvertureStage.tradeConsulate,
      );
      final embassy = overture.firstWhere(
        (a) => a.order.overtureStage == OvertureStage.embassy,
      );
      expect(consulate.enabled, isTrue, reason: consulate.rejectionReason);
      expect(embassy.enabled, isFalse);
      expect(embassy.rejectionReason, isNotEmpty);
    });

    DiplomaticPanelAction _actionOfType(
      Game game,
      String targetId,
      DiplomaticOrderType type,
    ) {
      final actions = enumerateDiplomaticPanelActionsForTarget(
        game: game,
        topology: _topology,
        playerId: 'gp1',
        targetId: targetId,
        currentOrders: const Orders(),
      );
      return actions.firstWhere((a) => a.order.type == type);
    }

    test('S14: boycott disabled when human holds no colony', () {
      final boycott = _actionOfType(
        _gpMinorGame(),
        'gp2',
        DiplomaticOrderType.boycott,
      );
      expect(boycott.enabled, isFalse);
      expect(boycott.rejectionReason, isNotEmpty);
    });

    test('S14: boycott enabled when human holds a colony at peace', () {
      final game = _gpMinorGame().copyWith(
        colonyStates: const [
          ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1),
        ],
      );
      final boycott = _actionOfType(game, 'gp2', DiplomaticOrderType.boycott);
      expect(boycott.enabled, isTrue, reason: boycott.rejectionReason);
    });

    test('S14: revoke enabled (and boycott disabled) with active boycott', () {
      final game = _gpMinorGame().copyWith(
        colonyStates: const [
          ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1),
        ],
        boycottStates: const [
          BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 1),
        ],
      );
      final revoke = _actionOfType(
        game,
        'gp2',
        DiplomaticOrderType.revokeBoycott,
      );
      final boycott = _actionOfType(game, 'gp2', DiplomaticOrderType.boycott);
      expect(revoke.enabled, isTrue, reason: revoke.rejectionReason);
      expect(boycott.enabled, isFalse);
    });

    test('S14: revoke disabled when no active boycott exists', () {
      final revoke = _actionOfType(
        _gpMinorGame(),
        'gp2',
        DiplomaticOrderType.revokeBoycott,
      );
      expect(revoke.enabled, isFalse);
      expect(revoke.rejectionReason, isNotEmpty);
    });

    test('AC-10: invalid declare war / offer peace still enumerated', () {
      final actions = enumerateDiplomaticPanelActionsForTarget(
        game: _gpMinorGame(),
        topology: _topology,
        playerId: 'gp1',
        targetId: 'gp2',
        currentOrders: const Orders(),
      );
      final offerPeace = actions.firstWhere(
        (a) => a.order.type == DiplomaticOrderType.offerPeace,
      );
      final declareWar = actions.firstWhere(
        (a) => a.order.type == DiplomaticOrderType.declareWar,
      );
      expect(offerPeace.enabled, isFalse);
      expect(offerPeace.rejectionReason, isNotEmpty);
      expect(declareWar.enabled, isTrue, reason: declareWar.rejectionReason);
    });
  });
}

/// Mirrors app helper for readable overture labels in assertions.
String diplomacyOvertureStageShortLabel(OvertureStage stage) {
  return switch (stage) {
    OvertureStage.none => 'Overture',
    OvertureStage.tradeConsulate => 'Consulate',
    OvertureStage.embassy => 'Embassy',
    OvertureStage.nap => 'NAP',
    OvertureStage.joinEmpire => 'Join Empire',
  };
}
