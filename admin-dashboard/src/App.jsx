import { useState } from 'react'
import './App.css'
import { AdminLayout } from './components/AdminLayout'
import { useAdminAuth } from './hooks/useAdminAuth'
import { AdminLogin } from './pages/AdminLogin'
import { AlertsManagement } from './pages/AlertsManagement'
import { AnalyticsPage } from './pages/AnalyticsPage'
import { LiveRiskMap } from './pages/LiveRiskMap'
import { PlaceholderPage } from './pages/PlaceholderPage'
import { ReportsManagement } from './pages/ReportsManagement'
import { UsersManagement } from './pages/UsersManagement'
import { VerificationReview } from './pages/VerificationReview'

const pageTitles = {
  dashboard: 'Dashboard',
  liveMap: 'Live Risk Map',
  reports: 'Reports',
  verification: 'Verification',
  alerts: 'Alerts',
  users: 'Users',
  analytics: 'Analytics',
  settings: 'Settings',
}

function App() {
  const [activePage, setActivePage] = useState('liveMap')
  const { adminProfile, error, signOutAdmin, status, user } = useAdminAuth()

  if (status !== 'admin') {
    return (
      <AdminLogin
        error={error}
        onSignOut={signOutAdmin}
        status={status}
      />
    )
  }

  return (
    <AdminLayout
      activePage={activePage}
      adminName={adminProfile?.display_name || user?.email || 'Admin'}
      onNavigate={setActivePage}
      onSignOut={signOutAdmin}
    >
      {activePage === 'liveMap' ? (
        <LiveRiskMap />
      ) : activePage === 'reports' ? (
        <ReportsManagement onOpenMap={() => setActivePage('liveMap')} />
      ) : activePage === 'verification' ? (
        <VerificationReview />
      ) : activePage === 'alerts' ? (
        <AlertsManagement />
      ) : activePage === 'users' ? (
        <UsersManagement onOpenVerification={() => setActivePage('verification')} />
      ) : activePage === 'analytics' ? (
        <AnalyticsPage />
      ) : (
        <PlaceholderPage title={pageTitles[activePage]} />
      )}
    </AdminLayout>
  )
}

export default App
