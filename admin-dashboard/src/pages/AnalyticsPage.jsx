import { useState } from 'react'
import { ImageOff, X } from 'lucide-react'
import {
  AdminMiniTable,
  AdminMiniTableHeader,
  AdminMiniTableRow,
} from '../components/AdminMiniTable'
import { MetricCard } from '../components/MetricCard'
import { PageTopbar } from '../components/PageTopbar'
import { StatusChip } from '../components/StatusChip'
import { TableState } from '../components/TableState'
import { useAnalytics } from '../hooks/useAnalytics'
import {
  formatAnalyticsDateTime,
  formatAnalyticsLabel,
} from '../utils/analytics'
import {
  getReportLabel,
  getReportLocationName,
  getReportTypeName,
  getReviewStatus,
  getRiskName,
} from '../utils/reports'

const trendRanges = [
  { label: '7 Days', value: '7' },
  { label: '30 Days', value: '30' },
  { label: 'All Time', value: 'all' },
]

export function AnalyticsPage() {
  const [selectedReport, setSelectedReport] = useState(null)
  const [trendRange, setTrendRange] = useState('7')
  const { analytics, error, status } = useAnalytics(trendRange)
  const {
    distributions,
    metrics,
    needsAttention,
    recentHighRiskReports,
    trend,
    trendSummary,
  } = analytics

  return (
    <div className="analytics-page">
      <PageTopbar
        description="Decision support for report volume, active risks, unresolved issues, alerts, and verification activity."
        title="Analytics"
      />

      <main className="analytics-content">
        <section className="metric-row analytics-metrics" aria-label="Analytics metrics">
          <MetricCard accent="#1778d4" className="analytics-metric-card" helper={trendSummary.todayDirection} label="Reports Today" value={trendSummary.today} />
          <MetricCard accent="#102f4d" className="analytics-metric-card" helper={trendSummary.weekDirection} label="7-Day Reports" value={trend.reduce((total, item) => total + item.total, 0)} />
          <MetricCard accent="#e8b118" className="analytics-metric-card" helper="Risk or flood" label="Risk/Flood Reports" value={metrics.highRiskReports} />
          <MetricCard accent="#e24d4d" className="analytics-metric-card" helper="Needs review" label="Pending Action" value={needsAttention.pendingAction} />
        </section>

        {error ? <p className="error-banner">{error}</p> : null}
        {status === 'loading' ? (
          <TableState>Loading analytics from Firestore...</TableState>
        ) : null}

        <section className="analytics-attention-card">
          <div className="analytics-section-heading">
            <div>
              <p>Barangay triage</p>
              <h3>Needs Attention</h3>
            </div>
            <StatusChip tone={needsAttention.pendingAction > 0 ? 'red' : 'green'}>
              {needsAttention.pendingAction > 0 ? 'Action needed' : 'Clear'}
            </StatusChip>
          </div>

          <div className="attention-summary-grid">
            <AttentionStat
              label="Active flood reports, 24h"
              tone="danger"
              value={needsAttention.recentFlood}
            />
            <AttentionStat
              label="Unresolved risk/flood reports"
              tone="warning"
              value={needsAttention.unresolvedRisk}
            />
            <AttentionStat
              label="Pending admin action"
              tone="neutral"
              value={needsAttention.pendingAction}
            />
          </div>
          {needsAttention.recentFlood +
            needsAttention.unresolvedRisk +
            needsAttention.pendingAction === 0 ? (
            <TableState>No urgent flood, risk, or pending reports right now.</TableState>
          ) : null}
        </section>

        <section className="analytics-grid">
          <article className="analytics-card trend-card">
            <div className="analytics-card-heading">
              <div>
                <h3>Reports Over Time</h3>
                <p>Daily rain and flood report activity</p>
              </div>
              <div className="analytics-range-filter" aria-label="Trend range">
                {trendRanges.map((range) => (
                  <button
                    className={trendRange === range.value ? 'is-active' : ''}
                    key={range.value}
                    onClick={() => setTrendRange(range.value)}
                    type="button"
                  >
                    {range.label}
                  </button>
                ))}
              </div>
            </div>
            <TrendChart data={trend} />
          </article>

          <article className="analytics-card mix-card">
            <h3>Reports by Risk Level</h3>
            <DistributionBars data={distributions.risk} />
          </article>

          <article className="analytics-card mix-card">
            <h3>Reports by Status</h3>
            <DistributionBars data={distributions.status} emptyText="No report statuses yet." />
          </article>

          <article className="analytics-card recent-risk-card">
            <h3>Recent High-Risk Reports</h3>
            <RecentHighRiskTable
              reports={recentHighRiskReports}
              setSelectedReport={setSelectedReport}
            />
          </article>
        </section>
      </main>

      {selectedReport ? (
        <AnalyticsReportModal
          onClose={() => setSelectedReport(null)}
          report={selectedReport}
        />
      ) : null}
    </div>
  )
}

function AttentionStat({ label, tone, value }) {
  return (
    <div className={`attention-stat is-${tone}`}>
      <strong>{value}</strong>
      <span>{label}</span>
    </div>
  )
}

function DistributionBars({ data, emptyText = 'No records yet.' }) {
  const max = Math.max(...data.map((item) => item.value), 0)

  if (max === 0) return <TableState>{emptyText}</TableState>

  return (
    <div className="analytics-distribution-list">
      {data.map((item) => (
        <div
          className="distribution-row"
          key={item.label}
          style={{ '--distribution-color': getDistributionColor(item.label) }}
        >
          <span>{item.label}</span>
          <div className="distribution-track">
            <i style={{ width: `${Math.max((item.value / max) * 100, 8)}%` }} />
          </div>
          <strong>{item.value}</strong>
        </div>
      ))}
    </div>
  )
}

function getDistributionColor(label) {
  const normalizedLabel = label.toLowerCase()
  if (normalizedLabel.includes('safe') || normalizedLabel.includes('resolved')) {
    return '#28a985'
  }
  if (normalizedLabel.includes('flood') || normalizedLabel.includes('rejected')) {
    return '#e24d4d'
  }
  if (normalizedLabel.includes('risk') || normalizedLabel.includes('pending')) {
    return '#e8b118'
  }
  return '#1778d4'
}

function RecentHighRiskTable({ reports, setSelectedReport }) {
  if (reports.length === 0) {
    return <TableState>No high-risk reports found.</TableState>
  }

  return (
    <AdminMiniTable className="analytics-risk-table">
      <AdminMiniTableHeader
        columns={['Date/time', 'Type', 'Risk', 'Status', 'Location', 'Action']}
      />
      {reports.map((report) => (
        <AdminMiniTableRow key={report.id}>
          <span>{formatAnalyticsDateTime(report.createdAt)}</span>
          <strong>{getReportTypeName(report)}</strong>
          <StatusChip size="mini" tone={report.riskLevel === 'safe' ? 'green' : 'red'}>
            {getRiskName(report)}
          </StatusChip>
          <StatusChip size="mini" tone={statusTone(report.status)}>
            {getReviewStatus(report)}
          </StatusChip>
          <span>{getReportLocationName(report)}</span>
          <button
            className="mini-link-button"
            onClick={() => setSelectedReport(report)}
            type="button"
          >
            View
          </button>
        </AdminMiniTableRow>
      ))}
    </AdminMiniTable>
  )
}

function TrendChart({ data }) {
  const max = Math.max(
    ...data.flatMap((item) => [item.rain, item.flood]),
    0,
  )

  if (max === 0) {
    return <TableState>No reports in this time range yet.</TableState>
  }

  return (
    <div className="trend-bar-chart" aria-label="Reports over time bar graph">
      <div className="trend-chart-y-label">Number of Reports</div>
      <div className="trend-bars">
        {data.map((item, index) => {
          const shouldShowLabel = index % Math.ceil(data.length / 7) === 0 ||
            index === data.length - 1

          return (
            <div className="trend-bar-item" key={`${item.label}-${index}`} tabIndex={0}>
              <strong>{item.total}</strong>
              <div className="trend-paired-bars" aria-label={`${item.label} rain and flood reports`}>
                <div className="trend-paired-bar">
                  <em>{item.rain}</em>
                  <span
                    className="is-rain"
                    style={{ height: `${Math.max((item.rain / max) * 150, item.rain ? 8 : 0)}px` }}
                    title={`${item.label}: ${item.rain} rain reports`}
                  />
                </div>
                <div className="trend-paired-bar">
                  <em>{item.flood}</em>
                  <span
                    className="is-flood"
                    style={{ height: `${Math.max((item.flood / max) * 150, item.flood ? 8 : 0)}px` }}
                    title={`${item.label}: ${item.flood} flood reports`}
                  />
                </div>
              </div>
              <small>{shouldShowLabel ? item.label : ''}</small>
              <div className="trend-tooltip" role="tooltip">
                <strong>{item.label}</strong>
                <span>Total reports: {item.total}</span>
                <span>Rain reports: {item.rain}</span>
                <span>Flood reports: {item.flood}</span>
              </div>
            </div>
          )
        })}
      </div>
      <div className="trend-chart-x-label">Date</div>
      <div className="trend-chart-legend">
        <span className="is-rain">Rain Reports</span>
        <span className="is-flood">Flood Reports</span>
        <span className="is-total">Top number is total</span>
      </div>
    </div>
  )
}

function AnalyticsReportModal({ onClose, report }) {
  const image = report.imageUrl || report.imageUrls?.[0]

  return (
    <div
      aria-labelledby="analytics-report-title"
      aria-modal="true"
      className="report-modal-backdrop"
      onClick={onClose}
      role="dialog"
    >
      <section
        className="report-modal report-modal-simple analytics-report-modal"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="simple-modal-header">
          <div>
            <p className="modal-eyebrow">Analytics report</p>
            <h3 id="analytics-report-title">{getReportLabel(report)}</h3>
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
        <div className="analytics-modal-body">
          <div className="analytics-modal-image">
            {image ? (
              <img alt="Report evidence" src={image} />
            ) : (
              <span>
                <ImageOff aria-hidden="true" size={24} />
                No photo attached
              </span>
            )}
          </div>
          <div className="analytics-modal-details">
            <div className="simple-chip-row">
              <StatusChip>{getReportTypeName(report)}</StatusChip>
              <StatusChip tone={report.riskLevel === 'safe' ? 'green' : 'red'}>
                {getRiskName(report)}
              </StatusChip>
              <StatusChip tone={statusTone(report.status)}>
                {formatAnalyticsLabel(report.status)}
              </StatusChip>
            </div>
            <h4>{getReportLocationName(report)}</h4>
            <p>{report.description || 'No description was provided.'}</p>
            <div className="simple-meta-list">
              <InfoItem label="Created" value={formatAnalyticsDateTime(report.createdAt)} />
              <InfoItem label="Reporter" value={report.reporterName || 'Anonymous'} />
              <InfoItem label="Latitude" value={formatCoordinate(report.latitude)} />
              <InfoItem label="Longitude" value={formatCoordinate(report.longitude)} />
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

function formatCoordinate(value) {
  return Number.isFinite(value) ? value.toFixed(5) : 'Unknown'
}

function statusTone(status) {
  if (status === 'verified' || status === 'resolved' || status === 'published') {
    return 'green'
  }
  if (status === 'rejected' || status === 'duplicate_hidden' || status === 'hidden') {
    return 'red'
  }
  if (status === 'pending' || status === 'review') return 'amber'
  return 'blue'
}
