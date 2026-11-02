import { forwardRef } from 'react'
import type { SelectHTMLAttributes } from 'react'
import { ChevronDown } from 'lucide-react'
import { cn } from '@/lib/utils'

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  error?: string
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(function Select(
  { className, error, children, ...rest },
  ref
) {
  return (
    <div className="w-full">
      <div className="relative">
        <select
          ref={ref}
          className={cn(
            'block w-full appearance-none rounded-md border bg-white pl-3 pr-10 h-10 text-sm text-gray-900',
            'focus:outline-none focus:ring-2',
            error
              ? 'border-danger focus:ring-danger/30 focus:border-danger'
              : 'border-gray-300 focus:ring-primary/30 focus:border-primary',
            'disabled:bg-gray-50 disabled:cursor-not-allowed',
            className
          )}
          {...rest}
        >
          {children}
        </select>
        <ChevronDown className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
      </div>
      {error && <p className="mt-1 text-xs text-danger">{error}</p>}
    </div>
  )
})
