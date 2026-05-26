import { useEffect, useState } from 'react'
import { collection, limit, onSnapshot, orderBy, query } from 'firebase/firestore'
import { db } from '../firebase'

const ALERT_QUERY_LIMIT = 75

export function useAlerts() {
  const [alerts, setAlerts] = useState([])
  const [status, setStatus] = useState('loading')
  const [error, setError] = useState('')

  useEffect(() => {
    const alertsQuery = query(
      collection(db, 'alerts'),
      orderBy('created_at', 'desc'),
      limit(ALERT_QUERY_LIMIT),
    )

    const unsubscribe = onSnapshot(
      alertsQuery,
      (snapshot) => {
        setAlerts(snapshot.docs.map((alertDoc) => parseAlert(alertDoc.id, alertDoc.data())))
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

  return { alerts, status, error }
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
