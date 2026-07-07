// Region id → user-facing label for units panels and related UI.
// SPEC/ui/military-units-panel.md, SPEC/ui/civilian-units-panel.md, SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kRegionNewWorld, kRegionOldWorld;

/// Maps a world [regionId] (`oldWorld`, `newWorld`, …) to a short display label.
String regionDisplayLabel(String regionId) {
  switch (regionId) {
    case kRegionOldWorld:
      return 'Old World';
    case kRegionNewWorld:
      return 'New World';
    default:
      return regionId;
  }
}
