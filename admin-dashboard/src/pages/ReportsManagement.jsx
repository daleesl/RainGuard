import { useMemo, useState } from 'react'
import { doc, updateDoc } from 'firebase/firestore'
import { Search } from 'lucide-react'
import { db } from '../firebase'
import { useReports } from '../hooks/useReports'
import {
  getReportLocationName,
  getReportTypeName,
  getReviewStatus,
  getRiskName,
  isToday,
} from '../utils/reports'

const reportMetrics = [
  {
    key: 'newReports',
    label: 'New reports',
    helper: 'Awaiting review',
    accent: '#1778d4',
  },
  {
    key: 'flagged',
    label: 'Flagged',
    helper: 'Possible duplicate',
    accent: '#e24d4d',
  },
  {
    key: 'verified',
    label: 'Verified',
    helper: 'Today',
    accent: '#28c59d',
  },
]

export function ReportsManagement({ onOpenMap }) {
  const { calambaReports, error, status } = useReports()
  const [activeFilter, setActiveFilter] = useState('all')
  const [searchTerm, setSearchTerm] = useState('')
  const [actionMessage, setActionMessage] = useState('')

  const filteredReports = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase()
    const visibleReports = calambaReports.filter((report) => {
      if (activeFilter === 'today') return isToday(report.createdAt)
      if (activeFilter === 'flood') return report.reportType === 'flood'
      if (activeFilter === 'unreviewed') return getReviewStatus(report) === 'New'
      return true
    })

    if (!normalizedSearch) return visibleReports

    return visibleReports.filter((report) =>
      [
        report.id,
        report.description,
        report.reportType,
        report.riskLevel,
        report.reporterName,
        getReportLocationName(report),
      ]
        .join(' ')
        .toLowerCase()
        .includes(normalizedSearch),
    )
  }, [activeFilter, calambaReports, searchTerm])

  const metrics = useMemo(() => {
    const todayReports = filteredReports.filter((report) =>
      isToday(report.createdAt),
    )

    return {
      newReports: filteredReports.filter(
        (report) => getReviewStatus(report) === 'New',
      ).length,
      flagged: filteredReports.filter(
        (report) => getReviewStatus(report) === 'Flagged',
      ).length,
      verified:
        filteredReports.filter((report) => report.status === 'verified')
          .length || todayReports.length,
    }
  }, [filteredReports])

  async function updateReportStatus(report, values, successMessage) {
    if (!report) return

    try {
      await updateDoc(doc(db, 'reports', report.id), values)
      setActionMessage(successMessage)
    } catch (updateError) {
      setActionMessage(updateError.message)
    }
  }

  function exportCsv() {
    const header = ['id', 'type', 'risk', 'location', 'reporter', 'created', 'status']
    const rows = filteredReports.map((report) => [
      report.id,
      getReportTypeName(report),
      getRiskName(report),
      getReportLocationName(report),
      report.reporterName || 'Anonymous',
      report.createdAt?.toISOString?.() || '',
      getReviewStatus(report),
    ])

    const csv = [header, ...rows]
      .map((row) =>
        row.map((cell) => `"${String(cell).replaceAll('"', '""')}"`).join(','),
      )
      .join('\n')

    const url = URL.createObjectURL(
      new Blob([csv], { type: 'text/csv;charset=utf-8;' }),
    )
    const link = document.createElement('a')
    link.href = url
    link.download = 'rainguard-reports.csv'
    link.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="reports-page">
      <header className="admin-topbar">
        <div>
          <h2>Reports Management</h2>
          <p>Review, verify, hide, or resolve community rain and flood reports.</p>
        </div>

        <div className="topbar-actions">
          <label className="search-field">
            <Search aria-hidden="true" size={14} />
            <input
              aria-label="Search admin records"
              onChange={(event) => setSearchTerm(event.target.value)}
              placeholder="Search admin records"
              type="search"
              value={searchTerm}
            />
          </label>
          <button className="primary-action" onClick={exportCsv} type="button">
            Export CSV
          </button>
        </div>
      </header>

      <main className="reports-content">
        <section className="metric-row reports-metrics" aria-label="Report metrics">
          {reportMetrics.map((metric) => (
            <MetricCard
              accent={metric.accent}
              helper={metric.helper}
              key={metric.key}
              label={metric.label}
              value={metrics[metric.key]}
            />
          ))}
        </section>

        {error || actionMessage ? (
          <p className={error ? 'error-banner' : 'success-banner'}>
            {error || actionMessage}
          </p>
        ) : null}

        <section className="reports-table-card reports-table-card-wide">
          <div className="reports-card-header">
            <div>
              <h3>Report Queue</h3>
              <p>{filteredReports.length} records in the current view</p>
            </div>

            <div className="report-filter-chips" aria-label="Report filters">
              <FilterChip
                activeFilter={activeFilter}
                colorClass="chip-blue"
                label="Today"
                setActiveFilter={setActiveFilter}
                value="today"
              />
              <FilterChip
                activeFilter={activeFilter}
                colorClass="chip-red"
                label="Flood"
                setActiveFilter={setActiveFilter}
                value="flood"
              />
              <FilterChip
                activeFilter={activeFilter}
                colorClass="chip-amber"
                label="Unreviewed"
                setActiveFilter={setActiveFilter}
                value="unreviewed"
              />
              <button
                className="chip chip-button chip-neutral"
                disabled={activeFilter === 'all' && !searchTerm}
                onClick={() => {
                  setActiveFilter('all')
                  setSearchTerm('')
                }}
                type="button"
              >
                Clear
              </button>
            </div>
          </div>

          <div className="reports-table-wrap">
            <table className="reports-table reports-review-table">
              <thead>
                <tr>
                  <th>Report</th>
                  <th>Risk</th>
                  <th>Location</th>
                  <th>Description</th>
                  <th>Reporter</th>
                  <th>Created</th>
                  <th>Status</th>
                  <th>Evidence</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredReports.slice(0, 12).map((report) => (
                  <tr key={report.id}>
                    <td>
                      <strong>{getReportTypeName(report)}</strong>
                    </td>
                    <td>
                      <span className={`status-pill ${riskClass(report)}`}>
                        {getRiskName(report)}
                      </span>
                    </td>
                    <td>{getReportLocationName(report)}</td>
                    <td className="description-cell">
                      {report.description || 'No description provided.'}
                    </td>
                    <td>{report.reporterName || 'Anonymous'}</td>
                    <td>{formatReportDateTime(report.createdAt)}</td>
                    <td>
                      <span className={`status-pill ${statusClass(report)}`}>
                        {getReviewStatus(report)}
                      </span>
                    </td>
                    <td>
                      {report.imageUrls.length > 0
                        ? `${report.imageUrls.length} photo${report.imageUrls.length > 1 ? 's' : ''}`
                        : 'No photo'}
                    </td>
                    <td>
                      <div className="row-action-group">
                        <button
                          className="table-action"
                          onClick={() =>
                            updateReportStatus(
                              report,
                              { status: 'verified', report_status: 'verified' },
                              'Report marked as verified.',
                            )
                          }
                          type="button"
                        >
                          Verify
                        </button>
                        <button
                          className="table-action"
                          onClick={() =>
                            updateReportStatus(
                              report,
                              { status: 'resolved', report_status: 'resolved' },
                              'Report marked as resolved.',
                            )
                          }
                          type="button"
                        >
                          Resolve
                        </button>
                        <button
                          className="table-action table-action-danger"
                          onClick={() =>
                            updateReportStatus(
                              report,
                              {
                                hidden: true,
                                status: 'duplicate_hidden',
                                report_status: 'duplicate_hidden',
                              },
                              'Report hidden as duplicate.',
                            )
                          }
                          type="button"
                        >
                          Hide
                        </button>
                        <button
                          className="table-action table-action-ghost"
                          onClick={onOpenMap}
                          type="button"
                        >
                          Map
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {status === 'loading' ? (
              <p className="table-state">Loading report queue...</p>
            ) : null}
            {status === 'ready' && filteredReports.length === 0 ? (
              <p className="table-state">
                No reports match this view. Try another chip or clear the
                search field.
              </p>
            ) : null}
          </div>
        </section>
      </main>
    </div>
  )
}

function formatReportDateTime(date) {
  if (!date) return 'Now'
  return new Intl.DateTimeFormat('en-PH', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(date)
}

function riskClass(report) {
  if (report.riskLevel === 'safe') return 'status-safe'
  if (report.riskLevel === 'flood' || report.reportType === 'flood') {
    return 'status-flood'
  }
  return 'status-risk'
}

function statusClass(report) {
  const statusValue = getReviewStatus(report)
  if (statusValue === 'Reviewed') return 'status-safe'
  if (statusValue === 'Flagged') return 'status-flood'
  if (statusValue === 'Review') return 'status-risk'
  return 'status-new'
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

function FilterChip({
  activeFilter,
  colorClass,
  label,
  setActiveFilter,
  value,
}) {
  const isActive = activeFilter === value

  return (
    <button
      className={`chip chip-button ${colorClass} ${isActive ? 'is-active' : ''}`}
      onClick={() => setActiveFilter(isActive ? 'all' : value)}
      type="button"
    >
      {label}
    </button>
  )
}
