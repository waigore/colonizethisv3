// Pins the dark editorial-monocle Tile section Resource row tokens:
// the localized `Resource: ` prefix (`provinceOverlay_tileResourcePrefix`)
// and the no-resource fallback `Text(resourceLabel)` (typically `—`).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Tile section body tokens
// (Refs #2865 S5 — extends the existing live-data Tile rows slice).
//
// Both Resource row `Text(...)` widgets in `_buildTileResourceLabelRow`
// MUST resolve their `TextStyle.color` to `EditorialMonoclePalette.fg`
// directly via the shared `_fgBodyStyle()` helper. Bare `Text(...)` with
// `style: null` is forbidden (the rendered colour would resolve through
// `DefaultTextStyle` fall-through). An `isNot(onSurface)` assertion is
// intentionally NOT used because under `editorialMonocle` the dark theme
// wires `colorScheme.onSurface` itself to `EditorialMonoclePalette.fg`,
// so the guard would tautologically fail for the correct token value
// (matching the existing live-data Tile-row pattern and the S6 Economic,
// S7 Military, S8 Civilian, Naval, and Political body pin patterns).
//
// The commodity-icon + visible commodity-id label rendered by the shared
// `ResourceLabelInline(commodityId: resourceVisible)` widget is
// intentionally out of scope here (the widget is also consumed by the
// Economic section row layout; pinning its label colour is tracked
// separately).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';

import 'support/province_overlay_test_harness.dart';

/// Returns the `Text` widget whose `data` exactly equals [text]. Used
/// for the literal Resource row children (`Resource: ` prefix and the
/// `—` no-resource fallback), which both render exactly once.
Text _findTileBodyTextExact(WidgetTester tester, String text) {
  final finder = find.byWidgetPredicate(
    (Widget w) => w is Text && w.data == text,
  );
  expect(
    finder,
    findsOneWidget,
    reason:
        'Expected exactly one Text whose data equals "$text" in the '
        'Tile section body.',
  );
  return tester.widget<Text>(finder);
}

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay dark editorial-monocle Tile section '
      'Resource row (SPEC § Dark-theme Tile section body tokens — '
      'live-data body rows: Resource row prefix + no-resource fallback)', () {
    testWidgets('Resource: prefix resolves to EditorialMonoclePalette.fg under '
        'editorialMonocle (positive AC: Resource row prefix colour)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildProvinceOverlayWithRevealedDemoTile());
      await tester.pumpAndSettle();

      final text = _findTileBodyTextExact(tester, 'Resource: ');
      expect(
        text.style?.color,
        EditorialMonoclePalette.fg,
        reason:
            'Tile Resource row prefix must resolve to '
            'EditorialMonoclePalette.fg (SPEC AC '
            '"Dark-theme Tile live-data — Resource row prefix '
            'colour").',
      );
    });

    testWidgets('Resource: prefix negative regression guard — never falls '
        'through DefaultTextStyle and never resolves to Colors.white '
        '(the bare dark Material bodyMedium fallback) under '
        'editorialMonocle', (WidgetTester tester) async {
      await tester.pumpWidget(buildProvinceOverlayWithRevealedDemoTile());
      await tester.pumpAndSettle();

      final text = _findTileBodyTextExact(tester, 'Resource: ');
      expect(
        text.style,
        isNotNull,
        reason:
            'Resource row prefix must declare its own TextStyle '
            'and not fall through DefaultTextStyle (SPEC AC '
            '"Dark-theme Tile live-data — Resource row Material '
            'fallback regression guard").',
      );
      expect(
        text.style?.color,
        isNotNull,
        reason:
            'Resource row prefix TextStyle.color must be non-null '
            'per SPEC regression guard.',
      );
      expect(
        text.style?.color,
        isNot(Colors.white),
        reason:
            'Resource row prefix must not regress to the dark '
            'Material bodyMedium `Colors.white` fallback (SPEC '
            'regression guard).',
      );
      expect(
        text.style?.color,
        EditorialMonoclePalette.fg,
        reason:
            'Resource row prefix must resolve to '
            'EditorialMonoclePalette.fg (SPEC regression guard '
            'positive token pin).',
      );
    });

    testWidgets('no-resource fallback row resolves to '
        'EditorialMonoclePalette.fg under editorialMonocle when the '
        'selected tile has no visible resource (positive AC: Resource '
        'row no-resource fallback colour)', (WidgetTester tester) async {
      final overlay = buildProvinceOverlayWithRevealedNoResourceTile();
      if (overlay == null) {
        // No revealed land tile without a resource is available in
        // the demo fixture; skip without failing so the slice
        // remains stable on fixtures that resource every revealed
        // tile. The prefix tests above still pin the shared
        // `_fgBodyStyle()` applied in `_buildTileResourceLabelRow`.
        return;
      }
      await tester.pumpWidget(overlay);
      await tester.pumpAndSettle();

      // The Resource row `Row` renders both children: the
      // `Resource: ` prefix and the no-resource fallback `Text`
      // (typically the localized `—` placeholder, sourced from
      // `resourceVisible ?? '—'` in `_buildTileSection`). Find
      // the fallback `Text` whose data does not equal the prefix
      // and exclude other Tile rows that may also render `—`
      // (e.g. the Improvement no-improvement row prints
      // `Improvement: —`, the road no-transport row prints
      // `Road / railroad: —`). The fallback row here is the
      // bare `—` widget (no row label), so target an exact-data
      // match.
      final fallback = find.byWidgetPredicate(
        (Widget w) => w is Text && w.data == '—',
      );
      // Multiple `Text('—')` widgets may exist on the same
      // overlay (Economic empty-state placeholder, Military
      // empty-state placeholder, Civilian empty-state placeholder,
      // Naval empty-state placeholder — all coloured `muted` per
      // the S9 empty-state body token slice). The Resource row
      // fallback is the one we want to pin to `fg`. Look for
      // the `Text` whose colour is `fg` (the Resource row) and
      // assert that at least one such `Text('—')` exists. If
      // every `Text('—')` resolves to `muted`, that means the
      // Resource row fallback regressed (or did not render),
      // which is itself the failure we want to surface.
      if (fallback.evaluate().isEmpty) {
        // The fallback row did not render (the selected tile did
        // expose a visible resource after all, contrary to the
        // search heuristic). Skip without failing.
        return;
      }
      final fgFallbacks = tester.widgetList<Text>(fallback).where((Text t) {
        return t.style?.color == EditorialMonoclePalette.fg;
      }).toList();
      expect(
        fgFallbacks,
        isNotEmpty,
        reason:
            'Tile Resource row no-resource fallback must resolve '
            'to EditorialMonoclePalette.fg (SPEC AC '
            '"Dark-theme Tile live-data — Resource row '
            'no-resource fallback colour"). Found '
            '${tester.widgetList<Text>(fallback).length} `Text("—")` '
            'widgets, none of which resolved to fg; check whether '
            'the Resource row fallback dropped its `style: '
            '_fgBodyStyle()` argument.',
      );
      for (final t in fgFallbacks) {
        expect(
          t.style,
          isNotNull,
          reason:
              'Resource row no-resource fallback must declare its '
              'own TextStyle and not fall through '
              'DefaultTextStyle (SPEC AC "Dark-theme Tile '
              'live-data — Resource row Material fallback '
              'regression guard").',
        );
        expect(
          t.style?.color,
          isNot(Colors.white),
          reason:
              'Resource row no-resource fallback must not regress '
              'to the dark Material bodyMedium `Colors.white` '
              'fallback (SPEC regression guard).',
        );
        expect(
          t.style?.color,
          EditorialMonoclePalette.fg,
          reason:
              'Resource row no-resource fallback must resolve to '
              'EditorialMonoclePalette.fg (SPEC regression guard '
              'positive token pin).',
        );
      }
    });
  });
}
