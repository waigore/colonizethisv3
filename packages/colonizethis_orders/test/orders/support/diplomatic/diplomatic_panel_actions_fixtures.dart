// Shared diplomatic panel action fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomatic_orders_test_fixtures.dart';

const diplomaticPanelActionsTopology = emptyTopology;

Game diplomaticPanelActionsBaseGame() => gpMinorGame(
      gameId: 'g',
      turnNumber: 1,
      treasury: 5000,
      gp1DisplayName: 'A',
      minorDisplayName: 'Bavaria',
      includeSecondGp: true,
      includeProvinces: true,
      overtureStates: const [],
    );

Game diplomaticPanelActionsAlliedGame() => diplomaticPanelActionsBaseGame().copyWith(
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 90,
          formalAlliance: true,
        ),
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'minor1',
          score: 50,
        ),
      ],
    );

Game diplomaticPanelActionsColonyAtPeaceGame() =>
    diplomaticPanelActionsBaseGame().copyWith(
      colonyStates: const [
        ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1),
      ],
    );

Game diplomaticPanelActionsActiveBoycottGame() =>
    diplomaticPanelActionsColonyAtPeaceGame().copyWith(
      boycottStates: const [
        BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 1),
      ],
    );

Game diplomaticPanelActionsAllianceBreakCooldownGame() =>
    diplomaticPanelActionsBaseGame().copyWith(
      allianceBreakCooldowns: const [
        AllianceBreakCooldownState(
          factionId1: 'gp1',
          factionId2: 'gp2',
          sinceTurn: 1,
        ),
      ],
    );

DiplomaticPanelAction diplomaticPanelActionOfType(
  Game game,
  String targetId,
  DiplomaticOrderType type,
) {
  final actions = enumerateDiplomaticPanelActionsForTarget(
    game: game,
    topology: diplomaticPanelActionsTopology,
    playerId: 'gp1',
    targetId: targetId,
    currentOrders: const Orders(),
  );
  return actions.firstWhere((a) => a.order.type == type);
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
