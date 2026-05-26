import { useEffect, useMemo, useState } from 'react'
import { collection, limit, onSnapshot, orderBy, query } from 'firebase/firestore'
import { db } from '../firebase'
import { isCalambaReport, parseReport } from '../utils/reports'

const REPORT_QUERY_LIMIT = 150

export function useReports() {
  const [reports, setReports] = useState([])
  const [status, setStatus] = useState('loading')
  const [error, setError] = useState('')

  useEffect(() => {
    const reportsQuery = query(
      collection(db, 'reports'),
      orderBy('created_at', 'desc'),
      limit(REPORT_QUERY_LIMIT),
    )

    const unsubscribe = onSnapshot(
      reportsQuery,
      (snapshot) => {
        setReports(snapshot.docs.map((doc) => parseReport(doc.id, doc.data())))
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

  const calambaReports = useMemo(
    () => reports.filter((report) => isCalambaReport(report)),
    [reports],
  )

  return { reports, calambaReports, status, error }
}
