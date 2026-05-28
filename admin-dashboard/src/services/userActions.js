import { doc, serverTimestamp, updateDoc } from 'firebase/firestore'
import { auth, db } from '../firebase'

export function updateUserAccount(userId, values) {
  return updateDoc(doc(db, 'users', userId), {
    ...values,
    updated_at: serverTimestamp(),
  })
}

export function suspendUser(userId) {
  return updateUserAccount(userId, {
    account_status: 'suspended',
    disabled: false,
  })
}

export function disableUser(userId) {
  return updateUserAccount(userId, {
    account_status: 'disabled',
    disabled: true,
  })
}

export function restoreUser(userId) {
  return updateUserAccount(userId, {
    account_status: 'active',
    disabled: false,
  })
}

export function updateVerificationStatus(userId, status, values = {}) {
  return updateUserAccount(userId, {
    verification_status: status,
    verification_reviewed_at: serverTimestamp(),
    verification_reviewed_by: auth.currentUser?.uid || 'admin_dashboard',
    ...values,
  })
}

export function approveVerification(userId) {
  return updateVerificationStatus(userId, 'verified', {
    verification_rejection_reason: null,
  })
}

export function rejectVerification(userId, reason) {
  return updateVerificationStatus(userId, 'rejected', {
    verification_rejection_reason: reason,
  })
}

export function requestNewVerificationPhoto(userId) {
  return updateVerificationStatus(userId, 'rejected', {
    verification_rejection_reason:
      'Please upload a clearer valid ID photo for review.',
  })
}
