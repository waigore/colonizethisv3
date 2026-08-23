// Ensure-visible + tap trigger hosts for
// `e2eEnsureVisibleAndTapHitTestable` pins (#4598 Slice B).
library;

import 'package:flutter/material.dart';

import 'e2e_tap_counter.dart';

class EnsureVisibleOnScreenTriggerHarness extends StatelessWidget {
  const EnsureVisibleOnScreenTriggerHarness(
    this.counter, {
    super.key,
    required this.triggerKey,
  });

  final E2eTapCounter counter;
  final Key triggerKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: triggerKey,
          onPressed: () => counter.value++,
          child: const Text('Trigger'),
        ),
      ),
    );
  }
}

class EnsureVisibleOffScreenTriggerHarness extends StatelessWidget {
  const EnsureVisibleOffScreenTriggerHarness(
    this.counter, {
    super.key,
    required this.triggerKey,
    required this.scrollableKey,
    required this.sentinelKey,
  });

  final E2eTapCounter counter;
  final Key triggerKey;
  final Key scrollableKey;
  final Key sentinelKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: 200,
        child: SingleChildScrollView(
          key: scrollableKey,
          child: Column(
            children: <Widget>[
              for (var i = 0; i < 6; i++)
                SizedBox(height: 80, child: Center(child: Text('Filler $i'))),
              TextButton(
                key: triggerKey,
                onPressed: () => counter.value++,
                child: const Text('Trigger'),
              ),
              SizedBox(
                height: 200,
                key: sentinelKey,
                child: const Center(child: Text('Sentinel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnsureVisibleUnscrollableTriggerHarness extends StatelessWidget {
  const EnsureVisibleUnscrollableTriggerHarness(
    this.counter, {
    super.key,
    required this.triggerKey,
  });

  final E2eTapCounter counter;
  final Key triggerKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: triggerKey,
          onPressed: () => counter.value++,
          child: const Text('Trigger'),
        ),
      ),
    );
  }
}

class EnsureVisibleOverlayCoveredTriggerHarness extends StatelessWidget {
  const EnsureVisibleOverlayCoveredTriggerHarness({
    super.key,
    required this.triggerKey,
  });

  final Key triggerKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Center(
            child: TextButton(
              key: triggerKey,
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
