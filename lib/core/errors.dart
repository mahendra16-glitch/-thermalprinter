/// A business rule was broken. [message] is written for staff and is shown
/// to them as-is.
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => message;
}
