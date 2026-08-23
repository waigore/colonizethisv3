// Delayed boolean host for `e2ePumpUntil` pins (#4598 Slice B).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_widget_pump_harness.dart';

class DelayedConditionHost extends StatefulWidget {
  const DelayedConditionHost({
    super.key,
    required this.flipAfter,
    required this.onState,
  });

  final Duration flipAfter;
  final void Function(DelayedConditionState state) onState;

  @override
  State<DelayedConditionHost> createState() => DelayedConditionState();
}

class DelayedConditionState extends State<DelayedConditionHost> {
  bool ready = false;

  @override
  void initState() {
    super.initState();
    widget.onState(this);
    Timer(widget.flipAfter, () {
      if (!mounted) return;
      setState(() => ready = true);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Future<DelayedConditionState> pumpDelayedConditionHost(
  WidgetTester tester, {
  required Duration flipAfter,
}) async {
  late DelayedConditionState captured;
  await pumpE2eScaffold(
    tester,
    DelayedConditionHost(flipAfter: flipAfter, onState: (s) => captured = s),
  );
  return captured;
}
