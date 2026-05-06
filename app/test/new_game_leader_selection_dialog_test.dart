import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

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
      )
      onConfirmed,
    }) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.colonial,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
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
      await pumpDialog(tester, onConfirmed: (_, _, _) {});

      expect(find.byType(GpDefaultMapColorSwatch), findsNWidgets(6));
      expect(find.text('England'), findsWidgets);
      expect(find.text('New game — Setup'), findsOneWidget);
      expect(find.text('Player 1 (You)'), findsOneWidget);
      expect(find.text('Player 2 (AI)'), findsOneWidget);
      expect(find.text('Player 6 (AI)'), findsOneWidget);
      expect(find.textContaining('Default map colours'), findsOneWidget);
      expect(find.text('Game / world seed'), findsOneWidget);
      expect(find.textContaining('Use 0 for a random world'), findsOneWidget);
    });

    testWidgets(
      'large viewport: six slots visible; single shell vertical scroll only',
      (WidgetTester tester) async {
        await pumpDialog(
          tester,
          surfaceSize: const Size(900, 1600),
          onConfirmed: (_, _, _) {},
        );
        await tester.pumpAndSettle();

        final shell = find.byType(CtDialogShell);
        expect(
          find.descendant(
            of: shell,
            matching: find.byType(CustomScrollView),
          ),
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
        onConfirmed: (_, _, _) {},
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

      await pumpDialog(
        tester,
        onConfirmed: (ids, leaders, seed) {
          gotIds = ids;
          gotLeaders = leaders;
          gotSeed = seed;
        },
      );

      await ensureTapStart(tester);

      expect(gotIds, GameSetupConfig.defaultConfig.selectedGreatPowerIds);
      expect(gotLeaders, isNotNull);
      expect(gotLeaders!.length, 6);
      expect(gotLeaders!['england'], 'queen_victoria');
      expect(gotSeed, 42);
    });

    testWidgets('Cancel closes dialog without calling onConfirmed', (
      WidgetTester tester,
    ) async {
      var confirmed = false;
      await pumpDialog(
        tester,
        onConfirmed: (_, _, _) {
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
        onConfirmed: (ids, leaders, _) {
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
      await pumpDialog(tester, onConfirmed: (_, _, s) => gotSeed = s);
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
      await pumpDialog(tester, onConfirmed: (_, _, s) => gotSeed = s);
      final field = find.byType(TextField);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, '');
      await tester.pump();
      await ensureTapStart(tester);
      expect(gotSeed, 42);
    });
  });
}
