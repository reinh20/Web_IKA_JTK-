import { useNavigate, useParams, Navigate } from 'react-router-dom'
import { useMemo, useState, useEffect } from 'react'
import { Pencil, Trash2, Send, ArchiveRestore, Check, X, Calendar, Clock, MapPin, Users, Search, Archive } from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { useAuthStore } from '@/stores/authStore'
import { formatDate, formatDateTime, getAvatarUrl, getFileUrl } from '@/lib/utils'
import { useSeoMeta } from '@/lib/useSeoMeta'
import type { Agenda, AgendaStatus } from '@/types/agenda'

function StatusBadge({ status }: { status: AgendaStatus }) {
  if (status === 'Published') return <Badge variant="green">Published</Badge>
  if (status === 'Draft') return <Badge variant="orange">Draft</Badge>
  if (status === 'Archived') return <Badge variant="gray">Archived</Badge>
  return <Badge variant="blue">Submission</Badge>
}

function formatTime(iso: string) {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return '-'
  return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
}

export function AgendaDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const canEdit = user?.permissions?.includes('agenda_edit') ?? false
  const [agenda, setAgenda] = useState<Agenda | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useSeoMeta({
    title: agenda?.judul,
    description: agenda?.deskripsi ? agenda.deskripsi.replace(/<[^>]+>/g, '').slice(0, 160) : undefined,
    tags: agenda?.tags,
  })

  const [confirmDelete, setConfirmDelete] = useState(false)
  const [confirmReject, setConfirmReject] = useState(false)
  const [confirmPublish, setConfirmPublish] = useState(false)
  const [confirmDraft, setConfirmDraft] = useState(false)
  const [confirmArchive, setConfirmArchive] = useState(false)
  const [pesertaQuery, setPesertaQuery] = useState('')

  const peserta = agenda?.peserta || []
  const filteredPeserta = useMemo(() => {
    const q = pesertaQuery.trim().toLowerCase()
    if (!q) return peserta
    return peserta.filter(
      (p: any) => 
        String(p.nama || '').toLowerCase().includes(q) || 
        String(p.angkatan || '').toLowerCase().includes(q)
    )
  }, [peserta, pesertaQuery])

  const fetchAgenda = async () => {
    try {
      setIsLoading(true)
      const res = await api.get(`/admin/agenda/${id}`)
      setAgenda(res.data)
    } catch (error) {
      toast('Gagal memuat agenda', 'error')
      navigate('/admin/agenda')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchAgenda()
  }, [id])

  if (isLoading) return <div className="p-10">Loading...</div>

  if (!agenda) return <Navigate to="/admin/agenda" replace />

  const handleDelete = async () => {
    setConfirmDelete(false)
    try {
      await api.delete(`/admin/agenda/${id}`)
      toast('Agenda berhasil dihapus', 'success')
      navigate('/admin/agenda')
    } catch (error) {
      toast('Gagal menghapus agenda', 'error')
    }
  }

  const handlePublish = async () => {
    setConfirmPublish(false)
    try {
      await api.put(`/admin/agenda/${id}`, { ...agenda, status: 'Published' })
      toast('Agenda berhasil dipublish', 'success')
      fetchAgenda()
    } catch (error) {
      toast('Gagal publish agenda', 'error')
    }
  }

  const handleSetDraft = async () => {
    setConfirmDraft(false)
    try {
      await api.put(`/admin/agenda/${id}`, { ...agenda, status: 'Draft' })
      toast('Agenda dipindahkan ke Draft', 'info')
      fetchAgenda()
    } catch (error) {
      toast('Gagal set draft', 'error')
    }
  }

  const handleArchive = async () => {
    setConfirmArchive(false)
    try {
      await api.put(`/admin/agenda/${id}`, { ...agenda, status: 'Archived' })
      toast('Agenda diarsipkan', 'info')
      fetchAgenda()
    } catch (error) {
      toast('Gagal mengarsipkan agenda', 'error')
    }
  }

  const handleAccept = async () => {
    try {
      await api.post(`/admin/agenda/${id}/approve`)
      toast('Agenda berhasil disetujui dan dipublish', 'success')
      fetchAgenda()
    } catch (error) {
      toast('Gagal terima agenda', 'error')
    }
  }

  const handleReject = async () => {
    setConfirmReject(false)
    try {
      await api.post(`/admin/agenda/${id}/reject`)
      toast('Submission ditolak', 'info')
      fetchAgenda()
    } catch (error) {
      toast('Gagal menolak submission', 'error')
    }
  }

  const isSubmission = agenda.status === 'Submission'

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Agenda', to: '/admin/agenda' },
          { label: isSubmission ? 'Detail Submission' : 'Detail Agenda' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">
        {isSubmission ? 'Detail Submission' : 'Detail Agenda'}
      </h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6 items-start">
        <article className="bg-white rounded-lg border border-gray-200 shadow-sm p-8 min-w-0">
          <h2 className="text-2xl font-bold text-gray-900 leading-tight">
            {agenda.judul}
          </h2>
          <div className="mt-2 flex items-center gap-2 text-sm text-gray-500">
            <Calendar className="h-3.5 w-3.5" />
            Diposting pada {formatDateTime(agenda.publishedAt || agenda.createdAt)}
          </div>
          {agenda.bannerUrl && (
            <img
              src={getFileUrl(agenda.bannerUrl)}
              alt={agenda.judul}
              className="mt-6 w-full rounded-md object-cover aspect-[16/9] bg-gray-100"
            />
          )}
          <div className="mt-6 grid grid-cols-1 sm:grid-cols-3 gap-3 p-4 rounded-md bg-gray-50 border border-gray-100">
            <InfoRow icon={<Calendar className="h-4 w-4" />} label="Tanggal" value={formatDate(agenda.tanggalEvent)} />
            <InfoRow icon={<Clock className="h-4 w-4" />} label="Waktu" value={`${formatTime(agenda.tanggalEvent)} (${agenda.waktu})`} />
            <InfoRow icon={<MapPin className="h-4 w-4" />} label="Lokasi" value={agenda.lokasi} />
          </div>
          <div
            className="rich-content mt-6 text-[15px] leading-relaxed text-gray-700 break-words"
            dangerouslySetInnerHTML={{ __html: agenda.deskripsi }}
          />

          {!isSubmission && (
            <div className="mt-8 pt-6 border-t border-gray-100">
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <div className="flex items-center gap-2">
                  <Users className="h-5 w-5 text-primary" />
                  <h3 className="text-lg font-bold text-gray-900">
                    Daftar Peserta
                  </h3>
                  <Badge variant="blue">{peserta.length}</Badge>
                </div>
                <div className="relative w-full sm:w-64">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <input
                    type="text"
                    value={pesertaQuery}
                    onChange={(e) => setPesertaQuery(e.target.value)}
                    placeholder="Cari nama / angkatan…"
                    className="w-full pl-9 pr-3 py-2 text-sm rounded-md border border-gray-200 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none"
                  />
                </div>
              </div>

              <div className="mt-3 text-sm text-gray-600">
                {peserta.length === 0
                  ? 'Belum ada peserta terdaftar'
                  : pesertaQuery.trim()
                    ? `Menampilkan ${filteredPeserta.length} dari ${peserta.length} peserta`
                    : `Total ${peserta.length} peserta`}
              </div>

              <div className="mt-4 overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="text-left text-xs text-gray-500 border-b border-gray-100">
                      <th className="py-2 font-medium">Nama</th>
                      <th className="py-2 font-medium">Angkatan</th>
                      <th className="py-2 font-medium">Mendaftar pada</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredPeserta.length === 0 ? (
                      <tr>
                        <td colSpan={3} className="py-6 text-center text-gray-400">
                          Tidak ada peserta yang cocok.
                        </td>
                      </tr>
                    ) : (
                      filteredPeserta.map((p: any) => (
                        <tr key={p.id} className="border-b border-gray-50 last:border-0">
                          <td className="py-2.5">
                            <div className="flex items-center gap-2.5">
                              <img
                                src={getAvatarUrl(p.avatarUrl, p.nama)}
                                alt={p.nama}
                                className="h-8 w-8 rounded-full object-cover bg-gray-100"
                              />
                              <span className="font-medium text-gray-900">{p.nama}</span>
                            </div>
                          </td>
                          <td className="py-2.5 text-gray-700">{p.angkatan}</td>
                          <td className="py-2.5 text-gray-500">{formatDate(p.joinedAt)}</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </article>

        <aside className="lg:sticky lg:top-8 space-y-6">
          <SectionCard title="Detail Agenda">
            <dl className="space-y-3 text-sm">
              <DetailRow label="Tanggal" value={formatDate(agenda.tanggalEvent)} />
              <DetailRow label="Waktu" value={`${formatTime(agenda.tanggalEvent)} WIB`} />
              <DetailRow label="Lokasi" value={agenda.lokasi} />
              {!isSubmission && (
                <DetailRow
                  label="Peserta Terdaftar"
                  value={
                    <span className="inline-flex items-center gap-1.5 font-semibold text-primary">
                      <Users className="h-3.5 w-3.5" />
                      {peserta.length} alumni
                    </span>
                  }
                />
              )}
              <div className="border-t border-gray-100 pt-3" />
              <DetailRow label="Dibuat pada" value={formatDateTime(agenda.createdAt)} />
              <DetailRow
                label="Dipublish pada"
                value={
                  agenda.publishedAt ? (
                    formatDateTime(agenda.publishedAt)
                  ) : (
                    <span className="text-gray-400 italic">Belum diposting</span>
                  )
                }
              />
              <div>
                <dt className="text-gray-500 text-xs mb-1.5">Author</dt>
                <dd className="flex items-center gap-2">
                  <img
                    src={getAvatarUrl(agenda.author.avatarUrl, agenda.author.nama)}
                    alt={agenda.author.nama}
                    className="h-7 w-7 rounded-full object-cover bg-gray-200"
                  />
                  <div className="text-sm">
                    <div className="text-gray-900 font-medium leading-tight">
                      {agenda.author.nama}
                    </div>
                    <div className="text-xs text-gray-500">{agenda.author.role}</div>
                  </div>
                </dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs mb-1.5">Status</dt>
                <dd>
                  <StatusBadge status={agenda.status} />
                </dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs mb-1.5">Tags (SEO)</dt>
                <dd className="flex flex-wrap gap-1">
                  {agenda.tags && agenda.tags.split(',').map((t) => t.trim()).filter(Boolean).length > 0 ? (
                    agenda.tags
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
                  {(agenda.status === 'Draft' || agenda.status === 'Archived') && canEdit && (
                    <Button
                      className="w-full"
                      onClick={() => setConfirmPublish(true)}
                      leftIcon={<Send className="h-4 w-4" />}
                    >
                      Publish
                    </Button>
                  )}
                  {agenda.status === 'Published' && canEdit && (
                    <Button
                      variant="outline"
                      className="w-full"
                      onClick={() => setConfirmDraft(true)}
                      leftIcon={<ArchiveRestore className="h-4 w-4" />}
                    >
                      Set as Draft
                    </Button>
                  )}
                  {agenda.status !== 'Archived' && canEdit && (
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
                      onClick={() => navigate(`/admin/agenda/${agenda.id}/edit`)}
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
                      Hapus Agenda
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
        title="Hapus Agenda Ini?"
        description="Tindakan ini akan menghapus agenda secara permanen dari sistem dan tidak dapat dibatalkan. Apakah Anda yakin ingin melanjutkan?"
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
        description="Submission agenda akan ditolak dan dihapus dari sistem. Tindakan ini tidak dapat dibatalkan."
        confirmLabel="Tolak"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleReject}
        onCancel={() => setConfirmReject(false)}
      />

      <ConfirmDialog
        open={confirmPublish}
        title="Publish Agenda?"
        description="Agenda akan langsung tampil di website portal alumni."
        confirmLabel="Publish"
        cancelLabel="Batal"
        onConfirm={handlePublish}
        onCancel={() => setConfirmPublish(false)}
      />

      <ConfirmDialog
        open={confirmDraft}
        title="Set Sebagai Draft?"
        description="Agenda akan dikembalikan ke status Draft dan tidak tampil di website hingga di-publish ulang."
        confirmLabel="Set as Draft"
        cancelLabel="Batal"
        onConfirm={handleSetDraft}
        onCancel={() => setConfirmDraft(false)}
      />

      <ConfirmDialog
        open={confirmArchive}
        title="Arsipkan Agenda?"
        description="Agenda akan diarsipkan dan tidak akan tampil di website publik lagi."
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

function InfoRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-start gap-2">
      <div className="text-primary mt-0.5">{icon}</div>
      <div className="min-w-0">
        <div className="text-xs text-gray-500">{label}</div>
        <div className="text-sm font-medium text-gray-900 truncate">{value}</div>
      </div>
    </div>
  )
}
