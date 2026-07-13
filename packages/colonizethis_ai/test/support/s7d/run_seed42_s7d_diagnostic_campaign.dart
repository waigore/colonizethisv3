// Seed-42 turn-100 EXPAND-arm S7-D diagnostic campaign runner (Refs #2847 / #3977 / #3997).

import '../seed42_observer_campaign.dart';
import 's7d_campaign_emission.dart';
import 's7d_campaign_rollup.dart';
import 's7d_campaign_turn_aggregation.dart';

/// Runs the seed-42 S7-D diagnostic campaign and emits structured JSON logs.
void runSeed42S7dDiagnosticCampaign() {
  final gpIds = [for (var i = 1; i <= 6; i++) 'gp$i'];
  final rollup = Seed42S7dCampaignRollup(gpIds);
  final campaign = runSeed42ObserverCampaign(
    turns: 100,
    onBeforeResolve: rollup.onBeforeResolve,
    onAfterResolve: rollup.onAfterResolve,
  );

  final game = campaign.finalGame;
  final owStart = <String, int>{
    for (final gpId in gpIds)
      gpId: campaign.initialGame.worldState.oldWorld.provinces
          .where((p) => p.ownerId == gpId)
          .length,
  };
  final gains = <String, int>{
    for (final gpId in gpIds)
      gpId:
          game.worldState.oldWorld.provinces
              .where((p) => p.ownerId == gpId)
              .length -
          owStart[gpId]!,
  };

  rollup.emitDiagnostic(gains: gains, owStart: owStart);
}
