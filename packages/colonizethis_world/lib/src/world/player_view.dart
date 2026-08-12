/// Player fog-of-war projection and tile/resource intel helpers.
///
/// Split into standalone libraries (Refs #4330 Slice A); this cascade re-exports
/// the sibling entry points so deep importers of `player_view.dart` stay
/// import-stable. The package barrel continues to export this cascade file.
library;

export 'player_view_core.dart';
export 'player_view_intel.dart';
