// Shared fixtures for `colonial_phase_planner_civilian_*_cases.dart` (Refs #4669).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/colonial_phase_planner_test_support.dart';

const String kColonialCivilianOwProv1 = 'oldWorld|p_alpha';
const String kColonialCivilianNwProv1 = 'newWorld|p_gamma';
const String kColonialCivilianNwProv2 = 'newWorld|p_delta';
const String kColonialCivilianNwForeignProv = 'newWorld|p_foreign';

const String kColonialCivilianOwTileA = 'oldWorld|p_alpha|1|1';
const String kColonialCivilianNwTileA = 'newWorld|p_gamma|1|1';
const String kColonialCivilianNwTileB = 'newWorld|p_gamma|2|2';
const String kColonialCivilianNwTileC = 'newWorld|p_delta|3|3';
const String kColonialCivilianNwTileTown = 'newWorld|p_gamma|0|0';
const String kColonialCivilianNwTileImproved = 'newWorld|p_delta|9|9';
const String kColonialCivilianNwForeignTile = 'newWorld|p_foreign|5|5';

Unit colonialCivilianIdleBuilder(String id, {String regionId = kOldWorldRegionId}) {
  final provinceId =
      regionId == kOldWorldRegionId ? kColonialCivilianOwProv1 : kColonialCivilianNwProv1;
  return Unit(
    id: id,
    type: kUnitTypeBuilder,
    ownerId: kColonialPhaseGp1,
    locationProvinceId: provinceId,
    tileKey: '$provinceId|9|9',
  );
}
