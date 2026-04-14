class MapViewState {
  const MapViewState({
    this.zoomMultiplier = 1.0,
    this.showProvinceOverlay = true,
    this.showProvinceOwnershipTint = false,
    this.showProvinceNamesLayer = true,
    this.showPlayerTurnEventsFeed = false,
  });

  final double zoomMultiplier;
  final bool showProvinceOverlay;
  final bool showProvinceOwnershipTint;
  final bool showProvinceNamesLayer;
  final bool showPlayerTurnEventsFeed;

  static const MapViewState defaults = MapViewState();

  Map<String, dynamic> toJson() => {
    'zoomMultiplier': zoomMultiplier,
    'showProvinceOverlay': showProvinceOverlay,
    'showProvinceOwnershipTint': showProvinceOwnershipTint,
    'showProvinceNamesLayer': showProvinceNamesLayer,
    'showPlayerTurnEventsFeed': showPlayerTurnEventsFeed,
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
    );
  }

  MapViewState copyWith({
    double? zoomMultiplier,
    bool? showProvinceOverlay,
    bool? showProvinceOwnershipTint,
    bool? showProvinceNamesLayer,
    bool? showPlayerTurnEventsFeed,
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
          showPlayerTurnEventsFeed == other.showPlayerTurnEventsFeed;

  @override
  int get hashCode => Object.hash(
    zoomMultiplier,
    showProvinceOverlay,
    showProvinceOwnershipTint,
    showProvinceNamesLayer,
    showPlayerTurnEventsFeed,
  );
}
