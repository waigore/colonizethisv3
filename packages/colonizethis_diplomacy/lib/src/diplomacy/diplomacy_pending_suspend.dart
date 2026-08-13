import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_logging.dart';
import 'diplomacy_phase_result.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_modifiers_resolver.dart';

/// Returns a pending [DiplomacyPhaseResult] when [pending] is non-empty;
/// otherwise null so the phase continues.
///
/// Used by overture / FTP / intervention / CTA suspend points so the four
/// early-return shapes share one helper while keeping distinct result fields.
DiplomacyPhaseResult? maybePendingDiplomacyResult<T>({
  required Game game,
  required List<T>? pending,
  required DiplomacyPhaseResult Function(List<T> items) build,
  String? logMessage,
}) {
  if (pending == null || pending.isEmpty) return null;
  if (logMessage != null) {
    diploLog.d(logMessage);
  }
  return build(pending);
}

/// Phase-start relation-score snapshot for skip-on-event decay (Refs #3753 R9.4).
Map<String, num> snapshotPhaseStartRelationScores(Game game) =>
    snapshotRelationScores(game);

/// Formal-alliance pair keys at diplomacy phase start (before this turn's
/// Alliance orders). SPEC/game/diplomacy.md § Alliances / Call to arms.
Set<String> formalAlliancePairKeysAtPhaseStart(Game game) => {
  for (final r in game.diplomacyRelations)
    if (r.formalAlliance) pairKey(r.factionId1, r.factionId2),
};
