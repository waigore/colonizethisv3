import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/src/setup/faction_setup_helpers.dart';
import 'package:colonizethis_test/test.dart';

/// Shared faction ownership/markdown helpers (Refs #3449): collapse the
/// duplicated `.where(owner).map(id).toList()..sort()` collection sites and the
/// repeated "Faction Setup" row construction while preserving byte-identical
/// observable output.
void main() {
  Province prov(String id, String? ownerId) =>
      Province(id: id, regionId: 'oldWorld', ownerId: ownerId);

  group('ownedProvinceIdsForFaction', () {
    test('positive: returns sorted ids owned by the faction by default', () {
      final provinces = [
        prov('ow|p3', 'gp1'),
        prov('ow|p1', 'gp1'),
        prov('ow|p2', 'gp2'),
        prov('ow|p0', 'gp1'),
      ];
      expect(ownedProvinceIdsForFaction(provinces, 'gp1'), [
        'ow|p0',
        'ow|p1',
        'ow|p3',
      ]);
    });

    test('positive: sorted=false preserves source iteration order', () {
      final provinces = [
        prov('ow|p3', 'gp1'),
        prov('ow|p1', 'gp1'),
        prov('ow|p0', 'gp1'),
      ];
      expect(ownedProvinceIdsForFaction(provinces, 'gp1', sorted: false), [
        'ow|p3',
        'ow|p1',
        'ow|p0',
      ]);
    });

    test('negative: faction owning nothing yields an empty list', () {
      final provinces = [prov('ow|p1', 'gp1'), prov('ow|p2', null)];
      expect(ownedProvinceIdsForFaction(provinces, 'gp9'), isEmpty);
    });

    test('matches the previous inline where/map/sort expression exactly', () {
      final provinces = [
        prov('ow|b', 'gp1'),
        prov('ow|a', 'gp1'),
        prov('ow|c', 'gp2'),
      ];
      final legacy =
          provinces
              .where((pr) => pr.ownerId == 'gp1')
              .map((pr) => pr.id)
              .toList()
            ..sort();
      expect(ownedProvinceIdsForFaction(provinces, 'gp1'), legacy);
    });
  });

  group('factionSetupTableRow', () {
    test('positive: byte-identical to the legacy Great Power row format', () {
      const id = 'gp1';
      const displayName = 'England';
      const capital = 'ow|cap1';
      final owned = ['ow|p1', 'ow|p2'];
      final legacy =
          '| $displayName ($id) | Great Power | $capital | ${owned.join(", ")} |';
      expect(
        factionSetupTableRow(
          displayLabel: displayName,
          factionId: id,
          typeLabel: 'Great Power',
          capitalProvinceId: capital,
          ownedProvinceIds: owned,
        ),
        legacy,
      );
    });

    test('negative: null capital renders as an em dash', () {
      final row = factionSetupTableRow(
        displayLabel: 'tribe1',
        factionId: 'tribe1',
        typeLabel: 'Tribe',
        capitalProvinceId: null,
        ownedProvinceIds: const [],
      );
      expect(row, '| tribe1 (tribe1) | Tribe | — |  |');
    });
  });
}
