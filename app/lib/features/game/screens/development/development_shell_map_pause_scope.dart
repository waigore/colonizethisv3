import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/shell_main_map_pause_provider.dart';

/// Acquires a shell main-map pause hold for the lifetime of [child].
///
/// Used by `GAME80001` so the live game map Flame engine stops ticking while
/// the Development panel is mounted. Refs #4687.
class DevelopmentShellMapPauseScope extends ConsumerStatefulWidget {
  const DevelopmentShellMapPauseScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DevelopmentShellMapPauseScope> createState() =>
      _DevelopmentShellMapPauseScopeState();
}

class _DevelopmentShellMapPauseScopeState
    extends ConsumerState<DevelopmentShellMapPauseScope> {
  ShellMainMapPauseHold? _hold;
  var _acquired = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hold = ref.read(shellMainMapPauseHoldProvider.notifier);
      _hold!.acquire();
      _acquired = true;
    });
  }

  @override
  void dispose() {
    final hold = _hold;
    final acquired = _acquired;
    _hold = null;
    _acquired = false;
    if (acquired && hold != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => hold.release());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
