import 'map_base_layer_flags.dart';

class MapViewState {
  /// Model / legacy defaults. Constructor and [fromJson] missing-field
  /// fallbacks keep [showPlayersBar] **true** so legacy saves without the
  /// field stay visible. New campaigns set `showPlayersBar: false` only in
  /// standard game setup (`game_setup_create_initial_game.dart`; Refs #3986).
  /// Information-layer flags ([showMapResources], [showMapImprovements],
  /// [showMapRoads]) default **true** (full detail); missing JSON fields
  /// load as all-on (Refs #4388).
  const MapViewState({
    this.zoomMultiplier = 1.0,
    this.showProvinceOverlay = true,
    this.showProvinceOwnershipTint = false,
    this.showProvinceNamesLayer = true,
    this.showPlayerTurnEventsFeed = false,
    this.showPlayersBar = true,
    this.showMapResources = true,
    this.showMapImprovements = true,
    this.showMapRoads = true,
  });

  final double zoomMultiplier;
  final bool showProvinceOverlay;
  final bool showProvinceOwnershipTint;
  final bool showProvinceNamesLayer;
  final bool showPlayerTurnEventsFeed;
  final bool showPlayersBar;
  final bool showMapResources;
  final bool showMapImprovements;
  final bool showMapRoads;

  /// Paint/cycle source of truth for resource, improvement, and road marks.
  MapBaseLayerFlags get mapBaseLayerFlags => MapBaseLayerFlags(
    showResources: showMapResources,
    showImprovements: showMapImprovements,
    showRoads: showMapRoads,
  );

  static const MapViewState defaults = MapViewState();

  MapViewState withMapBaseLayerFlags(MapBaseLayerFlags flags) => copyWith(
    showMapResources: flags.showResources,
    showMapImprovements: flags.showImprovements,
    showMapRoads: flags.showRoads,
  );

  Map<String, dynamic> toJson() => {
    'zoomMultiplier': zoomMultiplier,
    'showProvinceOverlay': showProvinceOverlay,
    'showProvinceOwnershipTint': showProvinceOwnershipTint,
    'showProvinceNamesLayer': showProvinceNamesLayer,
    'showPlayerTurnEventsFeed': showPlayerTurnEventsFeed,
    'showPlayersBar': showPlayersBar,
    'showMapResources': showMapResources,
    'showMapImprovements': showMapImprovements,
    'showMapRoads': showMapRoads,
  };

  static MapViewState fromJson(Map<String, dynamic> json) {
    return MapViewState(
      zoomMultiplier: (json['zoomMultiplier'] as num?)?.toDouble() ?? 1.0,
      showProvinceOverlay: json['showProvinceOverlay'] as bool? ?? true,
      showProvinceOwnershipTint:
          json['showProvinceOwnershipTint'] as bool? ?? false,
      showProvinceNamesLayer: json['showProvinceNamesLayer'] as bool? ?? true,
      showPlayerTurnEventsFeed:
          json['showPlayerTurnEventsFeed'] as bool? ?? false,
      showPlayersBar: json['showPlayersBar'] as bool? ?? true,
      showMapResources: json['showMapResources'] as bool? ?? true,
      showMapImprovements: json['showMapImprovements'] as bool? ?? true,
      showMapRoads: json['showMapRoads'] as bool? ?? true,
    );
  }

  MapViewState copyWith({
    double? zoomMultiplier,
    bool? showProvinceOverlay,
    bool? showProvinceOwnershipTint,
    bool? showProvinceNamesLayer,
    bool? showPlayerTurnEventsFeed,
    bool? showPlayersBar,
    bool? showMapResources,
    bool? showMapImprovements,
    bool? showMapRoads,
  }) {
    return MapViewState(
      zoomMultiplier: zoomMultiplier ?? this.zoomMultiplier,
      showProvinceOverlay: showProvinceOverlay ?? this.showProvinceOverlay,
      showProvinceOwnershipTint:
          showProvinceOwnershipTint ?? this.showProvinceOwnershipTint,
      showProvinceNamesLayer:
          showProvinceNamesLayer ?? this.showProvinceNamesLayer,
      showPlayerTurnEventsFeed:
          showPlayerTurnEventsFeed ?? this.showPlayerTurnEventsFeed,
      showPlayersBar: showPlayersBar ?? this.showPlayersBar,
      showMapResources: showMapResources ?? this.showMapResources,
      showMapImprovements: showMapImprovements ?? this.showMapImprovements,
      showMapRoads: showMapRoads ?? this.showMapRoads,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapViewState &&
          runtimeType == other.runtimeType &&
          zoomMultiplier == other.zoomMultiplier &&
          showProvinceOverlay == other.showProvinceOverlay &&
          showProvinceOwnershipTint == other.showProvinceOwnershipTint &&
          showProvinceNamesLayer == other.showProvinceNamesLayer &&
          showPlayerTurnEventsFeed == other.showPlayerTurnEventsFeed &&
          showPlayersBar == other.showPlayersBar &&
          showMapResources == other.showMapResources &&
          showMapImprovements == other.showMapImprovements &&
          showMapRoads == other.showMapRoads;

  @override
  int get hashCode => Object.hash(
    zoomMultiplier,
    showProvinceOverlay,
    showProvinceOwnershipTint,
    showProvinceNamesLayer,
    showPlayerTurnEventsFeed,
    showPlayersBar,
    showMapResources,
    showMapImprovements,
    showMapRoads,
  );
}
