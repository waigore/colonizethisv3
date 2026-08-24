/// Presentational spoke copy for MAP30001 / MAP30002.
library;

import 'tile_radial_catalog.dart';

/// Label + tooltip for one catalog spoke or More-dialog row.
class TileRadialSpokeView {
  const TileRadialSpokeView({
    required this.action,
    required this.enabled,
    required this.label,
    required this.tooltip,
    this.caption,
  });

  final TileRadialCatalogAction action;
  final bool enabled;
  final String label;
  final String tooltip;
  final String? caption;
}
