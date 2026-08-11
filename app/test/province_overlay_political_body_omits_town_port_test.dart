// Pins the Political body composition for ProvinceSeaZoneDetailOverlay:
// the section renders Name / Owner / Region / Capital / Town development
// (Refs #3870).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay;

import 'province_overlay_test_harness.dart';

Finder _textWhere(bool Function(String data) predicate) =>
    find.byWidgetPredicate((Widget w) => w is Text && predicate(w.data ?? ''));

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay Political body composition '
      '(SPEC § Province overlay content / § Acceptance criteria)', () {
    testWidgets(
      'Political body renders Name / Owner / Region / Capital / Town development',
      (WidgetTester tester) async {
        final game = demoGameForOverlay;
        final humanId = game.players.first.id;
        final owned = ownedProvinceIdInOldWorld(game: game, ownerId: humanId);
        Province? province;
        for (final p in [
          ...game.worldState.oldWorld.provinces,
          ...game.worldState.newWorld.provinces,
        ]) {
          if (p.id == owned) {
            province = p;
            break;
          }
        }
        expect(province, isNotNull);

        await tester.pumpWidget(
          buildProvinceOverlayDarkThemeShell(game: game, displayId: owned),
        );
        await tester.pumpAndSettle();

        expect(_textWhere((d) => d.startsWith('Name:')), findsOneWidget);
        expect(_textWhere((d) => d.startsWith('Owner:')), findsOneWidget);
        expect(_textWhere((d) => d.startsWith('Region:')), findsOneWidget);
        expect(_textWhere((d) => d.startsWith('Capital:')), findsOneWidget);
        expect(
          _textWhere(
            (d) =>
                d ==
                'Town development: ${province!.townDevelopmentLevel} of 4',
          ),
          findsOneWidget,
          reason: 'Political body must show true town development level.',
        );
      },
    );

    testWidgets(
      'Political body omits port-status row',
      (WidgetTester tester) async {
        final game = demoGameForOverlay;
        final humanId = game.players.first.id;
        final owned = ownedProvinceIdInOldWorld(game: game, ownerId: humanId);

        await tester.pumpWidget(
          buildProvinceOverlayDarkThemeShell(game: game, displayId: owned),
        );
        await tester.pumpAndSettle();

        expect(
          _textWhere((d) => d.toLowerCase().contains('port status')),
          findsNothing,
        );
      },
    );
  });
}
