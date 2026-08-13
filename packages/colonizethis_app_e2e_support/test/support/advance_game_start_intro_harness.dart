library;

import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Host that mounts (or unmounts) a [GameStartIntroLoadingIndicator] so the
/// `e2eAdvanceGameStartIntroUntilDismissed` polling loop drives the spinner →
/// cleared transition through its adaptive idle pump.
///
/// `Timer` callbacks scheduled in [State.initState] fire when `tester.pump`
/// advances fake-time past their delays, so the helper observes the
/// scheduled unmount on a later polling iteration without the test calling
/// `tester.pump` itself (which would deadlock against the helper's guarded
/// pump loop). Mirrors the `_NewGameSetupHost` controller pattern in
/// `app/test/e2e_wait_for_map_hud_after_new_game_start_test.dart`.
class IntroSpinnerHost extends StatefulWidget {
  const IntroSpinnerHost({required this.controller, this.clearAfter});

  final IntroSpinnerController controller;

  /// Fake-async delay before the host unmounts the spinner, or `null`
  /// to leave the controller untouched (no scheduled transition).
  final Duration? clearAfter;

  @override
  State<IntroSpinnerHost> createState() => IntroSpinnerHostState();
}

class IntroSpinnerHostState extends State<IntroSpinnerHost> {
  Timer? _clearTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final after = widget.clearAfter;
    if (after != null) {
      _clearTimer = Timer(after, () => widget.controller.visible = false);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.visible) {
      return const SizedBox.shrink();
    }
    return const Center(child: GameStartIntroLoadingIndicator());
  }
}

class IntroSpinnerController extends ChangeNotifier {
  IntroSpinnerController({required bool initiallyVisible})
    : _visible = initiallyVisible;

  bool _visible;

  bool get visible => _visible;

  set visible(bool value) {
    if (_visible == value) {
      return;
    }
    _visible = value;
    notifyListeners();
  }
}

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards (defensive in `finally` so a thrown
/// expectation does not leak the override into later tests).
///
/// Mirrors the `captureDebugPrintsAsync` helper in
/// `app/test/e2e_wait_for_map_hud_after_new_game_start_test.dart` so the
/// perf-attribution pins added here use the same capture contract as the
/// canonical map-HUD bootstrap perf-attribution group. Refs GitHub #2336
/// AC8 baseline-marker contract.
Future<List<String>> captureDebugPrintsAsync(
  Future<void> Function() body,
) async {
  final captured = <String>[];
  await runWithDebugPrintCapture(captured, body);
  return captured;
}

/// Underlying `debugPrint` override used by [captureDebugPrintsAsync] and the
/// fail-path perf tests, which need to inspect the captured lines even when
/// [body] throws.
Future<void> runWithDebugPrintCapture(
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

