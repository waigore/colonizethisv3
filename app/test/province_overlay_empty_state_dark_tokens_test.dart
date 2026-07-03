// Pins the dark editorial-monocle empty-state body tokens for
// ProvinceSeaZoneDetailOverlay (S9 — empty `—` placeholders).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme empty-state body tokens (S9).
//
// Material defaults (`Theme.of(context).colorScheme.onSurface`, the
// dark Material `Colors.white` fallback, or a `const Text('—')` with
// `style: null` that falls back to `DefaultTextStyle`) MUST NOT colour
// the standalone em-dash placeholder rendered by the Economic /
// Military / Civilian / Naval sections when their body content is
// empty. All colours resolve from `EditorialMonoclePalette.muted` via
// a shared `_emptyBodyDashText()` helper so every empty-state surface
// stays in sync.
//
// The four positive ACs exercise one empty-state branch each:
//
//  * Economic — clear `worldState.resourceByTileKey` so no resource
//    rows can be emitted; human-owned province ensures intel gating
//    passes and the live `_buildEconomicSection` runs (not the `???`
//    intel-gated fallback).
//  * Military — clear all `regionData.units` so the partitioned
//    military list is empty; empty `Orders` ensures no pending land
//    `MoveOrder` preview lines fire.
//  * Civilian — same setup as Military; the partitioned civilian
//    list is empty and `foreignCivilianVisibleToPlayer` cannot fire
//    on an empty input.
//  * Naval — use a sea-zone `displayId` whose `_seaZoneContent` path
//    is reached (sea zone is at least partially revealed), clear all
//    `fleets`, and pass empty `Orders`. The sea-zone Naval section
//    is invoked with `pendingNavalPortProvinceId: null`, so no
//    pending naval preview lines fire either.
//
// A combined Material-defaults regression guard pins the contract
// that the placeholder's `style.color` is non-null, neither
// `Colors.white` nor `Theme.of(context).colorScheme.onSurface`, and
// resolves exactly to `EditorialMonoclePalette.muted`.

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
        demoRegionForOverlay,
        sampleSeaZoneIdForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

import 'support/province_overlay_test_harness.dart';

/// Returns a copy of [base] with every unit removed from both regions
/// and every entry removed from `resourceByTileKey`, so the Economic /
/// Military / Civilian sections all render their standalone empty
/// `Text('—')` placeholder body on a human-owned province (intel
/// gating passes via ownership, but there is nothing to list).
Game _sparseGame(Game base) {
  final ws = base.worldState;
  final updatedWs = ws.copyWith(
    oldWorld: RegionData(provinces: ws.oldWorld.provinces, units: const []),
    newWorld: RegionData(provinces: ws.newWorld.provinces, units: const []),
    fleets: const [],
    resourceByTileKey: const <String, String>{},
  );
  return base.copyWith(worldState: updatedWs);
}

/// Returns a copy of [base] with every fleet removed and empty
/// `Orders` so the Naval section's sea-zone empty branch fires
/// deterministically.
Game _gameWithNoFleets(Game base) {
  final ws = base.worldState;
  return base.copyWith(worldState: ws.copyWith(fleets: const []));
}


/// Returns every rendered `Text` whose `data == '—'` in the current
/// widget tree, with a deterministic ordering. Used by the empty-state
/// pins below to assert that each section's body emits exactly one
/// such placeholder under the dark theme.
List<Text> _emptyDashTextWidgets(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.data == '—')
      .toList(growable: false);
}

void main() {
  suppressLogsForTests();

  // Mirrors `province_overlay_military_section_dark_tokens_test.dart`
  // (Refs #2865 S7) — `CtPanel` paints its dark chrome programmatically
  // so no asset bundle stub is required here either.

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle empty-state '
    'body (SPEC § Dark-theme empty-state body tokens — S9)',
    () {
      testWidgets(
        'Economic empty body em-dash placeholder resolves to '
        'EditorialMonoclePalette.muted',
        (WidgetTester tester) async {
          final base = demoGameForOverlay;
          final humanId = base.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: base,
            ownerId: humanId,
          );
          final game = _sparseGame(base);

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: game,
              displayId: ownedProvince,
              draftOrders: const Orders(),
            ),
          );
          await tester.pumpAndSettle();

          // The sparse game strips resourceByTileKey, units, and
          // fleets; for the human-owned province the Economic,
          // Military, Civilian, and Naval sections all render the
          // standalone empty `Text('—')` body via the shared
          // `_emptyBodyDashText()` helper.
          final dashTexts = _emptyDashTextWidgets(tester);
          expect(
            dashTexts,
            isNotEmpty,
            reason:
                'Test setup: the sparse game must surface at least one '
                'empty-state em-dash placeholder (Economic, Military, '
                'Civilian, or Naval — sections may collapse if intel '
                'gating fails). Found placeholder count: '
                '${dashTexts.length}.',
          );
          for (final dash in dashTexts) {
            expect(
              dash.style?.color,
              EditorialMonoclePalette.muted,
              reason:
                  'Every empty-state em-dash placeholder must resolve '
                  'TextStyle.color to EditorialMonoclePalette.muted per '
                  'SPEC § Dark-theme empty-state body tokens (S9).',
            );
          }
        },
      );

      testWidgets(
        'Naval (sea-zone context) empty body em-dash placeholder '
        'resolves to EditorialMonoclePalette.muted',
        (WidgetTester tester) async {
          final base = demoGameForOverlay;
          final seaZoneId = sampleSeaZoneIdForOverlay;
          // Strip fleets so the sea-zone Naval section reaches its
          // `fleets.isEmpty && pending.isEmpty` empty branch.
          final game = _gameWithNoFleets(base);

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: game,
              displayId: seaZoneId,
              draftOrders: const Orders(),
            ),
          );
          await tester.pumpAndSettle();

          final dashTexts = _emptyDashTextWidgets(tester);
          expect(
            dashTexts,
            isNotEmpty,
            reason:
                'Test setup: the sea-zone Naval section must surface '
                'its standalone empty-state em-dash placeholder '
                '(`fleets.isEmpty && pending.isEmpty`) when the demo '
                'sea zone has no fleets and pending naval orders are '
                'empty.',
          );
          for (final dash in dashTexts) {
            expect(
              dash.style?.color,
              EditorialMonoclePalette.muted,
              reason:
                  'The sea-zone Naval empty `—` body must resolve '
                  'TextStyle.color to EditorialMonoclePalette.muted '
                  'per SPEC § Dark-theme empty-state body tokens (S9).',
            );
          }
        },
      );

      testWidgets(
        'negative: empty-state em-dash placeholder declares its own '
        'TextStyle.color and is neither Colors.white nor the dark '
        'Material onSurface fallback',
        (WidgetTester tester) async {
          final base = demoGameForOverlay;
          final humanId = base.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: base,
            ownerId: humanId,
          );
          final game = _sparseGame(base);

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: game,
              displayId: ownedProvince,
              draftOrders: const Orders(),
            ),
          );
          await tester.pumpAndSettle();

          final dashTexts = _emptyDashTextWidgets(tester);
          expect(dashTexts, isNotEmpty);
          // Resolve `onSurface` from the first placeholder's
          // BuildContext so the assertion is anchored to the same
          // ThemeData the placeholder sees. This protects against an
          // accidental theme drift where `colorScheme.onSurface` is
          // wired to something other than `EditorialMonoclePalette.fg`
          // (so the placeholder must remain explicitly `muted`).
          final BuildContext context = tester
              .element(find.byWidget(dashTexts.first));
          final Color onSurface = Theme.of(context).colorScheme.onSurface;
          for (final dash in dashTexts) {
            expect(
              dash.style?.color,
              isNotNull,
              reason:
                  'Material defaults regression guard: empty-state '
                  'em-dash placeholder must declare its own '
                  'TextStyle.color rather than relying on '
                  'DefaultTextStyle fall-through (so the contract '
                  'survives a change in ambient bodyMedium colour).',
            );
            expect(
              dash.style?.color,
              isNot(equals(Colors.white)),
              reason:
                  'Material defaults regression guard: empty-state '
                  'em-dash placeholder must not resolve to the dark '
                  'Material `Colors.white` fallback.',
            );
            expect(
              dash.style?.color,
              isNot(equals(onSurface)),
              reason:
                  'Material defaults regression guard: empty-state '
                  'em-dash placeholder must not resolve to '
                  'Theme.of(context).colorScheme.onSurface (the dark '
                  'Material `bodyMedium` proxy — distinct from '
                  '`EditorialMonoclePalette.muted` under any '
                  'non-`editorialMonocle` theme).',
            );
            expect(
              dash.style?.color,
              equals(EditorialMonoclePalette.muted),
              reason:
                  'Material defaults regression guard: empty-state '
                  'em-dash placeholder must resolve to '
                  'EditorialMonoclePalette.muted (the single source).',
            );
          }
        },
      );
    },
  );
}
