library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class NewWorldRegionTabHost extends StatefulWidget {
  const NewWorldRegionTabHost({this.initialSelected = false});

  /// Initial value for the underlying [CtChoiceChip] `selected` flag — the
  /// short-circuit pin tests pre-select the chip so the helper's
  /// already-selected branch fires without going through an extra tap.
  final bool initialSelected;

  @override
  State<NewWorldRegionTabHost> createState() => NewWorldRegionTabHostState();
}

class NewWorldRegionTabHostState extends State<NewWorldRegionTabHost> {
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
class OldWorldRegionTabHost extends StatefulWidget {
  const OldWorldRegionTabHost({
    required this.label,
    this.initialSelected = false,
  });

  final String label;

  /// Initial value for the underlying [CtChoiceChip] `selected` flag — the
  /// short-circuit pin tests pre-select the chip so the helper's
  /// already-selected branch fires without going through an extra tap.
  final bool initialSelected;

  @override
  State<OldWorldRegionTabHost> createState() => OldWorldRegionTabHostState();
}

class OldWorldRegionTabHostState extends State<OldWorldRegionTabHost> {
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

Future<void> pumpScaffold(WidgetTester tester, Widget body) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: body)),
  );
}


