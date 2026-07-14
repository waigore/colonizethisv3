// Pins the dark editorial-monocle Civilian section body tokens for
// ProvinceSeaZoneDetailOverlay (S8 — Civilian body).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Civilian section body tokens
// (Refs #2865 S8).
//
// Material defaults (`Theme.of(context).colorScheme.onSurface`, the dark
// Material `Colors.white` fallback, or a bare `Text(...)` with `style: null`
// that falls through to `DefaultTextStyle`) MUST NOT colour the own- or
// foreign-civilian row labels. All colours resolve from
// `EditorialMonoclePalette` tokens so the dark theme owns this surface.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'support/province_overlay_dark_token_scenarios.dart';
import 'support/province_overlay_test_harness.dart';

const _regionId = 'oldWorld';
const _localProvinceId = 'pCivDarkTokens';
const _humanPlayerId = 'gp1';
const _foreignPlayerId = 'gp2';
String get _fullProvinceId => '$_regionId|$_localProvinceId';

String _tileKey(int x, int y) => overlayDarkTokenTileKey(
  regionId: _regionId,
  localProvinceId: _localProvinceId,
  x: x,
  y: y,
);

/// Finds the `Text(...)` row that prefixes with the literal `Explorer:`
/// emitted by `provinceOverlay_unitTarget` for the human player's own
/// idle Explorer civilian.
Finder _ownExplorerRowFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').startsWith('Explorer:') &&
        // Exclude the foreign-civilian line which embeds the owner prefix.
        !(w.data ?? '').contains('—'),
  );
}

/// Finds the `Text(...)` row emitted by `provinceOverlay_foreignUnitStatus`
/// for a visible foreign Merchant civilian (format `{owner} — {type}: {status}`).
Finder _foreignMerchantRowFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').contains(kUnitTypeMerchant) &&
        (w.data ?? '').contains('—'),
  );
}

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay dark editorial-monocle Civilian section '
      'body (SPEC § Dark-theme Civilian section body tokens, S8)', () {
    testWidgets(
      'own civilian row label resolves to EditorialMonoclePalette.fg',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        final ownUnit = Unit(
          id: 'c-own',
          type: kUnitTypeExplorer,
          ownerId: _humanPlayerId,
          locationProvinceId: _fullProvinceId,
          tileKey: tk,
        );
        final game = gameWithCivilianUnitsForOverlay(
          gameId: 'civilian_dark_tokens_test',
          regionId: _regionId,
          fullProvinceId: _fullProvinceId,
          displayName: 'CivDarkTokens',
          humanPlayerId: _humanPlayerId,
          foreignPlayerId: _foreignPlayerId,
          tileKeys: [tk],
          units: [ownUnit],
        );
        final region = regionMapWithLandCells(
          regionId: _regionId,
          localProvinceId: _localProvinceId,
          coords: [(x: 0, y: 0)],
          width: 1,
          height: 1,
          greatPowerFactionIds: const {_humanPlayerId, _foreignPlayerId},
        );

        await tester.pumpWidget(
          buildProvinceOverlayDarkThemeShell(
            game: game,
            region: region,
            displayId: _fullProvinceId,
            selectedTileKey: tk,
            humanPlayerId: _humanPlayerId,
            playerView: omniscientPlayerViewForTiles(
              humanPlayerId: _humanPlayerId,
              keys: [tk],
            ),
            shellWidth: 800,
          ),
        );
        await tester.pumpAndSettle();

        final finder = _ownExplorerRowFinder();
        expect(
          finder,
          findsAtLeastNWidgets(1),
          reason:
              'Test setup: with one own Explorer (humanPlayerId) the '
              'Civilian section must render the '
              '"Explorer: {status}" row label per '
              'provinceOverlay_unitTarget (app_en.arb).',
        );
        final Text label = tester.widget<Text>(finder.first);
        expect(
          label.style?.color,
          EditorialMonoclePalette.fg,
          reason:
              'Own-civilian row label must resolve TextStyle.color to '
              'EditorialMonoclePalette.fg per SPEC § Dark-theme '
              'Civilian section body tokens (S8 — Civilian body).',
        );
      },
    );

    testWidgets('foreign civilian row label resolves to '
        'EditorialMonoclePalette.muted', (WidgetTester tester) async {
      final tk = _tileKey(0, 0);
      final foreignUnit = Unit(
        id: 'c-foreign',
        type: kUnitTypeMerchant,
        ownerId: _foreignPlayerId,
        locationProvinceId: _fullProvinceId,
        // Foreign civilian visibility requires a non-unknown tile
        // visibility on the unit's tile from the human player's view;
        // tileKey ties the unit to a tile the human can see.
        tileKey: tk,
      );
      final game = gameWithCivilianUnitsForOverlay(
        gameId: 'civilian_dark_tokens_test',
        regionId: _regionId,
        fullProvinceId: _fullProvinceId,
        displayName: 'CivDarkTokens',
        humanPlayerId: _humanPlayerId,
        foreignPlayerId: _foreignPlayerId,
        tileKeys: [tk],
        units: [foreignUnit],
      );
      final region = regionMapWithLandCells(
        regionId: _regionId,
        localProvinceId: _localProvinceId,
        coords: [(x: 0, y: 0)],
        width: 1,
        height: 1,
        greatPowerFactionIds: const {_humanPlayerId, _foreignPlayerId},
      );

      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          region: region,
          displayId: _fullProvinceId,
          selectedTileKey: tk,
          humanPlayerId: _humanPlayerId,
          playerView: omniscientPlayerViewForTiles(
            humanPlayerId: _humanPlayerId,
            keys: [tk],
          ),
          shellWidth: 800,
        ),
      );
      await tester.pumpAndSettle();

      final finder = _foreignMerchantRowFinder();
      expect(
        finder,
        findsAtLeastNWidgets(1),
        reason:
            'Test setup: with one visible foreign Merchant the Civilian '
            'section must render the "{owner} — Merchant: {status}" row '
            'label per provinceOverlay_foreignUnitStatus (app_en.arb).',
      );
      final Text label = tester.widget<Text>(finder.first);
      expect(
        label.style?.color,
        EditorialMonoclePalette.muted,
        reason:
            'Foreign-civilian row label must resolve TextStyle.color '
            'to EditorialMonoclePalette.muted per SPEC § Dark-theme '
            'Civilian section body tokens (S8 — Civilian body).',
      );
    });

    testWidgets('negative: own civilian row label does not fall back to bare '
        'Material defaults', (WidgetTester tester) async {
      final tk = _tileKey(0, 0);
      final ownUnit = Unit(
        id: 'c-own',
        type: kUnitTypeExplorer,
        ownerId: _humanPlayerId,
        locationProvinceId: _fullProvinceId,
        tileKey: tk,
      );
      final game = gameWithCivilianUnitsForOverlay(
        gameId: 'civilian_dark_tokens_test',
        regionId: _regionId,
        fullProvinceId: _fullProvinceId,
        displayName: 'CivDarkTokens',
        humanPlayerId: _humanPlayerId,
        foreignPlayerId: _foreignPlayerId,
        tileKeys: [tk],
        units: [ownUnit],
      );
      final region = regionMapWithLandCells(
        regionId: _regionId,
        localProvinceId: _localProvinceId,
        coords: [(x: 0, y: 0)],
        width: 1,
        height: 1,
        greatPowerFactionIds: const {_humanPlayerId, _foreignPlayerId},
      );

      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          region: region,
          displayId: _fullProvinceId,
          selectedTileKey: tk,
          humanPlayerId: _humanPlayerId,
          playerView: omniscientPlayerViewForTiles(
            humanPlayerId: _humanPlayerId,
            keys: [tk],
          ),
          shellWidth: 800,
        ),
      );
      await tester.pumpAndSettle();

      final finder = _ownExplorerRowFinder();
      final Text label = tester.widget<Text>(finder.first);
      // The contract: the own-civilian row label must declare its own
      // `TextStyle.color`. A bare `Text(...)` with `style: null`
      // resolves the `color` getter to `null` (the property is unset;
      // rendering falls through to the ambient `DefaultTextStyle`).
      // Asserting `style?.color != null` catches a future regression
      // that drops the explicit `EditorialMonoclePalette.fg` colour
      // back to `null`.
      expect(
        label.style?.color,
        isNotNull,
        reason:
            'Material defaults regression guard: own-civilian row '
            'label must declare its own TextStyle.color rather than '
            'relying on DefaultTextStyle fall-through (so the contract '
            'survives a change in ambient bodyMedium colour).',
      );
      expect(
        label.style?.color,
        isNot(equals(Colors.white)),
        reason:
            'Material defaults regression guard: own-civilian row '
            'label must not resolve to the dark Material `Colors.white` '
            'fallback before the editorialMonocle overlay.',
      );
      expect(
        label.style?.color,
        equals(EditorialMonoclePalette.fg),
        reason:
            'Material defaults regression guard: own-civilian row '
            'label must resolve to EditorialMonoclePalette.fg (the '
            'single source). Note: an `isNot(onSurface)` guard is '
            'intentionally omitted because under editorialMonocle the '
            'dark colorScheme.onSurface == EditorialMonoclePalette.fg, '
            'which would tautologically fail.',
      );
    });

    testWidgets('negative: foreign civilian row label is not '
        'Theme.colorScheme.onSurface and is not the dark Material default', (
      WidgetTester tester,
    ) async {
      final tk = _tileKey(0, 0);
      final foreignUnit = Unit(
        id: 'c-foreign',
        type: kUnitTypeMerchant,
        ownerId: _foreignPlayerId,
        locationProvinceId: _fullProvinceId,
        tileKey: tk,
      );
      final game = gameWithCivilianUnitsForOverlay(
        gameId: 'civilian_dark_tokens_test',
        regionId: _regionId,
        fullProvinceId: _fullProvinceId,
        displayName: 'CivDarkTokens',
        humanPlayerId: _humanPlayerId,
        foreignPlayerId: _foreignPlayerId,
        tileKeys: [tk],
        units: [foreignUnit],
      );
      final region = regionMapWithLandCells(
        regionId: _regionId,
        localProvinceId: _localProvinceId,
        coords: [(x: 0, y: 0)],
        width: 1,
        height: 1,
        greatPowerFactionIds: const {_humanPlayerId, _foreignPlayerId},
      );

      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          region: region,
          displayId: _fullProvinceId,
          selectedTileKey: tk,
          humanPlayerId: _humanPlayerId,
          playerView: omniscientPlayerViewForTiles(
            humanPlayerId: _humanPlayerId,
            keys: [tk],
          ),
          shellWidth: 800,
        ),
      );
      await tester.pumpAndSettle();

      final finder = _foreignMerchantRowFinder();
      final Text label = tester.widget<Text>(finder.first);
      final BuildContext context = tester.element(finder.first);
      final Color onSurface = Theme.of(context).colorScheme.onSurface;
      expect(
        label.style?.color,
        isNotNull,
        reason:
            'Material defaults regression guard: foreign-civilian row '
            'label must declare its own TextStyle.color rather than '
            'relying on DefaultTextStyle fall-through.',
      );
      expect(
        label.style?.color,
        isNot(equals(onSurface)),
        reason:
            'Material defaults regression guard: foreign-civilian row '
            'label must not resolve to '
            'Theme.of(context).colorScheme.onSurface; use '
            'EditorialMonoclePalette.muted instead.',
      );
      expect(
        label.style?.color,
        isNot(equals(Colors.white)),
        reason:
            'Material defaults regression guard: foreign-civilian row '
            'label must not resolve to the dark Material `Colors.white` '
            'fallback.',
      );
      expect(
        label.style?.color,
        equals(EditorialMonoclePalette.muted),
        reason:
            'Material defaults regression guard: foreign-civilian row '
            'label must resolve to EditorialMonoclePalette.muted (the '
            'single source).',
      );
    });
  });
}
