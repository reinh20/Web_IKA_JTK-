export type Visibility = 'private' | 'public'

export type MembershipType = 'Executive' | 'Advisory Board' | 'Supervisory Board' | 'Alumni'

export const AlumniStatus = {
  UNVERIFIED: 'UNVERIFIED',
  PENDING: 'PENDING',
  APPROVED: 'APPROVED',
  ACTIVE: 'ACTIVE',
  INACTIVE: 'INACTIVE',
  REJECTED: 'REJECTED',
} as const

export type AlumniStatus = typeof AlumniStatus[keyof typeof AlumniStatus]
export type Gender = 'Laki-laki' | 'Perempuan'

export interface Pekerjaan {
  id: string
  pekerjaan: string
  perusahaan: string
  bulanMulai: string
  tahunMulai: string
  bulanSelesai: string
  tahunSelesai: string
  masihBekerja: boolean
  isGrafis?: boolean
}

export interface AlumniGrafisRequest {
  id: string
  alumniId: string
  kategori: string
  grafisId: string
  status: string
  createdAt: string
  alumni: {
    id: string
    nama: string
    angkatan: string
    avatarUrl?: string
  }
  detail?: any
}

export interface Prestasi {
  id: string
  judul: string
  tahun: string
  buktiUrl?: string
  isGrafis?: boolean
}

export interface Alumni {
  id: string
  noAlumni: string
  nama: string
  avatarUrl: string | null
  angkatan: number
  keanggotaan: MembershipType
  status: AlumniStatus
  tanggalLahir: string | null
  motto: string
  jenisKelamin: Gender | null
  nomorIjazah?: string
  tahunLulus?: number | null
  ipk?: string | number | null
  ijazahFile?: string | null

  email: string
  emailVisibility: Visibility
  emailVerified?: boolean
  nomorHandphone: string
  nomorHandphoneVisibility: Visibility
  phoneVerified?: boolean
  linkedin: string
  alamat: string
  alamatVisibility: Visibility

  pekerjaan: Pekerjaan[]
  prestasi: Prestasi[]

  username?: string
  alumniGrafis?: any
  diterimaPada?: string | null
  createdAt: string
  userAgreement?: boolean
}
