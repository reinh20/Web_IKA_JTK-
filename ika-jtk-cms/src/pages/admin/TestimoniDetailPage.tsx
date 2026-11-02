import { Navigate, useNavigate, useParams } from 'react-router-dom'
import { useState, useEffect } from 'react'
import { Quote, Check, X, Trash2, AlertTriangle } from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { Modal } from '@/components/ui/Modal'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { useAuthStore } from '@/stores/authStore'
import { formatDate, getAvatarUrl } from '@/lib/utils'
import type { Testimoni, TestimoniStatus } from '@/types/testimoni'

function StatusBadge({ status }: { status: TestimoniStatus }) {
  if (status === 'Published') return <Badge variant="green">Published</Badge>
  if (status === 'Pending') return <Badge variant="orange">Pending</Badge>
  return <Badge variant="red">Rejected</Badge>
}

export function TestimoniDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const user = useAuthStore((s) => s.user)
  const canEdit = user?.permissions?.includes('testimoni_edit') ?? false
  const [testi, setTesti] = useState<Testimoni | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const [confirmApprove, setConfirmApprove] = useState(false)
  const [confirmReject, setConfirmReject] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [rejectReason, setRejectReason] = useState('')
  const [isSaving, setIsSaving] = useState(false)

  const fetchTesti = async () => {
    try {
      setIsLoading(true)
      const res = await api.get(`/admin/testimoni/${id}`)
      setTesti(res.data)
    } catch (error) {
      toast('Gagal memuat testimoni', 'error')
      navigate('/admin/testimoni')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchTesti()
  }, [id])

  if (isLoading) return <div className="p-10">Loading...</div>

  if (!testi) return <Navigate to="/admin/testimoni" replace />

  const handleApprove = async () => {
    setConfirmApprove(false)
    try {
      await api.put(`/admin/testimoni/${id}`, { ...testi, status: 'Published', reviewedAt: new Date().toISOString() })
      toast(`Testimoni dari "${testi.alumniNama}" berhasil dipublish`, 'success')
      fetchTesti()
    } catch (error) {
      toast('Gagal mempublish testimoni', 'error')
    }
  }
  const handleReject = async (e?: React.FormEvent) => {
    if (e) e.preventDefault()
    setIsSaving(true)
    const isPublished = testi.status === 'Published'
    try {
      const res = await api.put(`/admin/testimoni/${id}`, { 
        ...testi, 
        status: 'Rejected', 
        rejectReason: rejectReason,
        reviewedAt: new Date().toISOString() 
      })
      if (res.data?.message === 'deleted') {
        toast('Testimoni dihapus setelah 3 kali penolakan', 'info')
        navigate('/admin/testimoni')
        return
      }
      toast(isPublished ? 'Testimoni diarsipkan' : 'Testimoni ditolak', 'info')
      fetchTesti()
    } catch (error) {
      toast(isPublished ? 'Gagal mengarsipkan testimoni' : 'Gagal menolak testimoni', 'error')
    } finally {
      setIsSaving(false)
      setConfirmReject(false)
      setRejectReason('')
    }
  }
  const handleDelete = async () => {
    setConfirmDelete(false)
    try {
      await api.delete(`/admin/testimoni/${id}`)
      toast('Testimoni berhasil dihapus', 'success')
      navigate('/admin/testimoni')
    } catch (error) {
      toast('Gagal menghapus testimoni', 'error')
    }
  }

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Testimoni', to: '/admin/testimoni' },
          { label: 'Detail Testimoni' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">Detail Testimoni</h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6 items-start">
        <div className="bg-white rounded-lg border border-gray-200 shadow-sm p-8">
          <div className="flex items-center gap-4 mb-6">
            <img
              src={getAvatarUrl(testi.alumniAvatarUrl, testi.alumniNama)}
              alt={testi.alumniNama}
              className="h-16 w-16 rounded-full object-cover bg-gray-200"
            />
            <div>
              <h2 className="text-xl font-bold text-gray-900">{testi.alumniNama}</h2>
              <p className="text-sm text-gray-500">Angkatan {testi.alumniAngkatan}</p>
            </div>
          </div>

          <div className="relative">
            <Quote className="absolute -top-2 -left-2 h-8 w-8 text-accent/20" />
            <blockquote className="pl-8 text-lg text-gray-700 leading-relaxed italic">
              {testi.isi}
            </blockquote>
          </div>
        </div>

        <aside className="lg:sticky lg:top-8 space-y-6">
          <SectionCard title="Detail Testimoni">
            <dl className="space-y-3 text-sm">
              <div>
                <dt className="text-gray-500 text-xs mb-0.5">Submitted pada</dt>
                <dd className="text-gray-900">{formatDate(testi.createdAt ?? testi.submittedAt)}</dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs mb-0.5">Reviewed pada</dt>
                <dd className="text-gray-900">
                  {testi.reviewedAt ? (
                    formatDate(testi.reviewedAt)
                  ) : (
                    <span className="text-gray-400 italic">Belum direview</span>
                  )}
                </dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs mb-1.5">Visibility</dt>
                <dd>
                  <Badge variant={testi.visibility === 'public' ? 'blue' : 'gray'}>
                    {testi.visibility === 'public' ? 'Public' : 'Private'}
                  </Badge>
                </dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs mb-1.5">Status</dt>
                <dd>
                  <StatusBadge status={testi.status} />
                </dd>
              </div>
              {(testi.rejectCount ?? 0) > 0 && (
                <div>
                  <dt className="text-gray-500 text-xs mb-1.5">Riwayat Penolakan</dt>
                  <dd className="flex items-center gap-2">
                    <span className={`text-sm font-semibold ${
                      (testi.rejectCount ?? 0) >= 3 ? 'text-danger' : (testi.rejectCount ?? 0) >= 2 ? 'text-orange-500' : 'text-gray-700'
                    }`}>
                      {testi.rejectCount}/3
                    </span>
                    <span className="text-xs text-gray-500">kali ditolak</span>
                    {(testi.rejectCount ?? 0) >= 2 && (
                      <span className="text-xs font-medium px-1.5 py-0.5 rounded bg-danger/10 text-danger">
                        {(testi.rejectCount ?? 0) >= 3 ? 'Batas maksimal tercapai' : '1 kesempatan tersisa'}
                      </span>
                    )}
                  </dd>
                </div>
              )}
            </dl>

            <div className="mt-6 pt-6 border-t border-gray-100 space-y-3">
              {testi.status === 'Pending' && canEdit && (
                <>
                  <Button
                    className="w-full"
                    onClick={() => setConfirmApprove(true)}
                    leftIcon={<Check className="h-4 w-4" />}
                  >
                    Publish Testimoni
                  </Button>
                  <Button
                    variant="danger"
                    className="w-full"
                    onClick={() => (testi.rejectCount ?? 0) >= 3 ? setConfirmDelete(true) : setConfirmReject(true)}
                    leftIcon={(testi.rejectCount ?? 0) >= 3 ? <Trash2 className="h-4 w-4" /> : <X className="h-4 w-4" />}
                  >
                    {(testi.rejectCount ?? 0) >= 3 ? 'Hapus Testimoni' : 'Tolak Testimoni'}
                  </Button>
                </>
              )}
              {testi.status === 'Published' && canEdit && (
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={() => setConfirmReject(true)}
                >
                  Unpublish
                </Button>
              )}
              {testi.status === 'Rejected' && canEdit && (
                <Button className="w-full" onClick={() => setConfirmApprove(true)}>
                  Publish Ulang
                </Button>
              )}
              {canEdit && (
                <button
                  type="button"
                  onClick={() => setConfirmDelete(true)}
                  className="w-full inline-flex items-center justify-center gap-2 text-sm font-semibold text-danger hover:underline py-2"
                >
                  <Trash2 className="h-4 w-4" />
                  Hapus Testimoni
                </button>
              )}
            </div>
          </SectionCard>
        </aside>
      </div>

      <ConfirmDialog
        open={confirmApprove}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-success-bg text-success">
            <Check className="h-6 w-6" />
          </div>
        }
        title="Publish Testimoni Ini?"
        description="Testimoni akan tampil di halaman portal alumni dan dapat dilihat semua pengunjung."
        confirmLabel="Publish"
        cancelLabel="Batal"
        onConfirm={handleApprove}
        onCancel={() => setConfirmApprove(false)}
      />

      <Modal open={confirmReject} onClose={() => setConfirmReject(false)}>
        <form onSubmit={handleReject} className="p-6">
          <div className="mb-4 inline-flex h-12 w-12 items-center justify-center rounded-full bg-accent-light text-accent">
            {(testi.rejectCount ?? 0) >= 3 ? <Trash2 className="h-6 w-6 text-danger" /> : <AlertTriangle className="h-6 w-6" />}
          </div>
          <h3 className="text-lg font-bold text-gray-900">
            {testi.status === 'Published' ? 'Arsipkan Testimoni Ini?' : 
             (testi.rejectCount ?? 0) >= 3 ? 'Tolak & Hapus Testimoni?' : 'Tolak Testimoni Ini?'}
          </h3>
          <div className="mt-2 text-sm text-gray-600 leading-relaxed">
            {(testi.rejectCount ?? 0) >= 3
              ? <span className="text-danger font-medium">⚠ Alumni ini sudah ditolak 3 kali. Penolakan ke-4 ini akan <strong>menghapus permanen</strong> testimoninya dari sistem.</span>
              : 'Testimoni tidak akan tampil di portal. Anda dapat mengubah statusnya kembali kapan saja.'}
          </div>
          
          <div className="mt-4">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Alasan Penolakan <span className="text-danger">*</span>
            </label>
            <textarea
              required
              className="w-full rounded-md border border-gray-300 p-2 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary min-h-[100px]"
              placeholder="Testimoni belum memenuhi ketentuan. Silakan lakukan perbaikan pada isi testimoni dan ajukan kembali."
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
            />
          </div>

          <div className="mt-6 flex items-center gap-3">
            <Button
              type="submit"
              variant="accent"
              loading={isSaving}
              disabled={!rejectReason.trim()}
            >
              {testi.status === 'Published' ? 'Arsipkan' : 'Tolak'}
            </Button>
            <Button type="button" variant="ghost" onClick={() => { setConfirmReject(false); setRejectReason(''); }} disabled={isSaving}>
              Batal
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={confirmDelete}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-danger-bg text-danger">
            <Trash2 className="h-6 w-6" />
          </div>
        }
        title="Hapus Testimoni Ini?"
        description="Testimoni akan dihapus permanen dari sistem dan tidak dapat dipulihkan."
        confirmLabel="Hapus"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleDelete}
        onCancel={() => setConfirmDelete(false)}
      />
    </div>
  )
}
