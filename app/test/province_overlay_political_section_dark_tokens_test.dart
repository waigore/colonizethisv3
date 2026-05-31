// Pins the dark editorial-monocle Political section body tokens for
// ProvinceSeaZoneDetailOverlay.
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Political section body tokens
// (Refs #2865).
//
// Material defaults (`Theme.of(context).colorScheme.onSurface`, the dark
// Material `Colors.white` fallback, or a `Text` whose `style` is `null`
// and so falls back to `DefaultTextStyle`) MUST NOT colour the Political
// section "Name" / "Owner" body rows. Both rows resolve their
// `TextStyle.color` from `EditorialMonoclePalette.fg`, so the dark theme
// owns this surface end-to-end (mirroring the Tile / Economic / Civilian /
// Military / Naval section dark-token pins on this issue).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

/// Returns a province id (regionId|localId, e.g. `oldWorld|gpName_2`)
/// owned by [ownerId] in the demo Old World. `Province.id` in the
/// debug-init game is already the prefixed form (see
/// `colonizethis_logic` setup), so the helper returns it as-is rather
/// than re-prefixing. Test pre-condition: at least one such province
/// exists; surface a test failure rather than silently fall back if
/// not.
String _ownedProvinceId({required Game game, required String ownerId}) {
  for (final province in game.worldState.oldWorld.provinces) {
    if (province.ownerId == ownerId) {
      return province.id;
    }
  }
  fail(
    'Test setup: no province in oldWorld is owned by "$ownerId"; '
    'cannot construct a human-owned province for the Political section.',
  );
}

Widget _darkOverlay({
  required Game game,
  required String displayId,
}) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: demoRegionForOverlay,
        displayId: displayId,
        selectedTileKey: null,
        humanPlayerId: game.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
        draftOrders: const Orders(),
      ),
    ),
  );
}

Finder _findTextStartingWith(String prefix) => find.byWidgetPredicate(
  (Widget w) => w is Text && (w.data ?? '').startsWith(prefix),
);

void main() {
  suppressLogsForTests();

  // Mirrors `province_overlay_dark_chrome_test.dart` (Refs #2859 R2 / S3):
  // `CtPanel` paints its dark editorial-monocle chrome programmatically so
  // no asset bundle stub is required here either.

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Political section '
    'body (SPEC § Dark-theme Political section body tokens)',
    () {
      testWidgets(
        '"Name: ..." row resolves to EditorialMonoclePalette.fg',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = _ownedProvinceId(
            game: game,
            ownerId: humanId,
          );

          await tester.pumpWidget(
            _darkOverlay(game: game, displayId: ownedProvince),
          );
          await tester.pumpAndSettle();

          final nameFinder = _findTextStartingWith('Name:');
          // Surface a meaningful failure when the section did not build
          // (e.g. the demo game's selected province changed) — the bare
          // `widget<Text>` call would otherwise throw a confusing
          // "No element" inside the helper.
          final List<String> renderedTexts = tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data ?? '')
              .toList();
          expect(
            nameFinder,
            findsAtLeastNWidgets(1),
            reason:
                'Political "Name: ..." row must render. Visible texts so '
                'far: ${renderedTexts.where((s) => s.isNotEmpty).take(40).toList()}',
          );
          final Text nameText = tester.widget<Text>(nameFinder.first);
          expect(
            nameText.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Political "Name: ..." row must resolve TextStyle.color to '
                'EditorialMonoclePalette.fg per SPEC § Dark-theme Political '
                'section body tokens.',
          );
        },
      );

      testWidgets(
        '"Owner: ..." row resolves to EditorialMonoclePalette.fg',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = _ownedProvinceId(
            game: game,
            ownerId: humanId,
          );

          await tester.pumpWidget(
            _darkOverlay(game: game, displayId: ownedProvince),
          );
          await tester.pumpAndSettle();

          final ownerFinder = _findTextStartingWith('Owner:');
          expect(
            ownerFinder,
            findsAtLeastNWidgets(1),
            reason:
                'Political "Owner: ..." row must render in the Political '
                'section.',
          );
          final Text ownerText = tester.widget<Text>(ownerFinder.first);
          expect(
            ownerText.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Political "Owner: ..." row must resolve TextStyle.color to '
                'EditorialMonoclePalette.fg per SPEC § Dark-theme Political '
                'section body tokens.',
          );
        },
      );

      testWidgets(
        'negative: Political rows declare explicit TextStyle.color (no '
        'DefaultTextStyle fall-through) and do not resolve to the dark '
        'Material `Colors.white` fallback',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = _ownedProvinceId(
            game: game,
            ownerId: humanId,
          );

          await tester.pumpWidget(
            _darkOverlay(game: game, displayId: ownedProvince),
          );
          await tester.pumpAndSettle();

          for (final prefix in const <String>['Name:', 'Owner:']) {
            final finder = _findTextStartingWith(prefix);
            expect(finder, findsAtLeastNWidgets(1));
            final Text row = tester.widget<Text>(finder.first);
            // The contract: each Political body row must declare its own
            // `TextStyle.color`. A bare `Text(line)` (no `style`) resolves
            // `style` to `null` and rendering falls through to ambient
            // `DefaultTextStyle`. Asserting `style?.color != null` catches
            // any regression that drops the explicit
            // `EditorialMonoclePalette.fg` colour back to `null`.
            expect(
              row.style?.color,
              isNotNull,
              reason:
                  'Material defaults regression guard: "$prefix" row must '
                  'declare its own TextStyle.color rather than relying on '
                  'DefaultTextStyle fall-through (so the contract survives '
                  'a change in ambient bodyMedium colour).',
            );
            // The bare dark-Material `bodyMedium` colour without the
            // `editorialMonocle` override is `Colors.white`; explicitly
            // forbid it so a future theme swap that lost the
            // `EditorialMonoclePalette.fg` override is surfaced.
            expect(
              row.style?.color,
              isNot(equals(Colors.white)),
              reason:
                  'Material defaults regression guard: "$prefix" row must '
                  'not resolve to the dark Material `Colors.white` '
                  'fallback.',
            );
            expect(
              row.style?.color,
              equals(EditorialMonoclePalette.fg),
              reason:
                  'Material defaults regression guard: "$prefix" row must '
                  'resolve to EditorialMonoclePalette.fg (the single '
                  'source).',
            );
          }
        },
      );
    },
  );
}
