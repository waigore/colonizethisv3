/// Victory-pace bonuses for Full AI goal selection. SPEC/game/victory.md, SPEC/ai/ai-architecture.md.
///
/// Topic libraries are split across `ai_victory_config_*.dart` modules and
/// re-exported here so existing `ai_victory_config.dart` / barrel imports stay
/// stable (Refs #4072, #4121).
/// Civilian-build planner constants live in
/// [ai_victory_config_civilian_build.dart].
/// Region ids are owned by [region_ids.dart] and re-exported for API stability.
library;

export 'ai_victory_config_civilian_build.dart';
export 'ai_victory_config_colonial.dart';
export 'ai_victory_config_declare_war.dart';
export 'ai_victory_config_observer.dart';
export 'ai_victory_config_offer_peace.dart';
export 'ai_victory_config_pace.dart';
export 'ai_victory_config_stalled_ow.dart';
export 'ai_victory_config_work.dart';
export 'region_ids.dart';
