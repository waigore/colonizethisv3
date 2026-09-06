import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();
  test('e2eAdaptivePollRampAfterIdle ramps under 100ms then caps', () {
    expect(e2eAdaptivePollRampAfterIdle(25), 50);
    expect(e2eAdaptivePollRampAfterIdle(75), 100);
    expect(e2eAdaptivePollRampAfterIdle(100), 100);
  });

  testWidgets('e2eOldWorldRegionChipAppearsSelected reads CtChoiceChip', (
    WidgetTester tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(
      buildAppShellMaterialApp(
        applyEditorialTheme: false,
        home: Scaffold(
          body: CtChoiceChip(
            label: Text(l10n.region_oldWorld),
            selected: true,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(e2eOldWorldRegionChipAppearsSelected(l10n), isTrue);
  });

  testWidgets('e2eNewWorldRegionChipAppearsSelected reads keyed subtree', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildAppShellMaterialApp(
        applyEditorialTheme: false,
        home: Scaffold(
          body: KeyedSubtree(
            key: kCtE2ERegionTabNewWorldKey,
            child: CtChoiceChip(
              label: const Text('New World'),
              selected: true,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(e2eNewWorldRegionChipAppearsSelected(), isTrue);
  });

  testWidgets('e2eCloseBottomSheet no-ops when no bottom sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildAppShellMaterialApp(applyEditorialTheme: false, home: SizedBox()),
    );
    await e2eCloseBottomSheet(tester);
  });

  testWidgets('e2eDismissTransientUi no-ops on empty scaffold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildAppShellMaterialApp(applyEditorialTheme: false, home: SizedBox()),
    );
    await e2eDismissTransientUi(tester);
  });

  testWidgets('e2eOpenPanelFromMarker short-circuits when panel already open', (
    WidgetTester tester,
  ) async {
    const panelKey = Key('e2e_smoke_panel_root');
    await tester.pumpWidget(
      buildAppShellMaterialApp(
        applyEditorialTheme: false,
        home: Scaffold(
          body: KeyedSubtree(key: panelKey, child: SizedBox()),
        ),
      ),
    );
    final sw = Stopwatch()..start();
    await e2eOpenPanelFromMarker(
      tester,
      markerButton: find.byKey(kCtE2EOpenFirstCivilianMarkerPanelKey),
      panelRoot: find.byKey(panelKey),
    );
    expect(sw.elapsed < const Duration(milliseconds: 200), isTrue);
  });

  testWidgets(
    'e2eGameStartIntroBlocksUi is true on first frame while intro Yarn loads',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShellMaterialApp(
          applyEditorialTheme: false,
          home: GameStartIntroOverlay(
            onDismissed: () {},
            child: const SizedBox(key: Key('map_child')),
          ),
        ),
      );
      expect(e2eGameStartIntroBlocksUi(tester), isTrue);
    },
  );

  testWidgets(
    'e2eGameStartIntroBlocksUi is true while intro spinner is visible',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShellMaterialApp(
          applyEditorialTheme: false,
          home: GameStartIntroLoadingIndicator(),
        ),
      );
      expect(e2eGameStartIntroBlocksUi(tester), isTrue);
    },
  );

  testWidgets('e2eReadNextTurnButtonLabel reads keyed next-turn chip text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildAppShellMaterialApp(
        applyEditorialTheme: false,
        home: Scaffold(
          body: Center(
            child: TextButton(
              key: kGameMapNextTurnButtonKey,
              onPressed: () {},
              child: const Text('Next turn (1 / 1492)'),
            ),
          ),
        ),
      ),
    );
    expect(e2eReadNextTurnButtonLabel(tester), 'Next turn (1 / 1492)');
  });
}
