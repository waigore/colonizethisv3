import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'planner_context.dart';

/// Shared army-move destination scoring inputs (Refs #3822 Phase 3).
final class ConquestMoveScoringContext {
  const ConquestMoveScoringContext({
    required this.nationId,
    required this.game,
    required this.topology,
    required this.snapshot,
    required this.provinceOwner,
    required this.invadable,
    required this.stalledExpansion,
    required this.declaredWarTargetFactionId,
    required this.phasePlanInvadableIsAuthoritative,
    required this.nwInvasionWeight,
    required this.oldWorldInvasionWeight,
  });

  final String nationId;
  final Game game;
  final MapTopology topology;
  final AIWorldSnapshot snapshot;
  final Map<String, String?> provinceOwner;
  final Set<String> invadable;
  final bool stalledExpansion;
  final String? declaredWarTargetFactionId;
  final bool phasePlanInvadableIsAuthoritative;
  final double nwInvasionWeight;
  final double oldWorldInvasionWeight;

  /// Builds the per-pass scoring context shared by conquest army-move helpers.
  factory ConquestMoveScoringContext.forArmyMovePass({
    required PlannerContext plannerCtx,
    required AIWorldSnapshot snapshot,
    required Set<String> invadable,
    required bool stalledExpansion,
    required String? declaredWarTargetFactionId,
    required bool phasePlanInvadableIsAuthoritative,
    required double nwInvasionWeight,
    required double oldWorldInvasionWeight,
  }) =>
      ConquestMoveScoringContext(
        nationId: plannerCtx.nationId,
        game: plannerCtx.game,
        topology: plannerCtx.topology,
        snapshot: snapshot,
        provinceOwner: plannerCtx.provinceOwner,
        invadable: invadable,
        stalledExpansion: stalledExpansion,
        declaredWarTargetFactionId: declaredWarTargetFactionId,
        phasePlanInvadableIsAuthoritative: phasePlanInvadableIsAuthoritative,
        nwInvasionWeight: nwInvasionWeight,
        oldWorldInvasionWeight: oldWorldInvasionWeight,
      );
}
