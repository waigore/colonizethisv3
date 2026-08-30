/// Owning-surface go-to for staged-decree families on `DLG60001`.
/// SPEC: SPEC/ui/components/staged-decree-review.md
library;

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Emits the same family routing as `OVL70001` order-rejected rows.
void emitStagedDecreeGoTo({
  required AppEventBus bus,
  required Game game,
  required String humanPlayerId,
  required Orders orders,
  required StagedDecreeFamily family,
  MapTopology? topology,
}) {
  switch (family) {
    case StagedDecreeFamily.civilianWork:
    case StagedDecreeFamily.spyRelocate:
      bus.emit(const OpenCivilianUnitsPanelEvent());
    case StagedDecreeFamily.armyMoves:
      bus.emit(const OpenMilitaryUnitsPanelEvent());
    case StagedDecreeFamily.fleet:
      bus.emit(const OpenNavalUnitsPanelEvent());
    case StagedDecreeFamily.trainingBuilds:
    case StagedDecreeFamily.labourRecruit:
      bus.emit(
        NavigateToRouteEvent(Routes.production, {
          'game': game,
          'humanPlayerId': humanPlayerId,
        }),
      );
    case StagedDecreeFamily.trade:
      bus.emit(
        NavigateToRouteEvent(Routes.trade, {
          'game': game,
          'humanPlayerId': humanPlayerId,
        }),
      );
    case StagedDecreeFamily.research:
      bus.emit(
        NavigateToRouteEvent(Routes.technology, {
          'game': game,
          'humanPlayerId': humanPlayerId,
          'currentOrders': orders,
        }),
      );
    case StagedDecreeFamily.diplomacy:
      if (topology == null) {
        return;
      }
      bus.emit(
        NavigateToRouteEvent(Routes.diplomacy, {
          'game': game,
          'humanPlayerId': humanPlayerId,
          'topology': topology,
          'currentOrders': orders,
        }),
      );
  }
}
