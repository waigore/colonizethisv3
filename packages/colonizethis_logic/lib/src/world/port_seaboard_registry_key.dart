/// Decodes keys from [WorldState.portsByProvinceSeaboard].
///
/// Supported formats:
/// - Prefixed: `regionId|provinceLocalId|seaZoneId` (three or more segments;
///   [fullProvinceId] is `regionId|provinceLocalId`).
/// - Legacy: `provinceId|seaZoneId` (exactly two segments; [fullProvinceId] is
///   [parts[0]] as stored).
({
  String fullProvinceId,
  String seaZoneId,
  String regionId,
  bool isPrefixedKey,
})?
decodePortSeaboardRegistryKey(String key) {
  final parts = key.split('|');
  if (parts.length >= 3) {
    return (
      fullProvinceId: '${parts[0]}|${parts[1]}',
      seaZoneId: parts[2],
      regionId: parts[0],
      isPrefixedKey: true,
    );
  }
  if (parts.length >= 2) {
    return (
      fullProvinceId: parts[0],
      seaZoneId: parts[1],
      regionId: '',
      isPrefixedKey: false,
    );
  }
  return null;
}
