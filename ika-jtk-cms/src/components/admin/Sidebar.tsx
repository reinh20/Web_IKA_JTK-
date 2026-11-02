import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard, Users, Newspaper, Calendar, Briefcase,
  MessageSquareQuote, Vote, Settings, MoreVertical, LogOut, ScrollText, Trophy,
} from 'lucide-react'
import { useState, useEffect } from 'react'
import { useAuthStore } from '@/stores/authStore'
import { cn, getAvatarUrl, getFileUrl } from '@/lib/utils'
import api from '@/lib/api'
import defaultLogoUrl from '/logo.png'

const navItems = [
  { to: '/admin/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/admin/alumni', label: 'Alumni', icon: Users, permission: 'alumni_view' },
  { to: '/admin/alumni-grafis', label: 'Alumni Grafis', icon: Trophy, permission: 'alumni_view' },
  { to: '/admin/berita', label: 'Berita', icon: Newspaper, permission: 'berita_view' },
  { to: '/admin/agenda', label: 'Agenda', icon: Calendar, permission: 'agenda_view' },
  { to: '/admin/loker', label: 'Loker', icon: Briefcase, permission: 'loker_view' },
  { to: '/admin/testimoni', label: 'Testimoni', icon: MessageSquareQuote, permission: 'testimoni_view' },
  { to: '/admin/pemilu', label: 'Pemilu', icon: Vote, permission: 'pemilu_view' },
  { to: '/admin/portal', label: 'Portal Settings', icon: Settings, permission: 'settings_view' },
]

export function Sidebar() {
  const user = useAuthStore((s) => s.user)
  const logout = useAuthStore((s) => s.logout)
  const [menuOpen, setMenuOpen] = useState(false)
  const [dynamicLogoUrl, setDynamicLogoUrl] = useState<string>('')
  const [dynamicSiteName, setDynamicSiteName] = useState<string>('IKA JTK POLBAN')

  useEffect(() => {
    const loadConfig = () => {
      api.getPortalConfig().then((data) => {
        if (data?.logo_url) setDynamicLogoUrl(data.logo_url)
        if (data?.site_name) {
          setDynamicSiteName(data.site_name)
          document.title = `${data.site_name} — Admin`
        }
      }).catch(() => {})
    }
    loadConfig()
    window.addEventListener('portal-config-updated', loadConfig)
    return () => window.removeEventListener('portal-config-updated', loadConfig)
  }, [])

  const sidebarLogoUrl = dynamicLogoUrl ? getFileUrl(dynamicLogoUrl) : defaultLogoUrl

  return (
    <aside className="sticky top-0 self-start flex flex-col h-screen w-64 shrink-0 bg-white border-r border-gray-200">
      <div className="px-6 py-5 flex items-center gap-2 border-b border-gray-100">
        <img src={sidebarLogoUrl} alt="Logo" className="h-8 w-8 object-contain" />
        <span className="font-bold text-primary text-base leading-tight line-clamp-2">
          {dynamicSiteName}
        </span>
      </div>

      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {navItems
          .filter((item) => {
            // Dashboard doesn't need permission
            if (!item.permission) return true
            // Super Admin has access to everything
            if (user?.role === 'Super Admin') return true
            // Otherwise, check if user has the required permission
            return user?.permissions?.includes(item.permission)
          })
          .map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              cn(
                'group flex items-center gap-3 px-3 h-10 rounded-md text-sm font-medium relative',
                isActive
                  ? 'bg-gray-100 text-gray-900'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              )
            }
          >
            {({ isActive }) => (
              <>
                {isActive && (
                  <span className="absolute right-0 top-2 bottom-2 w-1 bg-accent rounded-l" />
                )}
                <item.icon className="h-5 w-5" />
                <span>{item.label}</span>
              </>
            )}
          </NavLink>
        ))}

        {(user?.role === 'Super Admin' || user?.permissions?.includes('users_view')) && (
          <NavLink
            to="/admin/users"
            className={({ isActive }) =>
              cn(
                'group flex items-center gap-3 px-3 h-10 rounded-md text-sm font-medium relative',
                isActive
                  ? 'bg-gray-100 text-gray-900'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              )
            }
          >
            {({ isActive }) => (
              <>
                {isActive && (
                  <span className="absolute right-0 top-2 bottom-2 w-1 bg-accent rounded-l" />
                )}
                <Users className="h-5 w-5" />
                <span>Manajemen Admin</span>
              </>
            )}
          </NavLink>
        )}

        {(user?.role === 'Super Admin' ||
          user?.permissions?.includes('audit_log_view')) && (
          <NavLink
            to="/admin/audit-logs"
            className={({ isActive }) =>
              cn(
                'group flex items-center gap-3 px-3 h-10 rounded-md text-sm font-medium relative',
                isActive
                  ? 'bg-gray-100 text-gray-900'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              )
            }
          >
            {({ isActive }) => (
              <>
                {isActive && (
                  <span className="absolute right-0 top-2 bottom-2 w-1 bg-accent rounded-l" />
                )}
                <ScrollText className="h-5 w-5" />
                <span>Log Aktivitas</span>
              </>
            )}
          </NavLink>
        )}
      </nav>

      <div className="p-3 border-t border-gray-100 relative">
        <div className="flex items-center gap-3 p-2 rounded-md">
          <img
            src={getAvatarUrl(user?.avatarUrl, user?.nama)}
            alt={user?.nama}
            className="h-9 w-9 rounded-full object-cover"
          />
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-gray-900 truncate">
              {user?.nama}
            </p>
            <p className="text-xs text-gray-500 truncate">{user?.role}</p>
          </div>
          <button
            type="button"
            onClick={() => setMenuOpen((v) => !v)}
            className="p-1.5 rounded hover:bg-gray-100"
            aria-label="User menu"
          >
            <MoreVertical className="h-4 w-4 text-gray-500" />
          </button>
        </div>
        {menuOpen && (
          <div className="absolute right-3 bottom-16 z-20 w-44 rounded-md border border-gray-200 bg-white shadow-lg py-1">
            <button
              type="button"
              onClick={() => {
                setMenuOpen(false)
                logout()
              }}
              className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
            >
              <LogOut className="h-4 w-4" />
              Keluar
            </button>
          </div>
        )}
      </div>
    </aside>
  )
}
