// Attempt-first-fleet-move-specific dialog fixtures for
// `e2e_attempt_first_fleet_move_or_cancel_test.dart` (#4344 Slice C
// densify). These mirror the production `MoveFleetDialog` shape closely
// enough to drive the helper's confirmed / cancelled branches but are not
// reused by the sibling naval-move suites, unlike `naval_fleet_move_
// harness.dart`.
library;

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the production `MoveFleetDialog`, which renders as a
/// [CtDialogShell] (a Material `Dialog`, not an `AlertDialog`) with no
/// `RadioListTile` destinations — so the helper's keyed dialog wait and
/// empty-destinations cancel branch exercise the real widget shape.
WidgetBuilder emptyRadiosDialogBuilder(AppLocalizations l10n) {
  return (context) => CtDialogShell(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No destinations available.'),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
      ],
    ),
  );
}

/// Sea-zone destination-pick dialog fixture with `RadioListTile<dynamic>`
/// rows (exact-type match target for the helper's finder) and a Confirm
/// action.
class SeaPickHost extends StatefulWidget {
  const SeaPickHost({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  State<SeaPickHost> createState() => SeaPickHostState();
}

class SeaPickHostState extends State<SeaPickHost> {
  dynamic selected;
  int taps = 0;
  bool dialogOpen = true;

  @override
  Widget build(BuildContext context) {
    if (!dialogOpen) {
      return const SizedBox.shrink();
    }
    // Build `RadioListTile<dynamic>` explicitly so the helper's
    // `find.byType(RadioListTile<dynamic>)` (exact-type match per Flutter
    // Finder semantics) actually resolves the radios and the confirmed
    // branch can be exercised. The production `MoveFleetDialog` instead
    // renders custom `_MoveFleetDestinationRow` widgets (no `RadioListTile`),
    // so this finder is empty against the real dialog and the helper always
    // takes the cancel branch. Refs the "Legacy quirk preserved" note on
    // `e2eAttemptFirstFleetMoveOrCancel`.
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<dynamic>(
                  title: const Text('sea zone 1'),
                  value: 0,
                  groupValue: selected,
                  onChanged: (next) {
                    taps++;
                    setState(() => selected = next);
                  },
                ),
                RadioListTile<dynamic>(
                  title: const Text('sea zone 2'),
                  value: 1,
                  groupValue: selected,
                  onChanged: (next) {
                    taps++;
                    setState(() => selected = next);
                  },
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => dialogOpen = false),
            child: Text(widget.l10n.common_confirm),
          ),
        ],
      ),
    );
  }
}

Future<SeaPickHostState> pumpSeaPickDialogStandalone(
  WidgetTester tester, {
  required AppLocalizations l10n,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: SeaPickHost(l10n: l10n)),
      ),
    ),
  );
  return tester.state<SeaPickHostState>(find.byType(SeaPickHost));
}
