// Naval panel tile/split/combine interaction helpers (Refs #4352 Slice D).
// SPEC: SPEC/ui/naval-units-panel.md; SPEC/program/repo-lint.md.

import 'dart:async';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'naval_units_panel_wire_helpers.dart';

/// ExpansionTile finder for a fleet row label.
Finder navalFleetTileFinder(String label) =>
    find.widgetWithText(ExpansionTile, label);

Future<void> expandNavalFleetTile(
  WidgetTester tester,
  Finder fleetFinder,
) async {
  await tester.ensureVisible(fleetFinder);
  await tester.tap(fleetFinder);
  await tester.pumpAndSettle();
}

/// Wired locate bus + captured [LocateMapTileEvent] list (Refs #4021 densify).
(AppEventBus bus, List<LocateMapTileEvent> events) wireNavalLocateCaptureBus() {
  final events = <LocateMapTileEvent>[];
  final bus = AppEventBus.create();
  bus.on<LocateMapTileEvent>().listen(events.add);
  return (bus, events);
}

Future<bool> tapLocateOnNavalFleetTile(
  WidgetTester tester,
  Finder fleetTile,
) async {
  await tester.ensureVisible(fleetTile);
  final locateFinder = find.descendant(
    of: fleetTile,
    matching: find.byTooltip('Locate fleet'),
  );
  if (locateFinder.evaluate().isEmpty) return false;
  await tester.ensureVisible(locateFinder.first);
  await tester.tap(locateFinder.first, warnIfMissed: false);
  await tester.pumpAndSettle();
  return true;
}

Future<void> expandAndTapNavalSplit(
  WidgetTester tester,
  Finder fleetFinder,
) async {
  await expandNavalFleetTile(tester, fleetFinder);
  final splitButton = find.descendant(
    of: fleetFinder,
    matching: find.byTooltip('Split'),
  );
  expect(splitButton, findsOneWidget);
  await tester.tap(splitButton);
  await tester.pumpAndSettle();
}

Future<void> expandAndExpectNavalSplit(
  WidgetTester tester,
  Finder fleetFinder,
) async {
  await expandNavalFleetTile(tester, fleetFinder);
  expect(
    find.descendant(of: fleetFinder, matching: find.byTooltip('Split')),
    findsOneWidget,
  );
}

Future<void> confirmNavalSplitMovingFirstShip(
  WidgetTester tester,
  Fleet targetFleet,
) async {
  final moveTypeId = targetFleet.ships.first.typeId;
  await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne(moveTypeId)));
  await tester.pumpAndSettle();
  final confirmSplit = find.text('Confirm Split');
  expect(confirmSplit, findsOneWidget);
  await tester.tap(confirmSplit);
  await tester.pumpAndSettle();
}

(AppEventBus, NavalFleetsUpdatedEvent? Function()) wireNavalFleetBusWithWire({
  required StreamSubscription<dynamic> Function(AppEventBus bus) wire,
}) {
  NavalFleetsUpdatedEvent? updated;
  final bus = AppEventBus.create();
  addTearDown(
    bus.on<NavalFleetsUpdatedEvent>().listen((e) {
      updated = e;
    }).cancel,
  );
  addTearDown(wire(bus).cancel);
  return (bus, () => updated);
}

(AppEventBus, NavalFleetsUpdatedEvent? Function()) wireNavalSplitUpdatedBus({
  required Game Function() gameSnapshot,
}) => wireNavalFleetBusWithWire(
  wire: (bus) =>
      wireNavalSplitForWidgetTest(bus: bus, gameSnapshot: gameSnapshot),
);

(AppEventBus, NavalFleetsUpdatedEvent? Function())
wireNavalFleetsUpdatedCapture() {
  NavalFleetsUpdatedEvent? updated;
  final bus = AppEventBus.create();
  final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) => updated = e);
  addTearDown(sub.cancel);
  return (bus, () => updated);
}

Future<void> tapNavalFleetCheckboxes(
  WidgetTester tester,
  Iterable<String> fleetLabels, {
  bool scroll = false,
}) async {
  for (final label in fleetLabels) {
    late final Finder cb;
    if (scroll) {
      final title = find.text(label);
      await tester.scrollUntilVisible(title, 120);
      await tester.pumpAndSettle();
      final tile = find.ancestor(
        of: title,
        matching: find.byType(ExpansionTile),
      );
      cb = find.descendant(of: tile, matching: find.byType(Checkbox));
      await tester.scrollUntilVisible(cb, 120);
      await tester.pumpAndSettle();
    } else {
      final tile = find.widgetWithText(ExpansionTile, label);
      expect(tile, findsOneWidget);
      cb = find.descendant(of: tile, matching: find.byType(Checkbox));
    }
    await tester.ensureVisible(cb);
    await tester.tap(cb);
    await tester.pumpAndSettle();
  }
}

void expectNavalCombineEnabled(WidgetTester tester, {required bool enabled}) {
  expect(
    tester
        .widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, 'Combine'),
        )
        .enabled,
    enabled,
  );
}
