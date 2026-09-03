// Pin the 320 dp minimum-viewport contract for `DiplomacyScreen`
// (GAME30001) — default (non-observe) path.
// Global-observe pins live in
// `diplomacy_screen_320dp_min_viewport_observe_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7; `SPEC/ui/diplomacy-panel.md`.
// Refs #2870 S10.

import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_screen.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/panels/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_screen_320dp_min_viewport_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    game = buildDiplomacyScreenTestGame();
    humanPlayerId = game.players
        .firstWhere((p) => p.isHuman, orElse: () => game.players.first)
        .id;
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — DiplomacyScreen (default) @ '
      '320 dp (Refs #2870 S10)', () {
    testWidgets(
      'AC (positive) DiplomacyScreen default @ 320×640: no RenderFlex '
      'overflow exception, dark CtTopBar (title `Diplomacy`, back '
      'label `Map`) + DiplomacyPanel body (`Great Powers` heading) '
      'both render',
      (WidgetTester tester) async {
        await pumpDiplomacyScreen320(
          tester,
          size: kDiplomacyScreen320MinViewport,
          game: game,
          humanPlayerId: humanPlayerId,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: DiplomacyScreen must '
              'not emit a RenderFlex overflow exception at '
              'kMinViewportWidth (320 dp). The dark CtTopBar (36 dp '
              'tall — back chevron + `Map` label + 18 × 18 px '
              'diplomacy icon + `Diplomacy` title) above the '
              'DiplomacyPanel body must lay out within the 320 dp '
              'column per SPEC/ui/diplomacy-panel.md § Top bar and '
              '§ Layout / wireframe.',
        );

        final topBarFinder = find.byKey(DiplomacyScreen.topBarKey);
        expect(topBarFinder, findsOneWidget);
        final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
        expect(topBar.title, DiplomacyScreen.topBarTitle);
        expect(topBar.backButtonLabel, DiplomacyScreen.topBarBackLabel);

        expect(
          find.descendant(
            of: topBarFinder,
            matching: find.byType(CtBackButton),
          ),
          findsOneWidget,
          reason:
              'The CtTopBar back chevron must remain reachable at '
              '320 dp so the user can navigate back to the map '
              '(SPEC/ui/diplomacy-panel.md § Top bar — back affordance '
              'reads "← Map").',
        );

        expect(
          find.byType(DiplomacyPanel),
          findsOneWidget,
          reason:
              'Default (non-observe) path must mount the '
              '`DiplomacyPanel` body at 320 dp. '
              'SPEC/ui/diplomacy-panel.md § Layout / wireframe.',
        );
        // The DiplomacyPanel renders a `Great Powers` faction-section
        // heading when at least one GP exists in the game (the
        // debug-init fixture seeds six GPs). Pinning the heading
        // proves the panel actually laid out a non-empty body inside
        // the 320 dp column rather than rendering a placeholder.
        expect(
          find.text('Great Powers'),
          findsOneWidget,
          reason:
              'Default path must render the `Great Powers` faction-'
              'section heading inside the DiplomacyPanel body at '
              '320 dp (SPEC/ui/diplomacy-panel.md § Layout / '
              'wireframe — Faction sections).',
        );
        expect(
          find.byType(ObserveModeNotDefinedPanel),
          findsNothing,
          reason:
              'Default path must NOT render the observe sentinel — '
              'that is the global-observe variant covered by the '
              'second group below.',
        );
      },
    );

    testWidgets('Negative control: DiplomacyScreen default @ 1024×768 also '
        'pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpDiplomacyScreen320(
        tester,
        size: kDiplomacyScreen320WideViewport,
        game: game,
        humanPlayerId: humanPlayerId,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(DiplomacyScreen.topBarKey), findsOneWidget);
      expect(find.byType(DiplomacyPanel), findsOneWidget);
      expect(find.text('Great Powers'), findsOneWidget);
    });
  });
}
