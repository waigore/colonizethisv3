library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const kRailKey = ValueKey<String>('e2e_opvrom_rail');
const kMarkerKey = ValueKey<String>('e2e_opvrom_marker');
const kPanelKey = ValueKey<String>('e2e_opvrom_panel');

class TapCounter {
  int rail = 0;
  int marker = 0;
}


class _PanelRoot extends StatelessWidget {
  const _PanelRoot();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: kPanelKey,
      color: Color(0xFFEEEEEE),
      child: SizedBox(width: 200, height: 120),
    );
  }
}

/// Harness exposing both the rail and marker triggers. The panel root is
/// mounted when either trigger is tapped (mirroring the production opener
/// surface where both arms can open the same panel root).
class RailMarkerPanelHarness extends StatefulWidget {
  const RailMarkerPanelHarness(this.counter, {this.panelMounted = false});

  final TapCounter counter;
  final bool panelMounted;

  @override
  State<RailMarkerPanelHarness> createState() =>
      _RailMarkerPanelHarnessState();
}

class _RailMarkerPanelHarnessState extends State<RailMarkerPanelHarness> {
  late bool _panelOpen = widget.panelMounted;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            TextButton(
              key: kRailKey,
              onPressed: () {
                widget.counter.rail++;
                setState(() => _panelOpen = true);
              },
              child: const Text('Rail'),
            ),
            TextButton(
              key: kMarkerKey,
              onPressed: () {
                widget.counter.marker++;
                setState(() => _panelOpen = true);
              },
              child: const Text('Marker'),
            ),
            if (_panelOpen) const _PanelRoot(),
          ],
        ),
      ),
    );
  }
}

/// Harness exposing only the marker trigger — used to pin the marker
/// fallback arm of [e2eOpenPanelViaRailOrMarker] when the rail finder
/// resolves to zero elements.
class MarkerOnlyPanelHarness extends StatefulWidget {
  const MarkerOnlyPanelHarness(this.counter);

  final TapCounter counter;

  @override
  State<MarkerOnlyPanelHarness> createState() =>
      _MarkerOnlyPanelHarnessState();
}

class _MarkerOnlyPanelHarnessState extends State<MarkerOnlyPanelHarness> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            TextButton(
              key: kMarkerKey,
              onPressed: () {
                widget.counter.marker++;
                setState(() => _panelOpen = true);
              },
              child: const Text('Marker'),
            ),
            if (_panelOpen) const _PanelRoot(),
          ],
        ),
      ),
    );
  }
}

/// Harness that mounts the panel root only after a fake-async timer fires,
/// so the helper exercises its adaptive post-tap mount probe before
/// returning. Mirrors the async-mount pattern in
/// `app/test/e2e_open_civilian_panel_test.dart`.
class DelayedPanelHarness extends StatefulWidget {
  const DelayedPanelHarness(this.counter, {required this.mountAfter});

  final TapCounter counter;
  final Duration mountAfter;

  @override
  State<DelayedPanelHarness> createState() => _DelayedPanelHarnessState();
}

class _DelayedPanelHarnessState extends State<DelayedPanelHarness> {
  bool _panelOpen = false;
  bool _scheduled = false;

  void _handleRailTap() {
    widget.counter.rail++;
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    Timer(widget.mountAfter, () {
      if (!mounted) return;
      setState(() => _panelOpen = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            TextButton(
              key: kRailKey,
              onPressed: _handleRailTap,
              child: const Text('Rail'),
            ),
            TextButton(
              key: kMarkerKey,
              onPressed: () => widget.counter.marker++,
              child: const Text('Marker'),
            ),
            if (_panelOpen) const _PanelRoot(),
          ],
        ),
      ),
    );
  }
}

