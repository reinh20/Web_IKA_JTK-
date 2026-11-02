import type { BeritaAuthor } from './berita'

export type LokerStatus = 'Published' | 'Draft' | 'Archived' | 'Submission' | 'Rejected'

export type JenisPekerjaan = 'Full Time' | 'Part Time' | 'Kontrak' | 'Magang' | 'Freelance'

export type TipeLokasi = 'Onsite' | 'Remote' | 'Hybrid'

export type SkemaPelamaran = 'internal' | 'external'

export type FormFieldType = 'text' | 'number' | 'option' | 'longtext' | 'file'

export interface FormLamaranField {
  id: string
  label: string
  tipe: FormFieldType
  options?: string[]
  required?: boolean
  defaultValue?: string
  fileUrl?: string
  fileName?: string
}

export interface Pelamar {
  id: string
  noAlumni: string
  nama: string
  angkatan: number
  email: string
  tanggalPelamar: string
  keanggotaan: 'Executive' | 'Advisory Board' | 'Supervisory Board' | 'Alumni'
  avatarUrl: string
  jawaban?: Record<string, any>
  status: string
}

export interface Loker {
  id: string
  noLoker: string
  posisi: string
  namaPerusahaan: string
  websitePerusahaan: string
  logoUrl: string | null
  logoThumbnailUrl?: string | null
  tags?: string
  jenisPekerjaan: JenisPekerjaan
  tipeLokasi: TipeLokasi
  kota: string
  deskripsi: string
  skemaPelamaran: SkemaPelamaran
  linkExternal: string
  formLamaran: FormLamaranField[]
  author: BeritaAuthor
  status: LokerStatus
  createdAt: string
  publishedAt: string | null
  pelamar: Pelamar[]
}
