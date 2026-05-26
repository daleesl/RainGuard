import { useMemo, useState } from 'react'
import { doc, updateDoc } from 'firebase/firestore'
import { ConfirmActionModal } from '../components/ConfirmActionModal'
import { ImageZoomOverlay } from '../components/live-map/ImageZoomOverlay'
import { LiveReportMap } from '../components/live-map/LiveReportMap'
import { ReportDetailModal } from '../components/live-map/ReportDetailModal'
import { SelectedReportPanel } from '../components/live-map/SelectedReportPanel'
import { MetricCard } from '../components/MetricCard'
import { PageTopbar } from '../components/PageTopbar'
import { db } from '../firebase'
import { useReports } from '../hooks/useReports'
import { isToday } from '../utils/reports'

const metricConfig = [
  {
    key: 'active',
    label: 'Active pins',
    helper: 'Visible on map',
    accent: '#1778d4',
  },
  {
    key: 'flood',
    label: 'Flood zones',
    helper: 'Needs review',
    accent: '#e24d4d',
  },
  {
    key: 'rain',
    label: 'Rain clusters',
    helper: 'Increasing',
    accent: '#e8b118',
  },
  {
    key: 'resolved',
    label: 'Resolved',
    helper: 'Today',
    accent: '#28c59d',
  },
]

export function LiveRiskMap() {
  const { reports, calambaReports, status, error } = useReports()
  const [activeFilter, setActiveFilter] = useState('all')
  const [modalReportId, setModalReportId] = useState('')
  const [selectedReportId, setSelectedReportId] = useState('')
  const [selectedImageIndex, setSelectedImageIndex] = useState(0)
  const [zoomImageUrl, setZoomImageUrl] = useState('')
  const [searchTerm, setSearchTerm] = useState('')
  const [actionMessage, setActionMessage] = useState('')
  const [pendingAction, setPendingAction] = useState(null)

  const filteredReports = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase()
    const visibleReports = calambaReports.filter((report) => {
      if (activeFilter === 'today') return isToday(report.createdAt)
      if (activeFilter === 'flood') return report.reportType === 'flood'
      if (activeFilter === 'rain') return report.reportType === 'rain'
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
      ]
        .join(' ')
        .toLowerCase()
        .includes(normalizedSearch),
    )
  }, [activeFilter, calambaReports, searchTerm])

  const selectedReport = useMemo(
    () =>
      filteredReports.find((report) => report.id === selectedReportId) ||
      filteredReports[0] ||
      null,
    [filteredReports, selectedReportId],
  )

  const stats = useMemo(() => {
    const todayReports = filteredReports.filter((report) =>
      isToday(report.createdAt),
    )
    const floodReports = filteredReports.filter(
      (report) => report.reportType === 'flood',
    )
    const rainReports = filteredReports.filter(
      (report) => report.reportType === 'rain',
    )
    const resolvedReports = filteredReports.filter(
      (report) => report.status === 'resolved',
    )

    return {
      active: todayReports.length || filteredReports.length,
      flood: floodReports.length,
      rain: rainReports.length,
      resolved: resolvedReports.length,
    }
  }, [filteredReports])

  const modalReport = useMemo(
    () =>
      filteredReports.find((report) => report.id === modalReportId) ||
      calambaReports.find((report) => report.id === modalReportId) ||
      null,
    [calambaReports, filteredReports, modalReportId],
  )

  function clearFilters() {
    setActiveFilter('all')
    setSearchTerm('')
  }

  function selectReport(report) {
    setSelectedReportId(report.id)
    setSelectedImageIndex(0)
  }

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

  return (
    <div className="live-map-page">
      <PageTopbar
        action={
          <button className="primary-action" type="button">
            Create Alert
          </button>
        }
        description="Monitor real-time Calamba flood/rain reports and active advisories."
        search={{
          ariaLabel: 'Search admin records',
          onChange: setSearchTerm,
          value: searchTerm,
        }}
        title="Live Risk Map"
      />

      <main className="live-map-content">
        <section className="metric-row" aria-label="Live report metrics">
          {metricConfig.map((metric) => (
            <MetricCard
              accent={metric.accent}
              helper={metric.helper}
              key={metric.key}
              label={metric.label}
              value={stats[metric.key]}
            />
          ))}
        </section>

        {error ? <p className="error-banner">{error}</p> : null}
        {actionMessage ? <p className="success-banner">{actionMessage}</p> : null}

        <section className="map-and-details">
          <LiveReportMap
            activeFilter={activeFilter}
            calambaReports={calambaReports}
            filteredReports={filteredReports}
            onClearFilters={clearFilters}
            onFilterChange={setActiveFilter}
            onSelectReport={selectReport}
            reports={reports}
            searchTerm={searchTerm}
            status={status}
          />

          <SelectedReportPanel
            imageIndex={selectedImageIndex}
            onImageIndexChange={setSelectedImageIndex}
            onOpenDetails={(report) => setModalReportId(report.id)}
            onRequestAction={requestReportAction}
            onZoomImage={setZoomImageUrl}
            report={selectedReport}
          />
        </section>
      </main>

      {modalReport ? (
        <ReportDetailModal
          imageIndex={selectedImageIndex}
          onClose={() => setModalReportId('')}
          onImageIndexChange={setSelectedImageIndex}
          onZoomImage={setZoomImageUrl}
          report={modalReport}
        />
      ) : null}
      {zoomImageUrl ? (
        <ImageZoomOverlay imageUrl={zoomImageUrl} onClose={() => setZoomImageUrl('')} />
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
