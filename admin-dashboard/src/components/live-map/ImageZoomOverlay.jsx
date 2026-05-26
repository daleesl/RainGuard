import { X } from 'lucide-react'

export function ImageZoomOverlay({ imageUrl, onClose }) {
  return (
    <div
      aria-label="Zoomed report photo"
      aria-modal="true"
      className="image-zoom-backdrop"
      onClick={onClose}
      role="dialog"
    >
      <button
        aria-label="Close zoomed image"
        className="modal-close image-zoom-close"
        onClick={onClose}
        type="button"
      >
        <X aria-hidden="true" size={18} />
      </button>
      <img alt="Zoomed report evidence" onClick={(event) => event.stopPropagation()} src={imageUrl} />
    </div>
  )
}
