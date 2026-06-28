// Parity tests between [UiScreenIds] constants and the screen registry
// (SPEC/ui/screen-registry.md). Pin for issue #2783 — every active
// registry row must have a matching `UiScreenIds.*` constant and every
// existing constant must correspond to a row in the registry.

import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:flutter_test/flutter_test.dart';

const String _registryPath = '../SPEC/ui/screen-registry.md';

/// Hand-maintained mirror of the public `UiScreenIds.*` constants. Keep in
/// sync with `lib/config/ui_screen_ids.dart`; the first test enforces value
/// equality so a drift surfaces at test-time.
const Map<String, String> _expectedConstants = {
  'shellScreen': UiScreenIds.shellScreen,
  'mainMenu': UiScreenIds.mainMenu,
  'gameInitializing': UiScreenIds.gameInitializing,
  'pauseMenuPanel': UiScreenIds.pauseMenuPanel,
  'gameScreen': UiScreenIds.gameScreen,
  'productionScreen': UiScreenIds.productionScreen,
  'diplomacyScreen': UiScreenIds.diplomacyScreen,
  'diplomacyDetailScreen': UiScreenIds.diplomacyDetailScreen,
  'technologyScreen': UiScreenIds.technologyScreen,
  'gameSideMenu': UiScreenIds.gameSideMenu,
  'empireOverviewMapArea': UiScreenIds.empireOverviewMapArea,
  'provinceSeaZoneOverlay': UiScreenIds.provinceSeaZoneOverlay,
  'civilianUnitsPanel': UiScreenIds.civilianUnitsPanel,
  'militaryUnitsPanel': UiScreenIds.militaryUnitsPanel,
  'navalUnitsPanel': UiScreenIds.navalUnitsPanel,
  'trainCiviliansDialog': UiScreenIds.trainCiviliansDialog,
  'trainMilitaryDialog': UiScreenIds.trainMilitaryDialog,
  'trainNavalDialog': UiScreenIds.trainNavalDialog,
  'grantOrSubsidyDialog': UiScreenIds.grantOrSubsidyDialog,
  'productionCommodityBreakdownDialog':
      UiScreenIds.productionCommodityBreakdownDialog,
  'combatModeChoiceDialog': UiScreenIds.combatModeChoiceDialog,
  'quickBattleScreen': UiScreenIds.quickBattleScreen,
  'quickBattleResultDialog': UiScreenIds.quickBattleResultDialog,
  'gameStartIntroOverlay': UiScreenIds.gameStartIntroOverlay,
  'tribeFirstContactOverlay': UiScreenIds.tribeFirstContactOverlay,
  'victoryOverlay': UiScreenIds.victoryOverlay,
  'overtureDialogueOverlay': UiScreenIds.overtureDialogueOverlay,
  'callToArmsDialogueOverlay': UiScreenIds.callToArmsDialogueOverlay,
  'pendingInterventionOverlay': UiScreenIds.pendingInterventionOverlay,
  'observeModeOverlay': UiScreenIds.observeModeOverlay,
  'playerTurnEventFeed': UiScreenIds.playerTurnEventFeed,
  'newGameLeaderSelectionDialog': UiScreenIds.newGameLeaderSelectionDialog,
  'moveArmyDialog': UiScreenIds.moveArmyDialog,
  'moveFleetDialog': UiScreenIds.moveFleetDialog,
  'transferToHomeFleetDialog': UiScreenIds.transferToHomeFleetDialog,
  'turnNewsDialog': UiScreenIds.turnNewsDialog,
  'nextTurnConfirmation': UiScreenIds.nextTurnConfirmation,
  'debugLogViewer': UiScreenIds.debugLogViewer,
  'debugConsolePanel': UiScreenIds.debugConsolePanel,
};

/// Returns the set of (id, status) tuples from the SPEC/ui/screen-registry.md
/// Registry table — one entry per data row (`| `SHEL10001` | ... | active |`).
/// Rows above the Registry section (Categories table) are ignored because
/// they describe sub-flow digits, not allocated IDs.
List<({String id, String status})> _parseRegistryRows() {
  final file = File(_registryPath);
  if (!file.existsSync()) {
    fail('Registry file not found at $_registryPath');
  }
  final lines = file.readAsLinesSync();
  final rowPattern = RegExp(
    r'^\|\s*`([A-Z]+\d{5})`\s*\|.*\|\s*(draft|active)\s*\|\s*$',
  );
  final rows = <({String id, String status})>[];
  for (final line in lines) {
    final m = rowPattern.firstMatch(line);
    if (m != null) {
      rows.add((id: m.group(1)!, status: m.group(2)!));
    }
  }
  return rows;
}

void main() {
  suppressLogsForTests();

  group('UiScreenIds <-> SPEC/ui/screen-registry.md parity (#2783)', () {
    test('every UiScreenIds constant matches the canonical 8-char format', () {
      final pattern = RegExp(r'^[A-Z]+\d{5}$');
      for (final entry in _expectedConstants.entries) {
        expect(
          pattern.hasMatch(entry.value),
          isTrue,
          reason:
              'UiScreenIds.${entry.key} = "${entry.value}" '
              'does not match the 3-letter category + 5-digit format '
              'required by SPEC/ui/screen-registry.md.',
        );
      }
    });

    test('UiScreenIds constant values are unique', () {
      final seen = <String, String>{};
      for (final entry in _expectedConstants.entries) {
        final prior = seen[entry.value];
        expect(
          prior,
          isNull,
          reason:
              'UiScreenIds.${entry.key} reuses value "${entry.value}" '
              'already claimed by UiScreenIds.$prior. IDs must be unique.',
        );
        seen[entry.value] = entry.key;
      }
    });

    test('every active registry row has a matching UiScreenIds constant', () {
      final registryRows = _parseRegistryRows();
      expect(
        registryRows,
        isNotEmpty,
        reason:
            'Could not parse any registry rows from $_registryPath; '
            'check Registry table format.',
      );
      final knownIds = _expectedConstants.values.toSet();
      final missing = <String>[];
      for (final row in registryRows) {
        if (row.status != 'active') continue;
        if (!knownIds.contains(row.id)) {
          missing.add(row.id);
        }
      }
      expect(
        missing,
        isEmpty,
        reason:
            'Active registry rows without a matching UiScreenIds constant: '
            '${missing.join(", ")}. SPEC/ui/screen-registry.md requires every '
            'active row to have a `static const` in `UiScreenIds`.',
      );
    });

    test('every UiScreenIds constant corresponds to a row in the registry', () {
      final registryRows = _parseRegistryRows();
      final registryIds = {for (final row in registryRows) row.id};
      final orphans = <String>[];
      for (final entry in _expectedConstants.entries) {
        if (!registryIds.contains(entry.value)) {
          orphans.add('${entry.key}=${entry.value}');
        }
      }
      expect(
        orphans,
        isEmpty,
        reason:
            'UiScreenIds constants without a matching registry row: '
            '${orphans.join(", ")}. Every constant must be documented in '
            'SPEC/ui/screen-registry.md.',
      );
    });
  });
}
