import 'package:flame/components.dart';

import 'region_map_component.dart';

/// Session fields shared by de-parted [CtRegionMapGame] libraries (Refs #4117).
class CtRegionMapGameState {
  late CtRegionMapComponent mapComponent;
  double zoomMultiplier = 1.0;
  bool mapLoaded = false;
  Vector2? lastCanvasSize;
}
