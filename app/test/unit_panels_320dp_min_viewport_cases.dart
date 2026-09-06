// 320 dp unit-panel viewport pin harness (Refs #4734 Slice E, #2870).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'min_viewport_harness.dart';

const kUnitPanels320MinViewport = Size(kMinViewportWidth, 640);
const kUnitPanels320WideViewport = Size(1024, 768);

Future<void> pumpUnitPanelAt320(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  await pumpAtMinViewport(
    tester,
    size: size,
    child: Scaffold(body: child),
    settle: true,
  );
}

Widget buildUnitPanels320Civilian({
  required Game game,
  required String humanPlayerId,
}) {
  return CivilianUnitsPanel(
    game: game,
    humanPlayerId: humanPlayerId,
    bus: AppEventBus.create(),
  );
}

Widget buildUnitPanels320Military({
  required Game game,
  required String humanPlayerId,
}) {
  return MilitaryUnitsPanel(
    game: game,
    humanPlayerId: humanPlayerId,
    bus: AppEventBus.create(),
    topology: const MapTopology(),
    draftOrders: const Orders(),
  );
}

Widget buildUnitPanels320Naval({
  required Game game,
  required String humanPlayerId,
  required MapTopology topology,
}) {
  return NavalUnitsPanel(
    game: game,
    humanPlayerId: humanPlayerId,
    bus: AppEventBus.create(),
    topology: topology,
  );
}

typedef UnitPanel320Case = ({
  String groupLabel,
  String positiveName,
  String negativeName,
  String title,
  String overflowReason,
  Widget Function({
    required Game game,
    required String humanPlayerId,
    required MapTopology topology,
  }) buildPanel,
});

List<UnitPanel320Case> unitPanels320Cases() => [
      (
        groupLabel: 'SPEC/ui/mobile-adaptation.md § 7 — CivilianUnitsPanel @ 320 dp '
            '(Refs #2870 S10)',
        positiveName: 'AC (positive) CivilianUnitsPanel @ 320×640: no RenderFlex '
            'overflow exception, "Civilian Units" title renders',
        negativeName: 'Negative control: CivilianUnitsPanel @ 1024×768 also pumps '
            'without exception (regression sentinel for the overflow '
            'contract — keeps the 320 dp positive pin meaningful)',
        title: 'Civilian Units',
        overflowReason:
            'SPEC/ui/mobile-adaptation.md § 7: CivilianUnitsPanel must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The UnitsPanelShell chrome '
            '(CtTopBar + ListView) and per-unit UnitsEntityActionRow '
            'must fit within the 304 dp content column inside the '
            'shell padding without overflowing.',
        buildPanel: ({required game, required humanPlayerId, required topology}) =>
            buildUnitPanels320Civilian(
              game: game,
              humanPlayerId: humanPlayerId,
            ),
      ),
      (
        groupLabel: 'SPEC/ui/mobile-adaptation.md § 7 — MilitaryUnitsPanel @ 320 dp '
            '(Refs #2870 S10)',
        positiveName: 'AC (positive) MilitaryUnitsPanel @ 320×640: no RenderFlex '
            'overflow exception, "Military Units" title renders',
        negativeName: 'Negative control: MilitaryUnitsPanel @ 1024×768 also pumps '
            'without exception (regression sentinel for the overflow '
            'contract)',
        title: 'Military Units',
        overflowReason:
            'SPEC/ui/mobile-adaptation.md § 7: MilitaryUnitsPanel must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The UnitsPanelShell chrome '
            '(CtTopBar + ListView), Army ExpansionTile rows, and per-'
            'army UnitsEntityActionRow must fit within the 304 dp '
            'content column inside the shell padding without '
            'overflowing.',
        buildPanel: ({required game, required humanPlayerId, required topology}) =>
            buildUnitPanels320Military(
              game: game,
              humanPlayerId: humanPlayerId,
            ),
      ),
      (
        groupLabel: 'SPEC/ui/mobile-adaptation.md § 7 — NavalUnitsPanel @ 320 dp '
            '(Refs #2870 S10)',
        positiveName: 'AC (positive) NavalUnitsPanel @ 320×640: no RenderFlex '
            'overflow exception, "Naval Units" title renders',
        negativeName: 'Negative control: NavalUnitsPanel @ 1024×768 also pumps without '
            'exception (regression sentinel for the overflow contract — keeps '
            'the 320 dp positive pin meaningful)',
        title: 'Naval Units',
        overflowReason:
            'SPEC/ui/mobile-adaptation.md § 7: NavalUnitsPanel must not '
            'emit a RenderFlex overflow exception at kMinViewportWidth '
            '(320 dp). The UnitsPanelShell chrome (CtTopBar with header '
            'Combine + select-all checkbox + ListView), Fleet '
            'ExpansionTile rows, and per-fleet UnitsEntityActionRow '
            'must fit within the 304 dp content column inside the '
            'shell padding without overflowing.',
        buildPanel: ({required game, required humanPlayerId, required topology}) =>
            buildUnitPanels320Naval(
              game: game,
              humanPlayerId: humanPlayerId,
              topology: topology,
            ),
      ),
    ];
