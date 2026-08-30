// Synthetic civilian-panel host for assign-row pins (#4598 leftover host SoT).
library;

import 'package:colonizethis_app/config/themes.dart' show AppThemes;
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart'
    show CivilianUnitRowCard;
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart'
    show UnitsEntityAction;
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_widget_pump_harness.dart';

/// One row spec for [AssignCivilianRowPanelHost].
class AssignCivilianRowSpec {
  const AssignCivilianRowSpec({required this.title, required this.hasAssign});

  final String title;
  final bool hasAssign;
}

/// Hosts [CivilianUnitRowCard] rows under the civilian panel root key.
class AssignCivilianRowPanelHost extends StatefulWidget {
  const AssignCivilianRowPanelHost({super.key, required this.rows});

  final List<AssignCivilianRowSpec> rows;

  @override
  State<AssignCivilianRowPanelHost> createState() =>
      AssignCivilianRowPanelHostState();
}

class AssignCivilianRowPanelHostState
    extends State<AssignCivilianRowPanelHost> {
  /// Index of the row whose `Assign` was tapped. `-1` means no tap yet.
  int tappedRowIndex = -1;

  @override
  Widget build(BuildContext context) {
    return wrapE2eApp(
      Scaffold(
        body: Container(
          key: kCtE2ECivilianPanelRootKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < widget.rows.length; i++)
                      CivilianUnitRowCard(
                        details: Text(widget.rows[i].title),
                        selected: false,
                        onTap: () {},
                        actions: widget.rows[i].hasAssign
                            ? [
                                UnitsEntityAction(
                                  tooltip: 'Assign',
                                  icon: Icons.add,
                                  label: 'Assign',
                                  onPressed: () {
                                    setState(() {
                                      tappedRowIndex = i;
                                    });
                                  },
                                ),
                              ]
                            : const <UnitsEntityAction>[],
                      ),
                  ],
                ),
              ),
              if (tappedRowIndex >= 0) const Text('Build improvement'),
            ],
          ),
        ),
      ),
      theme: AppThemes.editorialMonocle,
    );
  }
}

int assignCivilianRowTappedIndex(WidgetTester tester) {
  final stateFinder = find.byType(AssignCivilianRowPanelHost);
  if (stateFinder.evaluate().isEmpty) {
    return -1;
  }
  return tester
      .state<AssignCivilianRowPanelHostState>(stateFinder)
      .tappedRowIndex;
}
