/// Thrown when E2E support helpers receive invalid parameters.
class E2eSupportValidationException implements Exception {
  E2eSupportValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
