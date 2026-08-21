// Pins Transport Overlay Candidates Widgetbook registration + shipped isolation
// (Refs #1819).
import 'dart:convert';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';
import 'package:widgetbook_host/catalogs/transport_overlay_candidate_preview.dart';

import 'widgetbook_in_game_shell_chrome_test_support.dart';

const _kExpectedUseCases = <String>{
  'Road — mask grid (candidate)',
  'Rail — mask grid (candidate)',
  'Road — network joins (candidate)',
  'Rail — network joins (candidate)',
  'Road — shipped vs candidate',
  'Rail — shipped vs candidate',
};

void main() {
  suppressLogsForTests();

  test('Transport Overlay Candidates folder registers six review use cases', () {
    final folder = transportOverlayCandidatesDirectories
        .whereType<WidgetbookFolder>()
        .firstWhere((f) => f.name == 'Transport Overlay Candidates');
    final names = (folder.children ?? const <WidgetbookNode>[])
        .whereType<WidgetbookUseCase>()
        .map((u) => u.name)
        .toSet();
    expect(names, _kExpectedUseCases);
  });

  testWidgets('Road mask-grid candidate story pumps without exception', (
    tester,
  ) async {
    await pumpWidgetbookStory(
      tester,
      transportOverlayCandidatesDirectories,
      folder: 'Transport Overlay Candidates',
      useCase: 'Road — mask grid (candidate)',
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(TransportOverlayCandidateMaskGrid), findsOneWidget);
  });

  test(
    'map terrain config transport_tilesets still point only at shipped atlases',
    () async {
      final raw = await rootBundle.loadString(
        'assets/data/map_terrain_tilesets.json',
      );
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final transport =
          json['transport_tilesets'] as Map<String, dynamic>? ?? const {};

      for (final family in ['road', 'rail']) {
        final entry = transport[family] as Map<String, dynamic>;
        final atlas = entry['atlas_png'] as String;
        expect(
          atlas,
          'assets/images/terrain/tilesets/tileset_transport_${family}_64.png',
        );
        expect(atlas.contains('widgetbook_host'), isFalse);
        expect(atlas.contains('transport_overlay_candidates'), isFalse);
        expect(atlas.contains('pytool/out'), isFalse);
      }
    },
  );

  test('candidate preview asset keys stay on widgetbook_host package', () {
    expect(
      kTransportOverlayCandidateRoadAsset,
      startsWith('packages/widgetbook_host/'),
    );
    expect(
      kTransportOverlayCandidateRailAsset,
      startsWith('packages/widgetbook_host/'),
    );
    expect(
      kTransportOverlayShippedRoadAsset,
      startsWith('packages/colonizethis_app/'),
    );
    expect(
      kTransportOverlayShippedRailAsset,
      startsWith('packages/colonizethis_app/'),
    );
  });
}
