import { useMemo, useState } from 'react'
import { ConfirmActionModal } from '../components/ConfirmActionModal'
import { MetricCard } from '../components/MetricCard'
import { PageTopbar } from '../components/PageTopbar'
import { StatusChip } from '../components/StatusChip'
import { useUsers } from '../hooks/useUsers'
import {
  approveVerification,
  rejectVerification,
  requestNewVerificationPhoto,
} from '../services/userActions'

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
  const [pendingReviewAction, setPendingReviewAction] = useState(null)
  const [rejectReason, setRejectReason] = useState('')

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

  function requestReviewAction(action) {
    if (!selectedApplicant) {
      setMessage('Select a submitted verification request first.')
      return
    }

    setPendingReviewAction({ ...action, applicant: selectedApplicant })
  }

  async function confirmReviewAction() {
    if (!pendingReviewAction) return
    const { action, applicant, successMessage } = pendingReviewAction

    try {
      setPendingReviewAction(null)
      await action(applicant.id)
      setMessage(successMessage)
    } catch (updateError) {
      setMessage(updateError.message)
    }
  }

  async function confirmReject() {
    if (!pendingReviewAction) return
    const reason = rejectReason.trim()

    if (!reason) {
      setMessage('Add a short reason before rejecting the verification.')
      return
    }

    try {
      const { applicant } = pendingReviewAction
      setPendingReviewAction(null)
      setRejectReason('')
      await rejectVerification(applicant.id, reason)
      setMessage('Verification rejected with a saved reason.')
    } catch (updateError) {
      setMessage(updateError.message)
    }
  }

  return (
    <div className="verification-page">
      <PageTopbar
        action={
          <button
            className="primary-action"
            disabled={applicants.length === 0}
            onClick={() => setSelectedId(applicants[0]?.id || '')}
            type="button"
          >
            Review Oldest
          </button>
        }
        description="Approve valid IDs so trusted users can submit safety reports."
        search={{
          ariaLabel: 'Search verification records',
          onChange: setSearchTerm,
          value: searchTerm,
        }}
        title="Verification Review"
      />

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
                  <div>
                    <h3>{selectedApplicant.displayName}</h3>
                    <p>{selectedApplicant.email || 'No email recorded'}</p>
                  </div>
                  <StatusChip tone={statusChipClass(selectedApplicant.verificationStatus)}>
                    {formatStatus(selectedApplicant.verificationStatus)}
                  </StatusChip>
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
                      requestReviewAction({
                        action: approveVerification,
                        confirmLabel: 'Approve ID',
                        message:
                          'This marks the resident as verified. They can submit community reports after approval.',
                        successMessage: 'Verification approved.',
                        title: 'Approve this verification?',
                      })
                    }
                    type="button"
                  >
                    Approve Verification
                  </button>
                  <button
                    className="panel-danger"
                    onClick={() => {
                      setRejectReason('')
                      requestReviewAction({
                        action: 'reject',
                        confirmLabel: 'Reject ID',
                        message:
                          'Save a short reason so the resident knows what to correct.',
                        successMessage: 'Verification rejected.',
                        title: 'Reject this verification?',
                      })
                    }}
                    type="button"
                  >
                    Reject With Reason
                  </button>
                  <button
                    className="panel-secondary"
                    onClick={() =>
                      requestReviewAction({
                        action: requestNewVerificationPhoto,
                        confirmLabel: 'Request photo',
                        message:
                          'This asks the resident to upload a clearer valid ID photo before approval.',
                        successMessage: 'New photo requested.',
                        title: 'Ask for a new photo?',
                      })
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
      {pendingReviewAction?.action === 'reject' ? (
        <RejectReasonModal
          onCancel={() => {
            setPendingReviewAction(null)
            setRejectReason('')
          }}
          onChange={setRejectReason}
          onConfirm={confirmReject}
          reason={rejectReason}
        />
      ) : null}
      {pendingReviewAction && pendingReviewAction.action !== 'reject' ? (
        <ConfirmActionModal
          confirmLabel={pendingReviewAction.confirmLabel}
          message={pendingReviewAction.message}
          onCancel={() => setPendingReviewAction(null)}
          onConfirm={confirmReviewAction}
          title={pendingReviewAction.title}
        />
      ) : null}
    </div>
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

function RejectReasonModal({ onCancel, onChange, onConfirm, reason }) {
  return (
    <div
      aria-labelledby="reject-verification-title"
      aria-modal="true"
      className="confirm-modal-backdrop"
      onClick={onCancel}
      role="dialog"
    >
      <section
        className="confirm-modal reject-reason-modal"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="confirm-modal-header">
          <div>
            <p className="modal-eyebrow">Verification decision</p>
            <h3 id="reject-verification-title">Reject this ID?</h3>
          </div>
          <button
            aria-label="Cancel rejection"
            className="modal-close"
            onClick={onCancel}
            type="button"
          >
            X
          </button>
        </div>
        <label className="reject-reason-field">
          <span>Reason</span>
          <textarea
            onChange={(event) => onChange(event.target.value)}
            placeholder="Example: ID photo is blurry or incomplete."
            value={reason}
          />
        </label>
        <div className="confirm-modal-actions">
          <button className="panel-secondary" onClick={onCancel} type="button">
            Cancel
          </button>
          <button className="panel-danger" onClick={onConfirm} type="button">
            Reject ID
          </button>
        </div>
      </section>
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
