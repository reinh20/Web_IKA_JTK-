import type { ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'

interface PermissionGuardProps {
  permission?: string
  children: ReactNode
}

export function PermissionGuard({ permission, children }: PermissionGuardProps) {
  const user = useAuthStore((s) => s.user)

  if (!permission) return <>{children}</>
  if (user?.role === 'Super Admin') return <>{children}</>

  if (!user?.permissions?.includes(permission)) {
    return <Navigate to="/admin/dashboard" replace />
  }

  return <>{children}</>
}
