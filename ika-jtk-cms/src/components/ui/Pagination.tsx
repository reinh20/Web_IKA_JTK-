import { ArrowLeft, ArrowRight } from 'lucide-react'
import { cn } from '@/lib/utils'

interface PaginationProps {
  page: number
  totalPages: number
  onChange: (page: number) => void
  className?: string
}

function buildRange(page: number, total: number): (number | 'gap')[] {
  if (total <= 7) {
    return Array.from({ length: total }, (_, i) => i + 1)
  }
  const result: (number | 'gap')[] = []
  result.push(1)
  if (page > 4) result.push('gap')
  const start = Math.max(2, page - 1)
  const end = Math.min(total - 1, page + 1)
  for (let i = start; i <= end; i++) result.push(i)
  if (page < total - 3) result.push('gap')
  result.push(total)
  return result
}

export function Pagination({ page, totalPages, onChange, className }: PaginationProps) {
  const items = buildRange(page, totalPages)
  return (
    <nav className={cn('flex items-center justify-center gap-1', className)} aria-label="Pagination">
      <button
        type="button"
        disabled={page <= 1}
        onClick={() => onChange(page - 1)}
        className={cn(
          'inline-flex items-center gap-1.5 h-9 px-3 text-sm font-medium rounded-md',
          page <= 1 ? 'text-gray-300 cursor-not-allowed' : 'text-gray-700 hover:bg-gray-100'
        )}
      >
        <ArrowLeft className="h-4 w-4" />
        Previous
      </button>
      {items.map((it, idx) =>
        it === 'gap' ? (
          <span key={`gap-${idx}`} className="px-2 text-gray-400 select-none">…</span>
        ) : (
          <button
            key={it}
            type="button"
            onClick={() => onChange(it)}
            className={cn(
              'inline-flex items-center justify-center h-9 min-w-9 px-3 text-sm font-medium rounded-md',
              it === page
                ? 'bg-gray-900 text-white'
                : 'text-gray-700 hover:bg-gray-100'
            )}
          >
            {it}
          </button>
        )
      )}
      <button
        type="button"
        disabled={page >= totalPages}
        onClick={() => onChange(page + 1)}
        className={cn(
          'inline-flex items-center gap-1.5 h-9 px-3 text-sm font-medium rounded-md',
          page >= totalPages ? 'text-gray-300 cursor-not-allowed' : 'text-gray-700 hover:bg-gray-100'
        )}
      >
        Next
        <ArrowRight className="h-4 w-4" />
      </button>
    </nav>
  )
}
