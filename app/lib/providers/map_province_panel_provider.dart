import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared UI state between the region map and the province/sea detail panel.
/// Map and panel stay decoupled: both read/write this provider only.
@immutable
class MapProvincePanelUiState {
  const MapProvincePanelUiState({
    this.overlayOpen = false,
    this.selectedTileKey,
    this.secondaryHighlightTileKey,
    this.secondaryHighlightTileKeys,
  });

  final bool overlayOpen;
  final String? selectedTileKey;

  /// List-hover / locate secondary cursor on the map (not the orange selection).
  final String? secondaryHighlightTileKey;

  /// Multi-tile secondary outlines (Extraction/Available commodity hover).
  /// When non-null and non-empty, takes precedence over [secondaryHighlightTileKey].
  final Set<String>? secondaryHighlightTileKeys;
}

/// Province / sea-zone id (`regionId|localId`) derived from a full tile key.
String? displayProvinceOrSeaIdFromTileKey(String? tileKey) {
  if (tileKey == null) return null;
  return tryParseTileKey(tileKey)?.prefixedProvinceId;
}

class MapProvincePanelNotifier extends Notifier<MapProvincePanelUiState> {
  @override
  MapProvincePanelUiState build() => const MapProvincePanelUiState();

  /// User tapped a map cell: select tile, open panel, keep secondary highlight as-is.
  void reportMapTileTapped(String tileKey) {
    state = MapProvincePanelUiState(
      overlayOpen: true,
      selectedTileKey: tileKey,
      secondaryHighlightTileKey: state.secondaryHighlightTileKey,
      secondaryHighlightTileKeys: state.secondaryHighlightTileKeys,
    );
  }

  void closeOverlay() {
    state = MapProvincePanelUiState(
      overlayOpen: false,
      selectedTileKey: state.selectedTileKey,
      secondaryHighlightTileKey: state.secondaryHighlightTileKey,
      secondaryHighlightTileKeys: state.secondaryHighlightTileKeys,
    );
  }

  /// Single-tile secondary highlight; clears multi-tile keys.
  void setSecondaryHighlight(String? tileKey) {
    state = MapProvincePanelUiState(
      overlayOpen: state.overlayOpen,
      selectedTileKey: state.selectedTileKey,
      secondaryHighlightTileKey: tileKey,
      secondaryHighlightTileKeys: null,
    );
  }

  /// Multi-tile secondary highlight; clears the single-key field.
  /// Pass null or empty to clear.
  void setSecondaryHighlights(Iterable<String>? tileKeys) {
    final keys = tileKeys == null ? null : Set<String>.of(tileKeys);
    state = MapProvincePanelUiState(
      overlayOpen: state.overlayOpen,
      selectedTileKey: state.selectedTileKey,
      secondaryHighlightTileKey: null,
      secondaryHighlightTileKeys: (keys == null || keys.isEmpty) ? null : keys,
    );
  }

  void reset() {
    state = const MapProvincePanelUiState();
  }
}

final mapProvincePanelProvider =
    NotifierProvider<MapProvincePanelNotifier, MapProvincePanelUiState>(
      MapProvincePanelNotifier.new,
    );
