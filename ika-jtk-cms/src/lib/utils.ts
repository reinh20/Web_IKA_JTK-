import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(input: string | Date | undefined | null) {
  if (!input) return '-'
  const d = typeof input === 'string' ? new Date(input) : input
  if (Number.isNaN(d.getTime())) return '-'
  return d.toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}

export function formatDateTime(input: string | Date | undefined | null) {
  if (!input) return '-'
  const d = typeof input === 'string' ? new Date(input) : input
  if (Number.isNaN(d.getTime())) return '-'
  const dateStr = d.toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
  const timeStr = d.toLocaleTimeString('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).replace('.', ':')
  return `${dateStr}, ${timeStr}`
}

export function getAvatarUrl(avatarUrl: string | undefined | null, name: string = 'User') {
  if (avatarUrl && !avatarUrl.startsWith('http') && !avatarUrl.startsWith('data:') && !avatarUrl.startsWith('blob:')) {
    const baseUrl = (import.meta.env.VITE_API_URL || 'http://localhost:5000/api').replace(/\/api$/, '');
    const normalizedAvatarUrl = avatarUrl.startsWith('/') ? avatarUrl : `/${avatarUrl}`;
    return `${baseUrl}${normalizedAvatarUrl}`;
  }
  if (avatarUrl) {
    return avatarUrl;
  }
  return `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=random`;
}

export function getThumbnailUrl(avatarUrl: string | undefined | null, name: string = 'User') {
  const url = getAvatarUrl(avatarUrl, name);
  if (url.includes('ui-avatars.com') || url.startsWith('data:') || url.startsWith('blob:')) return url;
  
  // Format thumbnail backend: baseName_thumb.ext
  // Contoh: /avatar/1234.jpg -> /avatar/1234_thumb.jpg
  const lastDotIndex = url.lastIndexOf('.');
  if (lastDotIndex !== -1 && url.length - lastDotIndex <= 5) {
    const withoutExt = url.substring(0, lastDotIndex);
    if (!withoutExt.endsWith('_thumb')) {
      return `${withoutExt}_thumb${url.substring(lastDotIndex)}`;
    }
  }
  return url;
}

export function getFileUrl(fileUrl: any) {
  if (!fileUrl) return ''
  let urlStr = fileUrl
  if (typeof fileUrl === 'object') {
    urlStr = fileUrl.url || (fileUrl.data && fileUrl.data.url) || ''
  }
  urlStr = String(urlStr || '').trim()
  if (!urlStr || urlStr === '[object Object]') return ''
  if (!urlStr.startsWith('http') && !urlStr.startsWith('data:') && !urlStr.startsWith('blob:')) {
    const baseUrl = (import.meta.env.VITE_API_URL || 'http://localhost:5000/api').replace(/\/api$/, '')
    const normalizedFileUrl = urlStr.startsWith('/') ? urlStr : `/${urlStr}`
    return `${baseUrl}${normalizedFileUrl}`
  }
  return urlStr
}

export function stripHtml(html: string | undefined | null) {
  if (!html) return ''
  const doc = new DOMParser().parseFromString(html, 'text/html')
  return doc.body.textContent || ''
}
