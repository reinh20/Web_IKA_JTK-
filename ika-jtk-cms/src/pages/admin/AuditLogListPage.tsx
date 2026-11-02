import { useEffect, useState } from 'react'
import { Eye, Search } from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { Input } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Pagination } from '@/components/ui/Pagination'
import { toast } from '@/components/ui/Toast'
import { AuditLogDetailModal } from '@/components/admin/AuditLogDetailModal'
import api from '@/lib/api'
import {
  type AuditLogEntry,
  type AuditLogListResponse,
  AUDIT_ACTIONS,
  AUDIT_ENTITY_TYPES,
  AUDIT_SOURCES,
} from '@/types/auditLog'

const PAGE_SIZE = 20

function actionVariant(action: string): 'green' | 'orange' | 'red' | 'gray' | 'blue' {
  if (action === 'create' || action === 'approve' || action === 'login' || action === 'restore') return 'green'
  if (action === 'delete' || action === 'reject') return 'red'
  if (action === 'update' || action === 'permission_change') return 'orange'
  if (action === 'logout') return 'gray'
  return 'blue'
}

function sourceVariant(source: string): 'green' | 'orange' | 'gray' {
  if (source === 'cms') return 'green'
  if (source === 'portal') return 'orange'
  return 'gray'
}

function actorTypeVariant(t: string | null): 'blue' | 'orange' | 'gray' {
  if (t === 'admin') return 'blue'
  if (t === 'alumni') return 'orange'
  return 'gray'
}

function formatTimestamp(iso: string): string {
  const d = new Date(iso)
  if (isNaN(d.getTime())) return iso
  return d.toLocaleString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export function AuditLogListPage() {
  const [data, setData] = useState<AuditLogEntry[]>([])
  const [total, setTotal] = useState(0)
  const [totalPages, setTotalPages] = useState(1)
  const [isLoading, setIsLoading] = useState(true)

  const [page, setPage] = useState(1)
  const [searchInput, setSearchInput] = useState('')
  const [search, setSearch] = useState('')
  const [action, setAction] = useState('')
  const [source, setSource] = useState('')
  const [entityType, setEntityType] = useState('')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')

  const [detailEntry, setDetailEntry] = useState<AuditLogEntry | null>(null)

  const fetchData = async () => {
    try {
      setIsLoading(true)
      const params: Record<string, string> = { page: String(page), perPage: String(PAGE_SIZE) }
      if (search) params.search = search
      if (action) params.action = action
      if (source) params.source = source
      if (entityType) params.entityType = entityType
      if (dateFrom) params.dateFrom = dateFrom
      if (dateTo) params.dateTo = dateTo

      const res = await api.get<AuditLogListResponse>('/admin/audit-logs', { params })
      setData(res.data.data || [])
      setTotal(res.data.meta?.total || 0)
      setTotalPages(res.data.meta?.totalPages || 1)
    } catch (error) {
      toast('Gagal memuat log aktivitas', 'error')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, search, action, source, entityType, dateFrom, dateTo])

  const applySearch = () => {
    setPage(1)
    setSearch(searchInput.trim())
  }

  const resetFilters = () => {
    setSearchInput('')
    setSearch('')
    setAction('')
    setSource('')
    setEntityType('')
    setDateFrom('')
    setDateTo('')
    setPage(1)
  }

  return (
    <div className="px-10 py-8">
      <Breadcrumb items={[{ label: 'Log Aktivitas' }]} />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">Log Aktivitas</h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 grid grid-cols-1 md:grid-cols-6 gap-3">
        <div className="md:col-span-2">
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Cari</label>
          <div className="flex gap-2">
            <Input
              placeholder="Cari deskripsi atau nama user..."
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') applySearch()
              }}
            />
            <Button variant="outline" onClick={applySearch} rightIcon={<Search className="h-4 w-4" />}>
              Cari
            </Button>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Source</label>
          <select
            className="w-full h-10 rounded-md border border-gray-300 px-3 text-sm focus:outline-none focus:ring-1 focus:ring-primary"
            value={source}
            onChange={(e) => { setSource(e.target.value); setPage(1) }}
          >
            <option value="">Semua</option>
            {AUDIT_SOURCES.map((s) => (
              <option key={s.value} value={s.value}>{s.label}</option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Action</label>
          <select
            className="w-full h-10 rounded-md border border-gray-300 px-3 text-sm focus:outline-none focus:ring-1 focus:ring-primary"
            value={action}
            onChange={(e) => { setAction(e.target.value); setPage(1) }}
          >
            <option value="">Semua</option>
            {AUDIT_ACTIONS.map((a) => (
              <option key={a.value} value={a.value}>{a.label}</option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Entity</label>
          <select
            className="w-full h-10 rounded-md border border-gray-300 px-3 text-sm focus:outline-none focus:ring-1 focus:ring-primary"
            value={entityType}
            onChange={(e) => { setEntityType(e.target.value); setPage(1) }}
          >
            <option value="">Semua</option>
            {AUDIT_ENTITY_TYPES.map((e) => (
              <option key={e.value} value={e.value}>{e.label}</option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Dari</label>
          <input
            type="date"
            className="w-full h-10 rounded-md border border-gray-300 px-3 text-sm focus:outline-none focus:ring-1 focus:ring-primary"
            value={dateFrom}
            onChange={(e) => { setDateFrom(e.target.value); setPage(1) }}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Sampai</label>
          <input
            type="date"
            className="w-full h-10 rounded-md border border-gray-300 px-3 text-sm focus:outline-none focus:ring-1 focus:ring-primary"
            value={dateTo}
            onChange={(e) => { setDateTo(e.target.value); setPage(1) }}
          />
        </div>

        <div className="md:col-span-6">
          <Button variant="ghost" onClick={resetFilters}>Reset filter</Button>
        </div>
      </div>

      <div className="mt-4 overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-100 text-gray-700 text-left">
                <th className="px-4 py-3 font-semibold whitespace-nowrap">Waktu</th>
                <th className="px-4 py-3 font-semibold">User</th>
                <th className="px-4 py-3 font-semibold">Source</th>
                <th className="px-4 py-3 font-semibold">Action</th>
                <th className="px-4 py-3 font-semibold">Entity</th>
                <th className="px-4 py-3 font-semibold">Deskripsi</th>
                <th className="px-4 py-3 font-semibold text-center">Detail</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {isLoading && (
                <tr>
                  <td colSpan={7} className="py-16 text-center text-gray-500">Memuat data...</td>
                </tr>
              )}
              {!isLoading && data.length === 0 && (
                <tr>
                  <td colSpan={7} className="py-16 text-center text-gray-500">Belum ada log aktivitas untuk filter ini.</td>
                </tr>
              )}
              {!isLoading && data.map((row) => (
                <tr key={row.id} className="hover:bg-gray-50/60">
                  <td className="px-4 py-3 text-gray-700 whitespace-nowrap">{formatTimestamp(row.createdAt)}</td>
                  <td className="px-4 py-3">
                    <div className="flex flex-col">
                      <span className="font-medium text-gray-900">{row.actorName || 'System'}</span>
                      {row.actorType && (
                        <Badge variant={actorTypeVariant(row.actorType)} className="mt-1 w-fit">{row.actorType}</Badge>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <Badge variant={sourceVariant(row.source)}>{row.source.toUpperCase()}</Badge>
                  </td>
                  <td className="px-4 py-3">
                    <Badge variant={actionVariant(row.action)}>{row.action}</Badge>
                  </td>
                  <td className="px-4 py-3 text-gray-700">
                    {row.entityType || '—'}
                  </td>
                  <td className="px-4 py-3 text-gray-700 max-w-md">
                    <span className="line-clamp-2">{row.description || '—'}</span>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <button
                      type="button"
                      onClick={() => setDetailEntry(row)}
                      className="inline-flex items-center justify-center h-8 w-8 rounded-md text-gray-600 hover:bg-gray-100"
                      aria-label="Lihat detail"
                    >
                      <Eye className="h-4 w-4" />
                    </button>
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
            : `Menampilkan ${(page - 1) * PAGE_SIZE + 1}–${Math.min(page * PAGE_SIZE, total)} dari ${total} log`}
        </p>
        <Pagination page={page} totalPages={totalPages} onChange={setPage} />
      </div>

      <AuditLogDetailModal entry={detailEntry} onClose={() => setDetailEntry(null)} />
    </div>
  )
}
