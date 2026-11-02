import { forwardRef, useState } from 'react'
import type { InputHTMLAttributes } from 'react'
import { Eye, EyeOff } from 'lucide-react'
import { cn } from '@/lib/utils'

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  error?: string
  noSpaces?: boolean
}

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { className, error, type, noSpaces, ...rest },
  ref
) {
  const [showPassword, setShowPassword] = useState(false)
  const isPassword = type === 'password'
  const inputType = isPassword ? (showPassword ? 'text' : 'password') : type
  const disallowSpaces = noSpaces || isPassword || type === 'email'

  return (
    <div className="w-full">
      <div className="relative">
        <input
          ref={ref}
          type={inputType}
          className={cn(
            'block w-full rounded-md border bg-white px-3 h-10 text-sm text-gray-900 placeholder-gray-400',
            'focus:outline-none focus:ring-2',
            error
              ? 'border-danger focus:ring-danger/30 focus:border-danger'
              : 'border-gray-300 focus:ring-primary/30 focus:border-primary',
            'disabled:bg-gray-50 disabled:cursor-not-allowed',
            isPassword && 'pr-10',
            className
          )}
          {...rest}
          onChange={(e) => {
            if (disallowSpaces && /\s/.test(e.target.value)) {
              e.target.value = e.target.value.replace(/\s/g, '')
            }
            rest.onChange?.(e)
          }}
          onKeyDown={(e) => {
            if (disallowSpaces && (e.key === ' ' || e.code === 'Space' || e.keyCode === 32)) {
              e.preventDefault()
            }
            rest.onKeyDown?.(e)
          }}
          onInput={(e) => {
            if (disallowSpaces) {
              e.currentTarget.value = e.currentTarget.value.replace(/\s/g, '')
            }
            rest.onInput?.(e)
          }}
          onPaste={(e) => {
            if (disallowSpaces) {
              const pasteData = e.clipboardData.getData('text')
              if (/\s/.test(pasteData)) {
                e.preventDefault()
                const cleanData = pasteData.replace(/\s/g, '')
                document.execCommand('insertText', false, cleanData)
              }
            }
            rest.onPaste?.(e)
          }}
        />
        {isPassword && (
          <button
            type="button"
            className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 focus:outline-none"
            onClick={() => setShowPassword(!showPassword)}
            tabIndex={-1}
          >
            {showPassword ? (
              <EyeOff className="h-4 w-4" />
            ) : (
              <Eye className="h-4 w-4" />
            )}
          </button>
        )}
      </div>
      {error && <p className="mt-1 text-xs text-danger">{error}</p>}
    </div>
  )
})

interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  error?: string
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  function Textarea({ className, error, ...rest }, ref) {
    return (
      <div className="w-full">
        <textarea
          ref={ref}
          className={cn(
            'block w-full rounded-md border bg-white px-3 py-2 text-sm text-gray-900 placeholder-gray-400',
            'focus:outline-none focus:ring-2',
            error
              ? 'border-danger focus:ring-danger/30 focus:border-danger'
              : 'border-gray-300 focus:ring-primary/30 focus:border-primary',
            'disabled:bg-gray-50 disabled:cursor-not-allowed',
            className
          )}
          {...rest}
        />
        {error && <p className="mt-1 text-xs text-danger">{error}</p>}
      </div>
    )
  }
)

interface LabelProps extends React.LabelHTMLAttributes<HTMLLabelElement> {
  required?: boolean
}

export function Label({ className, required, children, ...rest }: LabelProps) {
  return (
    <label
      className={cn('block text-sm font-medium text-gray-800 mb-1.5', className)}
      {...rest}
    >
      {children}
      {required && <span className="text-danger ml-0.5">*</span>}
    </label>
  )
}
