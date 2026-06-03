export function parseAlert(id, data) {
  return {
    id,
    area: data.area || 'All residents',
    delivery: Array.isArray(data.delivery) ? data.delivery : ['in_app'],
    message: data.message || '',
    publishedAt: data.published_at?.toDate?.() || data.created_at?.toDate?.() || null,
    riskLevel: data.risk_level || 'info',
    source: data.source || 'manual',
    status: normalizeAlertStatus(data.status),
    title: data.title || 'Untitled advisory',
  }
}

export function normalizeAlertStatus(status) {
  return typeof status === 'string' && status.trim()
    ? status.trim().toLowerCase()
    : 'draft'
}

export function formatAlertLabel(value) {
  const normalizedValue = String(value || '').trim().toLowerCase()
  if (normalizedValue === 'info' || normalizedValue === 'advisory') {
    return 'Advisory'
  }

  return normalizedValue.charAt(0).toUpperCase() +
    normalizedValue.slice(1).replaceAll('_', ' ')
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
