import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

interface TabItem {
  key: string
  label: ReactNode
  count?: number
  hasDot?: boolean
}

interface TabsProps {
  items: TabItem[]
  value: string
  onChange: (key: string) => void
  className?: string
}

export function Tabs({ items, value, onChange, className }: TabsProps) {
  return (
    <div className={cn('border-b border-gray-200', className)}>
      <div className="flex gap-8">
        {items.map((item) => {
          const active = item.key === value
          return (
            <button
              key={item.key}
              type="button"
              onClick={() => onChange(item.key)}
              className={cn(
                'relative pb-3 text-sm font-semibold transition-colors',
                active ? 'text-gray-900' : 'text-gray-500 hover:text-gray-700'
              )}
            >
              <span className="inline-flex items-center gap-1">
                {item.label}
                {typeof item.count === 'number' && (
                  <span className={cn(active ? 'text-gray-900' : 'text-gray-500')}>
                    ({item.count})
                  </span>
                )}
                {item.hasDot && (
                  <span className="ml-1 h-2 w-2 rounded-full bg-accent" />
                )}
              </span>
              {active && (
                <span className="absolute -bottom-px left-0 right-0 h-0.5 bg-accent rounded-full" />
              )}
            </button>
          )
        })}
      </div>
    </div>
  )
}
