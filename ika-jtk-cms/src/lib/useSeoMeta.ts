import { useEffect } from 'react'

export function useSeoMeta({
  title,
  description,
  tags,
}: {
  title?: string
  description?: string
  tags?: string
}) {
  useEffect(() => {
    const origTitle = document.title
    if (title) {
      document.title = `${title} | IKA JTK`
    }

    const setMetaTag = (nameAttr: string, nameValue: string, content?: string) => {
      if (!content) return null
      let el = document.querySelector(`meta[${nameAttr}="${nameValue}"]`) as HTMLMetaElement | null
      if (!el) {
        el = document.createElement('meta')
        el.setAttribute(nameAttr, nameValue)
        document.head.appendChild(el)
      }
      el.setAttribute('content', content)
      return el
    }

    setMetaTag('name', 'keywords', tags)
    setMetaTag('name', 'description', description)
    setMetaTag('property', 'og:title', title)
    setMetaTag('property', 'og:description', description)
    setMetaTag('property', 'og:tags', tags)
    setMetaTag('property', 'article:tag', tags)

    return () => {
      if (title) document.title = origTitle
    }
  }, [title, description, tags])
}
