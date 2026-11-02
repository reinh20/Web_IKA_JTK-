export type ElectionStatus = 'Draft' | 'Active' | 'Ongoing' | 'Completed' | 'Closed'

export interface ProgramKerjaItem {
  title: string
  description: string
}

export interface PrestasiItem {
  text: string
  year: string
}

export interface Kandidat {
  id: string
  nomorUrut: number
  nama: string
  angkatan: number
  fotoUrl: string
  visi: string
  misi: string[]
  pengalaman: string[]
  programKerja: ProgramKerjaItem[]
  prestasi: PrestasiItem[]
  tagline: string
  voteCount: number
}

export interface Election {
  id: string
  judul: string
  deskripsi: string
  periodeStart: string
  periodeEnd: string
  kandidatStart?: string
  kandidatEnd?: string
  pengumumanDate?: string
  pelantikanDate?: string
  status: ElectionStatus
  hideStatistik?: number | boolean
  totalVoter: number
  totalSuara: number
  totalAlumniTerdaftar?: number
  kandidat: Kandidat[]
  createdAt: string
}
