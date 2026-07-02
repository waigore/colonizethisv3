// ignore_for_file: deprecated_member_use

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/province_owner_cache.dart';
import 'package:colonizethis_world/src/world/province_traversal.dart';
import 'package:colonizethis_world/src/world_constants.dart'
    show kRegionNewWorld, kRegionOldWorld;

import '../world_test_support/province_lookup_test_support.dart';

part 'province_lookup_by_id_part.dart';
part 'province_lookup_part.dart';
part 'province_traversal_region_access_part.dart';

void main() {
  _province_lookup_testTests();
  _province_lookup_by_id_testTests();
  _province_traversal_region_access_testTests();
}
