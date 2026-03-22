// App event bus provider. One bus per ProviderScope / ProviderContainer.
// Use [AppEventBus.create] here — not [AppEventBus()] — so test containers can
// dispose without closing the global singleton used by legacy `AppEventBus()`.
// SPEC/program/app-event-bus.md.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final appEventBusProvider = Provider<AppEventBus>((ref) {
  final bus = AppEventBus.create();
  ref.onDispose(() => bus.dispose());
  return bus;
});
