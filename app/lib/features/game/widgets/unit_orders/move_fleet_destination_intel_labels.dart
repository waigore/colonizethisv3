// Localized at-sea destination intel lines for DLG30001. SPEC/ui/move-fleet-dialog.md (#4573).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'move_fleet_destination_intel.dart';

List<String> moveFleetDestinationIntelSummaryLines(
  AppLocalizations l10n,
  MoveFleetDestinationIntelSummary summary,
) {
  if (summary.intelLevel == MoveFleetDestinationIntelLevel.unknown) {
    return [l10n.moveFleet_destinationIntel_fleetsUnknown];
  }
  if (!summary.hasHostilePresence) {
    return const [];
  }
  final lines = <String>[];
  if (summary.anyHostilePatrol == true) {
    lines.add(l10n.moveFleet_destinationIntel_hostilePatrol);
  }
  if (summary.anyHostileBlockade == true) {
    lines.add(l10n.moveFleet_destinationIntel_hostileBlockade);
  }
  if (summary.anyHostilePatrol != true &&
      summary.anyHostileBlockade != true) {
    lines.add(
      l10n.moveFleet_destinationIntel_hostileFleets(
        summary.hostileAtSeaCount ?? 0,
      ),
    );
  }
  return lines;
}
