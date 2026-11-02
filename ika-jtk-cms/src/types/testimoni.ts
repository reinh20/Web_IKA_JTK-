export type TestimoniStatus = 'Pending' | 'Published' | 'Rejected'
export type TestimoniVisibility = 'public' | 'private'

export interface Testimoni {
  id: string
  alumniId: string
  alumniNama: string
  alumniAngkatan: string
  alumniAvatarUrl: string
  isi: string
  visibility: TestimoniVisibility
  status: TestimoniStatus
  createdAt: string
  rejectReason?: string
  rejectCount?: number
  /** @deprecated backend renamed submittedAt -> createdAt; kept for back-compat */
  submittedAt?: string
  reviewedAt: string | null
}
