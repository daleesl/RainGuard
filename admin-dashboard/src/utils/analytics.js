const MS_PER_DAY = 24 * 60 * 60 * 1000
const ACTIVE_EXCLUDED_STATUSES = new Set([
  'resolved',
  'rejected',
  'duplicate',
  'duplicate_hidden',
  'hidden',
])
const PENDING_ACTION_STATUSES = new Set(['active', 'pending', 'review'])
const RISK_LEVELS = ['safe', 'risk', 'flood']
const REPORT_TYPES = ['rain', 'flood']

export function buildAnalyticsData({
  alerts,
  now = new Date(),
  reports,
  trendRange,
  users,
}) {
  const activeReports = reports.filter(isActiveReport)
  const floodReports = reports.filter(isFloodReport)
  const rainReports = reports.filter(isRainReport)
  const highRiskReports = reports.filter(isHighRiskReport)
  const resolvedReports = reports.filter((report) => normalizeValue(report.status) === 'resolved')
  const pendingVerificationUsers = users.filter(
    (user) => normalizeValue(user.verificationStatus) === 'pending',
  )
  const publishedAlerts = alerts.filter(
    (alert) => normalizeValue(alert.status) === 'published',
  )
  const recentFloodReports = activeReports.filter(
    (report) => isFloodReport(report) && isWithinHours(report.createdAt, now, 24),
  )
  const unresolvedRiskReports = activeReports.filter(isHighRiskReport)
  const pendingActionReports = reports.filter(isPendingAdminAction)
  const recentHighRiskReports = highRiskReports
    .slice()
    .sort((a, b) => compareDatesDesc(a.createdAt, b.createdAt))
    .slice(0, 8)

  return {
    attentionReports: uniqueReports([
      ...recentFloodReports,
      ...unresolvedRiskReports,
      ...pendingActionReports,
    ])
      .slice()
      .sort((a, b) => compareDatesDesc(a.createdAt, b.createdAt))
      .slice(0, 5),
    coordinatesCount: reports.filter(hasCoordinates).length,
    distributions: {
      risk: buildFixedDistribution(reports, RISK_LEVELS, 'riskLevel'),
      status: buildStatusDistribution(reports),
      type: buildFixedDistribution(reports, REPORT_TYPES, 'reportType'),
    },
    metrics: {
      activeReports: activeReports.length,
      floodReports: floodReports.length,
      highRiskReports: highRiskReports.length,
      pendingVerificationUsers: pendingVerificationUsers.length,
      publishedAlerts: publishedAlerts.length,
      rainReports: rainReports.length,
      resolvedReports: resolvedReports.length,
      totalReports: reports.length,
    },
    needsAttention: {
      pendingAction: pendingActionReports.length,
      recentFlood: recentFloodReports.length,
      unresolvedRisk: unresolvedRiskReports.length,
    },
    recentHighRiskReports,
    trend: buildTrendData(reports, trendRange, now),
    trendSummary: buildTrendSummary(reports, now),
  }
}

export function formatAnalyticsDateTime(date) {
  if (!date) return 'Unknown'
  return new Intl.DateTimeFormat('en-PH', {
    day: '2-digit',
    hour: 'numeric',
    minute: '2-digit',
    month: 'short',
  }).format(date)
}

export function formatAnalyticsLabel(value) {
  const normalizedValue = normalizeValue(value)
  if (normalizedValue === 'duplicate_hidden') return 'Duplicate'
  if (!normalizedValue) return 'Unknown'
  return normalizedValue.charAt(0).toUpperCase() +
    normalizedValue.slice(1).replaceAll('_', ' ')
}

export function isActiveReport(report) {
  return !ACTIVE_EXCLUDED_STATUSES.has(normalizeValue(report.status))
}

export function isFloodReport(report) {
  return normalizeValue(report.reportType) === 'flood' ||
    normalizeValue(report.riskLevel) === 'flood'
}

export function isHighRiskReport(report) {
  return ['risk', 'flood'].includes(normalizeValue(report.riskLevel)) ||
    normalizeValue(report.reportType) === 'flood'
}

export function isRainReport(report) {
  return normalizeValue(report.reportType) === 'rain'
}

function buildFixedDistribution(reports, keys, field) {
  return keys.map((key) => ({
    label: formatAnalyticsLabel(key),
    value: reports.filter((report) => normalizeValue(report[field]) === key).length,
  }))
}

function buildStatusDistribution(reports) {
  const counts = new Map()
  reports.forEach((report) => {
    const status = normalizeValue(report.status)
    if (!status) return
    counts.set(status, (counts.get(status) || 0) + 1)
  })

  return [...counts.entries()]
    .map(([status, value]) => ({
      label: formatAnalyticsLabel(status),
      value,
    }))
    .sort((a, b) => b.value - a.value)
}

function buildTrendData(reports, trendRange, now) {
  if (trendRange === 'all') return buildAllTimeTrend(reports)

  const days = trendRange === '30' ? 30 : 7
  return Array.from({ length: days }, (_, index) => {
    const date = startOfDay(new Date(now.getTime() - (days - 1 - index) * MS_PER_DAY))
    const next = new Date(date.getTime() + MS_PER_DAY)
    return buildTrendPoint(reports, date, next, days)
  })
}

function buildAllTimeTrend(reports) {
  if (reports.length === 0) return []

  const datedReports = reports
    .filter((report) => report.createdAt)
    .sort((a, b) => a.createdAt - b.createdAt)

  if (datedReports.length === 0) return []

  const firstDay = startOfDay(datedReports[0].createdAt)
  const lastDay = startOfDay(datedReports.at(-1).createdAt)
  const dayCount = Math.floor((lastDay - firstDay) / MS_PER_DAY) + 1

  return Array.from({ length: dayCount }, (_, index) => {
    const date = new Date(firstDay.getTime() + index * MS_PER_DAY)
    const next = new Date(date.getTime() + MS_PER_DAY)
    return buildTrendPoint(reports, date, next, dayCount)
  })
}

function buildTrendSummary(reports, now) {
  const todayStart = startOfDay(now)
  const yesterdayStart = new Date(todayStart.getTime() - MS_PER_DAY)
  const weekStart = new Date(todayStart.getTime() - 6 * MS_PER_DAY)
  const previousWeekStart = new Date(weekStart.getTime() - 7 * MS_PER_DAY)

  const today = countReportsBetween(reports, todayStart, new Date(todayStart.getTime() + MS_PER_DAY))
  const yesterday = countReportsBetween(reports, yesterdayStart, todayStart)
  const thisWeek = countReportsBetween(reports, weekStart, new Date(todayStart.getTime() + MS_PER_DAY))
  const previousWeek = countReportsBetween(reports, previousWeekStart, weekStart)

  return {
    today,
    todayDirection: compareCount(today, yesterday),
    weekDirection: compareCount(thisWeek, previousWeek),
  }
}

function compareCount(current, previous) {
  if (current > previous) return 'Increasing'
  if (current < previous) return 'Decreasing'
  return 'Stable'
}

function countReportsBetween(reports, start, end) {
  return reports.filter((report) => isWithinDateRange(report.createdAt, start, end)).length
}

function buildTrendPoint(reports, date, next, days) {
  const reportsForDay = reports.filter((report) =>
    isWithinDateRange(report.createdAt, date, next),
  )

  return {
    flood: reportsForDay.filter(isFloodReport).length,
    label: formatTrendLabel(date, days),
    rain: reportsForDay.filter(isRainReport).length,
    total: reportsForDay.length,
  }
}

function compareDatesDesc(left, right) {
  return (right?.getTime?.() || 0) - (left?.getTime?.() || 0)
}

function formatTrendLabel(date) {
  return new Intl.DateTimeFormat('en-PH', {
    day: 'numeric',
    month: 'short',
  }).format(date)
}

function hasCoordinates(report) {
  return Number.isFinite(report.latitude) && Number.isFinite(report.longitude)
}

function isPendingAdminAction(report) {
  return PENDING_ACTION_STATUSES.has(normalizeValue(report.status))
}

function isWithinDateRange(date, start, end) {
  const time = date?.getTime?.()
  return Number.isFinite(time) && time >= start.getTime() && time < end.getTime()
}

function isWithinHours(date, now, hours) {
  const time = date?.getTime?.()
  if (!Number.isFinite(time)) return false
  return now.getTime() - time <= hours * 60 * 60 * 1000
}

function normalizeValue(value) {
  return typeof value === 'string' ? value.trim().toLowerCase() : ''
}

function startOfDay(date) {
  const nextDate = new Date(date)
  nextDate.setHours(0, 0, 0, 0)
  return nextDate
}

function uniqueReports(reports) {
  return [...new Map(reports.map((report) => [report.id, report])).values()]
}
