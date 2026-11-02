import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import api from '@/lib/api'

export interface AdminUser {
  id: string
  nama: string
  email: string
  username: string
  role: string
  avatarUrl: string
  permissions?: string[]
}

export interface AuthState {
  user: AdminUser | null
  token: string | null
  isLoggedIn: boolean
  sessionExpired: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  setSessionExpired: (value: boolean) => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isLoggedIn: false,
      sessionExpired: false,
      login: async (email, password) => {
        try {
          const res = await api.post('/admin/auth/login', { email, password })
          const { user, token } = res.data
          set({ user, token, isLoggedIn: true, sessionExpired: false })
        } catch (error: any) {
          throw new Error(error.response?.data?.message || 'Login failed')
        }
      },
      logout: () => {
        const token = useAuthStore.getState().token
        if (token) {
          api.post('/admin/auth/logout', {}, {
            headers: { Authorization: `Bearer ${token}` }
          }).catch(() => {})
        }
        set({ user: null, token: null, isLoggedIn: false, sessionExpired: false })
      },
      setSessionExpired: (value: boolean) => {
        set({ sessionExpired: value })
      },
    }),
    { name: 'ikajtk-cms-auth' }
  )
)
