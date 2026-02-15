/// Node in the map topology graph. SPEC/program/map-data.md, SPEC/game/map-topology.md.
enum TopologyNodeType {
  province,
  seaZone,
}

/// A province (P) or sea zone (S) in the topology graph.
class TopologyNode {
  const TopologyNode({
    required this.id,
    required this.regionId,
    required this.type,
  });

  final String id;
  final String regionId;
  final TopologyNodeType type;

  static const String _keyId = 'id';
  static const String _keyRegionId = 'regionId';
  static const String _keyType = 'type';
  static const String _typeProvince = 'province';
  static const String _typeSeaZone = 'seaZone';

  Map<String, dynamic> toJson() => {
        _keyId: id,
        _keyRegionId: regionId,
        _keyType: type == TopologyNodeType.province ? _typeProvince : _typeSeaZone,
      };

  static TopologyNode fromJson(Map<String, dynamic> json) {
    final typeStr = json[_keyType] as String? ?? '';
    final type = typeStr == _typeSeaZone
        ? TopologyNodeType.seaZone
        : TopologyNodeType.province;
    return TopologyNode(
      id: json[_keyId] as String,
      regionId: json[_keyRegionId] as String,
      type: type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopologyNode &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          regionId == other.regionId &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, regionId, type);
}
