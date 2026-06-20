import 'package:colonizethis_models/colonizethis_models.dart';

/// Replaces the snapshot for [playerId] with [updated], appending if missing.
List<Player> upsertPlayerSnapshot(
  List<Player> snapshots,
  String playerId,
  Player updated,
) {
  final idx = snapshots.indexWhere((p) => p.id == playerId);
  if (idx < 0) {
    return [...snapshots, updated];
  }
  final next = List<Player>.from(snapshots);
  next[idx] = updated;
  return next;
}
