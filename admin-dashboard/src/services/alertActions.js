import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore'
import { auth, db } from '../firebase'

export function createAlert({
  area,
  message,
  riskLevel,
  status,
  title,
}) {
  const isPublished = status === 'published'

  return addDoc(collection(db, 'alerts'), {
    area,
    created_at: serverTimestamp(),
    created_by: auth.currentUser?.uid || 'admin-dashboard',
    delivery: ['push'],
    message,
    published_at: isPublished ? serverTimestamp() : null,
    resolved_at: null,
    risk_level: riskLevel,
    source: 'manual',
    status,
    title,
  })
}

export function resolveAlert(alertId) {
  return updateDoc(doc(db, 'alerts', alertId), {
    resolved_at: serverTimestamp(),
    status: 'resolved',
  })
}

export function deleteAlert(alertId) {
  return deleteDoc(doc(db, 'alerts', alertId))
}
