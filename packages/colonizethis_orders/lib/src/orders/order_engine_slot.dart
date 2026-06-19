/// Slot descriptor and order-map deep-copy helper shared by the hand-written
/// `order_engine.dart` and the generated `order_engine.g.dart` library.
///
/// Kept in its own library (not re-exported from the package barrel) so the
/// generated slot/mixin code can be a standalone library with explicit
/// `import` declarations instead of a `part of 'order_engine.dart'` fragment,
/// without widening the package's public API surface (Refs #3543; extraction
/// shape per `SPEC/program/dart-file-non-comment-line-size.md` § Extraction
/// shape).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Deep-copy of order maps: new map and new list per player. Used by the
/// generated `copyInitialOrdersForEngine` / `copyOrdersSnapshotForEngine`
/// helpers.
Map<String, List<T>> copyMapOfOrderLists<T>(Map<String, List<T>> map) =>
    Map.from(map)..updateAll((_, v) => List<T>.from(v));

/// One order-type slot: how to read/replace its per-player map on [Orders] plus
/// a log label. Consumed by the generated add/remove/withContext methods.
class OrderSlot<T> {
  const OrderSlot({
    required this.getter,
    required this.updater,
    required this.label,
  });

  final Map<String, List<T>> Function(Orders) getter;
  final Orders Function(Orders, Map<String, List<T>>) updater;
  final String label;
}
