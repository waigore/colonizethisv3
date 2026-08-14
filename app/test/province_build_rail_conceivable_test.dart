// Conceivable transport levels for MAP20001 Build railroad. Refs #4383.

import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_build_rail.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test('Build railroad is conceivable only at stored transport 1 or 2', () {
    expect(
      GameMapAreaProvinceActionStatesBuildRail.tileCanConceivablyTakeBuildRailStep(
        roadLevel: 0,
      ),
      isFalse,
    );
    expect(
      GameMapAreaProvinceActionStatesBuildRail.tileCanConceivablyTakeBuildRailStep(
        roadLevel: 1,
      ),
      isTrue,
    );
    expect(
      GameMapAreaProvinceActionStatesBuildRail.tileCanConceivablyTakeBuildRailStep(
        roadLevel: 2,
      ),
      isTrue,
    );
    expect(
      GameMapAreaProvinceActionStatesBuildRail.tileCanConceivablyTakeBuildRailStep(
        roadLevel: 4,
      ),
      isFalse,
    );
  });
}
