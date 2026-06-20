/// Pins the widget-tree contract of [e2eTryNavalMoveSegment]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The fleet-reach turn loop in `new_game_fleet_reaches_new_world_e2e_test.dart`
/// calls this helper via the AC1 barrel alias `tryNavalMoveSegment` up to
/// `_kMaxNextTurnTapsForNwFleetReach (35)` times per scenario. A silent rename
/// or behavioural drift here would either stall the loop at the per-call
/// [kE2eDefaultNavalMoveSegmentUiWait] cap × 35 turns (Bottleneck 4 / H1–H4 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism) or break the
/// `no_non_home_move_control` / `no_legal_step` short-circuits that keep the
/// bundled-Explore path from burning wall clock on impossible moves.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test layer
/// carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 4 / H1–H4.
library;

// ignore_for_file: deprecated_member_use

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

const String _seaText = 'sea zone 1';

class _MoveButton extends StatelessWidget {
  const _MoveButton({this.onPressedSpy, this.dialogBuilder, this.buttonKey});

  final void Function()? onPressedSpy;
  final Widget Function(BuildContext context)? dialogBuilder;

  /// Stable key for the Move control. Non-home fleets carry the production
  /// [kCtE2EFleetMoveActionKey] so the helper's keyed finder resolves it
  /// (production renders the action icon-only at narrow test-host viewports —
  /// no `Text('Move')` — so it is located by key, Refs #2336). The home fleet
  /// has `onMoveFleet == null` in production and emits no keyed button.
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return TextButton(
          key: buttonKey,
          onPressed: () {
            onPressedSpy?.call();
            showDialog<void>(
              context: context,
              builder: dialogBuilder ??
                  (_) => const AlertDialog(content: Text('Move dialog')),
            );
          },
          child: const Text('Move'),
        );
      },
    );
  }
}

ExpansionTile _fleetTile({
  required String title,
  String? subtitle,
  void Function()? onMovePressed,
  Widget Function(BuildContext context)? dialogBuilder,
}) {
  return ExpansionTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    initiallyExpanded: true,
    children: [
      _MoveButton(
        onPressedSpy: onMovePressed,
        dialogBuilder: dialogBuilder,
        buttonKey: kCtE2EFleetMoveActionKey,
      ),
    ],
  );
}

Widget _navalPanel({required List<Widget> children}) => KeyedSubtree(
  key: kCtE2ENavalPanelRootKey,
  child: Column(children: children),
);

Widget _wrap(Widget body) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: body)));

class _DismissibleSeaDialog extends StatefulWidget {
  const _DismissibleSeaDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_DismissibleSeaDialog> createState() => _DismissibleSeaDialogState();
}

class _DismissibleSeaDialogState extends State<_DismissibleSeaDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        key: kCtE2EMoveFleetDialogScrollRootKey,
        child: RadioListTile<int>(
          title: const Text(_seaText),
          value: 0,
          groupValue: 0,
          onChanged: (_) {},
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.l10n.common_confirm),
        ),
      ],
    );
  }
}

void main() {
  suppressLogsForTests();

  group('e2eTryNavalMoveSegment — early exit branches', () {
    testWidgets('no non-home Move control -> no dialog (naval panel open)', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        _wrap(
          _navalPanel(
            children: [
              ExpansionTile(
                title: const Text('Home Fleet'),
                initiallyExpanded: true,
                children: [_MoveButton(onPressedSpy: () {})],
              ),
            ],
          ),
        ),
      );
      await e2eTryNavalMoveSegment(
        tester,
        l10n,
        navalPanelAlreadyOpen: true,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'no adjacent sea zones message -> Cancel dismisses dialog',
      (tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          _wrap(
            _navalPanel(
              children: [
                _fleetTile(
                  title: 'Fleet 2',
                  subtitle: 'New World — Outer Sea',
                  dialogBuilder: (context) => AlertDialog(
                    content: Text(l10n.moveFleet_noAdjacentSeaZones),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.common_cancel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        await e2eTryNavalMoveSegment(
          tester,
          l10n,
          navalPanelAlreadyOpen: true,
        );
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  });

  group('e2eTryNavalMoveSegment — happy path', () {
    testWidgets(
      'sea-radio move dialog confirmed when panel already open',
      (tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          _wrap(
            _navalPanel(
              children: [
                _fleetTile(
                  title: 'Fleet 2',
                  subtitle: 'New World — Outer Sea',
                  dialogBuilder: (_) => _DismissibleSeaDialog(l10n: l10n),
                ),
              ],
            ),
          ),
        );
        await e2eTryNavalMoveSegment(
          tester,
          l10n,
          navalPanelAlreadyOpen: true,
        );
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'allowWarpDestinations false reaches sea-radio branch on warp+sea dialog',
      (tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          _wrap(
            _navalPanel(
              children: [
                _fleetTile(
                  title: 'Fleet 2',
                  subtitle: 'New World — Outer Sea',
                  dialogBuilder: (_) => AlertDialog(
                    content: SingleChildScrollView(
                      key: kCtE2EMoveFleetDialogScrollRootKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<int>(
                            title: const Text('links to New World'),
                            value: 0,
                            groupValue: null,
                            onChanged: (_) {},
                          ),
                          RadioListTile<int>(
                            title: const Text(_seaText),
                            value: 1,
                            groupValue: null,
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      Builder(
                        builder: (context) => TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.common_confirm),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        Object? caught;
        try {
          await e2eTryNavalMoveSegment(
            tester,
            l10n,
            navalPanelAlreadyOpen: true,
            allowWarpDestinations: false,
            maxUiResponseWait: const Duration(seconds: 10),
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'allowWarpDestinations=false must delegate to the sea-radio '
              'branch without entering the warp drag-probe fail path.',
        );
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  });

  group('e2eTryNavalMoveSegment — perf markers', () {
    testWidgets('records no_non_home_move_control when Move not tapped', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final perf = E2ePerfLog('no_non_home_move');
      await tester.pumpWidget(
        _wrap(
          _navalPanel(
            children: const [Text('loading fleets')],
          ),
        ),
      );
      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        lines.add(message ?? '');
      };
      try {
        await e2eTryNavalMoveSegment(
          tester,
          l10n,
          navalPanelAlreadyOpen: true,
          perf: perf,
        );
      } finally {
        debugPrint = original;
      }
      expect(
        lines.any(
          (line) =>
              line.contains('fleet_move_segment') &&
              line.contains('no_non_home_move_control'),
        ),
        isTrue,
      );
    });

    testWidgets('records no_legal_step when adjacent-sea message shown', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final perf = E2ePerfLog('no_legal_step');
      await tester.pumpWidget(
        _wrap(
          _navalPanel(
            children: [
              _fleetTile(
                title: 'Fleet 2',
                subtitle: 'New World — Outer Sea',
                dialogBuilder: (context) => AlertDialog(
                  content: Text(l10n.moveFleet_noAdjacentSeaZones),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.common_cancel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        lines.add(message ?? '');
      };
      try {
        await e2eTryNavalMoveSegment(
          tester,
          l10n,
          navalPanelAlreadyOpen: true,
          perf: perf,
        );
      } finally {
        debugPrint = original;
      }
      expect(
        lines.any(
          (line) =>
              line.contains('fleet_move_segment') &&
              line.contains('no_legal_step'),
        ),
        isTrue,
      );
    });
  });

  group('e2eTryNavalMoveSegment — default constants', () {
    test('kE2eDefaultNavalMoveSegmentUiWait matches legacy 5 s cap', () {
      expect(
        kE2eDefaultNavalMoveSegmentUiWait,
        const Duration(seconds: 5),
      );
    });
  });
}
