import { useMemo, useState } from 'react'
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore'
import { ConfirmActionModal } from '../components/ConfirmActionModal'
import { MetricCard } from '../components/MetricCard'
import { PageTopbar } from '../components/PageTopbar'
import { StatusChip } from '../components/StatusChip'
import { auth, db } from '../firebase'
import { isAlertToday, useAlerts } from '../hooks/useAlerts'

const alertAreas = ['Lingga', 'Aplaya', 'Calamba', 'All residents']
const riskLevels = ['info', 'watch', 'warning', 'critical']

export function AlertsManagement() {
  const { alerts, error } = useAlerts()
  const [alertTitle, setAlertTitle] = useState('Heavy rainfall near Lingga Creek')
  const [area, setArea] = useState('Lingga')
  const [message, setMessage] = useState(
    'Avoid low-lying roads near Lingga Creek. Monitor updates and submit reports only when safe.',
  )
  const [pendingDeleteAlert, setPendingDeleteAlert] = useState(null)
  const [pendingResolveAlert, setPendingResolveAlert] = useState(null)
  const [riskLevel, setRiskLevel] = useState('warning')
  const [searchTerm, setSearchTerm] = useState('')
  const [statusMessage, setStatusMessage] = useState('')

  const filteredAlerts = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase()
    if (!normalizedSearch) return alerts

    return alerts.filter((alert) =>
      [
        alert.title,
        alert.area,
        alert.riskLevel,
        alert.source,
        alert.status,
      ]
        .join(' ')
        .toLowerCase()
        .includes(normalizedSearch),
    )
  }, [alerts, searchTerm])

  const metrics = useMemo(
    () => ({
      active: alerts.filter((alert) => alert.status === 'published').length,
      drafts: alerts.filter((alert) => alert.status === 'draft').length,
      sentToday: alerts.filter(
        (alert) => alert.status === 'published' && isAlertToday(alert.publishedAt),
      ).length,
    }),
    [alerts],
  )

  async function saveAlert(statusValue) {
    const cleanTitle = alertTitle.trim()
    const cleanMessage = message.trim()

    if (!cleanTitle || !cleanMessage) {
      setStatusMessage('Add an alert title and message first.')
      return
    }

    try {
      const isPublished = statusValue === 'published'
      await addDoc(collection(db, 'alerts'), {
        area,
        created_at: serverTimestamp(),
        created_by: auth.currentUser?.uid || 'admin-dashboard',
        delivery: ['in_app', 'push'],
        message: cleanMessage,
        published_at: isPublished ? serverTimestamp() : null,
        resolved_at: null,
        risk_level: riskLevel,
        source: 'manual',
        status: statusValue,
        title: cleanTitle,
      })
      setStatusMessage(
        isPublished
          ? 'Alert published. Mobile users will see it in Notifications.'
          : 'Alert draft saved.',
      )
    } catch (saveError) {
      setStatusMessage(saveError.message)
    }
  }

  async function resolveAlert() {
    if (!pendingResolveAlert) return

    try {
      const alert = pendingResolveAlert
      setPendingResolveAlert(null)
      await updateDoc(doc(db, 'alerts', alert.id), {
        resolved_at: serverTimestamp(),
        status: 'resolved',
      })
      setStatusMessage('Alert marked as resolved.')
    } catch (resolveError) {
      setStatusMessage(resolveError.message)
    }
  }

  async function deleteAlert() {
    if (!pendingDeleteAlert) return

    try {
      const alert = pendingDeleteAlert
      setPendingDeleteAlert(null)
      await deleteDoc(doc(db, 'alerts', alert.id))
      setStatusMessage('Alert deleted.')
    } catch (deleteError) {
      setStatusMessage(deleteError.message)
    }
  }

  function applyTemplate(template) {
    if (template === 'flood') {
      setAlertTitle('Flood Watch')
      setMessage(
        'Flood-prone areas are being monitored. Avoid riverside and low-lying roads until conditions improve.',
      )
      setRiskLevel('warning')
      return
    }

    if (template === 'rain') {
      setAlertTitle('Rain Advisory')
      setMessage(
        'Rainfall is expected in the area. Monitor updates and prepare safety essentials.',
      )
      setRiskLevel('watch')
      return
    }

    setAlertTitle('All Clear')
    setMessage(
      'Flood risk has eased for the monitored area. Continue to stay alert for new advisories.',
    )
    setRiskLevel('info')
  }

  return (
    <div className="alerts-page">
      <PageTopbar
        action={
          <button
            className="primary-action"
            onClick={() => saveAlert('published')}
            type="button"
          >
            Publish Alert
          </button>
        }
        description="Create safety advisories and manage active/resolved alert messages."
        search={{
          ariaLabel: 'Search alert records',
          onChange: setSearchTerm,
          value: searchTerm,
        }}
        title="Alerts Management"
      />

      <main className="alerts-content">
        <section className="metric-row review-metrics" aria-label="Alert metrics">
          <MetricCard accent="#1778d4" helper="Published" label="Active alerts" value={metrics.active} />
          <MetricCard accent="#e8b118" helper="Awaiting review" label="Drafts" value={metrics.drafts} />
          <MetricCard accent="#28c59d" helper="Published today" label="Sent today" value={metrics.sentToday} />
        </section>

        {error || statusMessage ? (
          <p className={error ? 'error-banner' : 'success-banner'}>
            {error || statusMessage}
          </p>
        ) : null}

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
            <div className="composer-select-grid">
              <label>
                <span>Target area</span>
                <select onChange={(event) => setArea(event.target.value)} value={area}>
                  {alertAreas.map((option) => (
                    <option key={option} value={option}>
                      {option}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                <span>Risk level</span>
                <select
                  onChange={(event) => setRiskLevel(event.target.value)}
                  value={riskLevel}
                >
                  {riskLevels.map((level) => (
                    <option key={level} value={level}>
                      {formatLabel(level)}
                    </option>
                  ))}
                </select>
              </label>
            </div>
            <div className="composer-chips">
              <StatusChip>{area}</StatusChip>
              <StatusChip tone={riskChipClass(riskLevel)}>
                {formatLabel(riskLevel)}
              </StatusChip>
              <StatusChip tone="green">
                Push notification
              </StatusChip>
            </div>
            <div className="composer-actions">
              <button className="panel-primary" onClick={() => saveAlert('published')} type="button">
                Publish Now
              </button>
              <button className="panel-secondary" onClick={() => saveAlert('draft')} type="button">
                Save Draft
              </button>
            </div>
          </article>

          <article className="alerts-list-card">
            <h3>Current / Published Alerts</h3>
            <div className="mini-table alerts-table">
              <div className="mini-table-header">
                <span>Alert</span>
                <span>Area</span>
                <span>Status</span>
                <span>Action</span>
              </div>
              {filteredAlerts.slice(0, 8).map((alert) => (
                <div className="mini-table-row" key={alert.id}>
                  <strong>{alert.title}</strong>
                  <span>{alert.area}</span>
                  <StatusChip size="mini" tone={statusChipClass(alert.status)}>
                    {formatLabel(alert.status)}
                  </StatusChip>
                  <span className="alert-row-actions">
                    {alert.status === 'published' ? (
                      <button
                        className="mini-link-button"
                        onClick={() => setPendingResolveAlert(alert)}
                        type="button"
                      >
                        Resolve
                      </button>
                    ) : (
                      <span>{formatLabel(alert.source)}</span>
                    )}
                    <button
                      className="mini-link-button is-danger"
                      onClick={() => setPendingDeleteAlert(alert)}
                      type="button"
                    >
                      Delete
                    </button>
                  </span>
                </div>
              ))}
              {filteredAlerts.length === 0 ? (
                <p className="table-state">No alerts match the current view.</p>
              ) : null}
            </div>

            <h4>Quick templates</h4>
            <div className="template-row">
              <button className="chip chip-button chip-red" onClick={() => applyTemplate('flood')} type="button">
                Flood Watch
              </button>
              <button className="chip chip-button chip-blue" onClick={() => applyTemplate('rain')} type="button">
                Rain Advisory
              </button>
              <button className="chip chip-button chip-green" onClick={() => applyTemplate('clear')} type="button">
                All Clear
              </button>
            </div>
          </article>
        </section>
      </main>

      {pendingResolveAlert ? (
        <ConfirmActionModal
          confirmLabel="Resolve alert"
          intent="primary"
          message="This moves the published alert out of the active alerts list and records it as resolved."
          onCancel={() => setPendingResolveAlert(null)}
          onConfirm={resolveAlert}
          title="Resolve this alert?"
        />
      ) : null}
      {pendingDeleteAlert ? (
        <ConfirmActionModal
          confirmLabel="Delete alert"
          intent="danger"
          message="This permanently removes the alert record from Firestore. Published alerts will disappear from the mobile app."
          onCancel={() => setPendingDeleteAlert(null)}
          onConfirm={deleteAlert}
          title="Delete this alert?"
        />
      ) : null}
    </div>
  )
}

function formatLabel(value) {
  return value.charAt(0).toUpperCase() + value.slice(1).replaceAll('_', ' ')
}

function riskChipClass(riskLevel) {
  if (riskLevel === 'critical' || riskLevel === 'warning') return 'chip-red'
  if (riskLevel === 'watch') return 'chip-amber'
  return 'chip-blue'
}

function statusChipClass(status) {
  if (status === 'published') return 'chip-green'
  if (status === 'resolved') return 'chip-blue'
  if (status === 'draft') return 'chip-amber'
  return 'chip-blue'
}
