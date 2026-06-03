import {
  BarChart3,
  Bell,
  ClipboardList,
  LayoutDashboard,
  Map,
  ShieldCheck,
  LogOut,
  Users,
} from 'lucide-react'

const navItems = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'liveMap', label: 'Live Risk Map', icon: Map },
  { id: 'reports', label: 'Reports', icon: ClipboardList },
  { id: 'verification', label: 'Verification', icon: ShieldCheck },
  { id: 'alerts', label: 'Alerts', icon: Bell },
  { id: 'users', label: 'Users', icon: Users },
  { id: 'analytics', label: 'Analytics', icon: BarChart3 },
]

export function AdminLayout({
  activePage,
  adminName,
  onNavigate,
  onSignOut,
  children,
}) {
  return (
    <div className="admin-shell">
      <aside className="admin-sidebar">
        <div>
          <div className="brand-lockup">
            <h1>RainGuard</h1>
            <p>Admin Operations</p>
          </div>

          <nav className="sidebar-nav" aria-label="Admin navigation">
            {navItems.map((item) => {
              const Icon = item.icon
              const isActive = activePage === item.id

              return (
                <button
                  className={`sidebar-link ${isActive ? 'is-active' : ''}`}
                  key={item.id}
                  onClick={() => onNavigate(item.id)}
                  type="button"
                >
                  <Icon aria-hidden="true" size={16} strokeWidth={1.8} />
                  <span>{item.label}</span>
                </button>
              )
            })}
          </nav>
        </div>

        <div className="moderator-card">
          <strong>{adminName || 'Barangay Safety Desk'}</strong>
          <span>Safety Moderator</span>
          <button className="sidebar-signout" onClick={onSignOut} type="button">
            <LogOut aria-hidden="true" size={13} />
            Sign out
          </button>
        </div>
      </aside>

      <div className="admin-content">{children}</div>
    </div>
  )
}
