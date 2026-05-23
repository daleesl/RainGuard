import { useMemo, useState } from 'react'
import { doc, updateDoc } from 'firebase/firestore'
import {
  CheckCircle2,
  Eye,
  EyeOff,
  ImageOff,
  RotateCcw,
  Search,
  X,
} from 'lucide-react'
import { ConfirmActionModal } from '../components/ConfirmActionModal'
import { db } from '../firebase'
import { useReports } from '../hooks/useReports'
import {
  getReportLabel,
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
  const [pendingAction, setPendingAction] = useState(null)
  const [selectedReport, setSelectedReport] = useState(null)

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

  function requestReportAction(report, action) {
    setPendingAction({ ...action, report })
  }

  async function confirmReportAction() {
    if (!pendingAction) return
    const { report, successMessage, values } = pendingAction
    setPendingAction(null)
    await updateReportStatus(report, values, successMessage)
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
                          className="table-action table-action-verify"
                          onClick={() =>
                            requestReportAction(
                              report,
                              report.status === 'verified'
                                ? {
                                    confirmLabel: 'Unverify report',
                                    intent: 'primary',
                                    message:
                                      'This removes the admin verified mark and returns the report to the unreviewed queue.',
                                    successMessage:
                                      'Report moved back to unreviewed.',
                                    title: 'Unverify this report?',
                                    values: {
                                      hidden: false,
                                      status: 'active',
                                      report_status: 'active',
                                    },
                                  }
                                : {
                                    confirmLabel: 'Verify report',
                                    intent: 'primary',
                                    message:
                                      'This marks the report as reviewed and trusted by admin.',
                                    successMessage:
                                      'Report marked as verified.',
                                    title: 'Verify this report?',
                                    values: {
                                      status: 'verified',
                                      report_status: 'verified',
                                    },
                                  },
                            )
                          }
                          type="button"
                          title={
                            report.status === 'verified'
                              ? 'Remove verified status'
                              : 'Mark report as verified'
                          }
                        >
                          <CheckCircle2 aria-hidden="true" size={13} />
                          <span>
                            {report.status === 'verified' ? 'Unverify' : 'Verify'}
                          </span>
                        </button>
                        <button
                          className="table-action table-action-resolve"
                          onClick={() =>
                            requestReportAction(report, {
                              confirmLabel: 'Resolve report',
                              intent: 'primary',
                              message:
                                'This marks the report as resolved so admins know the issue no longer needs active handling.',
                              successMessage: 'Report marked as resolved.',
                              title: 'Resolve this report?',
                              values: {
                                status: 'resolved',
                                report_status: 'resolved',
                              },
                            })
                          }
                          type="button"
                          title="Mark report as resolved"
                        >
                          <RotateCcw aria-hidden="true" size={13} />
                          <span>Resolve</span>
                        </button>
                        <button
                          className="table-action table-action-danger"
                          onClick={() =>
                            requestReportAction(report, {
                              confirmLabel: 'Hide report',
                              intent: 'danger',
                              message:
                                'This hides the report from admin review because it is a duplicate or invalid entry.',
                              successMessage: 'Report hidden as duplicate.',
                              title: 'Hide this report?',
                              values: {
                                hidden: true,
                                status: 'duplicate_hidden',
                                report_status: 'duplicate_hidden',
                              },
                            })
                          }
                          type="button"
                          title="Hide duplicate report"
                        >
                          <EyeOff aria-hidden="true" size={13} />
                          <span>Hide</span>
                        </button>
                        <button
                          className="table-action table-action-ghost"
                          onClick={() => setSelectedReport(report)}
                          type="button"
                          title="View report details"
                        >
                          <Eye aria-hidden="true" size={13} />
                          <span>View</span>
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

      {selectedReport ? (
        <ReportViewModal
          onClose={() => setSelectedReport(null)}
          onOpenMap={onOpenMap}
          report={selectedReport}
        />
      ) : null}
      {pendingAction ? (
        <ConfirmActionModal
          confirmLabel={pendingAction.confirmLabel}
          intent={pendingAction.intent}
          message={pendingAction.message}
          onCancel={() => setPendingAction(null)}
          onConfirm={confirmReportAction}
          title={pendingAction.title}
        />
      ) : null}
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
  if (statusValue === 'Verified') return 'status-safe'
  if (statusValue === 'Flagged') return 'status-flood'
  if (statusValue === 'Review') return 'status-risk'
  return 'status-new'
}

function ReportViewModal({ onClose, onOpenMap, report }) {
  const [imageIndex, setImageIndex] = useState(0)
  const images = report.imageUrls || []
  const safeImageIndex = Math.min(imageIndex, Math.max(images.length - 1, 0))
  const currentImage = images[safeImageIndex]

  function goToImage(direction) {
    if (images.length <= 1) return
    setImageIndex((safeImageIndex + direction + images.length) % images.length)
  }

  function openMapFromModal() {
    onClose()
    onOpenMap?.()
  }

  return (
    <div
      aria-labelledby="reports-view-modal-title"
      aria-modal="true"
      className="report-modal-backdrop"
      onClick={onClose}
      role="dialog"
    >
      <section
        className="report-modal report-modal-simple reports-view-modal"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="simple-modal-header">
          <div>
            <p className="modal-eyebrow">Report details</p>
            <h3 id="reports-view-modal-title">{getReportLabel(report)}</h3>
          </div>
          <button
            aria-label="Close report details"
            className="modal-close"
            onClick={onClose}
            type="button"
          >
            <X aria-hidden="true" size={18} />
          </button>
        </div>

        <div className="simple-modal-content">
          <div className="report-image-carousel reports-view-carousel">
            <div className="report-image-main reports-view-image">
              {currentImage ? (
                <img alt="Submitted report evidence" src={currentImage} />
              ) : (
                <span className="report-modal-empty-image">
                  <ImageOff aria-hidden="true" size={24} />
                  <span>No photo attached</span>
                </span>
              )}
            </div>

            {images.length > 1 ? (
              <div className="report-image-controls">
                <button onClick={() => goToImage(-1)} type="button">
                  Prev
                </button>
                <span>
                  {safeImageIndex + 1} / {images.length}
                </span>
                <button onClick={() => goToImage(1)} type="button">
                  Next
                </button>
              </div>
            ) : null}
          </div>

          <div className="simple-modal-details">
            <div className="simple-chip-row">
              <span className="chip chip-blue">{getReportTypeName(report)}</span>
              <span
                className={`chip ${
                  report.riskLevel === 'safe' ? 'chip-green' : 'chip-red'
                }`}
              >
                {getRiskName(report)}
              </span>
              <span className={`status-pill ${statusClass(report)}`}>
                {getReviewStatus(report)}
              </span>
            </div>

            <div className="simple-report-title">
              <span>Location</span>
              <strong>{getReportLocationName(report)}</strong>
            </div>

            <p className="simple-description">
              {report.description || 'No description was provided for this report.'}
            </p>

            <div className="simple-meta-list">
              <InfoItem label="Reporter" value={report.reporterName || 'Anonymous'} />
              <InfoItem label="Created" value={formatReportDateTime(report.createdAt)} />
              <InfoItem
                label="GPS"
                value={`${report.latitude.toFixed(5)}, ${report.longitude.toFixed(5)}`}
              />
              <InfoItem label="Source" value={report.locationSource} />
              <InfoItem
                label="Images"
                value={`${images.length || 0} attached`}
              />
              {report.floodLevel ? (
                <InfoItem label="Flood level" value={report.floodLevel} />
              ) : null}
            </div>

            <div className="simple-modal-actions">
              <button className="panel-primary" onClick={openMapFromModal} type="button">
                Open Map
              </button>
              <button className="panel-secondary" onClick={onClose} type="button">
                Close
              </button>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}

function InfoItem({ label, value }) {
  return (
    <div className="modal-info-item">
      <span>{label}</span>
      <strong>{value}</strong>
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
