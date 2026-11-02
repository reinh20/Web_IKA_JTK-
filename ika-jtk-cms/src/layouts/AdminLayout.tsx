import { Navigate, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useEffect } from 'react'
import { Sidebar } from '@/components/admin/Sidebar'
import { useAuthStore } from '@/stores/authStore'
import { SessionExpiredModal } from '@/components/ui/SessionExpiredModal'

function isJwtExpired(token: string | null): boolean {
  if (!token) return true
  try {
    const payloadBase64 = token.split('.')[1]
    if (!payloadBase64) return true
    const payloadJson = atob(payloadBase64.replace(/-/g, '+').replace(/_/g, '/'))
    const payload = JSON.parse(payloadJson)
    if (!payload.exp) return false
    return Date.now() >= payload.exp * 1000
  } catch {
    return true
  }
}

export function AdminLayout() {
  const { isLoggedIn, token, logout, sessionExpired, setSessionExpired } = useAuthStore()
  const navigate = useNavigate()
  const location = useLocation()

  useEffect(() => {
    if (isLoggedIn && isJwtExpired(token)) {
      setSessionExpired(true)
    }
  }, [location.pathname, isLoggedIn, token, setSessionExpired])

  const handleLoginAgain = () => {
    setSessionExpired(false)
    logout()
    navigate('/admin/login', { replace: true })
  }

  if (!isLoggedIn && !sessionExpired) return <Navigate to="/admin/login" replace />

  if (sessionExpired) {
    return (
      <div className="flex min-h-screen bg-gray-50 items-center justify-center">
        <SessionExpiredModal
          open={true}
          onLoginAgain={handleLoginAgain}
        />
      </div>
    )
  }

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <main className="flex-1 min-w-0 overflow-x-hidden">
        <Outlet />
      </main>

      <SessionExpiredModal
        open={sessionExpired}
        onLoginAgain={handleLoginAgain}
      />
    </div>
  )
}
