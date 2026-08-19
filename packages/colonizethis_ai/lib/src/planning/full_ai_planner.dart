/// Full Phase 6 AI order orchestration (delegates to strategic planners).
/// SPEC/program/ai-planner.md.
///
/// Per-player config/view assembly: [full_ai_planner_player_setup.dart].
/// All-GP rotation and merge: [full_ai_planner_merge.dart] (Refs #4530).
library;

export 'full_ai_planner_merge.dart' hide orderedFullAiPlayerIds;
export 'full_ai_planner_player_setup.dart';
