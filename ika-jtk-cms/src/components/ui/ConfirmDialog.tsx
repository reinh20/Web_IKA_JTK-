import type { ReactNode } from 'react'
import { Modal } from './Modal'
import { Button } from './Button'

interface ConfirmDialogProps {
  open: boolean
  icon?: ReactNode
  title: string
  description?: ReactNode
  confirmLabel?: string
  cancelLabel?: string
  variant?: 'primary' | 'danger' | 'accent'
  onConfirm: () => void
  onCancel: () => void
  loading?: boolean
}

export function ConfirmDialog({
  open,
  icon,
  title,
  description,
  confirmLabel = 'Konfirmasi',
  cancelLabel = 'Batal',
  variant = 'primary',
  onConfirm,
  onCancel,
  loading,
}: ConfirmDialogProps) {
  return (
    <Modal open={open} onClose={onCancel}>
      <div className="p-6">
        {icon && <div className="mb-4">{icon}</div>}
        <h3 className="text-lg font-bold text-gray-900">{title}</h3>
        {description && (
          <div className="mt-2 text-sm text-gray-600 leading-relaxed">
            {description}
          </div>
        )}

        <div className="mt-6 flex items-center gap-3">
          <Button
            variant={variant === 'danger' ? 'danger' : variant === 'accent' ? 'accent' : 'primary'}
            onClick={onConfirm}
            loading={loading}
          >
            {confirmLabel}
          </Button>
          <Button variant="ghost" onClick={onCancel} disabled={loading}>
            {cancelLabel}
          </Button>
        </div>
      </div>
    </Modal>
  )
}
