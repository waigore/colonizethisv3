// Localized labour-readiness copy shared by Production and map HUD.
// SPEC/ui/production-panel.md § Labour readiness; Refs #4237, #4506.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'commodity_ui_helpers.dart';

/// Primary shortage reason for a labour-readiness snapshot (one line).
String labourReadinessPrimaryReasonText(
  AppLocalizations l10n,
  LabourReadinessSnapshot snapshot,
) {
  return switch (snapshot.primaryCauseKind) {
    LabourReadinessCauseKind.food =>
      snapshot.militaryOrNavyConsumesFoodBeforeWorkers
          ? l10n.production_labourReasonFoodWithMilitary
          : l10n.production_labourReasonFood,
    LabourReadinessCauseKind.luxury => l10n.production_labourReasonLuxury(
      commodityDisplayName(
        l10n,
        snapshot.primaryLuxuryCommodityId ?? '',
      ),
    ),
    null => '',
  };
}
