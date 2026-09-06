import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Widget gameMapCornerControlsWrap({required Widget child}) {
  return buildAppShell(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: Scaffold(
      body: Align(alignment: Alignment.bottomLeft, child: child),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('GameMapCornerControls disabled + tooltip chrome (Refs #2861 S4)', () {
    testWidgets(
      'positive: home-to-capital disabled wraps the surface in IgnorePointer + Opacity(0.4)',
      (WidgetTester tester) async {
        var homeCalls = 0;
        await tester.pumpWidget(
          gameMapCornerControlsWrap(
            child: GameMapCornerControls(
              onCycleBaseLayerDisplayMode: () {},
              onCenterOnHomeCapital: () => homeCalls++,
              onOpenMapDisplayOptions: () {},
              homeToCapitalEnabled: false,
            ),
          ),
        );
        await tester.pump();

        final homeFinder = find.byKey(kHomeToCapitalButtonKey);
        expect(homeFinder, findsOneWidget);

        final Opacity opacity = tester.widget(
          find.ancestor(of: homeFinder, matching: find.byType(Opacity)).first,
        );
        expect(opacity.opacity, 0.4);
        expect(
          tester
              .widgetList<IgnorePointer>(
                find.ancestor(
                  of: homeFinder,
                  matching: find.byType(IgnorePointer),
                ),
              )
              .any((ip) => ip.ignoring),
          isTrue,
        );

        await tester.tap(homeFinder, warnIfMissed: false);
        await tester.pump();
        expect(homeCalls, 0);

        final AnimatedContainer container = tester.widget(
          find.descendant(
            of: homeFinder,
            matching: find.byType(AnimatedContainer),
          ),
        );
        final border = (container.decoration as BoxDecoration).border as Border;
        expect(border.top.color, EditorialMonoclePalette.border);
        expect(
          find.descendant(of: homeFinder, matching: find.byType(ColorFiltered)),
          findsNothing,
        );
      },
    );

    testWidgets(
      'cycle button tooltip names the current map marks combination (Refs #4388)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          gameMapCornerControlsWrap(
            child: GameMapCornerControls(
              onCycleBaseLayerDisplayMode: () {},
              onCenterOnHomeCapital: () {},
              onOpenMapDisplayOptions: () {},
              mapBaseLayerFlags: MapBaseLayerFlags.resourcesOnly,
            ),
          ),
        );
        expect(find.byTooltip('Map marks: resources'), findsOneWidget);
      },
    );
  });
}
