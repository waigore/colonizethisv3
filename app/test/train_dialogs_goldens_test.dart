// Widget goldens for the train-dialog visual acceptance criteria of issue
// #3568 (align Train Civilians dialog `UNIT40001` and the shared
// `TrainDialogChrome` — incl. Train Military `UNIT50001` — to the canonical
// mockup). PR #3569 landed the formatting/layout/styling and text-content
// assertions; these pixel baselines close the remaining UI verification gap by
// mapping the *visual* ACs (boxed inset resource bar, row geometry,
// `£`+comma glyphs, deficit-hint colour) to golden PNGs under
// `app/test/goldens/`.
//
// Harness mirrors the committed golden pattern
// (`diplomacy_panel_goldens_test.dart`, `unit_panels_goldens_test.dart`): a
// keyed `RepaintBoundary` wraps each dialog, deterministic
// `getDebugInitGameResult()` fixtures (seed 42) pin the content, and
// `AppThemes.editorialMonocle` supplies the dark-theme chrome
// (`colonizethis-ui-design.mdc`). Each golden is paired with structural finder
// assertions so the baseline keeps mapping to its AC rather than silently
// drifting.
//
//  - AC1 (£+comma treasury) / AC3 (name-over-cost + stepper-right row) /
//    AC4 (boxed inset resource bar, monospace bold values): civilian default.
//  - AC5 (both-resource deficit `Treasury low and Paper low` in danger colour):
//    civilian deficit.
//  - AC6 (military £+comma + shared restyled resource bar): military default.
//
// SPEC: SPEC/ui/train-civilians-dialog.md (`UNIT40001`),
// SPEC/ui/components/train-dialog-chrome.md, SPEC/ui/train-military-dialog.md.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_dialog_chrome.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canonical golden host viewport for the train dialogs (tall enough to render
/// the header, resource bar, and the first unit rows without the scroll body
/// clipping the chrome under test).
const Size _hostViewport = Size(420, 900);

int _argb(Color c) {
  final int a = (c.a * 255.0).round() & 0xFF;
  final int r = (c.r * 255.0).round() & 0xFF;
  final int g = (c.g * 255.0).round() & 0xFF;
  final int b = (c.b * 255.0).round() & 0xFF;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

void _expectEditorialMonocleDarkChrome(WidgetTester tester) {
  final BuildContext ctx = tester.element(find.byType(Scaffold).first);
  final ThemeData theme = Theme.of(ctx);
  expect(theme.brightness, Brightness.dark);
  expect(
    _argb(theme.colorScheme.primary),
    _argb(EditorialMonoclePalette.accent),
    reason: 'Train dialogs must render under the editorial-monocle dark theme',
  );
}

Widget _host({required Key boundaryKey, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      backgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
      body: RepaintBoundary(key: boundaryKey, child: child),
    ),
  );
}

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    game = getDebugInitGameResult().game;
    humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  });

  Player getPlayer(String pid) => game.players.firstWhere((p) => p.id == pid);

  Game gameWithResources({required int treasury, required int paper}) {
    final player = getPlayer(humanPlayerId);
    return game.copyWith(
      players: [
        player.copyWith(
          treasury: treasury,
          stockpile: player.stockpile.merge(
            Stockpile(quantities: {'paper': paper}),
          ),
          capitalProvinceId:
              player.capitalProvinceId ?? player.capitalTile?.provinceId,
        ),
        ...game.players.where((p) => p.id != humanPlayerId),
      ],
    );
  }

  Game militaryGameWithResources() {
    final player = getPlayer(humanPlayerId);
    final techUnlocked = Map<String, bool>.from(player.techUnlocked ?? {});
    for (final techId in unlockingTechByRegimentId.values) {
      techUnlocked[techId] = true;
    }
    return game.copyWith(
      players: [
        player.copyWith(
          treasury: 10000,
          workerPool: player.workerPool.copyWith(peasants: 20),
          techUnlocked: techUnlocked,
          stockpile: player.stockpile.merge(
            const Stockpile(
              quantities: {
                'fabric': 100,
                'castIron': 100,
                'lumber': 100,
                'horses': 100,
                'steel': 100,
                'bronze': 100,
              },
            ),
          ),
          capitalProvinceId:
              player.capitalProvinceId ?? player.capitalTile?.provinceId,
        ),
        ...game.players.where((p) => p.id != humanPlayerId),
      ],
    );
  }

  Future<void> pumpHost(WidgetTester tester, Widget child, Key key) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(_hostViewport);
    await tester.pumpWidget(_host(boundaryKey: key, child: child));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'golden: UNIT40001 Train Civilians dialog — £+comma treasury, boxed '
    'resource bar, name-over-cost rows (Refs #3568 AC1/AC3/AC4)',
    (WidgetTester tester) async {
      const key = ValueKey<String>('train_civilians_dialog_golden');
      final richGame = gameWithResources(treasury: 5000, paper: 12);
      await pumpHost(
        tester,
        TrainCiviliansDialog(
          game: richGame,
          humanPlayerId: humanPlayerId,
          currentOrders: const Orders(),
          bus: AppEventBus.create(),
        ),
        key,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TrainCiviliansDialog), findsOneWidget);
      _expectEditorialMonocleDarkChrome(tester);
      // AC1: £ + comma grouping, no `k` abbreviation.
      expect(find.textContaining('£5,000'), findsOneWidget);
      expect(find.textContaining('5k'), findsNothing);
      // AC4: boxed inset resource bar present.
      expect(find.byType(TrainDialogResourceBarBox), findsWidgets);

      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/train_civilians_dialog_default.png'),
      );
    },
  );

  testWidgets(
    'golden: UNIT40001 Train Civilians dialog — both-resource deficit hint '
    '"Treasury low and Paper low" (Refs #3568 AC5)',
    (WidgetTester tester) async {
      const key = ValueKey<String>('train_civilians_dialog_deficit_golden');
      final player = getPlayer(humanPlayerId);
      final capital =
          player.capitalProvinceId ?? player.capitalTile?.provinceId;
      expect(capital, isNotNull, reason: 'debug game needs capital');
      // Two queued Builders (2,000 treasury, 4 paper) exceed both resources.
      final limitedPlayer = player.copyWith(
        treasury: 1500,
        stockpile: const Stockpile(quantities: {'paper': 3}),
        capitalProvinceId: capital,
      );
      final limitedGame = game.copyWith(
        players: [
          limitedPlayer,
          ...game.players.where((p) => p.id != humanPlayerId),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          humanPlayerId: [
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary: false,
              spawnProvinceId: capital!,
            ),
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary: false,
              spawnProvinceId: capital,
            ),
          ],
        },
      );

      await pumpHost(
        tester,
        TrainCiviliansDialog(
          game: limitedGame,
          humanPlayerId: humanPlayerId,
          currentOrders: orders,
          bus: AppEventBus.create(),
        ),
        key,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Treasury low and Paper low'), findsOneWidget);

      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/train_civilians_dialog_deficit.png'),
      );
    },
  );

  testWidgets(
    'golden: UNIT50001 Train Military dialog — £+comma treasury + shared '
    'restyled resource bar (Refs #3568 AC6)',
    (WidgetTester tester) async {
      const key = ValueKey<String>('train_military_dialog_golden');
      final richGame = militaryGameWithResources();
      await pumpHost(
        tester,
        TrainMilitaryDialog(
          game: richGame,
          humanPlayerId: humanPlayerId,
          currentOrders: const Orders(),
          bus: AppEventBus.create(),
        ),
        key,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TrainMilitaryDialog), findsOneWidget);
      _expectEditorialMonocleDarkChrome(tester);
      // AC6: shared £+comma treasury and the boxed inset resource bar.
      expect(find.textContaining('£10,000'), findsOneWidget);
      expect(find.byType(TrainDialogResourceBarBox), findsWidgets);

      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/train_military_dialog_default.png'),
      );
    },
  );
}
