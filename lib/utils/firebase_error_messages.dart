String friendlyFirebaseError(
  Object? error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  final message = error.toString().toLowerCase();

  if (message.contains('permission-denied') ||
      message.contains('permission denied') ||
      message.contains('insufficient permissions')) {
    return 'You do not have permission to view this yet. Check your account status or try signing in again.';
  }

  if (message.contains('unavailable') || message.contains('network')) {
    return 'RainGuard cannot reach Firebase right now. Check your internet connection and try again.';
  }

  if (message.contains('failed-precondition') ||
      message.contains('requires an index')) {
    return 'This Firestore query needs an index. Ask the admin to deploy or create the required Firebase index.';
  }

  return fallback;
}
