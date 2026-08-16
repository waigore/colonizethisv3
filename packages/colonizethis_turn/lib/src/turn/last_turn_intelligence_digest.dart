// Last-turn intelligence digest. SPEC/program/intelligence-digest.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'last_turn_intelligence_digest_spy.dart';
import 'last_turn_intelligence_digest_world.dart';

/// Builds and persists the last-turn intelligence digest on [end].
/// When [worldNews] is null (victory), returns [end] unchanged.
Game persistLastTurnIntelligenceDigest({
  required Game start,
  required Game end,
  required TurnNewsDigest? worldNews,
  List<GameEvent> turnEvents = const [],
}) {
  if (worldNews == null) return end;
  final digest = buildLastTurnIntelligenceDigest(
    start: start,
    end: end,
    worldNews: worldNews,
    turnEvents: turnEvents,
  );
  return end.copyWith(lastTurnIntelligenceDigest: digest);
}

LastTurnIntelligenceDigest buildLastTurnIntelligenceDigest({
  required Game start,
  required Game end,
  required TurnNewsDigest worldNews,
  List<GameEvent> turnEvents = const [],
}) {
  final resolvedTurn = worldNews.resolvedTurnNumber;
  final worldLines = intelligenceWorldLines(
    news: worldNews,
    end: end,
    resolvedTurn: resolvedTurn,
  );
  final spyReports = intelligenceSpyReportsByObserver(
    start: start,
    end: end,
    resolvedTurn: resolvedTurn,
    turnEvents: turnEvents,
    worldNews: worldNews,
  );
  return LastTurnIntelligenceDigest(
    resolvedTurnNumber: resolvedTurn,
    worldLines: worldLines,
    spyReportsByObserverId: spyReports,
  );
}
