import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { Search, Plus, Eye, Pencil, Trash2, Send, ArchiveRestore, Archive } from 'lucide-react'
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
import { formatDate, cn, getFileUrl, getThumbnailUrl } from '@/lib/utils'
import type { Agenda, AgendaStatus } from '@/types/agenda'

const PAGE_SIZE = 10

function StatusBadge({ status }: { status: AgendaStatus }) {
  if (status === 'Published') return <Badge variant="green">Published</Badge>
  if (status === 'Draft') return <Badge variant="orange">Draft</Badge>
  if (status === 'Archived') return <Badge variant="gray">Archived</Badge>
  if (status === 'Rejected') return <Badge variant="red">Rejected</Badge>
  return <Badge variant="blue">Submission</Badge>
}

function formatEventDate(iso: string) {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return '-'
  const date = d.toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
  const time = d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
  return `${date}, ${time}`
}

export function AgendaListPage() {
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const canEdit = user?.permissions?.includes('agenda_edit') ?? false

  const [data, setData] = useState<Agenda[]>([])
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
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<'all' | AgendaStatus>('all')
  const [page, setPage] = useState(1)
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [deleteTarget, setDeleteTarget] = useState<Agenda | null>(null)

  const fetchData = async () => {
    try {
      setIsLoading(true)
      const res = await api.get('/admin/agenda', {
        params: {
          page,
          limit: PAGE_SIZE,
          search: searchTerm,
          tab,
          status: statusFilter
        }
      })
      setData(res.data.data)
      setTotal(res.data.total)
      setSemuaCount(res.data.semuaCount)
      setSubmissionCount(res.data.submissionCount)
    } catch (error) {
      toast('Gagal memuat data agenda', 'error')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [page, tab, searchTerm, statusFilter])

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

  const handlePublish = async (a: Agenda) => {
    try {
      await api.post(`/admin/agenda/${a.id}/approve`)
      setData((prev) =>
        prev.map((item) => (item.id === a.id ? { ...item, status: 'Published' } : item)),
      )
      toast(`Agenda "${a.judul.slice(0, 40)}..." berhasil dipublish`, 'success')
    } catch (error) {
      toast('Gagal mempublish agenda', 'error')
    }
  }

  const handleReject = async (a: Agenda) => {
    try {
      await api.post(`/admin/agenda/${a.id}/reject`)
      setData((prev) =>
        prev.map((item) => (item.id === a.id ? { ...item, status: 'Rejected' } : item)),
      )
      toast(`Agenda "${a.judul.slice(0, 40)}..." berhasil ditolak`, 'info')
    } catch (error) {
      toast('Gagal menolak agenda', 'error')
    }
  }

  const handleSetDraft = async (a: Agenda) => {
    try {
      await api.put(`/admin/agenda/${a.id}`, { ...a, status: 'Draft' })
      setData((prev) =>
        prev.map((item) => (item.id === a.id ? { ...item, status: 'Draft' } : item)),
      )
      toast(`Agenda dipindahkan ke Draft`, 'info')
    } catch (error) {
      toast('Gagal mengubah status agenda', 'error')
    }
  }

  const handleArchive = async (a: Agenda) => {
    try {
      await api.put(`/admin/agenda/${a.id}`, { ...a, status: 'Archived' })
      setData((prev) =>
        prev.map((item) => (item.id === a.id ? { ...item, status: 'Archived' } : item)),
      )
      toast(`Agenda diarsipkan`, 'info')
    } catch (error) {
      toast('Gagal mengarsipkan agenda', 'error')
    }
  }

  const confirmDelete = async () => {
    if (!deleteTarget) return
    const target = deleteTarget
    setDeleteTarget(null)
    try {
      await api.delete(`/admin/agenda/${target.id}`)
      setData((prev) => prev.filter((item) => item.id !== target.id))
      toast(`Agenda "${target.judul.slice(0, 30)}..." berhasil dihapus`, 'success')
    } catch (error) {
      toast('Gagal menghapus agenda', 'error')
    }
  }

  if (isLoading) return <div className="p-10">Loading...</div>

  return (
    <div className="px-10 py-8">
      <Breadcrumb items={[{ label: 'Agenda' }]} />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">Data Agenda</h1>
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
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Judul</label>
          <Input
            placeholder="Cari Judul"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                setSearchTerm(searchInput)
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
            setSearchTerm(searchInput)
            setPage(1)
          }}
          rightIcon={<Search className="h-4 w-4" />}
        >
          Cari
        </Button>
        <div className="ml-auto">
          {canEdit && (
            <Button
              onClick={() => navigate('/admin/agenda/new')}
              rightIcon={<Plus className="h-4 w-4" />}
            >
              Tambah Agenda
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
                <th className="px-4 py-3 font-semibold">No. Event</th>
                <th className="px-4 py-3 font-semibold">Cover</th>
                <th className="px-4 py-3 font-semibold">Judul</th>
                <th className="px-4 py-3 font-semibold">Tags</th>
                <th className="px-4 py-3 font-semibold">Tanggal</th>
                <th className="px-4 py-3 font-semibold">Lokasi</th>
                <th className="px-4 py-3 font-semibold">Tanggal Dibuat</th>
                <th className="px-4 py-3 font-semibold">Dibuat Oleh</th>
                <th className="px-4 py-3 font-semibold">Status</th>
                <th className="px-4 py-3 font-semibold text-center">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {pageRows.length === 0 && (
                <tr>
                  <td colSpan={11} className="py-16 text-center text-gray-500">
                    Belum ada agenda untuk filter ini.
                  </td>
                </tr>
              )}
              {pageRows.map((a) => (
                <tr key={a.id} className="hover:bg-gray-50/60">
                  <td className="hidden px-4 py-3">
                    <Checkbox
                      checked={selected.has(a.id)}
                      onChange={() => toggleOne(a.id)}
                    />
                  </td>
                  <td className="px-4 py-3 text-gray-700">{a.noEvent}</td>
                  <td className="px-4 py-3">
                    {a.bannerThumbnailUrl || a.bannerUrl ? (
                      <img
                        src={getFileUrl(a.bannerThumbnailUrl || a.bannerUrl || '')}
                        alt={a.judul}
                        className="h-10 w-16 rounded object-cover bg-gray-100"
                        loading="lazy"
                      />
                    ) : (
                      <div className="h-10 w-16 rounded bg-gray-100" />
                    )}
                  </td>
                  <td className="px-4 py-3 font-medium text-gray-900 max-w-md">
                    <div className="line-clamp-1 break-all">{a.judul}</div>
                  </td>
                  <td className="px-4 py-3 max-w-[180px]">
                    {a.tags ? (
                      <div className="flex flex-wrap gap-1">
                        {a.tags.split(',').filter(Boolean).map((t, idx) => {
                          const trimmed = t.trim()
                          if (!trimmed) return null
                          return (
                            <span
                              key={idx}
                              className="inline-block px-2 py-0.5 rounded bg-accent/10 text-accent text-xs font-medium"
                            >
                              {trimmed}
                            </span>
                          )
                        })}
                      </div>
                    ) : (
                      <span className="text-gray-400 text-xs">-</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-gray-700 whitespace-nowrap">
                    {formatEventDate(a.tanggalEvent)}
                  </td>
                  <td className="px-4 py-3 text-gray-700">{a.lokasi}</td>
                  <td className="px-4 py-3 text-gray-700 whitespace-nowrap">
                    {formatDate(a.createdAt)}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <img
                        src={getThumbnailUrl(a.author.avatarUrl, a.author.nama)}
                        alt={a.author.nama}
                        className="h-7 w-7 rounded-full object-cover bg-gray-200"
                      />
                      <div className="text-sm text-gray-900 truncate max-w-[140px]">
                        {a.author.nama}
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <StatusBadge status={a.status} />
                  </td>
                  <td className="px-4 py-3 text-center">
                    <RowActionMenu>
                      <ActionMenuItem
                        icon={<Eye className="h-4 w-4" />}
                        label="Lihat Agenda"
                        onClick={() => navigate(`/admin/agenda/${a.id}`)}
                      />
                      {a.status === 'Submission' ? (
                        <>
                          {canEdit && (
                            <>
                              <ActionMenuItem
                                icon={<Send className="h-4 w-4" />}
                                label="Terima & Publish"
                                onClick={() => handlePublish(a)}
                              />
                              <ActionMenuItem
                                icon={<Pencil className="h-4 w-4" />}
                                label="Edit Agenda"
                                onClick={() => navigate(`/admin/agenda/${a.id}/edit`)}
                              />
                              <ActionMenuItem
                                icon={<Trash2 className="h-4 w-4" />}
                                label="Tolak"
                                danger
                                onClick={() => handleReject(a)}
                              />
                            </>
                          )}
                        </>
                      ) : (
                        <>
                          {canEdit && (
                            <ActionMenuItem
                              icon={<Pencil className="h-4 w-4" />}
                              label="Edit Agenda"
                              onClick={() => navigate(`/admin/agenda/${a.id}/edit`)}
                            />
                          )}
                          {canEdit && (a.status === 'Draft' || a.status === 'Archived') && (
                            <ActionMenuItem
                              icon={<Send className="h-4 w-4" />}
                              label="Publish Agenda"
                              onClick={() => handlePublish(a)}
                            />
                          )}
                          {canEdit && a.status === 'Published' && (
                            <ActionMenuItem
                              icon={<ArchiveRestore className="h-4 w-4" />}
                              label="Set as Draft"
                              onClick={() => handleSetDraft(a)}
                            />
                          )}
                          {canEdit && a.status !== 'Archived' && (
                            <ActionMenuItem
                              icon={<Archive className="h-4 w-4" />}
                              label="Arsipkan Agenda"
                              onClick={() => handleArchive(a)}
                            />
                          )}
                          {canEdit && (
                            <ActionMenuItem
                              icon={<Trash2 className="h-4 w-4" />}
                              label="Hapus Agenda"
                              danger
                              onClick={() => setDeleteTarget(a)}
                            />
                          )}
                        </>
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
        title="Hapus Agenda Ini?"
        description="Tindakan ini akan menghapus agenda secara permanen dari sistem dan tidak dapat dibatalkan. Apakah Anda yakin ingin melanjutkan?"
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
