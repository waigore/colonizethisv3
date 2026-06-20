// Guard tests for the `Resource` enum → `CommodityId` mapping (Refs #3427).
//
// `resource_extractor.dart` (and the other extraction call sites) map a tile
// `Resource` to its `CommodityId` via `resource.name`, replacing the former
// 18-case `switch`. These tests pin the invariant the switch removal relies on:
// every `Resource` enum variant name is a valid catalog commodity id, so a
// future enum/`CommodityId` divergence fails fast here instead of silently
// dropping extraction yield on the hot path.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Resource → CommodityId mapping (Refs #3427)', () {
    test('every Resource.name resolves to a catalog commodity id', () {
      for (final Resource resource in Resource.values) {
        final CommodityId commodityId = resource.name;
        expect(
          CommodityCatalog.byId.containsKey(commodityId),
          isTrue,
          reason:
              'Resource.${resource.name} maps to commodity id "$commodityId" '
              'which is not present in CommodityCatalog. Resource enum names '
              'must stay aligned with CommodityId strings (resource.name) — '
              'see resource_extractor.dart.',
        );
      }
    });

    test('the mapping is total over all Resource values', () {
      expect(
        Resource.values.every((r) => CommodityCatalog.byId.containsKey(r.name)),
        isTrue,
      );
    });

    test('mapped commodity ids are unique per resource (no collisions)', () {
      final names = Resource.values.map((r) => r.name).toSet();
      expect(
        names.length,
        Resource.values.length,
        reason: 'each Resource must map to a distinct CommodityId',
      );
    });
  });
}
