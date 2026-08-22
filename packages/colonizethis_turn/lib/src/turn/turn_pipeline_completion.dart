import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'economy_turn_summary_events.dart';
import 'last_turn_intelligence_digest.dart';
import 'turn_event_sink.dart';
import 'turn_news_digest.dart';
import 'turn_resolution_events.dart';
import 'turn_resolution_result.dart';

/// Shared end-of-pipeline discovery / economy-summary / news / intel persist
/// used by both the calendar-halted early return and the full-run tail
/// (Refs #4583). Halted campaigns pass [reuseStartIndexForEnd] so a single
/// visibility index covers start=end; full runs build before and after.
TurnResolutionComplete completeTurnPipeline({
  required Game start,
  required Game end,
  required int turn,
  required TurnEventSink sink,
  required List<GameEvent> turnEvents,
  required bool reuseStartIndexForEnd,
}) {
  final startIndex = buildProvinceVisibilityIndex(start);
  final endIndex = reuseStartIndexForEnd
      ? startIndex
      : buildProvinceVisibilityIndex(end);
  emitPlayerDiscoveryEvents(
    start,
    end,
    turn,
    sink,
    beforeIndex: startIndex,
    afterIndex: endIndex,
  );
  emitEconomyTurnSummaryEvents(start: start, end: end, turn: turn, sink: sink);
  final news = buildTurnNewsDigestForComplete(
    start: start,
    end: end,
    startIndex: startIndex,
    endIndex: endIndex,
  );
  final game = persistLastTurnIntelligenceDigest(
    start: start,
    end: news.game,
    worldNews: news.digest,
    turnEvents: turnEvents,
  );
  return TurnResolutionComplete(game, turnNewsDigest: news.digest);
}
