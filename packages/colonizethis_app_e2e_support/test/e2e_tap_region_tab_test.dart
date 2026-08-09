/// Pins the **tap-and-settle** contract of `e2eTapNewWorldRegionTabIfPresent`
/// and `e2eTapOldWorldRegionTab` (`app/integration_test/e2e_test_shared.dart`),
/// including the **already-selected short-circuit** that skips the tap +
/// post-tap settle when the corresponding chip is already selected.
///
/// Both helpers were lifted from
/// `new_game_fleet_reaches_new_world_e2e_helpers.dart` so the
/// `kCtE2ERegionTabNewWorldKey` and `CtChoiceChip + region_oldWorld` tap
/// contracts are shared, canonical, and unit-pinned at the widget layer
/// (Refs GitHub #2336 AC1 / AC2 / AC5). They sit on the fleet-reach hot path
/// (`_tryNavalMoveSegment`, `_awaitNwCoastalOrVisibleLandForBundledExploreE2e`)
/// inside the `_kMaxNextTurnTapsForNwFleetReach = 35` turn loop, so a silent
/// regression — for example dropping the `.hitTestable()` guard, throwing on
/// timeout, skipping the chip-selected poll, or dropping the
/// already-selected short-circuit — would regress the wall-clock-bound paths
/// #2336 is shrinking. The short-circuit in particular removes the redundant
/// tap + 500ms-bounded post-tap settle that would otherwise fire on every
/// fleet-reach turn iteration after the first call selects the NW chip.
///
/// Because `integration_test/` runs behind a no-op `app_e2e_linux` lane today
/// (`SPEC/program/e2e-integration-tests.md` § CI), these widget-test pins are
/// the only per-PR enforcement gate for the tap contracts. The existing
/// `e2e_region_chip_selected_test.dart` pins the **predicate** branches of the
/// `e2eOldWorldRegionChipAppearsSelected` / `e2eNewWorldRegionChipAppearsSelected`
/// helpers; this file pins the **tap-and-poll wrappers** that compose them.
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

/// Toggling host for a single [CtChoiceChip] wrapped in a [KeyedSubtree] with
/// the [kCtE2ERegionTabNewWorldKey] so `find.byKey(...).hitTestable()` resolves
/// and an `onSelected` flip drives [e2eNewWorldRegionChipAppearsSelected] true.

part 'support/tap_region_tab_nw_part.dart';
part 'support/tap_region_tab_ow_part.dart';

class _NewWorldRegionTabHost extends StatefulWidget {
  const _NewWorldRegionTabHost({this.initialSelected = false});

  /// Initial value for the underlying [CtChoiceChip] `selected` flag — the
  /// short-circuit pin tests pre-select the chip so the helper's
  /// already-selected branch fires without going through an extra tap.
  final bool initialSelected;

  @override
  State<_NewWorldRegionTabHost> createState() => _NewWorldRegionTabHostState();
}

class _NewWorldRegionTabHostState extends State<_NewWorldRegionTabHost> {
  late bool selected = widget.initialSelected;
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: kCtE2ERegionTabNewWorldKey,
      child: CtChoiceChip(
        label: const Text('New World'),
        selected: selected,
        onSelected: (next) {
          taps++;
          setState(() => selected = next);
        },
      ),
    );
  }
}

/// Toggling host for a single Old World [CtChoiceChip] (no keyed subtree —
/// `e2eTapOldWorldRegionTab` matches by label text via `widgetWithText`).
class _OldWorldRegionTabHost extends StatefulWidget {
  const _OldWorldRegionTabHost({
    required this.label,
    this.initialSelected = false,
  });

  final String label;

  /// Initial value for the underlying [CtChoiceChip] `selected` flag — the
  /// short-circuit pin tests pre-select the chip so the helper's
  /// already-selected branch fires without going through an extra tap.
  final bool initialSelected;

  @override
  State<_OldWorldRegionTabHost> createState() => _OldWorldRegionTabHostState();
}

class _OldWorldRegionTabHostState extends State<_OldWorldRegionTabHost> {
  late bool selected = widget.initialSelected;
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return CtChoiceChip(
      label: Text(widget.label),
      selected: selected,
      onSelected: (next) {
        taps++;
        setState(() => selected = next);
      },
    );
  }
}

Future<void> _pumpScaffold(WidgetTester tester, Widget body) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: body)),
  );
}


void main() {
  suppressLogsForTests();
  registerTapRegionTabNwGroup();
  registerTapRegionTabOwGroup();
}
