import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the in-game region minimap is shown. Session-only; default true at shell entry.
/// SPEC/ui/empire-overview.md § Region minimap.
class RegionMinimapVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setVisible(bool value) => state = value;

  void toggle() => state = !state;

  void resetToDefault() => state = true;
}

final regionMinimapVisibleProvider =
    NotifierProvider<RegionMinimapVisibleNotifier, bool>(
      RegionMinimapVisibleNotifier.new,
    );
