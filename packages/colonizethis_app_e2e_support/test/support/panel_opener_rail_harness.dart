// Shared primary/secondary rail-trigger harnesses for the panel-opener
// pre-tap wait suites (#4344 Slice C densify): `e2e_await_panel_opener_rail_
// hit_testable_test.dart` and `e2e_close_panel_opener_sheet_and_await_
// opener_test.dart` previously cloned identical `_PrimaryHitTestableHarness`
// / `_SecondaryOnlyHarness` trees that only differed by suite-local key
// constants. Callers now pass their own [Key] so the trees stay shared.
library;

import 'dart:async';

import 'package:flutter/material.dart';

/// Harness with a single keyed primary trigger that is hit-testable on the
/// first pump (no overlay, no scrollable). Used by short-circuit fast-path
/// tests.
class PrimaryHitTestableHarness extends StatelessWidget {
  const PrimaryHitTestableHarness({super.key, required this.primaryKey});

  final Key primaryKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        key: primaryKey,
        onPressed: () {},
        child: const Text('Primary'),
      ),
    );
  }
}

/// Harness with only the secondary trigger rendered (primary is absent).
/// Mirrors the naval opener's `[marker, rail]` call site when the rail
/// button has not yet entered the tree.
class SecondaryOnlyHarness extends StatelessWidget {
  const SecondaryOnlyHarness({super.key, required this.secondaryKey});

  final Key secondaryKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        key: secondaryKey,
        onPressed: () {},
        child: const Text('Secondary'),
      ),
    );
  }
}

/// Harness that renders a keyed primary trigger covered by an opaque
/// modal-barrier-style overlay until an in-test [Timer] fires. The primary
/// is hit-testable only after the overlay clears, exercising the
/// pump-and-poll branch of the pre-tap wait helper.
class DelayedPrimaryHitTestableHarness extends StatefulWidget {
  const DelayedPrimaryHitTestableHarness({
    super.key,
    required this.primaryKey,
    required this.uncoverAfter,
  });

  final Key primaryKey;
  final Duration uncoverAfter;

  @override
  State<DelayedPrimaryHitTestableHarness> createState() =>
      _DelayedPrimaryHitTestableHarnessState();
}

class _DelayedPrimaryHitTestableHarnessState
    extends State<DelayedPrimaryHitTestableHarness> {
  bool _covered = true;
  Timer? _uncoverTimer;

  @override
  void initState() {
    super.initState();
    _uncoverTimer = Timer(widget.uncoverAfter, () {
      if (!mounted) {
        return;
      }
      setState(() => _covered = false);
    });
  }

  @override
  void dispose() {
    _uncoverTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Center(
            child: TextButton(
              key: widget.primaryKey,
              onPressed: () {},
              child: const Text('Primary'),
            ),
          ),
          if (_covered)
            const Positioned.fill(
              child: ModalBarrier(dismissible: false, color: Colors.black54),
            ),
        ],
      ),
    );
  }
}

/// Harness with a keyed primary trigger and an `open_sheet` text button
/// that pushes a modal [BottomSheet] covering the primary trigger.
class PrimaryWithSheetTriggerHarness extends StatelessWidget {
  const PrimaryWithSheetTriggerHarness({super.key, required this.primaryKey});

  final Key primaryKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Center(
            child: TextButton(
              key: primaryKey,
              onPressed: () {},
              child: const Text('Primary'),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Builder(
              builder: (ctx) => TextButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) => const SizedBox(
                      height: 400,
                      child: Center(child: Text('SheetBody')),
                    ),
                  );
                },
                child: const Text('open_sheet'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
