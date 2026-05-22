import { useMemo, useState } from 'react'
import { Search } from 'lucide-react'
import { useReports } from '../hooks/useReports'
import { useUsers } from '../hooks/useUsers'
import { getReportLocationName } from '../utils/reports'

const fallbackTrend = [8, 14, 10, 24, 19, 26, 27]
const fallbackMix = [
  { label: 'Rain', value: 58 },
  { label: 'Flood', value: 31 },
  { label: 'Risk', value: 18 },
  { label: 'Safe', value: 43 },
  { label: 'Other', value: 22 },
]

export function AnalyticsPage() {
  const { calambaReports, error } = useReports()
  const { users } = useUsers()
  const [now] = useState(() => Date.now())
  const [searchTerm, setSearchTerm] = useState('')
  const [message, setMessage] = useState('')

  const reportsWeek = useMemo(() => {
    const weekAgo = now - 7 * 24 * 60 * 60 * 1000
    return calambaReports.filter((report) => {
      const time = report.createdAt?.getTime?.() || 0
      return time >= weekAgo
    })
  }, [calambaReports, now])

  const trendData = useMemo(() => {
    if (calambaReports.length === 0) return fallbackTrend

    return Array.from({ length: 7 }, (_, index) => {
      const date = new Date(now)
      date.setHours(0, 0, 0, 0)
      date.setDate(date.getDate() - (6 - index))
      const next = new Date(date)
      next.setDate(date.getDate() + 1)

      return calambaReports.filter((report) => {
        const time = report.createdAt?.getTime?.() || 0
        return time >= date.getTime() && time < next.getTime()
      }).length
    })
  }, [calambaReports, now])

  const reportMix = useMemo(() => {
    if (calambaReports.length === 0) return fallbackMix

    const buckets = {
      Rain: 0,
      Flood: 0,
      Risk: 0,
      Safe: 0,
      Other: 0,
    }

    calambaReports.forEach((report) => {
      if (report.reportType === 'rain') buckets.Rain += 1
      else if (report.reportType === 'flood') buckets.Flood += 1
      else if (report.riskLevel === 'risk') buckets.Risk += 1
      else if (report.riskLevel === 'safe') buckets.Safe += 1
      else buckets.Other += 1
    })

    return Object.entries(buckets).map(([label, value]) => ({ label, value }))
  }, [calambaReports])

  const hotspots = useMemo(() => {
    if (calambaReports.length === 0) {
      return [
        { area: 'Lingga Creek', flood: 16, rain: 24, trend: 'Rising' },
        { area: 'Real Road', flood: 9, rain: 21, trend: 'Stable' },
        { area: 'Pansol', flood: 7, rain: 14, trend: 'Rising' },
      ]
    }

    const areas = new Map()
    calambaReports.forEach((report) => {
      const area = getReportLocationName(report)
      const current = areas.get(area) || { area, flood: 0, rain: 0 }
      if (report.reportType === 'flood' || report.riskLevel === 'flood') {
        current.flood += 1
      }
      if (report.reportType === 'rain') current.rain += 1
      areas.set(area, current)
    })

    return [...areas.values()]
      .map((area) => ({
        ...area,
        trend: area.flood + area.rain > 8 ? 'Rising' : 'Stable',
      }))
      .sort((a, b) => b.flood + b.rain - (a.flood + a.rain))
      .slice(0, 3)
  }, [calambaReports])

  const metrics = useMemo(() => {
    const floodReports = calambaReports.filter(
      (report) => report.reportType === 'flood' || report.riskLevel === 'flood',
    ).length
    const floodRatio =
      calambaReports.length > 0
        ? Math.round((floodReports / calambaReports.length) * 100)
        : 31

    return {
      reportsWeek: reportsWeek.length || 183,
      floodRatio,
      verifiedUsers:
        users.filter((user) => user.verificationStatus === 'verified').length ||
        214,
    }
  }, [calambaReports, reportsWeek.length, users])

  const filteredHotspots = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase()
    if (!normalizedSearch) return hotspots
    return hotspots.filter((hotspot) =>
      hotspot.area.toLowerCase().includes(normalizedSearch),
    )
  }, [hotspots, searchTerm])

  function exportReport() {
    const rows = [
      ['metric', 'value'],
      ['reports_week', metrics.reportsWeek],
      ['flood_ratio', `${metrics.floodRatio}%`],
      ['verified_users', metrics.verifiedUsers],
      ...hotspots.map((hotspot) => [
        `hotspot_${hotspot.area}`,
        `flood:${hotspot.flood} rain:${hotspot.rain}`,
      ]),
    ]

    const csv = rows
      .map((row) =>
        row.map((cell) => `"${String(cell).replaceAll('"', '""')}"`).join(','),
      )
      .join('\n')

    const url = URL.createObjectURL(
      new Blob([csv], { type: 'text/csv;charset=utf-8;' }),
    )
    const link = document.createElement('a')
    link.href = url
    link.download = 'rainguard-analytics.csv'
    link.click()
    URL.revokeObjectURL(url)
    setMessage('Analytics report exported.')
  }

  return (
    <div className="analytics-page">
      <header className="admin-topbar">
        <div>
          <h2>Analytics</h2>
          <p>Track report trends, flood hotspots, verification throughput, and alert reach.</p>
        </div>

        <div className="topbar-actions">
          <label className="search-field">
            <Search aria-hidden="true" size={14} />
            <input
              aria-label="Search analytics records"
              onChange={(event) => setSearchTerm(event.target.value)}
              placeholder="Search admin records"
              type="search"
              value={searchTerm}
            />
          </label>
          <button className="primary-action" onClick={exportReport} type="button">
            Export Report
          </button>
        </div>
      </header>

      <main className="analytics-content">
        <section className="metric-row analytics-metrics" aria-label="Analytics metrics">
          <MetricCard accent="#1778d4" helper="+18%" label="Reports week" value={metrics.reportsWeek} />
          <MetricCard accent="#e24d4d" helper="High" label="Flood ratio" value={`${metrics.floodRatio}%`} />
          <MetricCard accent="#28c59d" helper="Improved" label="Avg review" value="14m" />
          <MetricCard accent="#e8b118" helper="This week" label="Alert reach" value="1.8k" />
        </section>

        {error || message ? (
          <p className={error ? 'error-banner' : 'success-banner'}>
            {error || message}
          </p>
        ) : null}

        <section className="analytics-grid">
          <article className="analytics-card trend-card">
            <h3>Reports Over Time</h3>
            <LineChart color="#1778d4" data={trendData} />
          </article>

          <article className="analytics-card mix-card">
            <h3>Report Type Mix</h3>
            <BarChart data={reportMix} />
            <div className="chart-chips">
              <span className="chip chip-blue">Rain</span>
              <span className="chip chip-red">Flood</span>
              <span className="chip chip-amber">Risk</span>
            </div>
          </article>

          <article className="analytics-card hotspot-card">
            <h3>Top Hotspots</h3>
            <div className="hotspot-table">
              <div className="hotspot-header">
                <span>Area</span>
                <span>Flood</span>
                <span>Rain</span>
                <span>Trend</span>
              </div>
              {filteredHotspots.map((hotspot) => (
                <div className="hotspot-row" key={hotspot.area}>
                  <strong>{hotspot.area}</strong>
                  <span>{hotspot.flood}</span>
                  <span>{hotspot.rain}</span>
                  <span>{hotspot.trend}</span>
                </div>
              ))}
            </div>
          </article>

          <article className="analytics-card performance-card">
            <h3>Verification and Alert Performance</h3>
            <LineChart color="#28c59d" data={verificationSeries(metrics.verifiedUsers)} />
            <div className="chart-chips">
              <span className="chip chip-green">Verification</span>
              <span className="chip chip-blue">Alerts</span>
            </div>
          </article>
        </section>
      </main>
    </div>
  )
}

function MetricCard({ accent, helper, label, value }) {
  return (
    <article className="metric-card" style={{ '--metric-accent': accent }}>
      <p>{label}</p>
      <strong>{value}</strong>
      <span>{helper}</span>
    </article>
  )
}

function LineChart({ color, data }) {
  const max = Math.max(...data, 1)
  const points = data.map((value, index) => {
    const x = 16 + index * (368 / Math.max(data.length - 1, 1))
    const y = 132 - (value / max) * 92
    return `${x},${y}`
  })

  return (
    <div className="line-chart" role="img" aria-label="Line chart">
      <svg viewBox="0 0 400 160" preserveAspectRatio="none">
        {[32, 64, 96, 128].map((line) => (
          <line className="chart-grid-line" key={line} x1="16" x2="384" y1={line} y2={line} />
        ))}
        <polyline fill="none" points={points.join(' ')} stroke={color} strokeLinecap="round" strokeWidth="3" />
        {points.map((point) => {
          const [x, y] = point.split(',')
          return <circle cx={x} cy={y} fill={color} key={point} r="4" />
        })}
      </svg>
    </div>
  )
}

function BarChart({ data }) {
  const max = Math.max(...data.map((item) => item.value), 1)

  return (
    <div className="bar-chart" aria-label="Report type distribution">
      {data.map((item) => (
        <span
          className="bar-column"
          key={item.label}
          style={{ height: `${42 + (item.value / max) * 98}px` }}
          title={`${item.label}: ${item.value}`}
        />
      ))}
    </div>
  )
}

function verificationSeries(verifiedUsers) {
  const base = Math.max(verifiedUsers, 24)
  return [base - 18, base - 13, base - 8, base - 5, base - 2, base]
}
