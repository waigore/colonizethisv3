/// A 1:1 link between a sea zone on one region and a sea zone on another.
/// SPEC/game/map-topology.md § Warp zones; produced during world generation per game-setup-pipeline.
class WarpLink {
  const WarpLink({
    required this.regionId,
    required this.seaZoneId,
    required this.otherRegionId,
    required this.otherSeaZoneId,
  });

  final String regionId;
  final String seaZoneId;
  final String otherRegionId;
  final String otherSeaZoneId;

  /// Prefixed sea zone key for this side (regionId|seaZoneId).
  String get prefixedKey => '$regionId|$seaZoneId';

  /// Prefixed sea zone key for the other side.
  String get otherPrefixedKey => '$otherRegionId|$otherSeaZoneId';

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'regionId': regionId,
        'seaZoneId': seaZoneId,
        'otherRegionId': otherRegionId,
        'otherSeaZoneId': otherSeaZoneId,
      };

  /// Deserializes from JSON.
  factory WarpLink.fromJson(Map<String, dynamic> json) => WarpLink(
        regionId: json['regionId'] as String,
        seaZoneId: json['seaZoneId'] as String,
        otherRegionId: json['otherRegionId'] as String,
        otherSeaZoneId: json['otherSeaZoneId'] as String,
      );
}
