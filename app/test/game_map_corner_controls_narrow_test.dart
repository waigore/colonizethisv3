// Pins the narrow-layout sizing contract for GameMapCornerControls
// (Refs #2870 S3). SPEC: SPEC/ui/empire-overview.md § Narrow corner-control
// measurements; SPEC/ui/mobile-adaptation.md § In-game shell.
//
// Pins:
// - 24 × 24 dp tap target per corner button when `narrow: true`.
// - 2 dp horizontal gap between consecutive buttons.
// - 22 × 22 dp icon glyph (unchanged from wide layout).
//
// Negative regression guard: with `narrow: false` (default) the existing
// wide-layout 32 × 32 dp + 3 dp gap contract still holds.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/game_map_corner_controls.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required Widget child}) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: Align(alignment: Alignment.bottomLeft, child: child)),
  );
}

void main() {
  suppressLogsForTests();

  const List<Key> cornerKeys = <Key>[
    kBaseLayerCycleButtonKey,
    kHomeToCapitalButtonKey,
    kMapDisplayOptionsButtonKey,
  ];

  group(
    'GameMapCornerControls narrow layout (Refs #2870 S3)',
    () {
      testWidgets(
        'positive: narrow corner buttons paint a 24 x 24 dp surface',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _wrap(
              child: GameMapCornerControls(
                narrow: true,
                onCycleBaseLayerDisplayMode: () {},
                onCenterOnHomeCapital: () {},
                onOpenMapDisplayOptions: () {},
              ),
            ),
          );
          await tester.pump();

          expect(GameMapCornerControls.narrowButtonSize, 24.0);
          for (final key in cornerKeys) {
            final size = tester.getSize(find.byKey(key));
            expect(
              size.width,
              24.0,
              reason:
                  'Narrow corner button $key must paint a 24 dp wide tap target',
            );
            expect(
              size.height,
              24.0,
              reason:
                  'Narrow corner button $key must paint a 24 dp tall tap target',
            );
          }
        },
      );

      testWidgets(
        'positive: narrow corner row uses a 2 dp horizontal gap between buttons',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _wrap(
              child: GameMapCornerControls(
                narrow: true,
                onCycleBaseLayerDisplayMode: () {},
                onCenterOnHomeCapital: () {},
                onOpenMapDisplayOptions: () {},
              ),
            ),
          );
          await tester.pump();

          expect(GameMapCornerControls.narrowRowGap, 2.0);
          for (var i = 1; i < cornerKeys.length; i++) {
            final aRight = tester.getRect(find.byKey(cornerKeys[i - 1])).right;
            final bLeft = tester.getRect(find.byKey(cornerKeys[i])).left;
            expect(
              bLeft - aRight,
              2.0,
              reason:
                  'Narrow corner button ${cornerKeys[i]} must sit 2 dp right of '
                  '${cornerKeys[i - 1]}',
            );
          }
        },
      );

      testWidgets(
        'positive: narrow corner icon glyph is unchanged at 22 x 22 dp',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _wrap(
              child: GameMapCornerControls(
                narrow: true,
                onCycleBaseLayerDisplayMode: () {},
                onCenterOnHomeCapital: () {},
                onOpenMapDisplayOptions: () {},
              ),
            ),
          );
          await tester.pump();

          expect(GameMapCornerControls.iconSize, 22.0);
          for (final key in cornerKeys) {
            final iconFinder = find.descendant(
              of: find.byKey(key),
              matching: find.byType(StrictAssetIcon),
            );
            expect(iconFinder, findsOneWidget);
            final icon = tester.widget<StrictAssetIcon>(iconFinder);
            expect(
              icon.width,
              22.0,
              reason: 'Narrow corner icon for $key must remain 22 dp wide',
            );
            expect(
              icon.height,
              22.0,
              reason: 'Narrow corner icon for $key must remain 22 dp tall',
            );
          }
        },
      );

      testWidgets(
        'negative: wide corner controls (narrow: false) keep 32 dp + 3 dp gap baseline',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _wrap(
              child: GameMapCornerControls(
                onCycleBaseLayerDisplayMode: () {},
                onCenterOnHomeCapital: () {},
                onOpenMapDisplayOptions: () {},
              ),
            ),
          );
          await tester.pump();

          for (final key in cornerKeys) {
            final size = tester.getSize(find.byKey(key));
            expect(
              size.width,
              GameMapCornerControls.buttonSize,
              reason: 'Wide corner button $key must remain 32 dp wide',
            );
            expect(
              size.height,
              GameMapCornerControls.buttonSize,
              reason: 'Wide corner button $key must remain 32 dp tall',
            );
          }
          for (var i = 1; i < cornerKeys.length; i++) {
            final aRight = tester.getRect(find.byKey(cornerKeys[i - 1])).right;
            final bLeft = tester.getRect(find.byKey(cornerKeys[i])).left;
            expect(
              bLeft - aRight,
              GameMapCornerControls.rowGap,
              reason:
                  'Wide corner button ${cornerKeys[i]} must keep the 3 dp gap',
            );
          }
        },
      );
    },
  );
}
