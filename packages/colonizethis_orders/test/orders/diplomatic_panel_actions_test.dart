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
