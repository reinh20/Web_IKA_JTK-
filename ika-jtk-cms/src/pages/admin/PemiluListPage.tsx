import { useState, useEffect } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Plus, Vote, Users, Calendar, ChevronRight, Loader2 } from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Tabs } from '@/components/ui/Tabs'
import { Pagination } from '@/components/ui/Pagination'
import { formatDate, stripHtml } from '@/lib/utils'
import type { Election, ElectionStatus } from '@/types/election'
import api from '@/lib/api'
import { toast } from '@/components/ui/Toast'
import { useAuthStore } from '@/stores/authStore'

function StatusBadge({ status, periodeEnd }: { status: ElectionStatus; periodeEnd?: string }) {
  if ((status === 'Ongoing' || status === 'Active' || (status as string) === 'Sedang Berlangsung') && periodeEnd && new Date(periodeEnd).getTime() <= Date.now()) {
    return <Badge variant="blue">Selesai</Badge>
  }
  if (status === 'Ongoing') return <Badge variant="green">Sedang Berlangsung</Badge>
  if (status === 'Active') return <Badge variant="green">Aktif</Badge>
  if (status === 'Draft') return <Badge variant="orange">Draft</Badge>
  if (status === 'Completed') return <Badge variant="blue">Selesai</Badge>
  if (status === 'Closed') return <Badge variant="gray">Ditutup</Badge>
  return <Badge variant="gray">{status}</Badge>
}

export function PemiluListPage() {
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const canEdit = user?.permissions?.includes('pemilu_edit') ?? false
  const [tab, setTab] = useState<'semua' | 'berlangsung' | 'draft' | 'selesai'>('semua')
  const [elections, setElections] = useState<Election[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const PAGE_SIZE = 10

  const fetchElections = async (currentPage = page, silent = false) => {
    try {
      if (!silent) setLoading(true)
      const data = await api.getElections({ page: currentPage, limit: PAGE_SIZE })
      if (data && data.data) {
        const formattedData = data.data.map((item: any) => ({
          ...item,
          totalVoter: item.totalVoter || 0,
          totalSuara: item.totalSuara || 0,
          kandidat: item.candidates || item.kandidat || [],
        }))
        setElections(formattedData)
        setTotal(data.total || 0)
      } else {
        const formattedData = data.map((item: any) => ({
          ...item,
          totalVoter: item.totalVoter || 0,
          totalSuara: item.totalSuara || 0,
          kandidat: item.candidates || item.kandidat || [],
        }))
        setElections(formattedData)
        setTotal(formattedData.length)
      }
    } catch (error: any) {
      toast('Gagal mengambil data pemilu', 'error')
      console.error(error)
    } finally {
      if (!silent) setLoading(false)
    }
  }

  useEffect(() => {
    fetchElections(page)
  }, [page])

  const isCompleted = (e: Election) => {
    if (e.status === 'Completed' || e.status === 'Closed') return true
    if ((e.status === 'Ongoing' || e.status === 'Active' || (e.status as string) === 'Sedang Berlangsung') && e.periodeEnd && new Date(e.periodeEnd).getTime() <= Date.now()) {
      return true
    }
    return false
  }

  const isOngoing = (e: Election) => {
    return (e.status === 'Ongoing' || e.status === 'Active' || (e.status as string) === 'Sedang Berlangsung') && (!e.periodeEnd || new Date(e.periodeEnd).getTime() > Date.now())
  }

  const filtered = elections.filter((e) => {
    if (tab === 'berlangsung') return isOngoing(e)
    if (tab === 'draft') return e.status === 'Draft'
    if (tab === 'selesai') return isCompleted(e)
    return true
  })

  // Hitung jumlah data berdasarkan status secara dinamis
  const semuaCount = total
  const berlangsungCount = elections.filter(isOngoing).length
  const draftCount = elections.filter((e) => e.status === 'Draft').length
  const selesaiCount = elections.filter(isCompleted).length
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE))

  if (loading) return <div className="p-10">Loading...</div>

  return (
    <div className="px-10 py-8">
      <Breadcrumb items={[{ label: 'Pemilu' }]} />
      <div className="mt-2 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Data Pemilu</h1>
          <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />
        </div>
        {canEdit && (
          <Button
            onClick={() => navigate('/admin/pemilu/new')}
            rightIcon={<Plus className="h-4 w-4" />}
          >
            Buat Pemilu
          </Button>
        )}
      </div>

      <div className="mt-8">
        <Tabs
          value={tab}
          onChange={(v) => setTab(v as typeof tab)}
          items={[
            { key: 'semua', label: 'Semua', count: semuaCount },
            { key: 'berlangsung', label: 'Berlangsung', count: berlangsungCount, hasDot: berlangsungCount > 0 },
            { key: 'draft', label: 'Draft', count: draftCount },
            { key: 'selesai', label: 'Selesai', count: selesaiCount },
          ]}
        />
      </div>

      <div className="mt-6 grid grid-cols-1 gap-4">
        {loading && (
          <div className="flex flex-col items-center justify-center py-16 text-gray-500 bg-white rounded-lg border border-gray-200">
            <Loader2 className="h-8 w-8 animate-spin text-primary mb-4" />
            <p>Memuat data pemilu...</p>
          </div>
        )}
        {!loading && filtered.length === 0 && (
          <div className="text-center py-16 text-gray-500 bg-white rounded-lg border border-gray-200">
            Belum ada pemilu untuk filter ini.
          </div>
        )}
        {!loading && filtered.map((e) => {
          const turnout = e.totalVoter > 0
            ? Math.round((e.totalSuara / e.totalVoter) * 100)
            : 0
          return (
            <Link
              key={e.id}
              to={`/admin/pemilu/${e.id}`}
              className="block rounded-lg border border-gray-200 bg-white p-6 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-2">
                    <Vote className="h-4 w-4 text-primary" />
                    <StatusBadge status={e.status} periodeEnd={e.periodeEnd} />
                  </div>
                  <h2 className="text-xl font-bold text-gray-900 mb-1">{e.judul}</h2>
                  <p className="text-sm text-gray-600 line-clamp-2">{stripHtml(e.deskripsi)}</p>

                  <div className="mt-4 flex flex-wrap items-center gap-x-6 gap-y-2 text-sm text-gray-700">
                    <span className="inline-flex items-center gap-1.5">
                      <Calendar className="h-3.5 w-3.5 text-gray-400" />
                      {formatDate(e.periodeStart)} – {formatDate(e.periodeEnd)}
                    </span>
                    <span className="inline-flex items-center gap-1.5">
                      <Users className="h-3.5 w-3.5 text-gray-400" />
                      {(e.kandidat || []).length} kandidat
                    </span>
                    <span className="inline-flex items-center gap-1.5">
                      <Vote className="h-3.5 w-3.5 text-gray-400" />
                      {(e.totalSuara ?? 0).toLocaleString('id-ID')} suara ({turnout}%)
                    </span>
                  </div>

                  {e.status === 'Ongoing' && (
                    <div className="mt-4">
                      <div className="h-1.5 w-full bg-gray-100 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-success rounded-full"
                          style={{ width: `${turnout}%` }}
                        />
                      </div>
                      <p className="mt-1 text-xs text-gray-500">
                        Partisipasi: {(e.totalSuara ?? 0).toLocaleString('id-ID')} / {(e.totalVoter ?? 0).toLocaleString('id-ID')} ({turnout}%)
                      </p>
                    </div>
                  )}
                </div>
                <ChevronRight className="h-5 w-5 text-gray-400" />
              </div>
            </Link>
          )
        })}
      </div>
      
      {totalPages > 1 && (
        <div className="mt-6 flex justify-center">
          <Pagination
            page={page}
            totalPages={totalPages}
            onChange={setPage}
          />
        </div>
      )}
    </div>
  )
}
