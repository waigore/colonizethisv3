// Region id → user-facing label for units panels and related UI.
// SPEC/ui/military-units-panel.md, SPEC/ui/civilian-units-panel.md, SPEC/ui/naval-units-panel.md.

/// Maps a world [regionId] (`oldWorld`, `newWorld`, …) to a short display label.
String regionDisplayLabel(String regionId) {
  switch (regionId) {
    case 'oldWorld':
      return 'Old World';
    case 'newWorld':
      return 'New World';
    default:
      return regionId;
  }
}
