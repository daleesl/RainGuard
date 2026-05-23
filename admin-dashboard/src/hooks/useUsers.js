import { useEffect, useMemo, useState } from 'react'
import { collection, onSnapshot } from 'firebase/firestore'
import { db } from '../firebase'

export function useUsers() {
  const [users, setUsers] = useState([])
  const [status, setStatus] = useState('loading')
  const [error, setError] = useState('')

  useEffect(() => {
    const unsubscribe = onSnapshot(
      collection(db, 'users'),
      (snapshot) => {
        setUsers(snapshot.docs.map((doc) => parseUser(doc.id, doc.data())))
        setStatus('ready')
        setError('')
      },
      (snapshotError) => {
        setStatus('error')
        setError(snapshotError.message)
      },
    )

    return unsubscribe
  }, [])

  const pendingUsers = useMemo(
    () =>
      users.filter((user) =>
        ['pending', 'unverified', 'rejected'].includes(user.verificationStatus),
      ),
    [users],
  )

  return { users, pendingUsers, status, error }
}

function parseUser(id, data) {
  const displayName =
    data.display_name ||
    [data.first_name, data.last_name].filter(Boolean).join(' ') ||
    data.email ||
    'RainGuard user'

  return {
    id,
    accountStatus:
      data.account_status || data.accountStatus || (data.disabled ? 'disabled' : 'active'),
    disabled: Boolean(data.disabled),
    authProvider: data.auth_provider || data.authProvider || 'email',
    displayName,
    email: data.email || '',
    firstName: data.first_name || '',
    lastName: data.last_name || '',
    photoUrl: data.photo_url || data.photoUrl || '',
    role: data.role || (data.admin || data.is_admin ? 'admin' : 'resident'),
    verificationIdFrontUrl:
      data.verification_id_front_url ||
      data.verificationIdFrontUrl ||
      data.verification_image_url ||
      data.verificationImageUrl ||
      data.id_photo_url ||
      data.idPhotoUrl ||
      '',
    verificationStatus:
      data.verification_status || data.verificationStatus || 'unverified',
    verificationSubmittedAt:
      data.verification_submitted_at?.toDate?.() ||
      parseDate(data.verificationSubmittedAt),
    lastLoginAt: data.last_login_at?.toDate?.() || parseDate(data.lastLoginAt),
    updatedAt: data.updated_at?.toDate?.() || parseDate(data.updatedAt),
    createdAt: data.created_at?.toDate?.() || parseDate(data.createdAt),
  }
}

function parseDate(value) {
  if (!value) return null
  if (value instanceof Date) return value
  if (typeof value?.toDate === 'function') return value.toDate()
  const parsed = new Date(value)
  return Number.isNaN(parsed.getTime()) ? null : parsed
}
