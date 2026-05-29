import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';

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
      'skipIntroForTest: Accept/Reject toggles and Submit yields decisions',
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
  });
}
