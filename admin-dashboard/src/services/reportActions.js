import { doc, serverTimestamp, updateDoc } from 'firebase/firestore'
import { auth, db } from '../firebase'

export function updateReportStatus(reportId, values) {
  return updateDoc(doc(db, 'reports', reportId), values)
}

export function verifyReport(reportId) {
  return updateReportStatus(reportId, {
    hidden: false,
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
    hidden: false,
    status: 'resolved',
    report_status: 'resolved',
  })
}

export function reopenReport(reportId) {
  return updateReportStatus(reportId, {
    hidden: false,
    status: 'active',
    report_status: 'active',
  })
}

export function hiddenReportAuditValues(reason) {
  const admin = auth.currentUser

  return {
    hidden_at: serverTimestamp(),
    hidden_by: admin?.email || admin?.uid || 'admin',
    hidden_reason: String(reason || '').trim(),
  }
}

export function hideDuplicateReport(reportId, reason) {
  return updateReportStatus(reportId, {
    hidden: true,
    ...hiddenReportAuditValues(reason),
    status: 'duplicate_hidden',
    report_status: 'duplicate_hidden',
  })
}

export function unhideReport(reportId) {
  return updateReportStatus(reportId, {
    hidden: false,
    status: 'active',
    report_status: 'active',
  })
}
