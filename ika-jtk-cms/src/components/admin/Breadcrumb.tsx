import { Link } from 'react-router-dom'
import { Fragment } from 'react'

interface Crumb {
  label: string
  to?: string
}

interface BreadcrumbProps {
  items: Crumb[]
}

export function Breadcrumb({ items }: BreadcrumbProps) {
  return (
    <nav className="flex items-center text-xs font-bold tracking-wider text-primary">
      {items.map((c, i) => (
        <Fragment key={i}>
          {i > 0 && <span className="mx-2 text-gray-400">/</span>}
          {c.to ? (
            <Link to={c.to} className="hover:underline">
              {c.label.toUpperCase()}
            </Link>
          ) : (
            <span>{c.label.toUpperCase()}</span>
          )}
        </Fragment>
      ))}
    </nav>
  )
}
