import { ImageOff } from 'lucide-react'

export function ReportImageCarousel({
  imageIndex,
  onImageIndexChange,
  onZoomImage,
  report,
}) {
  const images = report.imageUrls.length > 0 ? report.imageUrls : []
  const safeIndex = Math.min(imageIndex, Math.max(images.length - 1, 0))
  const currentImage = images[safeIndex]

  function goToImage(direction) {
    if (images.length <= 1) return
    const nextIndex = (safeIndex + direction + images.length) % images.length
    onImageIndexChange(nextIndex)
  }

  return (
    <div className="report-image-carousel">
      <button
        aria-label={
          currentImage ? 'Zoom selected report photo' : 'No report photo attached'
        }
        className="report-image-main"
        disabled={!currentImage}
        onClick={() => currentImage && onZoomImage(currentImage)}
        type="button"
      >
        {currentImage ? (
          <img alt="Submitted report evidence" src={currentImage} />
        ) : (
          <span className="report-modal-empty-image">
            <ImageOff aria-hidden="true" size={24} />
            <span>No photo attached</span>
          </span>
        )}
      </button>

      {images.length > 1 ? (
        <div className="report-image-controls">
          <button onClick={() => goToImage(-1)} type="button">
            Prev
          </button>
          <span>
            {safeIndex + 1} / {images.length}
          </span>
          <button onClick={() => goToImage(1)} type="button">
            Next
          </button>
        </div>
      ) : null}
    </div>
  )
}
