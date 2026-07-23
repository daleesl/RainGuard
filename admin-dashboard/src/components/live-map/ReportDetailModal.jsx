import { X } from 'lucide-react'
import {
  getReportLabel,
  getReportLocationName,
  getReportObservationLabel,
  getReportObservationValue,
  getReportTypeName,
  getReviewStatus,
} from '../../utils/reports'
import { StatusChip } from '../StatusChip'
import { ReportImageCarousel } from './ReportImageCarousel'
import { formatReportDateTime } from './reportFormat'
import { ReportInfoItem } from './ReportInfoItem'

export function ReportDetailModal({
  imageIndex,
  onClose,
  onImageIndexChange,
  onZoomImage,
  report,
}) {
  return (
    <div
      aria-labelledby="report-modal-title"
      aria-modal="true"
      className="report-modal-backdrop"
      onClick={onClose}
      role="dialog"
    >
      <section
        className="report-modal report-modal-simple"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="simple-modal-header">
          <div>
            <p className="modal-eyebrow">Community report</p>
            <h3 id="report-modal-title">{getReportLabel(report)}</h3>
          </div>
          <button
            aria-label="Close report details"
            className="modal-close"
            onClick={onClose}
            type="button"
          >
            <X aria-hidden="true" size={18} />
          </button>
        </div>

        <div className="simple-modal-content">
          <ReportImageCarousel
            imageIndex={imageIndex}
            onImageIndexChange={onImageIndexChange}
            onZoomImage={onZoomImage}
            report={report}
          />

          <div className="simple-modal-details">
            <div className="simple-chip-row">
              <StatusChip>{getReportTypeName(report)}</StatusChip>
            </div>

            <div className="simple-report-title">
              <span>Location</span>
              <strong>{getReportLocationName(report)}</strong>
            </div>

            <p className="simple-description">
              {report.description || 'No description was provided for this report.'}
            </p>

            <div className="simple-meta-list">
              <ReportInfoItem label="Reporter" value={report.reporterName || 'Anonymous'} />
              <ReportInfoItem
                label="Created"
                value={formatReportDateTime(report.createdAt)}
                stacked
              />
              <ReportInfoItem label="Status" value={getReviewStatus(report)} />
              {report.hiddenReason ? (
                <ReportInfoItem
                  label="Hide Reason"
                  value={report.hiddenReason}
                />
              ) : null}
              <ReportInfoItem
                label={getReportObservationLabel(report)}
                value={getReportObservationValue(report)}
              />
              <ReportInfoItem
                label="GPS"
                value={`${report.latitude.toFixed(5)}, ${report.longitude.toFixed(5)}`}
              />
              <ReportInfoItem label="Source" value={report.locationSource} />
              <ReportInfoItem
                label="Images"
                value={`${report.imageUrls.length || 0} attached`}
              />
            </div>

            <div className="simple-modal-actions">
              <button className="panel-secondary" onClick={onClose} type="button">
                Back to Map
              </button>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
