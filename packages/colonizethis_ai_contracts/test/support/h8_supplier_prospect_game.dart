/// Shared Old World mineral feedstock prospect Game scaffold for H8-extraction
/// supplier localization pins (Refs #2847 / #4084).
library;

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'full_ai_civilian_work_supplier_feedstock_extraction_fixtures.dart';

/// Supplier-owned Old World iron tile at (x=2, y=0) for prospect localization.
const String h8SupplierProspectIronTile = 'oldWorld|s0|2|0';

/// Supplier-owned Old World timber tile for prospect localization controls.
const String h8SupplierProspectTimberTile = 'oldWorld|s0|1|0';

/// New World iron tile for Old-World-only negative controls.
const String h8SupplierProspectNewWorldIronTile = 'newWorld|n0|0|0';

/// Two-player supplier prospect fixture with default timber / iron / wool tiles.
Game supplierGame({
  Map<String, String>? resourceByTileKey,
  List<Unit> extraUnits = const [],
}) {
  return twoPlayerSupplierFeedstockGame(
    resourceByTileKey:
        resourceByTileKey ??
        const {
          h8SupplierProspectTimberTile: 'timber',
          h8SupplierProspectIronTile: 'iron',
          sellerWoolTile: 'wool',
        },
    extraUnits: extraUnits,
  );
}

/// Idle Explorer in the supplier feedstock province (`oldWorld|s0`).
Unit supplierProspectExplorer(String id, {CurrentWork? currentWork}) =>
    supplierProspectExplorerAt(id, 'oldWorld|s0', currentWork: currentWork);

/// Explorer owned by [supplierFeedstockId] at [locationProvinceId].
Unit supplierProspectExplorerAt(
  String id,
  String locationProvinceId, {
  CurrentWork? currentWork,
}) =>
    Unit(
      id: id,
      type: kUnitTypeExplorer,
      ownerId: supplierFeedstockId,
      locationProvinceId: locationProvinceId,
      currentWork: currentWork,
    );

/// Builder owned by [supplierFeedstockId] in the supplier feedstock province.
Unit supplierProspectBuilder(String id) => Unit(
  id: id,
  type: kUnitTypeBuilder,
  ownerId: supplierFeedstockId,
  locationProvinceId: 'oldWorld|s0',
);
