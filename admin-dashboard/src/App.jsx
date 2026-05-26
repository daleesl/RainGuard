import { lazy, Suspense, useState } from 'react'
import './App.css'
import { AdminLayout } from './components/AdminLayout'
import { useAdminAuth } from './hooks/useAdminAuth'
import { AdminLogin } from './pages/AdminLogin'
import { PlaceholderPage } from './pages/PlaceholderPage'

const AlertsManagement = lazy(() =>
  import('./pages/AlertsManagement').then((module) => ({
    default: module.AlertsManagement,
  })),
)
const AnalyticsPage = lazy(() =>
  import('./pages/AnalyticsPage').then((module) => ({
    default: module.AnalyticsPage,
  })),
)
const DashboardPage = lazy(() =>
  import('./pages/DashboardPage').then((module) => ({
    default: module.DashboardPage,
  })),
)
const LiveRiskMap = lazy(() =>
  import('./pages/LiveRiskMap').then((module) => ({
    default: module.LiveRiskMap,
  })),
)
const ReportsManagement = lazy(() =>
  import('./pages/ReportsManagement').then((module) => ({
    default: module.ReportsManagement,
  })),
)
const UsersManagement = lazy(() =>
  import('./pages/UsersManagement').then((module) => ({
    default: module.UsersManagement,
  })),
)
const VerificationReview = lazy(() =>
  import('./pages/VerificationReview').then((module) => ({
    default: module.VerificationReview,
  })),
)

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
  const [activePage, setActivePage] = useState('dashboard')
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
      <Suspense fallback={<AdminPageLoading title={pageTitles[activePage]} />}>
        {activePage === 'dashboard' ? (
          <DashboardPage onNavigate={setActivePage} />
        ) : activePage === 'liveMap' ? (
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
      </Suspense>
    </AdminLayout>
  )
}

function AdminPageLoading({ title }) {
  return (
    <main className="placeholder-page">
      <section className="placeholder-card">
        <p>RainGuard Admin</p>
        <h2>{title || 'Loading'}</h2>
        <span>Loading admin tools...</span>
      </section>
    </main>
  )
}

export default App
