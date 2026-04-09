/// Thrown when a Hive game envelope has a missing or unsupported
/// [saveFormatVersion]. SPEC/program/save-load.md.
class IncompatibleSaveFormatException implements Exception {
  IncompatibleSaveFormatException(this.message);

  final String message;

  @override
  String toString() => 'IncompatibleSaveFormatException: $message';
}
