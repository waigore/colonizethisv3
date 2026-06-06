import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generic [Notifier] for a single boolean toggle with a configurable default.
///
/// Replaces the repeated `build() => <default>` + single `set(bool)` template
/// previously duplicated across the in-game visibility/blocking toggle
/// providers (Refs #3279). Declare a site with
/// `NotifierProvider<StateToggleNotifier, bool>(() => StateToggleNotifier(true))`.
class StateToggleNotifier extends Notifier<bool> {
  StateToggleNotifier(this.defaultValue);

  /// Value returned by [build] at provider initialization and on [reset].
  final bool defaultValue;

  @override
  bool build() => defaultValue;

  /// Sets the toggle to [value].
  void set(bool value) => state = value;

  /// Flips the current value.
  void toggle() => state = !state;

  /// Restores [defaultValue].
  void reset() => state = defaultValue;
}
