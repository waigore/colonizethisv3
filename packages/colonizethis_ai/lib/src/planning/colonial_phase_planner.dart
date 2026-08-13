/// COLONIAL-phase planner barrel (Refs #2509 S3 / S10; #4365 Slice A).
///
/// Thin re-export host for COLONIAL domain planners. Contract docs live with
/// each sibling implementation (`colonial_phase_planner_*.dart`). Dispatch
/// via `phase_planner_dispatch.dart` when `observerGoalPhaseFor` is colonial.
library;

export 'colonial_phase_planner_acquisition.dart';
export 'colonial_phase_planner_civilian.dart';
export 'colonial_phase_planner_lite.dart';
export 'colonial_phase_planner_military.dart';
export 'colonial_phase_planner_naval.dart';
export 'colonial_phase_planner_peace.dart';
