/// Pins the widget-tree contract of [e2eDismissCtDialogShellIfPresent]
/// (`app/integration_test/e2e_test_shared_dismiss_ct_dialog_shell.dart`).
///
/// The full-turn E2E scenario in `new_game_full_turn_e2e_test.dart` calls
/// this helper exactly once after [e2eAttemptFirstFleetMoveOrCancel] to
/// dismiss any [CtDialogShell] that the optional move-confirm phase may
/// have left mounted. A silent rename or behavioural drift here would
/// either:
///
///   - Drop the localized close candidates ([common_cancel] /
///     [common_close]) in favour of the hardcoded English strings used by
///     the broad-spectrum [e2eDismissTransientUi] sweep — masking a
///     locale regression in the integration suite; or
///   - Stall the test for the default 3 s
///     `pump_until_shell_closed_after_close_candidate` cap when the shell
///     fails to unmount after a tap — inflating the wall-clock budget
///     issue #2336 is reducing.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
library;

import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

class _ShellHost extends StatefulWidget {
  const _ShellHost({required this.builder});

  /// Builds the dialog contents; receives a [close] callback the inner
  /// widgets can invoke from their `onPressed` callbacks to unmount the
  /// shell. Avoids tester.state hops inside button taps that would
  /// otherwise add lookup noise unrelated to the helper contract.
  final Widget Function(BuildContext context, VoidCallback close) builder;

  @override
  State<_ShellHost> createState() => _ShellHostState();
}

class _ShellHostState extends State<_ShellHost> {
  bool open = true;

  void _close() {
    setState(() => open = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return const SizedBox.shrink();
    }
    return CtDialogShell(
      child: widget.builder(context, _close),
    );
  }
}

Widget _wrap(Widget body) =>
    MaterialApp(home: Scaffold(body: Center(child: body)));

void main() {
  suppressLogsForTests();

  group('e2eDismissCtDialogShellIfPresent — no shell branch', () {
    testWidgets('returns false without tapping when no CtDialogShell mounted', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          TextButton(
            onPressed: () => taps++,
            child: Text(l10n.common_cancel),
          ),
        ),
      );

      final dismissed = await e2eDismissCtDialogShellIfPresent(tester, l10n);

      expect(
        dismissed,
        isFalse,
        reason:
            'Helper must short-circuit and return false when no CtDialogShell '
            'is mounted; otherwise a stray Cancel button elsewhere in the '
            'tree would be tapped between phases.',
      );
      expect(taps, 0, reason: 'No tap should fire when the shell is absent.');
    });
  });

  group('e2eDismissCtDialogShellIfPresent — Cancel candidate branch', () {
    testWidgets(
      'taps localized Cancel and pumps until the shell unmounts (returns true)',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          _wrap(
            _ShellHost(
              builder: (context, close) => TextButton(
                onPressed: close,
                child: Text(l10n.common_cancel),
              ),
            ),
          ),
        );
        expect(find.byType(CtDialogShell), findsOneWidget);

        final dismissed = await e2eDismissCtDialogShellIfPresent(tester, l10n);

        expect(
          dismissed,
          isTrue,
          reason:
              'Helper must report dismissal when the first close candidate is '
              'tapped and the shell unmounts within the pump budget.',
        );
        expect(find.byType(CtDialogShell), findsNothing);
      },
    );

    testWidgets('prefers Cancel over Close when both candidates are mounted', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      var cancelTaps = 0;
      var closeTaps = 0;
      await tester.pumpWidget(
        _wrap(
          _ShellHost(
            builder: (context, close) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  key: const ValueKey('candidate-cancel'),
                  onPressed: () {
                    cancelTaps++;
                    close();
                  },
                  child: Text(l10n.common_cancel),
                ),
                TextButton(
                  key: const ValueKey('candidate-close'),
                  onPressed: () => closeTaps++,
                  child: Text(l10n.common_close),
                ),
              ],
            ),
          ),
        ),
      );

      final dismissed = await e2eDismissCtDialogShellIfPresent(tester, l10n);

      expect(dismissed, isTrue);
      expect(
        cancelTaps,
        1,
        reason:
            'Cancel must be tapped before Close when both candidates are '
            'hit-testable (priority order in the close-candidate list).',
      );
      expect(
        closeTaps,
        0,
        reason:
            'Close must NOT be tapped when Cancel resolves first; a '
            'regression that fell through would tap two buttons per call.',
      );
    });
  });

  group('e2eDismissCtDialogShellIfPresent — Close fallback branch', () {
    testWidgets('taps localized Close when Cancel is absent', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      var closeTaps = 0;
      await tester.pumpWidget(
        _wrap(
          _ShellHost(
            builder: (context, close) => TextButton(
              key: const ValueKey('candidate-close-only'),
              onPressed: () {
                closeTaps++;
                close();
              },
              child: Text(l10n.common_close),
            ),
          ),
        ),
      );

      final dismissed = await e2eDismissCtDialogShellIfPresent(tester, l10n);

      expect(dismissed, isTrue);
      expect(closeTaps, 1);
      expect(find.byType(CtDialogShell), findsNothing);
    });
  });

  group('e2eDismissCtDialogShellIfPresent — close-icon fallback branch', () {
    testWidgets(
      'taps Icons.close when neither Cancel nor Close text is present',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        var iconTaps = 0;
        await tester.pumpWidget(
          _wrap(
            _ShellHost(
              builder: (context, close) => IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  iconTaps++;
                  close();
                },
              ),
            ),
          ),
        );

        final dismissed = await e2eDismissCtDialogShellIfPresent(tester, l10n);

        expect(dismissed, isTrue);
        expect(iconTaps, 1);
      },
    );
  });

  group('e2eDismissCtDialogShellIfPresent — no candidate branch', () {
    testWidgets(
      'returns false and leaves the shell mounted when no close candidate is '
      'hit-testable',
      (WidgetTester tester) async {
        // Helper intentionally avoids handlePopRoute / arrow_back fallbacks —
        // those belong to the broad e2eDismissTransientUi sweep. Pin guards
        // against a regression that silently adds them here and changes the
        // contract for callers that need single-purpose semantics.
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          _wrap(
            _ShellHost(
              builder: (context, close) => const Text('Nothing tappable'),
            ),
          ),
        );
        expect(find.byType(CtDialogShell), findsOneWidget);

        final dismissed = await e2eDismissCtDialogShellIfPresent(tester, l10n);

        expect(
          dismissed,
          isFalse,
          reason:
              'When no close candidate is hit-testable the helper must report '
              'false so callers can decide whether to fall back to '
              'e2eDismissTransientUi or fail-fast.',
        );
        expect(
          find.byType(CtDialogShell),
          findsOneWidget,
          reason:
              'Without a Cancel / Close / Icons.close path the helper must '
              'leave the shell mounted — the caller is responsible for the '
              'broader handlePopRoute fallback.',
        );
      },
    );
  });

  group('e2eDismissCtDialogShellIfPresent — perf wiring', () {
    testWidgets(
      'forwards the default phase label through e2ePumpUntil so wall-clock '
      'attribution sees the legacy phase step',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        final perf = E2ePerfLog('dismiss_shell_phase');
        await tester.pumpWidget(
          _wrap(
            _ShellHost(
              builder: (context, close) => TextButton(
                onPressed: close,
                child: Text(l10n.common_cancel),
              ),
            ),
          ),
        );

        final lines = <String>[];
        final original = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          lines.add(message ?? '');
        };
        try {
          await e2eDismissCtDialogShellIfPresent(tester, l10n, perf: perf);
        } finally {
          debugPrint = original;
        }

        expect(
          lines.any(
            (l) =>
                l.startsWith('E2E_TIMING') &&
                l.contains('phase=$kE2eDefaultCtDialogShellClosePhase'),
          ),
          isTrue,
          reason:
              'Default phase label must equal '
              'kE2eDefaultCtDialogShellClosePhase so existing log scrapers '
              'continue to attribute the wait under the legacy step name.',
        );
      },
    );
  });

  group('e2eDismissCtDialogShellIfPresent — default constants', () {
    test('kE2eDefaultCtDialogShellCloseTimeout matches legacy 3 s budget', () {
      expect(
        kE2eDefaultCtDialogShellCloseTimeout,
        const Duration(seconds: 3),
        reason:
            'A silent budget bump would change wall-clock guarantees for '
            'every call site that relies on the default; require an explicit '
            'override at the call site instead. Refs GitHub #2336 / AC4.',
      );
    });

    test(
      'kE2eDefaultCtDialogShellClosePhase preserves the legacy E2E_TIMING phase',
      () {
        expect(
          kE2eDefaultCtDialogShellClosePhase,
          'pump_until_shell_closed_after_close_candidate',
          reason:
              'Phase string is consumed verbatim by log scrapers and dashboards '
              'that survived the inline → shared lift; renaming it would '
              'orphan downstream attribution.',
        );
      },
    );
  });
}
