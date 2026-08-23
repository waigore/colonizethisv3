// Panel-opener trigger/panel hosts for
// `e2eOpenerTapTriggerAndAwaitMount` pins (#4598 Slice B).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'e2e_tap_counter.dart';
import 'e2e_widget_pump_harness.dart';

class OpenerPanelRoot extends StatelessWidget {
  const OpenerPanelRoot({super.key, required this.panelKey});

  final Key panelKey;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: panelKey,
      color: const Color(0xFFEEEEEE),
      child: const SizedBox(width: 200, height: 120),
    );
  }
}

class OpenerTriggerAndPanelHarness extends StatelessWidget {
  const OpenerTriggerAndPanelHarness(
    this.counter, {
    super.key,
    required this.panelMounted,
    required this.triggerKey,
    required this.panelKey,
  });

  final E2eTapCounter counter;
  final bool panelMounted;
  final Key triggerKey;
  final Key panelKey;

  @override
  Widget build(BuildContext context) {
    return wrapE2eScaffold(
      Column(
        children: <Widget>[
          TextButton(
            key: triggerKey,
            onPressed: () => counter.value++,
            child: const Text('Trigger'),
          ),
          if (panelMounted) OpenerPanelRoot(panelKey: panelKey),
        ],
      ),
    );
  }
}

class OpenerTriggerThenPanelHarness extends StatefulWidget {
  const OpenerTriggerThenPanelHarness(
    this.counter, {
    super.key,
    required this.mountAfter,
    required this.triggerKey,
    required this.panelKey,
  });

  final E2eTapCounter counter;
  final Duration mountAfter;
  final Key triggerKey;
  final Key panelKey;

  @override
  State<OpenerTriggerThenPanelHarness> createState() =>
      _OpenerTriggerThenPanelHarnessState();
}

class _OpenerTriggerThenPanelHarnessState
    extends State<OpenerTriggerThenPanelHarness> {
  bool _panelMounted = false;

  @override
  Widget build(BuildContext context) {
    return wrapE2eScaffold(
      Column(
        children: <Widget>[
          TextButton(
            key: widget.triggerKey,
            onPressed: () {
              widget.counter.value++;
              Timer(widget.mountAfter, () {
                if (!mounted) return;
                setState(() => _panelMounted = true);
              });
            },
            child: const Text('Trigger'),
          ),
          if (_panelMounted) OpenerPanelRoot(panelKey: widget.panelKey),
        ],
      ),
    );
  }
}

class OpenerTriggerOnlyHarness extends StatelessWidget {
  const OpenerTriggerOnlyHarness(
    this.counter, {
    super.key,
    required this.triggerKey,
  });

  final E2eTapCounter counter;
  final Key triggerKey;

  @override
  Widget build(BuildContext context) {
    return wrapE2eScaffold(
      TextButton(
        key: triggerKey,
        onPressed: () => counter.value++,
        child: const Text('Trigger'),
      ),
    );
  }
}
