import { useState } from 'react'
import { X } from 'lucide-react'

export function ConfirmActionModal({
  confirmLabel,
  intent = 'primary',
  message,
  onCancel,
  onConfirm,
  reasonLabel = 'Reason',
  reasonPlaceholder = 'Add a short reason...',
  requiresReason = false,
  title,
}) {
  const [reason, setReason] = useState('')
  const trimmedReason = reason.trim()
  const canConfirm = !requiresReason || trimmedReason.length > 0

  function handleConfirm() {
    if (!canConfirm) return
    onConfirm(trimmedReason)
  }

  return (
    <div
      aria-labelledby="confirm-action-title"
      aria-modal="true"
      className="confirm-modal-backdrop"
      onClick={onCancel}
      role="dialog"
    >
      <section
        className="confirm-modal"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="confirm-modal-header">
          <div>
            <p className="modal-eyebrow">Confirm action</p>
            <h3 id="confirm-action-title">{title}</h3>
          </div>
          <button
            aria-label="Cancel action"
            className="modal-close"
            onClick={onCancel}
            type="button"
          >
            <X aria-hidden="true" size={18} />
          </button>
        </div>

        <p className="confirm-modal-message">{message}</p>

        {requiresReason ? (
          <label className="confirm-reason-field">
            <span>{reasonLabel}</span>
            <textarea
              onChange={(event) => setReason(event.target.value)}
              placeholder={reasonPlaceholder}
              rows={4}
              value={reason}
            />
          </label>
        ) : null}

        <div className="confirm-modal-actions">
          <button className="panel-secondary" onClick={onCancel} type="button">
            Cancel
          </button>
          <button
            className={intent === 'danger' ? 'panel-danger' : 'panel-primary'}
            disabled={!canConfirm}
            onClick={handleConfirm}
            type="button"
          >
            {confirmLabel}
          </button>
        </div>
      </section>
    </div>
  )
}
