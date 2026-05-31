import { useEffect, useState } from 'react'
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

const ALERT_PAGE_SIZE = 50

export function useAlerts() {
  const [firstPageAlerts, setFirstPageAlerts] = useState([])
  const [olderAlerts, setOlderAlerts] = useState([])
  const [pageCursor, setPageCursor] = useState(null)
  const [status, setStatus] = useState('loading')
  const [error, setError] = useState('')
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const [hasMore, setHasMore] = useState(true)

  useEffect(() => {
    const alertsQuery = query(
      collection(db, 'alerts'),
      orderBy('created_at', 'desc'),
      limit(ALERT_PAGE_SIZE),
    )

    const unsubscribe = onSnapshot(
      alertsQuery,
      (snapshot) => {
        setFirstPageAlerts(
          snapshot.docs.map((alertDoc) =>
            parseAlert(alertDoc.id, alertDoc.data()),
          ),
        )
        setPageCursor(snapshot.docs.at(-1) || null)
        setHasMore(snapshot.docs.length === ALERT_PAGE_SIZE)
        setStatus('ready')
        setError('')
      },
      (snapshotError) => {
        setStatus('error')
        setError(friendlyFirebaseError(snapshotError, 'Unable to load alerts.'))
      },
    )

    return unsubscribe
  }, [])

  const alerts = dedupeAlerts([...firstPageAlerts, ...olderAlerts])

  async function loadMore() {
    if (!pageCursor || isLoadingMore || !hasMore) return

    setIsLoadingMore(true)
    try {
      const nextQuery = query(
        collection(db, 'alerts'),
        orderBy('created_at', 'desc'),
        startAfter(pageCursor),
        limit(ALERT_PAGE_SIZE),
      )
      const snapshot = await getDocs(nextQuery)
      setOlderAlerts((current) =>
        dedupeAlerts([
          ...current,
          ...snapshot.docs.map((alertDoc) =>
            parseAlert(alertDoc.id, alertDoc.data()),
          ),
        ]),
      )
      setPageCursor(snapshot.docs.at(-1) || pageCursor)
      setHasMore(snapshot.docs.length === ALERT_PAGE_SIZE)
      setError('')
    } catch (loadError) {
      setError(friendlyFirebaseError(loadError, 'Unable to load older alerts.'))
    } finally {
      setIsLoadingMore(false)
    }
  }

  return { alerts, status, error, hasMore, isLoadingMore, loadMore }
}

export function isAlertToday(date) {
  if (!date) return false
  const now = new Date()
  return (
    date.getFullYear() === now.getFullYear() &&
    date.getMonth() === now.getMonth() &&
    date.getDate() === now.getDate()
  )
}

function parseAlert(id, data) {
  return {
    id,
    area: data.area || 'All residents',
    delivery: Array.isArray(data.delivery) ? data.delivery : ['in_app'],
    message: data.message || '',
    publishedAt: data.published_at?.toDate?.() || data.created_at?.toDate?.() || null,
    riskLevel: data.risk_level || 'info',
    source: data.source || 'manual',
    status: data.status || 'draft',
    title: data.title || 'Untitled advisory',
  }
}

function dedupeAlerts(items) {
  return [...new Map(items.map((item) => [item.id, item])).values()]
}
