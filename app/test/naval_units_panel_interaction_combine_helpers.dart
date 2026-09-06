// Naval panel combine/transfer interaction helpers (Refs #4352 Slice D).
// SPEC: SPEC/ui/naval-units-panel.md; SPEC/program/repo-lint.md.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'naval_panel_combine_outcome_helpers.dart';
import 'naval_panel_combine_tables.dart';
import 'naval_units_panel_host_helpers.dart';
import 'naval_units_panel_interaction_tile_helpers.dart';
import 'naval_units_panel_wire_helpers.dart';

Future<void> tapNavalConfirmTransfer(
  WidgetTester tester, {
  String? moveAllTypeId,
  String? moveOneTypeId,
}) async {
  if (moveAllTypeId != null) {
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll(moveAllTypeId)));
    await tester.pumpAndSettle();
  } else if (moveOneTypeId != null) {
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne(moveOneTypeId)));
    await tester.pumpAndSettle();
  }
  final confirmTransfer = find.widgetWithText(CtNinePatchButton, 'Transfer');
  expect(confirmTransfer, findsOneWidget);
  final confirmTransferButton = tester.widget<CtNinePatchButton>(
    confirmTransfer,
  );
  expect(confirmTransferButton.enabled, isTrue);
  expect(confirmTransferButton.onPressed, isNotNull);
  confirmTransferButton.onPressed!.call();
  await tester.pumpAndSettle();
}

Future<NavalFleetsUpdatedEvent?> pumpNavalHomeFleetTransferAll(
  WidgetTester tester, {
  required Game game,
  required String humanId,
  required List<String> fleetLabels,
  required String transferTypeId,
}) async {
  final (bus, updated) = wireNavalFleetsUpdatedCapture();
  final subTransfer = wireNavalTransferForWidgetTest(
    bus: bus,
    gameSnapshot: () => game,
  );
  addTearDown(subTransfer.cancel);
  await pumpNavalPanel(tester, game: game, humanPlayerId: humanId, bus: bus);
  await tapNavalFleetCheckboxes(tester, fleetLabels);
  await tapNavalCombine(tester);
  expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
  await tapNavalConfirmTransfer(tester, moveAllTypeId: transferTypeId);
  return updated();
}

void expectNavalCombineOutcome(
  NavalFleetsUpdatedEvent? updated,
  NavalPanelCombineOutcomeCase case_,
) {
  expect(updated, isNotNull);
  final fleetsAfter = updated!.game.worldState.fleets;
  if (case_.expectedFleetCount != null) {
    expect(fleetsAfter.length, case_.expectedFleetCount);
  }
  final survivor = fleetsAfter.firstWhere(
    (f) => f.id == case_.expectedSurvivorId,
  );
  final shipIds = survivor.ships.map((s) => s.id).toList()..sort();
  final expected = [...case_.expectedShipIds]..sort();
  expect(shipIds, expected);
  expect(survivor.mission, case_.expectedSurvivorMission);
}

Future<void> tapNavalCombine(WidgetTester tester, {bool scroll = false}) async {
  final combineFinder = find.widgetWithText(CtActionTextButton, 'Combine');
  if (scroll) {
    await tester.scrollUntilVisible(combineFinder, 120);
    await tester.pumpAndSettle();
  } else {
    await tester.ensureVisible(combineFinder);
  }
  await tester.tap(combineFinder);
  await tester.pumpAndSettle();
}

Future<void> pumpNavalCheckCombineDisabled(
  WidgetTester tester, {
  required Game game,
  required String humanId,
  required List<String> fleetLabels,
  MapTopology topology = const MapTopology(),
}) async {
  await pumpNavalPanel(
    tester,
    game: game,
    humanPlayerId: humanId,
    topology: topology,
  );
  await tapNavalFleetCheckboxes(tester, fleetLabels);
  expectNavalCombineEnabled(tester, enabled: false);
}

Future<NavalFleetsUpdatedEvent?> pumpNavalTapCheckCombine(
  WidgetTester tester, {
  required Game game,
  required String humanId,
  required List<String> labels,
  bool scroll = false,
  bool? expectCombineEnabled,
}) async {
  final (bus, latest) = wireNavalFleetsUpdatedCapture();
  await pumpNavalPanel(tester, game: game, humanPlayerId: humanId, bus: bus);
  await tapNavalFleetCheckboxes(tester, labels, scroll: scroll);
  if (expectCombineEnabled != null) {
    expectNavalCombineEnabled(tester, enabled: expectCombineEnabled);
  }
  await tapNavalCombine(tester, scroll: scroll);
  return latest();
}

Future<void> pumpNavalCombineOutcomeCase(
  WidgetTester tester,
  NavalPanelCombineOutcomeCase case_,
) async {
  if (case_.pinCollapsedSplitToolbar) {
    final (bus, latest) = wireNavalFleetsUpdatedCapture();
    await pumpNavalPanel(
      tester,
      game: case_.build(),
      humanPlayerId: case_.humanId,
      bus: bus,
    );
    final tileA = find.widgetWithText(ExpansionTile, 'Fleet col_a');
    final tileB = find.widgetWithText(ExpansionTile, 'Fleet col_b');
    for (final tile in [tileA, tileB]) {
      expect(
        find.descendant(of: tile, matching: find.byTooltip('Split')),
        findsOneWidget,
      );
    }
    await tapNavalFleetCheckboxes(tester, case_.labels);
    expect(
      find.descendant(of: tileA, matching: find.byTooltip('Split')),
      findsOneWidget,
    );
    await tapNavalCombine(tester);
    expectNavalCombineOutcome(latest(), case_);
    return;
  }
  final updated = await pumpNavalTapCheckCombine(
    tester,
    game: case_.build(),
    humanId: case_.humanId,
    labels: case_.labels,
    scroll: case_.scroll,
    expectCombineEnabled: case_.expectCombineEnabled,
  );
  expectNavalCombineOutcome(updated, case_);
}
