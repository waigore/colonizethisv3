import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:flutter/material.dart';

/// Production rail is present but tapping it never mounts the panel root.
class NoOpProductionRailHarness extends StatelessWidget {
  const NoOpProductionRailHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kEmpireProductionButtonKey,
            onPressed: () {
              // Intentionally no panel-mount side effect — the inner post-tap
              // wait must exhaust without `fail()`, and the outer loop must
              // surface the timeout failure (Refs GitHub #2336).
            },
            child: const Text('Production'),
          ),
        ],
      ),
    );
  }
}

/// Mounts the panel root synchronously on the rail tap.
class ProductionRailHarness extends StatefulWidget {
  const ProductionRailHarness();

  @override
  State<ProductionRailHarness> createState() => _ProductionRailHarnessState();
}

class _ProductionRailHarnessState extends State<ProductionRailHarness> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kEmpireProductionButtonKey,
            onPressed: () => setState(() => _panelOpen = true),
            child: const Text('Production'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2EProductionPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}

/// Mounts the panel root only after [mountAfter] so adaptive post-tap waits run.
class DelayedProductionPanelHarness extends StatefulWidget {
  const DelayedProductionPanelHarness({required this.mountAfter});

  final Duration mountAfter;

  @override
  State<DelayedProductionPanelHarness> createState() =>
      _DelayedProductionPanelHarnessState();
}

class _DelayedProductionPanelHarnessState
    extends State<DelayedProductionPanelHarness> {
  bool _panelOpen = false;
  bool _scheduled = false;

  void _handleTap() {
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    Future<void>.delayed(widget.mountAfter, () {
      if (!mounted) {
        return;
      }
      setState(() => _panelOpen = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kEmpireProductionButtonKey,
            onPressed: _handleTap,
            child: const Text('Production'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2EProductionPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}
