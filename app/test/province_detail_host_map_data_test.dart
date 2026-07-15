// tryGetGameMapData / resolveProvinceDetailHostOverlayArgs (Refs #4035 AC3).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('tryGetGameMapData (Refs #4035 AC3)', () {
    test('positive: returns map data when load succeeds', () {
      final GameMapData data = (
        tileMapByRegion: <String, TileMapResult>{},
        topologyByRegion: <String, MapTopology>{},
        combinedTopology: const MapTopology(),
        warpLinks: null,
      );
      final result = tryGetGameMapData(() => data);
      expect(result, isNotNull);
      expect(result!.combinedTopology, same(data.combinedTopology));
    });

    test('negative: returns null when load throws', () {
      expect(
        tryGetGameMapData(() => throw StateError('hive not ready')),
        isNull,
      );
    });

    test('positive: null load result is preserved (not treated as error)', () {
      expect(tryGetGameMapData(() => null), isNull);
    });
  });

  group('resolveProvinceDetailHostOverlayArgs (Refs #4035 AC3)', () {
    test(
      'positive: loadMapData success wires mapData and close/bus callbacks',
      () {
        final GameMapData data = (
          tileMapByRegion: <String, TileMapResult>{},
          topologyByRegion: <String, MapTopology>{},
          combinedTopology: const MapTopology(),
          warpLinks: null,
        );
        final notifier = MapProvincePanelNotifier();
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        final args = resolveProvinceDetailHostOverlayArgs(
          loadMapData: () => data,
          panelNotifier: notifier,
          bus: bus,
        );

        expect(args.mapData, same(data));
        expect(args.bus, same(bus));
        expect(args.onClose, notifier.closeOverlay);
      },
    );

    test(
      'negative: Hive/service failure inside loadMapData yields null mapData',
      () {
        final notifier = MapProvincePanelNotifier();
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        final args = resolveProvinceDetailHostOverlayArgs(
          loadMapData: () => throw StateError('Box not found'),
          panelNotifier: notifier,
          bus: bus,
        );

        expect(args.mapData, isNull);
        expect(args.bus, same(bus));
      },
    );
  });
}
