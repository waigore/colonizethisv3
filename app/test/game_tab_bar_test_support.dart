// Shared GameTabBar pump host for shell chrome widget tests (Refs #4560).

import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/treasury_committed_spend.dart';
import 'package:flutter/material.dart';

import 'app_shell_harness.dart';

/// Hosts [GameTabBar] in a fixed-height [Scaffold] for widget tests.
Widget hostGameTabBar({
  int regionIndex = 0,
  ValueChanged<int>? onRegionIndexChanged,
  int treasury = 12345,
  int? treasuryDelta,
  bool treasuryNotDefined = false,
  List<TreasuryCommittedSpendLine> treasuryCommittedLines =
      const <TreasuryCommittedSpendLine>[],
  String cargoHoldLabel = '3/12',
  int cargoUsed = 3,
  int cargoCapacity = 12,
  bool cargoNotDefined = false,
  bool isCargoUsedReliable = true,
  double width = 600,
  Widget? trailing,
}) {
  return buildAppShell(
    child: Scaffold(
      body: SizedBox(
        width: width,
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GameTabBar(
              regionIndex: regionIndex,
              onRegionIndexChanged: onRegionIndexChanged ?? (_) {},
              oldWorldLabel: 'Old World',
              newWorldLabel: 'New World',
              treasury: treasury,
              treasuryDelta: treasuryDelta,
              treasuryNotDefined: treasuryNotDefined,
              treasuryCommittedLines: treasuryCommittedLines,
              cargoUsed: cargoUsed,
              cargoCapacity: cargoCapacity,
              cargoNotDefined: cargoNotDefined,
              isCargoUsedReliable: isCargoUsedReliable,
              cargoHoldLabel: cargoHoldLabel,
              trailing: trailing ?? const SizedBox(width: 32, height: 32),
            ),
          ],
        ),
      ),
    ),
  );
}
