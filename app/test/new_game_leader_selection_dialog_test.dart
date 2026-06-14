import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

const Key _kSlotPickersStackedColumnKey = ValueKey<String>(
  'newGameLeaderDialogSlotPickersColumn',
);
const Key _kSlotPickersSideBySideRowKey = ValueKey<String>(
  'newGameLeaderDialogSlotPickersRow',
);

void main() {
  suppressLogsForTests();

  group('parseSeedInput', () {
    test('empty and invalid map to 42', () {
      expect(NewGameLeaderSelectionDialog.parseSeedInput(''), 42);
      expect(NewGameLeaderSelectionDialog.parseSeedInput('   '), 42);
      expect(NewGameLeaderSelectionDialog.parseSeedInput('abc'), 42);
      expect(NewGameLeaderSelectionDialog.parseSeedInput('-3'), 42);
    });

    test('accepts non-negative integers', () {
      expect(NewGameLeaderSelectionDialog.parseSeedInput('0'), 0);
      expect(NewGameLeaderSelectionDialog.parseSeedInput(' 99 '), 99);
    });
  });

  group('NewGameLeaderSelectionDialog', () {
    Future<void> ensureTapStart(WidgetTester tester) async {
      final startButton = find.ancestor(
        of: find.text('Start'),
        matching: find.byType(CtNinePatchButton),
      );
      await tester.ensureVisible(startButton);
      await tester.pumpAndSettle();
      await tester.tap(startButton);
      await tester.pumpAndSettle();
    }

    Future<void> ensureTapCancel(WidgetTester tester) async {
      final cancelButton = find.ancestor(
        of: find.text('Cancel'),
        matching: find.byType(CtNinePatchButton),
      );
      await tester.ensureVisible(cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();
    }

    Future<void> pumpDialog(
      WidgetTester tester, {
      Size surfaceSize = const Size(800, 1300),
      required void Function(
        List<String> orderedGreatPowerIds,
        Map<String, String> leaderVariantByGpId,
        int seed,
        bool infiniteMode,
        double terrainVariation,
        Map<String, String?> aiProfileByGpId,
      )
      onConfirmed,
    }) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.colonial,
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    final base = GameSetupConfig.defaultConfig;
                    final naming = defaultNamingConfig;
                    final initial = <String, String>{};
                    for (final gpId in base.selectedGreatPowerIds) {
                      final gp = naming.gpById(gpId);
                      if (gp != null && gp.leaderVariants.isNotEmpty) {
                        initial[gpId] = gp.defaultLeaderVariantId;
                      }
                    }
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => NewGameLeaderSelectionDialog(
                        baseConfig: base,
                        naming: naming,
                        initialLeaderByGpId: initial,
                        blessedProfileNames: const [],
                        onCancel: () => Navigator.of(ctx).pop(),
                        onConfirmed: onConfirmed,
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows six GP colour swatches and default nation labels', (
      WidgetTester tester,
    ) async {
      await pumpDialog(tester, onConfirmed: (_, _, _, _, _, _) {});

      expect(find.byType(GpDefaultMapColorSwatch), findsNWidgets(6));
      expect(find.text('England'), findsWidgets);
      expect(find.text('New game — Setup'), findsOneWidget);
      expect(find.text('Player 1 (You)'), findsOneWidget);
      expect(find.text('Player 2 (AI)'), findsOneWidget);
      expect(find.text('Player 6 (AI)'), findsOneWidget);
      expect(find.textContaining('Default map colours'), findsOneWidget);
      expect(find.text('Game / world seed'), findsOneWidget);
      expect(find.textContaining('Use 0 for a random world'), findsOneWidget);
      expect(
        find.text('Infinite mode (turns progress past 1800)'),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsOneWidget);
    });

    testWidgets(
      'large viewport: six slots visible; single shell vertical scroll only',
      (WidgetTester tester) async {
        await pumpDialog(
          tester,
          surfaceSize: const Size(900, 2000),
          onConfirmed: (_, _, _, _, _, _) {},
        );
        await tester.pumpAndSettle();

        final shell = find.byType(CtDialogShell);
        expect(
          find.descendant(of: shell, matching: find.byType(CustomScrollView)),
          findsOneWidget,
        );

        final viewHeight = tester.view.physicalSize.height;
        final player6Top = tester.getRect(find.text('Player 6 (AI)')).top;
        final startTop = tester.getRect(find.text('Start')).top;
        expect(player6Top, greaterThan(0));
        expect(player6Top, lessThan(viewHeight));
        expect(startTop, greaterThan(player6Top));
        expect(startTop, lessThan(viewHeight));
      },
    );

    testWidgets('narrow viewport: shell scroll reaches Start', (
      WidgetTester tester,
    ) async {
      await pumpDialog(
        tester,
        surfaceSize: const Size(520, 420),
        onConfirmed: (_, _, _, _, _, _) {},
      );
      await tester.pumpAndSettle();

      final scrollable = find.descendant(
        of: find.byType(CtDialogShell),
        matching: find.byType(Scrollable),
      );
      await tester.dragUntilVisible(
        find.text('Start'),
        scrollable,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start'));
      expect(tester.getRect(find.text('Start')).top, greaterThanOrEqualTo(0));
    });

    testWidgets('Start passes default ordered Great Power ids and leader map', (
      WidgetTester tester,
    ) async {
      List<String>? gotIds;
      Map<String, String>? gotLeaders;
      int? gotSeed;
      bool? gotInfiniteMode;

      await pumpDialog(
        tester,
        onConfirmed: (ids, leaders, seed, infiniteMode, _, __) {
          gotIds = ids;
          gotLeaders = leaders;
          gotSeed = seed;
          gotInfiniteMode = infiniteMode;
        },
      );

      await ensureTapStart(tester);

      expect(gotIds, GameSetupConfig.defaultConfig.selectedGreatPowerIds);
      expect(gotLeaders, isNotNull);
      expect(gotLeaders!.length, 6);
      expect(gotLeaders!['england'], 'queen_victoria');
      expect(gotSeed, 42);
      expect(gotInfiniteMode, isFalse);
    });

    testWidgets('AI slots show profile dropdown when blessed names exist', (
      WidgetTester tester,
    ) async {
      Map<String, String?>? gotProfiles;
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.colonial,
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    final base = GameSetupConfig.defaultConfig;
                    final naming = defaultNamingConfig;
                    final initial = <String, String>{};
                    for (final gpId in base.selectedGreatPowerIds) {
                      final gp = naming.gpById(gpId);
                      if (gp != null && gp.leaderVariants.isNotEmpty) {
                        initial[gpId] = gp.defaultLeaderVariantId;
                      }
                    }
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => NewGameLeaderSelectionDialog(
                        baseConfig: base,
                        naming: naming,
                        initialLeaderByGpId: initial,
                        blessedProfileNames: const ['aggressive_v2'],
                        onCancel: () => Navigator.of(ctx).pop(),
                        onConfirmed:
                            (_, _, _, _, _, profiles) => gotProfiles = profiles,
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(CtDropdown<String>), findsNWidgets(17));
      await ensureTapStart(tester);
      expect(gotProfiles, isEmpty);
    });

    testWidgets('selecting blessed profile forwards aiProfileByGpId', (
      WidgetTester tester,
    ) async {
      Map<String, String?>? gotProfiles;
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.colonial,
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    final base = GameSetupConfig.defaultConfig;
                    final naming = defaultNamingConfig;
                    final initial = <String, String>{};
                    for (final gpId in base.selectedGreatPowerIds) {
                      final gp = naming.gpById(gpId);
                      if (gp != null && gp.leaderVariants.isNotEmpty) {
                        initial[gpId] = gp.defaultLeaderVariantId;
                      }
                    }
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => NewGameLeaderSelectionDialog(
                        baseConfig: base,
                        naming: naming,
                        initialLeaderByGpId: initial,
                        blessedProfileNames: const ['aggressive_v2'],
                        onCancel: () => Navigator.of(ctx).pop(),
                        onConfirmed:
                            (_, _, _, _, _, profiles) => gotProfiles = profiles,
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final profileDropdowns = find.widgetWithText(CtDropdown<String>, 'Normal');
      await tester.tap(profileDropdowns.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('aggressive_v2').last);
      await tester.pumpAndSettle();
      await ensureTapStart(tester);
      expect(gotProfiles?.values, contains('aggressive_v2'));
    });

    testWidgets('Cancel closes dialog without calling onConfirmed', (
      WidgetTester tester,
    ) async {
      var confirmed = false;
      await pumpDialog(
        tester,
        onConfirmed: (_, _, _, _, _, _) {
          confirmed = true;
        },
      );

      await ensureTapCancel(tester);

      expect(confirmed, isFalse);
      expect(find.text('New game — Setup'), findsNothing);
    });

    testWidgets('changing slot 1 nation to Sweden updates order and leader', (
      WidgetTester tester,
    ) async {
      List<String>? gotIds;
      Map<String, String>? gotLeaders;

      await pumpDialog(
        tester,
        onConfirmed: (ids, leaders, _, _, _, __) {
          gotIds = ids;
          gotLeaders = leaders;
        },
      );

      await tester.tap(find.text('England'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sweden'));
      await tester.pumpAndSettle();

      await ensureTapStart(tester);

      expect(gotIds, isNotNull);
      expect(gotIds!.first, 'sweden');
      expect(gotLeaders, isNotNull);
      expect(gotLeaders!['sweden'], 'gustavus');
    });

    testWidgets('Start passes seed 0 when field is 0', (
      WidgetTester tester,
    ) async {
      int? gotSeed;
      await pumpDialog(tester, onConfirmed: (_, _, s, _, _, __) => gotSeed = s);
      final field = find.byType(TextField);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, '0');
      await tester.pump();
      await ensureTapStart(tester);
      expect(gotSeed, 0);
    });

    testWidgets('Start uses 42 when field is cleared', (
      WidgetTester tester,
    ) async {
      int? gotSeed;
      await pumpDialog(tester, onConfirmed: (_, _, s, _, _, __) => gotSeed = s);
      final field = find.byType(TextField);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, '');
      await tester.pump();
      await ensureTapStart(tester);
      expect(gotSeed, 42);
    });

    testWidgets('Start passes infiniteMode true when checkbox checked', (
      WidgetTester tester,
    ) async {
      bool? gotInfiniteMode;
      await pumpDialog(
        tester,
        onConfirmed: (_, _, _, infiniteMode, _, __) =>
            gotInfiniteMode = infiniteMode,
      );
      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      await ensureTapStart(tester);
      expect(gotInfiniteMode, isTrue);
    });

    testWidgets(
      'shows terrain variation slider with default helper and label',
      (WidgetTester tester) async {
        await pumpDialog(tester, onConfirmed: (_, _, _, _, _, _) {});
        expect(find.byType(CtSlider), findsOneWidget);
        expect(find.textContaining('Terrain variation'), findsOneWidget);
        expect(
          find.textContaining('Higher values produce more mixed terrain'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Start passes default terrainVariation 0.5 when slider not moved',
      (WidgetTester tester) async {
        double? gotTerrainVariation;
        await pumpDialog(
          tester,
          onConfirmed: (_, _, _, _, terrainVariation, __) =>
              gotTerrainVariation = terrainVariation,
        );
        await ensureTapStart(tester);
        expect(gotTerrainVariation, closeTo(0.5, 1e-9));
      },
    );

    testWidgets(
      'Start passes terrainVariation 0.0 after dragging slider to leftmost',
      (WidgetTester tester) async {
        double? gotTerrainVariation;
        await pumpDialog(
          tester,
          onConfirmed: (_, _, _, _, terrainVariation, __) =>
              gotTerrainVariation = terrainVariation,
        );

        final slider = find.byType(CtSlider);
        await tester.ensureVisible(slider);
        await tester.pumpAndSettle();
        // Tap at the far-left of the slider track to snap to min (0.0).
        final rect = tester.getRect(slider);
        await tester.tapAt(Offset(rect.left + 1, rect.center.dy));
        await tester.pumpAndSettle();
        await ensureTapStart(tester);
        expect(gotTerrainVariation, closeTo(0.0, 1e-6));
      },
    );

    testWidgets(
      'Start passes terrainVariation 1.0 after dragging slider to rightmost',
      (WidgetTester tester) async {
        double? gotTerrainVariation;
        await pumpDialog(
          tester,
          onConfirmed: (_, _, _, _, terrainVariation, __) =>
              gotTerrainVariation = terrainVariation,
        );

        final slider = find.byType(CtSlider);
        await tester.ensureVisible(slider);
        await tester.pumpAndSettle();
        final rect = tester.getRect(slider);
        await tester.tapAt(Offset(rect.right - 1, rect.center.dy));
        await tester.pumpAndSettle();
        await ensureTapStart(tester);
        expect(gotTerrainVariation, closeTo(1.0, 1e-6));
      },
    );

    // Duplicate slot validation feedback contract (#2867 R19).
    //
    // SPEC: `SPEC/ui/new-game-leader-selection-dialog.md`
    // § Duplicate slot validation feedback. Positive AC pins that every
    // duplicate slot's nation `CtDropdown<String>` is wrapped in a keyed
    // `DecoratedBox` painting a 1 dp `EditorialMonoclePalette.danger`
    // border. Negative AC pins the absence of that wrapper when all six
    // slots hold unique ids. Recovery AC pins that swapping a duplicate
    // slot to a previously unused nation unmounts the wrapper and
    // re-enables Start.
    group('Duplicate slot validation feedback (#2867 R19)', () {
      Future<void> pumpDialogWithConfig(
        WidgetTester tester, {
        required GameSetupConfig baseConfig,
        Size surfaceSize = const Size(900, 1600),
        void Function(
          List<String> orderedGreatPowerIds,
          Map<String, String> leaderVariantByGpId,
          int seed,
          bool infiniteMode,
          double terrainVariation,
          Map<String, String?> aiProfileByGpId,
        )?
        onConfirmed,
      }) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = surfaceSize;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.colonial,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      final naming = defaultNamingConfig;
                      final initial = <String, String>{};
                      for (final gpId in baseConfig.selectedGreatPowerIds) {
                        final gp = naming.gpById(gpId);
                        if (gp != null && gp.leaderVariants.isNotEmpty) {
                          initial[gpId] = gp.defaultLeaderVariantId;
                        }
                      }
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => NewGameLeaderSelectionDialog(
                          baseConfig: baseConfig,
                          naming: naming,
                          initialLeaderByGpId: initial,
                          blessedProfileNames: const [],
                          onCancel: () => Navigator.of(ctx).pop(),
                          onConfirmed: onConfirmed ?? (_, _, _, _, _, _) {},
                        ),
                      );
                    },
                    child: const Text('open'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
      }

      bool hasDangerBorder(WidgetTester tester, int slotIndex) {
        final finder = find.byKey(
          ValueKey<String>(
            NewGameLeaderSelectionDialog.duplicateSlotBorderKey(slotIndex),
          ),
        );
        if (finder.evaluate().isEmpty) {
          return false;
        }
        final DecoratedBox box = tester.widget<DecoratedBox>(finder);
        final BoxDecoration decoration = box.decoration as BoxDecoration;
        final BoxBorder? border = decoration.border;
        if (border is! Border) {
          return false;
        }
        return border.top.color == EditorialMonoclePalette.danger &&
            border.top.width ==
                NewGameLeaderSelectionDialog.duplicateSlotBorderWidth;
      }

      testWidgets(
        'positive: two slots sharing England wrap both nation dropdowns in '
        '1 dp --danger DecoratedBox and Start stays disabled',
        (WidgetTester tester) async {
          // Force duplicate by repeating "england" in slots 0 and 5.
          final config = GameSetupConfig(
            selectedGreatPowerIds: const [
              'england',
              'france',
              'spain',
              'portugal',
              'netherlands',
              'england',
            ],
          );

          await pumpDialogWithConfig(tester, baseConfig: config);

          expect(
            hasDangerBorder(tester, 0),
            isTrue,
            reason:
                'Slot 0 holds the duplicate "england" id — its nation '
                'dropdown must be wrapped in the keyed danger border per '
                '#2867 R19.',
          );
          expect(
            hasDangerBorder(tester, 5),
            isTrue,
            reason:
                'Slot 5 also holds the duplicate "england" id — its '
                'nation dropdown must carry the keyed danger border.',
          );
          for (final i in const [1, 2, 3, 4]) {
            expect(
              hasDangerBorder(tester, i),
              isFalse,
              reason: 'Slot $i holds a unique id; no danger border.',
            );
          }

          final Finder startButtonText = find.text('Start');
          await tester.ensureVisible(startButtonText);
          await tester.pumpAndSettle();
          final CtNinePatchButton startButton = tester
              .widget<CtNinePatchButton>(
                find.ancestor(
                  of: startButtonText,
                  matching: find.byType(CtNinePatchButton),
                ),
              );
          expect(
            startButton.enabled,
            isFalse,
            reason:
                'Start must remain disabled while any slot is part of a '
                'duplicate group (mirrors _startEnabled rejecting '
                'duplicates).',
          );
        },
      );

      testWidgets('negative: default config (six unique nations) mounts no '
          'danger-border wrapper under any slot', (WidgetTester tester) async {
        await pumpDialogWithConfig(
          tester,
          baseConfig: GameSetupConfig.defaultConfig,
        );

        for (var i = 0; i < 6; i++) {
          final finder = find.byKey(
            ValueKey<String>(
              NewGameLeaderSelectionDialog.duplicateSlotBorderKey(i),
            ),
          );
          expect(
            finder,
            findsNothing,
            reason:
                'Slot $i: with six unique nations, no slot must carry '
                'the duplicate-border wrapper (negative AC).',
          );
        }
      });

      testWidgets(
        'recovery: replacing the duplicate nation unmounts the wrapper and '
        're-enables Start',
        (WidgetTester tester) async {
          final config = GameSetupConfig(
            selectedGreatPowerIds: const [
              'england',
              'france',
              'spain',
              'portugal',
              'netherlands',
              'england',
            ],
          );

          await pumpDialogWithConfig(tester, baseConfig: config);

          // Confirm initial duplicate borders are present.
          expect(hasDangerBorder(tester, 0), isTrue);
          expect(hasDangerBorder(tester, 5), isTrue);

          // Open slot 5's nation dropdown (the second "England" instance)
          // and pick a previously unused nation. Slot 5's dropdown is the
          // last keyed border wrapper, so its descendant CtDropdown is
          // unambiguous.
          final slot5Border = find.byKey(
            ValueKey<String>(
              NewGameLeaderSelectionDialog.duplicateSlotBorderKey(5),
            ),
          );
          final slot5Dropdown = find.descendant(
            of: slot5Border,
            matching: find.byType(CtDropdown<String>),
          );
          await tester.ensureVisible(slot5Dropdown);
          await tester.pumpAndSettle();
          await tester.tap(slot5Dropdown);
          await tester.pumpAndSettle();

          // Pick "Sweden" — not present in any other slot in this config.
          await tester.tap(find.text('Sweden').last);
          await tester.pumpAndSettle();

          // Both wrappers must now be absent — slot 0's id is unique
          // again and slot 5 holds a fresh unique id.
          for (var i = 0; i < 6; i++) {
            final finder = find.byKey(
              ValueKey<String>(
                NewGameLeaderSelectionDialog.duplicateSlotBorderKey(i),
              ),
            );
            expect(
              finder,
              findsNothing,
              reason:
                  'After resolving the duplicate, no slot must carry the '
                  'duplicate-border wrapper.',
            );
          }

          final CtNinePatchButton startButton = tester
              .widget<CtNinePatchButton>(
                find.ancestor(
                  of: find.text('Start'),
                  matching: find.byType(CtNinePatchButton),
                ),
              );
          expect(
            startButton.enabled,
            isTrue,
            reason:
                'Start must re-enable once every slot holds a unique '
                'non-empty Great Power id (mirrors _startEnabled).',
          );
        },
      );
    });

    // Dark editorial-monocle chrome contract (#2867 S6 / R1 / R2 / R21).
    //
    // Pins the keyed title color + `letterSpacing == fontSize * 0.05`, the
    // single keyed `CtBrassDivider` between title and intro, and the muted
    // italic intro style — mirroring the contract already pinned by the
    // overture (`overture_dialogue_overlay_test.dart`) and intervention
    // (`intervention_dialogue_overlay_dark_chrome_test.dart`) overlays so
    // every #2867 surface enforces the same dark chrome shape.
    group('Dark editorial-monocle chrome (#2867 S6)', () {
      testWidgets(
        'title resolves --accent color and letterSpacing == fontSize * 0.05',
        (WidgetTester tester) async {
          await pumpDialog(tester, onConfirmed: (_, _, _, _, _, _) {});
          final titleFinder = find.byKey(
            const ValueKey<String>('leaderSelectionDialogTitle'),
          );
          expect(titleFinder, findsOneWidget);
          final Text title = tester.widget<Text>(titleFinder);
          expect(title.style?.color, EditorialMonoclePalette.accent);
          final double fontSize = title.style?.fontSize ?? 16;
          expect(
            title.style?.letterSpacing,
            closeTo(fontSize * 0.05, 1e-9),
            reason:
                'letterSpacing must scale with the resolved fontSize so '
                'theme text-scale overrides preserve the canonical 0.05em '
                'ratio (#2867 R2).',
          );
        },
      );

      testWidgets('renders exactly one CtBrassDivider keyed below the title', (
        WidgetTester tester,
      ) async {
        await pumpDialog(tester, onConfirmed: (_, _, _, _, _, _) {});
        final dividerFinder = find.byKey(
          const ValueKey<String>('leaderSelectionDialogBrassDivider'),
        );
        expect(dividerFinder, findsOneWidget);
        expect(find.byType(CtBrassDivider), findsOneWidget);
        final Rect titleRect = tester.getRect(
          find.byKey(const ValueKey<String>('leaderSelectionDialogTitle')),
        );
        final Rect dividerRect = tester.getRect(dividerFinder);
        expect(
          dividerRect.top,
          greaterThanOrEqualTo(titleRect.bottom),
          reason:
              'Brass divider must paint below the title band per '
              '#2867 R21 chrome ordering.',
        );
      });

      testWidgets('intro paints --muted italic body color', (
        WidgetTester tester,
      ) async {
        await pumpDialog(tester, onConfirmed: (_, _, _, _, _, _) {});
        final introFinder = find.byKey(
          const ValueKey<String>('leaderSelectionDialogIntro'),
        );
        expect(introFinder, findsOneWidget);
        final Text intro = tester.widget<Text>(introFinder);
        expect(intro.style?.color, EditorialMonoclePalette.muted);
        expect(intro.style?.fontStyle, FontStyle.italic);
      });

      testWidgets('title does NOT use the raw textTheme.titleMedium color '
          '(regression guard against unstyled headings)', (
        WidgetTester tester,
      ) async {
        await pumpDialog(tester, onConfirmed: (_, _, _, _, _, _) {});
        final Text title = tester.widget<Text>(
          find.byKey(const ValueKey<String>('leaderSelectionDialogTitle')),
        );
        expect(
          title.style?.color,
          isNot(equals(AppThemes.colonial.textTheme.titleMedium?.color)),
          reason:
              'A regression that drops the EditorialMonoclePalette '
              'override would surface the colonial titleMedium color '
              'instead of the canonical --accent token (#2867 R1).',
        );
      });
    });
  });

  // Refs #2870 R3 — narrow slot-row stacking at `< kGameSetupNarrowBreakpoint`
  // (500 dp) per DLG10001 / SPEC/ui/new-game-leader-selection-dialog.md.
  // SPEC: `SPEC/ui/new-game-leader-selection-dialog.md` § Layout / wireframe
  // + § Acceptance Criteria narrow-viewport stacking AC; mirrors
  // `SPEC/ui/mobile-adaptation.md` § 4 Game Setup.
  group('NewGameLeaderSelectionDialog narrow slot stacking', () {
    Future<void> pumpDialogAt(
      WidgetTester tester, {
      required Size surfaceSize,
    }) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.colonial,
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    final base = GameSetupConfig.defaultConfig;
                    final naming = defaultNamingConfig;
                    final initial = <String, String>{};
                    for (final gpId in base.selectedGreatPowerIds) {
                      final gp = naming.gpById(gpId);
                      if (gp != null && gp.leaderVariants.isNotEmpty) {
                        initial[gpId] = gp.defaultLeaderVariantId;
                      }
                    }
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => NewGameLeaderSelectionDialog(
                        baseConfig: base,
                        naming: naming,
                        initialLeaderByGpId: initial,
                        blessedProfileNames: const [],
                        onCancel: () => Navigator.of(ctx).pop(),
                        onConfirmed: (_, _, _, _, _, _) {},
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('wide viewport (>= 500 dp): slot bodies render side-by-side row, '
        'no stacked column body, no exception', (WidgetTester tester) async {
      await pumpDialogAt(tester, surfaceSize: const Size(800, 1300));

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(_kSlotPickersSideBySideRowKey),
        findsNWidgets(6),
        reason:
            'Wide viewport must render one side-by-side row per slot '
            '(SPEC/ui/new-game-leader-selection-dialog.md narrow stacking AC).',
      );
      expect(
        find.byKey(_kSlotPickersStackedColumnKey),
        findsNothing,
        reason:
            'Wide viewport must not mount the stacked column body '
            '(negative AC).',
      );
      expect(
        find.byType(CtDropdown<String>),
        findsAtLeast(12),
        reason: 'Six slot rows × (nation + leader) = 12 dropdowns.',
      );
    });

    testWidgets('narrow viewport (< 500 dp): slot bodies render stacked column, '
        'no side-by-side row body, no exception', (WidgetTester tester) async {
      await pumpDialogAt(tester, surfaceSize: const Size(480, 1300));

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(_kSlotPickersStackedColumnKey),
        findsNWidgets(6),
        reason:
            'Narrow viewport must render one stacked column per slot '
            '(SPEC/ui/new-game-leader-selection-dialog.md narrow stacking AC).',
      );
      expect(
        find.byKey(_kSlotPickersSideBySideRowKey),
        findsNothing,
        reason:
            'Narrow viewport must not mount the side-by-side row body '
            '(negative AC).',
      );
      expect(
        find.byType(CtDropdown<String>),
        findsAtLeast(12),
        reason:
            'Both nation and leader dropdowns still mount in the stacked '
            'layout — six slots × two dropdowns = 12.',
      );
    });

    testWidgets('boundary: viewport exactly at 500 dp uses wide row body '
        '(breakpoint is strict <)', (WidgetTester tester) async {
      await pumpDialogAt(tester, surfaceSize: const Size(500, 1300));

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(_kSlotPickersSideBySideRowKey),
        findsNWidgets(6),
        reason:
            '500 dp is the boundary — kGameSetupNarrowBreakpoint is a '
            'strict less-than check, so 500 dp keeps the wide row body.',
      );
      expect(find.byKey(_kSlotPickersStackedColumnKey), findsNothing);
    });
  });
}
