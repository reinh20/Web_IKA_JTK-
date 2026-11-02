import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import {
  Search, Plus, Eye, Pencil, Trash2, UserX, UserCheck,
  Check, X, AlertTriangle,
} from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { Tabs } from '@/components/ui/Tabs'
import { Input } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Pagination } from '@/components/ui/Pagination'
import { Checkbox } from '@/components/ui/Checkbox'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { RowActionMenu } from '@/components/ui/RowActionMenu'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { cn, formatDate, getThumbnailUrl } from '@/lib/utils'
import type { Alumni } from '@/types/alumni'
import { AlumniStatus } from '@/types/alumni'

import { useAuthStore } from '@/stores/authStore'
import { getFriendlyErrorMessage } from '../../utils/errorHandler';

const PAGE_SIZE = 10

function StatusBadge({ status }: { status: AlumniStatus }) {
  if (status === AlumniStatus.ACTIVE || status === AlumniStatus.APPROVED) return <Badge variant="green">{status}</Badge>
  if (status === AlumniStatus.INACTIVE) return <Badge variant="gray">{status}</Badge>
  if (status === AlumniStatus.REJECTED) return <Badge variant="red">{status}</Badge>
  return <Badge variant="orange">{status}</Badge>
}

export function AlumniListPage() {
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const isViewer = !(user?.permissions?.includes('alumni_edit') ?? false)

  const [data, setData] = useState<Alumni[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [searchParams, setSearchParams] = useSearchParams()
  const tabParam = searchParams.get('tab')
  const validTabs: Array<'semua' | 'baru'> = ['semua', 'baru']
  const tab: 'semua' | 'baru' = tabParam && validTabs.includes(tabParam as any)
    ? (tabParam as 'semua' | 'baru')
    : 'semua'
  const [searchInput, setSearchInput] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const [semuaCount, setSemuaCount] = useState(0)
  const [baruCount, setBaruCount] = useState(0)
  const [selected, setSelected] = useState<Set<string>>(new Set())

  const [deleteTarget, setDeleteTarget] = useState<Alumni | null>(null)
  const [nonactivateTarget, setNonactivateTarget] = useState<Alumni | null>(null)
  const [activateTarget, setActivateTarget] = useState<Alumni | null>(null)
  const [acceptTarget, setAcceptTarget] = useState<Alumni | null>(null)
  const [rejectTarget, setRejectTarget] = useState<Alumni | null>(null)
  const [setPendingTarget, setSetPendingTarget] = useState<Alumni | null>(null)

  const [rejectReason, setRejectReason] = useState('')

  const [isAccepting, setIsAccepting] = useState(false)
  const [isRejecting, setIsRejecting] = useState(false)

  const fetchData = async () => {
    try {
      setIsLoading(true)
      const res = await api.get('/admin/alumni', {
        params: {
          page,
          limit: PAGE_SIZE,
          search: appliedSearch,
          tab,
        }
      })
      setData(res.data.data)
      setTotal(res.data.total)
      setSemuaCount(res.data.semuaCount)
      setBaruCount(res.data.baruCount)
    } catch (error) {
      toast('Gagal memuat data alumni', 'error')
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
    next.has(id) ? next.delete(id) : next.add(id)
    setSelected(next)
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    const nama = deleteTarget.nama
    try {
      await api.delete(`/admin/alumni/${deleteTarget.id}`)
      toast(`Alumni "${nama}" berhasil dihapus`, 'success')
      fetchData()
    } catch (error) {
      toast('Gagal menghapus alumni', 'error')
    } finally {
      setDeleteTarget(null)
    }
  }

  const handleNonactivate = async () => {
    if (!nonactivateTarget) return
    try {
      await api.put(`/admin/alumni/${nonactivateTarget.id}`, { status: AlumniStatus.INACTIVE })
      toast('Status alumni diperbarui ke Inactive', 'info')
      fetchData()
    } catch (error) {
      toast('Gagal menonaktifkan alumni', 'error')
    } finally {
      setNonactivateTarget(null)
    }
  }

  const handleActivate = async () => {
    if (!activateTarget) return
    try {
      await api.put(`/admin/alumni/${activateTarget.id}`, { status: AlumniStatus.ACTIVE })
      toast('Status alumni diperbarui ke Active', 'success')
      fetchData()
    } catch (error) {
      toast('Gagal mengaktifkan alumni', 'error')
    } finally {
      setActivateTarget(null)
    }
  }

  const handleAccept = async () => {
    if (!acceptTarget) return
    setIsAccepting(true)
    try {
      await api.post(`/admin/alumni/${acceptTarget.id}/approve`)
      toast(`Pendaftaran alumni "${acceptTarget.nama}" diterima`, 'success')
      fetchData()
    } catch (error: any) {
      toast(getFriendlyErrorMessage(error, 'Gagal menerima alumni'), 'error')
    } finally {
      setIsAccepting(false)
      setAcceptTarget(null)
    }
  }

  const handleReject = async () => {
    if (!rejectTarget) return
    if (!rejectReason.trim()) {
      toast('Alasan penolakan wajib diisi', 'error')
      return
    }
    setIsRejecting(true)
    try {
      await api.post(`/admin/alumni/${rejectTarget.id}/reject`, { reason: rejectReason })
      toast(`Pendaftaran alumni "${rejectTarget.nama}" ditolak`, 'info')
      fetchData()
    } catch (error: any) {
      toast(getFriendlyErrorMessage(error, 'Gagal menolak alumni'), 'error')
    } finally {
      setIsRejecting(false)
      setRejectTarget(null)
      setRejectReason('')
    }
  }

  const handleSetPending = async () => {
    if (!setPendingTarget) return
    try {
      await api.put(`/admin/alumni/${setPendingTarget.id}`, { status: AlumniStatus.PENDING })
      toast(`Status alumni "${setPendingTarget.nama}" dikembalikan ke Pending untuk verifikasi ulang`, 'success')
      fetchData()
    } catch (error: any) {
      toast(getFriendlyErrorMessage(error, 'Gagal mengubah status alumni'), 'error')
    } finally {
      setSetPendingTarget(null)
    }
  }

  if (isLoading) return <div className="p-10">Loading...</div>

  return (
    <div className="px-10 py-8">
      <Breadcrumb items={[{ label: 'Alumni' }]} />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">Data Alumni</h1>
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
            { key: 'semua', label: 'Alumni Terverifikasi', count: semuaCount },
            { key: 'baru', label: 'Alumni Baru', count: baruCount, hasDot: baruCount > 0 },
          ]}
        />
      </div>

      <div className="mt-6 flex flex-wrap items-end gap-4">
        <div className="flex-1 min-w-[280px] max-w-md">
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Nama</label>
          <Input
            placeholder="Cari Nama"
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
        {tab === 'semua' && !isViewer && (
          <div className="ml-auto">
            <Button
              onClick={() => navigate('/admin/alumni/new')}
              rightIcon={<Plus className="h-4 w-4" />}
            >
              Tambah Alumni
            </Button>
          </div>
        )}
      </div>

      <div className="mt-6 overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          {tab === 'semua' ? (
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-100 text-gray-700 text-left">
                  <th className="hidden w-12 px-4 py-3">
                    <Checkbox checked={allChecked} onChange={toggleAll} />
                  </th>
                  <th className="px-4 py-3 font-semibold">No. Alumni</th>
                  <th className="px-4 py-3 font-semibold">Image</th>
                  <th className="px-4 py-3 font-semibold">Nama</th>
                  <th className="px-4 py-3 font-semibold">Angkatan</th>
                  <th className="px-4 py-3 font-semibold">Keanggotaan</th>
                  <th className="px-4 py-3 font-semibold">Status</th>
                  <th className="px-4 py-3 font-semibold">Verifikasi</th>
                  <th className="px-4 py-3 font-semibold text-center">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {pageRows.length === 0 && (
                  <tr>
                    <td colSpan={8} className="py-16 text-center text-gray-500">
                      Belum ada alumni untuk filter ini.
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
                    <td className="px-4 py-3 text-gray-700">{a.noAlumni}</td>
                    <td className="px-4 py-3">
                      <img
                        src={getThumbnailUrl(a.avatarUrl, a.nama)}
                        alt={a.nama}
                        className="h-9 w-9 rounded object-cover bg-gray-200"
                      />
                    </td>
                    <td className="px-4 py-3 font-medium text-gray-900">{a.nama}</td>
                    <td className="px-4 py-3 text-gray-700">{a.angkatan}</td>
                    <td className="px-4 py-3">
                      <Badge variant={
                        a.keanggotaan === 'Executive' ? 'blue' : 
                        (a.keanggotaan === 'Advisory Board' || a.keanggotaan === 'Supervisory Board' ? 'navy' : 'gray')
                      }>
                        {a.keanggotaan || 'Alumni'}
                      </Badge>
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={a.status} />
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col gap-1">
                        {a.emailVerified ? (
                          <Badge variant="green" className="text-[10px] px-1.5 py-0.5 w-max">Email ✓</Badge>
                        ) : (
                          <Badge variant="gray" className="text-[10px] px-1.5 py-0.5 w-max">Email ✗</Badge>
                        )}
                        {a.phoneVerified ? (
                          <Badge variant="green" className="text-[10px] px-1.5 py-0.5 w-max">HP ✓</Badge>
                        ) : (
                          <Badge variant="gray" className="text-[10px] px-1.5 py-0.5 w-max">HP ✗</Badge>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-center">
                      <RowActionMenu width={192}>
                        <ActionMenuItem
                          icon={<Eye className="h-4 w-4" />}
                          label="Lihat Profile"
                          onClick={() => navigate(`/admin/alumni/${a.id}`)}
                        />
                        {!isViewer && (
                          <>
                            <ActionMenuItem
                              icon={<Pencil className="h-4 w-4" />}
                              label="Edit Alumni"
                              onClick={() => navigate(`/admin/alumni/${a.id}/edit`)}
                            />
                            {a.status === AlumniStatus.ACTIVE && (
                              <ActionMenuItem
                                icon={<UserX className="h-4 w-4" />}
                                label="Nonaktifkan Alumni"
                                onClick={() => setNonactivateTarget(a)}
                              />
                            )}
                            {a.status === AlumniStatus.INACTIVE && (
                              <ActionMenuItem
                                icon={<UserCheck className="h-4 w-4" />}
                                label="Aktifkan Alumni"
                                onClick={() => setActivateTarget(a)}
                              />
                            )}
                            {a.status === AlumniStatus.REJECTED && (
                              <ActionMenuItem
                                icon={<UserCheck className="h-4 w-4" />}
                                label="Verifikasi Ulang"
                                onClick={() => setSetPendingTarget(a)}
                              />
                            )}
                            {a.status !== AlumniStatus.ACTIVE && a.status !== AlumniStatus.APPROVED && a.status !== AlumniStatus.INACTIVE && (
                              <ActionMenuItem
                                icon={<Trash2 className="h-4 w-4" />}
                                label="Hapus Alumni"
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
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-100 text-gray-700 text-left">
                  <th className="px-4 py-3 font-semibold">Nama</th>
                  <th className="px-4 py-3 font-semibold">Angkatan</th>
                  <th className="px-4 py-3 font-semibold">Tanggal Lahir</th>
                  <th className="px-4 py-3 font-semibold">Email</th>
                  <th className="px-4 py-3 font-semibold">Username</th>
                  <th className="px-4 py-3 font-semibold">Verifikasi</th>
                  <th className="px-4 py-3 font-semibold text-center">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {pageRows.length === 0 && (
                  <tr>
                    <td colSpan={6} className="py-16 text-center text-gray-500">
                      Belum ada pendaftaran alumni baru.
                    </td>
                  </tr>
                )}
                {pageRows.map((a) => (
                  <tr key={a.id} className="hover:bg-gray-50/60">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <img
                          src={getThumbnailUrl(a.avatarUrl, a.nama)}
                          alt={a.nama}
                          className="h-8 w-8 rounded-full object-cover bg-gray-200"
                        />
                        <button
                          type="button"
                          onClick={() => navigate(`/admin/alumni/${a.id}`)}
                          className="font-medium text-gray-900 hover:underline"
                        >
                          {a.nama}
                        </button>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-gray-700">{a.angkatan}</td>
                    <td className="px-4 py-3 text-gray-700 whitespace-nowrap">
                      {a.tanggalLahir ? formatDate(a.tanggalLahir) : '-'}
                    </td>
                    <td className="px-4 py-3 text-gray-700">{a.email}</td>
                    <td className="px-4 py-3 text-gray-700">{a.username}</td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col gap-1">
                        {a.emailVerified ? (
                          <Badge variant="green" className="text-[10px] px-1.5 py-0.5 w-max">Email ✓</Badge>
                        ) : (
                          <Badge variant="gray" className="text-[10px] px-1.5 py-0.5 w-max">Email ✗</Badge>
                        )}
                        {a.phoneVerified ? (
                          <Badge variant="green" className="text-[10px] px-1.5 py-0.5 w-max">HP ✓</Badge>
                        ) : (
                          <Badge variant="gray" className="text-[10px] px-1.5 py-0.5 w-max">HP ✗</Badge>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-center">
                      {!isViewer ? (
                        <div className="inline-flex items-center gap-3">
                          <button
                            type="button"
                            onClick={() => setAcceptTarget(a)}
                            className="text-sm font-semibold text-primary hover:underline"
                          >
                            Terima
                          </button>
                          <span className="text-gray-300">|</span>
                          <button
                            type="button"
                            onClick={() => setRejectTarget(a)}
                            className="text-sm font-semibold text-danger hover:underline"
                          >
                            Tolak
                          </button>
                        </div>
                      ) : (
                        <span className="text-sm text-gray-400">Tidak ada aksi</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
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
        title="Hapus Alumni Ini?"
        description="Tindakan ini akan menghapus data alumni secara permanen dari sistem dan tidak dapat dibatalkan. Apakah Anda yakin ingin melanjutkan?"
        confirmLabel="Hapus"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />

      <ConfirmDialog
        open={nonactivateTarget !== null}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-accent-light text-accent">
            <AlertTriangle className="h-6 w-6" />
          </div>
        }
        title="Nonaktifkan Alumni Ini?"
        description="Alumni ini tidak akan memiliki akses ke platform IKA JTK. Anda dapat mengaktifkannya kembali kapan saja melalui halaman manajemen alumni."
        confirmLabel="Nonaktifkan"
        cancelLabel="Batalkan"
        variant="accent"
        onConfirm={handleNonactivate}
        onCancel={() => setNonactivateTarget(null)}
      />

      <ConfirmDialog
        open={activateTarget !== null}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-success-bg text-success">
            <Check className="h-6 w-6" />
          </div>
        }
        title="Aktifkan Alumni?"
        description="Alumni ini akan dapat kembali mengakses platform IKA JTK dan melihat seluruh fitur portal alumni."
        confirmLabel="Aktifkan"
        cancelLabel="Batal"
        onConfirm={handleActivate}
        onCancel={() => setActivateTarget(null)}
      />

      <ConfirmDialog
        open={acceptTarget !== null}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-success-bg text-success">
            <Check className="h-6 w-6" />
          </div>
        }
        title="Terima Pendaftaran Alumni?"
        description="Alumni ini akan diaktifkan dan dapat mengakses sistem. Pastikan data sudah sesuai dengan database IKA JTK. (Proses ini mungkin membutuhkan waktu beberapa detik untuk mengirimkan email)"
        confirmLabel="Terima"
        cancelLabel="Batal"
        onConfirm={handleAccept}
        onCancel={() => setAcceptTarget(null)}
        loading={isAccepting}
      />

      <ConfirmDialog
        open={rejectTarget !== null}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-danger-bg text-danger">
            <X className="h-6 w-6" />
          </div>
        }
        title="Tolak Pendaftaran Alumni?"
        description={
          <div className="mt-2 text-left">
            <p className="text-sm text-gray-500 mb-4">
              Pendaftaran alumni akan ditolak dan datanya akan dihapus dari sistem. Tindakan ini tidak dapat dibatalkan.
            </p>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Alasan Penolakan <span className="text-danger">*</span>
            </label>
            <textarea
              className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-1 focus:ring-danger focus:border-danger sm:text-sm"
              rows={3}
              placeholder="Contoh: Bukan merupakan alumni JTK..."
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
            />
          </div>
        }
        confirmLabel="Tolak"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleReject}
        onCancel={() => {
          setRejectTarget(null)
          setRejectReason('')
        }}
        loading={isRejecting}
      />

      <ConfirmDialog
        open={setPendingTarget !== null}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-success-bg text-success">
            <Check className="h-6 w-6" />
          </div>
        }
        title="Verifikasi Ulang Alumni?"
        description={`Alumni "${setPendingTarget?.nama}" akan dikembalikan ke status Pending untuk diverifikasi ulang. Alumni juga dapat melengkapi data sebelum verifikasi.`}
        confirmLabel="Ya, Verifikasi Ulang"
        cancelLabel="Batal"
        onConfirm={handleSetPending}
        onCancel={() => setSetPendingTarget(null)}
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
