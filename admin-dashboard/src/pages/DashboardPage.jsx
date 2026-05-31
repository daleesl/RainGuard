import { useMemo, useState } from 'react'
import {
  Activity,
  ArrowRight,
  BarChart3,
  Bell,
  ClipboardList,
  Map,
  Settings,
  ShieldCheck,
  Users,
  Waves,
} from 'lucide-react'
import { MetricCard } from '../components/MetricCard'
import { PageTopbar } from '../components/PageTopbar'
import { PrimaryActionButton } from '../components/PrimaryActionButton'
import { useAlerts } from '../hooks/useAlerts'
import { useReports } from '../hooks/useReports'
import { useUsers } from '../hooks/useUsers'
import {
  formatReportTime,
  getReportLocationName,
  getReportTypeName,
  getReviewStatus,
  isToday,
} from '../utils/reports'

export function DashboardPage({ onNavigate }) {
  const { calambaReports, error: reportsError, status: reportsStatus } = useReports()
  const { users, pendingUsers, error: usersError } = useUsers()
  const { alerts, error: alertsError } = useAlerts()
  const [now] = useState(() => Date.now())

  const residentUsers = useMemo(
    () => users.filter((user) => user.role !== 'admin'),
    [users],
  )

  const metrics = useMemo(() => {
    const activeReports = calambaReports.filter(
      (report) => !['resolved', 'duplicate_hidden'].includes(report.status),
    )
    const verifiedReports = calambaReports.filter(
      (report) => report.status === 'verified',
    )
    const floodReports = activeReports.filter(
      (report) => report.reportType === 'flood' || report.riskLevel === 'flood',
    )
    const activeAlerts = alerts.filter((alert) => alert.status === 'published')

    return {
      activeAlerts: activeAlerts.length,
      activeReports: activeReports.length,
      floodReports: floodReports.length,
      pendingIds: pendingUsers.filter((user) => user.role !== 'admin').length,
      registeredResidents: residentUsers.length,
      reportsToday: calambaReports.filter((report) => isToday(report.createdAt)).length,
      verifiedReports: verifiedReports.length,
    }
  }, [alerts, calambaReports, pendingUsers, residentUsers])

  const recentReports = useMemo(
    () =>
      calambaReports
        .filter((report) => report.status !== 'duplicate_hidden')
        .slice(0, 5),
    [calambaReports],
  )

  const recentAlerts = useMemo(
    () => alerts.filter((alert) => alert.status === 'published').slice(0, 3),
    [alerts],
  )

  const quickLinks = [
    {
      id: 'liveMap',
      title: 'Live Risk Map',
      description: 'Monitor clustered rain and flood reports across Calamba.',
      icon: Map,
      meta: `${metrics.activeReports} active reports`,
    },
    {
      id: 'reports',
      title: 'Reports Management',
      description: 'Verify, resolve, hide, and inspect submitted reports.',
      icon: ClipboardList,
      meta: `${metrics.reportsToday} reports today`,
    },
    {
      id: 'verification',
      title: 'Verification Review',
      description: 'Review resident ID uploads before allowing report submission.',
      icon: ShieldCheck,
      meta: `${metrics.pendingIds} pending IDs`,
    },
    {
      id: 'alerts',
      title: 'Alerts Management',
      description: 'Publish safety advisories for residents and responders.',
      icon: Bell,
      meta: `${metrics.activeAlerts} active alerts`,
    },
    {
      id: 'users',
      title: 'Users Management',
      description: 'Inspect resident accounts, IDs, and account access state.',
      icon: Users,
      meta: `${metrics.registeredResidents} residents`,
    },
    {
      id: 'analytics',
      title: 'Analytics',
      description: 'Review report trends, hotspots, and verification throughput.',
      icon: BarChart3,
      meta: `${metrics.verifiedReports} verified reports`,
    },
    {
      id: 'settings',
      title: 'Settings',
      description: 'Prepare admin preferences and dashboard configuration.',
      icon: Settings,
      meta: 'Admin controls',
    },
  ]

  const healthItems = [
    {
      label: 'Report feed',
      state: reportsStatus === 'ready' ? 'Live' : 'Checking',
      tone: reportsStatus === 'ready' ? 'good' : 'watch',
    },
    {
      label: 'Resident records',
      state: usersError ? 'Needs rules' : 'Connected',
      tone: usersError ? 'risk' : 'good',
    },
    {
      label: 'Alert feed',
      state: alertsError ? 'Needs rules' : 'Connected',
      tone: alertsError ? 'risk' : 'good',
    },
  ]

  return (
    <div className="dashboard-page">
      <PageTopbar
        action={
          <PrimaryActionButton onClick={() => onNavigate('liveMap')}>
            Open Live Map
          </PrimaryActionButton>
        }
        description="Open key admin tools and check current RainGuard operations."
        title="Dashboard"
      />

      <main className="dashboard-content">
        {reportsError || usersError || alertsError ? (
          <p className="error-banner">
            {reportsError || usersError || alertsError}
          </p>
        ) : null}

        <section className="dashboard-hero-panel">
          <div>
            <p className="dashboard-eyebrow">Barangay Safety Desk</p>
            <h3>Command center for today&apos;s reports, alerts, and resident access.</h3>
            <span>
              Use this page as the starting point before opening the live map,
              report queue, verification review, or alert composer.
            </span>
          </div>
          <div className="dashboard-hero-actions">
            <button onClick={() => onNavigate('reports')} type="button">
              Review Reports
              <ArrowRight aria-hidden="true" size={14} />
            </button>
            <button onClick={() => onNavigate('alerts')} type="button">
              Publish Alert
              <ArrowRight aria-hidden="true" size={14} />
            </button>
          </div>
        </section>

        <section className="metric-row dashboard-metrics" aria-label="Dashboard metrics">
          <MetricCard
            accent="#1778d4"
            className="dashboard-metric-card"
            helper="Open map pins"
            icon={Activity}
            label="Active Reports"
            value={metrics.activeReports}
          />
          <MetricCard
            accent="#e24d4d"
            className="dashboard-metric-card"
            helper="Flood or flood risk"
            icon={Waves}
            label="Flood Signals"
            value={metrics.floodReports}
          />
          <MetricCard
            accent="#e8b118"
            className="dashboard-metric-card"
            helper="Require review"
            icon={ShieldCheck}
            label="Pending IDs"
            value={metrics.pendingIds}
          />
          <MetricCard
            accent="#28c59d"
            className="dashboard-metric-card"
            helper="Published advisories"
            icon={Bell}
            label="Active Alerts"
            value={metrics.activeAlerts}
          />
        </section>

        <section className="dashboard-grid">
          <article className="dashboard-card quick-access-card">
            <div className="dashboard-card-heading">
              <div>
                <h3>Quick Access</h3>
                <p>Jump to any admin page from one place.</p>
              </div>
            </div>

            <div className="quick-access-grid">
              {quickLinks.map((link) => {
                const Icon = link.icon

                return (
                  <button
                    className="quick-access-tile"
                    key={link.id}
                    onClick={() => onNavigate(link.id)}
                    type="button"
                  >
                    <span className="quick-access-icon">
                      <Icon aria-hidden="true" size={17} />
                    </span>
                    <span>
                      <strong>{link.title}</strong>
                      <small>{link.description}</small>
                      <em>{link.meta}</em>
                    </span>
                    <ArrowRight aria-hidden="true" size={15} />
                  </button>
                )
              })}
            </div>
          </article>

          <aside className="dashboard-side-stack">
            <article className="dashboard-card">
              <div className="dashboard-card-heading">
                <div>
                  <h3>System Readiness</h3>
                  <p>Live data connections used by the dashboard.</p>
                </div>
              </div>
              <div className="readiness-list">
                {healthItems.map((item) => (
                  <div className="readiness-row" key={item.label}>
                    <span>{item.label}</span>
                    <strong className={`readiness-${item.tone}`}>
                      {item.state}
                    </strong>
                  </div>
                ))}
              </div>
            </article>

            <article className="dashboard-card">
              <div className="dashboard-card-heading">
                <div>
                  <h3>Priority Actions</h3>
                  <p>Recommended next admin checks.</p>
                </div>
              </div>
              <div className="priority-list">
                <PriorityButton
                  count={metrics.floodReports}
                  icon={Waves}
                  label="Check flood reports"
                  onClick={() => onNavigate('liveMap')}
                />
                <PriorityButton
                  count={metrics.pendingIds}
                  icon={ShieldCheck}
                  label="Review pending IDs"
                  onClick={() => onNavigate('verification')}
                />
                <PriorityButton
                  count={metrics.activeAlerts}
                  icon={Bell}
                  label="Review active alerts"
                  onClick={() => onNavigate('alerts')}
                />
              </div>
            </article>
          </aside>
        </section>

        <section className="dashboard-lower-grid">
          <article className="dashboard-card">
            <div className="dashboard-card-heading">
              <div>
                <h3>Recent Reports</h3>
                <p>Latest community reports in the current map scope.</p>
              </div>
              <button onClick={() => onNavigate('reports')} type="button">
                View all
              </button>
            </div>
            <div className="dashboard-list">
              {recentReports.length > 0 ? (
                recentReports.map((report) => (
                  <div className="dashboard-list-row" key={report.id}>
                    <span className="dashboard-list-icon">
                      <ClipboardList aria-hidden="true" size={14} />
                    </span>
                    <div>
                      <strong>{getReportTypeName(report)}</strong>
                      <small>{getReportLocationName(report)}</small>
                    </div>
                    <em>{getReviewStatus(report)}</em>
                    <time>{formatReportTime(report.createdAt)}</time>
                  </div>
                ))
              ) : (
                <p className="dashboard-empty">No recent reports yet.</p>
              )}
            </div>
          </article>

          <article className="dashboard-card">
            <div className="dashboard-card-heading">
              <div>
                <h3>Published Alerts</h3>
                <p>Latest active alerts visible to residents.</p>
              </div>
              <button onClick={() => onNavigate('alerts')} type="button">
                Manage
              </button>
            </div>
            <div className="dashboard-list">
              {recentAlerts.length > 0 ? (
                recentAlerts.map((alert) => (
                  <div className="dashboard-list-row" key={alert.id}>
                    <span className="dashboard-list-icon">
                      <Bell aria-hidden="true" size={14} />
                    </span>
                    <div>
                      <strong>{alert.title}</strong>
                      <small>{alert.area}</small>
                    </div>
                    <em>{formatLabel(alert.riskLevel)}</em>
                    <time>{formatRelativeTime(alert.publishedAt, now)}</time>
                  </div>
                ))
              ) : (
                <p className="dashboard-empty">No active alerts published.</p>
              )}
            </div>
          </article>
        </section>
      </main>
    </div>
  )
}

function PriorityButton({ count, icon: Icon, label, onClick }) {
  return (
    <button className="priority-button" onClick={onClick} type="button">
      <span>
        <Icon aria-hidden="true" size={15} />
        {label}
      </span>
      <strong>{count}</strong>
    </button>
  )
}

function formatLabel(value) {
  if (!value) return 'Unknown'
  return `${value.charAt(0).toUpperCase()}${value.slice(1)}`
}

function formatRelativeTime(date, now) {
  if (!date) return 'Pending'
  const diffMinutes = Math.max(0, Math.round((now - date.getTime()) / 60000))

  if (diffMinutes < 1) return 'Now'
  if (diffMinutes < 60) return `${diffMinutes}m ago`

  const diffHours = Math.round(diffMinutes / 60)
  if (diffHours < 24) return `${diffHours}h ago`

  return new Intl.DateTimeFormat('en-PH', {
    month: 'short',
    day: 'numeric',
  }).format(date)
}
