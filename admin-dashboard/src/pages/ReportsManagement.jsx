import { useMemo, useState } from 'react'
import {
  CheckCircle2,
  Eye,
  EyeOff,
  ImageOff,
  RotateCcw,
  X,
} from 'lucide-react'
import { AdminActionButton, AdminActionGroup } from '../components/AdminActionButton'
import { ConfirmActionModal } from '../components/ConfirmActionModal'
import { FilterChipButton } from '../components/FilterChipButton'
import { MetricCard } from '../components/MetricCard'
import { PageTopbar } from '../components/PageTopbar'
import { PrimaryActionButton } from '../components/PrimaryActionButton'
import { StatusChip } from '../components/StatusChip'
import { TableState } from '../components/TableState'
import { useReports } from '../hooks/useReports'
import {
  hideDuplicateReport,
  reopenReport,
  resolveReport,
  unhideReport,
  unverifyReport,
  verifyReport,
} from '../services/reportActions'
import {
  getReportLabel,
  getReportLocationName,
  getReportObservationLabel,
  getReportObservationShortValue,
  getReportObservationValue,
  getReportTypeName,
  getReviewStatus,
  isReportHidden,
  isReportResolved,
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

const reportFilters = [
  { label: 'All', tone: 'neutral', value: 'all' },
  { label: 'Today', tone: 'blue', value: 'today' },
  { label: 'Rain', tone: 'green', value: 'rain' },
  { label: 'Flood', tone: 'red', value: 'flood' },
  { label: 'Unreviewed', tone: 'amber', value: 'unreviewed' },
  { label: 'Flagged', tone: 'red', value: 'flagged' },
]

export function ReportsManagement({ onOpenMap }) {
  const {
    error,
    hasMore,
    isLoadingMore,
    localReports,
    loadMore,
    status,
  } = useReports()
  const [activeFilter, setActiveFilter] = useState('all')
  const [searchTerm, setSearchTerm] = useState('')
  const [actionMessage, setActionMessage] = useState('')
  const [pendingAction, setPendingAction] = useState(null)
  const [selectedReport, setSelectedReport] = useState(null)

  const filteredReports = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase()
    const visibleReports = localReports.filter((report) => {
      if (activeFilter === 'today') return isToday(report.createdAt)
      if (activeFilter === 'rain') return report.reportType === 'rain'
      if (activeFilter === 'flood') return report.reportType === 'flood'
      if (activeFilter === 'unreviewed') return getReviewStatus(report) === 'New'
      if (activeFilter === 'flagged') {
        return getReviewStatus(report) === 'Flagged'
      }
      return true
    })

    if (!normalizedSearch) return visibleReports

    return visibleReports.filter((report) =>
      [
        report.id,
        report.description,
        report.reportType,
        getReportObservationValue(report),
        report.reporterName,
        getReportLocationName(report),
      ]
        .join(' ')
        .toLowerCase()
        .includes(normalizedSearch),
    )
  }, [activeFilter, localReports, searchTerm])

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

  function requestReportAction(report, action) {
    setPendingAction({ ...action, report })
  }

  async function confirmReportAction(reason = '') {
    if (!pendingAction) return
    const { action, report, successMessage } = pendingAction
    setPendingAction(null)
    if (!report || !action) return

    try {
      await action(report.id, reason)
      setActionMessage(successMessage)
    } catch (updateError) {
      setActionMessage(updateError.message)
    }
  }

  function exportCsv() {
    const header = [
      'id',
      'type',
      'observation',
      'location',
      'reporter',
      'created',
      'status',
    ]
    const rows = filteredReports.map((report) => [
      report.id,
      getReportTypeName(report),
      getReportObservationValue(report),
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
      <PageTopbar
        action={
          <PrimaryActionButton onClick={exportCsv}>
            Export CSV
          </PrimaryActionButton>
        }
        description="Review, verify, hide, or resolve community rain and flood reports."
        search={{
          ariaLabel: 'Search admin records',
          onChange: setSearchTerm,
          value: searchTerm,
        }}
        title="Reports Management"
      />

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
              {reportFilters.map((filter) => (
                <FilterChip
                  activeFilter={activeFilter}
                  key={filter.value}
                  label={filter.label}
                  setActiveFilter={setActiveFilter}
                  tone={filter.tone}
                  value={filter.value}
                />
              ))}
            </div>
          </div>

          <div className="reports-table-wrap">
            <table className="reports-table reports-review-table">
              <thead>
                <tr>
                  <th>Report</th>
                  <th>Observation</th>
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
                {filteredReports.map((report) => (
                  <tr key={report.id}>
                    <td>
                      <strong>{getReportTypeName(report)}</strong>
                    </td>
                    <td>
                      <span
                        className={`status-pill observation-pill ${riskClass(report)}`}
                        title={getReportObservationValue(report)}
                      >
                        {getReportObservationShortValue(report)}
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
                      <AdminActionGroup>
                        <AdminActionButton
                          icon={CheckCircle2}
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
                                    action: unverifyReport,
                                  }
                                : {
                                    confirmLabel: 'Verify report',
                                    intent: 'primary',
                                    message:
                                      'This marks the report as reviewed and trusted by admin.',
                                    successMessage:
                                      'Report marked as verified.',
                                    title: 'Verify this report?',
                                    action: verifyReport,
                                  },
                            )
                          }
                          type="button"
                          title={
                            report.status === 'verified'
                              ? 'Remove verified status'
                              : 'Mark report as verified'
                          }
                          tone={report.status === 'verified' ? 'ghost' : 'verify'}
                        >
                          {report.status === 'verified' ? 'Unverify' : 'Verify'}
                        </AdminActionButton>
                        {isReportResolved(report) ? (
                          <AdminActionButton
                            icon={RotateCcw}
                            onClick={() =>
                              requestReportAction(report, {
                                confirmLabel: 'Reopen report',
                                intent: 'primary',
                                message:
                                  'This returns the report to the active review queue and can make it visible again in active admin views.',
                                successMessage: 'Report reopened.',
                                title: 'Reopen this report?',
                                action: reopenReport,
                              })
                            }
                            title="Reopen resolved report"
                            tone="resolve"
                          >
                            Reopen
                          </AdminActionButton>
                        ) : (
                          <AdminActionButton
                            icon={RotateCcw}
                            onClick={() =>
                              requestReportAction(report, {
                                confirmLabel: 'Resolve report',
                                intent: 'primary',
                                message:
                                  'This marks the report as resolved so admins know the issue no longer needs active handling.',
                                successMessage: 'Report marked as resolved.',
                                title: 'Resolve this report?',
                                action: resolveReport,
                              })
                            }
                            title="Mark report as resolved"
                            tone="resolve"
                          >
                            Resolve
                          </AdminActionButton>
                        )}
                        {isReportHidden(report) ? (
                          <AdminActionButton
                            icon={Eye}
                            onClick={() =>
                              requestReportAction(report, {
                                confirmLabel: 'Unhide report',
                                intent: 'primary',
                                message:
                                  'This returns the report to the active review queue and allows it to appear again in public views when eligible.',
                                successMessage: 'Report unhidden.',
                                title: 'Unhide this report?',
                                action: unhideReport,
                              })
                            }
                            title="Unhide report"
                            tone="ghost"
                          >
                            Unhide
                          </AdminActionButton>
                        ) : (
                          <AdminActionButton
                            icon={EyeOff}
                            onClick={() =>
                              requestReportAction(report, {
                                confirmLabel: 'Hide report',
                                intent: 'danger',
                                message:
                                  'This hides the report from public views because it is duplicate, invalid, or unclear.',
                                reasonLabel: 'Hide reason',
                                reasonPlaceholder:
                                  'Example: Duplicate report, unclear photo, invalid location...',
                                requiresReason: true,
                                successMessage:
                                  'Report hidden from public views.',
                                title: 'Hide this report?',
                                action: hideDuplicateReport,
                              })
                            }
                            title="Hide report"
                            tone="danger"
                          >
                            Hide
                          </AdminActionButton>
                        )}
                        <AdminActionButton
                          icon={Eye}
                          onClick={() => setSelectedReport(report)}
                          title="View report details"
                          tone="ghost"
                        >
                          View
                        </AdminActionButton>
                      </AdminActionGroup>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {status === 'loading' ? (
              <TableState>Loading report queue...</TableState>
            ) : null}
            {status === 'ready' && filteredReports.length === 0 ? (
              <TableState>
                No reports match this view. Try another chip or clear the
                search field.
              </TableState>
            ) : null}
            {hasMore ? (
              <div className="table-load-more">
                <button
                  className="panel-secondary"
                  disabled={isLoadingMore}
                  onClick={loadMore}
                  type="button"
                >
                  {isLoadingMore ? 'Loading older reports...' : 'Load more reports'}
                </button>
              </div>
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
          reasonLabel={pendingAction.reasonLabel}
          reasonPlaceholder={pendingAction.reasonPlaceholder}
          requiresReason={pendingAction.requiresReason}
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
  if (statusValue === 'Verified') return 'status-verified'
  if (statusValue === 'Resolved') return 'status-resolved'
  if (statusValue === 'Flagged' || statusValue === 'Rejected') {
    return 'status-hidden'
  }
  if (statusValue === 'Review') return 'status-review'
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
              <StatusChip>{getReportTypeName(report)}</StatusChip>
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
                label={getReportObservationLabel(report)}
                value={getReportObservationValue(report)}
              />
              {report.hiddenReason ? (
                <InfoItem label="Hide Reason" value={report.hiddenReason} />
              ) : null}
              <InfoItem
                label="Images"
                value={`${images.length || 0} attached`}
              />
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

function FilterChip({
  activeFilter,
  label,
  setActiveFilter,
  tone,
  value,
}) {
  const isActive = activeFilter === value

  return (
    <FilterChipButton
      className="report-filter-chip"
      isActive={isActive}
      onClick={() => setActiveFilter(value)}
      tone={tone}
    >
      {label}
    </FilterChipButton>
  )
}
