import { forwardRef } from 'react'
import type { InputHTMLAttributes } from 'react'
import { Check } from 'lucide-react'
import { cn } from '@/lib/utils'

interface CheckboxProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label?: React.ReactNode
}

export const Checkbox = forwardRef<HTMLInputElement, CheckboxProps>(function Checkbox(
  { className, label, checked, ...rest },
  ref
) {
  return (
    <label className={cn('inline-flex items-center gap-2 cursor-pointer select-none', className)}>
      <span className="relative inline-flex items-center justify-center">
        <input
          ref={ref}
          type="checkbox"
          checked={checked}
          className="peer sr-only"
          {...rest}
        />
        <span
          className={cn(
            'h-4 w-4 rounded border border-gray-300 bg-white inline-flex items-center justify-center transition-colors',
            'peer-checked:bg-primary peer-checked:border-primary'
          )}
        >
          {checked && <Check className="h-3 w-3 text-white" strokeWidth={3} />}
        </span>
      </span>
      {label && <span className="text-sm text-gray-800">{label}</span>}
    </label>
  )
})
