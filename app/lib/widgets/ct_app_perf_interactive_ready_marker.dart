import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Emits one [CtAppPerf] instant marker after the first frame with [child] mounted.
///
/// Use for empire-rail and overlay surfaces where `interactiveReady` marks
/// chrome + primary body paint (Refs #4688, #4690).
class CtAppPerfInteractiveReadyMarker extends StatefulWidget {
  const CtAppPerfInteractiveReadyMarker({
    super.key,
    required this.markerName,
    required this.child,
  });

  final String markerName;
  final Widget child;

  @override
  State<CtAppPerfInteractiveReadyMarker> createState() =>
      _CtAppPerfInteractiveReadyMarkerState();
}

class _CtAppPerfInteractiveReadyMarkerState
    extends State<CtAppPerfInteractiveReadyMarker> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ctAppPerfInstant(widget.markerName);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
