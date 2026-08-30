import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_work_constants.dart';
import 'orders_application_context.dart';
import 'orders_application_completed_work_handlers.dart';
import 'orders_application_completed_work_handlers_special.dart';
import 'orders_application_road_propagation.dart';

export 'orders_application_completed_work_handlers.dart'
    show CompletedWorkContext;
export 'orders_application_road_propagation.dart'
    show propagateRoadToAdjacentCapitalOrPort;

BuildWorkState dispatchCompletedWorkTarget(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
) {
  ordersApplicationLog.d(
    'work completed unit=${u.id} workTarget=${cw.workTarget} tileKey=${cw.tileKey}',
  );
  final handler = _completedWorkTargetHandlers[cw.workTarget];
  if (handler == null) return s;
  return handler((
    state: s,
    unit: u,
    cw: cw,
    getProvinces: getProvinces,
    replaceProvinces: replaceProvinces,
    applyExploreCompletion: applyExploreCompletion,
  ));
}

/// Map-based work completion (Refs #1531). Unknown targets no-op.
final Map<String, CompletedWorkHandler> _completedWorkTargetHandlers =
    <String, CompletedWorkHandler>{
      kWorkTargetBuildImprovement: completedWorkBuildImprovement,
      kWorkTargetUpgradeTown: completedWorkUpgradeTown,
      kWorkTargetExplore: completedWorkExplore,
      kWorkTargetBuildRoad: completedWorkBuildRoad,
      kWorkTargetBuildPort: completedWorkBuildPort,
      kWorkTargetBuildFort: completedWorkBuildFort,
      kWorkTargetBuildRail: completedWorkBuildRail,
      kWorkTargetProspect: completedWorkProspect,
      kWorkTargetPurchaseLand: completedWorkPurchaseLand,
      kWorkTargetCounterSpy: completedWorkNoop,
    };
