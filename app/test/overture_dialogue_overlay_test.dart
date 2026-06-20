import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';

void main() {
  suppressLogsForTests();

  Game game() {
    return const Game(
      id: 'g1',
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: [
        Player(id: 'gp1', displayName: 'Great Power 1', isHuman: true),
        Player(id: 'gp2', displayName: 'Great Power 2', isHuman: false),
      ],
    );
  }

  Future<void> pumpOverlay(
    WidgetTester tester, {
    required List<OvertureOffer> offers,
    required void Function(List<OvertureDecision>)? onDecisions,
    Size surfaceSize = const Size(900, 900),
  }) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      MaterialApp(
        home: OvertureDialogueOverlay(
          game: game(),
          pendingOvertures: offers,
          skipIntroForTest: true,
          onDecisions: onDecisions ?? (_) {},
          child: const Scaffold(body: Text('child')),
        ),
      ),
    );
    await tester.pump();
  }

  group('OvertureDialogueOverlay', () {
    testWidgets(
      'skipIntroForTest: Accept first + Reject second + Submit yields decisions in order (#2867 R23 / AC4)',
      (WidgetTester tester) async {
        final offers = <OvertureOffer>[
          const OvertureOffer(
            offererGpId: 'gp2',
            targetFactionId: 'gp1',
            stage: OvertureStage.tradeConsulate,
          ),
          const OvertureOffer(
            offererGpId: 'gp2',
            targetFactionId: 'gp1',
            stage: OvertureStage.embassy,
          ),
        ];
        List<OvertureDecision>? submitted;

        await pumpOverlay(
          tester,
          offers: offers,
          onDecisions: (d) => submitted = List.of(d),
        );

        expect(find.text('Diplomatic overtures'), findsOneWidget);
        // Offerer name renders in its own --accent Text per #2867 R22.
        expect(find.text('Great Power 2'), findsNWidgets(2));
        // Stage labels render in their own --muted Text per #2867 R22.
        expect(find.text('trade consulate'), findsOneWidget);
        expect(find.text('embassy'), findsOneWidget);
        // Separator between offerer and stage is its own --muted Text.
        expect(find.text(': '), findsNWidgets(2));

        // Every row starts undecided per #2867 R23 / AC4, so Submit is
        // disabled and tapping it must be a no-op. `warnIfMissed: false`
        // because the disabled button intentionally ignores hit-tests.
        await tester.tap(find.text('Submit'), warnIfMissed: false);
        await tester.pump();
        expect(submitted, isNull);

        await tester.tap(find.text('Accept').first);
        await tester.pump();
        await tester.tap(find.text('Reject').last);
        await tester.pump();

        await tester.tap(find.text('Submit'));
        await tester.pump();

        expect(submitted, isNotNull);
        expect(submitted, hasLength(2));
        expect(submitted![0].accepted, isTrue);
        expect(submitted![1].accepted, isFalse);
        expect(submitted![0].stage, OvertureStage.tradeConsulate);
        expect(submitted![1].stage, OvertureStage.embassy);
      },
    );

    testWidgets(
      'phase 2 Submit is disabled until every row has a non-null decision '
      '(#2867 R23 / AC4 — positive enable transition)',
      (WidgetTester tester) async {
        final offers = <OvertureOffer>[
          const OvertureOffer(
            offererGpId: 'gp2',
            targetFactionId: 'gp1',
            stage: OvertureStage.tradeConsulate,
          ),
          const OvertureOffer(
            offererGpId: 'gp2',
            targetFactionId: 'gp1',
            stage: OvertureStage.embassy,
          ),
        ];

        await pumpOverlay(tester, offers: offers, onDecisions: null);

        final Finder submitFinder = find.byKey(
          const ValueKey<String>('overtureSubmitButton'),
        );
        expect(submitFinder, findsOneWidget);

        CtNinePatchButton submitButton() =>
            tester.widget<CtNinePatchButton>(submitFinder);

        expect(
          submitButton().enabled,
          isFalse,
          reason:
              'Submit must start disabled when every overture row defaults '
              'to undecided (#2867 R23).',
        );

        await tester.tap(find.text('Accept').first);
        await tester.pump();
        expect(
          submitButton().enabled,
          isFalse,
          reason:
              'Submit must remain disabled when only the first row has been '
              'decided (#2867 R23 negative case).',
        );

        await tester.tap(find.text('Reject').last);
        await tester.pump();
        expect(
          submitButton().enabled,
          isTrue,
          reason:
              'Submit must enable once every overture row has a non-null '
              'decision (#2867 R23 positive case).',
        );
      },
    );

    testWidgets(
      'phase 2 Submit disabled while only the second row is decided '
      '(#2867 R23 / AC4 — negative case)',
      (WidgetTester tester) async {
        final offers = <OvertureOffer>[
          const OvertureOffer(
            offererGpId: 'gp2',
            targetFactionId: 'gp1',
            stage: OvertureStage.tradeConsulate,
          ),
          const OvertureOffer(
            offererGpId: 'gp2',
            targetFactionId: 'gp1',
            stage: OvertureStage.embassy,
          ),
        ];
        List<OvertureDecision>? submitted;

        await pumpOverlay(
          tester,
          offers: offers,
          onDecisions: (d) => submitted = List.of(d),
        );

        await tester.tap(find.text('Reject').last);
        await tester.pump();

        final Finder submitFinder = find.byKey(
          const ValueKey<String>('overtureSubmitButton'),
        );
        final CtNinePatchButton submitButton = tester
            .widget<CtNinePatchButton>(submitFinder);
        expect(submitButton.enabled, isFalse);

        // `warnIfMissed: false` because the disabled button intentionally
        // ignores hit-tests (per CtNinePatchButton § Disabled).
        await tester.tap(find.text('Submit'), warnIfMissed: false);
        await tester.pump();
        expect(
          submitted,
          isNull,
          reason:
              'Tapping the disabled Submit must not invoke onDecisions '
              'while any row is still undecided (#2867 R23).',
        );
      },
    );

    testWidgets(
      'phase 2 title uses --accent color and 0.05em letter-spacing (#2867 R2/R21)',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: null,
        );

        final Finder titleFinder = find.byKey(
          const ValueKey<String>('overtureTitle'),
        );
        expect(titleFinder, findsOneWidget);
        final Text titleText = tester.widget<Text>(titleFinder);
        expect(titleText.data, 'Diplomatic overtures');
        expect(titleText.style?.color, EditorialMonoclePalette.accent);
        final double? fontSize = titleText.style?.fontSize;
        expect(fontSize, isNotNull);
        expect(
          titleText.style?.letterSpacing,
          closeTo(fontSize! * 0.05, 0.0001),
        );
      },
    );

    testWidgets(
      'phase 2 renders CtBrassDivider between title and intro (#2867 R21)',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: null,
        );

        final Finder dividerFinder = find.byKey(
          const ValueKey<String>('overtureBrassDivider'),
        );
        expect(dividerFinder, findsOneWidget);
        expect(
          dividerFinder.evaluate().single.widget,
          isA<CtBrassDivider>(),
        );
      },
    );

    testWidgets(
      'phase 2 intro is rendered in --muted italic body style (#2867 R5/R21)',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: null,
        );

        final Finder introFinder = find.byKey(
          const ValueKey<String>('overtureIntro'),
        );
        expect(introFinder, findsOneWidget);
        final Text intro = tester.widget<Text>(introFinder);
        expect(intro.style?.color, EditorialMonoclePalette.muted);
        expect(intro.style?.fontStyle, FontStyle.italic);
      },
    );

    testWidgets(
      'offer row paints offerer in --accent and stage in --muted (#2867 R22)',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: null,
        );

        final Finder offererFinder = find.byKey(
          const ValueKey<String>('overtureOfferOfferer'),
        );
        expect(offererFinder, findsOneWidget);
        final Text offererText = tester.widget<Text>(offererFinder);
        expect(offererText.data, 'Great Power 2');
        expect(offererText.style?.color, EditorialMonoclePalette.accent);

        final Finder stageFinder = find.byKey(
          const ValueKey<String>('overtureOfferStage'),
        );
        expect(stageFinder, findsOneWidget);
        final Text stageText = tester.widget<Text>(stageFinder);
        expect(stageText.data, 'trade consulate');
        expect(stageText.style?.color, EditorialMonoclePalette.muted);

        final Finder separatorFinder = find.byKey(
          const ValueKey<String>('overtureOfferSeparator'),
        );
        expect(separatorFinder, findsOneWidget);
        final Text separator = tester.widget<Text>(separatorFinder);
        expect(separator.data, ': ');
        expect(separator.style?.color, EditorialMonoclePalette.muted);
      },
    );

    testWidgets(
      'phase 2 chrome contains no Material AlertDialog/ListTile/Card chrome (#2867 R1)',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: null,
        );

        final Finder overlay = find.byType(OvertureDialogueOverlay);
        expect(
          find.descendant(of: overlay, matching: find.byType(AlertDialog)),
          findsNothing,
        );
        expect(
          find.descendant(of: overlay, matching: find.byType(ListTile)),
          findsNothing,
        );
        expect(
          find.descendant(of: overlay, matching: find.byType(Card)),
          findsNothing,
        );
      },
    );

    testWidgets(
      'phase 2 scrim resolves to EditorialMonoclePalette.dialogScrim '
      '(#2867 R1; mirrors intervention overlay S9)',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: null,
        );

        final Finder shellFinder = find.byType(
          CtDialogShell,
        );
        expect(shellFinder, findsOneWidget);
        final Material scrim = tester.widget<Material>(
          find
              .ancestor(of: shellFinder, matching: find.byType(Material))
              .first,
        );
        expect(scrim.color, EditorialMonoclePalette.dialogScrim);
        expect(scrim.color, isNot(Colors.black54));
      },
    );

    testWidgets(
      'no Material descendant uses the legacy Colors.black54 scrim '
      '(#2867 R1 negative regression guard)',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: null,
        );

        final Finder overlay = find.byType(OvertureDialogueOverlay);
        for (final Element element in find
            .descendant(of: overlay, matching: find.byType(Material))
            .evaluate()) {
          final Material material = element.widget as Material;
          expect(
            material.color,
            isNot(Colors.black54),
            reason:
                'Legacy Colors.black54 scrim must not leak into the overture '
                'overlay; use EditorialMonoclePalette.dialogScrim per '
                '#2867 R1 / SPEC/ui/pixel-art-ui-catalog.md § Dialog scrim.',
          );
        }
      },
    );
  });

  group('OvertureDialogueOverlay R22 CtToggleSwitch (#2867 R22)', () {
    Finder acceptToggleAt(int rowIndex) => find.byKey(
      ValueKey<String>('overtureAcceptToggle_$rowIndex'),
    );

    Finder rejectToggleAt(int rowIndex) => find.byKey(
      ValueKey<String>('overtureRejectToggle_$rowIndex'),
    );

    testWidgets(
      'phase 2 renders Accept + Reject CtToggleSwitch widgets per row with '
      'the canonical --success / --danger glow tokens',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.embassy,
            ),
          ],
          onDecisions: null,
        );

        for (var i = 0; i < 2; i++) {
          expect(acceptToggleAt(i), findsOneWidget);
          expect(rejectToggleAt(i), findsOneWidget);

          final CtToggleSwitch accept = tester.widget<CtToggleSwitch>(
            acceptToggleAt(i),
          );
          expect(accept.value, isFalse);
          expect(accept.onGlowColor, EditorialMonoclePalette.success);

          final CtToggleSwitch reject = tester.widget<CtToggleSwitch>(
            rejectToggleAt(i),
          );
          expect(reject.value, isFalse);
          expect(reject.onGlowColor, EditorialMonoclePalette.danger);
        }
      },
    );

    testWidgets(
      'no CtNinePatchButton descendants paint the Accept / Reject affordances '
      'inside the per-offer row (negative regression guard for R22)',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: null,
        );

        // Submit is the only CtNinePatchButton expected in phase 2 (Accept /
        // Reject are now CtToggleSwitch per #2867 R22).
        final Iterable<CtNinePatchButton> buttons = tester
            .widgetList<CtNinePatchButton>(find.byType(CtNinePatchButton));
        expect(buttons, hasLength(1));
        final CtNinePatchButton only = buttons.single;
        expect(only.key, const ValueKey<String>('overtureSubmitButton'));
      },
    );

    testWidgets(
      'tapping the Accept toggle commits decision=true and turns Reject off',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: null,
        );

        await tester.tap(acceptToggleAt(0));
        await tester.pump();

        final CtToggleSwitch accept = tester.widget<CtToggleSwitch>(
          acceptToggleAt(0),
        );
        expect(accept.value, isTrue);
        final CtToggleSwitch reject = tester.widget<CtToggleSwitch>(
          rejectToggleAt(0),
        );
        expect(reject.value, isFalse);
      },
    );

    testWidgets(
      'tapping the Reject toggle commits decision=false and turns Accept off',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: null,
        );

        await tester.tap(rejectToggleAt(0));
        await tester.pump();

        final CtToggleSwitch reject = tester.widget<CtToggleSwitch>(
          rejectToggleAt(0),
        );
        expect(reject.value, isTrue);
        final CtToggleSwitch accept = tester.widget<CtToggleSwitch>(
          acceptToggleAt(0),
        );
        expect(accept.value, isFalse);
      },
    );

    testWidgets(
      'tapping Accept then Reject swaps the committed decision to false',
      (WidgetTester tester) async {
        List<OvertureDecision>? submitted;
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: (d) => submitted = List.of(d),
        );

        await tester.tap(acceptToggleAt(0));
        await tester.pump();
        await tester.tap(rejectToggleAt(0));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey<String>('overtureSubmitButton')));
        await tester.pump();

        expect(submitted, isNotNull);
        expect(submitted, hasLength(1));
        expect(submitted!.first.accepted, isFalse);
      },
    );

    testWidgets(
      'tapping a currently-on toggle reverts the row to undecided and '
      're-engages the #2867 R23 Submit gate (positive R22 + R23 interaction)',
      (WidgetTester tester) async {
        await pumpOverlay(
          tester,
          offers: const [
            OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'gp1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
          onDecisions: null,
        );

        final Finder submitFinder = find.byKey(
          const ValueKey<String>('overtureSubmitButton'),
        );

        await tester.tap(acceptToggleAt(0));
        await tester.pump();
        expect(
          tester.widget<CtNinePatchButton>(submitFinder).enabled,
          isTrue,
          reason:
              'Single-row overlay enables Submit immediately once a row is '
              'decided (#2867 R23 positive case).',
        );

        // Tap the Accept toggle again while currently on -> reverts to
        // undecided and Submit must disable again.
        await tester.tap(acceptToggleAt(0));
        await tester.pump();
        final CtToggleSwitch accept = tester.widget<CtToggleSwitch>(
          acceptToggleAt(0),
        );
        final CtToggleSwitch reject = tester.widget<CtToggleSwitch>(
          rejectToggleAt(0),
        );
        expect(accept.value, isFalse);
        expect(reject.value, isFalse);
        expect(
          tester.widget<CtNinePatchButton>(submitFinder).enabled,
          isFalse,
          reason:
              'Reverting a row to undecided must re-engage the R23 Submit '
              'gate so the user cannot submit unintentional decisions.',
        );
      },
    );
  });
}
