// Smoke tests for province draft-orders support (Refs #4035).

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/province_draft_orders_test_support.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pumpProvinceDraftOrdersOverlay hosts overlay shell', (
    WidgetTester tester,
  ) async {
    final tileKey = provinceDraftOrdersTileKey(0, 0);
    await pumpProvinceDraftOrdersOverlay(
      tester,
      game: provinceDraftOrdersGame(
        id: 'draft_support_smoke',
        tileKey: tileKey,
      ),
      tileKey: tileKey,
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
  });
}
