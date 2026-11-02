import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { Search, Plus, Eye, Pencil, Trash2, Send, ArchiveRestore, Check, X } from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { Tabs } from '@/components/ui/Tabs'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Pagination } from '@/components/ui/Pagination'
import { Checkbox } from '@/components/ui/Checkbox'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { RowActionMenu } from '@/components/ui/RowActionMenu'
import { toast } from '@/components/ui/Toast'
import { useAuthStore } from '@/stores/authStore'
import api from '@/lib/api'
import { formatDate, cn, getThumbnailUrl } from '@/lib/utils'
import type { Loker, LokerStatus } from '@/types/loker'

const PAGE_SIZE = 10

function StatusBadge({ status }: { status: LokerStatus }) {
  if (status === 'Published') return <Badge variant="green">Published</Badge>
  if (status === 'Draft') return <Badge variant="orange">Draft</Badge>
  if (status === 'Archived') return <Badge variant="gray">Archived</Badge>
  if (status === 'Rejected') return <Badge variant="red">Rejected</Badge>
  return <Badge variant="blue">Submission</Badge>
}

export function LokerListPage() {
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const canEdit = user?.permissions?.includes('loker_edit') ?? false
  const [data, setData] = useState<Loker[]>([])
  const [total, setTotal] = useState(0)
  const [semuaCount, setSemuaCount] = useState(0)
  const [submissionCount, setSubmissionCount] = useState(0)
  const [isLoading, setIsLoading] = useState(true)
  const [searchParams, setSearchParams] = useSearchParams()
  const tabParam = searchParams.get('tab')
  const validTabs: Array<'semua' | 'submission'> = ['semua', 'submission']
  const tab: 'semua' | 'submission' = tabParam && validTabs.includes(tabParam as any)
    ? (tabParam as 'semua' | 'submission')
    : 'semua'
  const [searchInput, setSearchInput] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<'all' | LokerStatus>('all')
  const [page, setPage] = useState(1)
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [deleteTarget, setDeleteTarget] = useState<Loker | null>(null)

  const fetchData = async () => {
    try {
      setIsLoading(true)
      const res = await api.get('/admin/loker', {
        params: {
          page,
          limit: PAGE_SIZE,
          search: appliedSearch,
          tab,
          status: statusFilter
        }
      })
      setData(res.data.data)
      setTotal(res.data.total)
      setSemuaCount(res.data.semuaCount)
      setSubmissionCount(res.data.submissionCount)
    } catch (error) {
      toast('Gagal memuat data loker', 'error')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [page, tab, appliedSearch, statusFilter])

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
    next.has(id) ? next.delete(id) : next.add(id)
    setSelected(next)
  }

  const handlePublish = async (l: Loker) => {
    try {
      await api.put(`/admin/loker/${l.id}`, { ...l, status: 'Published' })
      setData((prev) =>
        prev.map((item) => (item.id === l.id ? { ...item, status: 'Published' } : item)),
      )
      toast(`Loker "${l.posisi}" berhasil dipublish`, 'success')
    } catch (error) {
      toast('Gagal mempublish loker', 'error')
    }
  }

  const handleApprove = async (l: Loker) => {
    try {
      await api.post(`/admin/loker/${l.id}/approve`)
      setData((prev) =>
        prev.map((item) => (item.id === l.id ? { ...item, status: 'Published' } : item)),
      )
      toast(`Loker "${l.posisi}" berhasil disetujui`, 'success')
    } catch (error) {
      toast('Gagal menyetujui loker', 'error')
    }
  }

  const handleReject = async (l: Loker) => {
    try {
      await api.post(`/admin/loker/${l.id}/reject`)
      setData((prev) =>
        prev.map((item) => (item.id === l.id ? { ...item, status: 'Rejected' } : item)),
      )
      toast(`Loker "${l.posisi}" ditolak`, 'info')
    } catch (error) {
      toast('Gagal menolak loker', 'error')
    }
  }

  const handleSetDraft = async (l: Loker) => {
    try {
      await api.put(`/admin/loker/${l.id}`, { ...l, status: 'Draft' })
      setData((prev) =>
        prev.map((item) => (item.id === l.id ? { ...item, status: 'Draft' } : item)),
      )
      toast(`Loker dipindahkan ke Draft`, 'info')
    } catch (error) {
      toast('Gagal mengubah status loker', 'error')
    }
  }

  const handleArchive = async (l: Loker) => {
    try {
      await api.put(`/admin/loker/${l.id}`, { ...l, status: 'Archived' })
      setData((prev) =>
        prev.map((item) => (item.id === l.id ? { ...item, status: 'Archived' } : item)),
      )
      toast(`Loker berhasil diarsipkan`, 'success')
    } catch (error) {
      toast('Gagal mengarsipkan loker', 'error')
    }
  }

  const confirmDelete = async () => {
    if (!deleteTarget) return
    const target = deleteTarget
    setDeleteTarget(null)
    try {
      await api.delete(`/admin/loker/${target.id}`)
      setData((prev) => prev.filter((item) => item.id !== target.id))
      toast(`Loker "${target.posisi.slice(0, 30)}..." berhasil dihapus`, 'success')
    } catch (error) {
      toast('Gagal menghapus loker', 'error')
    }
  }

  if (isLoading) return <div className="p-10">Loading...</div>

  return (
    <div className="px-10 py-8">
      <Breadcrumb items={[{ label: 'Loker' }]} />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">Data Loker</h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8">
        <Tabs
          value={tab}
          onChange={(v) => {
            const nextParams = new URLSearchParams(searchParams)
            nextParams.set('tab', v)
            setSearchParams(nextParams)
            setPage(1)
            setSelected(new Set())
          }}
          items={[
            { key: 'semua', label: 'Semua', count: semuaCount },
            {
              key: 'submission',
              label: 'Submission',
              count: submissionCount,
              hasDot: submissionCount > 0,
            },
          ]}
        />
      </div>

      <div className="mt-6 flex flex-wrap items-end gap-4">
        <div className="flex-1 min-w-[240px] max-w-sm">
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Posisi / Tags</label>
          <Input
            placeholder="Cari Posisi atau Tag..."
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
        {tab === 'semua' && (
          <div className="w-44">
            <label className="block text-sm font-medium text-gray-700 mb-1.5">Status</label>
            <Select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value as typeof statusFilter)
                setPage(1)
              }}
            >
              <option value="all">Semua</option>
              <option value="Published">Published</option>
              <option value="Draft">Draft</option>
              <option value="Archived">Archived</option>
            </Select>
          </div>
        )}
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
        <div className="ml-auto">
          {canEdit && (
            <Button
              onClick={() => navigate('/admin/loker/new')}
              rightIcon={<Plus className="h-4 w-4" />}
            >
              Tambah Loker
            </Button>
          )}
        </div>
      </div>

      <div className="mt-6 overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-100 text-gray-700 text-left">
                <th className="hidden w-12 px-4 py-3">
                  <Checkbox checked={allChecked} onChange={toggleAll} />
                </th>
                <th className="px-4 py-3 font-semibold">No. Loker</th>
                <th className="px-4 py-3 font-semibold">Posisi</th>
                <th className="px-4 py-3 font-semibold">Perusahaan</th>
                <th className="px-4 py-3 font-semibold">Lokasi</th>
                <th className="px-4 py-3 font-semibold">Tanggal Dibuat</th>
                <th className="px-4 py-3 font-semibold">Dibuat Oleh</th>
                <th className="px-4 py-3 font-semibold">Tags</th>
                <th className="px-4 py-3 font-semibold">Status</th>
                <th className="px-4 py-3 font-semibold text-center">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {pageRows.length === 0 && (
                <tr>
                  <td colSpan={10} className="py-16 text-center text-gray-500">
                    Belum ada loker untuk filter ini.
                  </td>
                </tr>
              )}
              {pageRows.map((l) => (
                <tr key={l.id} className="hover:bg-gray-50/60">
                  <td className="hidden px-4 py-3">
                    <Checkbox
                      checked={selected.has(l.id)}
                      onChange={() => toggleOne(l.id)}
                    />
                  </td>
                  <td className="px-4 py-3 text-gray-700">{l.noLoker}</td>
                  <td className="px-4 py-3 font-medium text-gray-900">
                    {l.posisi}
                  </td>
                  <td className="px-4 py-3 text-gray-700">{l.namaPerusahaan}</td>
                  <td className="px-4 py-3 text-gray-700">{l.kota}</td>
                  <td className="px-4 py-3 text-gray-700 whitespace-nowrap">
                    {formatDate(l.createdAt)}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <img
                        src={getThumbnailUrl(l.author.avatarUrl, l.author.nama)}
                        alt={l.author.nama}
                        className="h-7 w-7 rounded-full object-cover bg-gray-200"
                      />
                      <div className="text-sm text-gray-900 truncate max-w-[140px]">
                        {l.author.nama}
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3 max-w-xs">
                    <div className="flex flex-wrap gap-1">
                      {l.tags ? (
                        l.tags.split(',').filter(Boolean).map((t, idx) => (
                          <span key={idx} className="inline-block px-2 py-0.5 rounded bg-accent/10 text-accent text-xs font-medium">
                            {t.trim()}
                          </span>
                        ))
                      ) : (
                        <span className="text-gray-400 text-xs">-</span>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <StatusBadge status={l.status} />
                  </td>
                  <td className="px-4 py-3 text-center">
                    <RowActionMenu>
                      <ActionMenuItem
                        icon={<Eye className="h-4 w-4" />}
                        label="Lihat Detail"
                        onClick={() => navigate(`/admin/loker/${l.id}`)}
                      />
                      {l.status === 'Submission' ? (
                        <>
                          {canEdit && (
                            <>
                              <ActionMenuItem
                                icon={<Check className="h-4 w-4" />}
                                label="Terima Submission"
                                onClick={() => handleApprove(l)}
                              />
                              <ActionMenuItem
                                icon={<X className="h-4 w-4" />}
                                label="Tolak Submission"
                                danger
                                onClick={() => handleReject(l)}
                              />
                            </>
                          )}
                        </>
                      ) : (
                        <>
                          {canEdit && (
                            <ActionMenuItem
                              icon={<Pencil className="h-4 w-4" />}
                              label="Edit Loker"
                              onClick={() => navigate(`/admin/loker/${l.id}/edit`)}
                            />
                          )}
                        </>
                      )}
                      {canEdit && (l.status === 'Draft' || l.status === 'Archived') && (
                        <ActionMenuItem
                          icon={<Send className="h-4 w-4" />}
                          label="Publish Loker"
                          onClick={() => handlePublish(l)}
                        />
                      )}
                      {canEdit && l.status === 'Published' && (
                        <ActionMenuItem
                          icon={<ArchiveRestore className="h-4 w-4" />}
                          label="Set as Draft"
                          onClick={() => handleSetDraft(l)}
                        />
                      )}
                      {canEdit && (l.status === 'Published' || l.status === 'Draft') && (
                        <ActionMenuItem
                          icon={<ArchiveRestore className="h-4 w-4" />}
                          label="Arsipkan Loker"
                          onClick={() => handleArchive(l)}
                        />
                      )}
                      {canEdit && (
                        <ActionMenuItem
                          icon={<Trash2 className="h-4 w-4" />}
                          label="Hapus Loker"
                          danger
                          onClick={() => setDeleteTarget(l)}
                        />
                      )}
                    </RowActionMenu>
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
        open={deleteTarget !== null}
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
        onConfirm={confirmDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  )
}

function ActionMenuItem({
  icon,
  label,
  onClick,
  danger,
}: {
  icon: React.ReactNode
  label: string
  onClick: () => void
  danger?: boolean
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'w-full flex items-center gap-2 px-3 py-2 text-sm hover:bg-gray-50',
        danger ? 'text-danger hover:bg-danger-bg' : 'text-gray-700'
      )}
    >
      {icon}
      {label}
    </button>
  )
}
