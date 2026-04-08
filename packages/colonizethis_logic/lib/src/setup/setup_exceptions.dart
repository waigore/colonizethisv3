import 'setup_validation_exception.dart';

/// Thrown when a Great Power cannot be assigned a valid sea-bound capital province.
class NoSeaBoundCapitalProvinceException extends SetupValidationException {
  static const codeValue = 'no_sea_bound_capital_province';
  final String code = codeValue;

  NoSeaBoundCapitalProvinceException({required String details})
    : super(details);
}

/// Thrown when a sea-bound GP capital province has no coastal tile candidate.
class NoCoastalCapitalTileForGpException extends SetupValidationException {
  static const codeValue = 'no_coastal_capital_tile_for_gp';
  final String code = codeValue;

  NoCoastalCapitalTileForGpException({required String details})
    : super(details);
}

/// Thrown when setup receives an invalid capital tile/province combination.
class CapitalTileMismatchException extends SetupValidationException {
  static const codeValue = 'capital_tile_province_mismatch';
  final String code = codeValue;

  CapitalTileMismatchException({required String details}) : super(details);
}

/// Thrown when setup cannot resolve required map/topology data for a region/province.
class SetupTopologyDataException extends SetupValidationException {
  final String code;

  SetupTopologyDataException({required String code, required String details})
    : code = code,
      super(details);
}

/// Thrown when setup config values are inconsistent with required faction counts.
class SetupConfigConstraintException extends SetupValidationException {
  final String code;

  SetupConfigConstraintException({
    required String code,
    required String details,
  }) : code = code,
       super(details);
}
