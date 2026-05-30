// Pins the dark editorial-monocle Naval section body tokens for
// ProvinceSeaZoneDetailOverlay (S7 — Naval body).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Naval section body tokens
// (Refs #2865 S7).
//
// Mirrors `province_overlay_military_section_dark_tokens_test.dart`
// (the Military `MoveOrder` preview-line slice) for the parallel Naval
// `NavalMoveOrder` preview lines:
//
//  * Positive: a pending in-port `NavalMoveOrder` preview line (rendered
//    via `provincePanelPendingNavalLines`) resolves its
//    `TextStyle.color` to `EditorialMonoclePalette.muted`.
//  * Negative regression guards: the same preview line MUST NOT fall
//    through `DefaultTextStyle` (`style?.color == null`), MUST NOT
//    resolve to the bare dark Material `bodyMedium` colour
//    (`Colors.white`), and MUST NOT consume
//    `Theme.of(context).colorScheme.onSurface` (which is the dark
//    Material `bodyMedium` proxy and is distinct from
//    `EditorialMonoclePalette.muted` under any non-`editorialMonocle`
//    theme).

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
/// owned by [ownerId] in the demo Old World. Province ids in the
/// debug-init game are already in their prefixed form (see
/// `colonizethis_logic` setup), so we return them as-is rather than
/// re-prefixing. Test pre-condition: at least one such province exists;
/// surface a test failure rather than silently fall back if not.
String _ownedProvinceId({required Game game, required String ownerId}) {
  for (final province in game.worldState.oldWorld.provinces) {
    if (province.ownerId == ownerId) {
      return province.id;
    }
  }
  fail(
    'Test setup: no province in oldWorld is owned by "$ownerId"; '
    'cannot construct a human-owned province for the Naval section.',
  );
}

/// Returns the demo game with one extra fleet in port at [provinceId]
/// (owned by [ownerId], region `oldWorld`) appended to
/// `worldState.fleets`, plus a pending `NavalMoveOrder` in
/// `orders.navalMoveOrdersByPlayerId[ownerId]` routing that fleet to a
/// non-empty sea-zone destination so
/// `provincePanelPendingNavalLines` emits the canonical "Ordered: move
/// fleet to sea …" preview line.
({Game game, Orders orders, String fleetId}) _gameWithFleetAndPendingMove({
  required String ownerId,
  required String provinceId,
  required String destinationSeaZoneId,
}) {
  final base = demoGameForOverlay;
  final ws = base.worldState;
  const fleetId = 'test_fleet_navalDarkTokens';
  // A single `frigate` ship instance so the fleet has non-empty
  // `ships` and the helper renders the in-port roster summary line.
  // The dark-token contract pinned here only depends on the pending
  // preview line, so the ship type is incidental.
  final fleet = Fleet(
    id: fleetId,
    ownerId: ownerId,
    inPortAtProvinceId: provinceId,
    regionId: 'oldWorld',
    shipTypeIds: const ['frigate'],
  );
  final updatedWs = ws.copyWith(fleets: [...ws.fleets, fleet]);
  final game = base.copyWith(worldState: updatedWs);

  final orders = Orders(
    navalMoveOrdersByPlayerId: {
      ownerId: [
        NavalMoveOrder(
          fleetId: fleetId,
          destinationSeaZoneId: destinationSeaZoneId,
        ),
      ],
    },
  );
  return (game: game, orders: orders, fleetId: fleetId);
}

Widget _darkOverlay({
  required Game game,
  required String displayId,
  required Orders draftOrders,
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
        draftOrders: draftOrders,
      ),
    ),
  );
}

/// Picks a non-empty sea-zone id to use as the pending move destination.
/// `provincePanelPendingNavalLines` resolves the destination via
/// `worldState.seaZoneDisplayNameById[id] ?? id`, so any non-empty
/// string produces the canonical "Ordered: move fleet to sea …" prefix
/// regardless of whether the id has a display name.
String _someSeaZoneIdForPendingMove(Game game) {
  final namedZones = game.worldState.seaZoneDisplayNameById.keys;
  if (namedZones.isNotEmpty) {
    return namedZones.first;
  }
  // Fallback: any non-empty string is fine — the helper falls back to
  // the raw id when no display name is registered.
  return 'oldWorld|s1';
}

void main() {
  suppressLogsForTests();

  // Mirrors the Military / Tile dark-token tests: `CtPanel` paints its
  // dark editorial-monocle chrome programmatically (Refs #2859 R2 / S3),
  // so no asset bundle stub is required here either.

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Naval section '
    'body (SPEC § Dark-theme Naval section body tokens)',
    () {
      testWidgets(
        'pending in-port NavalMoveOrder preview line resolves to '
        'EditorialMonoclePalette.muted',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = _ownedProvinceId(
            game: game,
            ownerId: humanId,
          );
          final destination = _someSeaZoneIdForPendingMove(game);

          final setup = _gameWithFleetAndPendingMove(
            ownerId: humanId,
            provinceId: ownedProvince,
            destinationSeaZoneId: destination,
          );

          await tester.pumpWidget(
            _darkOverlay(
              game: setup.game,
              displayId: ownedProvince,
              draftOrders: setup.orders,
            ),
          );
          await tester.pumpAndSettle();

          // The localized "Ordered: move fleet to sea {zone}" string
          // starts with "Ordered:" (see app/lib/l10n/arb/app_en.arb
          // `province_pending_fleetMoveSea`). The preview line is
          // rendered as a `Padding` wrapping a `Text` whose first
          // characters are `Ordered:`, mirroring the Military pending
          // preview line shape.
          final previewFinder = find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').startsWith('Ordered:'),
          );
          expect(
            previewFinder,
            findsAtLeastNWidgets(1),
            reason:
                'Test setup: pending NavalMoveOrder must render as an '
                '"Ordered: move fleet to sea ..." preview line in the '
                'Naval section.',
          );
          final Text previewLine = tester.widget<Text>(previewFinder.first);
          expect(
            previewLine.style?.color,
            EditorialMonoclePalette.muted,
            reason:
                'Pending in-port NavalMoveOrder preview line must resolve '
                'TextStyle.color to EditorialMonoclePalette.muted per SPEC '
                '§ Dark-theme Naval section body tokens.',
          );
        },
      );

      testWidgets(
        'negative: pending in-port NavalMoveOrder preview line is not '
        'Theme.colorScheme.onSurface and is not the dark Material default',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = _ownedProvinceId(
            game: game,
            ownerId: humanId,
          );
          final destination = _someSeaZoneIdForPendingMove(game);

          final setup = _gameWithFleetAndPendingMove(
            ownerId: humanId,
            provinceId: ownedProvince,
            destinationSeaZoneId: destination,
          );

          await tester.pumpWidget(
            _darkOverlay(
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
            isNot(equals(Colors.white)),
            reason:
                'Material defaults regression guard: pending preview line '
                'must not resolve to the dark Material `Colors.white` '
                'fallback.',
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
            equals(EditorialMonoclePalette.muted),
            reason:
                'Material defaults regression guard: pending preview line '
                'must resolve to EditorialMonoclePalette.muted (the single '
                'source).',
          );
        },
      );
    },
  );
}
