// Shared delayed-mount host for `e2e_wait_until_found_test.dart` and
// `e2e_await_panel_mount_after_opener_tap_test.dart` (#4344 Slice C
// densify). The two suites previously diverged the same "mount a widget
// after an optional fake-async delay" fixture: one keyed a `targetKey` /
// `mountAfter` / `startMounted` shape, the other exposed an `onState`
// callback plus a `mount()` escape hatch for post-pump fast-check tests.
// This harness unifies both call shapes behind a single `child` widget.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_widget_pump_harness.dart';

/// Host that mounts [child] after an optional fake-async delay so tests can
/// flip visibility while a helper polls (adaptive `tester.pump` loops).
///
/// `Timer` callbacks scheduled in [State.initState] fire when `tester.pump`
/// advances fake-time past the registered duration, so a helper under test
/// observes the newly mounted [child] on a later iteration without the test
/// calling `tester.pump` itself (which would deadlock against the helper's
/// guarded pump loop).
class DelayedMountHost extends StatefulWidget {
  const DelayedMountHost({
    super.key,
    required this.child,
    this.mountAfter,
    this.startMounted = false,
    this.onState,
  });

  /// Widget rendered once mounted; a [SizedBox.shrink] beforehand.
  final Widget child;

  /// Fake-async delay before the host mounts [child], or `null` to leave
  /// the mounted flag untouched.
  final Duration? mountAfter;

  /// Whether [child] is mounted on the first frame (pre-pump).
  final bool startMounted;

  /// Callback invoked with the created state during [State.initState] so a
  /// test can call [DelayedMountHostState.mount] externally — used by the
  /// post-pump fast-check tests that flip visibility without a `Timer`.
  final void Function(DelayedMountHostState state)? onState;

  @override
  State<DelayedMountHost> createState() => DelayedMountHostState();
}

class DelayedMountHostState extends State<DelayedMountHost> {
  late bool _shown;
  Timer? _mountTimer;

  @override
  void initState() {
    super.initState();
    _shown = widget.startMounted;
    widget.onState?.call(this);
    final after = widget.mountAfter;
    if (after != null) {
      _mountTimer = Timer(after, () {
        if (!mounted) return;
        setState(() => _shown = true);
      });
    }
  }

  /// Externally triggers a `setState` flip that mounts [DelayedMountHost.child].
  void mount() {
    setState(() => _shown = true);
  }

  @override
  void dispose() {
    _mountTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shown) {
      return const SizedBox.shrink();
    }
    return widget.child;
  }
}

/// Pumps [DelayedMountHost] wrapping a keyed [TextButton] inside
/// [wrapE2eScaffold] so pin suites do not re-declare `_pumpHost`.
Future<void> pumpDelayedMountKeyedButton(
  WidgetTester tester, {
  required Key targetKey,
  Duration? mountAfter,
  bool startMounted = false,
}) {
  return tester.pumpWidget(
    wrapE2eScaffold(
      Center(
        child: DelayedMountHost(
          mountAfter: mountAfter,
          startMounted: startMounted,
          child: TextButton(
            key: targetKey,
            onPressed: () {},
            child: const Text('btn'),
          ),
        ),
      ),
    ),
  );
}
