import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Search, Eye, Check, X, Trash2, Quote, AlertTriangle,
} from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { Tabs } from '@/components/ui/Tabs'
import { Input } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Pagination } from '@/components/ui/Pagination'
import { Checkbox } from '@/components/ui/Checkbox'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { Modal } from '@/components/ui/Modal'
import { RowActionMenu } from '@/components/ui/RowActionMenu'
import { toast } from '@/components/ui/Toast'
import { useAuthStore } from '@/stores/authStore'
import api from '@/lib/api'
import { formatDate, getThumbnailUrl } from '@/lib/utils'
import type { Testimoni, TestimoniStatus } from '@/types/testimoni'
import { getFriendlyErrorMessage } from '../../utils/errorHandler';

const PAGE_SIZE = 10

function StatusBadge({ status }: { status: TestimoniStatus }) {
  if (status === 'Published') return <Badge variant="green">Published</Badge>
  if (status === 'Pending') return <Badge variant="orange">Pending</Badge>
  return <Badge variant="red">Rejected</Badge>
}

export function TestimoniListPage() {
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const canEdit = user?.permissions?.includes('testimoni_edit') ?? false
  const [data, setData] = useState<Testimoni[]>([])
  const [total, setTotal] = useState(0)
  const [semuaCount, setSemuaCount] = useState(0)
  const [submissionCount, setSubmissionCount] = useState(0)
  const [publishedCount, setPublishedCount] = useState(0)
  const [rejectedCount, setRejectedCount] = useState(0)
  const [isLoading, setIsLoading] = useState(true)
  const [tab, setTab] = useState<'semua' | 'pending' | 'published' | 'rejected'>('semua')
  const [searchInput, setSearchInput] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [page, setPage] = useState(1)
  const [selected, setSelected] = useState<Set<string>>(new Set())

  const [approveTarget, setApproveTarget] = useState<Testimoni | null>(null)
  const [rejectTarget, setRejectTarget] = useState<Testimoni | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<Testimoni | null>(null)
  const [rejectReason, setRejectReason] = useState('')
  const [isSaving, setIsSaving] = useState(false)

  const fetchData = async () => {
    try {
      setIsLoading(true)
      const statusParam = tab === 'semua' ? 'all' : (tab === 'pending' ? 'Pending' : (tab === 'published' ? 'Published' : 'Rejected'))
      const res = await api.get('/admin/testimoni', {
        params: {
          page,
          limit: PAGE_SIZE,
          search: appliedSearch,
          tab,
          status: statusParam
        }
      })
      setData(res.data.data)
      setTotal(res.data.total)
      setSemuaCount(res.data.semuaCount)
      setSubmissionCount(res.data.submissionCount)
      setPublishedCount(res.data.publishedCount)
      setRejectedCount(res.data.rejectedCount)
    } catch (error) {
      toast('Gagal memuat data testimoni', 'error')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [page, tab, appliedSearch])

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE))
  const currentPage = Math.min(page, totalPages)
  const pageRows = data

  const allChecked = pageRows.length > 0 && pageRows.every((r) => selected.has(r.id))
  const toggleAll = () => {
    const next = new Set(selected)
    if (allChecked) pageRows.forEach((r) => next.delete(r.id))
    else pageRows.forEach((r) => next.add(r.id))
    setSelected(next)
  }
  const toggleOne = (id: string) => {
    const next = new Set(selected)
    if (next.has(id)) {
      next.delete(id)
    } else {
      next.add(id)
    }
    setSelected(next)
  }

  const pendingCount = submissionCount

  const handleApprove = async () => {
    if (!approveTarget) return
    const nama = approveTarget.alumniNama
    setIsSaving(true)
    try {
      await api.put(`/admin/testimoni/${approveTarget.id}`, {
        ...approveTarget,
        status: 'Published',
        reviewedAt: new Date().toISOString(),
      })
      toast(`Testimoni dari "${nama}" berhasil dipublish`, 'success')
      await fetchData()
    } catch (error: any) {
      toast(getFriendlyErrorMessage(error, 'Gagal mempublish testimoni'), 'error')
    } finally {
      setIsSaving(false)
      setApproveTarget(null)
    }
  }
  const handleReject = async (e?: React.FormEvent) => {
    if (e) e.preventDefault()
    if (!rejectTarget) return
    setIsSaving(true)
    const isPublished = rejectTarget.status === 'Published'
    try {
      const res = await api.put(`/admin/testimoni/${rejectTarget.id}`, {
        ...rejectTarget,
        status: 'Rejected',
        rejectReason: rejectReason,
        reviewedAt: new Date().toISOString(),
      })
      if (res.data?.message === 'deleted') {
        toast('Testimoni dihapus setelah 3 kali penolakan', 'info')
      } else {
        toast(isPublished ? 'Testimoni diarsipkan' : 'Testimoni ditolak', 'info')
      }
      await fetchData()
    } catch (error: any) {
      toast(error?.response?.data?.error || (isPublished ? 'Gagal mengarsipkan testimoni' : 'Gagal menolak testimoni'), 'error')
    } finally {
      setIsSaving(false)
      setRejectTarget(null)
      setRejectReason('')
    }
  }
  const handleDelete = async () => {
    if (!deleteTarget) return
    setIsSaving(true)
    try {
      await api.delete(`/admin/testimoni/${deleteTarget.id}`)
      toast('Testimoni berhasil dihapus', 'success')
      await fetchData()
    } catch (error: any) {
      toast(getFriendlyErrorMessage(error, 'Gagal menghapus testimoni'), 'error')
    } finally {
      setIsSaving(false)
      setDeleteTarget(null)
    }
  }

  if (isLoading) return <div className="p-10">Loading...</div>

  return (
    <div className="px-10 py-8">
      <Breadcrumb items={[{ label: 'Testimoni' }]} />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">Data Testimoni</h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8">
        <Tabs
          value={tab}
          onChange={(v) => {
            setTab(v as typeof tab)
            setPage(1)
            setSelected(new Set())
          }}
          items={[
            { key: 'semua', label: 'Semua', count: semuaCount },
            { key: 'pending', label: 'Pending', count: pendingCount, hasDot: pendingCount > 0 },
            { key: 'published', label: 'Published', count: publishedCount },
            { key: 'rejected', label: 'Rejected', count: rejectedCount },
          ]}
        />
      </div>

      <div className="mt-6 flex flex-wrap items-end gap-4">
        <div className="flex-1 min-w-[260px] max-w-md">
          <label className="block text-sm font-medium text-gray-700 mb-1.5">
            Cari Testimoni
          </label>
          <Input
            placeholder="Cari nama atau isi..."
            value={searchInput}
            onChange={(e) => {
              setSearchInput(e.target.value)
            }}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                setAppliedSearch(searchInput)
                setPage(1)
              }
            }}
          />
        </div>
        <Button
          variant="outline"
          onClick={() => {
            setAppliedSearch(searchInput)
            setPage(1)
          }}
          rightIcon={<Search className="h-4 w-4" />}
        >
          Cari
        </Button>
      </div>

      <div className="mt-6 overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-100 text-gray-700 text-left">
                <th className="hidden w-12 px-4 py-3">
                  <Checkbox checked={allChecked} onChange={toggleAll} />
                </th>
                <th className="px-4 py-3 font-semibold">Alumni</th>
                <th className="px-4 py-3 font-semibold">Isi Testimoni</th>
                <th className="px-4 py-3 font-semibold">Visibility</th>
                <th className="px-4 py-3 font-semibold">Tanggal</th>
                <th className="px-4 py-3 font-semibold">Status</th>
                <th className="px-4 py-3 font-semibold text-center">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {pageRows.length === 0 && (
                <tr>
                  <td colSpan={7} className="py-16 text-center text-gray-500">
                    Belum ada testimoni untuk filter ini.
                  </td>
                </tr>
              )}
              {pageRows.map((t) => (
                <tr key={t.id} className="hover:bg-gray-50/60">
                  <td className="hidden px-4 py-3">
                    <Checkbox
                      checked={selected.has(t.id)}
                      onChange={() => toggleOne(t.id)}
                    />
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <img
                        src={getThumbnailUrl(t.alumniAvatarUrl, t.alumniNama)}
                        alt={t.alumniNama}
                        className="h-8 w-8 rounded-full object-cover bg-gray-200"
                      />
                      <div className="min-w-0">
                        <div className="text-sm font-medium text-gray-900 truncate">
                          {t.alumniNama}
                        </div>
                        <div className="text-xs text-gray-500">
                          Angkatan {t.alumniAngkatan}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-gray-700 max-w-md">
                    <div className="flex items-start gap-2">
                      <Quote className="h-3 w-3 mt-1 text-accent flex-shrink-0" />
                      <p className="line-clamp-2 text-sm">{t.isi}</p>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <Badge variant={t.visibility === 'public' ? 'blue' : 'gray'}>
                      {t.visibility === 'public' ? 'Public' : 'Private'}
                    </Badge>
                  </td>
                  <td className="px-4 py-3 text-gray-700 whitespace-nowrap text-sm">
                    {formatDate(t.createdAt ?? t.submittedAt)}
                  </td>
                  <td className="px-4 py-3">
                    <StatusBadge status={t.status} />
                  </td>
                  <td className="px-4 py-3 text-center">
                    {t.status === 'Pending' ? (
                      <div className="inline-flex items-center justify-center gap-2">
                        <button
                          type="button"
                          onClick={() => navigate(`/admin/testimoni/${t.id}`)}
                          className="text-sm font-medium text-gray-600 hover:text-gray-900 flex items-center gap-1"
                        >
                          <Eye className="h-4 w-4" />
                          <span className="hidden sm:inline">Detail</span>
                        </button>
                        {canEdit && (
                          <>
                            <span className="text-gray-300">|</span>
                            <button
                              type="button"
                              onClick={() => setApproveTarget(t)}
                              className="text-sm font-semibold text-primary hover:underline"
                            >
                              Terima
                            </button>
                            <span className="text-gray-300">|</span>
                            <button
                              type="button"
                              onClick={() => (t.rejectCount ?? 0) >= 3 ? setDeleteTarget(t) : setRejectTarget(t)}
                              className="text-sm font-semibold text-danger hover:underline"
                            >
                              {(t.rejectCount ?? 0) >= 3 ? 'Hapus' : 'Tolak'}
                            </button>
                          </>
                        )}
                      </div>
                    ) : (
                      <RowActionMenu>
                        <button
                          type="button"
                          onClick={() => navigate(`/admin/testimoni/${t.id}`)}
                          className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                        >
                          <Eye className="h-4 w-4" />
                          Lihat Detail
                        </button>
                        {t.status === 'Rejected' && canEdit && (
                          <button
                            type="button"
                            onClick={() => setApproveTarget(t)}
                            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                          >
                            <Check className="h-4 w-4" />
                            Publish Ulang
                          </button>
                        )}
                        {t.status === 'Published' && canEdit && (
                          <button
                            type="button"
                            onClick={() => setRejectTarget(t)}
                            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                          >
                            <X className="h-4 w-4" />
                            Unpublish
                          </button>
                        )}
                        {canEdit && (
                          <button
                            type="button"
                            onClick={() => setDeleteTarget(t)}
                            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-danger hover:bg-danger-bg"
                          >
                            <Trash2 className="h-4 w-4" />
                            Hapus
                          </button>
                        )}
                      </RowActionMenu>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="mt-6 flex flex-col sm:flex-row items-center justify-between gap-3">
        <p className="text-sm text-gray-600">
          {total === 0
            ? 'Tidak ada data'
            : `Menampilkan ${(currentPage - 1) * PAGE_SIZE + 1}–${Math.min(currentPage * PAGE_SIZE, total)} dari ${total} data`}
        </p>
        <Pagination page={currentPage} totalPages={totalPages} onChange={setPage} />
      </div>

      <ConfirmDialog
        open={approveTarget !== null}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-success-bg text-success">
            <Check className="h-6 w-6" />
          </div>
        }
        title="Publish Testimoni Ini?"
        description="Testimoni akan tampil di halaman portal alumni dan dapat dilihat semua pengunjung."
        confirmLabel="Publish"
        cancelLabel="Batal"
        loading={isSaving}
        onConfirm={handleApprove}
        onCancel={() => setApproveTarget(null)}
      />

      <Modal open={rejectTarget !== null} onClose={() => setRejectTarget(null)}>
        <form onSubmit={handleReject} className="p-6">
          <div className="mb-4 inline-flex h-12 w-12 items-center justify-center rounded-full bg-accent-light text-accent">
            <AlertTriangle className="h-6 w-6" />
          </div>
          <h3 className="text-lg font-bold text-gray-900">
            {rejectTarget?.status === 'Published' ? 'Arsipkan Testimoni Ini?' : 'Tolak Testimoni Ini?'}
          </h3>
          <div className="mt-2 text-sm text-gray-600 leading-relaxed">
            Testimoni tidak akan tampil di portal. Anda dapat mengubah statusnya kembali kapan saja.
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
              {rejectTarget?.status === 'Published' ? 'Arsipkan' : 'Tolak'}
            </Button>
            <Button type="button" variant="ghost" onClick={() => { setRejectTarget(null); setRejectReason(''); }} disabled={isSaving}>
              Batal
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={deleteTarget !== null}
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
        loading={isSaving}
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  )
}
