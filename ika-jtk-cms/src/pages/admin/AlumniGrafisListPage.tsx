import { useEffect, useState } from 'react'
import { Check, X, ShieldAlert, Archive, ArchiveRestore } from 'lucide-react'
import api from '@/lib/api'
import type { AlumniGrafisRequest } from '@/types/alumni'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { useAuthStore } from '@/stores/authStore'
import { Navigate, useNavigate } from 'react-router-dom'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { toast } from '@/components/ui/Toast'

export function AlumniGrafisListPage() {
  const user = useAuthStore((state) => state.user)
  const hasAccess = user?.permissions?.includes('alumnigrafis_view') ?? false
  const canEdit = user?.permissions?.includes('alumnigrafis_edit') ?? false
  const navigate = useNavigate()

  const [activeTab, setActiveTab] = useState<'PENDING' | 'APPROVED' | 'REJECTED' | 'ALL'>('ALL')
  const [requests, setRequests] = useState<AlumniGrafisRequest[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [hasPending, setHasPending] = useState(false)

  // Accept dialog
  const [acceptTarget, setAcceptTarget] = useState<AlumniGrafisRequest | null>(null)
  const [isAccepting, setIsAccepting] = useState(false)

  // Reject dialog
  const [rejectTarget, setRejectTarget] = useState<AlumniGrafisRequest | null>(null)
  const [isRejecting, setIsRejecting] = useState(false)

  // Archive dialog
  const [archiveTarget, setArchiveTarget] = useState<AlumniGrafisRequest | null>(null)
  const [isArchiving, setIsArchiving] = useState(false)

  // Unarchive dialog
  const [unarchiveTarget, setUnarchiveTarget] = useState<AlumniGrafisRequest | null>(null)
  const [isUnarchiving, setIsUnarchiving] = useState(false)

  const fetchRequests = async () => {
    setIsLoading(true)
    try {
      const res = await api.get(`/admin/alumni-grafis?status=${activeTab}`)
      setRequests(res.data)
      
      const pendingRes = await api.get('/admin/alumni-grafis?status=PENDING')
      setHasPending(pendingRes.data.length > 0)
    } catch (error) {
      toast('Gagal memuat data pengajuan', 'error')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    if (hasAccess) {
      fetchRequests()
    }
  }, [activeTab, hasAccess])

  if (!hasAccess) {
    return <Navigate to="/admin/dashboard" replace />
  }

  const handleAccept = async () => {
    if (!acceptTarget) return
    setIsAccepting(true)
    try {
      await api.post(`/admin/alumni-grafis/${acceptTarget.id}/verify`, { status: 'APPROVED' })
      toast(`Pengajuan alumni grafis "${acceptTarget.alumni.nama}" disetujui`, 'success')
      setAcceptTarget(null)
      setActiveTab('ALL')
    } catch (error) {
      toast('Gagal menyetujui pengajuan', 'error')
    } finally {
      setIsAccepting(false)
    }
  }

  const handleReject = async () => {
    if (!rejectTarget) return
    setIsRejecting(true)
    try {
      await api.post(`/admin/alumni-grafis/${rejectTarget.id}/verify`, { status: 'REJECTED' })
      toast(`Pengajuan alumni grafis "${rejectTarget.alumni.nama}" ditolak`, 'info')
      setRejectTarget(null)
      fetchRequests()
    } catch (error) {
      toast('Gagal menolak pengajuan', 'error')
    } finally {
      setIsRejecting(false)
    }
  }

  const handleArchive = async () => {
    if (!archiveTarget) return
    setIsArchiving(true)
    try {
      await api.post(`/admin/alumni-grafis/${archiveTarget.id}/verify`, { status: 'ARCHIVED' })
      toast(`Alumni grafis "${archiveTarget.alumni.nama}" berhasil diarsipkan`, 'info')
      setArchiveTarget(null)
      fetchRequests()
    } catch (error) {
      toast('Gagal mengarsipkan pengajuan', 'error')
    } finally {
      setIsArchiving(false)
    }
  }

  const handleUnarchive = async () => {
    if (!unarchiveTarget) return
    setIsUnarchiving(true)
    try {
      await api.post(`/admin/alumni-grafis/${unarchiveTarget.id}/verify`, { status: 'APPROVED' })
      toast(`Alumni grafis "${unarchiveTarget.alumni.nama}" berhasil diaktifkan kembali`, 'success')
      setUnarchiveTarget(null)
      fetchRequests()
    } catch (error) {
      toast('Gagal mengaktifkan pengajuan', 'error')
    } finally {
      setIsUnarchiving(false)
    }
  }

  return (
    <div className="px-10 py-8">
      <Breadcrumb items={[{ label: 'Alumni Grafis' }]} />
      <div className="flex justify-between items-center mt-2">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Alumni Grafis</h1>
          <p className="text-gray-500 mt-1">Verifikasi pengajuan alumni grafis dari portal.</p>
        </div>
      </div>
      <span className="block mt-4 h-0.5 w-10 bg-accent rounded-full" />

      {/* Tabs */}
      <div className="mt-8 border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          {[
            { key: 'ALL', label: 'Alumni Grafis Terverifikasi' },
            { key: 'PENDING', label: 'Menunggu Verifikasi' },
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key as any)}
              className={`${
                activeTab === tab.key
                  ? 'border-accent text-accent'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              } relative whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-colors flex items-center gap-2`}
            >
              {tab.label}
              {tab.key === 'PENDING' && hasPending && (
                <span className="absolute top-3 right-0 -mr-3 flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-red-500"></span>
                </span>
              )}
            </button>
          ))}
        </nav>
      </div>

      <div className="mt-6 bg-white shadow-sm border border-gray-200 rounded-xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-600">
            <thead className="bg-gray-50/80 text-gray-700 border-b border-gray-200 uppercase text-xs">
              <tr>
                <th className="px-6 py-4 font-semibold">Alumni</th>
                <th className="px-6 py-4 font-semibold">Kategori</th>
                <th className="px-6 py-4 font-semibold">Detail Grafis</th>
                <th className="px-6 py-4 font-semibold">Waktu Pengajuan</th>
                {activeTab === 'PENDING' ? (
                  <th className="px-6 py-4 font-semibold text-right">Aksi</th>
                ) : (
                  <th className="px-6 py-4 font-semibold">Status</th>
                )}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {isLoading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                    Memuat data...
                  </td>
                </tr>
              ) : requests.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center">
                    <div className="flex flex-col items-center justify-center text-gray-400">
                      <ShieldAlert className="h-12 w-12 mb-3 text-gray-300" />
                      <p className="text-base font-medium text-gray-900">Tidak Ada Data</p>
                      <p className="text-sm mt-1">Belum ada pengajuan alumni grafis di tab ini.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                requests.map((req) => (
                  <tr key={req.id} className="hover:bg-gray-50/50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="h-10 w-10 shrink-0 rounded-full bg-primary/10 flex items-center justify-center font-bold text-primary overflow-hidden">
                          {req.alumni.avatarUrl ? (
                            <img src={req.alumni.avatarUrl} alt={req.alumni.nama} className="h-full w-full object-cover" />
                          ) : (
                            req.alumni.nama.charAt(0)
                          )}
                        </div>
                        <div>
                          <button
                            type="button"
                            onClick={() => navigate(`/admin/alumni/${req.alumni.id}`)}
                            className="font-semibold text-gray-900 hover:underline text-left"
                          >
                            {req.alumni.nama}
                          </button>
                          <div className="text-xs text-gray-500">Angkatan {req.alumni.angkatan}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10">
                        {req.kategori}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {req.detail ? (
                        req.kategori.toLowerCase().includes('prestasi') ? (
                          <div>
                            <p className="font-medium text-gray-900">{req.detail.judul}</p>
                            <p className="text-xs text-gray-500">{req.detail.tahun}</p>
                          </div>
                        ) : (
                          <div>
                            <p className="font-medium text-gray-900">{req.detail.pekerjaan}</p>
                            <p className="text-xs text-gray-500">{req.detail.perusahaan}</p>
                          </div>
                        )
                      ) : (
                        <span className="text-gray-400 italic">Detail tidak ditemukan</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      {new Date(req.createdAt).toLocaleDateString('id-ID', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </td>
                    {activeTab === 'PENDING' ? (
                      <td className="px-6 py-4 text-right">
                        {canEdit && (
                          <div className="flex justify-end gap-2">
                            <button
                              onClick={() => setAcceptTarget(req)}
                              className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-green-700 bg-green-50 rounded-md hover:bg-green-100 transition-colors"
                              title="Setujui Pengajuan"
                            >
                              <Check className="h-4 w-4" />
                              <span className="hidden sm:inline">Setujui</span>
                            </button>
                            <button
                              onClick={() => setRejectTarget(req)}
                              className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-red-700 bg-red-50 rounded-md hover:bg-red-100 transition-colors"
                              title="Tolak Pengajuan"
                            >
                              <X className="h-4 w-4" />
                              <span className="hidden sm:inline">Tolak</span>
                            </button>
                          </div>
                        )}
                      </td>
                    ) : (
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          {req.status === 'APPROVED' ? (
                            <>
                              <span className="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
                                Disetujui
                              </span>
                              {canEdit && (
                                <button
                                  onClick={() => setArchiveTarget(req)}
                                  className="text-gray-400 hover:text-gray-700 transition-colors"
                                  title="Arsipkan"
                                >
                                  <Archive className="h-4 w-4" />
                                </button>
                              )}
                            </>
                          ) : req.status === 'ARCHIVED' ? (
                            <>
                              <span className="inline-flex items-center rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700 ring-1 ring-inset ring-gray-600/20">
                                Diarsipkan
                              </span>
                              {canEdit && (
                                <button
                                  onClick={() => setUnarchiveTarget(req)}
                                  className="text-gray-400 hover:text-green-600 transition-colors"
                                  title="Aktifkan Kembali"
                                >
                                  <ArchiveRestore className="h-4 w-4" />
                                </button>
                              )}
                            </>
                          ) : req.status === 'REJECTED' ? (
                            <span className="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10">
                              Ditolak
                            </span>
                          ) : (
                            <span className="inline-flex items-center rounded-md bg-yellow-50 px-2 py-1 text-xs font-medium text-yellow-800 ring-1 ring-inset ring-yellow-600/20">
                              Menunggu
                            </span>
                          )}
                        </div>
                      </td>
                    )}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Accept Dialog */}
      <ConfirmDialog
        open={acceptTarget !== null}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-success-bg text-success">
            <Check className="h-6 w-6" />
          </div>
        }
        title="Setujui Pengajuan Alumni Grafis?"
        description={`Pengajuan dari "${acceptTarget?.alumni.nama}" untuk kategori "${acceptTarget?.kategori}" akan disetujui dan langsung ditampilkan di halaman alumni grafis portal.`}
        confirmLabel="Ya, Setujui"
        cancelLabel="Batal"
        onConfirm={handleAccept}
        onCancel={() => setAcceptTarget(null)}
        loading={isAccepting}
      />

      {/* Reject Dialog */}
      <ConfirmDialog
        open={rejectTarget !== null}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-danger-bg text-danger">
            <X className="h-6 w-6" />
          </div>
        }
        title="Tolak Pengajuan Alumni Grafis?"
        description={`Pengajuan dari "${rejectTarget?.alumni.nama}" akan ditolak. Tindakan ini tidak dapat dibatalkan.`}
        confirmLabel="Tolak"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleReject}
        onCancel={() => setRejectTarget(null)}
        loading={isRejecting}
      />

      {/* Archive Dialog */}
      <ConfirmDialog
        open={archiveTarget !== null}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 text-gray-600">
            <Archive className="h-6 w-6" />
          </div>
        }
        title="Arsipkan Alumni Grafis?"
        description={`Apakah Anda yakin ingin mengarsipkan alumni grafis "${archiveTarget?.alumni.nama}"? Grafis yang diarsipkan tidak akan tampil di portal publik.`}
        confirmLabel="Ya, Arsipkan"
        cancelLabel="Batal"
        onConfirm={handleArchive}
        onCancel={() => setArchiveTarget(null)}
        loading={isArchiving}
      />

      {/* Unarchive Dialog */}
      <ConfirmDialog
        open={unarchiveTarget !== null}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-success-bg text-success">
            <ArchiveRestore className="h-6 w-6" />
          </div>
        }
        title="Aktifkan Alumni Grafis?"
        description={`Apakah Anda yakin ingin mengaktifkan kembali alumni grafis "${unarchiveTarget?.alumni.nama}"? Grafis ini akan kembali tampil di portal publik.`}
        confirmLabel="Ya, Aktifkan"
        cancelLabel="Batal"
        onConfirm={handleUnarchive}
        onCancel={() => setUnarchiveTarget(null)}
        loading={isUnarchiving}
      />
    </div>
  )
}
