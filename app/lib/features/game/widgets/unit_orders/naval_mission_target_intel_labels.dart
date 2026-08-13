// Localized Blockade harbor intel lines for DLG31002. SPEC/ui/naval-mission-target-dialog.md (#4340).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'naval_mission_target_intel.dart';

List<String> navalMissionHarborIntelSummaryLines(
  AppLocalizations l10n,
  NavalMissionHarborIntelSummary summary,
) {
  if (summary.intelLevel == NavalMissionHarborIntelLevel.unknown) {
    return [l10n.naval_mission_targetIntel_harborUnknown];
  }
  if (summary.portPresent != true) {
    return [l10n.naval_mission_targetIntel_noPort];
  }
  final count = summary.hostileFleetsInPortCount ?? 0;
  if (count == 0) {
    return [l10n.naval_mission_targetIntel_emptyHarbor];
  }
  return [l10n.naval_mission_targetIntel_fleetsInPort(count)];
}
