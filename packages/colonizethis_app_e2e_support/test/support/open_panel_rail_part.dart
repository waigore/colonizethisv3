part of '../e2e_open_panel_via_rail_or_marker_test.dart';

void registerOpenPanelViaRailGroup() {
  suppressLogsForTests();

  testWidgets(
    'e2eOpenPanelViaRailOrMarker returns synchronously without tapping '
    'either trigger when the panel root is already hit-testable',
    (WidgetTester tester) async {
      // Pre-lift contract: the panel-already-hit-testable fast-path is
      // critical for the post-sheet-close iteration where the panel can
      // already be rebuilt before the outer loop reaches its rail-tap
      // arm. A regression that always tapped first would dismiss the
      // freshly rebuilt panel on every outer-loop iteration after a
      // sheet close.
      final counter = _TapCounter();
      await tester.pumpWidget(
        _RailMarkerPanelHarness(counter, panelMounted: true),
      );
      await e2eOpenPanelViaRailOrMarker(
        tester,
        openerLabel: 'pin_already_mounted',
        railButton: find.byKey(_kRailKey),
        markerButton: find.byKey(_kMarkerKey),
        panelRoot: find.byKey(_kPanelKey),
        afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
        overallTimeout: const Duration(seconds: 5),
        timeoutMessageBuilder: (_) =>
            'pin_already_mounted timeout should never fire',
      );
      expect(
        counter.rail,
        0,
        reason:
            'Already-hit-testable panel root must short-circuit before '
            'the outer loop reaches its rail-tap arm; a regression that '
            'always tapped would surface as a duplicate panel mount on '
            'every post-sheet-close iteration (Refs GitHub #2336 AC10).',
      );
      expect(
        counter.marker,
        0,
        reason:
            'Already-hit-testable panel root must short-circuit before '
            'the outer loop reaches its marker-fallback arm too; the '
            'short-circuit fires *before* either trigger is evaluated '
            '(Refs GitHub #2336 AC10).',
      );
    },
  );

  testWidgets(
    'e2eOpenPanelViaRailOrMarker taps the rail trigger and returns when '
    'the panel mounts synchronously after the tap',
    (WidgetTester tester) async {
      // Rail-tap branch: outer loop selects the rail arm before
      // evaluating the marker arm so a regression that swapped arm
      // priority (e.g. marker-first) would silently change the
      // post-tap mount attribution for the civilian and naval openers
      // even though both arms can mount the same panel root in fixture
      // harnesses.
      final counter = _TapCounter();
      await tester.pumpWidget(_RailMarkerPanelHarness(counter));
      await e2eOpenPanelViaRailOrMarker(
        tester,
        openerLabel: 'pin_rail_tap',
        railButton: find.byKey(_kRailKey),
        markerButton: find.byKey(_kMarkerKey),
        panelRoot: find.byKey(_kPanelKey),
        afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
        overallTimeout: const Duration(seconds: 5),
        timeoutMessageBuilder: (_) => 'pin_rail_tap timeout should never fire',
      );
      expect(
        counter.rail,
        1,
        reason:
            'Rail arm must dispatch exactly one tap on the success path; '
            'a regression that double-tapped would dismiss the freshly '
            'opened panel via the pop route stack (Refs GitHub #2336 '
            'AC10).',
      );
      expect(
        counter.marker,
        0,
        reason:
            'Marker arm must not fire when the rail arm already mounted '
            'the panel; a regression that fell through to the marker '
            'arm would silently double-tap the panel surface (Refs '
            'GitHub #2336 AC1).',
      );
      expect(find.byKey(_kPanelKey), findsOneWidget);
    },
  );

  testWidgets(
    'e2eOpenPanelViaRailOrMarker falls back to the marker trigger when '
    'the rail finder resolves to zero elements',
    (WidgetTester tester) async {
      // Marker fallback path: when the empire rail button is not in the
      // tree (typical when the rail rebuild races a transient overlay),
      // the helper must take the marker arm rather than spinning on the
      // bounded rail/marker hit-testable pump.
      final counter = _TapCounter();
      await tester.pumpWidget(_MarkerOnlyPanelHarness(counter));
      await e2eOpenPanelViaRailOrMarker(
        tester,
        openerLabel: 'pin_marker_fallback',
        railButton: find.byKey(_kRailKey),
        markerButton: find.byKey(_kMarkerKey),
        panelRoot: find.byKey(_kPanelKey),
        afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
        overallTimeout: const Duration(seconds: 5),
        timeoutMessageBuilder: (_) =>
            'pin_marker_fallback timeout should never fire',
      );
      expect(
        counter.rail,
        0,
        reason:
            'Rail arm must not fire when the rail trigger finder is '
            'empty; a regression that tapped a stale reference would '
            'crash with a tap-without-target (Refs GitHub #2336 AC1).',
      );
      expect(
        counter.marker,
        1,
        reason:
            'Marker arm must dispatch the fallback tap exactly once '
            'when the rail finder resolves to zero elements (Refs '
            'GitHub #2336 AC1 / AC10).',
      );
      expect(find.byKey(_kPanelKey), findsOneWidget);
    },
  );

  testWidgets('e2eOpenPanelViaRailOrMarker returns once the panel root mounts '
      'asynchronously after the rail tap (adaptive polling)', (
    WidgetTester tester,
  ) async {
    // Async-mount path exercises the bounded post-tap mount probe
    // inside the inner [e2eOpenerTapTriggerAndAwaitMount]: the helper
    // must keep pumping past the post-tap fast-check until the panel
    // mounts. A regression that promoted the mount probe to a strict
    // [e2ePumpUntil] would surface as a hard TestFailure inside the
    // outer loop rather than this success-with-async-mount path.
    final counter = _TapCounter();
    await tester.pumpWidget(
      _DelayedPanelHarness(
        counter,
        mountAfter: const Duration(milliseconds: 60),
      ),
    );
    expect(find.byKey(_kPanelKey), findsNothing);
    await e2eOpenPanelViaRailOrMarker(
      tester,
      openerLabel: 'pin_async_mount',
      railButton: find.byKey(_kRailKey),
      markerButton: find.byKey(_kMarkerKey),
      panelRoot: find.byKey(_kPanelKey),
      afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
      overallTimeout: const Duration(seconds: 5),
      timeoutMessageBuilder: (_) => 'pin_async_mount timeout should never fire',
    );
    expect(
      counter.rail,
      1,
      reason:
          'Rail arm must dispatch exactly one tap before the post-tap '
          'mount probe begins polling; double-tapping would dismiss '
          'the freshly opened panel (Refs GitHub #2336 AC10).',
    );
    expect(find.byKey(_kPanelKey), findsOneWidget);
  });

  testWidgets('e2eOpenPanelViaRailOrMarker fails with TestFailure when neither '
      'trigger surfaces, and forwards the configured overallTimeout into '
      'timeoutMessageBuilder', (WidgetTester tester) async {
    // Persistent-absence path: the outer loop must escalate to
    // `fail()` rather than silently returning, so per-opener failure
    // attribution stays stable in CI logs. The
    // `timeoutMessageBuilder` callback must receive the **configured**
    // overallTimeout argument verbatim so a caller's
    // `'Timed out after ${t.inSeconds}s ...'` interpolation reflects
    // the actual cap rather than a hardcoded default.
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    const overallTimeout = Duration(milliseconds: 200);
    Duration? captured;
    Object? caught;
    try {
      await e2eOpenPanelViaRailOrMarker(
        tester,
        openerLabel: 'pin_timeout',
        railButton: find.byKey(_kRailKey),
        markerButton: find.byKey(_kMarkerKey),
        panelRoot: find.byKey(_kPanelKey),
        afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
        overallTimeout: overallTimeout,
        timeoutMessageBuilder: (t) {
          captured = t;
          return 'pin_timeout diagnostic for ${t.inMilliseconds}ms';
        },
      );
    } catch (e) {
      caught = e;
    }
    expect(
      caught,
      isA<TestFailure>(),
      reason:
          'Persistent absence of both rail and marker must surface a '
          'TestFailure rather than silently returning (Refs GitHub '
          '#2336 AC10).',
    );
    expect(
      captured,
      overallTimeout,
      reason:
          'timeoutMessageBuilder must receive the configured '
          'overallTimeout argument so caller interpolation reflects '
          'the real cap, not a hardcoded default (Refs GitHub #2336 '
          'AC10 — attribution stability).',
    );
    expect(
      (caught! as TestFailure).message,
      contains('pin_timeout diagnostic for 200ms'),
      reason:
          'The fail() string must embed the caller-supplied '
          'diagnostic verbatim so CI logs attribute the timeout to '
          'the calling opener (Refs GitHub #2336 AC10).',
    );
  });

}
