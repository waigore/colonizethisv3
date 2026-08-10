import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'turn_event_sink.dart';

/// Emits [EconomyTurnSummaryEvent] for GPs with last-turn treasury and/or
/// stockpile net changes (Refs #4308).
void emitEconomyTurnSummaryEvents({
  required Game start,
  required Game end,
  required int turn,
  required TurnEventSink sink,
}) {
  final startById = {for (final p in start.players) p.id: p};
  final sortedGpIds = end.players.map((p) => p.id).toList()..sort();
  for (final gpId in sortedGpIds) {
    final startPlayer = startById[gpId];
    final endPlayer = end.players.firstWhere((p) => p.id == gpId);
    if (startPlayer == null) {
      continue;
    }
    final treasuryDelta = endPlayer.treasury - startPlayer.treasury;
    final stockpileDeltas = _stockpileDeltas(
      startPlayer.stockpile,
      endPlayer.stockpile,
    );
    if (treasuryDelta == 0 && stockpileDeltas.isEmpty) {
      continue;
    }
    sink.emit(
      EconomyTurnSummaryEvent(
        playerId: gpId,
        treasuryDelta: treasuryDelta,
        stockpileDeltas: stockpileDeltas,
        turnNumber: turn,
      ),
    );
  }
}

Map<String, int> _stockpileDeltas(Stockpile start, Stockpile end) {
  final keys = <String>{
    ...start.quantities.keys,
    ...end.quantities.keys,
  }.toList()
    ..sort();
  final deltas = <String, int>{};
  for (final key in keys) {
    final delta = end.quantityOf(key) - start.quantityOf(key);
    if (delta != 0) {
      deltas[key] = delta;
    }
  }
  return deltas;
}
