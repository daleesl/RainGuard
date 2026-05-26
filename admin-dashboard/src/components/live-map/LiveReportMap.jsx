import { Fragment, useMemo, useState } from 'react'
import L from 'leaflet'
import {
  CircleMarker,
  MapContainer,
  Marker,
  TileLayer,
  useMap,
  useMapEvents,
} from 'react-leaflet'
import {
  CALAMBA_CENTER,
  getReportColor,
} from '../../utils/reports'

const CLUSTER_RADIUS_PX = 48
const CLUSTER_MAX_ZOOM = 17

export function LiveReportMap({
  activeFilter,
  calambaReports,
  filteredReports,
  onClearFilters,
  onFilterChange,
  onSelectReport,
  reports,
  searchTerm,
  status,
}) {
  return (
    <article className="map-card">
      <div className="card-heading">
        <h3>Calamba Report Map</h3>
        <div className="chip-group">
          <FilterChip
            activeFilter={activeFilter}
            colorClass="chip-blue"
            label="Today"
            setActiveFilter={onFilterChange}
            value="today"
          />
          <FilterChip
            activeFilter={activeFilter}
            colorClass="chip-red"
            label="Flood"
            setActiveFilter={onFilterChange}
            value="flood"
          />
          <FilterChip
            activeFilter={activeFilter}
            colorClass="chip-blue"
            label="Rain"
            setActiveFilter={onFilterChange}
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
            onOpenReport={onSelectReport}
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
          onClick={onClearFilters}
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
