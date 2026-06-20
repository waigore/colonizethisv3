/// Widget-test coverage for `e2eOpenerTapTriggerAndAwaitMount`, the shared
/// inner `tryOpen` recipe that `e2eOpenCivilianPanel` and
/// `e2eOpenNavalPanel` both invoke from their outer adaptive-poll loop.
///
/// Before this lift each of the two panel openers inlined the same
/// three-step closure ("fast already-hit-testable short-circuit →
/// [e2eEnsureVisibleAndTapHitTestable] defensive tap → bounded
/// [e2eAwaitPanelMountAfterOpenerTap] mount probe") with per-opener
/// panel-root finders and `pump_until_<panel>_panel_after_trigger_tap`
/// phase labels. A regression that diverged either opener — for example
/// dropping the pre-tap `panelRoot.hitTestable()` short-circuit on naval
/// while keeping it on civilian — would surface only as a wall-clock
/// regression in the integration suite, but the `app_e2e_linux` lane is
/// a no-op per `SPEC/program/e2e-integration-tests.md` § CI, so the
/// widget-test layer carries the behavioural pins for the AC1 "single
/// canonical shared helper" and AC10 "no silent flakiness from off-screen
/// trigger drops" contracts.
///
/// Refs GitHub #2336 (AC1 — shared helpers; AC2 — single canonical
/// implementation; AC10 — no silent flakiness from timeout regressions).
library;

import 'dart:async';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';

const _kTriggerKey = ValueKey<String>('e2e_ottam_trigger');
const _kPanelKey = ValueKey<String>('e2e_ottam_panel');

class _TapCounter {
  int value = 0;
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'e2eOpenerTapTriggerAndAwaitMount returns true synchronously without '
    'tapping when the panel root is already hit-testable',
    (WidgetTester tester) async {
      // Mount the panel root before the helper runs so the immediate
      // `panelRoot.hitTestable().evaluate().isNotEmpty` short-circuit
      // fires. The fast-path matches the pre-lift inline civilian/naval
      // recipe, which is critical for the post-sheet-close iteration
      // where the panel can already be rebuilt before the opener loop
      // reaches its rail-tap arm.
      final counter = _TapCounter();
      await tester.pumpWidget(
        _TriggerAndPanelHarness(counter, panelMounted: true),
      );
      final result = await e2eOpenerTapTriggerAndAwaitMount(
        tester,
        trigger: find.byKey(_kTriggerKey),
        panelRoot: find.byKey(_kPanelKey),
        mountTimeout: const Duration(seconds: 3),
        mountPhaseName: 'pin_panel_already_hit_testable',
      );
      expect(
        result,
        isTrue,
        reason:
            'Already-hit-testable panel root must report true so the outer '
            'opener loop short-circuits without paying any pump cycles or '
            'firing a stray rail/marker tap (Refs GitHub #2336 AC1 / AC5).',
      );
      expect(
        counter.value,
        0,
        reason:
            'Helper must NOT tap the trigger when the panel is already '
            'hit-testable; a regression that always tapped first would '
            'dismiss the already-mounted panel on every outer-loop '
            'iteration after a sheet close (Refs GitHub #2336 AC10).',
      );
    },
  );

  testWidgets(
    'e2eOpenerTapTriggerAndAwaitMount returns false without tapping when '
    'the trigger finder resolves to zero elements',
    (WidgetTester tester) async {
      // No trigger and no panel are mounted, so the helper's fast-path
      // panel check fails; it then asks
      // [e2eEnsureVisibleAndTapHitTestable] to tap a finder that resolves
      // to nothing and must report `false` so the outer opener loop can
      // retry the rail/marker arm on the next iteration. A regression
      // that promoted the empty-trigger branch into a `fail()` call would
      // hard-stop every panel opener whose rail/marker is briefly absent
      // (typical during route transitions).
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final result = await e2eOpenerTapTriggerAndAwaitMount(
        tester,
        trigger: find.byKey(_kTriggerKey),
        panelRoot: find.byKey(_kPanelKey),
        mountTimeout: const Duration(seconds: 3),
        mountPhaseName: 'pin_trigger_absent',
      );
      expect(
        result,
        isFalse,
        reason:
            'Absent trigger must surface as a false return so the outer '
            'opener loop can dismiss transient overlays and retry the '
            'rail/marker arm without entering a hard TestFailure (Refs '
            'GitHub #2336 AC1 / AC10).',
      );
    },
  );

  testWidgets(
    'e2eOpenerTapTriggerAndAwaitMount taps the trigger and returns true '
    'when the panel mounts during the bounded mount probe',
    (WidgetTester tester) async {
      // Trigger is on-screen; tapping it should mount the panel after a
      // short fake-async delay that lands inside the mount-probe window.
      // This pins the full success path: tap fires → post-tap fast-check
      // misses → bounded poll observes the mount → helper returns true.
      final counter = _TapCounter();
      await tester.pumpWidget(
        _TriggerThenPanelHarness(
          counter,
          mountAfter: const Duration(milliseconds: 60),
        ),
      );
      expect(find.byKey(_kPanelKey), findsNothing);
      final result = await e2eOpenerTapTriggerAndAwaitMount(
        tester,
        trigger: find.byKey(_kTriggerKey),
        panelRoot: find.byKey(_kPanelKey),
        mountTimeout: const Duration(seconds: 3),
        mountPhaseName: 'pin_panel_mounts_after_tap',
      );
      expect(
        result,
        isTrue,
        reason:
            'Successful tap-then-mount path must report true so the outer '
            'opener loop emits its `open_panel_<rail>` perf-timing slice '
            'and exits the loop (Refs GitHub #2336 AC1).',
      );
      expect(
        counter.value,
        1,
        reason:
            'Helper must dispatch exactly one tap; double-tapping would '
            'dismiss the freshly-opened panel via the pop route stack '
            '(Refs GitHub #2336 AC10).',
      );
      expect(find.byKey(_kPanelKey), findsOneWidget);
    },
  );

  testWidgets(
    'e2eOpenerTapTriggerAndAwaitMount returns false without throwing when '
    'the panel never mounts within the mount timeout',
    (WidgetTester tester) async {
      // Trigger is on-screen but the harness never mounts the panel, so
      // the bounded mount probe must hit its timeout without escalating
      // into `fail()`. The outer opener loop relies on a `false` return
      // here to dismiss transient overlays and retry the rail/marker arm
      // (a regression that swapped [e2ePumpUntilConditionOrIdle] for the
      // strict [e2ePumpUntil] would surface as a hard TestFailure inside
      // `tryOpen`, regressing every opener whose rail tap races with a
      // closing sheet).
      final counter = _TapCounter();
      await tester.pumpWidget(_TriggerOnlyHarness(counter));
      Object? caught;
      bool? result;
      try {
        result = await e2eOpenerTapTriggerAndAwaitMount(
          tester,
          trigger: find.byKey(_kTriggerKey),
          panelRoot: find.byKey(_kPanelKey),
          mountTimeout: const Duration(milliseconds: 120),
          mountPhaseName: 'pin_panel_never_mounts',
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isNull,
        reason:
            'Mount-timeout must NOT escalate to a fail() call so the outer '
            'opener loop can recover via the next iteration (Refs GitHub '
            '#2336 AC10).',
      );
      expect(
        result,
        isFalse,
        reason:
            'Persistent not-mounted panel must surface as a false return '
            'so the outer opener loop knows to dismiss transient overlays '
            'and retry the rail/marker branch (Refs GitHub #2336 AC1).',
      );
      expect(
        counter.value,
        1,
        reason:
            'Trigger must be tapped exactly once even on the timeout path '
            'so the failure mode matches the legacy inline body that '
            'always issued the rail tap before entering the bounded poll '
            '(Refs GitHub #2336 AC10).',
      );
    },
  );

  testWidgets(
    'AC1 barrel alias `openerTapTriggerAndAwaitMount` forwards to the '
    'shared implementation with the documented signature',
    (WidgetTester tester) async {
      // Compile-time alias signature pin: the tear-off must assign to a
      // matching function type from the barrel without an explicit cast.
      // A future signature drift here (renamed parameters, added required
      // arg, or return-type change) would fail at compile time so
      // consumers of the AC1 barrel cannot silently switch to a different
      // recipe.
      final Future<bool> Function(
        WidgetTester, {
        required Finder trigger,
        required Finder panelRoot,
        required Duration mountTimeout,
        required String mountPhaseName,
        E2ePerfLog? perf,
      })
      tearOff = openerTapTriggerAndAwaitMount;
      final counter = _TapCounter();
      await tester.pumpWidget(
        _TriggerAndPanelHarness(counter, panelMounted: true),
      );
      final result = await tearOff(
        tester,
        trigger: find.byKey(_kTriggerKey),
        panelRoot: find.byKey(_kPanelKey),
        mountTimeout: const Duration(seconds: 1),
        mountPhaseName: 'pin_ac1_barrel_alias',
      );
      expect(result, isTrue);
      expect(counter.value, 0);
    },
  );
}

/// Hit-testable panel root used by the test fixtures. The shared
/// [e2eOpenerTapTriggerAndAwaitMount] helper queries
/// `panelRoot.hitTestable()` for its already-mounted short-circuit, so the
/// fixture mounts a [ColoredBox] (paints opaque pixels and participates
/// in hit-testing) rather than a bare [SizedBox] (no paint, not
/// hit-testable in the test render pipeline). Sized to match the
/// integration-test `kCtE2ECivilianPanelRootKey` / `kCtE2ENavalPanelRootKey`
/// bottom-sheet root so the visual area is realistic.
class _PanelRoot extends StatelessWidget {
  const _PanelRoot();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: _kPanelKey,
      color: Color(0xFFEEEEEE),
      child: SizedBox(width: 200, height: 120),
    );
  }
}

/// Harness that mounts a single keyed [TextButton] trigger and, optionally,
/// a hit-testable keyed panel root. Used to exercise the
/// already-hit-testable short-circuit branch and the AC1 barrel alias
/// signature pin.
class _TriggerAndPanelHarness extends StatelessWidget {
  const _TriggerAndPanelHarness(this.counter, {required this.panelMounted});

  final _TapCounter counter;
  final bool panelMounted;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            TextButton(
              key: _kTriggerKey,
              onPressed: () => counter.value++,
              child: const Text('Trigger'),
            ),
            if (panelMounted) const _PanelRoot(),
          ],
        ),
      ),
    );
  }
}

/// Harness that mounts the trigger immediately and arranges for the panel
/// root to mount after [mountAfter] elapsed fake-async time, simulating
/// the post-tap rebuild that opens the bottom sheet.
class _TriggerThenPanelHarness extends StatefulWidget {
  const _TriggerThenPanelHarness(this.counter, {required this.mountAfter});

  final _TapCounter counter;
  final Duration mountAfter;

  @override
  State<_TriggerThenPanelHarness> createState() =>
      _TriggerThenPanelHarnessState();
}

class _TriggerThenPanelHarnessState extends State<_TriggerThenPanelHarness> {
  bool _panelMounted = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            TextButton(
              key: _kTriggerKey,
              onPressed: () {
                widget.counter.value++;
                Timer(widget.mountAfter, () {
                  if (!mounted) return;
                  setState(() => _panelMounted = true);
                });
              },
              child: const Text('Trigger'),
            ),
            if (_panelMounted) const _PanelRoot(),
          ],
        ),
      ),
    );
  }
}

/// Harness that mounts only the trigger, never the panel — used to pin
/// the timeout branch of [e2eOpenerTapTriggerAndAwaitMount].
class _TriggerOnlyHarness extends StatelessWidget {
  const _TriggerOnlyHarness(this.counter);

  final _TapCounter counter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: TextButton(
          key: _kTriggerKey,
          onPressed: () => counter.value++,
          child: const Text('Trigger'),
        ),
      ),
    );
  }
}
