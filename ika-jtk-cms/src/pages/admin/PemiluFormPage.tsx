import { Navigate, useNavigate, useParams } from 'react-router-dom'
import { useEffect, useMemo, useRef, useState } from 'react'
import { Save, Upload, Plus, Trash2, ChevronDown, Search, X } from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Input, Label } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { RichTextEditor } from '@/components/ui/RichTextEditor'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { ImageCropModal } from '@/components/ui/ImageCropModal'
import { toast } from '@/components/ui/Toast'
import type { Alumni } from '@/types/alumni'
import type { Election, ElectionStatus, ProgramKerjaItem, PrestasiItem } from '@/types/election'
import { cn, getAvatarUrl, getThumbnailUrl } from '@/lib/utils'
import api from '@/lib/api'
import { useImageCropUpload } from '@/lib/useImageCropUpload'

function StatusBadge({ status }: { status: ElectionStatus }) {
  if (status === 'Ongoing') return <Badge variant="green">Sedang Berlangsung</Badge>
  if (status === 'Active') return <Badge variant="green">Aktif</Badge>
  if (status === 'Draft') return <Badge variant="orange">Draft</Badge>
  if (status === 'Completed') return <Badge variant="blue">Selesai</Badge>
  if (status === 'Closed') return <Badge variant="gray">Ditutup</Badge>
  return <Badge variant="gray">{status}</Badge>
}

export function PemiluFormPage() {
  const navigate = useNavigate()
  const { id } = useParams()
  const isEdit = Boolean(id)

  const [existing, setExisting] = useState<any>(null)
  const [loading, setLoading] = useState(isEdit)

  const [judul, setJudul] = useState('')
  const [deskripsi, setDeskripsi] = useState('')
  const [periodeStart, setPeriodeStart] = useState('')
  const [periodeEnd, setPeriodeEnd] = useState('')
  const [pengumumanDate, setPengumumanDate] = useState('')
  const [pelantikanDate, setPelantikanDate] = useState('')
  const [confirmSave, setConfirmSave] = useState(false)
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    if (isEdit && id) {
      api.getElectionById(id)
        .then((data) => {
          setExisting(data)
          setJudul(data.judul)
          setDeskripsi(data.deskripsi)
          setPeriodeStart(data.periodeStart ? data.periodeStart.replace(' ', 'T').slice(0, 16) : '')
          setPeriodeEnd(data.periodeEnd ? data.periodeEnd.replace(' ', 'T').slice(0, 16) : '')
          setPengumumanDate(data.pengumumanDate ? data.pengumumanDate.slice(0, 10) : '')
          setPelantikanDate(data.pelantikanDate ? data.pelantikanDate.slice(0, 10) : '')
        })
        .catch(() => {
          toast('Gagal mengambil detail pemilu', 'error')
          navigate('/admin/pemilu')
        })
        .finally(() => setLoading(false))
    }
  }, [id, isEdit, navigate])

  const isBackdate = Boolean(
    !isEdit &&
    periodeStart &&
    new Date(periodeStart).getTime() < Date.now()
  )

  const isEndInvalid = Boolean(
    periodeStart &&
      periodeEnd &&
      new Date(periodeEnd).getTime() <= new Date(periodeStart).getTime()
  )

  const isPengumumanInvalid = Boolean(
    periodeEnd &&
      pengumumanDate &&
      new Date(`${pengumumanDate}T23:59:59`).getTime() < new Date(periodeEnd).getTime()
  )

  const isPelantikanInvalid = Boolean(
    (pengumumanDate &&
      pelantikanDate &&
      new Date(`${pelantikanDate}T23:59:59`).getTime() < new Date(`${pengumumanDate}T00:00:00`).getTime()) ||
      (!pengumumanDate &&
        periodeEnd &&
        pelantikanDate &&
        new Date(`${pelantikanDate}T23:59:59`).getTime() < new Date(periodeEnd).getTime()) ||
      (!pengumumanDate &&
        !periodeEnd &&
        periodeStart &&
        pelantikanDate &&
        new Date(`${pelantikanDate}T23:59:59`).getTime() < new Date(periodeStart).getTime())
  )

  const isJadwalLocked = Boolean(
      existing &&
      existing.status !== 'Draft' &&
      existing.periodeStart &&
      new Date(existing.periodeStart).getTime() <= Date.now()
  )

  const formInvalid =
    judul.trim().length === 0 ||
    deskripsi.trim().length === 0 ||
    periodeStart.length === 0 ||
    periodeEnd.length === 0 ||
    isEndInvalid ||
    isPengumumanInvalid ||
    isPelantikanInvalid ||
    submitting

  const submit = async () => {
    if (isEndInvalid) {
      toast('Periode selesai harus setelah periode mulai', 'error')
      setConfirmSave(false)
      return
    }
    if (isPengumumanInvalid) {
      toast('Tanggal Pengumuman Hasil tidak boleh sebelum (backdate) dari Periode Selesai Waktu Pemilihan', 'error')
      setConfirmSave(false)
      return
    }
    if (isPelantikanInvalid) {
      toast('Tanggal Pelantikan Ketua Terpilih tidak boleh sebelum (backdate) dari Tanggal Pengumuman / Periode Pemilihan', 'error')
      setConfirmSave(false)
      return
    }
    setConfirmSave(false)
    setSubmitting(true)
    try {
      const payload = {
        judul,
        deskripsi,
        periodeStart: periodeStart.length === 16 ? `${periodeStart.replace('T', ' ')}:00` : periodeStart.replace('T', ' '),
        periodeEnd: periodeEnd.length === 16 ? `${periodeEnd.replace('T', ' ')}:00` : periodeEnd.replace('T', ' '),
        pengumumanDate: pengumumanDate ? `${pengumumanDate} 00:00:00` : null,
        pelantikanDate: pelantikanDate ? `${pelantikanDate} 00:00:00` : null,
        kandidatStart: null,
        kandidatEnd: null,
        status: existing ? existing.status : 'Draft',
        hideStatistik: 0
      }

      if (isEdit && id) {
        await api.updateElection(id, payload)
        toast(`Pemilu "${judul}" berhasil diperbarui`, 'success')
        navigate('/admin/pemilu')
      } else {
        await api.createElection(payload)
        toast(`Pemilu "${judul}" berhasil dibuat`, 'success')
        navigate(`/admin/pemilu`)
      }
    } catch (error: any) {
      const msg = error.response?.data?.error || 'Terjadi kesalahan saat menyimpan'
      toast(msg, 'error')
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return <div className="px-10 py-8">Memuat form pemilu...</div>
  }

  if (loading) return <div className="p-10">Loading...</div>

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Pemilu', to: '/admin/pemilu' },
          { label: isEdit ? 'Edit Pemilu' : 'Buat Pemilu' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">
        {isEdit ? 'Edit Pemilu' : 'Buat Pemilu Baru'}
      </h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_300px] gap-6 items-start">
        <div className="min-w-0">
          <SectionCard title="Detail Pemilu">
            <div className="space-y-4">
              <div>
                <Label required>Judul Pemilu</Label>
                <Input
                  placeholder="Mis. PEMILU Ketua IKA JTK 2025-2028"
                  value={judul}
                  onChange={(e) => setJudul(e.target.value)}
                />
              </div>
              <div>
                <Label required>Deskripsi</Label>
                <RichTextEditor
                  minHeight={200}
                  placeholder="Jelaskan tujuan dan informasi penting pemilu..."
                  value={deskripsi}
                  onChange={setDeskripsi}
                />
              </div>
              <div className="pt-3 border-t border-gray-100">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <Label required>Periode Mulai (Waktu Pemilihan)</Label>
                    <Input
                      type="datetime-local"
                      value={periodeStart}
                      onChange={(e) => setPeriodeStart(e.target.value)}
                      className={isBackdate ? 'border-red-500' : ''}
                      disabled={isJadwalLocked}
                    />
                    {isBackdate && (
                      <p className="mt-1 text-xs text-red-600 font-medium">
                        Periode mulai tidak boleh di waktu yang sudah lewat.
                      </p>
                    )}
                    {isJadwalLocked && (
                      <p className="mt-1 text-xs text-amber-600 font-medium">
                        Jadwal tidak dapat diubah karena pemilu sudah dimulai.
                      </p>
                    )}
                  </div>
                  <div>
                    <Label required>Periode Selesai (Waktu Pemilihan)</Label>
                    <Input
                      type="datetime-local"
                      value={periodeEnd}
                      onChange={(e) => setPeriodeEnd(e.target.value)}
                      className={isEndInvalid ? 'border-red-500' : ''}
                      disabled={isJadwalLocked}
                    />
                    {isEndInvalid && (
                      <p className="mt-1 text-xs text-red-600 font-medium">
                        Periode selesai harus setelah periode mulai.
                      </p>
                    )}
                  </div>
                </div>
                <p className="mt-1 text-xs text-gray-500">
                  Pemilu hanya aktif menerima suara dalam rentang waktu pemilihan di atas.
                </p>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4 pt-3 border-t border-gray-100">
                  <div>
                    <Label>Tanggal Pengumuman Hasil</Label>
                    <Input
                      type="date"
                      value={pengumumanDate}
                      onChange={(e) => setPengumumanDate(e.target.value)}
                      className={isPengumumanInvalid ? 'border-red-500' : ''}
                      disabled={isJadwalLocked}
                    />
                    {isPengumumanInvalid ? (
                      <p className="mt-1 text-xs text-red-600 font-medium">
                        Tanggal pengumuman tidak boleh sebelum (backdate) dari periode selesai pemilihan.
                      </p>
                    ) : (
                      <p className="mt-1 text-xs text-gray-500">
                        Opsional. Jadwal pengumuman hasil pemungutan suara.
                      </p>
                    )}
                  </div>
                  <div>
                    <Label>Tanggal Pelantikan Ketua Terpilih</Label>
                    <Input
                      type="date"
                      value={pelantikanDate}
                      onChange={(e) => setPelantikanDate(e.target.value)}
                      className={isPelantikanInvalid ? 'border-red-500' : ''}
                      disabled={isJadwalLocked}
                    />
                    {isPelantikanInvalid ? (
                      <p className="mt-1 text-xs text-red-600 font-medium">
                        Tanggal pelantikan tidak boleh sebelum (backdate) dari tanggal pengumuman / pemilihan.
                      </p>
                    ) : (
                      <p className="mt-1 text-xs text-gray-500">
                        Opsional. Jadwal pelantikan resmi ketua terpilih.
                      </p>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </SectionCard>

          <div className="mt-4 text-sm text-gray-500">
            Setelah menyimpan draft, kamu akan diarahkan ke halaman tambah kandidat.
          </div>
        </div>

        <aside className="lg:sticky lg:top-8 space-y-4">
          {isEdit && existing && (
            <SectionCard title="Status Pemilu">
              <div className="flex items-center gap-2">
                <span className="text-xs text-gray-500">Status saat ini:</span>
                <StatusBadge status={existing.status} />
              </div>
              <p className="mt-2 text-xs text-gray-400">
                Status hanya dapat diubah melalui halaman detail pemilu.
              </p>
            </SectionCard>
          )}
          <SectionCard title="Action">
            <div className="space-y-3">
              <Button
                className="w-full"
                disabled={formInvalid}
                onClick={() => setConfirmSave(true)}
                leftIcon={submitting ? undefined : <Save className="h-4 w-4" />}
              >
                {submitting ? 'Menyimpan...' : isEdit ? 'Simpan Perubahan' : 'Simpan Pemilu'}
              </Button>
              <button
                type="button"
                onClick={() => navigate('/admin/pemilu')}
                className="w-full text-sm text-gray-500 hover:text-gray-800 mt-2"
              >
                Batal
              </button>
            </div>
          </SectionCard>
        </aside>
      </div>

      <ConfirmDialog
        open={confirmSave}
        title={isEdit ? 'Simpan Perubahan?' : 'Simpan Pemilu sebagai Draft?'}
        description={
          isEdit
            ? 'Perubahan data pemilu akan tersimpan.'
            : 'Pemilu akan tersimpan sebagai draft, lalu kamu diarahkan ke form tambah kandidat.'
        }
        confirmLabel="Simpan"
        cancelLabel="Batal"
        onConfirm={submit}
        onCancel={() => setConfirmSave(false)}
      />
    </div>
  )
}

function AlumniCombobox({
  value,
  alumniList,
  onSelect,
}: {
  value: Alumni | null
  alumniList: Alumni[]
  onSelect: (alumni: Alumni | null) => void
}) {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')
  const wrapRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    const onDown = (e: MouseEvent) => {
      if (wrapRef.current && !wrapRef.current.contains(e.target as Node)) {
        setOpen(false)
      }
    }
    document.addEventListener('mousedown', onDown)
    return () => document.removeEventListener('mousedown', onDown)
  }, [open])

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    const base = q
      ? alumniList.filter(
        (a) =>
          a.nama.toLowerCase().includes(q) ||
          a.angkatan.toString().toLowerCase().includes(q) ||
          (a.noAlumni && a.noAlumni.toLowerCase().includes(q)),
      )
      : alumniList
    return base.slice(0, 50)
  }, [query, alumniList])

  return (
    <div className="relative" ref={wrapRef}>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className={cn(
          'flex w-full items-center justify-between rounded-md border bg-white pl-3 pr-2 h-10 text-sm',
          'border-gray-300 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary',
          !value && 'text-gray-400',
        )}
      >
        <span className="truncate text-left">
          {value ? (
            <span className="text-gray-900">
              {value.nama}
              <span className="ml-2 text-xs text-gray-500">
                Angkatan {value.angkatan}
                {value.noAlumni !== '-' && ` · ${value.noAlumni}`}
              </span>
            </span>
          ) : (
            'Pilih alumni'
          )}
        </span>
        <span className="flex items-center gap-1">
          {value && (
            <span
              role="button"
              tabIndex={0}
              onClick={(e) => {
                e.stopPropagation()
                onSelect(null)
              }}
              className="p-1 rounded hover:bg-gray-100 text-gray-400"
              aria-label="Hapus pilihan"
            >
              <X className="h-3.5 w-3.5" />
            </span>
          )}
          <ChevronDown className="h-4 w-4 text-gray-400" />
        </span>
      </button>

      {open && (
        <div className="absolute z-20 mt-1 w-full rounded-md border border-gray-200 bg-white shadow-lg">
          <div className="flex items-center gap-2 border-b border-gray-100 px-3 h-9">
            <Search className="h-3.5 w-3.5 text-gray-400" />
            <input
              autoFocus
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Cari nama, angkatan, atau no. alumni"
              className="w-full text-sm outline-none placeholder:text-gray-400"
            />
          </div>
          <div className="max-h-72 overflow-y-auto py-1">
            {filtered.length === 0 ? (
              <div className="px-3 py-6 text-center text-sm text-gray-500">
                Tidak ada alumni yang cocok.
              </div>
            ) : (
              filtered.map((a) => {
                const selected = value?.id === a.id
                return (
                  <button
                    key={a.id}
                    type="button"
                    onClick={() => {
                      onSelect(a)
                      setOpen(false)
                      setQuery('')
                    }}
                    className={cn(
                      'flex w-full items-center gap-3 px-3 py-2 text-left hover:bg-gray-50',
                      selected && 'bg-primary/5',
                    )}
                  >
                    <div className="h-8 w-8 rounded-full bg-gray-100 overflow-hidden shrink-0">
                      {a.avatarUrl && (
                        <img
                          src={getThumbnailUrl(a.avatarUrl, a.nama)}
                          alt=""
                          className="h-8 w-8 rounded-full object-cover shrink-0"
                        />
                      )}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="text-sm font-medium text-gray-900 truncate">
                        {a.nama}
                      </div>
                      <div className="text-xs text-gray-500 truncate">
                        Angkatan {a.angkatan}
                        {a.noAlumni !== '-' && ` · No. ${a.noAlumni}`}
                      </div>
                    </div>
                  </button>
                )
              })
            )}
            {query.trim().length === 0 && alumniList.length > 50 && (
              <div className="px-3 py-2 text-center text-xs text-gray-400 border-t border-gray-100">
                Menampilkan 50 dari {alumniList.length} alumni. Ketik untuk mencari.
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

const currentYear = new Date().getFullYear();
const tahunOptions = Array.from({ length: 60 }, (_, i) => String(currentYear - i));

export function KandidatFormPage() {
  const navigate = useNavigate()
  const { electionId, kandidatId } = useParams()
  const isEdit = Boolean(kandidatId)



  const [election, setElection] = useState<Election | null>(null)
  const [existing, setExisting] = useState<any>(null)
  const [alumniList, setAlumniList] = useState<Alumni[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedAlumni, setSelectedAlumni] = useState<Alumni | null>(null)

  const availableAlumniList = useMemo(() => {
    const activeAlumni = alumniList.filter(a => a.status === 'ACTIVE');
    const candidates = (election as any)?.candidates || election?.kandidat || [];
    
    if (candidates.length === 0) return activeAlumni;
    
    const existingAlumniIds = new Set(
      candidates
        .filter((c: any) => c.id !== kandidatId && c.alumniId)
        .map((c: any) => c.alumniId)
    )
    const existingNames = new Set(
      candidates
        .filter((c: any) => c.id !== kandidatId && c.nama)
        .map((c: any) => c.nama.toLowerCase().trim())
    )
    return activeAlumni.filter(
      (a) =>
        !existingAlumniIds.has(a.id) &&
        !existingNames.has(a.nama.toLowerCase().trim())
    )
  }, [alumniList, election, kandidatId])
  const [nomorUrut, setNomorUrut] = useState('1')
  const [visi, setVisi] = useState('')
  const [misi, setMisi] = useState<string[]>([''])
  const [pengalaman, setPengalaman] = useState<string[]>([''])
  const [tagline, setTagline] = useState('')
  const [programKerja, setProgramKerja] = useState<ProgramKerjaItem[]>([{ title: '', description: '' }])
  const [prestasi, setPrestasi] = useState<PrestasiItem[]>([{ text: '', year: '' }])
  const [confirmSave, setConfirmSave] = useState(false)

  const handleAlumniSelect = (alumni: Alumni | null) => {
    setSelectedAlumni(alumni)
    if (alumni && Array.isArray(alumni.prestasi) && alumni.prestasi.length > 0) {
      setPrestasi(
        alumni.prestasi.map((p) => ({
          text: p.judul ?? '',
          year: p.tahun ?? '',
        }))
      )
    }
  }
  const [submitting, setSubmitting] = useState(false)
  // Uploaded photo override. When null, the candidate photo defaults to the
  // selected alumni's avatar; when set, it replaces it.
  const [fotoOverride, setFotoOverride] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const { cropModalOpen, cropTarget, startCrop, closeCrop, uploadCropped, cropLoadingOverlay } = useImageCropUpload()

  const handleUploadFoto = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    const validExts = ['jpg', 'jpeg', 'png', 'svg']
    const ext = file.name.split('.').pop()?.toLowerCase() || ''
    if (!validExts.includes(ext)) {
      toast('Format file tidak didukung. Gunakan JPG, PNG, atau SVG.', 'error')
      e.target.value = ''
      return
    }

    const localUrl = URL.createObjectURL(file)
    startCrop({ id: 'foto', url: localUrl, title: 'Potong Foto Kandidat', maxSizeMb: 10, maxDimension: 1080, imageType: file.type })
    if (e.target) e.target.value = ''
  }

  const handleFotoCropComplete = async (cropFile: File) => {
    const url = await uploadCropped(cropFile, '/upload/avatar')
    if (url) {
      setFotoOverride(url)
    } else {
      toast('Gagal mengunggah foto hasil potong', 'error')
    }
  }

  useEffect(() => {
    if (!electionId) return
    Promise.all([
      api.getElectionById(electionId),
      api.getAlumni()
    ]).then(([data, alumniData]) => {
      setElection(data)
      setAlumniList(alumniData)
      const cand = data.candidates?.find((c: any) => c.id === kandidatId)
      if (isEdit && cand) {
        setExisting(cand)
        setNomorUrut(String(cand.nomorUrut))
        setVisi(cand.visi)
        setMisi(Array.isArray(cand.misi) && cand.misi.length > 0 ? cand.misi : [''])
        setTagline(typeof cand.tagline === 'string' ? cand.tagline : '')

        const pengalamanRaw = cand.pengalaman
        const isNestedPengalaman =
          pengalamanRaw && !Array.isArray(pengalamanRaw) && typeof pengalamanRaw === 'object'

        if (isNestedPengalaman) {
          setPengalaman([''])
        } else if (Array.isArray(pengalamanRaw) && pengalamanRaw.length > 0) {
          setPengalaman(pengalamanRaw.map((p: any) => (typeof p === 'string' ? p : '')))
        } else {
          setPengalaman([''])
        }

        const rawProgramKerja = isNestedPengalaman
          ? pengalamanRaw.programKerja
          : cand.programKerja
        setProgramKerja(
          Array.isArray(rawProgramKerja) && rawProgramKerja.length > 0
            ? rawProgramKerja.map((p: any) => ({
                title: typeof p?.title === 'string' ? p.title : (typeof p?.judul === 'string' ? p.judul : ''),
                description: typeof p?.description === 'string' ? p.description : (typeof p?.deskripsi === 'string' ? p.deskripsi : ''),
              }))
            : [{ title: '', description: '' }]
        )

        const rawPrestasi = isNestedPengalaman
          ? pengalamanRaw.prestasi
          : cand.prestasi
        setPrestasi(
          Array.isArray(rawPrestasi) && rawPrestasi.length > 0
            ? rawPrestasi.map((p: any) => ({
                text: typeof p?.text === 'string' ? p.text : (typeof p?.judul === 'string' ? p.judul : ''),
                year: typeof p?.year === 'string' ? p.year : (typeof p?.tahun === 'string' ? p.tahun : String(p?.year ?? p?.tahun ?? '')),
              }))
            : [{ text: '', year: '' }]
        )

        const alumniMatch = alumniData.find((a: Alumni) => a.id === cand.alumniId) || {
          id: cand.alumniId || '',
          nama: cand.nama,
          angkatan: cand.angkatan,
          avatarUrl: cand.fotoUrl || cand.avatarUrl || null,
          noAlumni: '-',
          email: '',
          keanggotaan: 'Alumni',
          status: 'Active',
          tanggalLahir: null,
          motto: '',
          jenisKelamin: null,
          emailVisibility: 'public',
          nomorHandphone: '',
          nomorHandphoneVisibility: 'public',
          linkedin: '',
          alamat: '',
          alamatVisibility: 'public',
          pekerjaan: [],
          prestasi: [],
          createdAt: ''
        } as unknown as Alumni
        setSelectedAlumni(alumniMatch)
      } else if (!isEdit) {
        setNomorUrut(String(data.candidates?.length ? data.candidates.length + 1 : 1))
      }
    }).catch(() => {
      toast('Gagal memuat data pemilu', 'error')
      navigate('/admin/pemilu')
    }).finally(() => setLoading(false))
  }, [electionId, kandidatId, isEdit, navigate])

  if (loading) {
    return <div className="px-10 py-8">Memuat form kandidat...</div>
  }


  const updateListItem = (
    list: string[],
    setList: (v: string[]) => void,
    idx: number,
    value: string,
  ) => {
    const next = [...list]
    next[idx] = value
    setList(next)
  }

  const nama = selectedAlumni?.nama ?? ''
  const angkatan = selectedAlumni?.angkatan ?? ''
  // Effective candidate photo: uploaded override wins, else the selected
  // alumni's avatar, else the existing candidate's photo (edit mode).
  const fotoUrl = fotoOverride ?? selectedAlumni?.avatarUrl ?? existing?.fotoUrl ?? existing?.avatarUrl ?? ''

  const formInvalid =
    !selectedAlumni ||
    visi.trim().length === 0 ||
    misi.every((m) => m.trim().length === 0) ||
    submitting

  const submit = async () => {
    if (!electionId) return
    setConfirmSave(false)
    setSubmitting(true)
    try {
      const payload = {
        alumniId: selectedAlumni?.id ?? null,
        nama,
        angkatan: angkatan ? parseInt(angkatan.toString(), 10) : null,
        fotoUrl,
        nomorUrut: parseInt(nomorUrut, 10) || 1,
        visi,
        misi: misi.filter((m) => m.trim().length > 0),
        pengalaman: pengalaman.filter((p) => p.trim().length > 0),
        tagline: tagline.trim(),
        programKerja: programKerja
          .filter((p) => p.title.trim().length > 0 || p.description.trim().length > 0)
          .map((p) => ({ title: p.title.trim(), description: p.description.trim() })),
        prestasi: prestasi
          .filter((p) => p.text.trim().length > 0)
          .map((p) => ({ text: p.text.trim(), year: String(p.year || '').trim() })),
      }

      if (isEdit && kandidatId) {
        await api.updateCandidate(electionId, kandidatId, payload)
        toast(`Kandidat "${nama}" berhasil diperbarui`, 'success')
      } else {
        await api.addCandidate(electionId, payload)
        toast(`Kandidat "${nama}" berhasil ditambahkan`, 'success')
      }
      navigate(`/admin/pemilu/${electionId}`)
    } catch (err: any) {
      console.error(err)
      const errorMsg = err.response?.data?.error || err.response?.data?.message || err.message || 'Gagal menyimpan kandidat';
      toast(`Error: ${errorMsg}`, 'error')
    } finally {
      setSubmitting(false)
    }
  }

  if (!election) return <Navigate to="/admin/pemilu" replace />

return (
  <div className="px-10 py-8">
    <Breadcrumb
      items={[
        { label: 'Pemilu', to: '/admin/pemilu' },
        { label: election.judul, to: `/admin/pemilu/${election.id}` },
        { label: isEdit ? 'Edit Kandidat' : 'Tambah Kandidat' },
      ]}
    />
    <h1 className="mt-2 text-3xl font-bold text-gray-900">
      {isEdit ? 'Edit Kandidat' : 'Tambah Kandidat'}
    </h1>
    <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

    <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_300px] gap-6 items-start">
      <div className="space-y-6 min-w-0">
        <SectionCard title="Foto Profile">
          <div className="flex items-start gap-6">
            <div className="h-32 w-32 rounded bg-gray-100 border border-gray-200 flex items-center justify-center overflow-hidden">
              {fotoUrl ? (
                <img
                  src={getAvatarUrl(fotoUrl, nama || existing?.nama)}
                  alt={nama || 'Foto kandidat'}
                  className="h-full w-full object-cover"
                />
              ) : (
                <Upload className="h-8 w-8 text-gray-300" />
              )}
            </div>
            <div className="flex items-center gap-3 pt-2">
              <input
                type="file"
                ref={fileInputRef}
                className="hidden"
                accept=".jpg,.jpeg,.png"
                onChange={handleUploadFoto}
              />
              <div className="flex flex-col">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => fileInputRef.current?.click()}
                >
                  Pilih Foto
                </Button>
                <p className="text-[10px] text-gray-500 mt-1">Maks. 10MB</p>
              </div>
              {fotoOverride && (
                <button
                  type="button"
                  onClick={() => setFotoOverride(null)}
                  className="text-sm font-semibold text-gray-600 hover:text-danger"
                >
                  Hapus
                </button>
              )}
              {selectedAlumni && !fotoOverride && (
                <span className="text-xs text-gray-500">
                  Diambil dari data alumni. Pilih foto untuk mengganti.
                </span>
              )}
            </div>
          </div>
        </SectionCard>

        <SectionCard title="Data Kandidat">
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-[1fr_120px] gap-4">
              <div>
                <Label required>Nama Lengkap</Label>
                <AlumniCombobox
                  value={selectedAlumni}
                  alumniList={availableAlumniList}
                  onSelect={handleAlumniSelect}
                />
                <p className="mt-1 text-xs text-gray-500">
                  Dipilih dari data alumni terdaftar.
                </p>
              </div>
              <div>
                <Label required>Nomor Urut</Label>
                <Input
                  type="number"
                  min={1}
                  value={nomorUrut}
                  onChange={(e) => setNomorUrut(e.target.value)}
                />
              </div>
            </div>
            <div>
              <Label>Angkatan</Label>
              <Input
                placeholder="Otomatis dari data alumni"
                value={angkatan}
                readOnly
                disabled
              />
            </div>
          </div>
        </SectionCard>

        <SectionCard title="Visi & Misi">
          <div className="space-y-4">
            <div>
              <Label>Tagline</Label>
              <Input
                placeholder="Slogan singkat kandidat (mis. Menguatkan jejaring alumni…)"
                value={tagline}
                onChange={(e) => setTagline(e.target.value)}
                maxLength={255}
              />
              <p className="mt-1 text-xs text-gray-500">
                Muncul di hero halaman profil kandidat.
              </p>
            </div>
            <div>
              <Label required>Visi</Label>
              <RichTextEditor
                minHeight={160}
                placeholder="Visi kandidat untuk periode kepemimpinan..."
                value={visi}
                onChange={setVisi}
              />
            </div>
            <div>
              <Label required>Misi (poin-poin)</Label>
              <div className="space-y-2">
                {misi.map((m, i) => (
                  <div key={i} className="flex items-center gap-2">
                    <Input
                      placeholder={`Misi ke-${i + 1}`}
                      value={m}
                      onChange={(e) => updateListItem(misi, setMisi, i, e.target.value)}
                    />
                    {misi.length > 1 && (
                      <button
                        type="button"
                        onClick={() => setMisi(misi.filter((_, idx) => idx !== i))}
                        className="p-2 rounded hover:bg-gray-100 text-gray-400 hover:text-danger"
                        aria-label="Hapus misi"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    )}
                  </div>
                ))}
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setMisi([...misi, ''])}
                  leftIcon={<Plus className="h-3.5 w-3.5" />}
                >
                  Tambah Misi
                </Button>
              </div>
            </div>
          </div>
        </SectionCard>

        <SectionCard title="Program Kerja">
          <div className="space-y-4">
            {programKerja.map((p, i) => (
              <div key={i} className="p-4 border border-gray-200 rounded-lg space-y-3 relative bg-gray-50/50">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Program Kerja #{i + 1}</span>
                  {programKerja.length > 1 && (
                    <button
                      type="button"
                      onClick={() => setProgramKerja(programKerja.filter((_, idx) => idx !== i))}
                      className="text-gray-400 hover:text-danger p-1"
                      aria-label="Hapus program kerja"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  )}
                </div>
                <div>
                  <Label required>Judul Program</Label>
                  <Input
                    placeholder="Contoh: Digital Alumni Hub"
                    value={p.title}
                    onChange={(e) => {
                      const next = [...programKerja]
                      next[i] = { ...next[i], title: e.target.value }
                      setProgramKerja(next)
                    }}
                  />
                </div>
                <div>
                  <Label>Deskripsi Singkat</Label>
                  <Input
                    placeholder="Contoh: Satu portal untuk data alumni, kegiatan, lowongan..."
                    value={p.description}
                    onChange={(e) => {
                      const next = [...programKerja]
                      next[i] = { ...next[i], description: e.target.value }
                      setProgramKerja(next)
                    }}
                  />
                </div>
              </div>
            ))}
            <Button
              variant="outline"
              size="sm"
              onClick={() => setProgramKerja([...programKerja, { title: '', description: '' }])}
              leftIcon={<Plus className="h-3.5 w-3.5" />}
            >
              Tambah Program Kerja
            </Button>
          </div>
        </SectionCard>

        <SectionCard title="Prestasi">
          <p className="mb-3 text-xs text-gray-500">
            Otomatis terisi dari data alumni yang dipilih. Bisa diedit atau ditambah.
          </p>
          <div className="space-y-3">
            {prestasi.map((p, i) => (
              <div key={i} className="flex items-center gap-2">
                <div className="flex-1">
                  <Input
                    placeholder={`Judul Prestasi ke-${i + 1} (Contoh: Top 50 Inspiring Women in Tech)`}
                    value={p.text}
                    onChange={(e) => {
                      const next = [...prestasi]
                      next[i] = { ...next[i], text: e.target.value }
                      setPrestasi(next)
                    }}
                  />
                </div>
                <div className="w-32">
                  <Select
                    value={p.year}
                    onChange={(e) => {
                      const next = [...prestasi]
                      next[i] = { ...next[i], year: e.target.value }
                      setPrestasi(next)
                    }}
                  >
                    <option value="">Tahun</option>
                    {tahunOptions.map((y) => (
                      <option key={y} value={y}>{y}</option>
                    ))}
                  </Select>
                </div>
                {prestasi.length > 1 && (
                  <button
                    type="button"
                    onClick={() => setPrestasi(prestasi.filter((_, idx) => idx !== i))}
                    className="p-2 rounded hover:bg-gray-100 text-gray-400 hover:text-danger shrink-0"
                    aria-label="Hapus prestasi"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                )}
              </div>
            ))}
            <Button
              variant="outline"
              size="sm"
              onClick={() => setPrestasi([...prestasi, { text: '', year: '' }])}
              leftIcon={<Plus className="h-3.5 w-3.5" />}
            >
              Tambah Prestasi
            </Button>
          </div>
        </SectionCard>

        {/*
        <SectionCard title="Pengalaman">
          <div className="space-y-2">
            {pengalaman.map((p, i) => (
              <div key={i} className="flex items-center gap-2">
                <Input
                  placeholder={`Pengalaman ke-${i + 1}`}
                  value={p}
                  onChange={(e) => updateListItem(pengalaman, setPengalaman, i, e.target.value)}
                />
                {pengalaman.length > 1 && (
                  <button
                    type="button"
                    onClick={() => setPengalaman(pengalaman.filter((_, idx) => idx !== i))}
                    className="p-2 rounded hover:bg-gray-100 text-gray-400 hover:text-danger"
                    aria-label="Hapus pengalaman"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                )}
              </div>
            ))}
            <Button
              variant="outline"
              size="sm"
              onClick={() => setPengalaman([...pengalaman, ''])}
              leftIcon={<Plus className="h-3.5 w-3.5" />}
            >
              Tambah Pengalaman
            </Button>
          </div>
        </SectionCard>
        */}
      </div>

      <aside className="lg:sticky lg:top-8">
        <SectionCard title="Action">
          <div className="space-y-3">
            <Button
              className="w-full"
              disabled={formInvalid}
              onClick={() => setConfirmSave(true)}
              leftIcon={submitting ? undefined : <Save className="h-4 w-4" />}
            >
              {submitting ? 'Menyimpan...' : isEdit ? 'Simpan Perubahan' : 'Tambah Kandidat'}
            </Button>
            <button
              type="button"
              onClick={() => navigate(`/admin/pemilu/${electionId}`)}
              className="w-full text-sm text-gray-500 hover:text-gray-800 mt-2"
            >
              Batal
            </button>
          </div>
        </SectionCard>
      </aside>
    </div>

    <ConfirmDialog
      open={confirmSave}
      title={isEdit ? 'Simpan Perubahan?' : 'Tambah Kandidat?'}
      description={
        isEdit
          ? 'Perubahan data kandidat akan tersimpan.'
          : 'Kandidat baru akan ditambahkan ke pemilu ini.'
      }
      confirmLabel="Simpan"
      cancelLabel="Batal"
      onConfirm={submit}
      onCancel={() => setConfirmSave(false)}
    />

      {cropTarget && (
        <ImageCropModal
          open={cropModalOpen}
          imageUrl={cropTarget.url}
          title={cropTarget.title}
          aspectRatio={1}
          aspectRatioLabel="Foto Kandidat (1 : 1)"
          imageType={cropTarget?.imageType}
          onClose={closeCrop}
          onCropComplete={handleFotoCropComplete}
        />
      )}
      {cropLoadingOverlay}
  </div>
)
}


