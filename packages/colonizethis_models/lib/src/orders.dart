/// Per-player order models for the current turn.
///
/// SPEC/game/world-model, SPEC/program/orders.md.
///
/// Split by order family (Refs #3393 Phase 5c): the [Orders] container lives in
/// `orders/orders_container.dart`; concrete order types are grouped by family in
/// `orders/move_orders.dart`, `orders/build_orders.dart`,
/// `orders/work_orders.dart`, and `orders/research_orders.dart`. This file is a
/// thin re-export barrel so existing imports of `src/orders.dart` and the public
/// `colonizethis_models` barrel keep working unchanged.
library;

export 'orders/build_orders.dart';
export 'orders/move_orders.dart';
export 'orders/orders_container.dart';
export 'orders/research_orders.dart';
export 'orders/work_orders.dart';
