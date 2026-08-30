// Extracted from e2e_open_panel_from_marker_test.dart (#4598 headroom).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Key kOpenPanelFromMarkerTestMarkerKey = Key(
  'e2e_open_panel_from_marker_test_marker',
);
const Key kOpenPanelFromMarkerTestPanelKey = Key(
  'e2e_open_panel_from_marker_test_panel',
);

/// Host that mounts a marker button and conditionally mounts a panel root
/// (sync or async) on the marker tap. An optional overlay covers the marker
/// with a hit-testable `OK` text so `e2eDismissTransientUi` can clear it.
class OpenPanelFromMarkerHost extends StatefulWidget {
  const OpenPanelFromMarkerHost({
    super.key,
    this.startWithOverlay = false,
    this.mountDelayOnTap,
    this.includeMarker = true,
  });

  final bool startWithOverlay;
  final Duration? mountDelayOnTap;
  final bool includeMarker;

  @override
  State<OpenPanelFromMarkerHost> createState() =>
      _OpenPanelFromMarkerHostState();
}

class _OpenPanelFromMarkerHostState extends State<OpenPanelFromMarkerHost> {
  late bool _showOverlay;
  bool _showPanel = false;
  Timer? _delayedMountTimer;

  @override
  void initState() {
    super.initState();
    _showOverlay = widget.startWithOverlay;
  }

  @override
  void dispose() {
    _delayedMountTimer?.cancel();
    super.dispose();
  }

  void _onMarkerPressed() {
    final delay = widget.mountDelayOnTap;
    if (delay == null) {
      setState(() => _showPanel = true);
      return;
    }
    _delayedMountTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _showPanel = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.includeMarker)
          Center(
            child: TextButton(
              key: kOpenPanelFromMarkerTestMarkerKey,
              onPressed: _onMarkerPressed,
              child: const Text('marker'),
            ),
          ),
        if (_showPanel)
          KeyedSubtree(
            key: kOpenPanelFromMarkerTestPanelKey,
            child: const ColoredBox(color: Color(0xFF112233)),
          ),
        if (_showOverlay)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xCC000000),
              child: Center(
                child: TextButton(
                  onPressed: () => setState(() => _showOverlay = false),
                  child: const Text('OK'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> pumpOpenPanelFromMarkerHost(
  WidgetTester tester, {
  bool startWithOverlay = false,
  Duration? mountDelayOnTap,
  bool includeMarker = true,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: OpenPanelFromMarkerHost(
          startWithOverlay: startWithOverlay,
          mountDelayOnTap: mountDelayOnTap,
          includeMarker: includeMarker,
        ),
      ),
    ),
  );
}
