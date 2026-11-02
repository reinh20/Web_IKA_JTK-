import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { MoreVertical } from 'lucide-react'
import { cn } from '@/lib/utils'

const VIEWPORT_PADDING = 8
const GAP = 4

type Props = {
  children: React.ReactNode
  width?: number
}

export function RowActionMenu({ children, width = 176 }: Props) {
  const [open, setOpen] = useState(false)
  const [coords, setCoords] = useState<{ top: number; left: number } | null>(
    null,
  )
  const triggerRef = useRef<HTMLButtonElement>(null)
  const menuRef = useRef<HTMLDivElement>(null)

  useLayoutEffect(() => {
    if (!open || !triggerRef.current) return
    const trigger = triggerRef.current.getBoundingClientRect()
    const menuHeight = menuRef.current?.offsetHeight ?? 200

    let left = trigger.right - width
    left = Math.max(VIEWPORT_PADDING, left)
    left = Math.min(window.innerWidth - width - VIEWPORT_PADDING, left)

    let top = trigger.bottom + GAP
    if (top + menuHeight > window.innerHeight - VIEWPORT_PADDING) {
      top = trigger.top - menuHeight - GAP
      if (top < VIEWPORT_PADDING) top = VIEWPORT_PADDING
    }
    setCoords({ top, left })
  }, [open, width])

  useEffect(() => {
    if (!open) return
    const onDown = (e: MouseEvent) => {
      if (
        menuRef.current?.contains(e.target as Node) ||
        triggerRef.current?.contains(e.target as Node)
      )
        return
      setOpen(false)
    }
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false)
    }
    const close = () => setOpen(false)
    document.addEventListener('mousedown', onDown)
    document.addEventListener('keydown', onKey)
    window.addEventListener('scroll', close, true)
    window.addEventListener('resize', close)
    return () => {
      document.removeEventListener('mousedown', onDown)
      document.removeEventListener('keydown', onKey)
      window.removeEventListener('scroll', close, true)
      window.removeEventListener('resize', close)
    }
  }, [open])

  return (
    <>
      <button
        ref={triggerRef}
        type="button"
        className={cn(
          'inline-flex h-8 w-8 items-center justify-center rounded hover:bg-gray-100',
          open && 'bg-gray-100',
        )}
        onClick={() => setOpen((o) => !o)}
        aria-label="Action"
        aria-haspopup="menu"
        aria-expanded={open}
      >
        <MoreVertical className="h-4 w-4 text-gray-500" />
      </button>
      {open &&
        createPortal(
          <div
            ref={menuRef}
            role="menu"
            className="fixed z-50 rounded-md border border-gray-200 bg-white shadow-lg py-1 text-left"
            style={{
              top: coords?.top ?? -9999,
              left: coords?.left ?? -9999,
              width,
              visibility: coords ? 'visible' : 'hidden',
            }}
            onClick={() => setOpen(false)}
          >
            {children}
          </div>,
          document.body,
        )}
    </>
  )
}
