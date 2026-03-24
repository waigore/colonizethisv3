import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/l10n/app_localizations.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

void main() {
  suppressLogsForTests();

  group('NewGameLeaderSelectionDialog', () {
    Future<void> pumpDialog(
      WidgetTester tester, {
      required void Function(
        List<String> orderedGreatPowerIds,
        Map<String, String> leaderVariantByGpId,
        bool enforceFairGpOldWorldAssignment,
      ) onConfirmed,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.colonial,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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

    testWidgets('shows six GP colour swatches and default nation labels',
        (WidgetTester tester) async {
      await pumpDialog(tester, onConfirmed: (_, __, ___) {});

      expect(find.byType(GpDefaultMapColorSwatch), findsNWidgets(6));
      expect(find.text('England'), findsWidgets);
      expect(find.text('New game — Setup'), findsOneWidget);
      expect(find.text('Player 1 (You)'), findsOneWidget);
      expect(find.text('Player 2 (AI)'), findsOneWidget);
      expect(find.text('Player 6 (AI)'), findsOneWidget);
      expect(
        find.textContaining('Default map colours'),
        findsOneWidget,
      );
    });

    testWidgets('Start passes default ordered Great Power ids and leader map',
        (WidgetTester tester) async {
      List<String>? gotIds;
      Map<String, String>? gotLeaders;
      bool? gotFair;

      await pumpDialog(
        tester,
        onConfirmed: (ids, leaders, fair) {
          gotIds = ids;
          gotLeaders = leaders;
          gotFair = fair;
        },
      );

      final startButton = find.ancestor(
        of: find.text('Start'),
        matching: find.byType(CtNinePatchButton),
      );
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(
        gotIds,
        GameSetupConfig.defaultConfig.selectedGreatPowerIds,
      );
      expect(gotLeaders, isNotNull);
      expect(gotLeaders!.length, 6);
      expect(gotLeaders!['england'], 'queen_victoria');
      expect(gotFair, isFalse);
    });

    testWidgets('Cancel closes dialog without calling onConfirmed',
        (WidgetTester tester) async {
      var confirmed = false;
      await pumpDialog(
        tester,
        onConfirmed: (_, __, ___) {
          confirmed = true;
        },
      );

      final cancelButton = find.ancestor(
        of: find.text('Cancel'),
        matching: find.byType(CtNinePatchButton),
      );
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
      expect(find.text('New game — Setup'), findsNothing);
    });

    testWidgets('Start passes enforceFairGpOldWorldAssignment when checkbox toggled',
        (WidgetTester tester) async {
      bool? gotFair;
      await pumpDialog(
        tester,
        onConfirmed: (_, __, fair) {
          gotFair = fair;
        },
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final startButton = find.ancestor(
        of: find.text('Start'),
        matching: find.byType(CtNinePatchButton),
      );
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(gotFair, isTrue);
    });

    testWidgets('changing slot 1 nation to Sweden updates order and leader',
        (WidgetTester tester) async {
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

      final startButton = find.ancestor(
        of: find.text('Start'),
        matching: find.byType(CtNinePatchButton),
      );
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(gotIds, isNotNull);
      expect(gotIds!.first, 'sweden');
      expect(gotLeaders, isNotNull);
      expect(gotLeaders!['sweden'], 'gustavus');
    });
  });
}
