// Shared delayed-removal host for `e2e_pump_until_finder_empty_test.dart`
// (#4598 leftover host SoT). Pin suites import this instead of declaring
// `_DelayedRemovalHost` / `_pumpHost` locally.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_widget_pump_harness.dart';

/// Removes an internal child after a fake-async delay so a polling helper
/// can observe disappearance without the test calling `tester.pump` itself.
class DelayedRemovalHost extends StatefulWidget {
  const DelayedRemovalHost({
    super.key,
    required this.removeAfter,
    required this.onState,
  });

  final Duration removeAfter;
  final void Function(DelayedRemovalHostState state) onState;

  @override
  State<DelayedRemovalHost> createState() => DelayedRemovalHostState();
}

class DelayedRemovalHostState extends State<DelayedRemovalHost> {
  bool present = true;

  @override
  void initState() {
    super.initState();
    widget.onState(this);
    Timer(widget.removeAfter, () {
      if (!mounted) return;
      setState(() => present = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!present) {
      return const SizedBox.shrink();
    }
    return const Text('pin-target', textDirection: TextDirection.ltr);
  }
}

Future<DelayedRemovalHostState> pumpDelayedRemovalHost(
  WidgetTester tester, {
  required Duration removeAfter,
}) async {
  late DelayedRemovalHostState captured;
  await tester.pumpWidget(
    wrapE2eScaffold(
      DelayedRemovalHost(
        removeAfter: removeAfter,
        onState: (s) => captured = s,
      ),
    ),
  );
  return captured;
}
