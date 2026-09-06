// 320 dp train-dialog viewport pin scenario table (Refs #4734 Slice E, #2870).

import 'package:colonizethis_app/features/game/widgets/train/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_naval_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'dialogs_320dp_min_viewport_support.dart';

const kTrainDialogs320MinViewport = kDialogs320MinViewport;
const kTrainDialogs320WideViewport = kDialogs320WideRegressionViewport;

typedef TrainDialog320Case = ({
  String groupLabel,
  String positiveName,
  String negativeName,
  String title,
  String overflowReason,
  Widget Function({
    required Game game,
    required String humanPlayerId,
  }) buildDialog,
});

List<TrainDialog320Case> trainDialogs320Cases() => [
      (
        groupLabel: 'SPEC/ui/mobile-adaptation.md § 7 — TrainCiviliansDialog @ 320 dp '
            '(Refs #2870 S8/S10)',
        positiveName: 'AC (positive) TrainCiviliansDialog @ 320×640: no RenderFlex '
            'overflow exception, "Train Civilians" title + Reset action render',
        negativeName: 'Negative control: TrainCiviliansDialog @ 1024×768 also pumps '
            'without exception (regression sentinel for the overflow '
            'contract — keeps the 320 dp positive pin meaningful)',
        title: 'Train Civilians',
        overflowReason:
            'SPEC/ui/mobile-adaptation.md § 7: TrainCiviliansDialog must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The CtDialogShell chrome — '
            'TrainDialogHeader (Cinzel accent title + 32 dp close ×), '
            'the Wrap-based TrainDialogResourceBar (Treasury + Paper '
            'lines), the per-civilian-unit rows '
            '(`builder`, `farmer`, `craftsman`, `paperMaker`, '
            '`bookbinder`, `clerk`) with name + cost header + +/- '
            'stepper, and the trailing right-aligned Reset action — '
            'must all fit within the ~288 dp CtDialogShell content '
            'column at 320 dp.',
        buildDialog: ({required game, required humanPlayerId}) =>
            TrainCiviliansDialog(
              game: game,
              humanPlayerId: humanPlayerId,
              currentOrders: const Orders(),
              bus: AppEventBus.create(),
            ),
      ),
      (
        groupLabel: 'SPEC/ui/mobile-adaptation.md § 7 — TrainMilitaryDialog @ 320 dp '
            '(Refs #2870 S8/S10)',
        positiveName: 'AC (positive) TrainMilitaryDialog @ 320×640: no RenderFlex '
            'overflow exception, "Train Military" title + Reset action render',
        negativeName: 'Negative control: TrainMilitaryDialog @ 1024×768 also pumps '
            'without exception (regression sentinel for the overflow '
            'contract — keeps the 320 dp positive pin meaningful)',
        title: 'Train Military',
        overflowReason:
            'SPEC/ui/mobile-adaptation.md § 7: TrainMilitaryDialog must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The CtDialogShell chrome — '
            'TrainDialogHeader, the Wrap-based military resource bar '
            '(Treasury + Peasants + six commodity chips: fabric, '
            'castIron, lumber, horses, steel, bronze), the per-regiment '
            'rows with name + cost header + +/- stepper, and the '
            'trailing right-aligned Reset action — must all wrap '
            'within the ~288 dp CtDialogShell content column at '
            '320 dp. The military resource Wrap (more chips than the '
            'civilian dialog) must flow onto extra runs without '
            'overflowing horizontally.',
        buildDialog: ({required game, required humanPlayerId}) =>
            TrainMilitaryDialog(
              game: game,
              humanPlayerId: humanPlayerId,
              currentOrders: const Orders(),
              bus: AppEventBus.create(),
            ),
      ),
      (
        groupLabel: 'SPEC/ui/mobile-adaptation.md § 7 — TrainNavalDialog @ 320 dp '
            '(Refs #3601 S15 / #2870 S8/S10)',
        positiveName: 'AC (positive) TrainNavalDialog @ 320×640: no RenderFlex '
            'overflow exception, "Train Naval" title + Reset action render',
        negativeName: 'Negative control: TrainNavalDialog @ 1024×768 also pumps '
            'without exception (regression sentinel for the overflow '
            'contract — keeps the 320 dp positive pin meaningful)',
        title: 'Train Naval',
        overflowReason:
            'SPEC/ui/mobile-adaptation.md § 7: TrainNavalDialog must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The CtDialogShell chrome — '
            'TrainDialogHeader, the Wrap-based naval resource bar '
            '(Treasury + Peasants + four commodity chips: lumber, '
            'fabric, castIron, coal), the per-ship rows with name + '
            'cost header + +/- stepper, and the trailing right-aligned '
            'Reset action — must all wrap within the ~288 dp '
            'CtDialogShell content column at 320 dp.',
        buildDialog: ({required game, required humanPlayerId}) =>
            TrainNavalDialog(
              game: game,
              humanPlayerId: humanPlayerId,
              currentOrders: const Orders(),
              bus: AppEventBus.create(),
            ),
      ),
    ];

String trainDialogs320HumanPlayerId(Game game) {
  return game.players.firstWhere((p) => p.isHuman).id;
}
