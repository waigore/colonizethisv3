// Pins the dark editorial-monocle Military section body tokens for
// ProvinceSeaZoneDetailOverlay (S7 — Military body).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Military section body tokens
// (Refs #2865 S7).
//
// Material defaults (`Theme.of(context).colorScheme.onSurface`, the dark
// Material `Colors.white` fallback, or a `const TextStyle` whose `color`
// is `null` and so falls back to `DefaultTextStyle`) MUST NOT colour the
// owner sub-header or the pending land-MoveOrder preview lines. All
// colours resolve from `EditorialMonoclePalette` tokens, so the dark
// theme owns this surface.

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

import 'support/province_overlay_test_harness.dart';

/// Returns the demo game with one extra infantry regiment (owned by
/// [ownerId], located in [provinceId] in Old World) appended to
/// `worldState.oldWorld.units`, plus optionally a pending land
/// `MoveOrder` for that regiment routed to [destinationTileKey] under
/// `orders.moveOrdersByPlayerId[ownerId]`.
({Game game, Orders orders, String unitId}) _gameWithMilitary({
  required String ownerId,
  required String provinceId,
  bool withPendingMove = false,
  String? destinationTileKey,
}) {
  final base = demoGameForOverlay;
  final ws = base.worldState;
  const unitId = 'test_pikemen_militaryDarkTokens';
  // `pikemen` is a canonical regiment id in
  // `packages/colonizethis_data/lib/src/combat_config.dart`, so
  // `isMilitaryUnit('pikemen')` returns true and the unit lands in the
  // Military section (vs the Civilian section, which would happen with
  // an unknown type id like `infantry`).
  final regiment = Unit(
    id: unitId,
    type: 'pikemen',
    ownerId: ownerId,
    locationProvinceId: provinceId,
  );
  final updatedOldWorld = RegionData(
    provinces: ws.oldWorld.provinces,
    units: [...ws.oldWorld.units, regiment],
  );
  final updatedWs = ws.copyWith(oldWorld: updatedOldWorld);
  final game = base.copyWith(worldState: updatedWs);

  Orders orders = const Orders();
  if (withPendingMove) {
    if (destinationTileKey == null) {
      fail(
        'Test setup: withPendingMove requires destinationTileKey to be set.',
      );
    }
    orders = Orders(
      moveOrdersByPlayerId: {
        ownerId: [
          MoveOrder(
            unitId: unitId,
            destinationTileKey: destinationTileKey,
          ),
        ],
      },
    );
  }
  return (game: game, orders: orders, unitId: unitId);
}


void main() {
  suppressLogsForTests();

  // Mirrors `province_overlay_dark_chrome_test.dart` (Refs #2859 R2 / S3):
  // `CtPanel` now paints its dark editorial-monocle chrome programmatically
  // so no asset bundle stub is required here either.

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Military section '
    'body (SPEC § Dark-theme Military section body tokens)',
    () {
      testWidgets(
        'owner sub-header (in-province roster) resolves to '
        'EditorialMonoclePalette.fg with FontWeight.w600',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: humanId,
          );
          final setup = _gameWithMilitary(
            ownerId: humanId,
            provinceId: ownedProvince,
          );

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: setup.game,
              displayId: ownedProvince,
              draftOrders: setup.orders,
            ),
          );
          await tester.pumpAndSettle();

          final humanDisplayName = setup.game.players
              .firstWhere((p) => p.id == humanId)
              .displayName;
          expect(
            humanDisplayName,
            isNotEmpty,
            reason: 'Human player must have a non-empty displayName for the '
                'Military section owner sub-header to render.',
          );
          // Capture every rendered Text to surface a meaningful failure
          // message if the section did not build (e.g. intel gating was
          // unexpectedly false) — the truthy assertion below would
          // otherwise surface a bare "Bad state: No element".
          final List<String> renderedTexts = tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data ?? '')
              .toList();
          expect(
            find.text(humanDisplayName),
            findsAtLeastNWidgets(1),
            reason:
                'Owner sub-header "$humanDisplayName" must render in the '
                'Military section. Visible texts so far: '
                '${renderedTexts.where((s) => s.isNotEmpty).take(40).toList()}',
          );
          final Text ownerHeader = tester.widget<Text>(
            find.text(humanDisplayName),
          );
          expect(
            ownerHeader.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Military owner sub-header must resolve TextStyle.color to '
                'EditorialMonoclePalette.fg per SPEC § Dark-theme Military '
                'section body tokens.',
          );
          expect(
            ownerHeader.style?.fontWeight,
            FontWeight.w600,
            reason:
                'Military owner sub-header must retain FontWeight.w600 per '
                'SPEC § Dark-theme Military section body tokens.',
          );
        },
      );

      testWidgets(
        'pending land MoveOrder preview line resolves to '
        'EditorialMonoclePalette.muted',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: humanId,
          );
          // Destination is the same human-owned province so the pending
          // MoveOrder unconditionally concerns it; the visual contract
          // pinned here does not depend on the routing semantics.
          final tileKeys = game.worldState
              .tileKeysByRegionAndProvince['oldWorld']?[ownedProvince];
          expect(
            tileKeys,
            isNotNull,
            reason:
                'Test setup: tileKeysByRegionAndProvince must yield tiles '
                'for the human-owned demo province.',
          );
          expect(tileKeys!, isNotEmpty);
          final destinationTileKey = tileKeys.first;

          final setup = _gameWithMilitary(
            ownerId: humanId,
            provinceId: ownedProvince,
            withPendingMove: true,
            destinationTileKey: destinationTileKey,
          );

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: setup.game,
              displayId: ownedProvince,
              draftOrders: setup.orders,
            ),
          );
          await tester.pumpAndSettle();

          // The localized "Ordered: move regiment to {destination}" string
          // starts with "Ordered:" (see app/lib/l10n/arb/app_en.arb
          // `province_pending_regimentMove`). The preview line is rendered
          // as a `Padding` wrapping a `Text` whose first characters are
          // `Ordered:`.
          final previewFinder = find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').startsWith('Ordered:'),
          );
          expect(
            previewFinder,
            findsAtLeastNWidgets(1),
            reason:
                'Test setup: pending regiment MoveOrder must render as an '
                '"Ordered: ..." preview line in the Military section.',
          );
          final Text previewLine = tester.widget<Text>(previewFinder.first);
          expect(
            previewLine.style?.color,
            EditorialMonoclePalette.muted,
            reason:
                'Pending land MoveOrder preview line must resolve '
                'TextStyle.color to EditorialMonoclePalette.muted per SPEC '
                '§ Dark-theme Military section body tokens.',
          );
        },
      );

      testWidgets(
        'negative: owner sub-header does not use a const TextStyle with '
        'null color and does not fall back to bare Material defaults',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: humanId,
          );
          final setup = _gameWithMilitary(
            ownerId: humanId,
            provinceId: ownedProvince,
          );

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: setup.game,
              displayId: ownedProvince,
              draftOrders: setup.orders,
            ),
          );
          await tester.pumpAndSettle();

          final humanDisplayName = setup.game.players
              .firstWhere((p) => p.id == humanId)
              .displayName;
          final Text ownerHeader = tester.widget<Text>(
            find.text(humanDisplayName),
          );
          // The contract: the owner sub-header must declare its own
          // `TextStyle.color`. A `const TextStyle(fontWeight: …)` with no
          // colour resolves the `color` getter to `null` (the property is
          // unset; rendering then falls through to the ambient
          // `DefaultTextStyle`). Asserting `style?.color != null` catches
          // any future regression that drops the explicit
          // `EditorialMonoclePalette.fg` colour back to `null`.
          expect(
            ownerHeader.style?.color,
            isNotNull,
            reason:
                'Material defaults regression guard: the owner sub-header '
                'must declare its own TextStyle.color rather than relying on '
                'DefaultTextStyle fall-through (so the contract survives a '
                'change in ambient bodyMedium colour).',
          );
          // The bare dark-Material `bodyMedium` colour without the
          // `editorialMonocle` override is `Colors.white`; explicitly
          // forbid it so a future theme swap that lost the
          // `EditorialMonoclePalette.fg` override is surfaced.
          expect(
            ownerHeader.style?.color,
            isNot(equals(Colors.white)),
            reason:
                'Material defaults regression guard: owner sub-header must '
                'not resolve to the dark Material `Colors.white` fallback.',
          );
          expect(
            ownerHeader.style?.color,
            equals(EditorialMonoclePalette.fg),
            reason:
                'Material defaults regression guard: owner sub-header must '
                'resolve to EditorialMonoclePalette.fg (the single source).',
          );
        },
      );

      testWidgets(
        'regiment-type-count indented line resolves to '
        'EditorialMonoclePalette.fg',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: humanId,
          );
          final setup = _gameWithMilitary(
            ownerId: humanId,
            provinceId: ownedProvince,
          );

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: setup.game,
              displayId: ownedProvince,
              draftOrders: setup.orders,
            ),
          );
          await tester.pumpAndSettle();

          // `_gameWithMilitary` appends one `pikemen` regiment owned by
          // [humanId] to the demo Old World. With the demo seed the
          // human-owned demo province contains no other regiments, so
          // the Military section renders exactly one localized
          // `provinceOverlay_indentedCount(label, count)` line, which
          // resolves to `  Pikemen: 1` per `app/lib/l10n/arb/app_en.arb`
          // (`province_regiment_pikemen` + `provinceOverlay_indentedCount`).
          final typeCountFinder = find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').trimLeft().startsWith('Pikemen:'),
          );
          expect(
            typeCountFinder,
            findsAtLeastNWidgets(1),
            reason:
                'Test setup: the appended `pikemen` regiment must render '
                'as a `  Pikemen: 1` indented type-count line in the '
                'Military section.',
          );
          final Text typeCountLine = tester.widget<Text>(
            typeCountFinder.first,
          );
          expect(
            typeCountLine.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Military regiment-type-count line must resolve '
                'TextStyle.color to EditorialMonoclePalette.fg per SPEC '
                '§ Dark-theme Military regiment-type-count line colour.',
          );
        },
      );

      testWidgets(
        'negative: regiment-type-count indented line declares its own '
        'TextStyle.color and is not Colors.white',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: humanId,
          );
          final setup = _gameWithMilitary(
            ownerId: humanId,
            provinceId: ownedProvince,
          );

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: setup.game,
              displayId: ownedProvince,
              draftOrders: setup.orders,
            ),
          );
          await tester.pumpAndSettle();

          final typeCountFinder = find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').trimLeft().startsWith('Pikemen:'),
          );
          expect(typeCountFinder, findsAtLeastNWidgets(1));
          final Text typeCountLine = tester.widget<Text>(
            typeCountFinder.first,
          );
          // The contract: the type-count line must declare its own
          // `TextStyle.color`. A `Text(...)` constructed without a
          // `style` parameter resolves `style?.color` to `null`, the
          // bare dark-Material `bodyMedium` fallback under another
          // `ThemeData` is `Colors.white`. Asserting both catches a
          // regression that drops the explicit
          // `EditorialMonoclePalette.fg` override.
          //
          // `style.color != Theme.of(context).colorScheme.onSurface` is
          // intentionally NOT asserted because under `editorialMonocle`
          // the dark theme wires `colorScheme.onSurface` to
          // `EditorialMonoclePalette.fg`, so an `isNot(onSurface)`
          // guard would tautologically fail for the type-count line's
          // correct value (matching the S7 owner sub-header and Naval
          // fleet-summary patterns).
          expect(
            typeCountLine.style?.color,
            isNotNull,
            reason:
                'Material defaults regression guard: the type-count '
                'line must declare its own TextStyle.color rather than '
                'relying on DefaultTextStyle fall-through (so the '
                'contract survives a change in ambient bodyMedium '
                'colour).',
          );
          expect(
            typeCountLine.style?.color,
            isNot(equals(Colors.white)),
            reason:
                'Material defaults regression guard: type-count line '
                'must not resolve to the dark Material `Colors.white` '
                'fallback.',
          );
          expect(
            typeCountLine.style?.color,
            equals(EditorialMonoclePalette.fg),
            reason:
                'Material defaults regression guard: type-count line '
                'must resolve to EditorialMonoclePalette.fg (the '
                'single source).',
          );
        },
      );

      testWidgets(
        'negative: pending land MoveOrder preview line is not '
        'Theme.colorScheme.onSurface and is not the dark Material default',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: humanId,
          );
          final tileKeys = game.worldState
              .tileKeysByRegionAndProvince['oldWorld']?[ownedProvince];
          expect(tileKeys, isNotNull);
          expect(tileKeys!, isNotEmpty);
          final destinationTileKey = tileKeys.first;

          final setup = _gameWithMilitary(
            ownerId: humanId,
            provinceId: ownedProvince,
            withPendingMove: true,
            destinationTileKey: destinationTileKey,
          );

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: setup.game,
              displayId: ownedProvince,
              draftOrders: setup.orders,
            ),
          );
          await tester.pumpAndSettle();

          final previewFinder = find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').startsWith('Ordered:'),
          );
          expect(previewFinder, findsAtLeastNWidgets(1));
          final Text previewLine = tester.widget<Text>(previewFinder.first);
          final BuildContext context = tester.element(previewFinder.first);
          final Color onSurface = Theme.of(context).colorScheme.onSurface;
          expect(
            previewLine.style?.color,
            isNotNull,
            reason:
                'Material defaults regression guard: pending preview line '
                'must declare its own TextStyle.color rather than relying '
                'on DefaultTextStyle fall-through.',
          );
          expect(
            previewLine.style?.color,
            isNot(equals(onSurface)),
            reason:
                'Material defaults regression guard: pending preview line '
                'must not resolve to Theme.of(context).colorScheme.onSurface; '
                'use EditorialMonoclePalette.muted instead.',
          );
          expect(
            previewLine.style?.color,
            isNot(equals(Colors.white)),
            reason:
                'Material defaults regression guard: pending preview line '
                'must not resolve to the dark Material `Colors.white` '
                'fallback.',
          );
        },
      );
    },
  );
}
