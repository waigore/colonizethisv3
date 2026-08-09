// Shared WidgetTester host for `e2e_pick_move_destination_and_confirm_test`
// (Slice C / AC5 additional family of #4075).
//
// Extracts the MoveFleetDialog-shaped AlertDialog fixture and pump helpers
// so the suite keeps behavioural axes only.
//
// The production move-fleet dialog constructs `RadioListTile<_MovePick>` with
// the legacy `groupValue` / `onChanged` API; fixtures must match that shape.
// ignore_for_file: deprecated_member_use
//
// Refs #4075.

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Warp row text under English locale — matches
/// `l10n.moveFleet_warpLinkToRegion(regionDisplayLabel('newWorld'))`.
const String kMoveDialogWarpText = 'links to New World';

/// Sea-zone destination row label distinct from the warp text.
const String kMoveDialogSeaText = 'sea zone 1';

/// Test-only host that renders a `MoveFleetDialog`-shaped [AlertDialog].
class MoveDialogHost extends StatefulWidget {
  const MoveDialogHost({
    super.key,
    required this.l10n,
    required this.includeWarp,
    this.includeSea = true,
    this.withScrollKey = true,
    this.warpAheadFillers = 0,
    this.scrollPhysics,
    this.includeScrollable = true,
    this.wrapWarpInIgnorePointer = false,
  });

  final AppLocalizations l10n;
  final bool includeWarp;
  final bool includeSea;
  final bool withScrollKey;

  /// When > 0, inserts that many tall filler rows BEFORE the warp row.
  final int warpAheadFillers;

  final ScrollPhysics? scrollPhysics;
  final bool includeScrollable;
  final bool wrapWarpInIgnorePointer;

  @override
  State<MoveDialogHost> createState() => MoveDialogHostState();
}

class MoveDialogHostState extends State<MoveDialogHost> {
  int? selectedRowIndex;
  int taps = 0;
  bool dialogOpen = true;

  @override
  Widget build(BuildContext context) {
    if (!dialogOpen) {
      return const SizedBox.shrink();
    }
    final rows = <Widget>[];
    var nextIndex = 0;
    for (var i = 0; i < widget.warpAheadFillers; i++) {
      rows.add(
        SizedBox(
          height: 200,
          child: Center(child: Text('filler-$i')),
        ),
      );
    }
    if (widget.includeWarp) {
      final warpIndex = nextIndex++;
      final Widget warpTile = RadioListTile<int>(
        key: const ValueKey('warp-tile'),
        title: const Text(kMoveDialogWarpText),
        value: warpIndex,
        groupValue: selectedRowIndex,
        onChanged: (next) {
          taps++;
          setState(() => selectedRowIndex = next);
        },
      );
      rows.add(
        widget.wrapWarpInIgnorePointer
            ? IgnorePointer(child: warpTile)
            : warpTile,
      );
    }
    if (widget.includeSea) {
      final seaIndex = nextIndex++;
      rows.add(
        RadioListTile<int>(
          key: const ValueKey('sea-tile'),
          title: const Text(kMoveDialogSeaText),
          value: seaIndex,
          groupValue: selectedRowIndex,
          onChanged: (next) {
            taps++;
            setState(() => selectedRowIndex = next);
          },
        ),
      );
    }
    final Widget content;
    if (widget.includeScrollable) {
      content = SingleChildScrollView(
        key: widget.withScrollKey ? kCtE2EMoveFleetDialogScrollRootKey : null,
        physics: widget.scrollPhysics,
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      );
    } else {
      content = Column(mainAxisSize: MainAxisSize.min, children: rows);
    }
    return AlertDialog(
      content: SizedBox(
        width: 320,
        height: 240,
        child: content,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            setState(() => dialogOpen = false);
          },
          child: Text(widget.l10n.common_confirm),
        ),
      ],
    );
  }

  String? get selectedKind {
    final i = selectedRowIndex;
    if (i == null) {
      return null;
    }
    var nextIndex = 0;
    if (widget.includeWarp) {
      if (i == nextIndex) {
        return 'warp';
      }
      nextIndex++;
    }
    if (widget.includeSea) {
      if (i == nextIndex) {
        return 'sea';
      }
    }
    return null;
  }
}

Future<void> pumpMoveDialogScaffold(
  WidgetTester tester, {
  required Widget child,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    ),
  );
}

/// Counter for unique [MoveDialogHost] keys so each [pumpMoveDialog] call
/// mounts a fresh State.
int _moveDialogHostKeyCounter = 0;

Future<MoveDialogHostState> pumpMoveDialog(
  WidgetTester tester, {
  required AppLocalizations l10n,
  required bool includeWarp,
  bool includeSea = true,
  bool withScrollKey = true,
  int warpAheadFillers = 0,
  ScrollPhysics? scrollPhysics,
  bool includeScrollable = true,
  bool wrapWarpInIgnorePointer = false,
}) async {
  _moveDialogHostKeyCounter++;
  final hostKey = ValueKey<int>(_moveDialogHostKeyCounter);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: MoveDialogHost(
                key: hostKey,
                l10n: l10n,
                includeWarp: includeWarp,
                includeSea: includeSea,
                withScrollKey: withScrollKey,
                warpAheadFillers: warpAheadFillers,
                scrollPhysics: scrollPhysics,
                includeScrollable: includeScrollable,
                wrapWarpInIgnorePointer: wrapWarpInIgnorePointer,
              ),
            );
          },
        ),
      ),
    ),
  );
  return tester.state<MoveDialogHostState>(find.byType(MoveDialogHost));
}
