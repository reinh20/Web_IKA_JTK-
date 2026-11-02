export type BeritaStatus = 'Published' | 'Draft' | 'Archived' | 'Submission' | 'Rejected'

export interface BeritaAuthor {
  id: string
  nama: string
  role: 'Admin' | 'Anggota' | 'Super Admin' | 'Alumni'
  avatarUrl: string
}

export interface Berita {
  id: string
  noBerita: string
  judul: string
  konten: string
  kategori: string
  tags?: string
  bannerUrl: string | null
  bannerThumbnailUrl: string | null
  author: BeritaAuthor
  status: BeritaStatus
  createdAt: string
  publishedAt: string | null
}
