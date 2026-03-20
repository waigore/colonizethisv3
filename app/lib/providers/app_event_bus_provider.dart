// App event bus provider. Riverpod provider wrapping AppEventBus singleton.
// SPEC/program/app-event-bus.md.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final appEventBusProvider = Provider<AppEventBus>((ref) {
  final bus = AppEventBus();
  ref.onDispose(() => bus.dispose());
  return bus;
});
