/// Base type for setup-time validation failures in colonizethis_logic.
class SetupValidationException implements Exception {
  const SetupValidationException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SetupValidationException($code): $message';
}

/// Thrown when a Great Power cannot be assigned a valid sea-bound capital province.
class NoSeaBoundCapitalProvinceException extends SetupValidationException {
  NoSeaBoundCapitalProvinceException({required String details})
    : super('no_sea_bound_capital_province', details);
}

/// Thrown when a sea-bound GP capital province has no coastal tile candidate.
class NoCoastalCapitalTileForGpException extends SetupValidationException {
  NoCoastalCapitalTileForGpException({required String details})
    : super('no_coastal_capital_tile_for_gp', details);
}

/// Thrown when setup receives an invalid capital tile/province combination.
class CapitalTileMismatchException extends SetupValidationException {
  CapitalTileMismatchException({required String details})
    : super('capital_tile_province_mismatch', details);
}

/// Thrown when setup cannot resolve required map/topology data for a region/province.
class SetupTopologyDataException extends SetupValidationException {
  SetupTopologyDataException({required String code, required String details})
    : super(code, details);
}

/// Thrown when setup config values are inconsistent with required faction counts.
class SetupConfigConstraintException extends SetupValidationException {
  SetupConfigConstraintException({
    required String code,
    required String details,
  }) : super(code, details);
}
