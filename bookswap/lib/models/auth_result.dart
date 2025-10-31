// lib/models/auth_result.dart

/// Result class to encapsulate authentication results.
/// This provides more detailed information about the outcome of auth operations,
/// including success status, a user-friendly message, and an optional error code.
class AuthResult {
  /// Indicates whether the authentication operation was successful.
  final bool success;

  /// A user-friendly message describing the outcome.
  final String message;

  /// An optional error code, useful for specific error handling (e.g., 'email-already-in-use').
  final String? errorCode;

  /// Constructor for AuthResult.
  ///
  /// [success] should be true if the operation succeeded, false otherwise.
  /// [message] is the message to display to the user.
  /// [errorCode] can be provided to identify specific failure reasons.
  AuthResult({
    required this.success,
    required this.message,
    this.errorCode,
  });
}