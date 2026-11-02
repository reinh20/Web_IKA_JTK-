import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

type BadgeVariant = 'gray' | 'orange' | 'green' | 'blue' | 'red' | 'navy'

interface BadgeProps {
  variant?: BadgeVariant
  children: ReactNode
  className?: string
}

const variantMap: Record<BadgeVariant, string> = {
  gray: 'bg-gray-200 text-gray-700',
  orange: 'bg-accent text-white',
  green: 'bg-success-bg text-success',
  blue: 'bg-primary-light text-primary',
  red: 'bg-danger-bg text-danger',
  navy: 'bg-navy text-white',
}

export function Badge({ variant = 'gray', className, children }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-md px-2.5 py-1 text-xs font-medium',
        variantMap[variant],
        className
      )}
    >
      {children}
    </span>
  )
}
