import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the in-game region minimap is shown. Session-only; default true at shell entry.
/// SPEC/ui/empire-overview.md § Region minimap.
///
/// Backed by the shared [StateToggleNotifier]: use `.set(bool)` to assign,
/// `.toggle()` to flip, and `.reset()` to restore the default-true state.
final regionMinimapVisibleProvider =
    NotifierProvider<StateToggleNotifier, bool>(
      () => StateToggleNotifier(true),
    );
