// Host widgets and pump helpers for `e2eWaitForMapHudAfterNewGameStart` pins (Slice D / #4195).
library;

import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class WaitMapHudNewGameSetupHost extends StatefulWidget {
  const WaitMapHudNewGameSetupHost({
    required this.controller,
    this.transitionAfter,
    this.transitionTo,
  });

  final WaitMapHudNewGameSetupController controller;

  /// Fake-async delay before the host applies [transitionTo], or `null`
  /// to leave the controller untouched (no scheduled transition).
  final Duration? transitionAfter;

  /// Target setup phase to apply when [transitionAfter] elapses, or
  /// `null` to leave the controller untouched.
  final WaitMapHudSetupPhase? transitionTo;

  @override
  State<WaitMapHudNewGameSetupHost> createState() => WaitMapHudNewGameSetupHostState();
}

class WaitMapHudNewGameSetupHostState extends State<WaitMapHudNewGameSetupHost> {
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final after = widget.transitionAfter;
    final next = widget.transitionTo;
    if (after != null && next != null) {
      _transitionTimer = Timer(after, () => widget.controller.phase = next);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.controller.phase) {
      case WaitMapHudSetupPhase.idle:
        return const SizedBox.shrink();
      case WaitMapHudSetupPhase.errorDialog:
        return const Center(child: Text('Could not create game'));
      case WaitMapHudSetupPhase.creatingGame:
        return const Center(child: Text('Creating game'));
      case WaitMapHudSetupPhase.introLoading:
        return const Center(child: GameStartIntroLoadingIndicator());
      case WaitMapHudSetupPhase.mapHud:
        return Center(
          child: TextButton(
            key: kHomeToCapitalButtonKey,
            onPressed: () {},
            child: const Text('Capital'),
          ),
        );
    }
  }
}

class WaitMapHudNewGameSetupController extends ChangeNotifier {
  WaitMapHudNewGameSetupController({WaitMapHudSetupPhase initial = WaitMapHudSetupPhase.idle})
      : _phase = initial;

  WaitMapHudSetupPhase _phase;

  WaitMapHudSetupPhase get phase => _phase;

  set phase(WaitMapHudSetupPhase value) {
    if (_phase == value) {
      return;
    }
    _phase = value;
    notifyListeners();
  }
}

enum WaitMapHudSetupPhase { idle, errorDialog, creatingGame, introLoading, mapHud }

Future<WaitMapHudNewGameSetupController> pumpWaitMapHudHost(
  WidgetTester tester, {
  WaitMapHudSetupPhase initial = WaitMapHudSetupPhase.idle,
  Duration? transitionAfter,
  WaitMapHudSetupPhase? transitionTo,
}) async {
  final controller = WaitMapHudNewGameSetupController(initial: initial);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WaitMapHudNewGameSetupHost(
          controller: controller,
          transitionAfter: transitionAfter,
          transitionTo: transitionTo,
        ),
      ),
    ),
  );
  return controller;
}

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards (defensive in `finally` so a thrown
/// expectation does not leak the override into later tests).
///
/// Mirrors the `_captureDebugPrints` helper in
/// `app/test/e2e_perf_log_markers_test.dart` so the perf-attribution pins
/// added here use the same capture contract as the canonical `E2ePerfLog`
/// marker tests. Refs GitHub #2336 AC8 baseline-marker contract.
Future<List<String>> captureWaitMapHudDebugPrintsAsync(Future<void> Function() body) async {
  final captured = <String>[];
  await runWaitMapHudDebugPrintCapture(captured, body);
  return captured;
}

/// Underlying `debugPrint` override used by [captureWaitMapHudDebugPrintsAsync] and the
/// fail-path perf tests, which need to inspect the captured lines even when
/// [body] throws.
Future<void> runWaitMapHudDebugPrintCapture(
  List<String> out,
  Future<void> Function() body,
) async {
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    out.add(message ?? '');
  };
  try {
    await body();
  } finally {
    debugPrint = original;
  }
}