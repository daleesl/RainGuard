export const CALAMBA_CENTER = [14.2050462, 121.1582127]

const CALAMBA_BOUNDS = {
  minLat: 13.9,
  maxLat: 14.4,
  minLng: 120.9,
  maxLng: 121.4,
}

export function parseReport(id, data) {
  const imageUrls = parseImageUrls(data)

  return {
    id,
    description: data.description || '',
    floodLevel: data.flood_level || '',
    imageUrl: imageUrls[0] || '',
    imageUrls,
    locationSource: data.location_source || 'gps',
    reportType: data.report_type || 'report',
    riskLevel: data.risk_level || 'risk',
    reporterName: data.reporter_display_name || data.reporter_name || '',
    status: data.status || data.report_status || 'active',
    userId: data.user_id || '',
    latitude: readNumber(data.latitude),
    longitude: readNumber(data.longitude),
    createdAt: data.created_at?.toDate?.() || null,
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

export function isCalambaReport(report) {
  return (
    Number.isFinite(report.latitude) &&
    Number.isFinite(report.longitude) &&
    report.latitude >= CALAMBA_BOUNDS.minLat &&
    report.latitude <= CALAMBA_BOUNDS.maxLat &&
    report.longitude >= CALAMBA_BOUNDS.minLng &&
    report.longitude <= CALAMBA_BOUNDS.maxLng
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

export function getReviewStatus(report) {
  if (report.status === 'verified') return 'Reviewed'
  if (report.status === 'flagged' || report.status === 'duplicate_hidden') {
    return 'Flagged'
  }
  if (report.status === 'review') return 'Review'
  return 'New'
}

export function getReportLocationName(report) {
  if (!Number.isFinite(report.latitude) || !Number.isFinite(report.longitude)) {
    return 'Unknown'
  }

  if (report.latitude >= 14.18 && report.latitude <= 14.23) {
    return 'Lingga Creek'
  }

  return report.locationSource === 'manual' ? 'Manual pin' : 'Calamba'
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

function readNumber(value) {
  return typeof value === 'number' ? value : Number(value)
}
