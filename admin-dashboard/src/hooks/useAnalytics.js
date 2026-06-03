import { useMemo } from 'react'
import { useAlerts } from './useAlerts'
import { useReports } from './useReports'
import { useUsers } from './useUsers'
import { buildAnalyticsData } from '../utils/analytics'

export function useAnalytics(trendRange) {
  const reportsState = useReports()
  const usersState = useUsers()
  const alertsState = useAlerts()

  const analytics = useMemo(
    () =>
      buildAnalyticsData({
        alerts: alertsState.alerts,
        reports: reportsState.reports,
        trendRange,
        users: usersState.users,
      }),
    [alertsState.alerts, reportsState.reports, trendRange, usersState.users],
  )

  const error = reportsState.error || usersState.error || alertsState.error
  const status =
    reportsState.status === 'loading' ||
    usersState.status === 'loading' ||
    alertsState.status === 'loading'
      ? 'loading'
      : error
        ? 'error'
        : 'ready'

  return {
    analytics,
    error,
    status,
  }
}
