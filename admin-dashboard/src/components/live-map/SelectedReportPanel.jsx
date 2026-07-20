import { Fragment } from 'react'
import {
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

export function SelectedReportPanel({
  imageIndex,
  onImageIndexChange,
  onOpenDetails,
  onRequestAction,
  onZoomImage,
  report,
}) {
  return (
    <aside className="selected-panel">
      <div className="selected-panel-header">
        <h3>Selected Report</h3>
        {report?.status === 'verified' ? (
          <StatusChip className="selected-verified-chip" tone="green">
            Verified
          </StatusChip>
        ) : null}
      </div>
      {report ? (
        <Fragment>
          <ReportImageCarousel
            imageIndex={imageIndex}
            onImageIndexChange={onImageIndexChange}
            onZoomImage={onZoomImage}
            report={report}
          />

          <div className="selected-report-card" key={report.id}>
            <div className="selected-chip-row">
              <div className="selected-chip-group">
                <StatusChip>
                  {getReportTypeName(report)}
                </StatusChip>
              </div>
            </div>

            <div className="selected-copy">
              <h4>{getReportLocationName(report)}</h4>
              <p>
                {report.description ||
                  'No description was provided for this report.'}
              </p>
            </div>

            <div className="selected-meta-list">
              <ReportInfoItem
                label="Reporter"
                value={report.reporterName || 'Anonymous'}
              />
              <ReportInfoItem
                label="Created"
                value={formatReportDateTime(report.createdAt)}
                stacked
              />
              <ReportInfoItem
                label="Status"
                value={getReviewStatus(report)}
              />
              <ReportInfoItem
                label={getReportObservationLabel(report)}
                value={getReportObservationValue(report)}
              />
              <ReportInfoItem
                label="GPS"
                value={`${report.latitude.toFixed(5)}, ${report.longitude.toFixed(5)}`}
              />
            </div>
          </div>

          <div className="selected-actions">
            <button
              className="panel-primary"
              onClick={() =>
                onRequestAction(
                  report,
                  report.status === 'verified'
                    ? {
                        confirmLabel: 'Unverify report',
                        intent: 'primary',
                        message:
                          'This removes the admin verified mark and returns the report to the unreviewed queue.',
                        successMessage: 'Report moved back to unreviewed.',
                        title: 'Unverify this report?',
                        values: {
                          hidden: false,
                          status: 'active',
                          report_status: 'active',
                        },
                      }
                    : {
                        confirmLabel: 'Verify report',
                        intent: 'primary',
                        message:
                          'This marks the report as reviewed and trusted by admin.',
                        successMessage: 'Report marked as verified.',
                        title: 'Verify this report?',
                        values: {
                          status: 'verified',
                          report_status: 'verified',
                        },
                      },
                )
              }
              type="button"
            >
              {report.status === 'verified'
                ? 'Unverify Report'
                : 'Mark Verified'}
            </button>
            <button
              className="panel-secondary"
              onClick={() => onOpenDetails(report)}
              type="button"
            >
              Open Full Details
            </button>
            <button
              className="panel-secondary"
              onClick={() =>
                onRequestAction(report, {
                  confirmLabel: 'Resolve report',
                  intent: 'primary',
                  message:
                    'This marks the report as resolved so admins know the issue no longer needs active handling.',
                  successMessage: 'Report marked as resolved.',
                  title: 'Resolve this report?',
                  values: {
                    status: 'resolved',
                    report_status: 'resolved',
                  },
                })
              }
              type="button"
            >
              Resolve Report
            </button>
            <button
              className="panel-danger"
              onClick={() =>
                onRequestAction(report, {
                  confirmLabel: 'Hide report',
                  intent: 'danger',
                  message:
                    'This hides the report from admin review because it is a duplicate or invalid entry.',
                  successMessage: 'Report hidden as duplicate.',
                  title: 'Hide this report?',
                  values: {
                    hidden: true,
                    status: 'duplicate_hidden',
                    report_status: 'duplicate_hidden',
                  },
                })
              }
              type="button"
            >
              Hide Duplicate
            </button>
          </div>
        </Fragment>
      ) : (
        <p className="inline-state">
          Select a map pin to review report information.
        </p>
      )}
    </aside>
  )
}
