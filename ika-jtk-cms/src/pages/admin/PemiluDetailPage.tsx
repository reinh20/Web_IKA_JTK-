import { Navigate, useNavigate, useParams } from 'react-router-dom'
import { useState, useEffect } from 'react'
import {
  Pencil, Trash2, Send, Plus, Users, Vote, Calendar,
  Award, AlertTriangle, Check, X, Loader2, RefreshCw
} from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { toast } from '@/components/ui/Toast'
import { formatDate, getAvatarUrl } from '@/lib/utils'
import type { Election, ElectionStatus, Kandidat } from '@/types/election'
import api from '@/lib/api'
import { useAuthStore } from '@/stores/authStore'
import { getFriendlyErrorMessage } from '../../utils/errorHandler';

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

export function PemiluDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const user = useAuthStore((state) => state.user)
  const canEdit = user?.permissions?.includes('pemilu_edit') ?? false

  const [election, setElection] = useState<Election | null>(null)
  const [loading, setLoading] = useState(true)

  const [confirmStart, setConfirmStart] = useState(false)
  const [confirmClose, setConfirmClose] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [confirmDeleteKandidat, setConfirmDeleteKandidat] = useState<Kandidat | null>(null)
  const [actionLoading, setActionLoading] = useState(false)

  const [summary, setSummary] = useState<any>(null)
  const [summaryLoading, setSummaryLoading] = useState(false)

  const fetchSummary = async () => {
    if (!id) return
    try {
      setSummaryLoading(true)
      const data = await api.getElectionSummary(id)
      setSummary(data)
    } catch (err) {
      // silent fail
    } finally {
      setSummaryLoading(false)
    }
  }

  useEffect(() => {
    if (election?.status === 'Ongoing' || election?.status === 'Active') {
      fetchSummary()
    }
  }, [id, election?.status])

  const fetchElection = async (silent = false) => {
    if (!id) return
    try {
      if (!silent) setLoading(true)
      const data = await api.getElectionById(id)
      setElection({
        ...data,
        totalVoter: data.totalVoter || 0,
        totalSuara: data.totalSuara || 0,
        kandidat: data.candidates || [],
      })
    } catch (err) {
      toast('Gagal memuat detail pemilu', 'error')
      navigate('/admin/pemilu')
    } finally {
      if (!silent) setLoading(false)
    }
  }

  useEffect(() => {
    fetchElection()
  }, [id])

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-32 text-gray-500">
        <Loader2 className="h-8 w-8 animate-spin text-primary mb-4" />
        <p>Memuat detail pemilu...</p>
      </div>
    )
  }



  if (!election) return <Navigate to="/admin/pemilu" replace />

  const turnout = (election.totalVoter ?? 0) > 0
    ? Math.round(((election.totalSuara ?? 0) / election.totalVoter) * 100)
    : 0

  const sortedKandidat = [...(election.kandidat || [])].sort((a, b) => (b?.voteCount ?? 0) - (a?.voteCount ?? 0))
  const winner = sortedKandidat[0]

  const handleStart = async () => {
    if (!id) return
    setConfirmStart(false)
    setActionLoading(true)
    try {
      await api.updateElection(id, { status: 'Ongoing' })
      toast('Pemilu berhasil dimulai', 'success')
      fetchElection()
    } catch (err: any) {
      const msg = err.response?.data?.error || 'Gagal memulai pemilu'
      toast(msg, 'error')
    } finally {
      setActionLoading(false)
    }
  }

  const handleClose = async () => {
    if (!id) return
    setConfirmClose(false)
    setActionLoading(true)
    try {
      await api.updateElection(id, { status: 'Completed' })
      toast('Pemilu berhasil ditutup', 'success')
      fetchElection()
    } catch (err: any) {
      const msg = err.response?.data?.error || 'Gagal menutup pemilu'
      toast(msg, 'error')
    } finally {
      setActionLoading(false)
    }
  }

  const handleDelete = async () => {
    if (!id) return
    setConfirmDelete(false)
    setActionLoading(true)
    try {
      await api.deleteElection(id)
      toast('Pemilu berhasil dihapus', 'success')
      navigate('/admin/pemilu')
    } catch (err: any) {
      const msg = err.response?.data?.error || 'Gagal menghapus pemilu'
      toast(msg, 'error')
    } finally {
      setActionLoading(false)
    }
  }

  const handleDeleteKandidat = async () => {
    if (!id || !confirmDeleteKandidat) return
    const nama = confirmDeleteKandidat.nama
    const candidateId = confirmDeleteKandidat.id
    setConfirmDeleteKandidat(null)
    setActionLoading(true)
    try {
      await api.deleteCandidate(id, candidateId)
      toast(`Kandidat "${nama}" berhasil dihapus`, 'success')
      fetchElection()
    } catch (err: any) {
      toast(getFriendlyErrorMessage(err, 'Gagal menghapus kandidat'), 'error')
    } finally {
      setActionLoading(false)
    }
  }

  const handleToggleStatistik = async () => {
    if (!id || !election) return
    const newHide = !Boolean(election.hideStatistik)
    setActionLoading(true)
    try {
      await api.updateElection(id, { hideStatistik: newHide ? 1 : 0 })
      setElection({ ...election, hideStatistik: newHide ? 1 : 0 })
      toast(`Data statistik berhasil ${newHide ? 'disembunyikan dari' : 'ditampilkan di'} portal`, 'success')
    } catch (err: any) {
      toast(getFriendlyErrorMessage(err, 'Gagal mengubah status statistik'), 'error')
    } finally {
      setActionLoading(false)
    }
  }

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Pemilu', to: '/admin/pemilu' },
          { label: 'Detail Pemilu' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">{election.judul}</h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />
      <div className="rich-content mt-4 text-sm text-gray-600 max-w-3xl" dangerouslySetInnerHTML={{ __html: election.deskripsi }} />

      <div className="mt-6 grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6 items-start">
        {/* Main */}
        <div className="space-y-6 min-w-0">
          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <StatBox icon={<Users className="h-4 w-4" />} label="Total Voter" value={election.totalVoter} />
            <StatBox icon={<Vote className="h-4 w-4" />} label="Suara Masuk" value={election.totalSuara} />
            <StatBox icon={<Award className="h-4 w-4" />} label="Kandidat" value={election.kandidat.length} />
            <StatBox icon={<Calendar className="h-4 w-4" />} label="Partisipasi" value={`${turnout}%`} />
          </div>

          {/* Kandidat */}
          <SectionCard
            title="Kandidat"
            actions={
              election.status === 'Draft' ? (
                canEdit && (
                  <Button
                    size="sm"
                    onClick={() => navigate(`/admin/pemilu/${election.id}/kandidat/new`)}
                    rightIcon={<Plus className="h-4 w-4" />}
                  >
                    Tambah Kandidat
                  </Button>
                )
              ) : undefined
            }
          >
            {election.status !== 'Draft' && election.kandidat.length > 0 && (
              <div className="mb-3 flex items-center gap-2 px-3 py-2 bg-amber-50 text-amber-700 rounded-md text-sm border border-amber-200">
                <AlertTriangle className="h-4 w-4 shrink-0" />
                <span>Kandidat hanya dapat diubah saat pemilu berstatus Draft. Pemilu ini sudah tidak dapat menerima perubahan kandidat.</span>
              </div>
            )}
            {election.kandidat.length === 0 ? (
              <div className="text-center py-12 text-gray-500">
                <p className="text-sm">Belum ada kandidat.</p>
                {election.status === 'Draft' && (
                  <p className="text-xs mt-1">Klik "Tambah Kandidat" untuk menambah.</p>
                )}
              </div>
            ) : (
              <div className="space-y-3">
                {sortedKandidat.map((k, idx) => (
                  <KandidatRow
                    key={k.id}
                    rank={idx + 1}
                    isWinner={(election.status === 'Closed' || election.status === 'Completed') && idx === 0}
                    kandidat={k}
                    totalSuara={election.totalSuara}
                    isDraft={election.status === 'Draft'}
                    canEdit={canEdit}
                    onEdit={() => navigate(`/admin/pemilu/${election.id}/kandidat/${k.id}/edit`)}
                    onDelete={() => setConfirmDeleteKandidat(k)}
                  />
                ))}
              </div>
            )}
          </SectionCard>

          {/* Results visualization for closed/active */}
          {election.kandidat.length > 0 && election.status !== 'Draft' && (
            <SectionCard
              title="Hasil Sementara"
              actions={
                <button
                  type="button"
                  onClick={fetchSummary}
                  className="p-2 rounded hover:bg-gray-100 text-gray-500"
                  disabled={summaryLoading}
                >
                  <RefreshCw className={`h-4 w-4 ${summaryLoading ? 'animate-spin' : ''}`} />
                </button>
              }
            >
              {summary ? (
                <div className="space-y-4">
                  <div className="text-sm text-gray-500 mb-2">
                    Total suara masuk: <strong>{(summary.totalSuara ?? 0).toLocaleString('id-ID')}</strong> dari{' '}
                    {(summary.totalVoter ?? 0).toLocaleString('id-ID')} pemilih terdaftar
                  </div>
                  {(summary.kandidat || []).map((k: any) => (
                    <div key={k.id}>
                      <div className="flex items-center justify-between mb-1 text-sm">
                        <span className="font-medium text-gray-900">
                          {k.nomorUrut}. {k.nama}
                        </span>
                        <span className="text-gray-700 font-semibold">
                          {(k.voteCount ?? 0).toLocaleString('id-ID')} ({k.persentase ?? 0}%)
                        </span>
                      </div>
                      <div className="h-2.5 w-full bg-gray-100 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-primary rounded-full transition-all"
                          style={{ width: `${k?.persentase ?? 0}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-gray-500">Memuat data...</p>
              )}
            </SectionCard>
          )}
        </div>

        {/* Sidebar */}
        <aside className="lg:sticky lg:top-8 space-y-6">
          <SectionCard title="Detail Pemilu">
            <dl className="space-y-3 text-sm">
              <div>
                <dt className="text-gray-500 text-xs mb-1.5">Status</dt>
                <dd>
                  <StatusBadge status={election.status} periodeEnd={election.periodeEnd} />
                </dd>
              </div>
              {election.kandidatStart && (
                <div>
                  <dt className="text-gray-500 text-xs mb-0.5">Periode Kandidat Mulai</dt>
                  <dd className="text-gray-900">{formatDate(election.kandidatStart)}</dd>
                </div>
              )}
              {election.kandidatEnd && (
                <div>
                  <dt className="text-gray-500 text-xs mb-0.5">Periode Kandidat Selesai</dt>
                  <dd className="text-gray-900">{formatDate(election.kandidatEnd)}</dd>
                </div>
              )}
              <div>
                <dt className="text-gray-500 text-xs mb-0.5">Periode Mulai</dt>
                <dd className="text-gray-900">{formatDate(election.periodeStart)}</dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs mb-0.5">Periode Selesai</dt>
                <dd className="text-gray-900">{formatDate(election.periodeEnd)}</dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs mb-0.5">Tanggal Pengumuman Hasil</dt>
                <dd className="text-gray-900">{formatDate(election.pengumumanDate)}</dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs mb-0.5">Tanggal Pelantikan Ketua Terpilih</dt>
                <dd className="text-gray-900">{formatDate(election.pelantikanDate)}</dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs mb-0.5">Dibuat pada</dt>
                <dd className="text-gray-900">{formatDate(election.createdAt)}</dd>
              </div>
              {winner && (election.status === 'Closed' || election.status === 'Completed') && (
                <div className="pt-3 border-t border-gray-100">
                  <dt className="text-gray-500 text-xs mb-1.5">Pemenang</dt>
                  <dd className="flex items-center gap-2">
                    <Award className="h-4 w-4 text-accent" />
                    <span className="font-semibold text-gray-900">{winner.nama}</span>
                  </dd>
                </div>
              )}
              <div className="pt-3 border-t border-gray-100">
                <div className="flex items-center justify-between">
                  <span className="text-xs text-gray-700 font-medium">Tampilkan Statistik & Demografi</span>
                  <button
                    type="button"
                    onClick={handleToggleStatistik}
                    disabled={actionLoading}
                    className={`relative inline-flex h-5 w-9 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                      !Boolean(election.hideStatistik) ? 'bg-primary' : 'bg-gray-200'
                    }`}
                  >
                    <span
                      className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                        !Boolean(election.hideStatistik) ? 'translate-x-4' : 'translate-x-0'
                      }`}
                    />
                  </button>
                </div>
                <p className="mt-1 text-[11px] text-gray-400">
                  Jika dinonaktifkan, section Statistik & tombol detailnya di portal akan disembunyikan.
                </p>
              </div>
            </dl>

            <div className="mt-6 pt-6 border-t border-gray-100 space-y-3">
              {election.status === 'Draft' && canEdit && (
                <Button
                  className="w-full"
                  onClick={() => setConfirmStart(true)}
                  leftIcon={<Send className="h-4 w-4" />}
                  disabled={actionLoading}
                >
                  Mulai Pemilu
                </Button>
              )}
              {(election.status === 'Active' || election.status === 'Ongoing') && canEdit && (
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={() => setConfirmClose(true)}
                >
                  Tutup Pemilu
                </Button>
              )}
              {canEdit && (
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={() => navigate(`/admin/pemilu/${election.id}/edit`)}
                  leftIcon={<Pencil className="h-4 w-4" />}
                >
                  Edit Detail
                </Button>
              )}
              {election.status === 'Draft' && canEdit && (
                <button
                  type="button"
                  onClick={() => setConfirmDelete(true)}
                  className="w-full inline-flex items-center justify-center gap-2 text-sm font-semibold text-danger hover:underline py-2"
                >
                  <Trash2 className="h-4 w-4" />
                  Hapus Pemilu
                </button>
              )}
            </div>
          </SectionCard>
        </aside>
      </div>

      <ConfirmDialog
        open={confirmStart}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-success-bg text-success">
            <Check className="h-6 w-6" />
          </div>
        }
        title="Mulai Pemilu Ini?"
        description="Pemilu akan dibuka dan dapat diakses oleh alumni untuk memilih. Setelah dimulai, daftar kandidat tidak dapat diubah."
        confirmLabel="Mulai"
        cancelLabel="Batal"
        onConfirm={handleStart}
        onCancel={() => setConfirmStart(false)}
      />

      <ConfirmDialog
        open={confirmClose}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-accent-light text-accent">
            <AlertTriangle className="h-6 w-6" />
          </div>
        }
        title="Tutup Pemilu Sekarang?"
        description="Pemilu akan ditutup dan tidak dapat menerima suara lagi. Hasil pemilu akan ditampilkan di portal."
        confirmLabel="Tutup"
        cancelLabel="Batal"
        variant="accent"
        onConfirm={handleClose}
        onCancel={() => setConfirmClose(false)}
      />

      <ConfirmDialog
        open={confirmDelete}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-danger-bg text-danger">
            <Trash2 className="h-6 w-6" />
          </div>
        }
        title="Hapus Pemilu Ini?"
        description="Pemilu dan seluruh data kandidat serta hasil voting akan dihapus permanen. Tindakan tidak dapat dibatalkan."
        confirmLabel="Hapus"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleDelete}
        onCancel={() => setConfirmDelete(false)}
      />

      <ConfirmDialog
        open={confirmDeleteKandidat !== null}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-danger-bg text-danger">
            <X className="h-6 w-6" />
          </div>
        }
        title="Hapus Kandidat Ini?"
        description="Kandidat akan dihapus dari pemilu. Suara yang sudah masuk untuk kandidat ini akan ikut terhapus."
        confirmLabel="Hapus"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleDeleteKandidat}
        onCancel={() => setConfirmDeleteKandidat(null)}
      />
    </div>
  )
}

interface StatBoxProps {
  icon: React.ReactNode
  label: string
  value: number | string
}

function StatBox({ icon, label, value }: StatBoxProps) {
  return (
    <div className="rounded-md bg-white border border-gray-200 p-4">
      <div className="flex items-center gap-2 text-gray-500 text-xs mb-1">
        {icon}
        {label}
      </div>
      <p className="text-xl font-bold text-gray-900">
        {typeof value === 'number' ? (value ?? 0).toLocaleString('id-ID') : (value ?? '-')}
      </p>
    </div>
  )
}

interface KandidatRowProps {
  rank: number
  isWinner: boolean
  isDraft: boolean
  canEdit: boolean
  kandidat: Kandidat
  totalSuara: number
  onEdit: () => void
  onDelete: () => void
}

function KandidatRow({ rank, isWinner, isDraft, canEdit, kandidat, totalSuara, onEdit, onDelete }: KandidatRowProps) {
  const pct = (totalSuara ?? 0) > 0
    ? Math.round(((kandidat?.voteCount ?? 0) / totalSuara) * 100)
    : 0

  return (
    <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-md border border-gray-100">
      <div className="relative">
        <img
          src={getAvatarUrl(kandidat?.fotoUrl, kandidat?.nama || '')}
          alt={kandidat?.nama || ''}
          className="h-12 w-12 rounded-full object-cover bg-gray-200"
        />
        {isWinner && (
          <Award className="absolute -top-1 -right-1 h-4 w-4 text-accent bg-white rounded-full" />
        )}
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <Badge variant="orange">No. {kandidat?.nomorUrut || '-'}</Badge>
          <p className="font-semibold text-gray-900 truncate">{kandidat?.nama || '-'}</p>
        </div>
        <p className="text-xs text-gray-500 mt-0.5">
          Angkatan {kandidat?.angkatan || '-'} · {(kandidat?.voteCount ?? 0).toLocaleString('id-ID')} suara ({pct}%)
        </p>
      </div>
      <div className="flex items-center gap-2">
        <span className="text-xs text-gray-400">#{rank}</span>
        {isDraft && canEdit && (
          <>
            <button
              type="button"
              onClick={onEdit}
              className="p-2 rounded hover:bg-white text-gray-500 hover:text-primary"
              aria-label="Edit"
            >
              <Pencil className="h-4 w-4" />
            </button>
            <button
              type="button"
              onClick={onDelete}
              className="p-2 rounded hover:bg-white text-gray-500 hover:text-danger"
              aria-label="Delete"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </>
        )}
      </div>
    </div>
  )
}
