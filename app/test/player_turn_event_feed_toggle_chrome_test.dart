import 'dart:io' show File;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'player_turn_event_feed_chrome_test_support.dart';

void main() {
  suppressLogsForTests();

  group('PlayerTurnEventsFeedToggleButton chrome', () {
    testWidgets(
      'surface is 28 × 22 dp, bg-deep fill, 1 dp border; glyph is not a Material Icon (M3)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostPlayerTurnFeedToggle(eventCount: 0, showFeed: false),
        );
        await tester.pump();

        final Container surface = playerTurnFeedToggleSurface(tester);
        expect(
          surface.constraints,
          equals(BoxConstraints.tightFor(width: 28, height: 22)),
        );
        final BoxDecoration decoration = surface.decoration as BoxDecoration;
        expect(decoration.color, equals(EditorialMonoclePalette.bgDeep));
        final Border border = decoration.border as Border;
        expect(border.top.width, equals(1));

        expect(
          find.descendant(
            of: find.byKey(kPlayerTurnFeedToggleButtonKey),
            matching: find.byType(Icon),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(kPlayerTurnFeedToggleButtonKey),
            matching: find.byType(NewspaperGlyph),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'closed-state glyph resolves to accentDim; border resolves to --border',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostPlayerTurnFeedToggle(eventCount: 0, showFeed: false),
        );
        await tester.pump();

        final NewspaperGlyph glyph = tester.widget<NewspaperGlyph>(
          find.descendant(
            of: find.byKey(kPlayerTurnFeedToggleButtonKey),
            matching: find.byType(NewspaperGlyph),
          ),
        );
        expect(glyph.size, equals(14));
        expect(glyph.color, equals(EditorialMonoclePalette.accentDim));

        final BoxDecoration decoration =
            playerTurnFeedToggleSurface(tester).decoration as BoxDecoration;
        final Border border = decoration.border as Border;
        expect(border.top.color, equals(EditorialMonoclePalette.border));
      },
    );

    testWidgets(
      'open-state glyph resolves to accent; border resolves to accentDim',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostPlayerTurnFeedToggle(eventCount: 3, showFeed: true),
        );
        await tester.pump();

        final NewspaperGlyph glyph = tester.widget<NewspaperGlyph>(
          find.descendant(
            of: find.byKey(kPlayerTurnFeedToggleButtonKey),
            matching: find.byType(NewspaperGlyph),
          ),
        );
        expect(glyph.color, equals(EditorialMonoclePalette.accent));

        final BoxDecoration decoration =
            playerTurnFeedToggleSurface(tester).decoration as BoxDecoration;
        final Border border = decoration.border as Border;
        expect(border.top.color, equals(EditorialMonoclePalette.accentDim));
      },
    );

    testWidgets(
      'unread badge background resolves to danger token (not redAccent)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostPlayerTurnFeedToggle(eventCount: 5, showFeed: false),
        );
        await tester.pump();

        final Container badge = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('5'),
                matching: find.byType(Container),
              )
              .first,
        );
        final BoxDecoration decoration = badge.decoration as BoxDecoration;
        final Color badgeColor = decoration.color!;
        final Color expected = EditorialMonoclePalette.danger.withValues(
          alpha: PlayerTurnEventsFeedToggleButton.badgeBackgroundAlpha,
        );
        expect(badgeColor, equals(expected));
        expect(badgeColor, isNot(equals(Colors.redAccent)));
      },
    );

    testWidgets(
      'unread badge label resolves to EditorialMonoclePalette.bg (not white)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostPlayerTurnFeedToggle(eventCount: 7, showFeed: false),
        );
        await tester.pump();

        final Text label = tester.widget<Text>(
          find.descendant(
            of: find.byKey(kPlayerTurnFeedToggleButtonKey),
            matching: find.text('7'),
          ),
        );
        expect(label.style?.color, equals(EditorialMonoclePalette.bg));
        expect(label.style?.color, isNot(equals(Colors.white)));
      },
    );

    testWidgets('unread badge clamps overflow counts to "99+"',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        hostPlayerTurnFeedToggle(eventCount: 250, showFeed: false),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(kPlayerTurnFeedToggleButtonKey),
          matching: find.text('99+'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('button fires onPressed on tap', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Center(
              child: PlayerTurnEventsFeedToggleButton(
                eventCount: 0,
                tooltip: 'tooltip',
                showFeed: false,
                onPressed: () => taps += 1,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
      await tester.pump();
      expect(taps, equals(1));
    });
  });

  group('Source-file legacy-color regression', () {
    const List<String> feedLibraryPaths = <String>[
      'lib/features/game/widgets/shell/player_turn_event_feed.dart',
      'lib/features/game/widgets/shell/player_turn_event_feed_toggle.dart',
      'lib/features/game/widgets/shell/player_turn_event_feed_card.dart',
    ];

    test(
      'player turn event feed library contains no legacy black/white/redAccent literals',
      () async {
        const List<String> forbidden = <String>[
          'Colors.black.withValues',
          'Colors.white,',
          'Colors.white70',
          'Colors.redAccent',
        ];
        for (final String relativePath in feedLibraryPaths) {
          final File source = File(relativePath);
          expect(
            source.existsSync(),
            isTrue,
            reason: '$relativePath must exist at the documented path',
          );
          final String contents = source.readAsStringSync();
          final List<String> codeLines = contents
              .split('\n')
              .where((String line) => !line.trimLeft().startsWith('//'))
              .toList();
          final String codeOnly = codeLines.join('\n');
          for (final String token in forbidden) {
            expect(
              codeOnly.contains(token),
              isFalse,
              reason: 'Forbidden legacy chrome token "$token" remains in '
                  'executable code of $relativePath; replace with '
                  'the corresponding EditorialMonoclePalette token (see issue '
                  '#2861 S7).',
            );
          }
        }
      },
    );
  });
}
