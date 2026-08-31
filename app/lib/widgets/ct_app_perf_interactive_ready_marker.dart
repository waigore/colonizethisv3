import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../package_logger.dart';

/// Emits one [CtAppPerf] instant marker after the first frame with [child] mounted.
///
/// When [surfaceOpenId] is set, also tracks wall-clock open-to-interactive and
/// logs `ui_surface_open` on profile/release binding hosts (Refs #4687, #4688).
class CtAppPerfInteractiveReadyMarker extends StatefulWidget {
  const CtAppPerfInteractiveReadyMarker({
    super.key,
    required this.markerName,
    required this.child,
    this.surfaceOpenId,
  });

  final String markerName;
  final Widget child;

  /// Optional surface id for wall-clock segment tracking (e.g. `trade`).
  final String? surfaceOpenId;

  @override
  State<CtAppPerfInteractiveReadyMarker> createState() =>
      _CtAppPerfInteractiveReadyMarkerState();
}

class _CtAppPerfInteractiveReadyMarkerState
    extends State<CtAppPerfInteractiveReadyMarker> {
  static final _log = packageLogger('perf');

  @override
  void initState() {
    super.initState();
    final surfaceOpenId = widget.surfaceOpenId;
    if (surfaceOpenId != null) {
      ctAppPerfSurfaceOpenBegin(surfaceOpenId);
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final surfaceOpenId = widget.surfaceOpenId;
      if (surfaceOpenId != null) {
        final elapsedMs = ctAppPerfSurfaceOpenInteractiveReady(surfaceOpenId);
        if ((kProfileMode || kReleaseMode) && elapsedMs != null) {
          final host = ctAppPerfSurfaceOpenBindingHost();
          _log.i(
            'ui_surface_open surface=$surfaceOpenId elapsed_ms=$elapsedMs '
            'budget_ms=$kUiSurfaceOpenBudgetMs host=$host',
          );
        }
        return;
      }
      ctAppPerfInstant(widget.markerName);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
