import { X } from 'lucide-react'

export function ConfirmActionModal({
  confirmLabel,
  intent = 'primary',
  message,
  onCancel,
  onConfirm,
  title,
}) {
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

        <div className="confirm-modal-actions">
          <button className="panel-secondary" onClick={onCancel} type="button">
            Cancel
          </button>
          <button
            className={intent === 'danger' ? 'panel-danger' : 'panel-primary'}
            onClick={onConfirm}
            type="button"
          >
            {confirmLabel}
          </button>
        </div>
      </section>
    </div>
  )
}
