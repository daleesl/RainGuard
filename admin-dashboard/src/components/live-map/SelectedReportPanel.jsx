import { Fragment } from 'react'
import {
  getReportLocationName,
  getReportObservationLabel,
  getReportObservationValue,
  getReportTypeName,
  getReviewStatus,
  isReportHidden,
  isReportResolved,
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
            </div>
          </div>

          <div className="selected-actions">
            <button
              className={
                report.status === 'verified'
                  ? 'panel-secondary panel-view'
                  : 'panel-primary panel-verify'
              }
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
              className="panel-secondary panel-view"
              onClick={() => onOpenDetails(report)}
              type="button"
            >
              Open Full Details
            </button>
            {isReportResolved(report) ? (
              <button
                className="panel-secondary panel-resolve"
                onClick={() =>
                  onRequestAction(report, {
                    confirmLabel: 'Reopen report',
                    intent: 'primary',
                    message:
                      'This returns the report to the active review queue and can make it visible again in active admin views.',
                    successMessage: 'Report reopened.',
                    title: 'Reopen this report?',
                    values: {
                      hidden: false,
                      status: 'active',
                      report_status: 'active',
                    },
                  })
                }
                type="button"
              >
                Reopen Report
              </button>
            ) : (
              <button
                className="panel-secondary panel-resolve"
                onClick={() =>
                  onRequestAction(report, {
                    confirmLabel: 'Resolve report',
                    intent: 'primary',
                    message:
                      'This marks the report as resolved so admins know the issue no longer needs active handling.',
                    successMessage: 'Report marked as resolved.',
                    title: 'Resolve this report?',
                    values: {
                      hidden: false,
                      status: 'resolved',
                      report_status: 'resolved',
                    },
                  })
                }
                type="button"
              >
                Resolve Report
              </button>
            )}
            {isReportHidden(report) ? (
              <button
                className="panel-secondary"
                onClick={() =>
                  onRequestAction(report, {
                    confirmLabel: 'Unhide report',
                    intent: 'primary',
                    message:
                      'This returns the report to the active review queue and allows it to appear again in public views when eligible.',
                    successMessage: 'Report unhidden.',
                    title: 'Unhide this report?',
                    values: {
                      hidden: false,
                      status: 'active',
                      report_status: 'active',
                    },
                  })
                }
                type="button"
              >
                Unhide Report
              </button>
            ) : (
              <button
                className="panel-danger"
                onClick={() =>
                  onRequestAction(report, {
                    confirmLabel: 'Hide report',
                    intent: 'danger',
                    message:
                      'This hides the report from public views because it is duplicate, invalid, or unclear.',
                    reasonLabel: 'Hide reason',
                    reasonPlaceholder:
                      'Example: Duplicate report, unclear photo, invalid location...',
                    requiresReason: true,
                    successMessage: 'Report hidden from public views.',
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
                Hide Report
              </button>
            )}
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
