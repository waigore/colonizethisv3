import 'package:riverpod/riverpod.dart';

import '../gen/tile_map_generation_fn.dart';

/// Default [TileMapRegionGenerator]. Override in tests via [ProviderContainer].
final tileMapRegionGeneratorProvider = Provider<TileMapRegionGenerator>((ref) {
  return defaultTileMapRegionGenerator;
});
