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
import { isCalambaReport, parseReport } from '../utils/reports'

const REPORT_PAGE_SIZE = 50

export function useReports() {
  const [firstPageReports, setFirstPageReports] = useState([])
  const [olderReports, setOlderReports] = useState([])
  const [pageCursor, setPageCursor] = useState(null)
  const [status, setStatus] = useState('loading')
  const [error, setError] = useState('')
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const [hasMore, setHasMore] = useState(true)

  useEffect(() => {
    const reportsQuery = query(
      collection(db, 'reports'),
      orderBy('created_at', 'desc'),
      limit(REPORT_PAGE_SIZE),
    )

    const unsubscribe = onSnapshot(
      reportsQuery,
      (snapshot) => {
        setFirstPageReports(
          snapshot.docs.map((doc) => parseReport(doc.id, doc.data())),
        )
        setPageCursor(snapshot.docs.at(-1) || null)
        setHasMore(snapshot.docs.length === REPORT_PAGE_SIZE)
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

  const reports = useMemo(
    () => dedupeReports([...firstPageReports, ...olderReports]),
    [firstPageReports, olderReports],
  )

  const calambaReports = useMemo(
    () => reports.filter((report) => isCalambaReport(report)),
    [reports],
  )

  async function loadMore() {
    if (!pageCursor || isLoadingMore || !hasMore) return

    setIsLoadingMore(true)
    try {
      const nextQuery = query(
        collection(db, 'reports'),
        orderBy('created_at', 'desc'),
        startAfter(pageCursor),
        limit(REPORT_PAGE_SIZE),
      )
      const snapshot = await getDocs(nextQuery)
      setOlderReports((current) =>
        dedupeReports([
          ...current,
          ...snapshot.docs.map((doc) => parseReport(doc.id, doc.data())),
        ]),
      )
      setPageCursor(snapshot.docs.at(-1) || pageCursor)
      setHasMore(snapshot.docs.length === REPORT_PAGE_SIZE)
      setError('')
    } catch (loadError) {
      setError(loadError.message)
    } finally {
      setIsLoadingMore(false)
    }
  }

  return {
    reports,
    calambaReports,
    status,
    error,
    hasMore,
    isLoadingMore,
    loadMore,
  }
}

function dedupeReports(items) {
  return [...new Map(items.map((item) => [item.id, item])).values()]
}
