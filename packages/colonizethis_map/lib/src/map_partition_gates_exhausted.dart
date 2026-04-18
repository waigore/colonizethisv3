/// Thrown when [generateLockedFullInitTileMapPair] is called but
/// [GameSetupConfig.isLockedFullInitProfile] is false (GitHub #1830 / #1834).
class LockedFullInitProfileRequiredException implements Exception {
  LockedFullInitProfileRequiredException(this.message);

  final String message;

  @override
  String toString() => 'LockedFullInitProfileRequiredException: $message';
}

/// Thrown when bounded regeneration cannot produce OW+NW topologies that satisfy
/// locked full-init partition and feasibility gates (GitHub #1834 / SPEC).
class MapPartitionGatesExhaustedException implements Exception {
  MapPartitionGatesExhaustedException({
    required this.attempts,
    this.lastOwPartition,
    this.lastNwPartition,
  });

  static const String codeValue = 'map_partition_exhausted';

  final int attempts;
  final List<int>? lastOwPartition;
  final List<int>? lastNwPartition;

  String get code => codeValue;

  @override
  String toString() =>
      'MapPartitionGatesExhaustedException($codeValue): '
      '$attempts attempt(s); last OW multiset=$lastOwPartition '
      'NW multiset=$lastNwPartition';
}
