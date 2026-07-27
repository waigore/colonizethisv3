// Per-order naval-move handlers (dock / at-sea) for naval resolution
// (Refs #3290 Phase-0 file-split, #4168 wave-5 destination/handler split).
// Imported by `naval_resolution.dart`; handlers stay unexported from the
// package barrel.

export 'naval_resolution_move_dock.dart' show applyDockNavalMoveOrder;
export 'naval_resolution_move_sea.dart' show applySeaNavalMoveOrder;
