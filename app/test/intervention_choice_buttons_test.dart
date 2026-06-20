// Pin the differentiated choice-button styling for the intervention
// overlay's per-prompt picker (#2867 R26b).
//
//   - SPEC/ui/screens/pending-intervention-overlay.md § Choice-button
//     styling: **Intervene** uses default / primary `CtNinePatchButton`
//     chrome; **Do naught** and **Diplomatic protest** use
//     `mutedVariant: true`; none of the three uses `dangerVariant`.
//   - SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component catalog
//     (CtNinePatchButton) — Muted variant rules.
//
// `InterventionChoiceButtons` is the public testable extraction of the
// three picker buttons from `InterventionDialogueOverlay` so this test
// can pin styling without driving the parent through its async Yarn
// flow into `_awaitingChoice`.
//
// The deeper colour / hover / corner-bracket contract for the muted
// variant itself is owned by `widgets/ct_nine_patch_button_dark_test
// .dart` so this file deliberately stays focused on the per-button
// variant flag wiring (the contract that maps from the overlay spec to
// the catalog).
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show InterventionChoice;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpPicker(
  WidgetTester tester, {
  required void Function(InterventionChoice) onPick,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: InterventionChoiceButtons(onPick: onPick),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

CtNinePatchButton _findButton(WidgetTester tester, String key) {
  final Finder finder = find.byKey(ValueKey<String>(key));
  expect(finder, findsOneWidget);
  return tester.widget<CtNinePatchButton>(finder);
}

void main() {
  suppressLogsForTests();

  group('InterventionChoiceButtons styling contract (#2867 R26b)', () {
    testWidgets(
      'Intervene button uses default / primary CtNinePatchButton chrome '
      '(positive — #2867 R26b: dangerVariant: false, mutedVariant: false)',
      (WidgetTester tester) async {
        await _pumpPicker(tester, onPick: (_) {});

        final CtNinePatchButton intervene = _findButton(
          tester,
          kInterventionInterveneButtonKey,
        );
        expect(
          intervene.dangerVariant,
          isFalse,
          reason:
              'Intervene must not adopt the destructive `dangerVariant` '
              'token — that token is reserved for declare-war / exit flows.',
        );
        expect(
          intervene.mutedVariant,
          isFalse,
          reason:
              'Intervene reads as the primary action in the picker and '
              'must render with the default CtNinePatchButton chrome.',
        );
      },
    );

    testWidgets(
      'Do naught button uses mutedVariant secondary chrome '
      '(positive — #2867 R26b)',
      (WidgetTester tester) async {
        await _pumpPicker(tester, onPick: (_) {});

        final CtNinePatchButton doNothing = _findButton(
          tester,
          kInterventionDoNothingButtonKey,
        );
        expect(
          doNothing.mutedVariant,
          isTrue,
          reason:
              'Do naught is a secondary affordance and must render with '
              'CtNinePatchButton.mutedVariant: true so the player can '
              'distinguish it from the primary Intervene action.',
        );
        expect(
          doNothing.dangerVariant,
          isFalse,
          reason:
              'Do naught is non-destructive — the danger token must not '
              'apply.',
        );
      },
    );

    testWidgets(
      'Diplomatic protest button uses mutedVariant secondary chrome '
      '(positive — #2867 R26b)',
      (WidgetTester tester) async {
        await _pumpPicker(tester, onPick: (_) {});

        final CtNinePatchButton protest = _findButton(
          tester,
          kInterventionProtestButtonKey,
        );
        expect(
          protest.mutedVariant,
          isTrue,
          reason:
              'Diplomatic protest is a secondary affordance and must '
              'render with CtNinePatchButton.mutedVariant: true.',
        );
        expect(
          protest.dangerVariant,
          isFalse,
          reason:
              'Diplomatic protest is not destructive — the danger token '
              'must not apply.',
        );
      },
    );

    testWidgets(
      'no choice button in the picker uses dangerVariant '
      '(negative — #2867 R26b destructive-token guard)',
      (WidgetTester tester) async {
        await _pumpPicker(tester, onPick: (_) {});

        final Iterable<Element> allButtons = find
            .byType(CtNinePatchButton)
            .evaluate();
        expect(
          allButtons,
          hasLength(3),
          reason:
              'The picker must render exactly three CtNinePatchButton '
              'instances (Intervene + Do naught + Diplomatic protest).',
        );
        for (final Element element in allButtons) {
          final CtNinePatchButton button =
              element.widget as CtNinePatchButton;
          expect(
            button.dangerVariant,
            isFalse,
            reason:
                'No intervention choice is destructive; the dangerVariant '
                'token is reserved for declare-war / exit flows per the '
                'catalog and overlay specs.',
          );
        }
      },
    );

    testWidgets(
      'exactly one button is primary and exactly two are muted '
      '(positive — picker hierarchy contract: one primary, two secondary)',
      (WidgetTester tester) async {
        await _pumpPicker(tester, onPick: (_) {});

        final List<CtNinePatchButton> buttons = find
            .byType(CtNinePatchButton)
            .evaluate()
            .map((Element e) => e.widget as CtNinePatchButton)
            .toList(growable: false);

        final int primaryCount = buttons
            .where((CtNinePatchButton b) => !b.mutedVariant && !b.dangerVariant)
            .length;
        final int mutedCount = buttons
            .where((CtNinePatchButton b) => b.mutedVariant)
            .length;
        expect(
          primaryCount,
          1,
          reason:
              'The picker hierarchy must keep exactly one primary action '
              '(Intervene) so the affordance reads at a glance.',
        );
        expect(
          mutedCount,
          2,
          reason:
              'Do naught + Diplomatic protest are both secondary; if more '
              'than two muted buttons render, the primary affordance is '
              'no longer unique.',
        );
      },
    );

    testWidgets(
      'tapping each button forwards the matching InterventionChoice '
      'to the onPick callback (positive — wiring regression guard)',
      (WidgetTester tester) async {
        InterventionChoice? captured;
        await _pumpPicker(tester, onPick: (c) => captured = c);

        await tester.tap(
          find.byKey(const ValueKey<String>(kInterventionInterveneButtonKey)),
        );
        await tester.pump();
        expect(captured, InterventionChoice.intervene);

        await tester.tap(
          find.byKey(const ValueKey<String>(kInterventionDoNothingButtonKey)),
        );
        await tester.pump();
        expect(captured, InterventionChoice.doNothing);

        await tester.tap(
          find.byKey(const ValueKey<String>(kInterventionProtestButtonKey)),
        );
        await tester.pump();
        expect(captured, InterventionChoice.protest);
      },
    );
  });
}
