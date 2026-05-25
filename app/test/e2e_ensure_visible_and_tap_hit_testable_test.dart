/// Widget-test coverage for `e2eEnsureVisibleAndTapHitTestable`, the shared
/// defensive rail/marker tap primitive that `e2eOpenCivilianPanel`,
/// `e2eOpenNavalPanel`, and `e2eOpenProductionPanel` invoke from their
/// inner `tryOpen` closures.
///
/// Lifted from the inline `try { ensureVisible } catch (_) {} + hitTestable
/// resolve + tap` pattern that PR #2555 inlined into the naval opener after
/// the rail tap was observed to land off-target on Linux headless CI
/// (production rolled the hit-testable resolve inline too but skipped
/// `ensureVisible`; civilian still relied on raw `tap(trigger.first)`).
/// Lifting the recipe into one shared helper gives all three openers the
/// same off-screen-trigger resilience byte-equivalently.
///
/// Because `integration_test/` is not part of the PR `quality` workflow
/// (`SPEC/program/e2e-integration-tests.md` § CI — `app_e2e_linux` lane is
/// a no-op), the widget-test layer carries the behavioural pins for the
/// AC1 "single canonical shared helper" and AC10 "no silent flakiness
/// from off-screen-trigger drops" contracts. Without these pins, a future
/// refactor that re-inlined the recipe inconsistently across the three
/// openers could silently regress at the integration-test wall-clock
/// layer with no unit-level signal.
///
/// Refs GitHub #2336 (AC1 — shared helpers; AC2 — single canonical
/// implementation; AC10 — no silent flakiness from timeout regressions).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';

const _kTriggerKey = ValueKey<String>('e2e_evt_trigger');
const _kSentinelKey = ValueKey<String>('e2e_evt_sentinel');
const _kScrollableKey = ValueKey<String>('e2e_evt_scrollable');

/// Mutable tap counter held outside the [StatelessWidget] harness so the
/// `must_be_immutable` lint stays satisfied (a `StatefulWidget`-only test
/// fixture would otherwise need to leak counter state up through a
/// `GlobalKey`, which is more brittle than a plain holder).
class _TapCounter {
  int value = 0;
}

void main() {
  suppressLogsForTests();

  testWidgets('e2eEnsureVisibleAndTapHitTestable returns false without tapping '
      'when the trigger finder resolves to zero elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final result = await e2eEnsureVisibleAndTapHitTestable(
      tester,
      find.byKey(_kTriggerKey),
    );
    expect(
      result,
      isFalse,
      reason:
          'Absent trigger must return false so opener tryOpen closures '
          'know to skip the rail/marker branch without firing a stray tap '
          '(Refs GitHub #2336 AC1).',
    );
  });

  testWidgets(
    'e2eEnsureVisibleAndTapHitTestable taps an on-screen hit-testable trigger '
    'and reports true',
    (WidgetTester tester) async {
      final counter = _TapCounter();
      await tester.pumpWidget(MaterialApp(home: _TapCountHarness(counter)));
      expect(find.byKey(_kTriggerKey), findsOneWidget);
      final result = await e2eEnsureVisibleAndTapHitTestable(
        tester,
        find.byKey(_kTriggerKey),
      );
      expect(
        result,
        isTrue,
        reason:
            'On-screen hit-testable trigger must report a successful tap so '
            'the opener tryOpen closure proceeds to the panel-mount probe '
            '(Refs GitHub #2336 AC1).',
      );
      expect(
        counter.value,
        1,
        reason:
            'Helper must dispatch exactly one tap; a regression that taps '
            'twice (for example tapping both the raw and hit-testable '
            'finders) would dismiss the freshly-opened panel on the second '
            'tap (Refs GitHub #2336 AC10).',
      );
    },
  );

  testWidgets(
    'e2eEnsureVisibleAndTapHitTestable scrolls an off-screen trigger into '
    'view before tapping',
    (WidgetTester tester) async {
      final counter = _TapCounter();
      await tester.pumpWidget(
        MaterialApp(home: _OffScreenTriggerHarness(counter)),
      );
      expect(find.byKey(_kTriggerKey), findsOneWidget);
      // Pre-condition: the trigger exists in the widget tree but is not
      // hit-testable because it sits past the viewport bottom in a
      // scrollable list. A raw `tester.tap(trigger.first)` would either
      // throw (`warnIfMissed: true`) or fire a tap at the trigger's
      // off-screen center and miss the visible button row entirely.
      expect(
        find.byKey(_kTriggerKey).hitTestable(),
        findsNothing,
        reason:
            'Test fixture must start with the trigger off-screen so the '
            'ensureVisible branch is actually exercised.',
      );
      final result = await e2eEnsureVisibleAndTapHitTestable(
        tester,
        find.byKey(_kTriggerKey),
      );
      expect(
        result,
        isTrue,
        reason:
            'Off-screen trigger must report a successful tap once '
            'ensureVisible scrolls it into the viewport (Refs GitHub #2336 '
            'AC10 — PR #2555 history fix for the naval rail tap).',
      );
      expect(
        counter.value,
        1,
        reason:
            'ensureVisible + hit-testable resolve must land a real tap on '
            'the scrolled-in trigger; a regression that skipped '
            'ensureVisible would leave counter.value at 0 (Refs GitHub '
            '#2336 AC10).',
      );
    },
  );

  testWidgets(
    'e2eEnsureVisibleAndTapHitTestable swallows an ensureVisible failure '
    'and still taps the raw trigger',
    (WidgetTester tester) async {
      // Mount a trigger that is NOT inside any [Scrollable]. The Flutter
      // test harness throws `StateError('No Scrollable widget found')` when
      // `ensureVisible` is invoked in that configuration; the helper's
      // `try`/`catch (_)` must absorb the throw and fall through to the
      // raw-trigger fallback so the tap still fires.
      final counter = _TapCounter();
      await tester.pumpWidget(
        MaterialApp(home: _UnscrollableTriggerHarness(counter)),
      );
      expect(find.byKey(_kTriggerKey), findsOneWidget);
      expect(
        find.byKey(_kTriggerKey).hitTestable(),
        findsOneWidget,
        reason:
            'Test fixture trigger must already be hit-testable so the '
            'tap can land via the hit-testable resolve fallback once the '
            'helper swallows the ensureVisible StateError.',
      );
      final result = await e2eEnsureVisibleAndTapHitTestable(
        tester,
        find.byKey(_kTriggerKey),
      );
      expect(
        result,
        isTrue,
        reason:
            'ensureVisible failure inside a non-scrollable host must not '
            'propagate past the helper; the tap should still land via the '
            'raw-trigger fallback (Refs GitHub #2336 AC10).',
      );
      expect(counter.value, 1);
    },
  );

  testWidgets(
    'e2eEnsureVisibleAndTapHitTestable falls back to the raw trigger when '
    'no hit-testable element resolves',
    (WidgetTester tester) async {
      // The trigger sits under an opaque overlay so it is rendered in the
      // tree but not hit-testable. Without the raw-trigger fallback the
      // helper would skip the tap; with the fallback it still issues a
      // centered tap at the trigger's geometric position (matching the
      // legacy naval opener behaviour pre-PR #2555). The overlay absorbs
      // the tap so the harness records zero taps, but the helper still
      // returns true to keep the opener tryOpen closure on the post-tap
      // probe path.
      final harness = _OverlayCoveredTriggerHarness();
      await tester.pumpWidget(MaterialApp(home: harness));
      expect(find.byKey(_kTriggerKey), findsOneWidget);
      expect(
        find.byKey(_kTriggerKey).hitTestable(),
        findsNothing,
        reason:
            'Overlay-covered trigger must not be hit-testable so the '
            'raw-trigger fallback branch is the only path the helper can '
            'take.',
      );
      final result = await e2eEnsureVisibleAndTapHitTestable(
        tester,
        find.byKey(_kTriggerKey),
      );
      expect(
        result,
        isTrue,
        reason:
            'Raw-trigger fallback must still report a tap issued so the '
            'opener tryOpen closure continues to the post-tap panel-mount '
            'probe rather than retrying the rail/marker branch immediately '
            '(Refs GitHub #2336 AC1).',
      );
    },
  );

  testWidgets(
    'AC1 barrel alias `ensureVisibleAndTapHitTestable` forwards to the '
    'shared implementation',
    (WidgetTester tester) async {
      // Compile-time alias signature pin: the tear-off must assign to a
      // matching function type from the barrel without an explicit cast.
      // A future signature drift here (extra positional/named arg, or
      // return-type change) would fail at compile time so consumers do
      // not silently switch to a different recipe.
      final Future<bool> Function(WidgetTester, Finder) tearOff =
          ensureVisibleAndTapHitTestable;
      final counter = _TapCounter();
      await tester.pumpWidget(MaterialApp(home: _TapCountHarness(counter)));
      final result = await tearOff(tester, find.byKey(_kTriggerKey));
      expect(result, isTrue);
      expect(counter.value, 1);
    },
  );
}

/// Test harness that mounts a single keyed [TextButton] inside the
/// viewport and bumps [_TapCounter.value] on tap.
class _TapCountHarness extends StatelessWidget {
  const _TapCountHarness(this.counter);

  final _TapCounter counter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: _kTriggerKey,
          onPressed: () => counter.value++,
          child: const Text('Trigger'),
        ),
      ),
    );
  }
}

/// Test harness that mounts the trigger button below the viewport inside a
/// scrollable list so it is not initially hit-testable.
///
/// The helper must call `ensureVisible` to scroll the trigger into view
/// before tapping. A regression that skipped `ensureVisible` would either
/// throw (`warnIfMissed: true`) or land the tap on empty viewport space.
class _OffScreenTriggerHarness extends StatelessWidget {
  const _OffScreenTriggerHarness(this.counter);

  final _TapCounter counter;

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView keeps every child built (unlike ListView's
    // lazy viewport-only builder) so `find.byKey(_kTriggerKey)` resolves
    // even when the trigger is past the viewport. The Scrollable is still
    // present for `ensureVisible` to walk; the SizedBox height clip
    // forces the trigger off-screen at mount.
    return Scaffold(
      body: SizedBox(
        height: 200,
        child: SingleChildScrollView(
          key: _kScrollableKey,
          child: Column(
            children: <Widget>[
              for (var i = 0; i < 6; i++)
                SizedBox(height: 80, child: Center(child: Text('Filler $i'))),
              TextButton(
                key: _kTriggerKey,
                onPressed: () => counter.value++,
                child: const Text('Trigger'),
              ),
              const SizedBox(
                height: 200,
                key: _kSentinelKey,
                child: Center(child: Text('Sentinel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Test harness that mounts the trigger button outside any [Scrollable] so
/// `tester.ensureVisible` throws `StateError`. The helper must swallow the
/// throw and still issue the tap via the hit-testable resolve fallback.
class _UnscrollableTriggerHarness extends StatelessWidget {
  const _UnscrollableTriggerHarness(this.counter);

  final _TapCounter counter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: _kTriggerKey,
          onPressed: () => counter.value++,
          child: const Text('Trigger'),
        ),
      ),
    );
  }
}

/// Test harness that mounts the trigger button under an opaque full-screen
/// overlay so it is rendered (`find.byKey(_kTriggerKey)` resolves) but not
/// hit-testable (`hitTestable()` resolves to nothing). Forces the helper
/// to fall back to the raw trigger; the overlay absorbs the tap so the
/// underlying button never fires its `onPressed`, but the helper must
/// still report `true` to keep the opener tryOpen closure on the post-tap
/// probe path rather than dropping into a hard retry.
class _OverlayCoveredTriggerHarness extends StatefulWidget {
  const _OverlayCoveredTriggerHarness();

  @override
  State<_OverlayCoveredTriggerHarness> createState() =>
      _OverlayCoveredTriggerHarnessState();
}

class _OverlayCoveredTriggerHarnessState
    extends State<_OverlayCoveredTriggerHarness> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Center(
            child: TextButton(
              key: _kTriggerKey,
              onPressed: () {},
              child: const Text('Trigger'),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const ColoredBox(color: Color(0xFF000000)),
            ),
          ),
        ],
      ),
    );
  }
}
