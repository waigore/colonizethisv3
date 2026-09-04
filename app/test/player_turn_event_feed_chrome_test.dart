import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapWideProvinceSidePanelWidth;
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'player_turn_event_feed_chrome_test_support.dart';

/// Tests for the dark editorial-monocle restyle of the news feed card and
/// newspaper toggle button (issue #2861 S7).
///
/// SPEC: `SPEC/ui/player-turn-event-feed.md` § Card chrome and § Toggle
/// button chrome (dark editorial-monocle).
void main() {
  suppressLogsForTests();

  group('PlayerTurnEventFeedCard chrome', () {
    testWidgets(
      'card surface paints panelGradient + 1dp accentDim border (no black Material)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hostPlayerTurnFeedCard(entries: const <PlayerTurnEventFeedEntry>[]),
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
        hostPlayerTurnFeedCard(entries: const <PlayerTurnEventFeedEntry>[]),
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
        hostPlayerTurnFeedCard(
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
          hostPlayerTurnFeedCard(
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
          hostPlayerTurnFeedCard(
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
        hostPlayerTurnFeedCard(
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

    testWidgets(
      'link-affordance row shows trailing chevron and fires onTap',
      (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          hostPlayerTurnFeedCard(
            entries: <PlayerTurnEventFeedEntry>[
              PlayerTurnEventFeedEntry(
                text:
                    'Research complete: Crop Rotation unlocked · '
                    'Unlocks: Sheep Ranching, Animal Husbandry, and '
                    'Steppe Horsemen research paths',
                linkAffordance: true,
                onTap: () => tapped = true,
              ),
            ],
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        await tester.tap(find.textContaining('Crop Rotation unlocked'));
        await tester.pump();
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'tappable row on narrow viewport enforces 44 dp minimum height',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(360, 800)),
            child: hostPlayerTurnFeedCard(
              entries: <PlayerTurnEventFeedEntry>[
                PlayerTurnEventFeedEntry(
                  text:
                      'Research complete: Crop Rotation unlocked · '
                      'Unlocks: Sheep Ranching, Animal Husbandry, and '
                      'Steppe Horsemen research paths',
                  linkAffordance: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        );
        await tester.pump();

        final inkWellFinder = find.descendant(
          of: find.byKey(PlayerTurnEventFeedCard.surfaceKey),
          matching: find.byType(InkWell),
        );
        expect(
          tester.getSize(inkWellFinder).height,
          greaterThanOrEqualTo(PlayerTurnEventFeedCard.narrowTappableRowMinHeight),
        );
      },
    );
  });
}
