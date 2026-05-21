import { useMemo, useState } from 'react'
import { doc, updateDoc } from 'firebase/firestore'
import { Search } from 'lucide-react'
import { db } from '../firebase'
import { useReports } from '../hooks/useReports'
import { useUsers } from '../hooks/useUsers'

export function UsersManagement({ onOpenVerification }) {
  const { users, error, status } = useUsers()
  const { calambaReports } = useReports()
  const [now] = useState(() => Date.now())
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedUserId, setSelectedUserId] = useState('')
  const [message, setMessage] = useState('')

  const reportCounts = useMemo(() => {
    const counts = new Map()
    calambaReports.forEach((report) => {
      if (report.userId) {
        counts.set(report.userId, (counts.get(report.userId) || 0) + 1)
      }
    })
    return counts
  }, [calambaReports])

  const visibleUsers = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase()
    if (!normalizedSearch) return users

    return users.filter((user) =>
      [
        user.displayName,
        user.email,
        user.authProvider,
        user.verificationStatus,
        user.role,
      ]
        .join(' ')
        .toLowerCase()
        .includes(normalizedSearch),
    )
  }, [searchTerm, users])

  const selectedUser =
    visibleUsers.find((user) => user.id === selectedUserId) ||
    visibleUsers[0] ||
    null

  const metrics = useMemo(() => {
    const verified = users.filter(
      (user) => user.verificationStatus === 'verified',
    ).length
    const admins = users.filter((user) => user.role === 'admin').length

    return {
      registered: users.length,
      verified,
      unverified: users.length - verified,
      admins,
    }
  }, [users])

  async function disableUser() {
    if (!selectedUser) return

    try {
      await updateDoc(doc(db, 'users', selectedUser.id), { disabled: true })
      setMessage(
        'User marked disabled in Firestore. To block login fully, add an admin cloud function or client-side access check.',
      )
    } catch (updateError) {
      setMessage(updateError.message)
    }
  }

  return (
    <div className="users-page">
      <header className="admin-topbar">
        <div>
          <h2>Users Management</h2>
          <p>Search residents, inspect verification state, and manage admin roles.</p>
        </div>

        <div className="topbar-actions">
          <label className="search-field">
            <Search aria-hidden="true" size={14} />
            <input
              aria-label="Search users"
              onChange={(event) => setSearchTerm(event.target.value)}
              placeholder="Search admin records"
              type="search"
              value={searchTerm}
            />
          </label>
          <button
            className="primary-action"
            onClick={() => setMessage('Create admin accounts in Firebase Auth, then set role: admin in Firestore.')}
            type="button"
          >
            Add Admin
          </button>
        </div>
      </header>

      <main className="users-content">
        <section className="metric-row users-metrics" aria-label="User metrics">
          <MetricCard accent="#1778d4" helper="Total users" label="Registered" value={metrics.registered} />
          <MetricCard accent="#28c59d" helper="Can report" label="Verified" value={metrics.verified} />
          <MetricCard accent="#e8b118" helper="Browse only" label="Unverified" value={metrics.unverified} />
          <MetricCard accent="#0b355e" helper="Role holders" label="Admins" value={metrics.admins} />
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
                <span>Reports</span>
                <span>Last Seen</span>
              </div>

              {visibleUsers.slice(0, 8).map((user) => (
                <button
                  className={`users-table users-table-row ${
                    selectedUser?.id === user.id ? 'is-selected' : ''
                  }`}
                  key={user.id}
                  onClick={() => setSelectedUserId(user.id)}
                  type="button"
                >
                  <strong>{user.displayName}</strong>
                  <span>{user.email || 'No email'}</span>
                  <span>{formatProvider(user.authProvider)}</span>
                  <span>{formatStatus(user.verificationStatus)}</span>
                  <span>{reportCounts.get(user.id) || 0}</span>
                  <span>{formatRelativeDate(user.lastLoginAt || user.updatedAt, now)}</span>
                </button>
              ))}

              {status === 'loading' ? (
                <p className="table-state">Loading resident accounts...</p>
              ) : null}
              {status === 'ready' && visibleUsers.length === 0 ? (
                <p className="table-state">No resident account matches the current data.</p>
              ) : null}
            </div>
          </article>

          <aside className="user-profile-panel">
            {selectedUser ? (
              <>
                <div className="user-profile-heading">
                  <span className="profile-avatar">
                    {selectedUser.photoUrl ? <img alt="" src={selectedUser.photoUrl} /> : null}
                  </span>
                  <div>
                    <h3>{selectedUser.displayName}</h3>
                    <p>{selectedUser.email || 'No email'}</p>
                  </div>
                </div>

                <span className={`chip ${statusChipClass(selectedUser.verificationStatus)}`}>
                  {formatStatus(selectedUser.verificationStatus)}
                </span>

                <div className="user-profile-copy">
                  <p>Auth provider: {formatProvider(selectedUser.authProvider)}</p>
                  <p>Reports: {reportCounts.get(selectedUser.id) || 0}</p>
                  <p>Last login: {formatRelativeDate(selectedUser.lastLoginAt || selectedUser.updatedAt, now)}</p>
                  <p>Created: {formatMonthYear(selectedUser.createdAt)}</p>
                  {selectedUser.disabled ? <p>Status: Disabled</p> : null}
                </div>

                <button
                  className="panel-primary"
                  onClick={onOpenVerification}
                  type="button"
                >
                  Open Verification
                </button>
                <button className="panel-danger" onClick={disableUser} type="button">
                  Disable User
                </button>
              </>
            ) : (
              <p className="table-state">Select a user to inspect account details.</p>
            )}
          </aside>
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

function formatRelativeDate(date, now) {
  if (!date) return 'Never'
  const days = Math.floor((now - date.getTime()) / 86400000)
  if (days <= 0) return 'Today'
  if (days === 1) return 'Yesterday'
  return `${days} days`
}

function formatMonthYear(date) {
  if (!date) return 'Unknown'
  return new Intl.DateTimeFormat('en-PH', {
    month: 'short',
    year: 'numeric',
  }).format(date)
}
