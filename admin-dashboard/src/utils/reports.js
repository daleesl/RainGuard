export const QUILING_CENTER = [14.0943, 121.0370]

const LOCAL_REPORT_BOUNDS = {
  minLat: 13.9,
  maxLat: 14.4,
  minLng: 120.9,
  maxLng: 121.4,
}

const FLOOD_OBSERVATION_LABELS = {
  ankle_deep: {
    detail: 'Ankle level - up to 20 cm',
    short: 'Ankle level',
  },
  'ankle level - up to 20 cm': {
    detail: 'Ankle level - up to 20 cm',
    short: 'Ankle level',
  },
  knee_deep: {
    detail: 'Knee level - around 21-50 cm',
    short: 'Knee level',
  },
  'knee level - around 21-50 cm': {
    detail: 'Knee level - around 21-50 cm',
    short: 'Knee level',
  },
  waist_deep: {
    detail: 'Waist level - around 51-100 cm',
    short: 'Waist level',
  },
  'waist level - around 51-100 cm': {
    detail: 'Waist level - around 51-100 cm',
    short: 'Waist level',
  },
  chest_deep: {
    detail: 'Chest level or higher - above 100 cm',
    short: 'Chest level+',
  },
  'chest level or higher - above 100 cm': {
    detail: 'Chest level or higher - above 100 cm',
    short: 'Chest level+',
  },
}

export function parseReport(id, data) {
  const imageUrls = parseImageUrls(data)

  return {
    id,
    description: data.description || '',
    floodLevel: data.flood_level || '',
    hidden: data.hidden === true,
    hiddenAt: parseDate(data.hidden_at),
    hiddenBy: data.hidden_by || '',
    hiddenReason: normalizeText(data.hidden_reason),
    imageUrl: imageUrls[0] || '',
    imageUrls,
    locationName: normalizeText(data.location_name),
    locationSource: data.location_source || 'gps',
    rainIntensity: data.rain_intensity || '',
    reportType: data.report_type || 'report',
    riskLevel: data.risk_level || 'risk',
    reporterName: data.reporter_display_name || data.reporter_name || '',
    status: data.status || data.report_status || 'active',
    userId: data.user_id || '',
    latitude: readNumber(data.latitude),
    longitude: readNumber(data.longitude),
    createdAt: parseDate(data.created_at),
  }
}

export function parseImageUrls(data) {
  const urls = []

  if (Array.isArray(data.image_urls)) {
    data.image_urls.forEach((url) => {
      if (typeof url === 'string' && url.trim()) urls.push(url.trim())
    })
  }

  if (
    typeof data.image_url === 'string' &&
    data.image_url.trim() &&
    !urls.includes(data.image_url.trim())
  ) {
    urls.unshift(data.image_url.trim())
  }

  return urls
}

export function isLocalReport(report) {
  return (
    Number.isFinite(report.latitude) &&
    Number.isFinite(report.longitude) &&
    report.latitude >= LOCAL_REPORT_BOUNDS.minLat &&
    report.latitude <= LOCAL_REPORT_BOUNDS.maxLat &&
    report.longitude >= LOCAL_REPORT_BOUNDS.minLng &&
    report.longitude <= LOCAL_REPORT_BOUNDS.maxLng
  )
}

export function getReportColor(report) {
  if (report.reportType === 'rain') return '#1778d4'
  if (report.riskLevel === 'safe') return '#28c59d'
  if (report.riskLevel === 'flood' || report.reportType === 'flood') {
    return '#e24d4d'
  }
  return '#e8b118'
}

export function getReportLabel(report) {
  const type = report.reportType || 'report'
  return `${type.charAt(0).toUpperCase()}${type.slice(1)} report`
}

export function getReportTypeName(report) {
  const type = report.reportType || 'report'
  return `${type.charAt(0).toUpperCase()}${type.slice(1)}`
}

export function getRiskName(report) {
  const risk = report.riskLevel || 'risk'
  return `${risk.charAt(0).toUpperCase()}${risk.slice(1)}`
}

export function getReportObservationLabel(report) {
  return report.reportType === 'flood'
    ? 'Estimated Flood Water'
    : 'Rain Intensity'
}

export function getReportObservationValue(report) {
  const value =
    report.reportType === 'flood' ? report.floodLevel : report.rainIntensity
  if (!value) return 'Not specified'

  if (report.reportType === 'flood') {
    return floodObservationLabel(value).detail
  }

  return value
}

export function getReportObservationShortValue(report) {
  const value =
    report.reportType === 'flood' ? report.floodLevel : report.rainIntensity
  if (!value) return 'Not specified'

  if (report.reportType === 'flood') {
    return floodObservationLabel(value).short
  }

  return value
}

export function getReviewStatus(report) {
  if (report.status === 'verified') return 'Verified'
  if (report.status === 'resolved') return 'Resolved'
  if (report.status === 'rejected') return 'Rejected'
  if (
    report.hidden ||
    report.status === 'flagged' ||
    report.status === 'duplicate_hidden' ||
    report.status === 'hidden'
  ) {
    return 'Flagged'
  }
  if (report.status === 'review') return 'Review'
  return 'New'
}

export function isReportResolved(report) {
  return report.status === 'resolved'
}

export function isReportHidden(report) {
  return (
    report.hidden ||
    report.status === 'flagged' ||
    report.status === 'duplicate_hidden' ||
    report.status === 'hidden'
  )
}

export function getReportLocationName(report) {
  if (report.locationName) return report.locationName

  if (!Number.isFinite(report.latitude) || !Number.isFinite(report.longitude)) {
    return 'Unknown'
  }

  const coordinates = `${report.latitude.toFixed(5)}, ${report.longitude.toFixed(5)}`
  return report.locationSource === 'manual'
    ? `Manual pin ${coordinates}`
    : `GPS ${coordinates}`
}

export function formatReportTime(date) {
  if (!date) return 'Now'
  return new Intl.DateTimeFormat('en-PH', {
    hour: 'numeric',
    minute: '2-digit',
  }).format(date)
}

export function isToday(date) {
  if (!date) return false
  const now = new Date()
  return (
    date.getFullYear() === now.getFullYear() &&
    date.getMonth() === now.getMonth() &&
    date.getDate() === now.getDate()
  )
}

export function isThisWeek(date) {
  if (!date) return false
  const now = new Date()
  const weekAgo = new Date(now)
  weekAgo.setDate(now.getDate() - 7)
  return date >= weekAgo && date <= now
}

export function isDefaultMapReport(report) {
  if (
    report.hidden ||
    report.status === 'resolved' ||
    report.status === 'rejected' ||
    report.status === 'duplicate_hidden' ||
    report.status === 'hidden'
  ) {
    return false
  }

  const ageHours = report.createdAt
    ? (Date.now() - report.createdAt.getTime()) / (1000 * 60 * 60)
    : 0

  return (
    ageHours <= 72 ||
    report.status === 'active' ||
    report.status === 'pending' ||
    report.status === 'verified'
  )
}

function readNumber(value) {
  return typeof value === 'number' ? value : Number(value)
}

function parseDate(value) {
  if (!value) return null
  if (value instanceof Date) return value
  if (typeof value?.toDate === 'function') return value.toDate()

  const parsedDate = new Date(value)
  return Number.isNaN(parsedDate.getTime()) ? null : parsedDate
}

function normalizeText(value) {
  return typeof value === 'string' ? value.trim() : ''
}

function floodObservationLabel(value) {
  const normalizedValue = normalizeText(value)
  const mappedValue =
    FLOOD_OBSERVATION_LABELS[normalizedValue.toLowerCase()] || null

  if (mappedValue) return mappedValue

  const readableValue = normalizedValue
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase())

  return {
    detail: readableValue,
    short: readableValue.split(' - ')[0],
  }
}
