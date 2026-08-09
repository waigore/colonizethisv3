import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global province/sea boundary strokes on in-game Empire overview maps.
/// Defaults to true at app start; updated via the Map display options dialog.
/// SPEC/ui/map-widget.md, SPEC/ui/empire-overview.md.
final mapProvinceOverlayVisibleProvider =
    NotifierProvider<StateToggleNotifier, bool>(
      () => StateToggleNotifier(true),
    );

/// Great Power land ownership tint on in-game Empire overview maps.
/// Independent of [mapProvinceOverlayVisibleProvider]. Defaults to false at app start.
final mapProvinceOwnershipTintVisibleProvider =
    NotifierProvider<StateToggleNotifier, bool>(
      () => StateToggleNotifier(false),
    );

/// Global land province name labels on in-game Empire overview maps.
/// Independent of boundary and ownership-tint toggles. Defaults to true at app start.
final mapProvinceNamesVisibleProvider =
    NotifierProvider<StateToggleNotifier, bool>(
      () => StateToggleNotifier(true),
    );
