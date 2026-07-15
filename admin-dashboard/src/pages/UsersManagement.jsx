import { useMemo, useState } from 'react'
import { Ban, IdCard, ImageOff, RotateCcw, ShieldAlert, X } from 'lucide-react'
import { AdminActionButton, AdminActionGroup } from '../components/AdminActionButton'
import { ConfirmActionModal } from '../components/ConfirmActionModal'
import { MetricCard } from '../components/MetricCard'
import { PageTopbar } from '../components/PageTopbar'
import { PrimaryActionButton } from '../components/PrimaryActionButton'
import { StatusChip } from '../components/StatusChip'
import { TableState } from '../components/TableState'
import { useReports } from '../hooks/useReports'
import { useUsers } from '../hooks/useUsers'
import {
  disableUser,
  restoreUser,
  suspendUser,
} from '../services/userActions'

export function UsersManagement({ onOpenVerification }) {
  const {
    users,
    error,
    status,
    hasMore,
    isLoadingMore,
    loadMore,
  } = useUsers()
  const { localReports } = useReports()
  const [now] = useState(() => Date.now())
  const [searchTerm, setSearchTerm] = useState('')
  const [message, setMessage] = useState('')
  const [pendingAction, setPendingAction] = useState(null)
  const [idPreviewUser, setIdPreviewUser] = useState(null)

  const reportCounts = useMemo(() => {
    const counts = new Map()
    localReports.forEach((report) => {
      if (report.userId) {
        counts.set(report.userId, (counts.get(report.userId) || 0) + 1)
      }
    })
    return counts
  }, [localReports])

  const residentUsers = useMemo(
    () => users.filter((user) => user.role !== 'admin'),
    [users],
  )

  const visibleUsers = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase()
    if (!normalizedSearch) return residentUsers

    return residentUsers.filter((user) =>
      [
        user.displayName,
        user.email,
        user.authProvider,
        user.verificationStatus,
        user.accountStatus,
      ]
        .join(' ')
        .toLowerCase()
        .includes(normalizedSearch),
    )
  }, [residentUsers, searchTerm])

  const metrics = useMemo(() => {
    const verified = residentUsers.filter(
      (user) => user.verificationStatus === 'verified',
    ).length

    return {
      registered: residentUsers.length,
      verified,
      unverified: residentUsers.length - verified,
      withId: residentUsers.filter((user) => user.verificationIdFrontUrl).length,
    }
  }, [residentUsers])

  function requestUserAction(user, action) {
    setPendingAction({ ...action, user })
  }

  async function confirmUserAction() {
    if (!pendingAction) return
    const { action, successMessage, user } = pendingAction

    try {
      setPendingAction(null)
      await action(user.id)
      setMessage(successMessage)
    } catch (updateError) {
      setMessage(updateError.message)
    }
  }

  return (
    <div className="users-page">
      <PageTopbar
        action={
          <PrimaryActionButton
            onClick={() => setMessage('Create admin accounts in Firebase Auth, then set role: admin in Firestore.')}
          >
            Add Admin
          </PrimaryActionButton>
        }
        description="Search residents, inspect verification state, and manage account access."
        search={{
          ariaLabel: 'Search users',
          onChange: setSearchTerm,
          value: searchTerm,
        }}
        title="Users Management"
      />

      <main className="users-content">
        <section className="metric-row users-metrics" aria-label="User metrics">
          <MetricCard accent="#1778d4" helper="Total users" label="Registered" value={metrics.registered} />
          <MetricCard accent="#28c59d" helper="Can report" label="Verified" value={metrics.verified} />
          <MetricCard accent="#e8b118" helper="Browse only" label="Unverified" value={metrics.unverified} />
          <MetricCard accent="#0b355e" helper="Uploaded ID" label="With ID" value={metrics.withId} />
        </section>

        {error || message ? (
          <p className={error ? 'error-banner' : 'success-banner'}>
            {error || message}
          </p>
        ) : null}

        <section className="users-grid">
          <article className="users-table-card">
            <h3>Resident Accounts</h3>
            <div className="users-table-wrap">
              <div className="users-table users-table-header">
                <span>Name</span>
                <span>Email</span>
                <span>Provider</span>
                <span>Verify</span>
                <span>Account</span>
                <span>Reports</span>
                <span>Last Seen</span>
                <span>Actions</span>
              </div>

              {visibleUsers.map((user) => (
                <div
                  className="users-table users-table-row"
                  key={user.id}
                >
                  <strong>{user.displayName}</strong>
                  <span>{user.email || 'No email'}</span>
                  <span>{formatProvider(user.authProvider)}</span>
                  <StatusChip size="mini" tone={statusChipClass(user.verificationStatus)}>
                    {formatStatus(user.verificationStatus)}
                  </StatusChip>
                  <StatusChip size="mini" tone={accountChipClass(user)}>
                    {formatAccountStatus(user)}
                  </StatusChip>
                  <span>{reportCounts.get(user.id) || 0}</span>
                  <span>{formatRelativeDate(user.lastLoginAt || user.updatedAt, now)}</span>
                  <UserActions
                    onOpenVerification={onOpenVerification}
                    onRequestAction={requestUserAction}
                    onViewId={setIdPreviewUser}
                    user={user}
                  />
                </div>
              ))}

              {status === 'loading' ? (
                <TableState>Loading resident accounts...</TableState>
              ) : null}
              {status === 'ready' && visibleUsers.length === 0 ? (
                <TableState>No resident account matches the current data.</TableState>
              ) : null}
              {hasMore ? (
                <div className="table-load-more">
                  <button
                    className="panel-secondary"
                    disabled={isLoadingMore}
                    onClick={loadMore}
                    type="button"
                  >
                    {isLoadingMore ? 'Loading older users...' : 'Load more users'}
                  </button>
                </div>
              ) : null}
            </div>
          </article>
        </section>
      </main>

      {pendingAction ? (
        <ConfirmActionModal
          confirmLabel={pendingAction.confirmLabel}
          intent={pendingAction.intent}
          message={pendingAction.message}
          onCancel={() => setPendingAction(null)}
          onConfirm={confirmUserAction}
          title={pendingAction.title}
        />
      ) : null}
      {idPreviewUser ? (
        <UserIdPreviewModal
          onClose={() => setIdPreviewUser(null)}
          onOpenVerification={() => {
            setIdPreviewUser(null)
            onOpenVerification()
          }}
          user={idPreviewUser}
        />
      ) : null}
    </div>
  )
}

function UserActions({ onOpenVerification, onRequestAction, onViewId, user }) {
  const accountStatus = getAccountStatus(user)
  const needsVerification = user.verificationStatus !== 'verified'
  const hasIdPhoto = Boolean(user.verificationIdFrontUrl)

  return (
    <AdminActionGroup className="w-[min(100%,252px)] flex-nowrap gap-[5px]">
      {hasIdPhoto ? (
        <AdminActionButton
          icon={IdCard}
          onClick={() => onViewId(user)}
          title="View submitted ID"
          tone="ghost"
        >
          View ID
        </AdminActionButton>
      ) : null}

      {needsVerification ? (
        <AdminActionButton
          icon={ShieldAlert}
          onClick={onOpenVerification}
          title="Open Verification Review"
          tone="ghost"
        >
          Review ID
        </AdminActionButton>
      ) : null}

      {accountStatus === 'active' ? (
        <>
          <AdminActionButton
            icon={Ban}
            onClick={() =>
              onRequestAction(user, {
                confirmLabel: 'Suspend account',
                intent: 'primary',
                message:
                  'This marks the resident account as suspended in Firestore. Add client or rules enforcement before relying on it as a hard block.',
                successMessage: 'User account marked as suspended.',
                title: 'Suspend this account?',
                action: suspendUser,
              })
            }
            title="Suspend account"
            tone="resolve"
          >
            Suspend
          </AdminActionButton>
          <AdminActionButton
            icon={Ban}
            onClick={() =>
              onRequestAction(user, {
                confirmLabel: 'Disable account',
                intent: 'danger',
                message:
                  'This marks the account as disabled in Firestore. To fully block Firebase Auth login, connect this to a Cloud Function or enforce the field in the app.',
                successMessage: 'User account marked as disabled.',
                title: 'Disable this account?',
                action: disableUser,
              })
            }
            title="Disable account"
            tone="danger"
          >
            Disable
          </AdminActionButton>
        </>
      ) : (
        <AdminActionButton
          icon={RotateCcw}
          onClick={() =>
            onRequestAction(user, {
              confirmLabel: 'Restore account',
              intent: 'primary',
              message:
                'This returns the resident account to active status in Firestore.',
              successMessage: 'User account restored to active.',
              title: 'Restore this account?',
              action: restoreUser,
            })
          }
          title="Restore account"
          tone="verify"
        >
          Restore
        </AdminActionButton>
      )}
    </AdminActionGroup>
  )
}

function UserIdPreviewModal({ onClose, onOpenVerification, user }) {
  return (
    <div
      aria-labelledby="user-id-preview-title"
      aria-modal="true"
      className="report-modal-backdrop"
      onClick={onClose}
      role="dialog"
    >
      <section
        className="report-modal report-modal-simple user-id-preview-modal"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="simple-modal-header">
          <div>
            <p className="modal-eyebrow">Resident identity record</p>
            <h3 id="user-id-preview-title">{user.displayName}</h3>
          </div>
          <button
            aria-label="Close ID preview"
            className="modal-close"
            onClick={onClose}
            type="button"
          >
            <X aria-hidden="true" size={18} />
          </button>
        </div>

        <div className="simple-modal-content">
          <div className="simple-chip-row">
            <StatusChip tone={statusChipClass(user.verificationStatus)}>
              {formatStatus(user.verificationStatus)}
            </StatusChip>
            <StatusChip tone={accountChipClass(user)}>
              {formatAccountStatus(user)}
            </StatusChip>
          </div>

          <div className="user-id-preview-image">
            {user.verificationIdFrontUrl ? (
              <a
                href={user.verificationIdFrontUrl}
                rel="noreferrer"
                target="_blank"
              >
                <img
                  alt={`${user.displayName} submitted ID`}
                  src={user.verificationIdFrontUrl}
                />
                <span>Open image</span>
              </a>
            ) : (
              <span className="report-modal-empty-image">
                <ImageOff aria-hidden="true" size={24} />
                <span>No ID image uploaded</span>
              </span>
            )}
          </div>

          <div className="simple-meta-list">
            <InfoItem label="Email" value={user.email || 'No email'} />
            <InfoItem label="Provider" value={formatProvider(user.authProvider)} />
            <InfoItem
              label="Submitted"
              value={formatFullDate(user.verificationSubmittedAt)}
            />
            <InfoItem label="Created" value={formatFullDate(user.createdAt)} />
          </div>

          <div className="simple-modal-actions">
            <button className="panel-primary" onClick={onOpenVerification} type="button">
              Open Verification Review
            </button>
            <button className="panel-secondary" onClick={onClose} type="button">
              Close
            </button>
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

function formatProvider(provider) {
  if (!provider) return 'Email'
  return provider.charAt(0).toUpperCase() + provider.slice(1)
}

function formatStatus(status) {
  if (!status) return 'Unverified'
  return status.charAt(0).toUpperCase() + status.slice(1).replaceAll('_', ' ')
}

function statusChipClass(status) {
  if (status === 'verified') return 'chip-green'
  if (status === 'rejected') return 'chip-red'
  if (status === 'pending') return 'chip-amber'
  return 'chip-blue'
}

function getAccountStatus(user) {
  if (user.disabled) return 'disabled'
  return user.accountStatus || 'active'
}

function formatAccountStatus(user) {
  return formatStatus(getAccountStatus(user))
}

function accountChipClass(user) {
  const accountStatus = getAccountStatus(user)
  if (accountStatus === 'active') return 'chip-green'
  if (accountStatus === 'suspended') return 'chip-amber'
  if (accountStatus === 'disabled') return 'chip-red'
  return 'chip-blue'
}

function formatRelativeDate(date, now) {
  if (!date) return 'Never'
  const days = Math.floor((now - date.getTime()) / 86400000)
  if (days <= 0) return 'Today'
  if (days === 1) return 'Yesterday'
  return `${days} days`
}

function formatFullDate(date) {
  if (!date) return 'Not recorded'
  return new Intl.DateTimeFormat('en-PH', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(date)
}
