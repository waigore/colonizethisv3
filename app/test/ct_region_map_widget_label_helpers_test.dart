// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// province/sea label helpers.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show
        resolveProvinceLabelIconIds,
        resolveProvinceLabelPresenceIconIds,
        resolveSeaZoneLabelPrefixIconIds,
        shouldEllipsizeProvinceLabelText,
        shouldWrapProvinceLabelPresenceIcons;

import 'ct_region_map_test_support.dart';

Future<void> _pumpBlank(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'province/sea label helpers: presence gate, capital prepend, warp, ellipsis, wrap',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        const allPresence = ProvinceUnitPresenceView(
          civilianCount: 1,
          regimentCount: 2,
          shipCount: 3,
          intelVisible: true,
        );
        const allIcons = [
          'map_presence_civilian',
          'map_presence_regiment',
          'map_presence_ship',
        ];
        for (final case_
            in <
              ({
                ProvinceUnitPresenceView? presence,
                List<String> icons,
                String? reason,
              })
            >[
              (
                presence: null,
                icons: const [],
                reason: 'Null presence should suppress all icons',
              ),
              (
                presence: const ProvinceUnitPresenceView(
                  civilianCount: 1,
                  regimentCount: 1,
                  shipCount: 1,
                  intelVisible: false,
                ),
                icons: const [],
                reason: 'Hidden intel should suppress all icons',
              ),
              (presence: allPresence, icons: allIcons, reason: null),
              (
                presence: const ProvinceUnitPresenceView(
                  civilianCount: 0,
                  regimentCount: 4,
                  shipCount: 0,
                  intelVisible: true,
                ),
                icons: const ['map_presence_regiment'],
                reason: 'Only >0 classes should render',
              ),
            ]) {
          expect(
            resolveProvinceLabelPresenceIconIds(case_.presence),
            case_.icons,
            reason: case_.reason,
          );
        }
        expect(
          resolveProvinceLabelIconIds(isCapital: true, presence: null),
          const ['map_capital_star'],
        );
        expect(
          resolveProvinceLabelIconIds(isCapital: true, presence: allPresence),
          ['map_capital_star', ...allIcons],
        );
        expect(resolveSeaZoneLabelPrefixIconIds(isWarpZone: false), isEmpty);
        expect(resolveSeaZoneLabelPrefixIconIds(isWarpZone: true), const [
          'map_warp_zone',
        ]);
        expect(shouldEllipsizeProvinceLabelText(isCapital: true), isFalse);
        expect(shouldEllipsizeProvinceLabelText(isCapital: false), isTrue);
        for (final case_
            in <({double width, int icons, bool wrap, String? reason})>[
              (width: 20, icons: 0, wrap: false, reason: null),
              (
                width: 60,
                icons: 2,
                wrap: false,
                reason: 'Content fits one line',
              ),
              (
                width: 110,
                icons: 3,
                wrap: true,
                reason: 'Content should wrap to second line when too wide',
              ),
            ]) {
          expect(
            shouldWrapProvinceLabelPresenceIcons(
              textWidthPx: case_.width,
              iconCount: case_.icons,
            ),
            case_.wrap,
            reason: case_.reason,
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );
  });
}
