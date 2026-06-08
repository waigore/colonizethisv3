import 'package:test/test.dart';

import '../tool/check_land_province_bucket_keys.dart';

void main() {
  group('findLandProvinceBucketKeyViolations', () {
    test('flags local-only province lookup variable', () {
      const src = r'''
void f(WorldState ws, String regionId, String localProvinceId) {
  final tiles = ws.tileKeysByRegionAndProvince[regionId]?[localProvinceId] ?? const [];
  print(tiles.length);
}
''';
      final violations = findLandProvinceBucketKeyViolations(
        relativePath:
            'packages/colonizethis_logic/lib/src/world/fog_resolution.dart',
        source: src,
      );
      expect(violations, isNotEmpty);
    });

    test('flags ProvinceId.localIdFrom local-only lookup', () {
      const src = r'''
void f(WorldState ws, String regionId, String fullProvinceId) {
  final tiles = ws.tileKeysByRegionAndProvince[regionId]?[ProvinceId.localIdFrom(fullProvinceId)] ?? const [];
  print(tiles.length);
}
''';
      final violations = findLandProvinceBucketKeyViolations(
        relativePath:
            'packages/colonizethis_turn/lib/src/turn/turn_news_digest.dart',
        source: src,
      );
      expect(violations, isNotEmpty);
    });

    test('accepts canonical full province lookup', () {
      const src = r'''
void f(WorldState ws, String regionId, String fullProvinceId) {
  final tiles = ws.tileKeysByRegionAndProvince[regionId]?[fullProvinceId] ?? const [];
  print(tiles.length);
}
''';
      final violations = findLandProvinceBucketKeyViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/orders_application.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
