class MapViewState {
  /// Model / legacy defaults. Constructor and [fromJson] missing-field
  /// fallbacks keep [showPlayersBar] **true** so legacy saves without the
  /// field stay visible. New campaigns set `showPlayersBar: false` only in
  /// standard game setup (`game_setup_create_initial_game.dart`; Refs #3986).
  /// [showCapitalLinkDisconnectedHighlight] defaults **true** (Refs #4370).
  const MapViewState({
    this.zoomMultiplier = 1.0,
    this.showProvinceOverlay = true,
    this.showProvinceOwnershipTint = false,
    this.showProvinceNamesLayer = true,
    this.showCapitalLinkDisconnectedHighlight = true,
    this.showPlayerTurnEventsFeed = false,
    this.showPlayersBar = true,
  });

  final double zoomMultiplier;
  final bool showProvinceOverlay;
  final bool showProvinceOwnershipTint;
  final bool showProvinceNamesLayer;

  /// When true, human/viewing-player owned land tiles not in the capital
  /// connected set receive the disconnected hatch on MAP10001 (Refs #4370).
  final bool showCapitalLinkDisconnectedHighlight;
  final bool showPlayerTurnEventsFeed;
  final bool showPlayersBar;

  static const MapViewState defaults = MapViewState();

  Map<String, dynamic> toJson() => {
    'zoomMultiplier': zoomMultiplier,
    'showProvinceOverlay': showProvinceOverlay,
    'showProvinceOwnershipTint': showProvinceOwnershipTint,
    'showProvinceNamesLayer': showProvinceNamesLayer,
    'showCapitalLinkDisconnectedHighlight':
        showCapitalLinkDisconnectedHighlight,
    'showPlayerTurnEventsFeed': showPlayerTurnEventsFeed,
    'showPlayersBar': showPlayersBar,
  };

  static MapViewState fromJson(Map<String, dynamic> json) {
    return MapViewState(
      zoomMultiplier: (json['zoomMultiplier'] as num?)?.toDouble() ?? 1.0,
      showProvinceOverlay: json['showProvinceOverlay'] as bool? ?? true,
      showProvinceOwnershipTint:
          json['showProvinceOwnershipTint'] as bool? ?? false,
      showProvinceNamesLayer: json['showProvinceNamesLayer'] as bool? ?? true,
      showCapitalLinkDisconnectedHighlight:
          json['showCapitalLinkDisconnectedHighlight'] as bool? ?? true,
      showPlayerTurnEventsFeed:
          json['showPlayerTurnEventsFeed'] as bool? ?? false,
      showPlayersBar: json['showPlayersBar'] as bool? ?? true,
    );
  }

  MapViewState copyWith({
    double? zoomMultiplier,
    bool? showProvinceOverlay,
    bool? showProvinceOwnershipTint,
    bool? showProvinceNamesLayer,
    bool? showCapitalLinkDisconnectedHighlight,
    bool? showPlayerTurnEventsFeed,
    bool? showPlayersBar,
  }) {
    return MapViewState(
      zoomMultiplier: zoomMultiplier ?? this.zoomMultiplier,
      showProvinceOverlay: showProvinceOverlay ?? this.showProvinceOverlay,
      showProvinceOwnershipTint:
          showProvinceOwnershipTint ?? this.showProvinceOwnershipTint,
      showProvinceNamesLayer:
          showProvinceNamesLayer ?? this.showProvinceNamesLayer,
      showCapitalLinkDisconnectedHighlight:
          showCapitalLinkDisconnectedHighlight ??
          this.showCapitalLinkDisconnectedHighlight,
      showPlayerTurnEventsFeed:
          showPlayerTurnEventsFeed ?? this.showPlayerTurnEventsFeed,
      showPlayersBar: showPlayersBar ?? this.showPlayersBar,
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
          showCapitalLinkDisconnectedHighlight ==
              other.showCapitalLinkDisconnectedHighlight &&
          showPlayerTurnEventsFeed == other.showPlayerTurnEventsFeed &&
          showPlayersBar == other.showPlayersBar;

  @override
  int get hashCode => Object.hash(
    zoomMultiplier,
    showProvinceOverlay,
    showProvinceOwnershipTint,
    showProvinceNamesLayer,
    showCapitalLinkDisconnectedHighlight,
    showPlayerTurnEventsFeed,
    showPlayersBar,
  );
}
