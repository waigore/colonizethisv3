// Widget tests that verify CtGameSetup screen functionality against SPEC/ui
// acceptance criteria. Split from `screen_spec_acceptance_test.dart` to keep
// each file within the `repo.dart_file_non_comment_line_size` budget
// (`SPEC/program/repo-lint.md`). Screen contract: `SPEC/ui/game-setup.md`.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/game_setup.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

void main() {
  suppressLogsForTests();

  group('CtGameSetup — SPEC/ui/game-setup.md acceptance criteria', () {
    List<String> unselectedSlots() => List.filled(6, '');

    Widget buildGameSetup({
      GameSetupState state = GameSetupState.default_,
      GameSetupVariant variant = GameSetupVariant.plain,
      List<String> initialOrderedGpIds = const [],
      Map<String, String> initialLeaderVariantByGpId = const {},
      Size? viewportSize,
      void Function(List<String>, Map<String, String>)? onStartGame,
      VoidCallback? onBack,
    }) {
      final gpIds = initialOrderedGpIds.isEmpty
          ? unselectedSlots()
          : initialOrderedGpIds;
      final child = MaterialApp(
        theme: AppThemes.colonial,
        home: CtGameSetup(
          variant: variant,
          state: state,
          naming: defaultNamingConfig,
          initialOrderedGpIds: gpIds,
          initialLeaderVariantByGpId: initialLeaderVariantByGpId,
          onStartGame: onStartGame ?? (_, _) {},
          onBack: onBack ?? () {},
        ),
      );
      if (viewportSize != null) {
        return MediaQuery(
          data: MediaQueryData(size: viewportSize),
          child: child,
        );
      }
      return child;
    }

    testWidgets('AC Visibility: title, six slot rows, Start Game, Back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildGameSetup());
      await tester.pumpAndSettle();

      expect(find.text('Game Setup'), findsOneWidget);
      expect(find.text('Player 1 (You)'), findsOneWidget);
      expect(find.text('Player 2 (AI)'), findsOneWidget);
      expect(find.text('Player 6 (AI)'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets(
      'AC Initial state unselected: Select nation/leader, Start disabled',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(
            initialOrderedGpIds: unselectedSlots(),
            initialLeaderVariantByGpId: {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Select nation'), findsNWidgets(6));
        expect(find.text('Select leader'), findsNWidgets(6));
        final startFinder = find.widgetWithText(
          CtNinePatchButton,
          'Start Game',
        );
        expect(startFinder, findsOneWidget);
        expect(tester.widget<CtNinePatchButton>(startFinder).enabled, isFalse);
      },
    );

    testWidgets(
      'AC Start disabled until complete: all six slots filled enables Start',
      (WidgetTester tester) async {
        final gpIds = defaultNamingConfig.greatPowers
            .map((g) => g.id)
            .take(6)
            .toList();
        final leaderMap = <String, String>{};
        for (final id in gpIds) {
          final gp = defaultNamingConfig.gpById(id);
          if (gp != null && gp.leaderVariants.isNotEmpty) {
            leaderMap[id] = gp.defaultLeaderVariantId;
          }
        }

        await tester.pumpWidget(
          buildGameSetup(
            initialOrderedGpIds: gpIds,
            initialLeaderVariantByGpId: leaderMap,
          ),
        );
        await tester.pumpAndSettle();

        final startFinder = find.widgetWithText(
          CtNinePatchButton,
          'Start Game',
        );
        expect(startFinder, findsOneWidget);
        expect(tester.widget<CtNinePatchButton>(startFinder).enabled, isTrue);
      },
    );

    testWidgets(
      'AC No duplicate nations: selecting nation in slot 0 removes it from slot 1',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameSetup());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select nation').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('England').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select nation').first);
        await tester.pumpAndSettle();
        expect(find.text('England'), findsOneWidget);
        expect(find.text('France'), findsWidgets);
      },
    );

    testWidgets(
      'AC Leader follows nation: leader dropdown shows nation variants',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameSetup());
        await tester.pumpAndSettle();

        final nationDropdowns = find.byType(CtDropdown<String>);
        await tester.tap(nationDropdowns.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('England').last);
        await tester.pumpAndSettle();

        expect(find.text('Queen Victoria'), findsOneWidget);
      },
    );

    testWidgets('AC Start: onStartGame called with six gpIds and leader map', (
      WidgetTester tester,
    ) async {
      List<String>? receivedGpIds;
      Map<String, String>? receivedLeaders;

      final gpIds = defaultNamingConfig.greatPowers
          .map((g) => g.id)
          .take(6)
          .toList();
      final leaderMap = <String, String>{};
      for (final id in gpIds) {
        final gp = defaultNamingConfig.gpById(id);
        if (gp != null && gp.leaderVariants.isNotEmpty) {
          leaderMap[id] = gp.defaultLeaderVariantId;
        }
      }

      await tester.pumpWidget(
        buildGameSetup(
          initialOrderedGpIds: gpIds,
          initialLeaderVariantByGpId: leaderMap,
          onStartGame: (ids, leaders) {
            receivedGpIds = ids;
            receivedLeaders = leaders;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      expect(receivedGpIds, isNotNull);
      expect(receivedGpIds!.length, 6);
      expect(receivedLeaders, isNotNull);
      expect(receivedLeaders!.length, 6);
    });

    testWidgets('AC Back: onBack invoked when tapping Back', (
      WidgetTester tester,
    ) async {
      var backCalled = false;
      await tester.pumpWidget(buildGameSetup(onBack: () => backCalled = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(backCalled, isTrue);
    });

    testWidgets('AC Loading: Start disabled, Back enabled', (
      WidgetTester tester,
    ) async {
      var backCalled = false;
      await tester.pumpWidget(
        buildGameSetup(
          state: GameSetupState.loading,
          onBack: () => backCalled = true,
        ),
      );
      await tester.pump();

      expect(find.text('Generating world…'), findsOneWidget);
      final startFinder = find.widgetWithText(CtNinePatchButton, 'Start Game');
      expect(tester.widget<CtNinePatchButton>(startFinder).enabled, isFalse);
      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(backCalled, isTrue);
    });

    testWidgets('Coverage: narrow viewport uses stacked slot layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildGameSetup(viewportSize: const Size(400, 800)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Game Setup'), findsOneWidget);
      expect(find.text('Player 1 (You)'), findsOneWidget);
      expect(find.text('Player 6 (AI)'), findsOneWidget);
      expect(find.text('Select nation'), findsNWidgets(6));
    });

    testWidgets('Coverage: pixelArt variant builds and Back link works', (
      WidgetTester tester,
    ) async {
      var backCalled = false;
      await tester.pumpWidget(
        buildGameSetup(
          variant: GameSetupVariant.pixelArt,
          onBack: () => backCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      // Dark editorial-monocle action region (Refs #2868 S3) replaces the
      // legacy single "Back" button stack with a Cancel + Start Game row
      // plus a "Back to Main Menu" link below — also makes the pixelArt
      // setup taller than the 800x600 test viewport. Scroll the back link
      // label into the visible region before tapping.
      final backLinkFinder = find.byKey(
        const ValueKey<String>('gameSetupBackLinkLabel'),
      );
      await tester.ensureVisible(backLinkFinder);
      await tester.pumpAndSettle();
      await tester.tap(backLinkFinder);
      await tester.pumpAndSettle();
      expect(backCalled, isTrue);
    });

    testWidgets('Coverage: initialOrderedGpIds pad to six slots', (
      WidgetTester tester,
    ) async {
      final fourIds = defaultNamingConfig.greatPowers
          .map((g) => g.id)
          .take(4)
          .toList();
      await tester.pumpWidget(buildGameSetup(initialOrderedGpIds: fourIds));
      await tester.pumpAndSettle();

      expect(find.text('Game Setup'), findsOneWidget);
      expect(find.text('Player 1 (You)'), findsOneWidget);
    });

    testWidgets('Coverage: didUpdateWidget when initial data changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildGameSetup(
          initialOrderedGpIds: unselectedSlots(),
          initialLeaderVariantByGpId: {},
        ),
      );
      await tester.pumpAndSettle();

      final gpIds = defaultNamingConfig.greatPowers
          .map((g) => g.id)
          .take(6)
          .toList();
      final leaderMap = <String, String>{};
      for (final id in gpIds) {
        final gp = defaultNamingConfig.gpById(id);
        if (gp != null && gp.leaderVariants.isNotEmpty) {
          leaderMap[id] = gp.defaultLeaderVariantId;
        }
      }
      await tester.pumpWidget(
        buildGameSetup(
          initialOrderedGpIds: gpIds,
          initialLeaderVariantByGpId: leaderMap,
        ),
      );
      await tester.pumpAndSettle();

      final startFinder = find.widgetWithText(CtNinePatchButton, 'Start Game');
      expect(tester.widget<CtNinePatchButton>(startFinder).enabled, isTrue);
    });

    testWidgets('Coverage: clear nation in slot hits empty value branch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildGameSetup());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select nation').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('England').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CtDropdown<String>).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Select nation').first);
      await tester.tap(find.text('Select nation').first, warnIfMissed: false);
      await tester.pumpAndSettle();
    });

    testWidgets('Coverage: change leader in slot', (WidgetTester tester) async {
      await tester.pumpWidget(buildGameSetup());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CtDropdown<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('England').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CtDropdown<String>).at(1));
      await tester.pumpAndSettle();
      final leaderOptions = find.text('Queen Victoria');
      if (leaderOptions.evaluate().length > 1) {
        await tester.tap(leaderOptions.last);
      } else {
        await tester.tap(leaderOptions);
      }
      await tester.pumpAndSettle();
    });

    // Refs #2868 S1 — dark editorial-monocle header chrome (pixelArt variant).
    testWidgets(
      'AC Header (pixelArt): eyebrow, title, intro, brass divider visible',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(variant: GameSetupVariant.pixelArt),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('gameSetupEyebrow')),
          findsOneWidget,
        );
        expect(find.text('NEW CAMPAIGN'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('gameSetupTitlePixelArt')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('gameSetupIntro')),
          findsOneWidget,
        );
        expect(
          find.text('Choose six great powers and a leader variant for each.'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('gameSetupBrassDivider')),
          findsOneWidget,
        );
      },
    );

    testWidgets('AC Header (pixelArt): title uses accent colour + glow shadow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildGameSetup(variant: GameSetupVariant.pixelArt),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.byKey(
        const ValueKey<String>('gameSetupTitlePixelArt'),
      );
      expect(titleFinder, findsOneWidget);
      final TextStyle? titleStyle = tester.widget<Text>(titleFinder).style;
      expect(titleStyle, isNotNull);
      expect(titleStyle!.color, EditorialMonoclePalette.accent);
      expect(titleStyle.shadows, isNotNull);
      expect(titleStyle.shadows!.length, 1);
      expect(
        titleStyle.shadows!.first.color.toARGB32() & 0x00FFFFFF,
        EditorialMonoclePalette.accentBright.toARGB32() & 0x00FFFFFF,
      );
    });

    testWidgets(
      'AC Header (plain): eyebrow, intro, brass divider are not rendered',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameSetup());
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('gameSetupEyebrow')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('gameSetupIntro')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('gameSetupBrassDivider')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('gameSetupTitlePixelArt')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('gameSetupTitlePlain')),
          findsOneWidget,
        );
      },
    );

    // -------------------------------------------------------------------
    // Issue #2868 S2 — slot row chrome, swatches, leader-disabled.
    // -------------------------------------------------------------------

    testWidgets(
      'AC Issue #2868 R9: slot nation dropdown renders the GP map-colour '
      'swatch on the closed trigger after a nation is selected',
      (WidgetTester tester) async {
        final gpIds = defaultNamingConfig.greatPowers
            .map((g) => g.id)
            .take(6)
            .toList();
        final leaderMap = <String, String>{
          for (final id in gpIds)
            id: defaultNamingConfig.gpById(id)!.defaultLeaderVariantId,
        };
        await tester.pumpWidget(
          buildGameSetup(
            initialOrderedGpIds: gpIds,
            initialLeaderVariantByGpId: leaderMap,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(GpDefaultMapColorSwatch), findsNWidgets(6));
      },
    );

    testWidgets(
      'AC Issue #2868 R9: nation picker rows render the GP colour swatch '
      'next to each option when the dropdown is opened',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameSetup());
        await tester.pumpAndSettle();

        expect(find.byType(GpDefaultMapColorSwatch), findsNothing);

        await tester.tap(find.text('Select nation').first);
        await tester.pumpAndSettle();

        final swatches = find.byType(GpDefaultMapColorSwatch);
        expect(swatches, findsWidgets);
        final allGpCount = defaultNamingConfig.greatPowers.length;
        expect(swatches.evaluate().length, equals(allGpCount));
      },
    );

    testWidgets(
      'AC Issue #2868 R10: leader dropdown for an unselected nation slot is '
      'rendered at 0.4 opacity and ignores pointer events',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameSetup());
        await tester.pumpAndSettle();

        final disabledLeaderFinder = find.descendant(
          of: find.byType(Opacity),
          matching: find.widgetWithText(CtDropdown<String>, 'Select leader'),
        );
        expect(disabledLeaderFinder, findsNWidgets(6));

        final opacities = tester
            .widgetList<Opacity>(
              find.ancestor(
                of: find.widgetWithText(
                  CtDropdown<String>,
                  'Select leader',
                ),
                matching: find.byType(Opacity),
              ),
            )
            .map((w) => w.opacity)
            .toList();
        expect(opacities, isNotEmpty);
        for (final value in opacities) {
          expect(value, closeTo(0.4, 1e-9));
        }

        final beforeTap = find.text('Select leader').evaluate().length;
        await tester.tap(
          find.widgetWithText(CtDropdown<String>, 'Select leader').first,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        final afterTap = find.text('Select leader').evaluate().length;
        expect(afterTap, equals(beforeTap));
      },
    );

    testWidgets(
      'AC Issue #2868 R10: leader dropdown becomes interactive (no 0.4 '
      'opacity wrapper) after the slot has a nation selected',
      (WidgetTester tester) async {
        final gpIds = defaultNamingConfig.greatPowers
            .map((g) => g.id)
            .take(6)
            .toList();
        final leaderMap = <String, String>{
          for (final id in gpIds)
            id: defaultNamingConfig.gpById(id)!.defaultLeaderVariantId,
        };
        await tester.pumpWidget(
          buildGameSetup(
            initialOrderedGpIds: gpIds,
            initialLeaderVariantByGpId: leaderMap,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Select leader'), findsNothing);

        expect(find.text('Queen Victoria'), findsOneWidget);
      },
    );

    testWidgets(
      'AC Issue #2868 R7: pixelArt variant renders the brass-strip slot '
      'row chrome (gradient + accent-dim 1.5px borders on all four sides)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(variant: GameSetupVariant.pixelArt),
        );
        await tester.pumpAndSettle();

        final decoratedContainers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) {
              final dec = c.decoration;
              if (dec is! BoxDecoration) return false;
              return dec.gradient is LinearGradient && dec.border is Border;
            })
            .toList();

        final brassRowContainers = decoratedContainers.where((c) {
          final border = (c.decoration as BoxDecoration).border! as Border;
          final sides = <BorderSide>[
            border.top,
            border.bottom,
            border.left,
            border.right,
          ];
          return sides.every((side) {
            return side.width == 1.5 &&
                side.color == EditorialMonoclePalette.accentDim;
          });
        }).toList();

        expect(brassRowContainers.length, equals(6));
      },
    );

    testWidgets(
      'AC Issue #2868 R7 negative: plain variant does NOT paint the brass '
      '1.5px slot-row borders (no chrome regression onto non-pixelArt path)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameSetup());
        await tester.pumpAndSettle();

        final hasBrassChrome = tester
            .widgetList<Container>(find.byType(Container))
            .any((c) {
              final dec = c.decoration;
              if (dec is! BoxDecoration) return false;
              final border = dec.border;
              if (border is! Border) return false;
              return border.top.width == 1.5 &&
                  border.top.color == EditorialMonoclePalette.accentDim;
            });
        expect(hasBrassChrome, isFalse);
      },
    );

    // -------------------------------------------------------------------
    // Issue #2868 S4 — loading dim/scrim overlay (Refs #2868 R15).
    // -------------------------------------------------------------------

    testWidgets(
      'AC Issue #2868 R15: loading state shows the "Generating world…" '
      'label keyed gameSetupLoadingLabel above a dialogScrim wash',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(state: GameSetupState.loading),
        );
        await tester.pump();

        expect(
          find.byKey(const ValueKey<String>('gameSetupLoadingLabel')),
          findsOneWidget,
        );
        expect(find.text('Generating world…'), findsOneWidget);

        final scrimBoxes = tester.widgetList<ColoredBox>(
          find.byType(ColoredBox),
        );
        final hasScrim = scrimBoxes.any(
          (box) => box.color == EditorialMonoclePalette.dialogScrim,
        );
        expect(hasScrim, isTrue);
      },
    );

    testWidgets(
      'AC Issue #2868 R15: loading state wraps the header + slot rows in '
      'Opacity(0.4) and IgnorePointer(ignoring: true)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(state: GameSetupState.loading),
        );
        await tester.pump();

        final dimmedOpacityFinder = find.ancestor(
          of: find.widgetWithText(CtDropdown<String>, 'Select nation').first,
          matching: find.byWidgetPredicate(
            (Widget w) => w is Opacity && w.opacity == 0.4,
          ),
        );
        expect(dimmedOpacityFinder, findsWidgets);

        final dimmedIgnorePointerFinder = find.ancestor(
          of: find.widgetWithText(CtDropdown<String>, 'Select nation').first,
          matching: find.byWidgetPredicate(
            (Widget w) => w is IgnorePointer && w.ignoring == true,
          ),
        );
        expect(dimmedIgnorePointerFinder, findsWidgets);
      },
    );

    testWidgets(
      'AC Issue #2868 R15 negative: default state renders no dialogScrim '
      'ColoredBox and no gameSetupLoadingLabel widget',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameSetup());
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('gameSetupLoadingLabel')),
          findsNothing,
        );
        expect(find.text('Generating world…'), findsNothing);

        final hasScrim = tester
            .widgetList<ColoredBox>(find.byType(ColoredBox))
            .any((box) => box.color == EditorialMonoclePalette.dialogScrim);
        expect(hasScrim, isFalse);
      },
    );

    testWidgets(
      'AC Issue #2868 R15: Back button remains tappable under the loading '
      'scrim (scrim covers the dim region only, not the action buttons)',
      (WidgetTester tester) async {
        var backCalled = false;
        await tester.pumpWidget(
          buildGameSetup(
            state: GameSetupState.loading,
            onBack: () => backCalled = true,
          ),
        );
        await tester.pump();

        await tester.tap(find.text('Back'));
        await tester.pump();
        expect(backCalled, isTrue);
      },
    );

    // -------------------------------------------------------------------
    // Issue #2868 S3 — action buttons + back link (Refs #2868 R12/R13/R14).
    // -------------------------------------------------------------------

    testWidgets(
      'AC Issue #2868 R12: pixelArt action row renders the bespoke Cancel '
      'affordance with the localized "Cancel" label',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(variant: GameSetupVariant.pixelArt),
        );
        await tester.pumpAndSettle();

        final cancelLabelFinder = find.byKey(
          const ValueKey<String>('gameSetupCancelLabel'),
        );
        await tester.ensureVisible(cancelLabelFinder);
        await tester.pumpAndSettle();

        expect(cancelLabelFinder, findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      },
    );

    testWidgets(
      'AC Issue #2868 R12: tapping the pixelArt Cancel affordance invokes '
      'onBack exactly once (shared destination with the back link)',
      (WidgetTester tester) async {
        var backCallCount = 0;
        await tester.pumpWidget(
          buildGameSetup(
            variant: GameSetupVariant.pixelArt,
            onBack: () => backCallCount += 1,
          ),
        );
        await tester.pumpAndSettle();

        final cancelLabelFinder = find.byKey(
          const ValueKey<String>('gameSetupCancelLabel'),
        );
        await tester.ensureVisible(cancelLabelFinder);
        await tester.pumpAndSettle();
        await tester.tap(cancelLabelFinder);
        await tester.pumpAndSettle();

        expect(backCallCount, equals(1));
      },
    );

    testWidgets(
      'AC Issue #2868 R13: pixelArt Start Game uses the canonical '
      'CtNinePatchButton chrome (primary brass-accent surface)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(variant: GameSetupVariant.pixelArt),
        );
        await tester.pumpAndSettle();

        final startFinder = find.widgetWithText(
          CtNinePatchButton,
          'Start Game',
        );
        await tester.ensureVisible(startFinder);
        await tester.pumpAndSettle();

        expect(startFinder, findsOneWidget);
        // Disabled by default because all six slots start unselected.
        expect(tester.widget<CtNinePatchButton>(startFinder).enabled, isFalse);
      },
    );

    testWidgets(
      'AC Issue #2868 R14: pixelArt back link renders CtBackButton glyph + '
      '"Back to Main Menu" label below the action row',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(variant: GameSetupVariant.pixelArt),
        );
        await tester.pumpAndSettle();

        final backLinkLabelFinder = find.byKey(
          const ValueKey<String>('gameSetupBackLinkLabel'),
        );
        await tester.ensureVisible(backLinkLabelFinder);
        await tester.pumpAndSettle();

        expect(backLinkLabelFinder, findsOneWidget);
        expect(find.text('Back to Main Menu'), findsOneWidget);
        expect(find.byType(CtBackButton), findsOneWidget);
      },
    );

    testWidgets(
      'AC Issue #2868 R14: tapping the back-link label invokes onBack '
      '(label and CtBackButton glyph share the same destination)',
      (WidgetTester tester) async {
        var backCallCount = 0;
        await tester.pumpWidget(
          buildGameSetup(
            variant: GameSetupVariant.pixelArt,
            onBack: () => backCallCount += 1,
          ),
        );
        await tester.pumpAndSettle();

        final backLinkLabelFinder = find.byKey(
          const ValueKey<String>('gameSetupBackLinkLabel'),
        );
        await tester.ensureVisible(backLinkLabelFinder);
        await tester.pumpAndSettle();
        await tester.tap(backLinkLabelFinder);
        await tester.pumpAndSettle();

        expect(backCallCount, equals(1));
      },
    );

    testWidgets(
      'AC Issue #2868 R12/R14 negative: plain variant action region keeps '
      'the pre-S3 single-column Start/Back stack (no Cancel, no back link)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameSetup());
        await tester.pumpAndSettle();

        expect(find.text('Cancel'), findsNothing);
        expect(find.text('Back to Main Menu'), findsNothing);
        expect(find.byType(CtBackButton), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('gameSetupCancelLabel')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('gameSetupBackLinkLabel')),
          findsNothing,
        );
        // Plain variant still surfaces the legacy "Back" button text.
        expect(find.text('Back'), findsOneWidget);
      },
    );

    testWidgets(
      'AC Issue #2868 R12/R14: pixelArt loading state keeps Cancel and the '
      'back link tappable (they paint outside the dim/scrim overlay)',
      (WidgetTester tester) async {
        var backCallCount = 0;
        await tester.pumpWidget(
          buildGameSetup(
            variant: GameSetupVariant.pixelArt,
            state: GameSetupState.loading,
            onBack: () => backCallCount += 1,
          ),
        );
        await tester.pump();

        // `pump` (not `pumpAndSettle`) below because the loading spinner
        // animates indefinitely; `pumpAndSettle` would time out.
        final cancelLabelFinder = find.byKey(
          const ValueKey<String>('gameSetupCancelLabel'),
        );
        await tester.ensureVisible(cancelLabelFinder);
        await tester.pump();
        await tester.tap(cancelLabelFinder);
        await tester.pump();
        expect(backCallCount, equals(1));

        final backLinkLabelFinder = find.byKey(
          const ValueKey<String>('gameSetupBackLinkLabel'),
        );
        await tester.ensureVisible(backLinkLabelFinder);
        await tester.pump();
        await tester.tap(backLinkLabelFinder);
        await tester.pump();
        expect(backCallCount, equals(2));
      },
    );

    // -------------------------------------------------------------------
    // Issue #2868 S5 / S6 — narrow-viewport slot-row stacking + action
    // button retention (Refs #2868 R16/R17). Mirrors the SPEC AC block
    // "Narrow-viewport slot-row stacking and action-button retention".
    //
    // Layout marker: the wide slot body wraps the slot label in
    // `SizedBox(width: 100, child: labelWidget)` inside a horizontal `Row`;
    // the narrow slot body uses a vertical `Column` with no
    // `SizedBox(width: 100)` wrapper. The presence/absence of that
    // wrapper around each slot label is therefore a stable structural
    // signal of which body variant rendered.
    // -------------------------------------------------------------------

    bool isWideSlotLabelSizedBox(Widget w) =>
        w is SizedBox && w.width == 100 && w.height == null;

    testWidgets(
      'AC Issue #2868 R16 pixelArt: viewport < kGameSetupNarrowBreakpoint '
      'stacks each slot row as a vertical Column (no wide-Row label '
      'SizedBox(width:100) ancestor)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(
            variant: GameSetupVariant.pixelArt,
            viewportSize: const Size(
              kGameSetupNarrowBreakpoint - 1,
              1200,
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (var slotIndex = 0; slotIndex < 6; slotIndex++) {
          final String label = slotIndex == 0
              ? 'Player 1 (You)'
              : 'Player ${slotIndex + 1} (AI)';
          final labelFinder = find.text(label);
          expect(labelFinder, findsOneWidget);
          final wideLabelSized = find.ancestor(
            of: labelFinder,
            matching: find.byWidgetPredicate(isWideSlotLabelSizedBox),
          );
          expect(
            wideLabelSized,
            findsNothing,
            reason:
                'narrow viewport (<${kGameSetupNarrowBreakpoint}dp) must '
                'mount the stacked Column slot body — slot "$label" should '
                'not be wrapped in the wide-Row SizedBox(width:100) label '
                'sentinel.',
          );
        }
      },
    );

    testWidgets(
      'AC Issue #2868 R16 pixelArt: viewport >= kGameSetupNarrowBreakpoint '
      'lays each slot row in a horizontal Row with the wide-body label '
      'SizedBox(width:100) wrapper present for all six slots',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(
            variant: GameSetupVariant.pixelArt,
            viewportSize: const Size(
              kGameSetupNarrowBreakpoint + 100,
              1200,
            ),
          ),
        );
        await tester.pumpAndSettle();

        var foundCount = 0;
        for (var slotIndex = 0; slotIndex < 6; slotIndex++) {
          final String label = slotIndex == 0
              ? 'Player 1 (You)'
              : 'Player ${slotIndex + 1} (AI)';
          final labelFinder = find.text(label);
          expect(labelFinder, findsOneWidget);
          final wideLabelSized = find.ancestor(
            of: labelFinder,
            matching: find.byWidgetPredicate(isWideSlotLabelSizedBox),
          );
          if (wideLabelSized.evaluate().isNotEmpty) {
            foundCount += 1;
          }
        }
        expect(
          foundCount,
          equals(6),
          reason:
              'wide viewport (>=${kGameSetupNarrowBreakpoint}dp) must '
              'mount the wide-Row slot body for every slot — expected each '
              'of the six labels to be wrapped in SizedBox(width:100).',
        );
      },
    );

    testWidgets(
      'AC Issue #2868 R16 plain: viewport < kGameSetupNarrowBreakpoint '
      'also stacks each slot row vertically (plain variant honors the '
      'same 500dp breakpoint as pixelArt)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(
            viewportSize: const Size(
              kGameSetupNarrowBreakpoint - 1,
              1200,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final labelFinder = find.text('Player 1 (You)');
        expect(labelFinder, findsOneWidget);
        final wideLabelSized = find.ancestor(
          of: labelFinder,
          matching: find.byWidgetPredicate(isWideSlotLabelSizedBox),
        );
        expect(wideLabelSized, findsNothing);
      },
    );

    testWidgets(
      'AC Issue #2868 R17 pixelArt: narrow viewport keeps Cancel and Start '
      'Game side-by-side (same Y row, Cancel left of Start) with the '
      'back-link region rendered beneath the action row',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(
            variant: GameSetupVariant.pixelArt,
            viewportSize: const Size(
              kGameSetupNarrowBreakpoint - 1,
              1600,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cancelLabelFinder = find.byKey(
          const ValueKey<String>('gameSetupCancelLabel'),
        );
        await tester.ensureVisible(cancelLabelFinder);
        await tester.pumpAndSettle();
        expect(cancelLabelFinder, findsOneWidget);

        final startFinder = find.widgetWithText(
          CtNinePatchButton,
          'Start Game',
        );
        expect(startFinder, findsOneWidget);
        await tester.ensureVisible(startFinder);
        await tester.pumpAndSettle();

        // R17 retention: Cancel and Start Game must remain side-by-side
        // even at narrow widths (no Cancel-above-Start reflow). Compare
        // their painted bounds — Cancel center sits left of Start center
        // on X, and their Y ranges overlap (same horizontal row).
        final Rect cancelRect = tester.getRect(cancelLabelFinder);
        final Rect startRect = tester.getRect(startFinder);
        expect(
          cancelRect.center.dx < startRect.center.dx,
          isTrue,
          reason:
              'Cancel center.dx (${cancelRect.center.dx}) must sit LEFT of '
              'Start Game center.dx (${startRect.center.dx}) at narrow '
              'viewport per #2868 R17.',
        );
        expect(
          cancelRect.top < startRect.bottom && startRect.top < cancelRect.bottom,
          isTrue,
          reason:
              'Cancel Y range [${cancelRect.top}, ${cancelRect.bottom}] and '
              'Start Game Y range [${startRect.top}, ${startRect.bottom}] '
              'must overlap (same horizontal row) at narrow viewport per '
              '#2868 R17 — no Cancel-above-Start reflow.',
        );

        // Back-link region remains BELOW the action row at narrow widths.
        final backLinkLabelFinder = find.byKey(
          const ValueKey<String>('gameSetupBackLinkLabel'),
        );
        await tester.ensureVisible(backLinkLabelFinder);
        await tester.pumpAndSettle();
        expect(backLinkLabelFinder, findsOneWidget);
        expect(find.byType(CtBackButton), findsOneWidget);
        final Rect backLinkRect = tester.getRect(backLinkLabelFinder);
        expect(
          backLinkRect.top >= startRect.bottom &&
              backLinkRect.top >= cancelRect.bottom,
          isTrue,
          reason:
              'back-link Y top (${backLinkRect.top}) must sit at or below '
              'the Cancel/Start action row bottom — back link must remain '
              'below the action row at narrow viewport per #2868 R17.',
        );
      },
    );
  });
}
