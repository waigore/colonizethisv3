import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/call_to_arms_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dark editorial-monocle chrome tests for [CallToArmsDialogueOverlay] per
/// `SPEC/ui/call-to-arms-dialogue-overlay.md` § Editorial-monocle chrome
/// (issue #2867 R24): title accent + 0.05em letter-spacing, intro
/// muted+italic, single brass divider between intro and call list, and
/// canonical `EditorialMonoclePalette.dialogScrim` instead of `Colors.black54`.
void main() {
  suppressLogsForTests();

  Game twoPlayerGame() {
    return const Game(
      id: 'cta_chrome',
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: [
        Player(id: 'gp_player', displayName: 'Player', isHuman: true),
        Player(id: 'gp_portugal', displayName: 'Portugal', isHuman: false),
        Player(id: 'gp_spain', displayName: 'Spain', isHuman: false),
      ],
    );
  }

  Future<void> pumpOverlay(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: Scaffold(
          body: CallToArmsDialogueOverlay(
            game: twoPlayerGame(),
            pending: const [
              CallToArmsPending(
                allyGpId: 'gp_player',
                defenderGpId: 'gp_portugal',
                aggressorGpId: 'gp_spain',
              ),
            ],
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('CallToArmsDialogueOverlay dark chrome (Refs #2867 R24)', () {
    testWidgets('title uses editorial-monocle accent + 0.05em letter-spacing',
        (WidgetTester tester) async {
      await pumpOverlay(tester);

      final BuildContext context = tester.element(find.byType(CtBrassDivider));
      final ThemeData theme = Theme.of(context);
      final double resolvedFontSize =
          theme.textTheme.titleMedium?.fontSize ?? 16.0;

      final Text titleText =
          tester.widget<Text>(find.text('Call to arms'));
      expect(titleText.style?.color, EditorialMonoclePalette.accent);
      expect(titleText.style?.fontWeight, FontWeight.w600);
      expect(
        titleText.style?.letterSpacing,
        closeTo(0.05 * resolvedFontSize, 1e-9),
      );
    });

    testWidgets('intro line uses muted color and italic style',
        (WidgetTester tester) async {
      await pumpOverlay(tester);

      final Text introText = tester.widget<Text>(find.text(
        'An allied power is at war. Join their war or refuse '
        '(alliance ends, relations worsen).',
      ));
      expect(introText.style?.color, EditorialMonoclePalette.muted);
      expect(introText.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('one CtBrassDivider sits between intro and call list',
        (WidgetTester tester) async {
      await pumpOverlay(tester);

      expect(find.byType(CtBrassDivider), findsOneWidget);

      final Finder introFinder = find.text(
        'An allied power is at war. Join their war or refuse '
        '(alliance ends, relations worsen).',
      );
      final Finder listFinder = find.byType(ListView);
      final Finder dividerFinder = find.byType(CtBrassDivider);

      final Offset introCenter = tester.getCenter(introFinder);
      final Offset dividerCenter = tester.getCenter(dividerFinder);
      final Offset listCenter = tester.getCenter(listFinder);

      expect(
        dividerCenter.dy > introCenter.dy,
        isTrue,
        reason: 'CtBrassDivider must paint below the intro line',
      );
      expect(
        listCenter.dy > dividerCenter.dy,
        isTrue,
        reason: 'Call-row list must paint below the CtBrassDivider',
      );
    });

    testWidgets('scrim Material uses EditorialMonoclePalette.dialogScrim',
        (WidgetTester tester) async {
      await pumpOverlay(tester);

      final Iterable<Material> scrimMaterials = tester
          .widgetList<Material>(find.byType(Material))
          .where(
            (m) => m.color == EditorialMonoclePalette.dialogScrim,
          );
      expect(
        scrimMaterials,
        isNotEmpty,
        reason:
            'Overlay scrim Material must use the canonical dialogScrim token, '
            'not Colors.black54.',
      );

      final Iterable<Material> blackScrim = tester
          .widgetList<Material>(find.byType(Material))
          .where((m) => m.color == Colors.black54);
      expect(
        blackScrim,
        isEmpty,
        reason: 'No Material in the overlay should still use Colors.black54.',
      );
    });

    testWidgets(
      'Submit stays disabled until every pending call has a non-null '
      'decision (#2867 R25 / AC5)',
      (WidgetTester tester) async {
        await pumpOverlay(tester);

        final Finder submitFinder = find.byKey(
          const ValueKey<String>('callToArmsSubmitButton'),
        );
        expect(submitFinder, findsOneWidget);

        CtNinePatchButton submitButton() =>
            tester.widget<CtNinePatchButton>(submitFinder);

        expect(
          submitButton().enabled,
          isFalse,
          reason:
              'Submit must start disabled when the row defaults to '
              'undecided (#2867 R25).',
        );

        await tester.tap(find.text('Join'));
        await tester.pump();
        expect(
          submitButton().enabled,
          isTrue,
          reason:
              'Submit must enable as soon as every row has a non-null '
              'decision (#2867 R25 positive case).',
        );
      },
    );
  });

  group('CallToArmsDialogueOverlay R24 CtToggleSwitch (#2867 R24)', () {
    Finder joinToggle(int rowIndex) => find.byKey(
          ValueKey<String>('callToArmsJoinToggle_$rowIndex'),
        );
    Finder refuseToggle(int rowIndex) => find.byKey(
          ValueKey<String>('callToArmsRefuseToggle_$rowIndex'),
        );

    testWidgets(
      'each row exposes Join (--success glow) + Refuse (--danger glow) '
      'CtToggleSwitch controls and an accent faction-name label',
      (WidgetTester tester) async {
        await pumpOverlay(tester);

        expect(joinToggle(0), findsOneWidget);
        expect(refuseToggle(0), findsOneWidget);

        final CtToggleSwitch join =
            tester.widget<CtToggleSwitch>(joinToggle(0));
        final CtToggleSwitch refuse =
            tester.widget<CtToggleSwitch>(refuseToggle(0));
        expect(join.onGlowColor, EditorialMonoclePalette.success);
        expect(refuse.onGlowColor, EditorialMonoclePalette.danger);

        // The prompt Text.rich must paint the calling faction (defender)
        // name span in --accent (#2867 R24 "faction name in --accent").
        final Text prompt = tester.widget<Text>(
          find.byKey(const ValueKey<String>('callToArmsPrompt')),
        );
        final InlineSpan? span = prompt.textSpan;
        expect(span, isA<TextSpan>());
        final List<InlineSpan> children =
            (span! as TextSpan).children ?? const <InlineSpan>[];
        final Iterable<TextSpan> accentSpans = children
            .whereType<TextSpan>()
            .where((s) => s.text == 'Portugal');
        expect(
          accentSpans,
          isNotEmpty,
          reason: 'Defender name must be its own span in the prompt rich text.',
        );
        expect(accentSpans.first.style?.color, EditorialMonoclePalette.accent);
      },
    );

    testWidgets(
      'tapping an active Join toggle reverts the row to undecided and '
      're-disables Submit (#2867 R24 tristate / R25 gate)',
      (WidgetTester tester) async {
        await pumpOverlay(tester);

        CtNinePatchButton submitButton() => tester.widget<CtNinePatchButton>(
              find.byKey(const ValueKey<String>('callToArmsSubmitButton')),
            );
        CtToggleSwitch joinSwitch() =>
            tester.widget<CtToggleSwitch>(joinToggle(0));

        expect(joinSwitch().value, isFalse);
        expect(submitButton().enabled, isFalse);

        await tester.tap(joinToggle(0));
        await tester.pump();
        expect(joinSwitch().value, isTrue);
        expect(submitButton().enabled, isTrue);

        await tester.tap(joinToggle(0));
        await tester.pump();
        expect(
          joinSwitch().value,
          isFalse,
          reason:
              'Tapping an active toggle must revert the row to undecided '
              '(#2867 R24 tristate).',
        );
        expect(
          submitButton().enabled,
          isFalse,
          reason:
              'Reverting to undecided must re-disable Submit (#2867 R25).',
        );
      },
    );

    testWidgets(
      'Join and Refuse are mutually exclusive within a row',
      (WidgetTester tester) async {
        await pumpOverlay(tester);

        await tester.tap(find.text('Join'));
        await tester.pump();
        expect(tester.widget<CtToggleSwitch>(joinToggle(0)).value, isTrue);
        expect(tester.widget<CtToggleSwitch>(refuseToggle(0)).value, isFalse);

        await tester.tap(find.text('Refuse'));
        await tester.pump();
        expect(tester.widget<CtToggleSwitch>(joinToggle(0)).value, isFalse);
        expect(tester.widget<CtToggleSwitch>(refuseToggle(0)).value, isTrue);
      },
    );
  });
}
