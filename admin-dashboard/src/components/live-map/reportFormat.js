export function formatReportDateTime(date) {
  if (!date) {
    return {
      primary: 'Today',
      secondary: 'Now',
    }
  }

  return {
    primary: new Intl.DateTimeFormat('en-PH', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    }).format(date),
    secondary: new Intl.DateTimeFormat('en-PH', {
      hour: 'numeric',
      minute: '2-digit',
    }).format(date),
  }
}
