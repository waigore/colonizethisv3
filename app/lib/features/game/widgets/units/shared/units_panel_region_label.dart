// Shared region labels for units panels. SPEC/ui/civilian-units-panel.md et al.

/// Region id to display label for Old/New World sections in units panels.
String unitsPanelRegionLabel(String regionId) {
  switch (regionId) {
    case 'oldWorld':
      return 'Old World';
    case 'newWorld':
      return 'New World';
    default:
      return regionId;
  }
}
