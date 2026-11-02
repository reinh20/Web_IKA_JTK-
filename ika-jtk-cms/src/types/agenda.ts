import type { BeritaAuthor } from './berita'

export type AgendaStatus = 'Published' | 'Draft' | 'Archived' | 'Submission' | 'Rejected'

export interface Agenda {
  id: string
  noEvent: string
  judul: string
  deskripsi: string
  tags?: string
  bannerUrl: string | null
  bannerThumbnailUrl: string | null
  tanggalEvent: string
  waktu: string
  lokasi: string
  author: BeritaAuthor
  status: AgendaStatus
  createdAt: string
  publishedAt: string | null
  peserta?: any[]
}
