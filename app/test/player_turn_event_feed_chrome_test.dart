import 'dart:io' show File;

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show kGameMapWideProvinceSidePanelWidth, kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_app/features/game/widgets/player_turn_event_feed.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the dark editorial-monocle restyle of the news feed card and
/// newspaper toggle button (issue #2861 S7).
///
/// SPEC: `SPEC/ui/player-turn-event-feed.md` § Card chrome and § Toggle
/// button chrome (dark editorial-monocle).
///
/// Asserts that:
///   1. The card surface paints `CtGradients.panelGradient` plus a 1 dp
///      `accentDim` border (no legacy `Material(color: Colors.black…)`
///      chrome inside the card subtree).
///   2. Body text resolves to `EditorialMonoclePalette.fg` and empty-state
///      copy to `EditorialMonoclePalette.muted` italic (no `Colors.white*`).
///   3. The toggle button glyph resolves to `accent` (closed) or
///      `accentBright` (open) and never to a Material default.
///   4. The unread-count badge background resolves to `EditorialMonoclePalette.danger`
///      (not `Colors.redAccent`) and the text colour resolves to
///      `EditorialMonoclePalette.bg` (not `Colors.white`).
///   5. The source file `player_turn_event_feed.dart` no longer contains
///      legacy `Colors.black`, `Colors.white`, or `Colors.redAccent`
///      literals (catalog ban / SPEC AC last bullet).
void main() {
  suppressLogsForTests();

  Widget hostFeedCard({
    required List<PlayerTurnEventFeedEntry> entries,
    String emptyLabel = 'No major events last turn.',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              right: 0,
              child: PlayerTurnEventFeedCard(
                entries: entries,
                emptyLabel: emptyLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget hostToggle({
    required int eventCount,
    required bool showFeed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: PlayerTurnEventsFeedToggleButton(
            eventCount: eventCount,
            tooltip: 'tooltip',
            showFeed: showFeed,
            onPressed: () {},
          ),
        ),
      ),
    );
  }

  group('PlayerTurnEventFeedCard chrome', () {
    testWidgets(
      'card surface paints panelGradient + 1dp accentDim border (no black Material)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostFeedCard(entries: const <PlayerTurnEventFeedEntry>[]),
        );
        await tester.pump();

        final Finder surface = find.byKey(PlayerTurnEventFeedCard.surfaceKey);
        expect(surface, findsOneWidget);

        final DecoratedBox box = tester.widget<DecoratedBox>(surface);
        final BoxDecoration decoration = box.decoration as BoxDecoration;
        final LinearGradient? gradient = decoration.gradient as LinearGradient?;
        expect(gradient, isNotNull);
        // The panel gradient is begin: topCenter, end: bottomCenter, with
        // surface → bg colours from EditorialMonoclePalette. Compare by
        // colour list rather than identity to keep the AC robust to
        // accessor changes.
        expect(
          gradient!.colors,
          equals(CtGradients.panelGradient.colors),
        );
        final Border border = decoration.border! as Border;
        expect(border.top.width, equals(PlayerTurnEventFeedCard.borderWidth));
        expect(border.top.color, equals(EditorialMonoclePalette.accentDim));
        expect(border.right.color, equals(EditorialMonoclePalette.accentDim));
        expect(border.bottom.color, equals(EditorialMonoclePalette.accentDim));
        expect(border.left.color, equals(EditorialMonoclePalette.accentDim));

        // No legacy black-Material surface should sit inside the card.
        final Iterable<Material> materials = tester.widgetList<Material>(
          find.descendant(of: surface, matching: find.byType(Material)),
        );
        for (final Material m in materials) {
          expect(
            m.color,
            isNot(equals(Colors.black.withValues(alpha: 0.62))),
            reason: 'Card body must not paint legacy Colors.black backdrop',
          );
        }
      },
    );

    testWidgets('card width equals the wide province side-panel width',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        hostFeedCard(entries: const <PlayerTurnEventFeedEntry>[]),
      );
      await tester.pump();

      final SizedBox sized = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byKey(PlayerTurnEventFeedCard.surfaceKey),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sized.width, equals(kGameMapWideProvinceSidePanelWidth));
    });

    testWidgets('event row body text resolves to EditorialMonoclePalette.fg',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        hostFeedCard(
          entries: const <PlayerTurnEventFeedEntry>[
            PlayerTurnEventFeedEntry(text: 'Research complete'),
          ],
        ),
      );
      await tester.pump();

      final Text entryText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(PlayerTurnEventFeedCard.surfaceKey),
          matching: find.text('Research complete'),
        ),
      );
      expect(entryText.style?.color, equals(EditorialMonoclePalette.fg));
      // Negative regression guard: no Colors.white left over from legacy chrome.
      expect(entryText.style?.color, isNot(equals(Colors.white)));
    });

    testWidgets(
      'empty-state copy resolves to EditorialMonoclePalette.muted italic',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostFeedCard(
            entries: const <PlayerTurnEventFeedEntry>[],
            emptyLabel: 'No major events last turn.',
          ),
        );
        await tester.pump();

        final Text emptyText = tester.widget<Text>(
          find.descendant(
            of: find.byKey(PlayerTurnEventFeedCard.surfaceKey),
            matching: find.text('No major events last turn.'),
          ),
        );
        expect(emptyText.style?.color, equals(EditorialMonoclePalette.muted));
        expect(emptyText.style?.fontStyle, equals(FontStyle.italic));
        // Negative regression guard against the legacy Colors.white70 token.
        expect(emptyText.style?.color, isNot(equals(Colors.white70)));
      },
    );

    testWidgets(
      'tappable row wraps content in a transparent Material + InkWell that fires onTap',
      (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          hostFeedCard(
            entries: <PlayerTurnEventFeedEntry>[
              PlayerTurnEventFeedEntry(
                text: 'Province captured',
                onTap: () => tapped = true,
              ),
            ],
          ),
        );
        await tester.pump();

        // The tappable row must use a transparent Material so the dark
        // gradient remains visible behind the row press highlight.
        final InkWell inkWell = tester.widget<InkWell>(
          find.descendant(
            of: find.byKey(PlayerTurnEventFeedCard.surfaceKey),
            matching: find.byType(InkWell),
          ),
        );
        expect(inkWell.splashColor, equals(EditorialMonoclePalette.surfaceLite));
        expect(inkWell.highlightColor, equals(EditorialMonoclePalette.surfaceLite));
        expect(inkWell.hoverColor, equals(EditorialMonoclePalette.surfaceLite));

        await tester.tap(find.text('Province captured'));
        await tester.pump();
        expect(tapped, isTrue);
      },
    );

    testWidgets('non-tappable row renders raw Text (no InkWell wrapper)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        hostFeedCard(
          entries: const <PlayerTurnEventFeedEntry>[
            PlayerTurnEventFeedEntry(text: 'Static event'),
          ],
        ),
      );
      await tester.pump();

      // No InkWell should appear inside the card when no row is tappable.
      expect(
        find.descendant(
          of: find.byKey(PlayerTurnEventFeedCard.surfaceKey),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });
  });

  group('PlayerTurnEventsFeedToggleButton chrome', () {
    // Resolves the bordered 28 × 22 dp toggle surface Container (the only
    // Container in the subtree carrying a Border).
    Container surfaceContainer(WidgetTester tester) {
      return tester
          .widgetList<Container>(
            find.descendant(
              of: find.byKey(kPlayerTurnFeedToggleButtonKey),
              matching: find.byType(Container),
            ),
          )
          .firstWhere(
            (Container c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).border != null,
          );
    }

    testWidgets(
      'surface is 28 × 22 dp, bg-deep fill, 1 dp border; glyph is not a Material Icon (M3)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostToggle(eventCount: 0, showFeed: false),
        );
        await tester.pump();

        final Container surface = surfaceContainer(tester);
        expect(
          surface.constraints,
          equals(BoxConstraints.tightFor(width: 28, height: 22)),
        );
        final BoxDecoration decoration = surface.decoration as BoxDecoration;
        expect(decoration.color, equals(EditorialMonoclePalette.bgDeep));
        final Border border = decoration.border as Border;
        expect(border.top.width, equals(1));

        // The glyph must be the monochrome NewspaperGlyph vector, not a
        // Material Icon at 20 dp.
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
          hostToggle(eventCount: 0, showFeed: false),
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
            surfaceContainer(tester).decoration as BoxDecoration;
        final Border border = decoration.border as Border;
        expect(border.top.color, equals(EditorialMonoclePalette.border));
      },
    );

    testWidgets(
      'open-state glyph resolves to accent; border resolves to accentDim',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostToggle(eventCount: 3, showFeed: true),
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
            surfaceContainer(tester).decoration as BoxDecoration;
        final Border border = decoration.border as Border;
        expect(border.top.color, equals(EditorialMonoclePalette.accentDim));
      },
    );

    testWidgets(
      'unread badge background resolves to danger token (not redAccent)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostToggle(eventCount: 5, showFeed: false),
        );
        await tester.pump();

        // The badge background is the Container wrapping the count Text,
        // painted with a BoxDecoration whose color resolves to
        // EditorialMonoclePalette.danger at 0.95 alpha.
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
        // Negative regression guard: must not paint legacy redAccent.
        expect(badgeColor, isNot(equals(Colors.redAccent)));
      },
    );

    testWidgets(
      'unread badge label resolves to EditorialMonoclePalette.bg (not white)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostToggle(eventCount: 7, showFeed: false),
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
        hostToggle(eventCount: 250, showFeed: false),
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
        MaterialApp(
          home: Scaffold(
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
    test(
      'player_turn_event_feed.dart contains no legacy black/white/redAccent literals',
      () async {
        // The widget source file must not paint with the legacy Material
        // chrome tokens (issue #2861 S7 chrome contract / catalog ban per
        // SPEC/ui/pixel-art-ui-catalog.md § Material design ban).
        final File source = File(
          'lib/features/game/widgets/player_turn_event_feed.dart',
        );
        expect(
          source.existsSync(),
          isTrue,
          reason: 'player_turn_event_feed.dart must exist at the documented path',
        );
        final String contents = source.readAsStringSync();
        // Forbid the specific Material tokens the legacy chrome used.
        // (Colors.transparent is still allowed and is the canonical way to
        // surface a tappable Material above the editorial-monocle gradient.)
        // The check ignores comment lines so doc-string references to the
        // legacy tokens (explaining what was replaced) are allowed; only
        // executable code lines must not paint with those tokens.
        const List<String> forbidden = <String>[
          'Colors.black.withValues',
          'Colors.white,',
          'Colors.white70',
          'Colors.redAccent',
        ];
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
                'executable code of player_turn_event_feed.dart; replace with '
                'the corresponding EditorialMonoclePalette token (see issue '
                '#2861 S7).',
          );
        }
      },
    );
  });
}
