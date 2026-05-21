import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'
import { getStorage } from 'firebase/storage'

const firebaseConfig = {
  apiKey: 'AIzaSyDTvA0DDc_jn9K8qMFeWAaHEkpeFacolbs',
  authDomain: 'rainguard-13ec1.firebaseapp.com',
  projectId: 'rainguard-13ec1',
  storageBucket: 'rainguard-13ec1.firebasestorage.app',
  messagingSenderId: '858501899685',
  appId: '1:858501899685:web:809411e491574b5da9b44c',
  measurementId: 'G-QVW616VSZD',
}

export const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)
export const db = getFirestore(app)
export const storage = getStorage(app)
