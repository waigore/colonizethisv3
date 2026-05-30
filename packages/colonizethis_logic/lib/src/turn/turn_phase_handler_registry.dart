import 'package:colonizethis_models/colonizethis_models.dart';

import 'phases.dart';
import 'turn_resolution_sequence.dart';
import 'turn_resolver_config.dart';

/// Canonical turn-phase handler registry. SPEC/program/turn-resolution-phase-details.md § Phase handler registry.
///
/// Every `TurnPhaseHandler` implementation lives in `turn/phases/*.dart`;
/// this module only maps each [TurnPhase] to its handler. Refs #2560.
final class TurnPhaseHandlerRegistry {
  TurnPhaseHandlerRegistry._();

  static Map<TurnPhase, TurnPhaseHandler> get defaults =>
      Map<TurnPhase, TurnPhaseHandler>.unmodifiable(_handlers);

  static TurnPhaseHandler? handlerFor(TurnPhase phase) => _handlers[phase];

  static const Map<TurnPhase, TurnPhaseHandler> _handlers =
      <TurnPhase, TurnPhaseHandler>{
        TurnPhase.orders: ordersTurnPhaseHandler,
        TurnPhase.extraction: extractionTurnPhaseHandler,
        TurnPhase.richesToTreasury: richesToTreasuryTurnPhaseHandler,
        TurnPhase.consumption: consumptionTurnPhaseHandler,
        TurnPhase.production: productionTurnPhaseHandler,
        TurnPhase.diplomacy: diplomacyTurnPhaseHandler,
        TurnPhase.research: researchTurnPhaseHandler,
        TurnPhase.movement: movementTurnPhaseHandler,
        TurnPhase.minorRegimentUpgrade: minorRegimentUpgradeTurnPhaseHandler,
        TurnPhase.navalInterceptionCombat:
            navalInterceptionCombatTurnPhaseHandler,
        TurnPhase.combat: combatTurnPhaseHandler,
        TurnPhase.buildWork: buildWorkTurnPhaseHandler,
        TurnPhase.worldMarket: worldMarketTurnPhaseHandler,
        TurnPhase.endOfTurn: endOfTurnTurnPhaseHandler,
      };
}

/// Validates that [defaults] covers every phase in [turnResolutionSequence].
void assertTurnPhaseHandlerRegistryComplete() {
  for (final phase in turnResolutionSequence) {
    if (TurnPhaseHandlerRegistry.handlerFor(phase) == null) {
      throw StateError(
        'TurnPhaseHandlerRegistry missing handler for ${phase.name}',
      );
    }
  }
}
