import '../order_work_constants.dart';
import 'explore_work_handler.dart';
import 'simple_work_order_handler.dart';
import 'standard_work_handler.dart';
import 'work_order_handler.dart';

/// Canonical target → handler map for build/work phase application.
/// SPEC/program/orders.md § Work-order handler registry.
final Map<String, WorkOrderHandler> workOrderHandlersByTarget =
    <String, WorkOrderHandler>{
      kWorkTargetPurchaseLand: purchaseLandWorkOrderHandler,
      kWorkTargetStealTech: stealTechWorkOrderHandler,
      kWorkTargetCounterSpy: counterSpyWorkOrderHandler,
      kWorkTargetProspect: prospectWorkOrderHandler,
      kWorkTargetExplore: exploreWorkOrderHandler,
      kWorkTargetBuildImprovement: standardBuildImprovementWorkOrderHandler,
      kWorkTargetBuildRoad: standardBuildRoadWorkOrderHandler,
      kWorkTargetBuildPort: standardBuildPortWorkOrderHandler,
      kWorkTargetUpgradeTown: standardBuildUpgradeTownWorkOrderHandler,
      kWorkTargetBuildFort: standardBuildFortWorkOrderHandler,
      kWorkTargetBuildRail: standardBuildRailWorkOrderHandler,
    };

WorkOrderHandler? workOrderHandlerForTarget(String target) =>
    workOrderHandlersByTarget[target];
