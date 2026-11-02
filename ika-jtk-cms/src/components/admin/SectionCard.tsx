import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'
import { AlertCircle } from 'lucide-react'

interface SectionCardProps {
  title: ReactNode
  children: ReactNode
  className?: string
  actions?: ReactNode
  hasError?: boolean
}

export function SectionCard({ title, children, className, actions, hasError }: SectionCardProps) {
  return (
    <section
      data-error={hasError ? "true" : "false"}
      className={cn(
        'rounded-lg border bg-white shadow-sm p-6 transition-colors duration-300',
        hasError ? 'border-danger/40 ring-1 ring-danger/40' : 'border-gray-200',
        className
      )}
    >
      <header className="flex items-start justify-between mb-5">
        <div>
          <h2 className={cn("text-lg font-bold", hasError ? "text-danger" : "text-gray-900")}>
            {title}
          </h2>
          <span className={cn("block mt-1.5 h-0.5 w-8 rounded-full", hasError ? "bg-danger" : "bg-accent")} />
          {hasError && (
            <div className="flex items-center gap-1.5 mt-3 text-sm text-danger font-medium">
              <AlertCircle className="h-4 w-4" />
              <span>Bagian ini wajib dilengkapi atau terdapat isian yang tidak sesuai.</span>
            </div>
          )}
        </div>
        {actions}
      </header>
      {children}
    </section>
  )
}
