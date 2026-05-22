import { Fragment, useMemo, useState } from 'react'
import { doc, updateDoc } from 'firebase/firestore'
import L from 'leaflet'
import {
  CircleMarker,
  MapContainer,
  Marker,
  TileLayer,
  useMap,
  useMapEvents,
} from 'react-leaflet'
import { ImageOff, Search, X } from 'lucide-react'
import { db } from '../firebase'
import { useReports } from '../hooks/useReports'
import {
  CALAMBA_CENTER,
  getReportColor,
  getReportLabel,
  getReportLocationName,
  getReportTypeName,
  getReviewStatus,
  getRiskName,
  isToday,
} from '../utils/reports'

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

const CLUSTER_RADIUS_PX = 48
const CLUSTER_MAX_ZOOM = 17

export function LiveRiskMap() {
  const { reports, calambaReports, status, error } = useReports()
  const [activeFilter, setActiveFilter] = useState('all')
  const [modalReportId, setModalReportId] = useState('')
  const [selectedReportId, setSelectedReportId] = useState('')
  const [selectedImageIndex, setSelectedImageIndex] = useState(0)
  const [zoomImageUrl, setZoomImageUrl] = useState('')
  const [searchTerm, setSearchTerm] = useState('')
  const [actionMessage, setActionMessage] = useState('')

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

  return (
    <div className="live-map-page">
      <header className="admin-topbar">
        <div>
          <h2>Live Risk Map</h2>
          <p>Monitor real-time Calamba flood/rain reports and active advisories.</p>
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
          <button className="primary-action" type="button">
            Create Alert
          </button>
        </div>
      </header>

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
          <article className="map-card">
            <div className="card-heading">
              <h3>Calamba Report Map</h3>
              <div className="chip-group">
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
                  colorClass="chip-blue"
                  label="Rain"
                  setActiveFilter={setActiveFilter}
                  value="rain"
                />
              </div>
            </div>

            <div className="leaflet-shell">
              <MapContainer
                center={CALAMBA_CENTER}
                className="risk-map"
                scrollWheelZoom
                zoom={14}
                zoomControl
              >
                <TileLayer
                  attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                <ClusteredReportMarkers
                  onOpenReport={selectReport}
                  reports={filteredReports}
                />
              </MapContainer>
              <div className="map-legend" aria-label="Map legend">
                <span>
                  <i className="legend-dot legend-dot-flood" /> Flood
                </span>
                <span>
                  <i className="legend-dot legend-dot-rain" /> Rain
                </span>
                <span>
                  <i className="legend-dot legend-dot-risk" /> Risk
                </span>
                <span>
                  <i className="legend-dot legend-dot-safe" /> Safe
                </span>
              </div>
              <span className="map-caption">
                Calamba, Laguna report activity
              </span>
            </div>

            {status === 'loading' ? (
              <p className="inline-state">Loading live reports...</p>
            ) : null}
            {status === 'ready' && filteredReports.length === 0 ? (
              <p className="inline-state">
                No reports match this filter yet. Try clearing search or changing
                the chip filter.
              </p>
            ) : null}

            <div className="map-footer">
              <span>{filteredReports.length} map reports</span>
              <button
                className="footer-filter-reset"
                disabled={activeFilter === 'all' && !searchTerm}
                onClick={() => {
                  setActiveFilter('all')
                  setSearchTerm('')
                }}
                type="button"
              >
                Clear filters
              </button>
              <span>
                {reports.length - calambaReports.length} outside Calamba/PH
              </span>
              <span>{status === 'ready' ? 'Firebase live' : 'Syncing'}</span>
            </div>
          </article>

          <aside className="selected-panel">
            <h3>Selected Report</h3>
            {selectedReport ? (
              <Fragment>
                <ReportImageCarousel
                  imageIndex={selectedImageIndex}
                  onImageIndexChange={setSelectedImageIndex}
                  onZoomImage={setZoomImageUrl}
                  report={selectedReport}
                />

                <div className="selected-report-card" key={selectedReport.id}>
                  <div className="selected-chip-row">
                    <span className="chip chip-blue">
                      {getReportTypeName(selectedReport)}
                    </span>
                    <span
                      className={`chip ${
                        selectedReport.riskLevel === 'safe'
                          ? 'chip-green'
                          : 'chip-red'
                      }`}
                    >
                      {getRiskName(selectedReport)}
                    </span>
                  </div>

                  <div className="selected-copy">
                    <h4>{getReportLocationName(selectedReport)}</h4>
                    <p>
                      {selectedReport.description ||
                        'No description was provided for this report.'}
                    </p>
                  </div>

                  <div className="selected-meta-list">
                    <InfoItem
                      label="Reporter"
                      value={selectedReport.reporterName || 'Anonymous'}
                    />
                    <InfoItem
                      label="Created"
                      value={formatReportDateTime(selectedReport.createdAt)}
                      stacked
                    />
                    <InfoItem
                      label="Status"
                      value={getReviewStatus(selectedReport)}
                    />
                    <InfoItem
                      label="GPS"
                      value={`${selectedReport.latitude.toFixed(5)}, ${selectedReport.longitude.toFixed(5)}`}
                    />
                  </div>
                </div>

                <div className="selected-actions">
                  <button
                    className="panel-primary"
                    onClick={() =>
                      updateReportStatus(
                        selectedReport,
                        { status: 'verified', report_status: 'verified' },
                        'Report marked as verified.',
                      )
                    }
                    type="button"
                  >
                    Mark Verified
                  </button>
                  <button
                    className="panel-secondary"
                    onClick={() => setModalReportId(selectedReport.id)}
                    type="button"
                  >
                    Open Full Details
                  </button>
                  <button
                    className="panel-secondary"
                    onClick={() =>
                      updateReportStatus(
                        selectedReport,
                        { status: 'resolved', report_status: 'resolved' },
                        'Report marked as resolved.',
                      )
                    }
                    type="button"
                  >
                    Resolve Report
                  </button>
                  <button
                    className="panel-danger"
                    onClick={() =>
                      updateReportStatus(
                        selectedReport,
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
                    Hide Duplicate
                  </button>
                </div>
              </Fragment>
            ) : (
              <p className="inline-state">
                Select a map pin to review report information.
              </p>
            )}
          </aside>
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

function ClusteredReportMarkers({ onOpenReport, reports }) {
  const map = useMap()
  const [mapState, setMapState] = useState(() => getMapState(map))
  const [expandedClusterId, setExpandedClusterId] = useState('')

  useMapEvents({
    moveend: () => {
      setMapState(getMapState(map))
      setExpandedClusterId('')
    },
    zoomend: () => {
      setMapState(getMapState(map))
      setExpandedClusterId('')
    },
  })

  const markerGroups = useMemo(() => {
    if (mapState.zoom > CLUSTER_MAX_ZOOM) {
      return reports.map((report) => ({
        id: report.id,
        latitude: report.latitude,
        longitude: report.longitude,
        reports: [report],
        type: 'pin',
      }))
    }

    const clusters = []

    reports.forEach((report) => {
      const point = map.project([report.latitude, report.longitude], mapState.zoom)
      const nearbyCluster = clusters.find(
        (cluster) => point.distanceTo(cluster.centerPoint) <= CLUSTER_RADIUS_PX,
      )

      if (nearbyCluster) {
        nearbyCluster.reports.push(report)
        nearbyCluster.centerPoint = averageClusterPoint(
          nearbyCluster.reports,
          map,
          mapState.zoom,
        )
        return
      }

      clusters.push({
        centerPoint: point,
        reports: [report],
      })
    })

    return clusters.map((cluster) => {
      const center = map.unproject(cluster.centerPoint, mapState.zoom)

      return {
        id: cluster.reports.map((report) => report.id).join('-'),
        latitude: center.lat,
        longitude: center.lng,
        reports: cluster.reports,
        type: cluster.reports.length > 1 ? 'cluster' : 'pin',
      }
    })
  }, [map, mapState.zoom, reports])

  return markerGroups.map((group) => {
    if (group.type === 'cluster') {
      const floodCount = group.reports.filter(
        (report) => report.reportType === 'flood' || report.riskLevel === 'flood',
      ).length
      const isExpanded = expandedClusterId === group.id
      const className = [
        'report-cluster',
        floodCount > 0 ? 'has-flood' : '',
        isExpanded ? 'is-expanded' : '',
      ]
        .filter(Boolean)
        .join(' ')
      const spiderPins = isExpanded ? getSpiderPins(group, map, mapState.zoom) : []

      return (
        <Fragment key={group.id}>
          {!isExpanded ? (
            <Marker
              eventHandlers={{
                click: () => setExpandedClusterId(group.id),
              }}
              icon={L.divIcon({
                className: '',
                html: `<span class="${className}">${group.reports.length}</span>`,
                iconAnchor: [19, 19],
                iconSize: [38, 38],
              })}
              position={[group.latitude, group.longitude]}
            />
          ) : null}

          {spiderPins.map(({ position, report }) => (
            <Marker
              eventHandlers={{
                click: () => onOpenReport(report),
              }}
              icon={L.divIcon({
                className: '',
                html: `<span class="spider-report-pin" style="--pin-color:${getReportColor(
                  report,
                )}"><span></span><i></i></span>`,
                iconAnchor: [18, 18],
                iconSize: [44, 44],
              })}
              key={`${report.id}-spider`}
              position={position}
            />
          ))}
        </Fragment>
      )
    }

    const report = group.reports[0]

    return (
      <CircleMarker
        center={[report.latitude, report.longitude]}
        eventHandlers={{
          click: () => onOpenReport(report),
        }}
        fillColor={getReportColor(report)}
        fillOpacity={0.9}
        key={report.id}
        pathOptions={{
          color: '#ffffff',
          fillColor: getReportColor(report),
          fillOpacity: 0.92,
          weight: 3,
        }}
        radius={8}
      />
    )
  })
}

function averageClusterPoint(reports, map, zoom) {
  const total = reports.reduce(
    (sum, report) => {
      const point = map.project([report.latitude, report.longitude], zoom)
      return {
        x: sum.x + point.x,
        y: sum.y + point.y,
      }
    },
    { x: 0, y: 0 },
  )

  return L.point(total.x / reports.length, total.y / reports.length)
}

function getSpiderPins(group, map, zoom) {
  const centerPoint = map.project([group.latitude, group.longitude], zoom)
  const goldenAngle = Math.PI * (3 - Math.sqrt(5))
  const startRadius = 18
  const radiusStep = 4
  const maxRadius = 58

  return group.reports.map((report, index) => {
    const angle = index * goldenAngle - Math.PI / 2
    const radius = Math.min(startRadius + index * radiusStep, maxRadius)
    const point = L.point(
      centerPoint.x + Math.cos(angle) * radius,
      centerPoint.y + Math.sin(angle) * radius,
    )
    const latLng = map.unproject(point, zoom)

    return {
      position: [latLng.lat, latLng.lng],
      report,
    }
  })
}

function getMapState(map) {
  return {
    boundsKey: map.getBounds().toBBoxString(),
    zoom: map.getZoom(),
  }
}

function ReportImageCarousel({
  imageIndex,
  onImageIndexChange,
  onZoomImage,
  report,
}) {
  const images = report.imageUrls.length > 0 ? report.imageUrls : []
  const safeIndex = Math.min(imageIndex, Math.max(images.length - 1, 0))
  const currentImage = images[safeIndex]

  function goToImage(direction) {
    if (images.length <= 1) return
    const nextIndex = (safeIndex + direction + images.length) % images.length
    onImageIndexChange(nextIndex)
  }

  return (
    <div className="report-image-carousel">
      <button
        aria-label={
          currentImage ? 'Zoom selected report photo' : 'No report photo attached'
        }
        className="report-image-main"
        disabled={!currentImage}
        onClick={() => currentImage && onZoomImage(currentImage)}
        type="button"
      >
        {currentImage ? (
          <img alt="Submitted report evidence" src={currentImage} />
        ) : (
          <span className="report-modal-empty-image">
            <ImageOff aria-hidden="true" size={24} />
            <span>No photo attached</span>
          </span>
        )}
      </button>

      {images.length > 1 ? (
        <div className="report-image-controls">
          <button onClick={() => goToImage(-1)} type="button">
            Prev
          </button>
          <span>
            {safeIndex + 1} / {images.length}
          </span>
          <button onClick={() => goToImage(1)} type="button">
            Next
          </button>
        </div>
      ) : null}
    </div>
  )
}

function ReportDetailModal({
  imageIndex,
  onClose,
  onImageIndexChange,
  onZoomImage,
  report,
}) {
  return (
    <div
      aria-labelledby="report-modal-title"
      aria-modal="true"
      className="report-modal-backdrop"
      onClick={onClose}
      role="dialog"
    >
      <section
        className="report-modal report-modal-simple"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="simple-modal-header">
          <div>
            <p className="modal-eyebrow">Community report</p>
            <h3 id="report-modal-title">{getReportLabel(report)}</h3>
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
          <ReportImageCarousel
            imageIndex={imageIndex}
            onImageIndexChange={onImageIndexChange}
            onZoomImage={onZoomImage}
            report={report}
          />

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
              <InfoItem
                label="Created"
                value={formatReportDateTime(report.createdAt)}
                stacked
              />
              <InfoItem label="Status" value={getReviewStatus(report)} />
              <InfoItem
                label="GPS"
                value={`${report.latitude.toFixed(5)}, ${report.longitude.toFixed(5)}`}
              />
              <InfoItem label="Source" value={report.locationSource} />
              <InfoItem
                label="Images"
                value={`${report.imageUrls.length || 0} attached`}
              />
              {report.floodLevel ? (
                <InfoItem label="Flood level" value={report.floodLevel} />
              ) : null}
            </div>

            <div className="simple-modal-actions">
              <button className="panel-secondary" onClick={onClose} type="button">
                Back to Map
              </button>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}

function ImageZoomOverlay({ imageUrl, onClose }) {
  return (
    <div
      aria-label="Zoomed report photo"
      aria-modal="true"
      className="image-zoom-backdrop"
      onClick={onClose}
      role="dialog"
    >
      <button
        aria-label="Close zoomed image"
        className="modal-close image-zoom-close"
        onClick={onClose}
        type="button"
      >
        <X aria-hidden="true" size={18} />
      </button>
      <img alt="Zoomed report evidence" onClick={(event) => event.stopPropagation()} src={imageUrl} />
    </div>
  )
}

function formatReportDateTime(date) {
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

function InfoItem({ label, stacked = false, value }) {
  return (
    <div className={`modal-info-item ${stacked ? 'is-stacked' : ''}`}>
      <span>{label}</span>
      {stacked && typeof value === 'object' ? (
        <strong>
          <em>{value.primary}</em>
          <em>{value.secondary}</em>
        </strong>
      ) : (
        <strong>{value}</strong>
      )}
    </div>
  )
}
