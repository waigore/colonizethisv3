/// Branch-waterfall pin for `e2eGameStartIntroBlocksUi`.
///
/// The helper drives every adaptive idle wait that touches the game-start
/// intro overlay (Refs GitHub #2336 AC5 / pump-reduction). Three short-circuit
/// branches plus the spinner-precedence rule together decide whether the
/// caller pays an idle pump or proceeds, so each branch needs a dedicated
/// test pin so a later refactor cannot silently break one path while the
/// integration suite still passes via the other paths.
///
/// Branch contract pinned here:
/// 1. `GameStartIntroLoadingIndicator` mounted → returns true (checked first,
///    independent of whether an overlay wraps the indicator).
/// 2. No `GameStartIntroOverlay` mounted and no loading indicator → returns
///    false (fail-fast: nothing blocks the UI).
/// 3. `GameStartIntroOverlay` mounted **with** a `CtDialogShell` descendant
///    (asset-load error path renders the shell) → returns true.
/// 4. `GameStartIntroOverlay` mounted **without** a `CtDialogShell` descendant
///    (initial state before async load completes) → returns false.
library;

import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Asset bundle whose `load` always throws, forcing
/// [GameStartIntroOverlay] into its `_loadError` rendering branch (which
/// mounts a `CtDialogShell` descendant). Required for Branch 3 below — the
/// real bundle would either succeed or be flaky depending on the test
/// runner's asset wiring; an explicit failure bundle keeps the pin
/// deterministic.
class _ThrowingAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('test: asset $key intentionally unavailable');
  }
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'Branch 1 (spinner-precedence): returns true when the loading indicator is mounted '
    'even without a wrapping overlay',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GameStartIntroLoadingIndicator()),
      );
      expect(
        find.byType(GameStartIntroLoadingIndicator),
        findsOneWidget,
        reason: 'precondition: the loading indicator must be mounted',
      );
      expect(
        find.byType(GameStartIntroOverlay),
        findsNothing,
        reason:
            'precondition: this case must verify that the spinner check '
            'runs before the overlay short-circuit; if both checks ran in '
            'the other order, an unmounted overlay would already return '
            'false here and hide the spinner-precedence bug.',
      );
      expect(
        e2eGameStartIntroBlocksUi(tester),
        isTrue,
        reason:
            'Branch 1: a mounted GameStartIntroLoadingIndicator must keep '
            'callers in the adaptive-wait loop regardless of whether the '
            'overlay is also in the tree (#2336 AC5 / pump-reduction).',
      );
    },
  );

  testWidgets(
    'Branch 2 (fail-fast no-overlay): returns false when no overlay '
    'and no loading indicator is mounted',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SizedBox(key: Key('non_intro_tree'))),
      );
      expect(
        find.byType(GameStartIntroLoadingIndicator),
        findsNothing,
        reason: 'precondition: no loading indicator should be mounted',
      );
      expect(
        find.byType(GameStartIntroOverlay),
        findsNothing,
        reason: 'precondition: no overlay should be mounted',
      );
      expect(
        e2eGameStartIntroBlocksUi(tester),
        isFalse,
        reason:
            'Branch 2: when neither the spinner nor the overlay is mounted, '
            'the helper must return false so callers do not pay a pump '
            '(#2336 AC5 short-circuit).',
      );
    },
  );

  testWidgets(
    'Branch 3 (overlay-with-shell): returns true when the overlay mounts a '
    'CtDialogShell descendant via the asset-load error path',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GameStartIntroOverlay(
            onDismissed: () {},
            assetBundle: _ThrowingAssetBundle(),
            child: const SizedBox(key: Key('error_branch_child')),
          ),
        ),
      );
      // Allow the async _loadAndRun to throw and propagate to setState.
      // Two pumps cover the microtask + rebuild boundary deterministically.
      await tester.pump();
      await tester.pump();
      expect(
        find.byType(GameStartIntroOverlay),
        findsOneWidget,
        reason: 'precondition: overlay must be mounted',
      );
      expect(
        find.byType(GameStartIntroLoadingIndicator),
        findsNothing,
        reason:
            'precondition: this branch must exercise the CtDialogShell '
            'short-circuit, not the spinner-precedence branch. If the '
            'loading indicator is found, Branch 1 would already return '
            'true and Branch 3 coverage would be illusory.',
      );
      expect(
        find.descendant(
          of: find.byType(GameStartIntroOverlay),
          matching: find.byType(CtDialogShell),
        ),
        findsOneWidget,
        reason:
            'precondition: the error path must mount a CtDialogShell under '
            'the overlay so the helper has something to match.',
      );
      expect(
        e2eGameStartIntroBlocksUi(tester),
        isTrue,
        reason:
            'Branch 3: an overlay rendering a CtDialogShell (load-error '
            'continue prompt or dialogue shell) must keep callers waiting '
            '(#2336 AC5 / pump-reduction).',
      );
    },
  );

  testWidgets(
    'Branch 4 (overlay-without-shell): returns false when the overlay '
    'has no CtDialogShell descendant yet',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GameStartIntroOverlay(
            onDismissed: () {},
            child: const SizedBox(key: Key('pre_load_child')),
          ),
        ),
      );
      expect(
        find.byType(GameStartIntroOverlay),
        findsOneWidget,
        reason: 'precondition: overlay must be mounted',
      );
      expect(
        find.byType(GameStartIntroLoadingIndicator),
        findsNothing,
        reason:
            'precondition: the spinner-precedence branch must not fire — '
            'the overlay returns just widget.child on its first build, '
            'before _loadAndRun completes.',
      );
      expect(
        find.descendant(
          of: find.byType(GameStartIntroOverlay),
          matching: find.byType(CtDialogShell),
        ),
        findsNothing,
        reason:
            'precondition: no CtDialogShell descendant before async load '
            'completes (the overlay returns widget.child until _view, '
            '_runner, or _loadError is populated).',
      );
      expect(
        e2eGameStartIntroBlocksUi(tester),
        isFalse,
        reason:
            'Branch 4: an overlay that has not yet rendered any dialog '
            'shell must let callers proceed without paying a pump (#2336 '
            'AC5 short-circuit).',
      );
    },
  );

  testWidgets(
    'Order-of-checks invariant: a CtDialogShell mounted **outside** any '
    'GameStartIntroOverlay does not block (the descendant scope matters)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CtDialogShell(child: SizedBox(key: Key('standalone_shell'))),
          ),
        ),
      );
      expect(
        find.byType(CtDialogShell),
        findsOneWidget,
        reason:
            'precondition: a shell is mounted, but it is not a descendant of '
            'any GameStartIntroOverlay — the helper must ignore it.',
      );
      expect(
        find.byType(GameStartIntroOverlay),
        findsNothing,
        reason: 'precondition: no overlay should be mounted',
      );
      expect(
        find.byType(GameStartIntroLoadingIndicator),
        findsNothing,
        reason: 'precondition: no loading indicator should be mounted',
      );
      expect(
        e2eGameStartIntroBlocksUi(tester),
        isFalse,
        reason:
            'A standalone CtDialogShell (e.g. an unrelated dialog) must not '
            'cause the helper to report blocking — the descendant-of-overlay '
            'scope keeps unrelated shells from holding callers in the wait '
            'loop (#2336 AC5).',
      );
    },
  );
}
