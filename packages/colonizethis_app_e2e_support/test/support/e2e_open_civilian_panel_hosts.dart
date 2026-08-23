// Extracted from e2e_open_civilian_panel_test.dart (#4598 leftover host SoT).
library;

import 'dart:async';

import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:flutter/material.dart';

/// Mounts the civilian panel root synchronously when the empire rail is tapped.
class CivilianRailHost extends StatefulWidget {
  const CivilianRailHost({super.key});

  @override
  State<CivilianRailHost> createState() => _CivilianRailHostState();
}

class _CivilianRailHostState extends State<CivilianRailHost> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kEmpireCivilianUnitsButtonKey,
            onPressed: () => setState(() => _panelOpen = true),
            child: const Text('Civilian'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ECivilianPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}

/// First-civilian marker only — no empire rail button.
class CivilianMarkerOnlyHost extends StatefulWidget {
  const CivilianMarkerOnlyHost({super.key});

  @override
  State<CivilianMarkerOnlyHost> createState() => _CivilianMarkerOnlyHostState();
}

class _CivilianMarkerOnlyHostState extends State<CivilianMarkerOnlyHost> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextButton(
            key: kCtE2EOpenFirstCivilianMarkerPanelKey,
            onPressed: () => setState(() => _panelOpen = true),
            child: const Text('Marker'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ECivilianPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}

/// Panel mounts after [mountAfter] so adaptive post-tap waits run.
class DelayedCivilianPanelHost extends StatefulWidget {
  const DelayedCivilianPanelHost({super.key, required this.mountAfter});

  final Duration mountAfter;

  @override
  State<DelayedCivilianPanelHost> createState() =>
      _DelayedCivilianPanelHostState();
}

class _DelayedCivilianPanelHostState extends State<DelayedCivilianPanelHost> {
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
            key: kEmpireCivilianUnitsButtonKey,
            onPressed: _handleTap,
            child: const Text('Civilian'),
          ),
          if (_panelOpen)
            const KeyedSubtree(
              key: kCtE2ECivilianPanelRootKey,
              child: SizedBox(width: 100, height: 100),
            ),
        ],
      ),
    );
  }
}
