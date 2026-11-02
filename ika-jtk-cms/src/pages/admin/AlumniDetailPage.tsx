import { useNavigate, useParams, Navigate } from 'react-router-dom'
import { useState, useEffect } from 'react'
import { formatFileName } from '../../utils/file'
import {
  Pencil, Trash2, UserX, UserCheck, Check, X, AlertTriangle,
  Mail, Phone, Link2, MapPin, FileText, ImageIcon
} from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { useAuthStore } from '@/stores/authStore'
import { formatDate, getAvatarUrl, getFileUrl } from '@/lib/utils'
import { countryCodes } from '@/utils/country_codes'
import type { Alumni, Pekerjaan, Prestasi } from '@/types/alumni'
import { AlumniStatus } from '@/types/alumni'

function StatusBadge({ status }: { status: AlumniStatus }) {
  if (status === AlumniStatus.ACTIVE || status === AlumniStatus.APPROVED) return <Badge variant="green">{status}</Badge>
  if (status === AlumniStatus.INACTIVE) return <Badge variant="gray">{status}</Badge>
  if (status === AlumniStatus.REJECTED) return <Badge variant="red">{status}</Badge>
  return <Badge variant="orange">{status}</Badge>
}

function periodLabel(p: Pekerjaan) {
  const start = [p.bulanMulai, p.tahunMulai].filter(Boolean).join(' ')
  const end = p.masihBekerja
    ? 'Present'
    : [p.bulanSelesai, p.tahunSelesai].filter(Boolean).join(' ')
  if (!start && !end) return ''
  return `${start || '?'} - ${end || '?'}`
}

export function AlumniDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const user = useAuthStore((s) => s.user)
  const canEdit = user?.permissions?.includes('alumni_edit') ?? false
  const [alumni, setAlumni] = useState<Alumni | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const [confirmDelete, setConfirmDelete] = useState(false)
  const [confirmNonactivate, setConfirmNonactivate] = useState(false)
  const [confirmActivate, setConfirmActivate] = useState(false)
  const [confirmAccept, setConfirmAccept] = useState(false)
  const [confirmReject, setConfirmReject] = useState(false)
  const [rejectReason, setRejectReason] = useState('')
  const [isRejecting, setIsRejecting] = useState(false)

  const fetchAlumni = async () => {
    try {
      setIsLoading(true)
      const res = await api.get(`/admin/alumni/${id}`)
      setAlumni(res.data)
    } catch (error) {
      toast('Gagal memuat alumni', 'error')
      navigate('/admin/alumni')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchAlumni()
  }, [id])

  if (isLoading) return <div className="p-10">Loading...</div>

  if (!alumni) return <Navigate to="/admin/alumni" replace />

  const handleDelete = async () => {
    setConfirmDelete(false)
    try {
      await api.delete(`/admin/alumni/${id}`)
      toast(`Alumni "${alumni.nama}" berhasil dihapus`, 'success')
      navigate('/admin/alumni')
    } catch (error) {
      toast('Gagal menghapus alumni', 'error')
    }
  }
  const handleNonactivate = async () => {
    setConfirmNonactivate(false)
    try {
      await api.put(`/admin/alumni/${id}`, { status: AlumniStatus.INACTIVE })
      toast('Status alumni diperbarui ke Inactive', 'info')
      fetchAlumni()
    } catch (error) {
      toast('Gagal nonaktifkan alumni', 'error')
    }
  }
  const handleActivate = async () => {
    setConfirmActivate(false)
    try {
      await api.put(`/admin/alumni/${id}`, { status: AlumniStatus.ACTIVE })
      toast('Status alumni diperbarui ke Active', 'success')
      fetchAlumni()
    } catch (error) {
      toast('Gagal aktifkan alumni', 'error')
    }
  }
  const handleAccept = async () => {
    setConfirmAccept(false)
    try {
      await api.post(`/admin/alumni/${id}/approve`)
      toast(`Pendaftaran "${alumni.nama}" diterima`, 'success')
      fetchAlumni()
    } catch (error) {
      toast('Gagal terima pendaftaran', 'error')
    }
  }
  const handleReject = async () => {
    if (!rejectReason.trim()) {
      toast('Alasan penolakan wajib diisi', 'error')
      return
    }
    setIsRejecting(true)
    try {
      await api.post(`/admin/alumni/${id}/reject`, { reason: rejectReason })
      toast(`Pendaftaran "${alumni.nama}" ditolak`, 'info')
      setConfirmReject(false)
      setRejectReason('')
      fetchAlumni()
    } catch (error) {
      toast('Gagal menolak pendaftaran', 'error')
    } finally {
      setIsRejecting(false)
    }
  }

  const isPending = alumni.status === AlumniStatus.PENDING
  const isActive = alumni.status === AlumniStatus.ACTIVE
  const isInactive = alumni.status === AlumniStatus.INACTIVE
  const isRejected = alumni.status === AlumniStatus.REJECTED

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Alumni', to: '/admin/alumni' },
          { label: 'Profile Alumni' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">Profile Alumni</h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6 items-start">
        <div className="space-y-6 min-w-0">
          <div className="bg-white rounded-lg border border-gray-200 shadow-sm p-6 flex flex-col sm:flex-row items-center gap-6">
            <img
              src={getAvatarUrl(alumni.avatarUrl, alumni.nama)}
              alt={alumni.nama}
              className="h-28 w-28 rounded-md object-cover bg-gray-200 shrink-0"
            />
            <div className="min-w-0 flex-1">
              <h2 className="text-2xl font-bold text-gray-900 leading-tight">
                {alumni.nama}
              </h2>
              {alumni.motto ? (
                <p className="mt-1 text-sm italic text-gray-500">
                  "{alumni.motto}"
                </p>
              ) : (
                <p className="mt-1 text-sm italic text-gray-400">
                  Alumni belum menambahkan motto.
                </p>
              )}
            </div>
          </div>

          <SectionCard title="Data Alumni">
            <dl className="space-y-4 text-sm">
              <DataRow label="No. Alumni" value={alumni.noAlumni} />
              <DataRow label="Angkatan" value={alumni.angkatan} />
              <DataRow label="Keanggotaan" value={<Badge variant="gray">{alumni.keanggotaan}</Badge>} />
              {alumni.tanggalLahir && (
                <DataRow label="Tanggal Lahir" value={formatDate(alumni.tanggalLahir)} />
              )}
              {alumni.jenisKelamin && (
                <DataRow label="Jenis Kelamin" value={alumni.jenisKelamin} />
              )}
              {alumni.username && (
                <DataRow label="Username" value={alumni.username} />
              )}
            </dl>
          </SectionCard>

          <SectionCard title="Kontak">
            <dl className="space-y-4 text-sm">
              <KontakRow
                icon={<Mail className="h-4 w-4" />}
                label="Email"
                value={
                  <div className="flex items-center gap-2">
                    <span>{alumni.email}</span>
                    {alumni.emailVerified ? (
                      <Badge variant="green">Verified</Badge>
                    ) : (
                      <Badge variant="gray">Unverified</Badge>
                    )}
                  </div>
                }
              />
              <KontakRow
                icon={<Phone className="h-4 w-4" />}
                label="Nomor Handphone"
                value={
                  <div className="flex items-center gap-2">
                    <span>
                      {(() => {
                        if (!alumni.nomorHandphone) return '-'
                        let hpRaw = alumni.nomorHandphone.trim()
                        if (hpRaw.startsWith('+')) hpRaw = hpRaw.substring(1).trim()
                        
                        const sortedCodes = [...countryCodes].sort((a, b) => b.code.length - a.code.length)
                        const matched = sortedCodes.find(c => hpRaw.startsWith(c.code))
                        
                        if (matched) {
                          const numPart = hpRaw.substring(matched.code.length)
                          return `+${matched.code} ${numPart}`
                        }
                        
                        if (hpRaw.startsWith('62')) hpRaw = hpRaw.substring(2).trim()
                        else if (hpRaw.startsWith('0')) hpRaw = hpRaw.substring(1).trim()
                        return `+62 ${hpRaw}`
                      })()}
                    </span>
                    {alumni.phoneVerified ? (
                      <Badge variant="green">Verified</Badge>
                    ) : (
                      <Badge variant="gray">Unverified</Badge>
                    )}
                  </div>
                }
              />
              <KontakRow
                icon={<Link2 className="h-4 w-4" />}
                label="LinkedIn"
                value={
                  alumni.linkedin ? (
                    <a
                      href={alumni.linkedin.startsWith('http') ? alumni.linkedin : `https://${alumni.linkedin}`}
                      target="_blank"
                      rel="noreferrer"
                      className="text-primary hover:underline break-all"
                    >
                      {alumni.linkedin}
                    </a>
                  ) : (
                    '-'
                  )
                }
              />
              <KontakRow icon={<MapPin className="h-4 w-4" />} label="Alamat" value={alumni.alamat || '-'} />
            </dl>
          </SectionCard>

          <SectionCard title="Ijazah / PDDIKTI / Surat Keterangan Jurusan">
            <dl className="space-y-4 text-sm">
              {alumni.nomorIjazah && (
                <DataRow label="Nomor" value={alumni.nomorIjazah} />
              )}
              {alumni.tahunLulus && (
                <DataRow label="Tahun Lulus" value={alumni.tahunLulus} />
              )}
              {alumni.ipk && (
                <DataRow label="IPK" value={alumni.ipk} />
              )}
              {alumni.ijazahFile && (
                <DataRow
                  label="File"
                  value={
                    <a href={getFileUrl(alumni.ijazahFile)} target="_blank" rel="noreferrer" className="text-primary hover:underline flex items-center gap-2">
                      <FileText className="h-4 w-4 flex-shrink-0" /> 
                      <span className="truncate">{formatFileName(alumni.ijazahFile)}</span>
                    </a>
                  }
                />
              )}
              {(!alumni.nomorIjazah && !alumni.tahunLulus && !alumni.ipk && !alumni.ijazahFile) && (
                <p className="text-gray-500 italic">Belum ada data Ijazah / PDDIKTI / Surat Keterangan Jurusan.</p>
              )}
            </dl>
          </SectionCard>
          <SectionCard title="Pekerjaan">
            {alumni.pekerjaan.length === 0 ? (
              <p className="text-sm italic text-gray-400">
                Belum ada data pekerjaan.
              </p>
            ) : (
              <ul className="space-y-5">
                {alumni.pekerjaan.map((p) => (
                  <PekerjaanRow key={p.id} pekerjaan={p} />
                ))}
              </ul>
            )}
          </SectionCard>

          <SectionCard title="Prestasi">
            {alumni.prestasi.length === 0 ? (
              <p className="text-sm italic text-gray-400">
                Belum ada data prestasi.
              </p>
            ) : (
              <ul className="space-y-5">
                {alumni.prestasi.map((p) => (
                  <PrestasiRow key={p.id} prestasi={p} />
                ))}
              </ul>
            )}
          </SectionCard>

          <SectionCard title="Alumni Grafis">
            {(() => {
              let grafis = null;
              try {
                grafis = typeof alumni.alumniGrafis === 'string' ? JSON.parse(alumni.alumniGrafis) : alumni.alumniGrafis;
              } catch (e) { }
              if (!grafis || !grafis.kategori || grafis.kategori === 'None') {
                return (
                  <p className="text-sm italic text-gray-400">
                    Belum ada pengajuan atau data Alumni Grafis.
                  </p>
                );
              }
              const targetJob = alumni.pekerjaan?.find(p => p.id === grafis.id);
              const targetPrestasi = alumni.prestasi?.find(p => p.id === grafis.id);
              const label = targetJob
                ? `${targetJob.pekerjaan} - ${targetJob.perusahaan}`
                : targetPrestasi
                ? `${targetPrestasi.judul} (${targetPrestasi.tahun})`
                : grafis.id;
              return (
                <div className="space-y-3 text-sm">
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-gray-500">Kategori</span>
                    <span className="font-semibold text-gray-900">{grafis.kategori}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-gray-500">Pekerjaan/Prestasi Terpilih</span>
                    <span className="font-semibold text-gray-900 text-right">{label}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-gray-500">Status Grafis</span>
                    <Badge variant={grafis.status === 'APPROVED' ? 'green' : grafis.status === 'PENDING' ? 'orange' : 'gray'}>
                      {grafis.status || 'APPROVED'}
                    </Badge>
                  </div>
                </div>
              );
            })()}
          </SectionCard>
        </div>

        <aside className="lg:sticky lg:top-8 space-y-6">
          <SectionCard title="Detail Alumni">
            <dl className="space-y-3 text-sm">
              <DetailRow label="Dibuat pada" value={formatDate(alumni.createdAt)} />
              <DetailRow
                label="Diterima pada"
                value={
                  alumni.diterimaPada ? (
                    formatDate(alumni.diterimaPada)
                  ) : (
                    <span className="text-gray-400 italic">Belum diterima</span>
                  )
                }
              />
              <div>
                <dt className="text-gray-500 text-xs mb-1.5">Status</dt>
                <dd>
                  <StatusBadge status={alumni.status} />
                </dd>
              </div>
            </dl>

            <div className="mt-6 pt-6 border-t border-gray-100 space-y-3">
              {isPending && canEdit && (
                <>
                  <Button
                    className="w-full"
                    onClick={() => setConfirmAccept(true)}
                    leftIcon={<Check className="h-4 w-4" />}
                  >
                    Terima Pendaftaran
                  </Button>
                  <Button
                    variant="danger"
                    className="w-full"
                    onClick={() => setConfirmReject(true)}
                    leftIcon={<X className="h-4 w-4" />}
                  >
                    Tolak Pendaftaran
                  </Button>
                </>
              )}
              {isActive && canEdit && (
                <>
                  <Button
                    variant="outline"
                    className="w-full"
                    onClick={() => navigate(`/admin/alumni/${alumni.id}/edit`)}
                    leftIcon={<Pencil className="h-4 w-4" />}
                  >
                    Edit Alumni
                  </Button>
                  <Button
                    variant="outline"
                    className="w-full"
                    onClick={() => setConfirmNonactivate(true)}
                    leftIcon={<UserX className="h-4 w-4" />}
                  >
                    Nonaktifkan Alumni
                  </Button>
                </>
              )}
              {isInactive && canEdit && (
                <Button
                  className="w-full"
                  onClick={() => setConfirmActivate(true)}
                  leftIcon={<UserCheck className="h-4 w-4" />}
                >
                  Aktifkan Alumni
                </Button>
              )}
              {isRejected && canEdit && (
                <button
                  type="button"
                  onClick={() => setConfirmDelete(true)}
                  className="w-full inline-flex items-center justify-center gap-2 text-sm font-semibold text-danger hover:underline py-2"
                >
                  <Trash2 className="h-4 w-4" />
                  Hapus Alumni
                </button>
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
        title="Hapus Alumni Ini?"
        description="Tindakan ini akan menghapus data alumni secara permanen dari sistem dan tidak dapat dibatalkan. Apakah Anda yakin ingin melanjutkan?"
        confirmLabel="Hapus"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleDelete}
        onCancel={() => setConfirmDelete(false)}
      />

      <ConfirmDialog
        open={confirmNonactivate}
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
        onCancel={() => setConfirmNonactivate(false)}
      />

      <ConfirmDialog
        open={confirmActivate}
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
        onCancel={() => setConfirmActivate(false)}
      />

      <ConfirmDialog
        open={confirmAccept}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-success-bg text-success">
            <Check className="h-6 w-6" />
          </div>
        }
        title="Terima Pendaftaran Alumni?"
        description="Alumni ini akan diaktifkan dan dapat mengakses sistem. Pastikan data sudah sesuai dengan database IKA JTK."
        confirmLabel="Terima"
        cancelLabel="Batal"
        onConfirm={handleAccept}
        onCancel={() => setConfirmAccept(false)}
      />

      <ConfirmDialog
        open={confirmReject}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-danger-bg text-danger">
            <X className="h-6 w-6" />
          </div>
        }
        title="Tolak Pendaftaran Alumni?"
        description={
          <div className="mt-2 text-left">
            <p className="text-sm text-gray-500 mb-4">
              Pendaftaran alumni akan ditolak dan statusnya diubah menjadi ditolak.
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
          setConfirmReject(false)
          setRejectReason('')
        }}
        loading={isRejecting}
      />
    </div>
  )
}

function DataRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="grid grid-cols-[140px_1fr] sm:grid-cols-[200px_1fr] gap-4">
      <dt className="font-bold text-gray-900 text-sm">{label}</dt>
      <dd className="text-gray-500 text-sm">{value}</dd>
    </div>
  )
}

function KontakRow({
  icon, label, value,
}: {
  icon: React.ReactNode
  label: string
  value: React.ReactNode
}) {
  return (
    <div className="grid grid-cols-[140px_1fr] sm:grid-cols-[200px_1fr] gap-4">
      <dt className="inline-flex items-center gap-2 font-bold text-gray-900 text-sm">
        <span className="text-gray-400 font-normal">{icon}</span>
        {label}
      </dt>
      <dd className="text-gray-500 text-sm">{value}</dd>
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

function PekerjaanRow({ pekerjaan }: { pekerjaan: Pekerjaan }) {
  return (
    <li className="flex items-start justify-between gap-4">
      <div className="min-w-0">
        <p className="font-semibold text-gray-900">{pekerjaan.pekerjaan}</p>
        <p className="text-sm text-gray-500">{pekerjaan.perusahaan}</p>
      </div>
      <span className="text-xs text-gray-500 whitespace-nowrap pt-1">
        {periodLabel(pekerjaan)}
      </span>
    </li>
  )
}

function PrestasiRow({ prestasi }: { prestasi: Prestasi }) {
  return (
    <li className="flex flex-col gap-1">
      <div className="flex items-start justify-between gap-4">
        <p className="font-bold text-gray-900">{prestasi.judul}</p>
        <span className="text-xs text-gray-500 whitespace-nowrap pt-0.5">
          {prestasi.tahun}
        </span>
      </div>
      {prestasi.buktiUrl && (
        <div className="flex items-center gap-2 text-sm mt-1">
          {typeof prestasi.buktiUrl === 'string' && prestasi.buktiUrl.match(/\.pdf$/i) ? (
            <FileText className="h-4 w-4 text-primary" />
          ) : (
            <ImageIcon className="h-4 w-4 text-primary" />
          )}
          <a href={getFileUrl(prestasi.buktiUrl)} target="_blank" rel="noreferrer" className="text-primary hover:underline truncate">
            {formatFileName(prestasi.buktiUrl)}
          </a>
        </div>
      )}
    </li>
  )
}
