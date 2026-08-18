import 'package:colonizethis_test/test.dart';

import '../world_test_support/connectivity_builders.dart';
import '../world_test_support/world_test_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Additional blockade resolveConnectivity pins ported from logic (Refs #4090).
void main() {
  group('ConnectivityResolver blockade (additional)', () {
    test(
      'resolveConnectivity auto-applies fleet+diplomacy blockade when map omitted',
      () {
        final scenario = dualRegionPortBlockadeAutoApplyScenario();
        final result = resolveConnectivity(
          game: scenario.game,
          tileMapByRegion: scenario.tileMapByRegion,
          topology: scenario.topology,
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), isTrue);
        expect(connected.contains('newWorld|p2|0|0'), isFalse);
      },
    );

    test(
      'same-region two ports: explicit blockade keeps capital port, cuts other',
      () {
        final scenario = twoPortOldWorldBlockadeConnectivityScenario();
        final result = resolveConnectivity(
          game: scenario.game,
          tileMapByRegion: scenario.tileMapByRegion,
          topology: scenario.topology,
          blockadedPortProvincesByPlayerId: {
            'pl1': {'oldWorld|p2'},
          },
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), isTrue);
        expect(connected.contains('oldWorld|p1|1|0'), isTrue);
        expect(connected.contains('oldWorld|p2|2|0'), isFalse);
        expect(connected.contains('oldWorld|p2|3|0'), isFalse);
      },
    );

    test(
      'inland capital: land-connected port excluded only when blockaded',
      () {
        final scenario = inlandCapitalLandPortConnectivityScenario();
        final noBlockade = resolveConnectivity(
          game: scenario.game,
          tileMapByRegion: scenario.tileMapByRegion,
          topology: scenario.topology,
        );
        expect(
          noBlockade['pl1']!.connected.contains('oldWorld|p2|1|0'),
          isTrue,
        );

        final blockaded = resolveConnectivity(
          game: scenario.game,
          tileMapByRegion: scenario.tileMapByRegion,
          topology: scenario.topology,
          blockadedPortProvincesByPlayerId: {
            'pl1': {'oldWorld|p2'},
          },
        );
        expect(
          blockaded['pl1']!.connected.contains('oldWorld|p2|1|0'),
          isFalse,
        );
        expect(
          blockaded['pl1']!.connected.contains('oldWorld|p1|0|0'),
          isTrue,
        );
      },
    );
  });
}
