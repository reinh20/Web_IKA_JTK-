import { create } from 'zustand'
import { CheckCircle2, XCircle, AlertCircle, X } from 'lucide-react'
import { useEffect } from 'react'
import { cn } from '@/lib/utils'

type ToastVariant = 'success' | 'error' | 'info'

interface Toast {
  id: string
  message: string
  variant: ToastVariant
}

interface ToastStore {
  toasts: Toast[]
  push: (message: string, variant?: ToastVariant) => void
  remove: (id: string) => void
}

const useToastStore = create<ToastStore>((set) => ({
  toasts: [],
  push: (message, variant = 'success') => {
    const id = Math.random().toString(36).slice(2)
    set((s) => ({ toasts: [...s.toasts, { id, message, variant }] }))
    setTimeout(() => {
      set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) }))
    }, 3500)
  },
  remove: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),
}))

export function toast(message: string, variant: ToastVariant = 'success') {
  useToastStore.getState().push(message, variant)
}

export function ToastContainer() {
  const toasts = useToastStore((s) => s.toasts)
  const remove = useToastStore((s) => s.remove)

  return (
    <div className="fixed top-6 right-6 z-[60] flex flex-col gap-2 pointer-events-none">
      {toasts.map((t) => (
        <ToastItem key={t.id} toast={t} onClose={() => remove(t.id)} />
      ))}
    </div>
  )
}

function ToastItem({ toast: t, onClose }: { toast: Toast; onClose: () => void }) {
  useEffect(() => {
    const timer = setTimeout(onClose, 3500)
    return () => clearTimeout(timer)
  }, [onClose])

  const Icon =
    t.variant === 'success' ? CheckCircle2 : t.variant === 'error' ? XCircle : AlertCircle

  return (
    <div
      className={cn(
        'pointer-events-auto flex items-center gap-2 rounded-md px-4 py-3 shadow-lg border min-w-[280px] max-w-md text-sm font-medium animate-in slide-in-from-top-2',
        t.variant === 'success' && 'bg-success-bg border-success/30 text-success',
        t.variant === 'error' && 'bg-danger-bg border-danger/30 text-danger',
        t.variant === 'info' && 'bg-primary-light border-primary/30 text-primary'
      )}
    >
      <Icon className="h-4 w-4 shrink-0" />
      <span className="flex-1">{t.message}</span>
      <button onClick={onClose} className="p-1 -mr-1 hover:opacity-70" aria-label="Close">
        <X className="h-3.5 w-3.5" />
      </button>
    </div>
  )
}
