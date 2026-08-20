import 'package:colonizethis_models/colonizethis_models.dart';

/// Unit factories for [TestFixtures].
abstract final class TestFixturesUnits {
  TestFixturesUnits._();

  /// Typical civilian unit on a land province (optionally tile-addressed).
  static Unit testCivilianUnit({
    required String id,
    String type = kUnitTypeBuilder,
    String ownerId = 'p1',
    String locationProvinceId = 'oldWorld|p1',
    String? tileKey,
  }) =>
      Unit(
        id: id,
        type: type,
        ownerId: ownerId,
        locationProvinceId: locationProvinceId,
        tileKey: tileKey,
      );

  /// Typical military regiment on a province.
  static Unit testMilitaryUnit({
    required String id,
    String type = 'grenadiers',
    String ownerId = 'p1',
    String locationProvinceId = 'oldWorld|p1',
    int medals = 0,
  }) =>
      Unit(
        id: id,
        type: type,
        ownerId: ownerId,
        locationProvinceId: locationProvinceId,
        medals: medals,
      );

  /// Civilian aboard or adjacent to coastal tile (naval/boarding scenarios).
  static Unit testNavalScenarioUnit({
    required String id,
    String ownerId = 'p1',
    required String harborProvinceId,
    required String tileKey,
    String type = kUnitTypeExplorer,
  }) =>
      Unit(
        id: id,
        type: type,
        ownerId: ownerId,
        locationProvinceId: harborProvinceId,
        tileKey: tileKey,
      );
}
