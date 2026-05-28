import { doc, updateDoc } from 'firebase/firestore'
import { db } from '../firebase'

export function updateReportStatus(reportId, values) {
  return updateDoc(doc(db, 'reports', reportId), values)
}

export function verifyReport(reportId) {
  return updateReportStatus(reportId, {
    status: 'verified',
    report_status: 'verified',
  })
}

export function unverifyReport(reportId) {
  return updateReportStatus(reportId, {
    hidden: false,
    status: 'active',
    report_status: 'active',
  })
}

export function resolveReport(reportId) {
  return updateReportStatus(reportId, {
    status: 'resolved',
    report_status: 'resolved',
  })
}

export function hideDuplicateReport(reportId) {
  return updateReportStatus(reportId, {
    hidden: true,
    status: 'duplicate_hidden',
    report_status: 'duplicate_hidden',
  })
}
