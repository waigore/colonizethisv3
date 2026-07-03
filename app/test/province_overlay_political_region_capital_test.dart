// Pins the Political section Region + Capital rows for
// ProvinceSeaZoneDetailOverlay (Refs #2865).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Province overlay content `Political / Economic / Naval` and
// § Style / implementation — Dark-theme Political section body tokens.
//
// The Political body renders, in order, Name / Owner / Region / Capital.
// Region uses the localized region label (Old World / New World) for the
// province's regionId; Capital reads Yes when the province id equals the
// capitalProvinceId of any faction and No otherwise. Both rows are
// always-exact political intel and resolve their TextStyle.color to
// EditorialMonoclePalette.fg.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoHumanPlayerViewForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

import 'support/province_overlay_test_harness.dart';

String _nonCapitalOwnedProvinceId({
  required Game game,
  required String ownerId,
}) {
  for (final province in game.worldState.oldWorld.provinces) {
    if (province.ownerId == ownerId &&
        !provinceOverlayIsCapital(game, province.id)) {
      return province.id;
    }
  }
  fail(
    'Test setup: no non-capital province in oldWorld is owned by "$ownerId".',
  );
}

Game _withFirstPlayerCapital(Game base, String capitalProvinceId) {
  final players = <Player>[
    base.players.first.copyWith(capitalProvinceId: capitalProvinceId),
    ...base.players.skip(1),
  ];
  return base.copyWith(players: players);
}

Finder _findTextStartingWith(String prefix) => find.byWidgetPredicate(
  (Widget w) => w is Text && (w.data ?? '').startsWith(prefix),
);

void main() {
  suppressLogsForTests();

  group('province overlay Political helpers (Refs #2865)', () {
    test(
      'provinceOverlayRegionLabel maps oldWorld/newWorld and falls back',
      () {
        final l10n = lookupAppLocalizations(const Locale('en'));
        expect(provinceOverlayRegionLabel(l10n, 'oldWorld'), 'Old World');
        expect(provinceOverlayRegionLabel(l10n, 'newWorld'), 'New World');
        // Unknown region id is surfaced verbatim (defensive fallback).
        expect(
          provinceOverlayRegionLabel(l10n, 'mysteryRegion'),
          'mysteryRegion',
        );
      },
    );

    test('provinceOverlayIsCapital is true for a faction capital, false '
        'for a non-capital id', () {
      final base = demoGameForOverlay;
      final humanId = base.players.first.id;
      final owned = ownedProvinceIdInOldWorld(game: base, ownerId: humanId);
      final game = _withFirstPlayerCapital(base, owned);
      expect(provinceOverlayIsCapital(game, owned), isTrue);
      expect(
        provinceOverlayIsCapital(game, 'oldWorld|definitely_not_a_province'),
        isFalse,
      );
    });
  });

  group('ProvinceSeaZoneDetailOverlay Political Region + Capital rows '
      '(SPEC § Province overlay content)', () {
    testWidgets('Region row renders the localized region label in fg', (
      WidgetTester tester,
    ) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final owned = ownedProvinceIdInOldWorld(game: game, ownerId: humanId);

      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(game: game, displayId: owned),
      );
      await tester.pumpAndSettle();

      final finder = _findTextStartingWith('Region:');
      expect(finder, findsAtLeastNWidgets(1));
      final Text row = tester.widget<Text>(finder.first);
      expect(row.data, 'Region: Old World');
      expect(
        row.style?.color,
        EditorialMonoclePalette.fg,
        reason:
            'Region row must resolve TextStyle.color to '
            'EditorialMonoclePalette.fg per SPEC § Dark-theme Political '
            'section body tokens.',
      );
    });

    testWidgets('Capital row reads "Capital: Yes" for a faction capital '
        'province in fg', (WidgetTester tester) async {
      final base = demoGameForOverlay;
      final humanId = base.players.first.id;
      final owned = ownedProvinceIdInOldWorld(game: base, ownerId: humanId);
      final game = _withFirstPlayerCapital(base, owned);

      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(game: game, displayId: owned),
      );
      await tester.pumpAndSettle();

      final finder = find.text('Capital: Yes');
      expect(finder, findsAtLeastNWidgets(1));
      final Text row = tester.widget<Text>(finder.first);
      expect(
        row.style?.color,
        EditorialMonoclePalette.fg,
        reason:
            'Capital row must resolve TextStyle.color to '
            'EditorialMonoclePalette.fg.',
      );
    });

    testWidgets('Capital row reads "Capital: No" for a non-capital province', (
      WidgetTester tester,
    ) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final nonCapital = _nonCapitalOwnedProvinceId(
        game: game,
        ownerId: humanId,
      );

      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(game: game, displayId: nonCapital),
      );
      await tester.pumpAndSettle();

      expect(find.text('Capital: No'), findsAtLeastNWidgets(1));
      expect(find.text('Capital: Yes'), findsNothing);
    });
  });
}
