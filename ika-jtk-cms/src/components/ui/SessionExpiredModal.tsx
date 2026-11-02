import { LogOut } from 'lucide-react'
import { Button } from './Button'

interface SessionExpiredModalProps {
  open: boolean
  onLoginAgain: () => void
}

/**
 * Blocking modal that appears when the JWT token expires (HTTP 401).
 * Cannot be dismissed — user must click "Login Kembali" to proceed.
 */
export function SessionExpiredModal({ open, onLoginAgain }: SessionExpiredModalProps) {
  if (!open) return null

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4">
      {/* Non-dismissable backdrop */}
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" />

      <div
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="session-expired-title"
        aria-describedby="session-expired-desc"
        className="relative w-full max-w-sm bg-white rounded-2xl shadow-2xl border border-gray-100 overflow-hidden"
      >
        {/* Top accent bar */}
        <div className="h-1 w-full bg-gradient-to-r from-primary to-accent" />

        <div className="p-8 flex flex-col items-center text-center">
          {/* Icon */}
          <div className="inline-flex h-16 w-16 items-center justify-center rounded-full bg-orange-50 text-accent mb-5">
            <LogOut className="h-7 w-7" />
          </div>

          <h2
            id="session-expired-title"
            className="text-xl font-bold text-gray-900 leading-tight"
          >
            Sesi Telah Berakhir
          </h2>

          <p
            id="session-expired-desc"
            className="mt-3 text-sm text-gray-500 leading-relaxed"
          >
            Sesi login Anda telah habis atau tidak valid. Silakan login kembali untuk melanjutkan.
          </p>

          <Button
            className="mt-7 w-full"
            onClick={onLoginAgain}
            leftIcon={<LogOut className="h-4 w-4" />}
          >
            Login Kembali
          </Button>
        </div>
      </div>
    </div>
  )
}
