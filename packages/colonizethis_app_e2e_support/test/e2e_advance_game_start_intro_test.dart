/// Unit coverage for `e2eAdvanceGameStartIntroUntilDismissed` adaptive
/// backoff path. The helper's two idle-pump branches (loading spinner + no
/// tap target) previously paid a fixed 50ms frame per iteration; this test
/// pins the short-circuit behavior and adaptive ramp expectations introduced
/// for GitHub #2336 AC5 / pump-reduction.
///
/// The perf-attribution group at the bottom of the file pins the
/// `E2E_TIMING` / `E2E_COUNTER` markers the helper emits via [E2ePerfLog]
/// when callers thread a perf log through. The bootstrap chain
/// (`e2eBootstrapNewGameToMap` → `e2eWaitForMapHudAfterNewGameStart` →
/// `e2eAdvanceGameStartIntroUntilDismissed`) wires `perf` from the standard
/// scenario opener, so a silent regression in either the phase label, the
/// `result=...` meta tag, or the iteration counter would break the AC8
/// baseline timing pipeline (`tool/run_e2e_timing.sh` +
/// `tool/compare_e2e_timing.sh`) without surfacing in the legacy
/// short-circuit / timeout tests (which all pass `perf: null` by default).
/// Mirrors the perf-attribution pattern landed for
/// `e2eWaitForMapHudAfterNewGameStart` in PR #2960 (`app/test/
/// e2e_wait_for_map_hud_after_new_game_start_test.dart` § perf attribution).
library;

import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';


part 'support/advance_game_start_intro_baseline_part.dart';
part 'support/advance_game_start_intro_multi_part.dart';
part 'support/advance_game_start_intro_perf_part.dart';

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
class _IntroSpinnerHost extends StatefulWidget {
  const _IntroSpinnerHost({required this.controller, this.clearAfter});

  final _IntroSpinnerController controller;

  /// Fake-async delay before the host unmounts the spinner, or `null`
  /// to leave the controller untouched (no scheduled transition).
  final Duration? clearAfter;

  @override
  State<_IntroSpinnerHost> createState() => _IntroSpinnerHostState();
}

class _IntroSpinnerHostState extends State<_IntroSpinnerHost> {
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

class _IntroSpinnerController extends ChangeNotifier {
  _IntroSpinnerController({required bool initiallyVisible})
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
/// Mirrors the `_captureDebugPrintsAsync` helper in
/// `app/test/e2e_wait_for_map_hud_after_new_game_start_test.dart` so the
/// perf-attribution pins added here use the same capture contract as the
/// canonical map-HUD bootstrap perf-attribution group. Refs GitHub #2336
/// AC8 baseline-marker contract.
Future<List<String>> _captureDebugPrintsAsync(
  Future<void> Function() body,
) async {
  final captured = <String>[];
  await _runWithDebugPrintCapture(captured, body);
  return captured;
}

/// Underlying `debugPrint` override used by [_captureDebugPrintsAsync] and the
/// fail-path perf tests, which need to inspect the captured lines even when
/// [body] throws.
Future<void> _runWithDebugPrintCapture(
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

void main() {
  suppressLogsForTests();
  registerAdvanceGameStartIntroBaselineGroup();
  registerAdvanceGameStartIntroMultiLabelGroup();
  registerAdvanceGameStartIntroPerfGroup();
}
