import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/logic_validation_exception.dart';
import 'package:colonizethis_world/src/world/capital_and_gp_fall.dart';
import 'package:colonizethis_world/src/world/capital_reassignment.dart';
import 'package:colonizethis_world/src/world/capital_reassignment_fatal.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/province_owner_cache.dart';
import 'package:colonizethis_world/src/world_constants.dart'
    show kRegionOldWorld;

import '../world_test_support/world_test_support.dart';

part 'capital_and_gp_fall_reassignment_part.dart';
part 'capital_and_gp_fall_reassignment_unified_part.dart';
part 'capital_and_gp_fall_terminal_part.dart';
part 'capital_reassignment_part.dart';

const _emptyTopology = kEmptyMapTopology;

CapitalTile _tile(String provinceId, {int x = 1, int y = 2}) =>
    capitalTileFor(provinceId, x: x, y: y);

Unit _unit(String id, String ownerId, String provinceId) => Unit(
  id: id,
  type: 'grenadiers',
  ownerId: ownerId,
  locationProvinceId: provinceId,
);

Fleet _fleet(String id, String ownerId) =>
    Fleet(id: id, ownerId: ownerId, seaZoneId: 's1', regionId: 'oldWorld');

void main() {
  _capital_and_gp_fall_reassignment_testTests();
  _capital_and_gp_fall_reassignment_unified_testTests();
  _capital_and_gp_fall_terminal_testTests();
  _capital_reassignment_testTests();
}
