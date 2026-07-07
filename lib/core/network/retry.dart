import 'dart:async';

/// Retries an async [action] with exponential backoff.
///
/// Used for transient Firestore/network failures. The [retryIf] predicate lets
/// callers avoid retrying non-transient errors (e.g. a validation failure).
Future<T> retryWithBackoff<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 400),
  bool Function(Object error)? retryIf,
}) async {
  assert(maxAttempts >= 1, 'maxAttempts must be at least 1');
  Duration delay = initialDelay;
  Object? lastError;

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } catch (error) {
      lastError = error;
      final bool shouldRetry = retryIf?.call(error) ?? true;
      if (!shouldRetry || attempt == maxAttempts) rethrow;
      await Future<void>.delayed(delay);
      delay *= 2;
    }
  }

  // Unreachable — the loop always returns or rethrows — but keeps the analyzer happy.
  throw lastError ?? StateError('retryWithBackoff exhausted without an error');
}
