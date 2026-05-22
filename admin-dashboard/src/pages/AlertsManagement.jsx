import { useMemo, useState } from 'react'
import { Search } from 'lucide-react'

const initialAlerts = [
  ['Lingga flood watch', 'Lingga', 'Active'],
  ['Heavy rainfall', 'Calamba', 'Active'],
  ['Road passable', 'Halang', 'Resolved'],
  ['Preparedness tips', 'All users', 'Scheduled'],
  ['Duplicate advisory', 'Pansol', 'Draft'],
]

export function AlertsManagement() {
  const [alerts, setAlerts] = useState(initialAlerts)
  const [alertTitle, setAlertTitle] = useState('Heavy rainfall near Lingga Creek')
  const [message, setMessage] = useState(
    'Avoid low-lying roads near Lingga Creek. Monitor updates and submit reports only when safe.',
  )
  const [searchTerm, setSearchTerm] = useState('')
  const [statusMessage, setStatusMessage] = useState('')

  const filteredAlerts = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase()
    if (!normalizedSearch) return alerts

    return alerts.filter((alert) =>
      alert.join(' ').toLowerCase().includes(normalizedSearch),
    )
  }, [alerts, searchTerm])

  function publishAlert() {
    setAlerts((currentAlerts) => [
      [alertTitle || 'Untitled advisory', 'Lingga', 'Active'],
      ...currentAlerts,
    ])
    setStatusMessage('Alert added to the active list for this session.')
  }

  function saveDraft() {
    setAlerts((currentAlerts) => [
      [alertTitle || 'Untitled advisory', 'Lingga', 'Draft'],
      ...currentAlerts,
    ])
    setStatusMessage('Draft saved locally in the dashboard view.')
  }

  return (
    <div className="alerts-page">
      <header className="admin-topbar">
        <div>
          <h2>Alerts Management</h2>
          <p>Create safety advisories and manage active/resolved alert messages.</p>
        </div>
        <div className="topbar-actions">
          <label className="search-field">
            <Search aria-hidden="true" size={14} />
            <input
              aria-label="Search alert records"
              onChange={(event) => setSearchTerm(event.target.value)}
              placeholder="Search admin records"
              type="search"
              value={searchTerm}
            />
          </label>
          <button className="primary-action" onClick={publishAlert} type="button">
            Publish Alert
          </button>
        </div>
      </header>

      <main className="alerts-content">
        <section className="metric-row review-metrics" aria-label="Alert metrics">
          <MetricCard accent="#1778d4" helper="2 high priority" label="Active alerts" value={alerts.filter((alert) => alert[2] === 'Active').length} />
          <MetricCard accent="#e8b118" helper="Awaiting approval" label="Drafts" value={alerts.filter((alert) => alert[2] === 'Draft').length} />
          <MetricCard accent="#28c59d" helper="Push + in-app" label="Sent today" value={8} />
        </section>

        {statusMessage ? <p className="success-banner">{statusMessage}</p> : null}

        <section className="alerts-grid">
          <article className="alert-composer-card">
            <h3>Safety Alert Composer</h3>
            <label>
              <span>Alert title</span>
              <input
                onChange={(event) => setAlertTitle(event.target.value)}
                value={alertTitle}
              />
            </label>
            <label>
              <span>Message</span>
              <textarea
                onChange={(event) => setMessage(event.target.value)}
                value={message}
              />
            </label>
            <div className="composer-chips">
              <span className="chip chip-blue">Barangay Lingga</span>
              <span className="chip chip-red">Flood risk</span>
              <span className="chip chip-green">Push + In-app</span>
            </div>
            <div className="composer-actions">
              <button className="panel-primary" onClick={publishAlert} type="button">
                Publish Now
              </button>
              <button className="panel-secondary" onClick={saveDraft} type="button">
                Save Draft
              </button>
            </div>
          </article>

          <article className="alerts-list-card">
            <h3>Active and Recent Alerts</h3>
            <div className="mini-table">
              <div className="mini-table-header">
                <span>Alert</span>
                <span>Area</span>
                <span>Status</span>
              </div>
              {filteredAlerts.map(([title, area, status], index) => (
                <div className="mini-table-row" key={`${title}-${index}`}>
                  <strong>{title}</strong>
                  <span>{area}</span>
                  <span>{status}</span>
                </div>
              ))}
            </div>

            <h4>Quick templates</h4>
            <div className="template-row">
              <button className="chip chip-button chip-red" onClick={() => setAlertTitle('Flood Watch')} type="button">
                Flood Watch
              </button>
              <button className="chip chip-button chip-blue" onClick={() => setAlertTitle('Rain Advisory')} type="button">
                Rain Advisory
              </button>
              <button className="chip chip-button chip-green" onClick={() => setAlertTitle('All Clear')} type="button">
                All Clear
              </button>
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
