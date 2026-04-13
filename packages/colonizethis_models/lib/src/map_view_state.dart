class MapViewState {
  const MapViewState({
    this.zoomMultiplier = 1.0,
    this.showProvinceOverlay = true,
    this.showProvinceOwnershipTint = false,
    this.showProvinceNamesLayer = true,
  });

  final double zoomMultiplier;
  final bool showProvinceOverlay;
  final bool showProvinceOwnershipTint;
  final bool showProvinceNamesLayer;

  static const MapViewState defaults = MapViewState();

  Map<String, dynamic> toJson() => {
    'zoomMultiplier': zoomMultiplier,
    'showProvinceOverlay': showProvinceOverlay,
    'showProvinceOwnershipTint': showProvinceOwnershipTint,
    'showProvinceNamesLayer': showProvinceNamesLayer,
  };

  static MapViewState fromJson(Map<String, dynamic> json) {
    return MapViewState(
      zoomMultiplier: (json['zoomMultiplier'] as num?)?.toDouble() ?? 1.0,
      showProvinceOverlay: json['showProvinceOverlay'] as bool? ?? true,
      showProvinceOwnershipTint:
          json['showProvinceOwnershipTint'] as bool? ?? false,
      showProvinceNamesLayer: json['showProvinceNamesLayer'] as bool? ?? true,
    );
  }

  MapViewState copyWith({
    double? zoomMultiplier,
    bool? showProvinceOverlay,
    bool? showProvinceOwnershipTint,
    bool? showProvinceNamesLayer,
  }) {
    return MapViewState(
      zoomMultiplier: zoomMultiplier ?? this.zoomMultiplier,
      showProvinceOverlay: showProvinceOverlay ?? this.showProvinceOverlay,
      showProvinceOwnershipTint:
          showProvinceOwnershipTint ?? this.showProvinceOwnershipTint,
      showProvinceNamesLayer:
          showProvinceNamesLayer ?? this.showProvinceNamesLayer,
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
          showProvinceNamesLayer == other.showProvinceNamesLayer;

  @override
  int get hashCode => Object.hash(
    zoomMultiplier,
    showProvinceOverlay,
    showProvinceOwnershipTint,
    showProvinceNamesLayer,
  );
}
