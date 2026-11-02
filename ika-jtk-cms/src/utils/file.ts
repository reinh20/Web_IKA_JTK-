export function formatFileName(url: string | null | undefined): string {
  if (!url) return ''
  const parts = url.split('/')
  const lastPart = parts[parts.length - 1]
  if (lastPart.includes('___')) {
    const splitByUnderscore = lastPart.split('___')
    return splitByUnderscore[splitByUnderscore.length - 1]
  }
  return lastPart
}
