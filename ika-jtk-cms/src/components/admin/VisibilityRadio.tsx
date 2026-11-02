import { Label } from '@/components/ui/Input'
import type { Visibility } from '@/types/alumni'

interface VisibilityRadioProps {
  label: string
  value: Visibility
  onChange: (v: Visibility) => void
}

export function VisibilityRadio({ label, value, onChange }: VisibilityRadioProps) {
  const isPublic = value === 'public'
  return (
    <div className="flex items-center justify-between py-3">
      <Label className="m-0 text-gray-700">{label}</Label>
      <div className="flex items-center gap-3">
        <span className={`text-sm font-medium ${isPublic ? 'text-primary' : 'text-gray-500'}`}>
          {isPublic ? 'Publik' : 'Privat'}
        </span>
        <button
          type="button"
          role="switch"
          aria-checked={isPublic}
          onClick={() => onChange(isPublic ? 'private' : 'public')}
          className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 ${
            isPublic ? 'bg-primary' : 'bg-gray-300'
          }`}
        >
          <span className="sr-only">Toggle {label}</span>
          <span
            aria-hidden="true"
            className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
              isPublic ? 'translate-x-5' : 'translate-x-0'
            }`}
          />
        </button>
      </div>
    </div>
  )
}
