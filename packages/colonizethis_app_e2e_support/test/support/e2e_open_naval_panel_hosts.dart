// Extracted from e2e_open_naval_panel_test.dart (#4598 headroom).
library;

import 'dart:async';

import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:flutter/material.dart';

/// Mounts the naval panel root synchronously when the empire rail is tapped.
class NavalRailHost extends StatefulWidget {
  const NavalRailHost({super.key});

  @override
  State<NavalRailHost> createState() => _NavalRailHostState();
}

class _NavalRailHostState extends State<NavalRailHost> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kEmpireNavalUnitsButtonKey,
            onPressed: () => setState(() => _panelOpen = true),
            child: const Text('Naval'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ENavalPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}

/// First-fleet marker only — no empire rail button.
class NavalMarkerOnlyHost extends StatefulWidget {
  const NavalMarkerOnlyHost({super.key});

  @override
  State<NavalMarkerOnlyHost> createState() => _NavalMarkerOnlyHostState();
}

class _NavalMarkerOnlyHostState extends State<NavalMarkerOnlyHost> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kCtE2EOpenFirstFleetMarkerPanelKey,
            onPressed: () => setState(() => _panelOpen = true),
            child: const Text('Marker'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ENavalPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}

/// Panel mounts after [mountAfter] so adaptive post-tap waits run.
class DelayedNavalPanelHost extends StatefulWidget {
  const DelayedNavalPanelHost({super.key, required this.mountAfter});

  final Duration mountAfter;

  @override
  State<DelayedNavalPanelHost> createState() => _DelayedNavalPanelHostState();
}

class _DelayedNavalPanelHostState extends State<DelayedNavalPanelHost> {
  bool _panelOpen = false;
  bool _scheduled = false;

  void _handleTap() {
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    Timer(widget.mountAfter, () {
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
            key: kEmpireNavalUnitsButtonKey,
            onPressed: _handleTap,
            child: const Text('Naval'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ENavalPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}
