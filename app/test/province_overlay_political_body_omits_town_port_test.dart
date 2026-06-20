// Pins the Political body composition for ProvinceSeaZoneDetailOverlay:
// the section renders exactly Name / Owner / Region / Capital and
// intentionally omits a town-development-level row and a port-status row
// (Refs #2865).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Province overlay content `Political / Economic / Naval` and
// § Acceptance criteria — "Political body omits town-development level and
// port status". Town development is economic intel surfaced elsewhere and
// no province-level world-state field carries port status, so the
// always-exact Political body must not surface either field. This is the
// negative regression guard for that AC (the positive Region + Capital row
// rendering is pinned by province_overlay_political_region_capital_test.dart).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

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

Widget _darkOverlay({required Game game, required String displayId}) {
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

Finder _textWhere(bool Function(String data) predicate) =>
    find.byWidgetPredicate(
      (Widget w) => w is Text && predicate(w.data ?? ''),
    );

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay Political body composition '
    '(SPEC § Province overlay content / § Acceptance criteria)',
    () {
      testWidgets(
        'Political body renders exactly Name / Owner / Region / Capital rows',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final owned = _ownedProvinceId(game: game, ownerId: humanId);

          await tester.pumpWidget(_darkOverlay(game: game, displayId: owned));
          await tester.pumpAndSettle();

          // Each always-exact Political row renders exactly once.
          expect(
            _textWhere((d) => d.startsWith('Name:')),
            findsOneWidget,
            reason: 'Political body must render the Name row.',
          );
          expect(
            _textWhere((d) => d.startsWith('Owner:')),
            findsOneWidget,
            reason: 'Political body must render the Owner row.',
          );
          expect(
            _textWhere((d) => d.startsWith('Region:')),
            findsOneWidget,
            reason: 'Political body must render the Region row.',
          );
          expect(
            _textWhere((d) => d.startsWith('Capital:')),
            findsOneWidget,
            reason: 'Political body must render the Capital row '
                '(Capital: Yes or Capital: No).',
          );
        },
      );

      testWidgets(
        'Political body omits any town-development-level or port-status row',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final owned = _ownedProvinceId(game: game, ownerId: humanId);

          await tester.pumpWidget(_darkOverlay(game: game, displayId: owned));
          await tester.pumpAndSettle();

          // Negative regression guard for SPEC § Acceptance criteria
          // ("Political body omits town-development level and port status").
          // With no tile selected, the Tile section renders only its
          // guidance prompt, so the Tile "port or railroad" road caption is
          // not present; any of these substrings would indicate a leaked
          // town-development or port-status row.
          expect(
            _textWhere((d) => d.toLowerCase().contains('development level')),
            findsNothing,
            reason: 'Political body must not surface a town-development-level '
                'row (town development is economic intel surfaced elsewhere).',
          );
          expect(
            _textWhere((d) => d.toLowerCase().contains('port status')),
            findsNothing,
            reason: 'Political body must not surface a port-status row '
                '(no province-level world-state field carries port status).',
          );
          expect(
            _textWhere((d) => d.toLowerCase().startsWith('town')),
            findsNothing,
            reason: 'Political body must not surface a town-development row.',
          );
        },
      );
    },
  );
}
