import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/di.dart';
import 'package:colonizethis_test/test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('tileMapRegionGeneratorProvider yields defaultTileMapRegionGenerator', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final g = container.read(tileMapRegionGeneratorProvider);
    expect(identical(g, defaultTileMapRegionGenerator), isTrue);
  });
}
