import { useEffect, useMemo, useState } from 'react'
import {
  collection,
  getDocs,
  limit,
  onSnapshot,
  orderBy,
  query,
  startAfter,
} from 'firebase/firestore'
import { db } from '../firebase'
import { friendlyFirebaseError } from '../utils/firebaseErrors'

const USER_PAGE_SIZE = 50

export function useUsers() {
  const [firstPageUsers, setFirstPageUsers] = useState([])
  const [olderUsers, setOlderUsers] = useState([])
  const [pageCursor, setPageCursor] = useState(null)
  const [status, setStatus] = useState('loading')
  const [error, setError] = useState('')
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const [hasMore, setHasMore] = useState(true)

  useEffect(() => {
    const usersQuery = query(
      collection(db, 'users'),
      orderBy('created_at', 'desc'),
      limit(USER_PAGE_SIZE),
    )

    const unsubscribe = onSnapshot(
      usersQuery,
      (snapshot) => {
        setFirstPageUsers(
          snapshot.docs.map((doc) => parseUser(doc.id, doc.data())),
        )
        setPageCursor(snapshot.docs.at(-1) || null)
        setHasMore(snapshot.docs.length === USER_PAGE_SIZE)
        setStatus('ready')
        setError('')
      },
      (snapshotError) => {
        setStatus('error')
        setError(friendlyFirebaseError(snapshotError, 'Unable to load users.'))
      },
    )

    return unsubscribe
  }, [])

  const users = useMemo(
    () => dedupeUsers([...firstPageUsers, ...olderUsers]),
    [firstPageUsers, olderUsers],
  )

  const pendingUsers = useMemo(
    () =>
      users.filter((user) =>
        ['pending', 'unverified', 'rejected'].includes(user.verificationStatus),
      ),
    [users],
  )

  async function loadMore() {
    if (!pageCursor || isLoadingMore || !hasMore) return

    setIsLoadingMore(true)
    try {
      const nextQuery = query(
        collection(db, 'users'),
        orderBy('created_at', 'desc'),
        startAfter(pageCursor),
        limit(USER_PAGE_SIZE),
      )
      const snapshot = await getDocs(nextQuery)
      setOlderUsers((current) =>
        dedupeUsers([
          ...current,
          ...snapshot.docs.map((doc) => parseUser(doc.id, doc.data())),
        ]),
      )
      setPageCursor(snapshot.docs.at(-1) || pageCursor)
      setHasMore(snapshot.docs.length === USER_PAGE_SIZE)
      setError('')
    } catch (loadError) {
      setError(friendlyFirebaseError(loadError, 'Unable to load older users.'))
    } finally {
      setIsLoadingMore(false)
    }
  }

  return {
    users,
    pendingUsers,
    status,
    error,
    hasMore,
    isLoadingMore,
    loadMore,
  }
}

function dedupeUsers(items) {
  return [...new Map(items.map((item) => [item.id, item])).values()]
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
