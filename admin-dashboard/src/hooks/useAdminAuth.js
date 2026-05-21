import { useEffect, useState } from 'react'
import { onAuthStateChanged, signOut } from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, db } from '../firebase'

export function useAdminAuth() {
  const [authState, setAuthState] = useState({
    adminProfile: null,
    error: '',
    status: 'checking',
    user: null,
  })

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setAuthState({
          adminProfile: null,
          error: '',
          status: 'signed-out',
          user: null,
        })
        return
      }

      try {
        const userSnapshot = await getDoc(doc(db, 'users', user.uid))
        const profile = userSnapshot.data() || {}

        if (profile.role !== 'admin') {
          setAuthState({
            adminProfile: profile,
            error: 'This account is not registered as a RainGuard admin.',
            status: 'not-admin',
            user,
          })
          return
        }

        setAuthState({
          adminProfile: profile,
          error: '',
          status: 'admin',
          user,
        })
      } catch (error) {
        setAuthState({
          adminProfile: null,
          error: error.message,
          status: 'error',
          user,
        })
      }
    })

    return unsubscribe
  }, [])

  return {
    ...authState,
    signOutAdmin: () => signOut(auth),
  }
}
