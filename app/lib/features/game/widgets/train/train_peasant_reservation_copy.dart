import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'train_peasant_reservation.dart';

/// Player-facing one-line gist for other-family peasant reservation.
///
/// Returns `null` when nothing is promised outside this dialog.
String? trainPeasantsPromisedGist(
  AppLocalizations l10n,
  TrainOtherFamilyPeasantReservation otherFamily,
) {
  if (otherFamily.isEmpty) return null;
  final parts = <String>[];
  if (otherFamily.workerTraining > 0) {
    parts.add(
      l10n.trainUnits_promisedToWorkerTraining(otherFamily.workerTraining),
    );
  }
  if (otherFamily.ships > 0) {
    parts.add(l10n.trainUnits_promisedToShips(otherFamily.ships));
  }
  if (otherFamily.regiments > 0) {
    parts.add(l10n.trainUnits_promisedToRegiments(otherFamily.regiments));
  }
  if (parts.isEmpty) return null;
  return parts.join(', ');
}

/// Multi-line Peasants-chip details (tooltip/tap). Never includes order class
/// names — only player words for each promised family.
String trainPeasantsPromisedDetails(
  AppLocalizations l10n,
  TrainOtherFamilyPeasantReservation otherFamily,
) {
  if (otherFamily.isEmpty) {
    return l10n.trainUnits_peasantsChipDetailsEmpty;
  }
  final lines = <String>[
    l10n.trainUnits_peasantsChipDetailsHeader,
  ];
  if (otherFamily.workerTraining > 0) {
    lines.add(
      l10n.trainUnits_promisedToWorkerTraining(otherFamily.workerTraining),
    );
  }
  if (otherFamily.ships > 0) {
    lines.add(l10n.trainUnits_promisedToShips(otherFamily.ships));
  }
  if (otherFamily.regiments > 0) {
    lines.add(l10n.trainUnits_promisedToRegiments(otherFamily.regiments));
  }
  return lines.join('\n');
}
