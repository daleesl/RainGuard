export function friendlyFirebaseError(error, fallback = 'Unable to load records.') {
  const message = String(error?.message || error || '').toLowerCase()

  if (
    message.includes('permission-denied') ||
    message.includes('missing or insufficient permissions')
  ) {
    return 'Missing permission. Sign in with an admin account and confirm the Firestore user document has role: admin.'
  }

  if (message.includes('failed-precondition') || message.includes('index')) {
    return 'Firestore needs an index for this view. Deploy firestore.indexes.json or create the index from Firebase Console.'
  }

  if (message.includes('unavailable') || message.includes('network')) {
    return 'Firebase is unavailable right now. Check your internet connection and try again.'
  }

  return error?.message || fallback
}
