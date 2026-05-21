// Pins the **fail-fast guards**, **single-row happy path**, and **post-tap
// work-menu wait** of `e2eTapFirstAssignInCivilianPanel` in
// `app/integration_test/e2e_test_shared.dart` (Refs GitHub #2336 H9 sibling
// / `SPEC/program/e2e-integration-tests.md` § Adaptive poll pacing).
//
// The helper is used by full-turn / fleet-reach E2E paths that need to fire
// civilian work orders without caring about which unit-type row carries the
// first idle `Assign` button. A regression here would either:
//
//   - hang silently on a missing civilian panel root / ListView (timeout
//     budget burned per test, contributes to AC9 wall-clock gap), or
//   - silently no-op when the panel has no Assign anywhere (helper
//     waits out the downstream work-menu timeout instead of failing
//     fast at the offending turn), or
//   - return before the work menu mounts (downstream `Build improvement`
//     / `Prospect` / `Explore` taps race the not-yet-mounted menu).
//
// The existing `e2e_tap_assign_on_civilian_row_with_title_test.dart` co-pins
// the multi-row title-fallback sibling and includes ONE positive test for
// `e2eTapFirstAssignInCivilianPanel` (multi-row "first regardless of title").
// That test stays put. This file covers the **failure branches** and the
// **single-Assign positive base case** that have no dedicated coverage
// today. The off-screen scroll branch is exercised end-to-end by the
// Linux integration runs (`new_game_full_turn_e2e_test.dart`) and is not
// re-pinned here because reproducing its viewport / sliver-cache
// preconditions inside the widget-test layer is brittle across Flutter
// SDK versions.
//
// `integration_test/` runs behind a no-op `app_e2e_linux` lane today
// (`SPEC/program/e2e-integration-tests.md` § CI), so this widget-test layer
// is the only per-PR enforcement gate for the helper's fail-fast guards.
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Synthetic civilian-panel host whose body is provided by the test. Lets
/// each test choose whether to mount the root key, the ListView, the
/// Assign button(s), and the post-tap work-menu text independently.
class _CustomCivilianPanelHost extends StatefulWidget {
  const _CustomCivilianPanelHost({
    required this.bodyBuilder,
    this.includeRootKey = true,
    this.showWorkMenuOnTap = true,
  });

  final Widget Function(VoidCallback onAssignTapped) bodyBuilder;
  final bool includeRootKey;
  final bool showWorkMenuOnTap;

  @override
  State<_CustomCivilianPanelHost> createState() =>
      _CustomCivilianPanelHostState();
}

class _CustomCivilianPanelHostState extends State<_CustomCivilianPanelHost> {
  bool _tapped = false;

  void _markTapped() {
    if (!widget.showWorkMenuOnTap) {
      return;
    }
    setState(() {
      _tapped = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.bodyBuilder(_markTapped);
    final rootChild = Column(
      children: <Widget>[
        Expanded(child: body),
        if (_tapped)
          // The helper polls for any of {Build improvement, Prospect,
          // Explore} after tapping Assign. Showing one of those labels here
          // is the synthetic equivalent of the work-menu surfacing in the
          // production scaffold.
          const Text('Build improvement'),
      ],
    );
    return MaterialApp(
      home: Scaffold(
        body: widget.includeRootKey
            ? Container(key: kCtE2ECivilianPanelRootKey, child: rootChild)
            : rootChild,
      ),
    );
  }
}

bool _hostWasTapped(WidgetTester tester) {
  final stateFinder = find.byType(_CustomCivilianPanelHost);
  if (stateFinder.evaluate().isEmpty) {
    return false;
  }
  final state = tester.state<_CustomCivilianPanelHostState>(stateFinder);
  return state._tapped;
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'fails fast when kCtE2ECivilianPanelRootKey is absent',
    (WidgetTester tester) async {
      // No root key wrapping the ListView; the helper's first
      // `expect(listView, findsOneWidget)` must surface this as a
      // TestFailure rather than hanging while the missing root key would
      // otherwise make the descendant ListView search return zero matches
      // forever.
      await tester.pumpWidget(
        _CustomCivilianPanelHost(
          includeRootKey: false,
          bodyBuilder: (onAssign) => ListView(
            children: <Widget>[
              ListTile(
                title: const Text('Builder'),
                trailing: TextButton(
                  onPressed: onAssign,
                  child: const Text('Assign'),
                ),
              ),
            ],
          ),
        ),
      );

      Object? caught;
      try {
        await e2eTapFirstAssignInCivilianPanel(tester);
      } catch (e) {
        caught = e;
      }

      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Missing civilian panel root key must surface a TestFailure '
            'so the fleet-reach loop fails fast at the offending turn '
            'instead of burning the 5s post-tap timeout silently '
            '(#2336 H9 sibling fail-fast contract).',
      );
      expect(
        _hostWasTapped(tester),
        isFalse,
        reason:
            'Helper must not have tapped an off-tree Assign before its '
            'fail-fast guard fires; a tap that lands without the root key '
            'mounted would mutate panel state on the wrong host.',
      );
    },
  );

  testWidgets(
    'fails fast when root key is present but contains no ListView',
    (WidgetTester tester) async {
      // kCtE2ECivilianPanelRootKey is mounted but its subtree has no
      // ListView descendant; the helper's `expect(listView, findsOneWidget)`
      // guard must reject this before scrollUntilVisible is reached.
      await tester.pumpWidget(
        _CustomCivilianPanelHost(
          bodyBuilder: (onAssign) => Column(
            children: <Widget>[
              const Text('Civilian panel placeholder'),
              TextButton(
                onPressed: onAssign,
                child: const Text('Assign'),
              ),
            ],
          ),
        ),
      );

      Object? caught;
      try {
        await e2eTapFirstAssignInCivilianPanel(tester);
      } catch (e) {
        caught = e;
      }

      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'A root-keyed subtree without a ListView descendant must fail '
            '`findsOneWidget` immediately so the helper cannot fall '
            'through to scrollUntilVisible on a non-scrollable host '
            '(scrollUntilVisible would throw an opaque assertion deep in '
            'the framework, masking the real shape mismatch).',
      );
    },
  );

  testWidgets(
    'fails fast when no Assign text descendant is present in the panel',
    (WidgetTester tester) async {
      // The root + ListView + Scrollable shape is correct, but no row
      // exposes an `Assign` button (every row already assigned). The
      // helper's `expect(assign, findsWidgets)` guard must surface this
      // before scrollUntilVisible or tap is attempted.
      await tester.pumpWidget(
        _CustomCivilianPanelHost(
          bodyBuilder: (_) => ListView(
            children: const <Widget>[
              ListTile(title: Text('Builder'), trailing: Text('Busy')),
              ListTile(title: Text('Merchant'), trailing: Text('Busy')),
            ],
          ),
        ),
      );

      Object? caught;
      try {
        await e2eTapFirstAssignInCivilianPanel(tester);
      } catch (e) {
        caught = e;
      }

      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'A civilian panel with no `Assign` descendants must surface a '
            'TestFailure rather than silently waiting out the downstream '
            'work-menu timeout — the AC9 wall-clock budget is dominated '
            'by silently-burned 5s timeouts on broken panel states.',
      );
      expect(
        _hostWasTapped(tester),
        isFalse,
        reason:
            'Helper must not tap any non-Assign widget when the assertion '
            'fails (no Busy / title row taps as a fallback).',
      );
    },
  );

  testWidgets(
    'taps the lone Assign in a single-row panel and waits for the work menu',
    (WidgetTester tester) async {
      // Positive single-row base case: distinct from the existing
      // multi-row "first regardless of title" test in
      // `e2e_tap_assign_on_civilian_row_with_title_test.dart` — pins that
      // the helper still works when only one Assign is present (no
      // first-of-many ambiguity to resolve).
      await tester.pumpWidget(
        _CustomCivilianPanelHost(
          bodyBuilder: (onAssign) => ListView(
            children: <Widget>[
              ListTile(
                title: const Text('Builder'),
                trailing: TextButton(
                  onPressed: onAssign,
                  child: const Text('Assign'),
                ),
              ),
            ],
          ),
        ),
      );

      await e2eTapFirstAssignInCivilianPanel(tester);

      expect(
        _hostWasTapped(tester),
        isTrue,
        reason:
            'Single-Assign happy path: the lone Assign button must be '
            'tapped so the downstream work-menu wait can settle on the '
            "host's emitted `Build improvement` label.",
      );
      expect(
        find.text('Build improvement'),
        findsOneWidget,
        reason:
            'Helper must not return before the work menu mounts, '
            'otherwise downstream finders that look for Build '
            'improvement / Prospect / Explore would race a not-yet-'
            'mounted menu on slower Linux CI runners.',
      );
    },
  );

  testWidgets(
    'fails with TestFailure when the post-tap work menu never surfaces',
    (WidgetTester tester) async {
      // The Assign tap fires (host sees the press) but the synthetic
      // host is configured NOT to emit `Build improvement` / `Prospect` /
      // `Explore`. The helper's downstream `e2eWaitUntilAnyFinderHitTestable`
      // must run to its 5s timeout and surface a TestFailure rather than
      // returning silently.
      await tester.pumpWidget(
        _CustomCivilianPanelHost(
          showWorkMenuOnTap: false,
          bodyBuilder: (onAssign) => ListView(
            children: <Widget>[
              ListTile(
                title: const Text('Builder'),
                trailing: TextButton(
                  onPressed: onAssign,
                  child: const Text('Assign'),
                ),
              ),
            ],
          ),
        ),
      );

      Object? caught;
      try {
        await e2eTapFirstAssignInCivilianPanel(tester);
      } catch (e) {
        caught = e;
      }

      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'When the work menu never surfaces, the helper must throw '
            'TestFailure (via e2eWaitUntilAnyFinderHitTestable) so the '
            'caller fails the scenario at the offending turn rather than '
            'continuing with a stale civilian panel state.',
      );
    },
  );
}
