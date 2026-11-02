import { cn } from '@/lib/utils'

interface RadioOption {
  value: string
  label: string
}

interface RadioGroupProps {
  name: string
  value: string
  options: RadioOption[]
  onChange: (v: string) => void
  className?: string
  columns?: 2 | 3
}

export function RadioGroup({ name, value, options, onChange, className, columns = 2 }: RadioGroupProps) {
  return (
    <div className={cn('grid gap-3', columns === 2 ? 'grid-cols-2' : 'grid-cols-3', className)}>
      {options.map((opt) => {
        const checked = opt.value === value
        return (
          <label
            key={opt.value}
            className="inline-flex items-center gap-2 cursor-pointer select-none text-sm text-gray-800"
          >
            <span
              className={cn(
                'relative inline-flex h-4 w-4 items-center justify-center rounded-full border-2 transition-colors',
                checked ? 'border-primary' : 'border-gray-300'
              )}
            >
              {checked && <span className="h-2 w-2 rounded-full bg-primary" />}
            </span>
            <input
              type="radio"
              name={name}
              className="sr-only"
              checked={checked}
              onChange={() => onChange(opt.value)}
            />
            {opt.label}
          </label>
        )
      })}
    </div>
  )
}
