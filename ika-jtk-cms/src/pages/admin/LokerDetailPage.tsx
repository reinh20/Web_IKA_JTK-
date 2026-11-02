import { useNavigate, useParams, Navigate } from 'react-router-dom'
import { useState, useEffect } from 'react'
import {
  Pencil, Trash2, Send, ArchiveRestore, Check, X, Briefcase, MapPin,
  Globe, Building2, Download,
} from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { Tabs } from '@/components/ui/Tabs'
import { Input } from '@/components/ui/Input'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { useAuthStore } from '@/stores/authStore'
import { getAvatarUrl, formatDate, formatDateTime, getFileUrl } from '@/lib/utils'
import { useSeoMeta } from '@/lib/useSeoMeta'
import type { Loker, LokerStatus } from '@/types/loker'

function parseAnswerString(rawAns: any): string {
  if (!rawAns) return ''
  if (typeof rawAns === 'string') return rawAns
  if (typeof rawAns === 'object') {
    if (rawAns.url) return String(rawAns.url)
    if (rawAns.data && rawAns.data.url) return String(rawAns.data.url)
  }
  if (Array.isArray(rawAns)) return rawAns.join(', ')
  return String(rawAns)
}

function getOriginalFileName(url: string): string {
  if (!url) return 'lampiran'
  try {
    const parts = url.split('/')
    let filename = parts[parts.length - 1] || 'lampiran'
    filename = filename.split('?')[0]
    filename = decodeURIComponent(filename)
    if (filename.includes('___')) {
      const idx = filename.indexOf('___')
      filename = filename.substring(idx + 3)
    }
    return filename || 'lampiran'
  } catch {
    return 'lampiran'
  }
}

function StatusBadge({ status }: { status: LokerStatus }) {
  if (status === 'Published') return <Badge variant="green">Published</Badge>
  if (status === 'Draft') return <Badge variant="orange">Draft</Badge>
  if (status === 'Archived') return <Badge variant="gray">Archived</Badge>
  return <Badge variant="blue">Submission</Badge>
}

export function LokerDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const canEdit = user?.permissions?.includes('loker_edit') ?? false
  const [loker, setLoker] = useState<Loker | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useSeoMeta({
    title: loker?.posisi,
    description: loker?.deskripsi ? loker.deskripsi.replace(/<[^>]+>/g, '').slice(0, 160) : undefined,
    tags: loker?.tags,
  })

  const [tab, setTab] = useState<'loker' | 'pelamar'>('loker')
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [confirmReject, setConfirmReject] = useState(false)
  const [confirmPublish, setConfirmPublish] = useState(false)
  const [confirmDraft, setConfirmDraft] = useState(false)
  const [confirmArchive, setConfirmArchive] = useState(false)

  const fetchLoker = async () => {
    try {
      setIsLoading(true)
      const res = await api.get(`/admin/loker/${id}`)
      setLoker(res.data)
    } catch (error) {
      toast('Gagal memuat loker', 'error')
      navigate('/admin/loker')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchLoker()
  }, [id])

  if (isLoading) return <div className="p-10">Loading...</div>

  if (!loker) return <Navigate to="/admin/loker" replace />

  const isSubmission = loker.status === 'Submission'

  const handleDelete = async () => {
    setConfirmDelete(false)
    try {
      await api.delete(`/admin/loker/${id}`)
      toast('Loker berhasil dihapus', 'success')
      navigate('/admin/loker')
    } catch (error) {
      toast('Gagal menghapus loker', 'error')
    }
  }
  const handlePublish = async () => {
    setConfirmPublish(false)
    try {
      await api.put(`/admin/loker/${id}`, { ...loker, status: 'Published' })
      toast('Loker berhasil dipublish', 'success')
      fetchLoker()
    } catch (error) {
      toast('Gagal publish loker', 'error')
    }
  }
  const handleSetDraft = async () => {
    setConfirmDraft(false)
    try {
      await api.put(`/admin/loker/${id}`, { ...loker, status: 'Draft' })
      toast('Loker dipindahkan ke Draft', 'info')
      fetchLoker()
    } catch (error) {
      toast('Gagal set draft', 'error')
    }
  }
  const handleArchive = async () => {
    setConfirmArchive(false)
    try {
      await api.put(`/admin/loker/${id}`, { ...loker, status: 'Archived' })
      toast('Loker berhasil diarsipkan', 'success')
      fetchLoker()
    } catch (error) {
      toast('Gagal mengarsipkan loker', 'error')
    }
  }
  const handleAccept = async () => {
    try {
      await api.post(`/admin/loker/${id}/approve`)
      toast('Loker berhasil disetujui dan dipublish', 'success')
      fetchLoker()
    } catch (error) {
      toast('Gagal terima loker', 'error')
    }
  }
  const handleReject = async () => {
    setConfirmReject(false)
    try {
      await api.post(`/admin/loker/${id}/reject`)
      toast('Submission ditolak', 'info')
      fetchLoker()
    } catch (error) {
      toast('Gagal menolak submission', 'error')
    }
  }

  const pelamarCount = loker.pelamar?.length || 0

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Loker', to: '/admin/loker' },
          { label: isSubmission ? 'Detail Submission' : 'Detail Loker' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">
        {isSubmission ? 'Detail Submission' : 'Detail Loker'}
      </h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      {!isSubmission && (
        <div className="mt-6">
          <Tabs
            value={tab}
            onChange={(v) => setTab(v as 'loker' | 'pelamar')}
            items={[
              { key: 'loker', label: 'Loker' },
              {
                key: 'pelamar',
                label: 'Pelamar',
                count: pelamarCount,
                hasDot: pelamarCount > 0,
              },
            ]}
          />
        </div>
      )}

      {tab === 'pelamar' ? (
        <PelamarTab loker={loker} onUpdate={fetchLoker} />
      ) : (
        <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6 items-start">
          <article className="bg-white rounded-lg border border-gray-200 shadow-sm p-8 min-w-0">
            <div className="flex items-start gap-4">
              <div className="h-14 w-14 rounded-md bg-primary-light text-primary flex items-center justify-center flex-shrink-0 overflow-hidden">
                {loker.logoUrl ? (
                  <img src={getFileUrl(loker.logoUrl)} alt={loker.posisi} className="h-full w-full object-cover" />
                ) : (
                  <Briefcase className="h-7 w-7" />
                )}
              </div>
              <div className="flex-1 min-w-0">
                <h2 className="text-2xl font-bold text-gray-900 leading-tight">
                  {loker.posisi}
                </h2>
                <div className="mt-1.5 flex items-center flex-wrap gap-x-3 gap-y-1 text-sm text-gray-600">
                  <span className="inline-flex items-center gap-1">
                    <Building2 className="h-3.5 w-3.5" /> {loker.namaPerusahaan}
                  </span>
                  <span className="text-gray-300">•</span>
                  <span className="inline-flex items-center gap-1">
                    <MapPin className="h-3.5 w-3.5" /> {loker.kota}
                  </span>
                  {loker.websitePerusahaan && (
                    <>
                      <span className="text-gray-300">•</span>
                      <a
                        href={`https://${loker.websitePerusahaan}`}
                        target="_blank"
                        rel="noreferrer"
                        className="inline-flex items-center gap-1 text-primary hover:underline"
                      >
                        <Globe className="h-3.5 w-3.5" /> {loker.websitePerusahaan}
                      </a>
                    </>
                  )}
                </div>
                <div className="mt-3 flex items-center gap-2 flex-wrap">
                  <Badge variant="blue">{loker.jenisPekerjaan}</Badge>
                  <Badge variant="gray">{loker.tipeLokasi}</Badge>
                </div>
              </div>
            </div>

            <hr className="my-6 border-gray-100" />

            <div
              className="rich-content text-[15px] leading-relaxed text-gray-700 break-words"
              dangerouslySetInnerHTML={{ __html: loker.deskripsi }}
            />

            {loker.skemaPelamaran === 'internal' && loker.formLamaran.length > 0 && (
              <div className="mt-8 pt-6 border-t border-gray-100">
                <h3 className="text-lg font-bold text-gray-900 mb-1">Form Lamaran</h3>
                <span className="block mb-4 h-0.5 w-8 bg-accent rounded-full" />
                <div className="space-y-4">
                  {loker.formLamaran.map((f) => (
                    <FormFieldPreview key={f.id} field={f} />
                  ))}
                </div>
              </div>
            )}

            {loker.skemaPelamaran === 'external' && loker.linkExternal && (
              <div className="mt-8 pt-6 border-t border-gray-100">
                <p className="text-sm text-gray-500 mb-2">Pelamar akan diarahkan ke:</p>
                <a
                  href={loker.linkExternal}
                  target="_blank"
                  rel="noreferrer"
                  className="text-sm text-primary hover:underline break-all"
                >
                  {loker.linkExternal}
                </a>
              </div>
            )}
          </article>

          <aside className="lg:sticky lg:top-8 space-y-6">
            <SectionCard title="Detail Loker">
              <dl className="space-y-3 text-sm">
                <div>
                  <dt className="text-gray-500 text-xs mb-0.5">Jenis Pekerjaan</dt>
                  <dd><Badge variant="blue">{loker.jenisPekerjaan}</Badge></dd>
                </div>
                <DetailRow
                  label="Lokasi"
                  value={`${loker.tipeLokasi} • ${loker.kota}`}
                />
                <div className="border-t border-gray-100 pt-3" />
                <DetailRow label="Dibuat pada" value={formatDateTime(loker.createdAt)} />
                <DetailRow
                  label="Dipublish pada"
                  value={
                    loker.publishedAt ? (
                      formatDateTime(loker.publishedAt)
                    ) : (
                      <span className="text-gray-400 italic">Belum diposting</span>
                    )
                  }
                />
                <div>
                  <dt className="text-gray-500 text-xs mb-1.5">Author</dt>
                  <dd className="flex items-center gap-2">
                    <img
                      src={getAvatarUrl(loker.author.avatarUrl, loker.author.nama)}
                      alt={loker.author.nama}
                      className="h-7 w-7 rounded-full object-cover bg-gray-200"
                    />
                    <div className="text-sm">
                      <div className="text-gray-900 font-medium leading-tight">
                        {loker.author.nama}
                      </div>
                      <div className="text-xs text-gray-500">{loker.author.role}</div>
                    </div>
                  </dd>
                </div>
                <div>
                  <dt className="text-gray-500 text-xs mb-1.5">Status</dt>
                  <dd><StatusBadge status={loker.status} /></dd>
                </div>
                <div>
                  <dt className="text-gray-500 text-xs mb-1.5">Tags (SEO)</dt>
                  <dd className="flex flex-wrap gap-1">
                    {loker.tags && loker.tags.split(',').map((t) => t.trim()).filter(Boolean).length > 0 ? (
                      loker.tags
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
                    <Button className="w-full" onClick={handleAccept} leftIcon={<Check className="h-4 w-4" />}>
                      Terima Submission
                    </Button>
                    <Button
                      variant="danger"
                      className="w-full"
                      onClick={() => setConfirmReject(true)}
                      leftIcon={<X className="h-4 w-4" />}
                    >
                      Tolak Submission
                    </Button>
                  </>
                ) : (
                  <>
                    {canEdit && (
                      <Button
                        variant="outline"
                        className="w-full"
                        onClick={() => navigate(`/admin/loker/${loker.id}/edit`)}
                        leftIcon={<Pencil className="h-4 w-4" />}
                      >
                        Edit Loker
                      </Button>
                    )}
                    {(loker.status === 'Draft' || loker.status === 'Archived') && canEdit && (
                      <Button
                        className="w-full"
                        onClick={() => setConfirmPublish(true)}
                        leftIcon={<Send className="h-4 w-4" />}
                      >
                        Publish
                      </Button>
                    )}
                    {loker.status === 'Published' && canEdit && (
                      <Button
                        variant="outline"
                        className="w-full"
                        onClick={() => setConfirmDraft(true)}
                        leftIcon={<ArchiveRestore className="h-4 w-4" />}
                      >
                        Tarik ke Draft
                      </Button>
                    )}
                    {(loker.status === 'Published' || loker.status === 'Draft') && canEdit && (
                      <Button
                        variant="outline"
                        className="w-full"
                        onClick={() => setConfirmArchive(true)}
                        leftIcon={<ArchiveRestore className="h-4 w-4" />}
                      >
                        Arsipkan
                      </Button>
                    )}
                  </>
                )}
                {canEdit && (
                  <button
                    type="button"
                    onClick={() => setConfirmDelete(true)}
                    className="w-full inline-flex items-center justify-center gap-2 text-sm font-semibold text-danger hover:underline py-2 mt-4"
                  >
                    <Trash2 className="h-4 w-4" />
                    Hapus Loker
                  </button>
                )}
              </div>
            </SectionCard>
          </aside>
        </div>
      )}

      <ConfirmDialog
        open={confirmDelete}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-danger-bg text-danger">
            <Trash2 className="h-6 w-6" />
          </div>
        }
        title="Hapus Loker Ini?"
        description="Tindakan ini akan menghapus loker secara permanen dari sistem dan tidak dapat dibatalkan. Apakah Anda yakin ingin melanjutkan?"
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
        description="Submission loker akan ditolak dan dihapus dari sistem. Tindakan ini tidak dapat dibatalkan."
        confirmLabel="Tolak"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleReject}
        onCancel={() => setConfirmReject(false)}
      />
      <ConfirmDialog
        open={confirmDraft}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 text-gray-600">
            <ArchiveRestore className="h-6 w-6" />
          </div>
        }
        title="Set Loker sebagai Draft?"
        description="Loker akan diturunkan dari portal IKA JTK dan tidak dapat dilihat oleh member/publik."
        confirmLabel="Set Draft"
        cancelLabel="Batal"
        variant="primary"
        onConfirm={handleSetDraft}
        onCancel={() => setConfirmDraft(false)}
      />
      <ConfirmDialog
        open={confirmArchive}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-orange-100 text-orange-600">
            <ArchiveRestore className="h-6 w-6" />
          </div>
        }
        title="Arsipkan Loker Ini?"
        description="Loker akan dipindahkan ke arsip dan tidak akan muncul di portal pencarian."
        confirmLabel="Arsipkan"
        cancelLabel="Batal"
        variant="primary"
        onConfirm={handleArchive}
        onCancel={() => setConfirmArchive(false)}
      />
      <ConfirmDialog
        open={confirmPublish}
        title="Publish Loker?"
        description="Loker akan langsung tampil di website portal alumni dan dapat dilamar."
        confirmLabel="Publish"
        cancelLabel="Batal"
        onConfirm={handlePublish}
        onCancel={() => setConfirmPublish(false)}
      />
      <ConfirmDialog
        open={confirmDraft}
        title="Set Sebagai Draft?"
        description="Loker akan dikembalikan ke status Draft dan tidak tampil di website hingga di-publish ulang."
        confirmLabel="Set as Draft"
        cancelLabel="Batal"
        onConfirm={handleSetDraft}
        onCancel={() => setConfirmDraft(false)}
      />
    </div>
  )
}

function FormFieldPreview({ field }: { field: Loker['formLamaran'][number] }) {
  return (
    <div>
      <label className="block text-sm font-medium text-gray-800 mb-1.5">
        {field.label || <span className="text-gray-400 italic">Belum ada label</span>}
      </label>
      {field.tipe === 'text' && <Input disabled placeholder={field.label || 'Jawaban singkat'} />}
      {field.tipe === 'longtext' && (
        <textarea
          disabled
          rows={3}
          placeholder={field.label || 'Jawaban panjang'}
          className="block w-full rounded-md border border-gray-300 bg-gray-50 px-3 py-2 text-sm text-gray-500"
        />
      )}
      {field.tipe === 'number' && <Input disabled type="number" placeholder="0" />}
      {field.tipe === 'option' && (
        <div className="space-y-2">
          {(field.options ?? []).map((opt, i) => (
            <label key={i} className="flex items-center gap-2 text-sm text-gray-600">
              <span className="h-4 w-4 rounded-full border-2 border-gray-300 inline-block" />
              {opt || <span className="italic text-gray-400">Opsi {i + 1}</span>}
            </label>
          ))}
        </div>
      )}
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

function PelamarTab({ loker, onUpdate }: { loker: Loker; onUpdate: () => void }) {
  const user = useAuthStore((state) => state.user)
  const canEdit = user?.permissions?.includes('loker_edit') ?? false
  const [search, setSearch] = useState('')
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [viewPelamar, setViewPelamar] = useState<Loker['pelamar'][number] | null>(null)
  const [processingId, setProcessingId] = useState<string | null>(null)

  const handleUpdateLamaranStatus = async (lamaranId: string, status: string) => {
    if (processingId) return
    setProcessingId(lamaranId)
    try {
      await api.put(`/admin/loker/${loker.id}/lamaran/${lamaranId}/status`, { status })
      toast(`Status lamaran diubah menjadi ${status}`, 'success')
      onUpdate()
    } catch (error) {
      toast('Gagal mengubah status lamaran', 'error')
    } finally {
      setProcessingId(null)
    }
  }

  const handleDeleteLamaran = async (lamaranId: string) => {
    if (!confirm('Yakin ingin menghapus lamaran ini?')) return
    try {
      await api.delete(`/admin/loker/${loker.id}/lamaran/${lamaranId}`)
      toast('Lamaran berhasil dihapus', 'success')
      onUpdate()
    } catch (error) {
      toast('Gagal menghapus lamaran', 'error')
    }
  }

  const filtered = (loker.pelamar || []).filter((p) =>
    !search.trim() ||
    p.nama.toLowerCase().includes(search.toLowerCase()) ||
    p.email.toLowerCase().includes(search.toLowerCase())
  )

  const handleExport = () => {
    // Dynamic headers based on formLamaran
    const customHeaders = loker.formLamaran.map((f) => f.label)
    
    const rows = [
      ['No. Alumni', 'Nama', 'Angkatan', 'Email', 'Tanggal Pelamar', 'Keanggotaan', ...customHeaders],
      ...filtered.map((p) => {
        const customAnswers = loker.formLamaran.map((f) => {
          return parseAnswerString(p.jawaban?.[f.id])
        })
        return [
          p.noAlumni, p.nama, p.angkatan, p.email, formatDate(p.tanggalPelamar), p.keanggotaan, ...customAnswers
        ]
      }),
    ]
    const csv = rows.map((r) => r.map((v) => `"${String(v ?? '').replace(/"/g, '""')}"`).join(',')).join('\n')
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `pelamar-${loker.posisi.replace(/\s+/g, '-')}.csv`
    a.click()
    URL.revokeObjectURL(url)
    toast('Data pelamar berhasil diekspor (CSV)', 'success')
  }

  const allChecked = filtered.length > 0 && filtered.every((p) => selected.has(p.id))
  const toggleAll = () => {
    const next = new Set(selected)
    if (allChecked) filtered.forEach((p) => next.delete(p.id))
    else filtered.forEach((p) => next.add(p.id))
    setSelected(next)
  }
  const toggleOne = (id: string) => {
    const next = new Set(selected)
    next.has(id) ? next.delete(id) : next.add(id)
    setSelected(next)
  }

  return (
    <div className="mt-6">
      <div className="flex flex-wrap items-end gap-4 mb-4">
        <div className="flex-1 min-w-[240px] max-w-sm">
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Cari Pelamar</label>
          <Input
            placeholder="Cari nama atau email"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div className="ml-auto">
          <Button
            onClick={handleExport}
            disabled={filtered.length === 0}
            rightIcon={<Download className="h-4 w-4" />}
          >
            Eksport
          </Button>
        </div>
      </div>

      <div className="mb-3 text-sm text-gray-600">
        {(loker.pelamar || []).length === 0
          ? 'Belum ada pelamar'
          : search.trim()
            ? `Menampilkan ${filtered.length} dari ${(loker.pelamar || []).length} pelamar`
            : `Total ${(loker.pelamar || []).length} pelamar`}
      </div>

      <div className="overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-100 text-gray-700 text-left">
                <th className="w-12 px-4 py-3">
                  <input
                    type="checkbox"
                    checked={allChecked}
                    onChange={toggleAll}
                  />
                </th>
                <th className="px-4 py-3 font-semibold">No. Alumni</th>
                <th className="px-4 py-3 font-semibold">Nama</th>
                <th className="px-4 py-3 font-semibold">Angkatan</th>
                <th className="px-4 py-3 font-semibold">Email</th>
                <th className="px-4 py-3 font-semibold">Tanggal Pelamar</th>
                <th className="px-4 py-3 font-semibold">Keanggotaan</th>
                <th className="px-4 py-3 font-semibold">Status</th>
                <th className="px-4 py-3 font-semibold text-center">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={9} className="py-16 text-center text-gray-500">
                    Belum ada pelamar.
                  </td>
                </tr>
              )}
              {filtered.map((p) => (
                <tr key={p.id} className="hover:bg-gray-50/60">
                  <td className="px-4 py-3">
                    <input
                      type="checkbox"
                      checked={selected.has(p.id)}
                      onChange={() => toggleOne(p.id)}
                    />
                  </td>
                  <td className="px-4 py-3 text-gray-700">{p.noAlumni}</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <img
                        src={getAvatarUrl(p.avatarUrl, p.nama)}
                        alt={p.nama}
                        className="h-7 w-7 rounded-full object-cover bg-gray-200"
                      />
                      <span className="text-gray-900 font-medium">{p.nama}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-gray-700">{p.angkatan}</td>
                  <td className="px-4 py-3 text-gray-700">{p.email}</td>
                  <td className="px-4 py-3 text-gray-700 whitespace-nowrap">
                    {formatDate(p.tanggalPelamar)}
                  </td>
                  <td className="px-4 py-3">
                    <Badge variant="gray">{p.keanggotaan}</Badge>
                  </td>
                  <td className="px-4 py-3">
                    <Badge
                      variant={
                        p.status === 'Diterima'
                          ? 'green'
                          : p.status === 'Ditolak'
                          ? 'red'
                          : 'orange'
                      }
                    >
                      {p.status || 'Sedang Direview'}
                    </Badge>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <div className="flex items-center justify-center gap-3">
                      {(!p.status || p.status === 'Sedang Direview') && canEdit && (
                        <>
                          <button
                            type="button"
                            disabled={processingId === p.id}
                            onClick={() => handleUpdateLamaranStatus(p.id, 'Diterima')}
                            className="text-green-600 hover:underline font-medium text-xs disabled:opacity-50 disabled:cursor-not-allowed"
                          >
                            Terima
                          </button>
                          <button
                            type="button"
                            disabled={processingId === p.id}
                            onClick={() => handleUpdateLamaranStatus(p.id, 'Ditolak')}
                            className="text-red-600 hover:underline font-medium text-xs disabled:opacity-50 disabled:cursor-not-allowed"
                          >
                            Tolak
                          </button>
                        </>
                      )}
                      <button
                        type="button"
                        onClick={() => setViewPelamar(p)}
                        className={`text-primary hover:underline font-medium text-xs ${(!p.status || p.status === 'Sedang Direview') && canEdit ? 'border-l pl-3 ml-1' : ''}`}
                      >
                        Lihat Detail
                      </button>
                      {canEdit && (
                        <button
                          type="button"
                          onClick={() => handleDeleteLamaran(p.id)}
                          className="text-gray-500 hover:text-danger hover:underline font-medium text-xs border-l pl-3 ml-1"
                        >
                          Hapus
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <PelamarDetailModal
        open={!!viewPelamar}
        pelamar={viewPelamar}
        loker={loker}
        onClose={() => setViewPelamar(null)}
      />
    </div>
  )
}

function PelamarDetailModal({
  open,
  pelamar,
  loker,
  onClose,
}: {
  open: boolean
  pelamar: Loker['pelamar'][number] | null
  loker: Loker
  onClose: () => void
}) {
  if (!pelamar) return null
  return (
    <div
      className={`fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 transition-opacity ${
        open ? 'opacity-100 visible' : 'opacity-0 invisible'
      }`}
    >
      <div className="absolute inset-0 bg-gray-900/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative w-full max-w-2xl bg-white rounded-xl shadow-xl overflow-hidden flex flex-col max-h-full">
        <div className="flex items-center justify-between p-6 border-b border-gray-100">
          <div>
            <h3 className="text-xl font-bold text-gray-900 leading-tight">
              Detail Pelamar
            </h3>
            <p className="text-sm text-gray-500 mt-1">{pelamar.nama}</p>
          </div>
          <button
            onClick={onClose}
            className="h-8 w-8 inline-flex items-center justify-center rounded-full text-gray-400 hover:bg-gray-100 hover:text-gray-700 transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="p-6 overflow-y-auto space-y-6 flex-1">
          <SectionCard title="Data Profil Alumni">
            <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-4 text-sm">
              <DetailRow label="No. Alumni" value={pelamar.noAlumni} />
              <DetailRow label="Angkatan" value={pelamar.angkatan} />
              <DetailRow label="Email" value={pelamar.email} />
              <DetailRow label="Keanggotaan" value={<Badge variant="gray">{pelamar.keanggotaan}</Badge>} />
              <DetailRow label="Tanggal Melamar" value={formatDate(pelamar.tanggalPelamar)} />
            </dl>
          </SectionCard>
          <SectionCard title="Informasi Tambahan (Form Lamaran)">
            {loker.formLamaran.length === 0 ? (
              <p className="text-sm text-gray-500">Tidak ada informasi tambahan.</p>
            ) : (
              <dl className="space-y-4 text-sm">
                {loker.formLamaran.map((f) => {
                  const ans = parseAnswerString(pelamar.jawaban?.[f.id])
                  const fileUrl = getFileUrl(ans)
                  return (
                    <div key={f.id} className="pb-4 border-b border-gray-50 last:border-0 last:pb-0">
                      <dt className="text-gray-500 text-xs mb-1 font-medium">{f.label}</dt>
                      <dd className="text-gray-900">
                        {f.tipe === 'file' ? (
                          ans ? (
                            ans.match(/\.(jpeg|jpg|gif|png)$/i) ? (
                              <div className="space-y-3 mt-1.5">
                                <a href={fileUrl} target="_blank" rel="noreferrer" className="block max-w-[240px] rounded-lg border border-gray-200 overflow-hidden shadow-sm hover:opacity-90 transition-opacity">
                                  <img src={fileUrl} alt={f.label} className="w-full h-auto object-cover" />
                                </a>
                                <a
                                  href={fileUrl}
                                  target="_blank"
                                  rel="noreferrer"
                                  download={getOriginalFileName(ans)}
                                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md bg-primary/10 text-primary hover:bg-primary/20 transition-colors text-xs font-semibold max-w-full"
                                >
                                  <Download className="h-3.5 w-3.5 flex-shrink-0" />
                                  <span className="truncate">Unduh ({getOriginalFileName(ans)})</span>
                                </a>
                              </div>
                            ) : (
                              <a
                                href={fileUrl}
                                target="_blank"
                                rel="noreferrer"
                                download={getOriginalFileName(ans)}
                                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md bg-primary/10 text-primary hover:bg-primary/20 transition-colors text-xs font-semibold max-w-full"
                              >
                                <Download className="h-3.5 w-3.5 flex-shrink-0" />
                                <span className="truncate">Unduh ({getOriginalFileName(ans)})</span>
                              </a>
                            )
                          ) : (
                            <span className="text-gray-400 italic">Tidak ada file</span>
                          )
                        ) : (
                          ans || <span className="text-gray-400 italic">Kosong</span>
                        )}
                      </dd>
                    </div>
                  )
                })}
              </dl>
            )}
          </SectionCard>
        </div>
        <div className="p-6 border-t border-gray-100 flex justify-end">
          <Button onClick={onClose} variant="outline">
            Tutup
          </Button>
        </div>
      </div>
    </div>
  )
}

