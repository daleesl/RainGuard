import { useMemo, useState } from 'react'
import { doc, updateDoc } from 'firebase/firestore'
import { Search } from 'lucide-react'
import { db } from '../firebase'
import { useUsers } from '../hooks/useUsers'

const checklist = [
  ['Name is readable', 'Review ID photo'],
  ['ID is valid type', 'Review ID photo'],
  ['Photo is not blurry', 'Review ID photo'],
  ['Address match', 'Not required'],
]

export function VerificationReview() {
  const { users, pendingUsers, status, error } = useUsers()
  const [selectedId, setSelectedId] = useState('')
  const [searchTerm, setSearchTerm] = useState('')
  const [message, setMessage] = useState('')

  const applicants = useMemo(() => {
    const reviewableUsers = pendingUsers.filter(
      (user) =>
        user.verificationStatus !== 'unverified' ||
        user.verificationIdFrontUrl,
    )
    const normalizedSearch = searchTerm.trim().toLowerCase()
    if (!normalizedSearch) return reviewableUsers

    return reviewableUsers.filter((applicant) =>
      [applicant.displayName, applicant.email, applicant.verificationStatus]
        .join(' ')
        .toLowerCase()
        .includes(normalizedSearch),
    )
  }, [pendingUsers, searchTerm])

  const selectedApplicant =
    applicants.find((applicant) => applicant.id === selectedId) ||
    applicants[0] ||
    null

  const stats = {
    pending: pendingUsers.length,
    verified: users.filter((user) => user.verificationStatus === 'verified')
      .length,
    rejected: users.filter((user) => user.verificationStatus === 'rejected')
      .length,
  }

  async function updateVerification(statusValue, successMessage) {
    if (!selectedApplicant) {
      setMessage('Select a submitted verification request first.')
      return
    }

    try {
      await updateDoc(doc(db, 'users', selectedApplicant.id), {
        verification_status: statusValue,
      })
      setMessage(successMessage)
    } catch (updateError) {
      setMessage(updateError.message)
    }
  }

  return (
    <div className="verification-page">
      <header className="admin-topbar">
        <div>
          <h2>Verification Review</h2>
          <p>Approve valid IDs so trusted users can submit safety reports.</p>
        </div>
        <div className="topbar-actions">
          <label className="search-field">
            <Search aria-hidden="true" size={14} />
            <input
              aria-label="Search verification records"
              onChange={(event) => setSearchTerm(event.target.value)}
              placeholder="Search admin records"
              type="search"
              value={searchTerm}
            />
          </label>
          <button
            className="primary-action"
            disabled={applicants.length === 0}
            onClick={() => setSelectedId(applicants[0]?.id || '')}
            type="button"
          >
            Review Oldest
          </button>
        </div>
      </header>

      <main className="review-content">
        <section className="metric-row review-metrics" aria-label="Verification metrics">
          <MetricCard accent="#e8b118" helper="Awaiting review" label="Pending IDs" value={stats.pending} />
          <MetricCard accent="#28c59d" helper="Total" label="Verified users" value={stats.verified} />
          <MetricCard accent="#e24d4d" helper="Total" label="Rejected" value={stats.rejected} />
        </section>

        {error || message ? (
          <p className={error ? 'error-banner' : 'success-banner'}>
            {error || message}
          </p>
        ) : null}

        <section className="verification-grid">
          <article className="verification-list-card">
            <h3>Pending Applicants</h3>
            <div className="applicant-list">
              {status === 'loading' ? <p className="table-state">Loading applicants...</p> : null}
              {status === 'ready' && applicants.length === 0 ? (
                <p className="table-state">
                  No submitted ID verification requests yet.
                </p>
              ) : null}
              {applicants.map((applicant) => (
                <button
                  className={`applicant-card ${
                    selectedApplicant?.id === applicant.id ? 'is-selected' : ''
                  }`}
                  key={applicant.id}
                  onClick={() => setSelectedId(applicant.id)}
                  style={{ '--applicant-accent': applicant.accent || '#e8b118' }}
                  type="button"
                >
                  <span className="applicant-avatar">
                    {applicant.photoUrl ? <img alt="" src={applicant.photoUrl} /> : null}
                  </span>
                  <span>
                    <strong>{applicant.displayName}</strong>
                    <small>{applicant.email || formatStatus(applicant.verificationStatus)}</small>
                  </span>
                </button>
              ))}
            </div>
          </article>

          <article className="document-review-card">
            {selectedApplicant ? (
              <>
                <div className="document-title">
                  <h3>{selectedApplicant.displayName}</h3>
                  <span className={`chip ${statusChipClass(selectedApplicant.verificationStatus)}`}>
                    {formatStatus(selectedApplicant.verificationStatus)}
                  </span>
                </div>

                <div className="document-previews">
                  <DocumentPreview
                    imageUrl={selectedApplicant.verificationIdFrontUrl}
                    label="ID document front"
                  />
                </div>

                <h4>Review checklist</h4>
                <div className="review-table">
                  <div className="review-table-header">
                    <span>Check</span>
                    <span>Status</span>
                  </div>
                  {checklist.map(([label, value]) => (
                    <div className="review-table-row" key={label}>
                      <strong>{label}</strong>
                      <span>{value}</span>
                    </div>
                  ))}
                </div>

                <div className="review-actions">
                  <button
                    className="panel-primary"
                    onClick={() =>
                      updateVerification('verified', 'Verification approved.')
                    }
                    type="button"
                  >
                    Approve Verification
                  </button>
                  <button
                    className="panel-danger"
                    onClick={() =>
                      updateVerification('rejected', 'Verification rejected.')
                    }
                    type="button"
                  >
                    Reject With Reason
                  </button>
                  <button
                    className="panel-secondary"
                    onClick={() =>
                      updateVerification('pending', 'New photo requested.')
                    }
                    type="button"
                  >
                    Ask for New Photo
                  </button>
                </div>
              </>
            ) : (
              <p className="table-state">
                Select a submitted verification request to review the uploaded ID.
              </p>
            )}
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

function DocumentPreview({ imageUrl, label }) {
  const [failed, setFailed] = useState(false)

  return (
    <div className={`document-preview ${imageUrl ? 'has-image' : ''}`}>
      {imageUrl ? (
        <a href={imageUrl} rel="noreferrer" target="_blank">
          {failed ? (
            <strong>Image link available. Click to open.</strong>
          ) : (
            <img alt={label} onError={() => setFailed(true)} src={imageUrl} />
          )}
          <span>{failed ? 'Open ID image' : 'Open image'}</span>
        </a>
      ) : (
        <span>No {label.toLowerCase()} uploaded yet.</span>
      )}
    </div>
  )
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
