import { useState, useRef, useEffect } from 'react'
import { Search, ChevronDown } from 'lucide-react'
import { cn } from '@/lib/utils'

interface Option {
  value: string
  label: React.ReactNode
  searchText?: string
}

interface SearchableSelectProps {
  options: Option[]
  value: string
  onChange: (value: string) => void
  disabled?: boolean
  placeholder?: string
  searchPlaceholder?: string
  className?: string
  buttonClassName?: string
  numericOnly?: boolean
  error?: string
}

export function SearchableSelect({
  options,
  value,
  onChange,
  disabled,
  placeholder = 'Pilih...',
  searchPlaceholder = 'Cari...',
  className,
  buttonClassName,
  numericOnly,
  error,
}: SearchableSelectProps) {
  const [open, setOpen] = useState(false)
  const [search, setSearch] = useState('')
  const containerRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const selected = options.find((o) => o.value === value)

  const filtered = search.trim()
    ? options.filter((o) => {
        const textToSearch = o.searchText || (typeof o.label === 'string' ? o.label : '')
        return textToSearch.toLowerCase().includes(search.toLowerCase())
      })
    : options

  useEffect(() => {
    if (open) {
      setSearch('')
      setTimeout(() => inputRef.current?.focus(), 50)
    }
  }, [open])

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  return (
    <div ref={containerRef} className={cn('relative w-full', className)}>
      <button
        type="button"
        disabled={disabled}
        onClick={() => !disabled && setOpen((v) => !v)}
        className={cn(
          'flex w-full items-center justify-between rounded-md border bg-white px-3 h-10 text-sm text-left',
          'focus:outline-none focus:ring-2',
          error 
            ? 'border-danger focus:ring-danger/30 focus:border-danger' 
            : 'border-gray-300 focus:ring-primary/30 focus:border-primary',
          disabled && 'bg-gray-50 cursor-not-allowed text-gray-500',
          !selected && 'text-gray-400',
          buttonClassName
        )}
      >
        <span className="truncate">{selected ? selected.label : placeholder}</span>
        <ChevronDown className="h-4 w-4 text-gray-400 shrink-0" />
      </button>
      {error && <p className="mt-1 text-xs text-danger text-left">{error}</p>}

      {open && (
        <div className="absolute z-50 mt-1 w-full rounded-md border border-gray-200 bg-white shadow-lg">
          <div className="flex items-center gap-2 border-b border-gray-100 px-3 h-10">
            <Search className="h-4 w-4 text-gray-400 shrink-0" />
            <input
              ref={inputRef}
              value={search}
              onChange={(e) => {
                let val = e.target.value
                if (numericOnly) val = val.replace(/\D/g, '')
                setSearch(val)
              }}
              placeholder={searchPlaceholder}
              className="flex-1 text-sm text-gray-900 placeholder-gray-400 outline-none border-none bg-transparent h-full"
            />
          </div>
          <div className="max-h-48 overflow-y-auto py-1">
            {filtered.length === 0 ? (
              <div className="px-3 py-4 text-sm text-gray-400 text-center">
                Tidak ada hasil
              </div>
            ) : (
              filtered.map((opt) => (
                <button
                  key={opt.value}
                  type="button"
                  onClick={() => {
                    onChange(opt.value)
                    setOpen(false)
                  }}
                  className={cn(
                    'w-full text-left px-3 py-2 text-sm hover:bg-gray-50',
                    opt.value === value
                      ? 'bg-blue-50 text-primary font-medium'
                      : 'text-gray-700',
                  )}
                >
                  {opt.label}
                </button>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )
}
