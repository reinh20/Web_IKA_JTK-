import { useState, useRef, type KeyboardEvent } from 'react'
import { X, Tag as TagIcon } from 'lucide-react'

interface TagInputProps {
  value: string
  onChange: (value: string) => void
  placeholder?: string
  label?: string
  className?: string
}

export function TagInput({
  value,
  onChange,
  placeholder = 'Ketik tag lalu tekan Koma (,) atau Enter...',
  className = '',
}: TagInputProps) {
  const [inputValue, setInputValue] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)

  // Split comma separated freetext into array of individual tags
  const tags = value
    ? value
        .split(',')
        .map((t) => t.trim())
        .filter(Boolean)
    : []

  const addTag = (tagText: string) => {
    const trimmed = tagText.trim().replace(/,/g, '')
    if (!trimmed) return

    // Avoid duplicates if already present (case insensitive check)
    if (tags.some((t) => t.toLowerCase() === trimmed.toLowerCase())) {
      setInputValue('')
      return
    }

    const newTags = [...tags, trimmed]
    onChange(newTags.join(', '))
    setInputValue('')
  }

  const removeTag = (indexToRemove: number) => {
    const newTags = tags.filter((_, index) => index !== indexToRemove)
    onChange(newTags.join(', '))
  }

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === ',' || e.key === 'Enter') {
      e.preventDefault()
      addTag(inputValue)
    } else if (e.key === 'Backspace' && !inputValue && tags.length > 0) {
      removeTag(tags.length - 1)
    }
  }

  const handleBlur = () => {
    if (inputValue.trim()) {
      addTag(inputValue)
    }
  }

  return (
    <div className={`w-full ${className}`}>
      <div
        onClick={() => inputRef.current?.focus()}
        className="min-h-[42px] p-1.5 flex flex-wrap items-center gap-1.5 w-full rounded-lg border border-gray-300 bg-white text-sm focus-within:border-accent focus-within:ring-1 focus-within:ring-accent transition-colors cursor-text shadow-sm"
      >
        <TagIcon className="h-4 w-4 text-gray-400 ml-1.5 mr-0.5 shrink-0" />
        {tags.map((tag, idx) => (
          <span
            key={idx}
            className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md bg-accent/10 border border-accent/20 text-accent font-medium text-xs shadow-2xs transition-all hover:bg-accent/15"
          >
            <span>{tag}</span>
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation()
                removeTag(idx)
              }}
              className="text-accent/70 hover:text-accent hover:bg-accent/20 rounded-sm p-0.5 transition-colors focus:outline-none"
              title="Hapus tag"
            >
              <X className="h-3 w-3" />
            </button>
          </span>
        ))}
        <input
          ref={inputRef}
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyDown={handleKeyDown}
          onBlur={handleBlur}
          placeholder={tags.length === 0 ? placeholder : 'Ketik tag lain...'}
          className="flex-1 min-w-[140px] border-none bg-transparent py-1 px-2 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-0"
        />
      </div>
      <p className="mt-1.5 text-xs text-gray-500 flex items-center gap-1">
        <span>💡 Tips: Ketik kata kunci lalu tekan <kbd className="px-1 py-0.5 bg-gray-100 border rounded text-[10px] font-mono">Koma (,)</kbd> atau <kbd className="px-1 py-0.5 bg-gray-100 border rounded text-[10px] font-mono">Enter</kbd> untuk menambahkan tag. Disimpan otomatis sebagai freetext dengan pemisah koma.</span>
      </p>
    </div>
  )
}
