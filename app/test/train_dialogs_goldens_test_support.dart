// Train-dialog golden harness helpers (Refs #4352).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_dialog_chrome.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_fixture.dart';
import 'golden_capture_harness.dart';

const Size trainDialogsGoldenHostViewport = Size(420, 900);

Widget trainDialogsGoldenHost({required Key boundaryKey, required Widget child}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    center: false,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: child,
  );
}

class TrainDialogsGoldenFixtures {
  TrainDialogsGoldenFixtures(this.game, this.humanPlayerId);

  final Game game;
  final String humanPlayerId;

  Player player(String pid) => game.players.firstWhere((p) => p.id == pid);

  Game withResources({required int treasury, required int paper}) {
    final p = player(humanPlayerId);
    return game.copyWith(
      players: [
        p.copyWith(
          treasury: treasury,
          stockpile: p.stockpile.merge(
            Stockpile(quantities: {'paper': paper}),
          ),
          capitalProvinceId: p.capitalProvinceId ?? p.capitalTile?.provinceId,
        ),
        ...game.players.where((x) => x.id != humanPlayerId),
      ],
    );
  }

  Game withUnlockedTech({
    required Iterable<String> techIds,
    required int treasury,
    required Map<String, int> stockpile,
  }) {
    final p = player(humanPlayerId);
    final techUnlocked = Map<String, bool>.from(p.techUnlocked ?? {});
    for (final techId in techIds) {
      techUnlocked[techId] = true;
    }
    return game.copyWith(
      players: [
        p.copyWith(
          treasury: treasury,
          workerPool: p.workerPool.copyWith(peasants: 20),
          techUnlocked: techUnlocked,
          stockpile: p.stockpile.merge(Stockpile(quantities: stockpile)),
          capitalProvinceId: p.capitalProvinceId ?? p.capitalTile?.provinceId,
        ),
        ...game.players.where((x) => x.id != humanPlayerId),
      ],
    );
  }

  Game military({int treasury = 10000}) => withUnlockedTech(
        techIds: unlockingTechByRegimentId.values,
        treasury: treasury,
        stockpile: const {
          'fabric': 100,
          'castIron': 100,
          'lumber': 100,
          'horses': 100,
          'steel': 100,
          'bronze': 100,
        },
      );

  Game naval({int treasury = 50000}) => withUnlockedTech(
        techIds: unlockingTechByShipId.values,
        treasury: treasury,
        stockpile: const {
          'lumber': 100,
          'fabric': 100,
          'castIron': 100,
          'coal': 100,
        },
      );
}

Future<void> pumpTrainDialogsGoldenHost(
  WidgetTester tester,
  Widget child,
  Key key,
) async {
  await configureGoldenSurface(tester, size: trainDialogsGoldenHostViewport);
  await tester.pumpWidget(trainDialogsGoldenHost(boundaryKey: key, child: child));
  await pumpForGolden(tester);
}

void expectTrainDialogChromeParity(WidgetTester tester) {
  expect(find.text('×'), findsNothing);
  expect(find.byType(TrainDialogSectionDivider), findsNothing);
  expect(find.byType(TrainDialogResourceBarBox), findsWidgets);
}

int trainDialogsDangerColoredTextCount(WidgetTester tester) {
  return tester.widgetList<Text>(find.byType(Text)).where((t) {
    return t.style?.color == EditorialMonoclePalette.danger;
  }).length;
}

bool trainDialogsHasDangerPlusButton(WidgetTester tester) {
  return tester
      .widgetList<CtNinePatchButton>(
        find.byWidgetPredicate(
          (w) =>
              w is CtNinePatchButton &&
              w.child is Text &&
              (w.child as Text).data == '+',
        ),
      )
      .any((b) => b.dangerVariant);
}

TrainDialogsGoldenFixtures loadTrainDialogsGoldenFixtures() {
  final game = loadSeed42Game();
  final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  return TrainDialogsGoldenFixtures(game, humanPlayerId);
}
