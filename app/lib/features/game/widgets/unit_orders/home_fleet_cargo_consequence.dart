// Home Fleet remaining-holds vs overseas-load line (Refs #4448).
// SPEC/ui/naval-units-fleet-management.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

/// Sum of `cargoHold` for the given ship-type counts.
int cargoHoldsForTypeCounts(Map<String, int> typeCounts) {
  var holds = 0;
  for (final entry in typeCounts.entries) {
    holds += NavalStatsCatalog.get(entry.key).cargoHold * entry.value;
  }
  return holds;
}

/// Palette colour for the Home Fleet split cargo line.
///
/// Unreliable / not-defined used is never treated as a shortfall.
Color homeFleetSplitCargoLineColor({
  required int remainingHolds,
  required int overseasUsed,
  required bool isCargoUsedReliable,
  required bool cargoNotDefined,
}) {
  if (cargoNotDefined || !isCargoUsedReliable) {
    return EditorialMonoclePalette.muted;
  }
  if (remainingHolds > overseasUsed) return EditorialMonoclePalette.muted;
  if (remainingHolds == overseasUsed) return EditorialMonoclePalette.accent;
  return EditorialMonoclePalette.danger;
}

String homeFleetSplitCargoUsedLabel({
  required int overseasUsed,
  required bool isCargoUsedReliable,
  required bool cargoNotDefined,
}) {
  if (cargoNotDefined || !isCargoUsedReliable) return '—';
  return '$overseasUsed';
}

String homeFleetSplitCargoLineText({
  required AppLocalizations l10n,
  required int remainingHolds,
  required int overseasUsed,
  required bool isCargoUsedReliable,
  required bool cargoNotDefined,
}) {
  return l10n.splitFleet_homeCargoConsequence(
    remainingHolds,
    homeFleetSplitCargoUsedLabel(
      overseasUsed: overseasUsed,
      isCargoUsedReliable: isCargoUsedReliable,
      cargoNotDefined: cargoNotDefined,
    ),
  );
}

/// Live cargo-consequence line for a Home Fleet split transfer list.
Widget homeFleetSplitCargoLine({
  required AppLocalizations l10n,
  required Map<String, int> leftCounts,
  required int overseasUsed,
  required bool isCargoUsedReliable,
  required bool cargoNotDefined,
}) {
  final remaining = cargoHoldsForTypeCounts(leftCounts);
  final color = homeFleetSplitCargoLineColor(
    remainingHolds: remaining,
    overseasUsed: overseasUsed,
    isCargoUsedReliable: isCargoUsedReliable,
    cargoNotDefined: cargoNotDefined,
  );
  return Text(
    homeFleetSplitCargoLineText(
      l10n: l10n,
      remainingHolds: remaining,
      overseasUsed: overseasUsed,
      isCargoUsedReliable: isCargoUsedReliable,
      cargoNotDefined: cargoNotDefined,
    ),
    style: TextStyle(color: color),
  );
}
