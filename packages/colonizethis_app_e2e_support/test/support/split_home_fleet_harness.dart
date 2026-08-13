// Shared split-fleet dialog harness for `e2e_split_home_fleet_test.dart`
// (#4344 Slice C densify).
library;

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String kMoveOneTransferKey = 'ctTransfer.left.>';
const String kMoveAllTransferKey = 'ctTransfer.left.>>';

/// Controller a test pumps through to inspect helper behaviour without
/// coupling to fleet model state. Tracks total nudge taps, surfaces
/// confirm-tap signals, and gates dialog dismissal.
class SplitHarnessController extends ChangeNotifier {
  SplitHarnessController({
    required this.nudgesUntilConfirm,
    this.includeMoveAll = true,
  });

  /// Number of left-transfer button taps required before
  /// `splitFleet_confirm` becomes enabled.
  final int nudgesUntilConfirm;

  /// Whether the harness exposes the `>>` move-all button alongside the
  /// `>` move-one button. When false the helper must fall back to the
  /// single-nudge button.
  final bool includeMoveAll;

  int nudgeCount = 0;
  int moveAllTaps = 0;
  int moveOneTaps = 0;
  int confirmTaps = 0;
  bool dialogVisible = false;

  bool get confirmEnabled => nudgeCount >= nudgesUntilConfirm;

  void openDialog() {
    dialogVisible = true;
    notifyListeners();
  }

  void registerMoveAll() {
    moveAllTaps += 1;
    nudgeCount += 1;
    notifyListeners();
  }

  void registerMoveOne() {
    moveOneTaps += 1;
    nudgeCount += 1;
    notifyListeners();
  }

  void registerConfirm() {
    confirmTaps += 1;
    dialogVisible = false;
    notifyListeners();
  }
}

class SplitHarness extends StatefulWidget {
  const SplitHarness({
    super.key,
    required this.controller,
    required this.l10n,
    this.includeExpansionTile = false,
  });

  final SplitHarnessController controller;
  final AppLocalizations l10n;

  /// Whether to render a collapsed `ExpansionTile` inside the naval-panel
  /// subtree so the trailing `e2eExpandEachExpansionTileOnce` step has
  /// something to act on.
  final bool includeExpansionTile;

  @override
  State<SplitHarness> createState() => _SplitHarnessState();
}

class _SplitHarnessState extends State<SplitHarness> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final l10n = widget.l10n;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          KeyedSubtree(
            key: kCtE2ENavalPanelRootKey,
            child: ListView(
              children: <Widget>[
                if (widget.includeExpansionTile)
                  const ExpansionTile(
                    initiallyExpanded: false,
                    title: Text('Home Fleet'),
                    children: <Widget>[Text('Carrack')],
                  ),
                TextButton(
                  onPressed: controller.openDialog,
                  child: const Text('Split'),
                ),
              ],
            ),
          ),
          if (controller.dialogVisible)
            Positioned.fill(
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: CtDialogShell(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(l10n.splitFleet_dialogTitle),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            if (widget.controller.includeMoveAll)
                              CtNinePatchButton(
                                key: const ValueKey<String>(
                                  kMoveAllTransferKey,
                                ),
                                onPressed: controller.registerMoveAll,
                                child: const Text('>>'),
                              ),
                            CtNinePatchButton(
                              key: const ValueKey<String>(kMoveOneTransferKey),
                              onPressed: controller.registerMoveOne,
                              child: const Text('>'),
                            ),
                          ],
                        ),
                        CtNinePatchButton(
                          enabled: controller.confirmEnabled,
                          onPressed: controller.registerConfirm,
                          child: Text(l10n.splitFleet_confirm),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> pumpSplitHarness(
  WidgetTester tester, {
  required SplitHarnessController controller,
  required AppLocalizations l10n,
  bool includeExpansionTile = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SplitHarness(
        controller: controller,
        l10n: l10n,
        includeExpansionTile: includeExpansionTile,
      ),
    ),
  );
}
