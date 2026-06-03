import { useMemo, useState } from 'react'
import {
  AdminMiniTable,
  AdminMiniTableHeader,
  AdminMiniTableRow,
} from '../components/AdminMiniTable'
import { ConfirmActionModal } from '../components/ConfirmActionModal'
import { MetricCard } from '../components/MetricCard'
import { PageTopbar } from '../components/PageTopbar'
import { PrimaryActionButton } from '../components/PrimaryActionButton'
import { StatusChip } from '../components/StatusChip'
import { TableState } from '../components/TableState'
import { isAlertToday, useAlerts } from '../hooks/useAlerts'
import {
  createAlert,
  deleteAlert as removeAlert,
  resolveAlert as markAlertResolved,
} from '../services/alertActions'
import { formatAlertLabel } from '../utils/alerts'

const alertAreas = ['Lingga', 'Aplaya', 'Calamba', 'All residents']
const riskLevels = ['advisory', 'watch', 'warning', 'critical']

export function AlertsManagement() {
  const {
    alerts,
    error,
    hasMore,
    isLoadingMore,
    loadMore,
  } = useAlerts()
  const [alertTitle, setAlertTitle] = useState('Heavy rainfall near Lingga Creek')
  const [area, setArea] = useState('Lingga')
  const [message, setMessage] = useState(
    'Avoid low-lying roads near Lingga Creek. Monitor updates and submit reports only when safe.',
  )
  const [pendingDeleteAlert, setPendingDeleteAlert] = useState(null)
  const [pendingPublishStatus, setPendingPublishStatus] = useState('')
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

  function requestPublish(statusValue) {
    const cleanTitle = alertTitle.trim()
    const cleanMessage = message.trim()

    if (!cleanTitle || !cleanMessage) {
      setStatusMessage('Add an alert title and message first.')
      return
    }

    setPendingPublishStatus(statusValue)
  }

  async function saveAlert(statusValue = pendingPublishStatus) {
    const cleanTitle = alertTitle.trim()
    const cleanMessage = message.trim()

    if (!cleanTitle || !cleanMessage) {
      setStatusMessage('Add an alert title and message first.')
      return
    }

    try {
      const isPublished = statusValue === 'published'
      setPendingPublishStatus('')
      await createAlert({
        area,
        message: cleanMessage,
        riskLevel,
        status: statusValue,
        title: cleanTitle,
      })
      setStatusMessage(
        isPublished
          ? 'Alert published and push notification queued.'
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
      await markAlertResolved(alert.id)
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
      await removeAlert(alert.id)
      setStatusMessage('Alert deleted.')
    } catch (deleteError) {
      setStatusMessage(deleteError.message)
    }
  }

  return (
    <div className="alerts-page">
      <PageTopbar
        action={
          <PrimaryActionButton onClick={() => requestPublish('published')}>
            Publish Alert
          </PrimaryActionButton>
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
              <div className="risk-pick-group">
                <span>Risk level</span>
                <div className="risk-option-grid">
                  {riskLevels.map((level) => (
                    <button
                      className={`risk-option ${riskLevel === level ? 'is-active' : ''} ${riskChipClass(level)}`}
                      key={level}
                      onClick={() => setRiskLevel(level)}
                      type="button"
                    >
                      {formatAlertLabel(level)}
                    </button>
                  ))}
                </div>
              </div>
            </div>
            <div className="composer-chips">
              <StatusChip>{area}</StatusChip>
              <StatusChip tone={riskChipClass(riskLevel)}>
                {formatAlertLabel(riskLevel)}
              </StatusChip>
              <StatusChip tone="green">
                Push notification
              </StatusChip>
            </div>
            <div className="alert-preview-card">
              <div>
                <span>Mobile alert preview</span>
                <strong>{alertTitle || 'Untitled alert'}</strong>
                <p>{message || 'Alert message will appear here.'}</p>
              </div>
              <StatusChip tone={riskChipClass(riskLevel)}>
                {formatAlertLabel(riskLevel)}
              </StatusChip>
            </div>
            <div className="composer-actions">
              <button className="panel-primary" onClick={() => requestPublish('published')} type="button">
                Publish Now
              </button>
              <button className="panel-secondary" onClick={() => saveAlert('draft')} type="button">
                Save Draft
              </button>
            </div>
          </article>

          <article className="alerts-list-card">
            <h3>Current / Published Alerts</h3>
            <AdminMiniTable className="alerts-table">
              <AdminMiniTableHeader
                columns={['Alert', 'Area', 'Status', 'Action']}
              />
              {filteredAlerts.map((alert) => (
                <AdminMiniTableRow key={alert.id}>
                  <strong>{alert.title}</strong>
                  <span>{alert.area}</span>
                  <StatusChip size="mini" tone={statusChipClass(alert.status)}>
                    {formatAlertLabel(alert.status)}
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
                      <span>{formatAlertLabel(alert.source)}</span>
                    )}
                    <button
                      className="mini-link-button is-danger"
                      onClick={() => setPendingDeleteAlert(alert)}
                      type="button"
                    >
                      Delete
                    </button>
                  </span>
                </AdminMiniTableRow>
              ))}
              {filteredAlerts.length === 0 ? (
                <TableState>No alerts match the current view.</TableState>
              ) : null}
              {hasMore ? (
                <div className="table-load-more">
                  <button
                    className="panel-secondary"
                    disabled={isLoadingMore}
                    onClick={loadMore}
                    type="button"
                  >
                    {isLoadingMore ? 'Loading older alerts...' : 'Load more alerts'}
                  </button>
                </div>
              ) : null}
            </AdminMiniTable>

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
      {pendingPublishStatus === 'published' ? (
        <PublishAlertModal
          area={area}
          message={message}
          onCancel={() => setPendingPublishStatus('')}
          onConfirm={() => saveAlert('published')}
          riskLevel={riskLevel}
          title={alertTitle}
        />
      ) : null}
    </div>
  )
}

function PublishAlertModal({
  area,
  message,
  onCancel,
  onConfirm,
  riskLevel,
  title,
}) {
  return (
    <div
      aria-labelledby="publish-alert-title"
      aria-modal="true"
      className="confirm-modal-backdrop"
      onClick={onCancel}
      role="dialog"
    >
      <section
        className="confirm-modal publish-alert-modal"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="confirm-modal-header">
          <div>
            <p className="modal-eyebrow">Push notification</p>
            <h3 id="publish-alert-title">Publish this alert?</h3>
          </div>
          <button
            aria-label="Cancel publish"
            className="modal-close"
            onClick={onCancel}
            type="button"
          >
            X
          </button>
        </div>
        <div className="alert-confirm-preview">
          <div className="alert-confirm-row">
            <span>Target area</span>
            <strong>{area}</strong>
          </div>
          <div className="alert-confirm-row">
            <span>Risk level</span>
            <StatusChip tone={riskChipClass(riskLevel)}>
              {formatAlertLabel(riskLevel)}
            </StatusChip>
          </div>
          <div className="alert-confirm-message">
            <strong>{title}</strong>
            <p>{message}</p>
          </div>
        </div>
        <p className="confirm-modal-message">
          This will create a published alert. Your Cloud Function will use it for
          push notification delivery.
        </p>
        <div className="confirm-modal-actions">
          <button className="panel-secondary" onClick={onCancel} type="button">
            Cancel
          </button>
          <button className="panel-primary" onClick={onConfirm} type="button">
            Publish Alert
          </button>
        </div>
      </section>
    </div>
  )
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
