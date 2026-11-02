import { useNavigate, useParams, Navigate } from 'react-router-dom'
import { useState, useEffect } from 'react'
import { Pencil, Trash2, Send, ArchiveRestore, Check, X, Archive } from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { useAuthStore } from '@/stores/authStore'
import { formatDateTime, getAvatarUrl, getFileUrl } from '@/lib/utils'
import { useSeoMeta } from '@/lib/useSeoMeta'
import type { Berita, BeritaStatus } from '@/types/berita'

function StatusBadge({ status, isSubmission }: { status: BeritaStatus, isSubmission?: boolean }) {
  if (isSubmission) return <Badge variant="blue">Submission</Badge>
  if (status === 'Published') return <Badge variant="green">Published</Badge>
  if (status === 'Draft') return <Badge variant="orange">Draft</Badge>
  if (status === 'Archived') return <Badge variant="gray">Archived</Badge>
  if (status === 'Rejected') return <Badge variant="red">Rejected</Badge>
  return <Badge variant="blue">{status}</Badge>
}

export function BeritaDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const canEdit = user?.permissions?.includes('berita_edit') ?? false
  const [berita, setBerita] = useState<Berita | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useSeoMeta({
    title: berita?.judul,
    description: berita?.konten ? berita.konten.replace(/<[^>]+>/g, '').slice(0, 160) : undefined,
    tags: berita?.tags,
  })

  const [confirmDelete, setConfirmDelete] = useState(false)
  const [confirmReject, setConfirmReject] = useState(false)
  const [confirmPublish, setConfirmPublish] = useState(false)
  const [confirmDraft, setConfirmDraft] = useState(false)
  const [confirmArchive, setConfirmArchive] = useState(false)

  const fetchBerita = async () => {
    try {
      setIsLoading(true)
      const res = await api.get(`/admin/berita/${id}`)
      setBerita(res.data)
    } catch (error) {
      toast('Gagal memuat berita', 'error')
      navigate('/admin/berita')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchBerita()
  }, [id])

  if (isLoading) {
    return <div className="p-10">Loading...</div>
  }

  if (!berita) {
    return <Navigate to="/admin/berita" replace />
  }

  const handleDelete = async () => {
    setConfirmDelete(false)
    try {
      await api.delete(`/admin/berita/${id}`)
      toast(`Berita berhasil dihapus`, 'success')
      navigate('/admin/berita')
    } catch (error) {
      toast('Gagal menghapus berita', 'error')
    }
  }

  const handlePublish = async () => {
    setConfirmPublish(false)
    try {
      await api.put(`/admin/berita/${id}`, { ...berita, status: 'Published' })
      toast(`Berita berhasil dipublish`, 'success')
      fetchBerita()
    } catch (error) {
      toast('Gagal publish berita', 'error')
    }
  }

  const handleSetDraft = async () => {
    setConfirmDraft(false)
    try {
      await api.put(`/admin/berita/${id}`, { ...berita, status: 'Draft' })
      toast(`Berita dipindahkan ke Draft`, 'info')
      fetchBerita()
    } catch (error) {
      toast('Gagal set draft', 'error')
    }
  }

  const handleArchive = async () => {
    setConfirmArchive(false)
    try {
      await api.put(`/admin/berita/${id}`, { ...berita, status: 'Archived' })
      toast(`Berita diarsipkan`, 'info')
      fetchBerita()
    } catch (error) {
      toast('Gagal mengarsipkan berita', 'error')
    }
  }

  const handleAccept = async () => {
    try {
      await api.post(`/admin/berita/${id}/approve`)
      toast(`Berita berhasil disetujui dan dipublish`, 'success')
      fetchBerita()
    } catch (error) {
      toast('Gagal terima berita', 'error')
    }
  }

  const handleReject = async () => {
    setConfirmReject(false)
    try {
      await api.post(`/admin/berita/${id}/reject`)
      toast(`Submission ditolak`, 'info')
      fetchBerita()
    } catch (error) {
      toast('Gagal menolak submission', 'error')
    }
  }

  const isSubmission = berita.status === 'Submission'

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Berita', to: '/admin/berita' },
          { label: isSubmission ? 'Detail Submission' : 'Detail Berita' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">
        {isSubmission ? 'Detail Submission' : 'Detail Berita'}
      </h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6 items-start">
        <article className="bg-white rounded-lg border border-gray-200 shadow-sm p-8 min-w-0">
          <h2 className="text-2xl font-bold text-gray-900 leading-tight break-words">
            {berita.judul}
          </h2>
          <div className="mt-2 flex items-center gap-2 text-sm text-gray-500">
            <span className="inline-block h-3.5 w-3.5">📅</span>
            Diposting pada {formatDateTime(berita.createdAt)}
          </div>
          {berita.bannerUrl && (
            <img
              src={getFileUrl(berita.bannerUrl)}
              alt={berita.judul}
              className="mt-6 w-full rounded-md object-cover aspect-[16/9] bg-gray-100"
            />
          )}
          <div
            className="rich-content mt-6 text-[15px] leading-relaxed text-gray-700 break-words"
            dangerouslySetInnerHTML={{ __html: berita.konten }}
          />
        </article>

        <aside className="lg:sticky lg:top-8 space-y-6">
          <SectionCard title="Detail Berita">
            <dl className="space-y-3 text-sm">
              <DetailRow label="Dibuat pada" value={formatDateTime(berita.createdAt)} />
              <DetailRow
                label="Dipublish pada"
                value={
                  berita.publishedAt ? (
                    formatDateTime(berita.publishedAt)
                  ) : (
                    <span className="text-gray-400 italic">Belum diposting</span>
                  )
                }
              />
              <div>
                <dt className="text-gray-500 mb-1.5">Author</dt>
                <dd className="flex items-center gap-2">
                  <img
                    src={getAvatarUrl(berita.author.avatarUrl, berita.author.nama)}
                    alt={berita.author.nama}
                    className="h-7 w-7 rounded-full object-cover bg-gray-200"
                  />
                  <div className="text-sm">
                    <div className="text-gray-900 font-medium leading-tight">
                      {berita.author.nama}
                    </div>
                    <div className="text-xs text-gray-500">{berita.author.role}</div>
                  </div>
                </dd>
              </div>
              <div>
                <dt className="text-gray-500 mb-1.5">Kategori</dt>
                <dd>
                  <Badge variant="gray">{berita.kategori || 'Berita'}</Badge>
                </dd>
              </div>
              <div>
                <dt className="text-gray-500 mb-1.5">Status</dt>
                <dd>
                  <StatusBadge status={berita.status} isSubmission={isSubmission} />
                </dd>
              </div>
              <div>
                <dt className="text-gray-500 mb-1.5">Tags (SEO)</dt>
                <dd className="flex flex-wrap gap-1">
                  {berita.tags && berita.tags.split(',').map((t) => t.trim()).filter(Boolean).length > 0 ? (
                    berita.tags
                      .split(',')
                      .map((t) => t.trim())
                      .filter(Boolean)
                      .map((t, idx) => (
                        <span key={idx} className="inline-block px-2 py-0.5 rounded bg-accent/10 text-accent text-xs font-medium">
                          {t}
                        </span>
                      ))
                  ) : (
                    <span className="text-gray-400 italic">Tidak ada tag</span>
                  )}
                </dd>
              </div>
            </dl>

            <div className="mt-6 pt-6 border-t border-gray-100 space-y-3">
              {isSubmission ? (
                <>
                  {canEdit && (
                    <Button className="w-full" onClick={handleAccept} leftIcon={<Check className="h-4 w-4" />}>
                      Terima Submission
                    </Button>
                  )}
                  {canEdit && (
                    <Button
                      variant="danger"
                      className="w-full"
                      onClick={() => setConfirmReject(true)}
                      leftIcon={<X className="h-4 w-4" />}
                    >
                      Tolak Submission
                    </Button>
                  )}
                </>
              ) : (
                <>
                  {(berita.status === 'Draft' || berita.status === 'Archived') && canEdit && (
                    <Button
                      className="w-full"
                      onClick={() => setConfirmPublish(true)}
                      leftIcon={<Send className="h-4 w-4" />}
                    >
                      Publish
                    </Button>
                  )}
                  {berita.status === 'Published' && canEdit && (
                    <Button
                      variant="outline"
                      className="w-full"
                      onClick={() => setConfirmDraft(true)}
                      leftIcon={<ArchiveRestore className="h-4 w-4" />}
                    >
                      Set as Draft
                    </Button>
                  )}
                  {berita.status !== 'Archived' && canEdit && (
                    <Button
                      variant="outline"
                      className="w-full"
                      onClick={() => setConfirmArchive(true)}
                      leftIcon={<Archive className="h-4 w-4" />}
                    >
                      Arsipkan
                    </Button>
                  )}
                  {canEdit && (
                    <Button
                      variant="outline"
                      className="w-full"
                      onClick={() => navigate(`/admin/berita/${berita.id}/edit`)}
                      leftIcon={<Pencil className="h-4 w-4" />}
                    >
                      Edit
                    </Button>
                  )}
                  {canEdit && (
                    <button
                      type="button"
                      onClick={() => setConfirmDelete(true)}
                      className="w-full inline-flex items-center justify-center gap-2 text-sm font-semibold text-danger hover:underline py-2"
                    >
                      <Trash2 className="h-4 w-4" />
                      Hapus
                    </button>
                  )}
                </>
              )}
            </div>
          </SectionCard>
        </aside>
      </div>

      <ConfirmDialog
        open={confirmDelete}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-danger-bg text-danger">
            <Trash2 className="h-6 w-6" />
          </div>
        }
        title="Hapus Berita Ini?"
        description="Tindakan ini akan menghapus berita secara permanen dari sistem dan tidak dapat dibatalkan. Apakah Anda yakin ingin melanjutkan?"
        confirmLabel="Hapus"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleDelete}
        onCancel={() => setConfirmDelete(false)}
      />

      <ConfirmDialog
        open={confirmReject}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-danger-bg text-danger">
            <X className="h-6 w-6" />
          </div>
        }
        title="Tolak Submission?"
        description="Submission berita akan ditolak dan dihapus dari sistem. Tindakan ini tidak dapat dibatalkan."
        confirmLabel="Tolak"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleReject}
        onCancel={() => setConfirmReject(false)}
      />

      <ConfirmDialog
        open={confirmPublish}
        title="Publish Berita?"
        description="Berita akan langsung tampil di website portal alumni."
        confirmLabel="Publish"
        cancelLabel="Batal"
        onConfirm={handlePublish}
        onCancel={() => setConfirmPublish(false)}
      />

      <ConfirmDialog
        open={confirmDraft}
        title="Set Sebagai Draft?"
        description="Berita akan dikembalikan ke status Draft dan tidak tampil di website hingga di-publish ulang."
        confirmLabel="Set as Draft"
        cancelLabel="Batal"
        onConfirm={handleSetDraft}
        onCancel={() => setConfirmDraft(false)}
      />

      <ConfirmDialog
        open={confirmArchive}
        title="Arsipkan Berita?"
        description="Berita akan diarsipkan dan tidak akan tampil di website publik lagi."
        confirmLabel="Arsipkan"
        cancelLabel="Batal"
        onConfirm={handleArchive}
        onCancel={() => setConfirmArchive(false)}
      />
    </div>
  )
}

function DetailRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div>
      <dt className="text-gray-500 text-xs mb-0.5">{label}</dt>
      <dd className="text-gray-900 text-sm">{value}</dd>
    </div>
  )
}
