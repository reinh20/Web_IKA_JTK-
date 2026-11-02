import { useNavigate, useParams } from 'react-router-dom'
import { useState, useEffect, useRef } from 'react'
import { Plus, Trash2, ImagePlus, FileText, ImageIcon } from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { VisibilityRadio } from '@/components/admin/VisibilityRadio'
import { Input, Label } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { SearchableSelect } from '@/components/ui/SearchableSelect'
import { Button } from '@/components/ui/Button'
import { Checkbox } from '@/components/ui/Checkbox'
import { ImageCropModal } from '@/components/ui/ImageCropModal'
import { RadioGroup } from '@/components/ui/RadioGroup'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { getAvatarUrl, getFileUrl } from '@/lib/utils'
import { useImageCropUpload } from '@/lib/useImageCropUpload'
import type { Pekerjaan, Prestasi, Visibility } from '@/types/alumni'
import { getFriendlyErrorMessage } from '../../utils/errorHandler'
import { formatFileName } from '../../utils/file';
import { countryCodes } from '../../utils/country_codes';

const BULAN = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
]

function uid() {
  return Math.random().toString(36).slice(2, 10)
}

function emptyPekerjaan(): Pekerjaan {
  return {
    id: uid(),
    pekerjaan: '',
    perusahaan: '',
    bulanMulai: '',
    tahunMulai: '',
    bulanSelesai: '',
    tahunSelesai: '',
    masihBekerja: false,
  }
}

function emptyPrestasi(): Prestasi {
  return { id: uid(), judul: '', tahun: '' }
}

export function AlumniFormPage() {
  const navigate = useNavigate()
  const { id } = useParams()
  const isEdit = Boolean(id)

  const [foto, setFoto] = useState<string | null>(null)
  const [nama, setNama] = useState('')
  const [angkatan, setAngkatan] = useState('')
  const [keanggotaan, setKeanggotaan] = useState('Alumni')
  const [tanggalLahir, setTanggalLahir] = useState('')
  const [motto, setMotto] = useState('')
  const [jenisKelamin, setJenisKelamin] = useState<any>('')

  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')

  const [email, setEmail] = useState('')
  const [emailVis, setEmailVis] = useState<Visibility>('private')
  const [hpPrefix, setHpPrefix] = useState('62')
  const [hp, setHp] = useState('')
  const [hpVis, setHpVis] = useState<Visibility>('private')
  const [linkedin, setLinkedin] = useState('')
  const [alamat, setAlamat] = useState('')
  const [alamatVis, setAlamatVis] = useState<Visibility>('private')
  const [nomorIjazah, setNomorIjazah] = useState('')
  const [tahunLulus, setTahunLulus] = useState('')
  const [ipk, setIpk] = useState('')
  const [ijazahFile, setIjazahFile] = useState<string | null>(null)

  const [pekerjaan, setPekerjaan] = useState<Pekerjaan[]>([emptyPekerjaan()])
  const [prestasi, setPrestasi] = useState<Prestasi[]>([emptyPrestasi()])
  const [alumniGrafisKategori, setAlumniGrafisKategori] = useState<'Jabatan strategis/Public Figure' | 'Public Figure' | 'Prestasi' | 'None' | ''>('')
  const [alumniGrafisId, setAlumniGrafisId] = useState('')
  const [alumniGrafisStatus, setAlumniGrafisStatus] = useState<string | null>(null)
  const [userAgreement, setUserAgreement] = useState(true)
  const [isLoading, setIsLoading] = useState(isEdit)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const { cropModalOpen, cropTarget, startCrop, closeCrop, uploadCropped, cropLoadingOverlay } = useImageCropUpload()

  useEffect(() => {
    if (isEdit) {
      api.get(`/admin/alumni/${id}`)
        .then((res) => {
          const d = res.data
          setFoto(d.avatarUrl || null)
          setNama(d.nama || '')
          setAngkatan(d.angkatan ? String(d.angkatan) : '')
          setKeanggotaan(d.keanggotaan || 'Alumni')
          setTanggalLahir(d.tanggalLahir || '')
          setMotto(d.motto || '')
          setJenisKelamin(d.jenisKelamin || '')
          setUsername(d.username || '')
          // password never returned from API; leave blank
          setEmail(d.email || '')
          setEmailVis(d.emailVisibility || 'private')

          let hpRaw = d.nomorHandphone || ''
          let foundPrefix = '62'
          if (hpRaw.startsWith('+')) hpRaw = hpRaw.substring(1)
          for (const c of countryCodes) {
            if (hpRaw.startsWith(c.code)) {
               foundPrefix = c.code;
               hpRaw = hpRaw.substring(c.code.length).trim();
               break;
            }
          }
          if (hpRaw.startsWith('0')) hpRaw = hpRaw.substring(1).trim()
          setHpPrefix(foundPrefix)
          setHp(hpRaw)

          setHpVis(d.nomorHandphoneVisibility || 'private')
          const rawLinkedin = d.linkedin || ''
          const liUsername = rawLinkedin
            .replace('https://www.linkedin.com/in/', '')
            .replace('https://linkedin.com/in/', '')
            .replace(/\/$/, '')
          setLinkedin(liUsername)
          setAlamat(d.alamat || '')
          setAlamatVis(d.alamatVisibility || 'private')
          setNomorIjazah(d.nomorIjazah || '')
          setTahunLulus(d.tahunLulus?.toString() || '')
          setIpk(d.ipk?.toString() || '')
          setIjazahFile(d.ijazahFile || null)
          if (d.pekerjaan?.length) {
            setPekerjaan(d.pekerjaan.map((p: any) => ({
              ...p,
              tahunMulai: p.tahunMulai ? String(p.tahunMulai) : '',
              tahunSelesai: p.tahunSelesai ? String(p.tahunSelesai) : ''
            })))
          }
          if (d.prestasi?.length) {
            setPrestasi(d.prestasi.map((p: any) => ({
              ...p,
              tahun: p.tahun ? String(p.tahun) : ''
            })))
          }
          
          setUserAgreement(Boolean(d.userAgreement))

          if (d.alumniGrafis) {
            try {
              const parsed = typeof d.alumniGrafis === 'string' ? JSON.parse(d.alumniGrafis) : d.alumniGrafis;
              if (parsed) {
                let kat = parsed.kategori || '';
                if (kat === 'Public Figure') kat = 'Jabatan strategis/Public Figure';
                setAlumniGrafisKategori(kat);
                setAlumniGrafisId(parsed.id || '');
                setAlumniGrafisStatus(parsed.status || null);
              }
            } catch (e) { }
          }
        })
        .catch(() => {
          toast('Gagal memuat alumni', 'error')
          navigate('/admin/alumni')
        })
        .finally(() => setIsLoading(false))
    }
  }, [id, isEdit, navigate])

  const updatePekerjaan = (id: string, patch: Partial<Pekerjaan>) =>
    setPekerjaan((list) => list.map((p) => (p.id === id ? { ...p, ...patch } : p)))
  const updatePrestasi = (id: string, patch: Partial<Prestasi>) =>
    setPrestasi((list) => list.map((p) => (p.id === id ? { ...p, ...patch } : p)))

  const handleSubmit = async () => {
    const newErrors: Record<string, string> = {}
    setErrors({})

    if (isStrictMode) {
      if (!foto) newErrors.foto = 'Mohon unggah foto profil untuk melengkapi data tambahan yang Anda berikan.'
      if (!tanggalLahir) newErrors.tanggalLahir = 'Mohon lengkapi informasi tanggal lahir Anda.'
      if (!linkedin.trim()) newErrors.linkedin = 'Mohon cantumkan profil LinkedIn Anda.'
      if (!alamat.trim()) newErrors.alamat = 'Mohon isi alamat domisili Anda untuk melengkapi profil.'
      if (!nomorIjazah.trim()) newErrors.nomorIjazah = 'Mohon isi nomor dokumen (ijazah/PDDIKTI/SKJ) Anda.'
      if (!tahunLulus.trim()) newErrors.tahunLulus = 'Mohon isi tahun kelulusan Anda.'
      if (!ipk.trim()) newErrors.ipk = 'Mohon lengkapi nilai IPK Anda.'
      if (!ijazahFile) newErrors.ijazahFile = 'Mohon unggah dokumen ijazah untuk memvalidasi data Anda.'
    }

    if (!nama.trim()) {
      newErrors.nama = 'Nama lengkap wajib diisi.'
    }

    if (!jenisKelamin) {
      newErrors.jenisKelamin = 'Jenis kelamin wajib dipilih.'
    }

    if (!username.trim()) {
      newErrors.username = 'Username wajib diisi.'
    } else if (/\s/.test(username)) {
      newErrors.username = 'Username tidak boleh mengandung spasi.'
    }

    if (!email.trim()) {
      newErrors.email = 'Alamat email wajib diisi.'
    } else if (email.trim()) {
      const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/
      if (!emailRegex.test(email.trim())) {
        newErrors.email = 'Format alamat email tidak sesuai. Harap pastikan penulisannya benar.'
      }
    }

    if (!hp.trim()) {
      newErrors.hp = 'Nomor handphone wajib diisi.'
    } else {
      const cleanHp = hp.trim()
      if (!cleanHp.startsWith('8') && hpPrefix === '62') {
        newErrors.hp = 'Nomor handphone Indonesia harus diawali dengan angka 8.'
      } else if (cleanHp.length < 5 || cleanHp.length > 15) {
        newErrors.hp = 'Format nomor handphone tidak sesuai. Harap periksa jumlah digit.'
      }
    }

    if (alamat.trim().length > 300) {
      newErrors.alamat = 'Alamat terlalu panjang (maksimal 300 karakter).'
    }

    if (!angkatan.trim()) newErrors.angkatan = 'Mohon isi tahun angkatan untuk melengkapi profil Anda.'
    if (!keanggotaan) newErrors.keanggotaan = 'Keanggotaan wajib dipilih.'

    if (ipk.trim()) {
      const numIpk = parseFloat(ipk.trim())
      if (isNaN(numIpk) || numIpk < 0 || numIpk > 4.00) {
        newErrors.ipk = 'IPK maksimal adalah 4.00'
      }
    }

    if (tahunLulus.trim() && angkatan.trim()) {
      const a = parseInt(angkatan, 10)
      const t = parseInt(tahunLulus, 10)
      if (!isNaN(a) && !isNaN(t) && t < a) {
        newErrors.tahunLulus = 'Tahun lulus tidak dapat lebih awal dari tahun angkatan.'
      }
    }

    if (!isEdit) {
      if (!password.trim()) newErrors.password = 'Password wajib diisi.'
      if (!confirmPassword.trim()) newErrors.confirmPassword = 'Konfirmasi password wajib diisi.'
    } else {
      if (password.trim() && !confirmPassword.trim()) {
        newErrors.confirmPassword = 'Konfirmasi password wajib diisi.'
      }
    }

    if (/\s/.test(password)) {
      newErrors.password = 'Password tidak boleh mengandung spasi.'
    }
    if (/\s/.test(confirmPassword)) {
      newErrors.confirmPassword = 'Konfirmasi password tidak boleh mengandung spasi.'
    }

    if (password.trim() || confirmPassword.trim()) {
      if (password !== confirmPassword) {
        newErrors.confirmPassword = 'Konfirmasi password tidak sesuai dengan password yang Anda masukkan.'
      }
    }

    const birthYear = tanggalLahir ? new Date(tanggalLahir).getFullYear() : NaN

    for (const p of pekerjaan) {
      const job = p.pekerjaan || ''
      const company = p.perusahaan || ''
      
      if ((company.trim() || p.tahunMulai || p.bulanMulai) && !job.trim()) {
        newErrors.pekerjaan = 'Nama pekerjaan wajib diisi.'
        toast(newErrors.pekerjaan, 'error')
      }
      
      if (job.trim() || company.trim()) {
        const startYear = parseInt((p.tahunMulai || '').toString(), 10)
        if (!isNaN(startYear) && !isNaN(birthYear) && startYear < birthYear) {
          newErrors.pekerjaan = `Tahun mulai pekerjaan tidak valid (tidak dapat mendahului tahun lahir).`
          toast(newErrors.pekerjaan, 'error')
        }
      }
    }

    for (const p of prestasi) {
      const title = p.judul || ''
      const hasTahun = !!p.tahun
      
      if (title.trim() && !hasTahun) {
        newErrors.prestasi = 'Tahun prestasi wajib diisi jika judul diisi.'
        toast(newErrors.prestasi, 'error')
      }
      if (!title.trim() && hasTahun) {
        newErrors.prestasi = 'Judul prestasi wajib diisi jika tahun diisi.'
        toast(newErrors.prestasi, 'error')
      }
      
      if (title.trim()) {
        const year = parseInt((p.tahun || '').toString(), 10)
        if (!isNaN(year) && !isNaN(birthYear) && year < birthYear) {
          newErrors.prestasi = `Tahun pencapaian prestasi tidak valid (tidak dapat mendahului tahun lahir).`
          toast(newErrors.prestasi, 'error')
        }
        if (!p.buktiUrl) {
          newErrors.prestasi = `Dokumen bukti prestasi wajib diunggah untuk "${title}".`
          toast(newErrors.prestasi, 'error')
        }
      }
    }

    if (alumniGrafisKategori && alumniGrafisKategori !== 'None') {
      if (!alumniGrafisId) {
        newErrors.alumniGrafisId = `Pilihan data ${alumniGrafisKategori === 'Prestasi' ? 'prestasi' : 'pekerjaan'} wajib dipilih untuk Alumni Grafis.`
        toast(newErrors.alumniGrafisId, 'error')
      }
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors)

      let toastMessage = 'Terdapat formulir yang belum sesuai. Mohon periksa kembali isian Anda.'
      
      if (isStrictMode) {
        const strictMissingFields = []
        if (!foto) strictMissingFields.push('Foto Profil')
        if (!tanggalLahir) strictMissingFields.push('Tanggal Lahir')
        if (!linkedin.trim()) strictMissingFields.push('LinkedIn')
        if (!alamat.trim()) strictMissingFields.push('Alamat')
        if (!nomorIjazah.trim()) strictMissingFields.push('Nomor Ijazah')
        if (!tahunLulus.trim()) strictMissingFields.push('Tahun Lulus')
        if (!ipk.trim()) strictMissingFields.push('IPK')
        if (!ijazahFile) strictMissingFields.push('Ijazah')

        if (strictMissingFields.length > 0) {
          toastMessage = `Verifikasi Profil: Terdapat data wajib yang belum dilengkapi (${strictMissingFields.join(', ')}).`
        }
      }

      toast(toastMessage, 'error')
      setTimeout(() => {
        const firstErrorEl = document.querySelector('[data-error="true"]')
        if (firstErrorEl) {
          firstErrorEl.scrollIntoView({ behavior: 'smooth', block: 'center' })
        }
      }, 300)
      return
    }

    try {
      const payload: Record<string, any> = {
        nama,
        angkatan: parseInt(angkatan, 10),
        keanggotaan,
        tanggalLahir,
        motto,
        jenisKelamin,
        username: username.trim(),
        email,
        emailVisibility: emailVis,
        nomorHandphone: `${hpPrefix}${hp.trim()}`,
        nomorHandphoneVisibility: hpVis,
        linkedin: linkedin.trim() ? `https://www.linkedin.com/in/${linkedin.trim()}` : '',
        alamat,
        alamatVisibility: alamatVis,
        nomorIjazah,
        tahunLulus: tahunLulus.trim() ? parseInt(tahunLulus.trim(), 10) : null,
        ipk: ipk.trim() ? ipk.trim() : null,
        ijazahFile,
        pekerjaan: pekerjaan
          .filter(p => p.pekerjaan.trim() !== '' || p.perusahaan.trim() !== '')
          .map(p => ({
            ...p,
            tahunMulai: p.tahunMulai ? parseInt(p.tahunMulai.toString(), 10) : null,
            tahunSelesai: p.tahunSelesai ? parseInt(p.tahunSelesai.toString(), 10) : null
          })),
        prestasi: prestasi
          .filter(p => p.judul.trim() !== '' || p.tahun !== '')
          .map(p => ({
            ...p,
            tahun: p.tahun ? parseInt(p.tahun.toString(), 10) : null
          })),
        alumniGrafis: alumniGrafisKategori && alumniGrafisKategori !== 'None' && alumniGrafisId
          ? { kategori: alumniGrafisKategori, id: alumniGrafisId, status: alumniGrafisStatus || 'APPROVED' }
          : null,
        fotoUrl: foto,
        userAgreement,
      }

      if (password.trim() || confirmPassword.trim()) {
        payload.password = password
      }

      if (isEdit) {
        await api.put(`/admin/alumni/${id}`, payload)
      } else {
        await api.post('/admin/alumni', payload)
      }
      toast(`${isEdit ? 'Update' : 'Tambah'} alumni berhasil`, 'success')
      navigate('/admin/alumni')
    } catch (error: any) {
      const msg = error.response?.data?.error || error.response?.data?.message || 'Terjadi kendala saat menyimpan data. Silakan coba beberapa saat lagi.'
      toast(msg, 'error')
    }
  }

  const currentYear = new Date().getFullYear();
  const tahunOptions = Array.from({ length: 60 }, (_, i) => String(currentYear - i))

  const fileInputRef = useRef<HTMLInputElement>(null)
  const handleUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    const validExts = ['jpg', 'jpeg', 'png']
    const ext = file.name.split('.').pop()?.toLowerCase() || ''
    if (!validExts.includes(ext)) {
      toast('Format dokumen tidak didukung. Harap gunakan format JPG atau PNG.', 'error')
      if (e.target) e.target.value = ''
      return
    }


    if (file.size > 5 * 1024 * 1024) {
      toast('Foto >5MB akan otomatis dikompresi di bawah 5MB saat disimpan.', 'info')
    }

    const localUrl = URL.createObjectURL(file)
    startCrop({ id: 'avatar', url: localUrl, title: 'Potong Foto Profil', maxSizeMb: 5, maxDimension: 1080, imageType: file.type })
    if (e.target) e.target.value = ''
  }

  const handleAvatarCropComplete = async (cropFile: File) => {
    const url = await uploadCropped(cropFile, '/upload/avatar')
    if (url) {
      setFoto(url)
    } else {
      toast('Gagal mengunggah foto profil. Silakan coba kembali.', 'error')
    }
  }

  const isStrictMode = Boolean(
    pekerjaan.some(p => p.pekerjaan.trim() || p.perusahaan.trim()) ||
    prestasi.some(p => p.judul.trim()) ||
    (alumniGrafisKategori && alumniGrafisKategori !== 'None')
  );

  if (isLoading) return <div className="p-10">Loading...</div>

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Alumni', to: '/admin/alumni' },
          { label: isEdit ? 'Edit Alumni' : 'Tambah Alumni' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">
        {isEdit ? 'Edit Alumni' : 'Tambah Alumni'}
      </h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_300px] gap-6 items-start">
        <div className="space-y-6 min-w-0">
          <SectionCard title={<div className="flex items-center gap-1">Foto Profile {isStrictMode && !isEdit && <span className="text-danger">*</span>}</div> as any} hasError={!!errors.foto}>
            <div className="flex flex-col sm:flex-row items-start gap-6">
              <div className="h-[280px] w-[280px] rounded-md bg-gray-100 border border-gray-200 flex items-center justify-center overflow-hidden shrink-0">
                {foto ? (
                  <img src={getAvatarUrl(foto, nama || 'Alumni')} alt="Profile" className="h-full w-full object-cover" />
                ) : (
                  <ImagePlus className="h-10 w-10 text-gray-300" />
                )}
              </div>
              <div className="flex items-center gap-4 pt-2">
                <input
                  type="file"
                  ref={fileInputRef}
                  className="hidden"
                  accept=".jpg,.jpeg,.png"
                  onChange={handleUpload}
                />
                <div className="flex flex-col">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => fileInputRef.current?.click()}
                  >
                    Ganti Photo
                  </Button>
                  <p className="text-[10px] text-gray-500 mt-1">Maks. 5MB (Rekomendasi: 1200x1200px)</p>
                </div>
                <button
                  type="button"
                  onClick={() => setFoto(null)}
                  className="text-sm font-semibold text-gray-600 hover:text-danger"
                >
                  Hapus Photo
                </button>
              </div>
            </div>
            {errors.foto && <p className="mt-2 text-xs font-semibold text-danger">{errors.foto}</p>}
          </SectionCard>

          <SectionCard title="Data Alumni" hasError={!!(errors.nama || errors.angkatan || errors.keanggotaan || errors.tanggalLahir || errors.jenisKelamin)}>
            <div className="space-y-4">
              <div>
                <Label required>Nama Lengkap</Label>
                <Input
                  placeholder="Masukkan Nama Lengkap"
                  value={nama}
                  onChange={(e) => setNama(e.target.value)}
                  error={errors.nama}
                />
              </div>
              <div>
                <Label required>Angkatan</Label>
                <SearchableSelect
                  value={angkatan}
                  placeholder="Pilih Angkatan"
                  searchPlaceholder="Cari Tahun..."
                  numericOnly
                  onChange={(val) => setAngkatan(val)}
                  options={tahunOptions.map((y) => ({ value: y, label: y }))}
                  error={errors.angkatan}
                />
              </div>
              <div>
                <Label required>Keanggotaan</Label>
                <Select
                  value={keanggotaan}
                  onChange={(e) => setKeanggotaan(e.target.value as typeof keanggotaan)}
                  error={errors.keanggotaan}
                >
                  <option value="Alumni">Alumni</option>
                </Select>
              </div>
              <div>
                <Label required={isStrictMode}>Tanggal Lahir</Label>
                <Input
                  type="date"
                  value={tanggalLahir ?? ''}
                  max={(() => {
                    const yesterday = new Date(new Date().getTime() - 24 * 60 * 60 * 1000).toISOString().split('T')[0];
                    if (angkatan) {
                      const angkatanMax = `${angkatan}-12-31`;
                      return angkatanMax < yesterday ? angkatanMax : yesterday;
                    }
                    return yesterday;
                  })()}
                  onChange={(e) => setTanggalLahir(e.target.value)}
                  error={errors.tanggalLahir}
                />
              </div>
              <div>
                <Label>Motto</Label>
                <Input
                  placeholder="Masukkan Motto"
                  value={motto}
                  onChange={(e) => setMotto(e.target.value)}
                />
              </div>
              <div>
                <Label required>Jenis Kelamin</Label>
                <RadioGroup
                  name="jenisKelamin"
                  value={jenisKelamin}
                  onChange={(v) => setJenisKelamin(v)}
                  options={[
                    { value: 'Laki-laki', label: 'Laki-laki' },
                    { value: 'Perempuan', label: 'Perempuan' },
                  ]}
                />
                {errors.jenisKelamin && <p className="mt-1 text-xs text-danger">{errors.jenisKelamin}</p>}
              </div>
            </div>
          </SectionCard>

          <SectionCard title="Akun Login" hasError={!!(errors.username || errors.password || errors.confirmPassword)}>
            <div className="space-y-4">
              <div>
                <Label required>Username</Label>
                <Input
                  noSpaces
                  autoComplete="off"
                  placeholder="Masukkan Username"
                  value={username}
                  onKeyDown={(e) => { if (e.key === ' ') e.preventDefault(); }}
                  onChange={(e) => setUsername(e.target.value.replace(/\s/g, ''))}
                  disabled={isEdit}
                  className={isEdit ? "bg-gray-100 cursor-not-allowed" : ""}
                  error={errors.username}
                />
              </div>
              <div>
                <Label required={!isEdit}>
                  Password{' '}
                  {isEdit && (
                    <span className="text-gray-400 font-normal">
                      (Kosongkan jika tidak ingin diubah)
                    </span>
                  )}
                </Label>
                <Input
                  noSpaces
                  type="password"
                  autoComplete="new-password"
                  placeholder="Masukkan Password"
                  value={password}
                  onKeyDown={(e) => { if (e.key === ' ') e.preventDefault(); }}
                  onChange={(e) => setPassword(e.target.value.replace(/\s/g, ''))}
                  error={errors.password}
                />
              </div>
              <div>
                <Label required={!isEdit || password.trim().length > 0}>
                  Konfirmasi Password
                </Label>
                <Input
                  noSpaces
                  type="password"
                  autoComplete="new-password"
                  placeholder="Masukkan Konfirmasi Password"
                  value={confirmPassword}
                  onKeyDown={(e) => { if (e.key === ' ') e.preventDefault(); }}
                  onChange={(e) => setConfirmPassword(e.target.value.replace(/\s/g, ''))}
                  error={errors.confirmPassword}
                />
              </div>
            </div>
          </SectionCard>

          <SectionCard title="Kontak" hasError={!!(errors.email || errors.hp || errors.linkedin || errors.alamat)}>
            <div className="space-y-4">
              <div>
                <Label required>Email</Label>
                <Input
                  type="email"
                  noSpaces
                  placeholder="Masukkan Email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value.replace(/\s/g, ''))}
                  error={errors.email}
                />
                <VisibilityRadio
                  label="Visibilitas Email"
                  value={emailVis}
                  onChange={setEmailVis}
                />
              </div>
              <div>
                <Label required>Nomor Handphone</Label>
                <div className={`flex items-center rounded-md border focus-within:ring-2 ${errors.hp ? 'border-danger focus-within:ring-danger/30 focus-within:border-danger' : 'border-gray-300 focus-within:ring-primary/30 focus-within:border-primary'}`}>
                  <SearchableSelect
                    className="w-32 shrink-0"
                    buttonClassName="border-0 border-r border-gray-300 rounded-none rounded-l-md shadow-none focus:ring-0"
                    value={hpPrefix}
                    onChange={(val) => setHpPrefix(val)}
                    searchPlaceholder="Cari..."
                    options={countryCodes.map((c) => ({
                      value: c.code,
                      searchText: c.name + ' ' + c.code,
                      label: (
                        <div className="flex items-center gap-2">
                          <img 
                            src={`https://flagcdn.com/w20/${c.iso}.png`} 
                            alt={c.name} 
                            className="w-5 h-auto object-cover rounded-[2px]"
                            onError={(e) => {
                              // Fallback to emoji if image fails to load
                              (e.target as HTMLElement).style.display = 'none';
                              const parent = (e.target as HTMLElement).parentElement;
                              if (parent) {
                                const span = document.createElement('span');
                                span.textContent = c.flag;
                                parent.insertBefore(span, e.target as HTMLElement);
                              }
                            }}
                          />
                          <span>+{c.code}</span>
                        </div>
                      )
                    }))}
                  />
                  <input
                    className="flex-1 px-3 h-10 text-sm outline-none bg-white rounded-r-md"
                    placeholder="812..."
                    value={hp}
                    inputMode="numeric"
                    onChange={(e) => setHp(e.target.value.replace(/\D/g, ''))}
                  />
                </div>
                {errors.hp && <p className="mt-1 text-xs text-danger">{errors.hp}</p>}
                <div className="mt-2" />
                <VisibilityRadio
                  label="Visibilitas Nomor Handphone"
                  value={hpVis}
                  onChange={setHpVis}
                />
              </div>
              <div>
                <Label required={isStrictMode}>LinkedIn</Label>
                <div className={`flex items-center rounded-md border overflow-hidden focus-within:ring-2 focus-within:ring-primary focus-within:border-primary ${errors.linkedin ? 'border-danger ring-1 ring-danger' : 'border-gray-300'}`}>
                  <span className="px-3 py-2 bg-gray-100 text-gray-500 text-sm whitespace-nowrap border-r border-gray-300 select-none">
                    linkedin.com/in/
                  </span>
                  <input
                    className="flex-1 px-3 py-2 text-sm outline-none bg-white"
                    placeholder="username"
                    value={linkedin}
                    onChange={(e) => setLinkedin(e.target.value.replace(/[^a-zA-Z0-9_-]/g, ''))}
                  />
                </div>
                {errors.linkedin && <p className="text-xs text-danger mt-1">{errors.linkedin}</p>}
              </div>
              <div>
                <Label required={isStrictMode}>Alamat</Label>
                <Input
                  placeholder="Masukkan Alamat"
                  value={alamat}
                  maxLength={300}
                  onChange={(e) => setAlamat(e.target.value)}
                  error={errors.alamat}
                />
                <VisibilityRadio
                  label="Visibilitas Alamat"
                  value={alamatVis}
                  onChange={setAlamatVis}
                />
              </div>
            </div>
          </SectionCard>

          <SectionCard title="Ijazah / PDDIKTI / Surat Keterangan Jurusan" hasError={!!(errors.nomorIjazah || errors.tahunLulus || errors.ipk || errors.ijazahFile)}>
            <div className="space-y-4">
              <div>
                <Label required={isStrictMode}>Nomor Ijazah / PDDIKTI / Surat Keterangan Jurusan</Label>
                <Input
                  placeholder="Masukkan Nomor"
                  value={nomorIjazah}
                  onChange={(e) => setNomorIjazah(e.target.value)}
                  error={errors.nomorIjazah}
                />
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label required={isStrictMode}>Tahun Lulus</Label>
                  <SearchableSelect
                    value={tahunLulus}
                    placeholder="Pilih Tahun"
                    searchPlaceholder="Cari Tahun..."
                    onChange={(val) => setTahunLulus(val)}
                    error={errors.tahunLulus}
                    options={(() => {
                      const currentYear = new Date().getFullYear()
                      const startYear = angkatan ? parseInt(angkatan, 10) : currentYear - 30
                      const years = []
                      for (let y = currentYear; y >= startYear; y--) {
                        years.push(y.toString())
                      }
                      if (tahunLulus && !years.includes(tahunLulus)) {
                        years.push(tahunLulus)
                        years.sort((a, b) => b.localeCompare(a))
                      }
                      return years.map(y => ({ value: y, label: y }))
                    })()}
                  />
                </div>
                <div>
                  <Label required={isStrictMode}>IPK</Label>
                  <Input
                    placeholder="Contoh: 3.85"
                    value={ipk}
                    error={errors.ipk}
                    onChange={(e) => {
                      const val = e.target.value.replace(/[^0-9.]/g, '');
                      if (val === '' || val === '.') {
                        setIpk(val);
                        return;
                      }
                      const num = parseFloat(val);
                      if (!isNaN(num) && num > 4.00) {
                        return;
                      }
                      setIpk(val);
                    }}
                  />
                </div>
              </div>
              <div className="flex flex-col gap-2">
                <Label required={isStrictMode && !isEdit}>Upload Ijazah / PDDIKTI / Surat Keterangan Jurusan (PDF/Image)</Label>
                <div className="flex items-center gap-3">
                  <input
                    type="file"
                    id="ijazahFile"
                    className="hidden"
                    accept=".pdf,.jpg,.jpeg,.png"
                    onChange={async (e) => {
                      const file = e.target.files?.[0]
                      if (!file) return
                      if (file.size > 10 * 1024 * 1024) {
                        toast('Ukuran file maksimal 10MB', 'error')
                        e.target.value = ''
                        return
                      }

                      const validExts = ['pdf', 'jpg', 'jpeg', 'png']
                      const ext = file.name.split('.').pop()?.toLowerCase() || ''
                      if (!validExts.includes(ext)) {
                        toast('Format file tidak didukung', 'error')
                        e.target.value = ''
                        return
                      }

                      const formData = new FormData()
                      formData.append('file', file)
                      try {
                        const res = await api.post('/upload/document', formData, {
                          headers: { 'Content-Type': 'multipart/form-data' },
                        })
                        setIjazahFile(res.data.url)
                        toast('File berhasil diunggah', 'success')
                      } catch (err: any) {
                        toast('Gagal mengunggah file', 'error')
                      }
                      e.target.value = ''
                    }}
                  />
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => document.getElementById('ijazahFile')?.click()}
                  >
                    {ijazahFile ? 'Ganti File' : 'Upload File'}
                  </Button>
                  {ijazahFile && (
                    <div className="flex items-center gap-2 text-sm">
                      {typeof ijazahFile === 'string' && ijazahFile.match(/\.pdf$/i) ? (
                        <FileText className="h-4 w-4 text-primary" />
                      ) : (
                        <ImageIcon className="h-4 w-4 text-primary" />
                      )}
                      <a href={getFileUrl(ijazahFile)} target="_blank" rel="noreferrer" className="text-primary hover:underline truncate">
                        {formatFileName(ijazahFile)}
                      </a>
                    </div>
                  )}
                </div>
                {errors.ijazahFile && <p className="text-xs font-semibold text-danger mt-1">{errors.ijazahFile}</p>}
              </div>
            </div>
          </SectionCard>

          <SectionCard title="Pekerjaan" hasError={!!errors.pekerjaan}>
            <div className="space-y-4">
              {pekerjaan.map((p) => {
                const isGrafisLocked = p.isGrafis || (alumniGrafisId === p.id && (alumniGrafisKategori === 'Jabatan strategis/Public Figure' || alumniGrafisKategori === 'Public Figure'));
                return (
                <div
                  key={p.id}
                  className="rounded-md border border-gray-200 bg-gray-50/50 p-4 space-y-3"
                >
                  <div>
                    <Label>Pekerjaan</Label>
                    <Input
                      placeholder="Masukkan Pekerjaan"
                      disabled={isGrafisLocked}
                      value={p.pekerjaan}
                      onChange={(e) =>
                        updatePekerjaan(p.id, { pekerjaan: e.target.value })
                      }
                    />
                  </div>
                  <div>
                    <Label>Perusahaan</Label>
                    <Input
                      placeholder="Masukkan Perusahaan"
                      disabled={isGrafisLocked}
                      value={p.perusahaan}
                      onChange={(e) =>
                        updatePekerjaan(p.id, { perusahaan: e.target.value })
                      }
                    />
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <Label>Dari</Label>
                      <div className="grid grid-cols-2 gap-2">
                        <Select
                          disabled={isGrafisLocked}
                          value={p.bulanMulai}
                          onChange={(e) => {
                            const val = e.target.value
                            const patch: Partial<typeof p> = { bulanMulai: val }
                            if (p.tahunMulai && p.tahunSelesai && p.tahunMulai === p.tahunSelesai && p.bulanSelesai) {
                              if (BULAN.indexOf(p.bulanSelesai) < BULAN.indexOf(val)) {
                                patch.bulanSelesai = ''
                              }
                            }
                            updatePekerjaan(p.id, patch)
                          }}
                        >
                          <option value="">Bulan</option>
                          {BULAN.map((b) => (
                            <option key={b} value={b}>{b}</option>
                          ))}
                        </Select>
                        <SearchableSelect
                          disabled={isGrafisLocked}
                          value={p.tahunMulai}
                          placeholder="Tahun"
                          searchPlaceholder="Cari Tahun..."
                          numericOnly
                          onChange={(val) => {
                            const newTahun = val
                            const patch: Partial<typeof p> = { tahunMulai: newTahun }
                            if (p.tahunSelesai && newTahun && parseInt(p.tahunSelesai) < parseInt(newTahun)) {
                              patch.tahunSelesai = ''
                              patch.bulanSelesai = ''
                            } else if (p.tahunSelesai === newTahun && p.bulanMulai && p.bulanSelesai) {
                              if (BULAN.indexOf(p.bulanSelesai) < BULAN.indexOf(p.bulanMulai)) {
                                patch.bulanSelesai = ''
                              }
                            }
                            updatePekerjaan(p.id, patch)
                          }}
                          options={tahunOptions
                            .filter((y) => !tanggalLahir || parseInt(y, 10) >= new Date(tanggalLahir).getFullYear())
                            .map((y) => ({ value: y, label: y }))}
                        />
                      </div>
                    </div>
                    <div>
                      <Label>Sampai</Label>
                      <div className="grid grid-cols-2 gap-2">
                        <Select
                          disabled={isGrafisLocked || p.masihBekerja}
                          value={p.bulanSelesai}
                          onChange={(e) =>
                            updatePekerjaan(p.id, { bulanSelesai: e.target.value })
                          }
                        >
                          <option value="">Bulan</option>
                          {BULAN.map((b, i) => {
                            if (p.tahunMulai && p.tahunSelesai && p.tahunMulai === p.tahunSelesai && p.bulanMulai) {
                              if (i < BULAN.indexOf(p.bulanMulai)) return null
                            }
                            return <option key={b} value={b}>{b}</option>
                          })}
                        </Select>
                        <SearchableSelect
                          disabled={isGrafisLocked || p.masihBekerja}
                          value={p.tahunSelesai}
                          placeholder="Tahun"
                          searchPlaceholder="Cari Tahun..."
                          numericOnly
                          onChange={(val) => {
                            const newTahunS = val
                            const patch: Partial<typeof p> = { tahunSelesai: newTahunS }
                            if (newTahunS && p.tahunMulai && newTahunS === p.tahunMulai && p.bulanMulai && p.bulanSelesai) {
                              if (BULAN.indexOf(p.bulanSelesai) < BULAN.indexOf(p.bulanMulai)) {
                                patch.bulanSelesai = ''
                              }
                            }
                            updatePekerjaan(p.id, patch)
                          }}
                          options={tahunOptions
                            .filter((y) => {
                              const bYear = tanggalLahir ? new Date(tanggalLahir).getFullYear() : null
                              const validBirth = !bYear || parseInt(y, 10) >= bYear
                              const validStart = !p.tahunMulai || parseInt(y, 10) >= parseInt(p.tahunMulai, 10)
                              return validBirth && validStart
                            })
                            .map((y) => ({ value: y, label: y }))}
                        />
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center justify-between">
                    <Checkbox
                      label="Saya masih bekerja pada perusahaan ini"
                      checked={p.masihBekerja}
                      disabled={isGrafisLocked}
                      onChange={(e) =>
                        updatePekerjaan(p.id, { masihBekerja: e.target.checked })
                      }
                    />
                    <Button
                      variant="danger"
                      size="sm"
                      onClick={() =>
                        setPekerjaan((list) =>
                          list.length === 1
                            ? [emptyPekerjaan()]
                            : list.filter((x) => x.id !== p.id)
                        )
                      }
                      rightIcon={<Trash2 className="h-3.5 w-3.5" />}
                      disabled={isGrafisLocked}
                      title={isGrafisLocked ? "Terkunci: Data ini terdaftar sebagai Alumni Grafis" : undefined}
                    >
                      Hapus
                    </Button>
                  </div>
                  {isGrafisLocked && (
                    <div className="text-xs text-amber-600 font-medium italic mt-1">
                      Terkunci: Tidak bisa diedit karena sudah dimasukkan ke Alumni Grafis
                    </div>
                  )}
                </div>
              )})}
              <Button
                variant="outline"
                className="w-full"
                onClick={() => setPekerjaan((list) => [...list, emptyPekerjaan()])}
                leftIcon={<Plus className="h-4 w-4" />}
              >
                Tambah Pekerjaan
              </Button>
            </div>
          </SectionCard>

          <SectionCard title="Prestasi" hasError={!!errors.prestasi}>
            <div className="space-y-4">
              {prestasi.map((p) => {
                const isGrafisLocked = p.isGrafis || (alumniGrafisId === p.id && alumniGrafisKategori === 'Prestasi');
                return (
                <div
                  key={p.id}
                  className="rounded-md border border-gray-200 bg-gray-50/50 p-4 space-y-3"
                >
                  <div>
                    <Label>Judul Prestasi</Label>
                    <Input
                      placeholder="Masukkan Judul Prestasi"
                      disabled={isGrafisLocked}
                      value={p.judul}
                      onChange={(e) => updatePrestasi(p.id, { judul: e.target.value })}
                    />
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-[1fr_auto] gap-4 items-end">
                    <div>
                      <Label>Tahun</Label>
                      <SearchableSelect
                        disabled={isGrafisLocked}
                        value={p.tahun}
                        placeholder="Tahun"
                        searchPlaceholder="Cari Tahun..."
                        numericOnly
                        onChange={(val) => updatePrestasi(p.id, { tahun: val })}
                        options={tahunOptions
                          .filter((y) => !tanggalLahir || parseInt(y, 10) >= new Date(tanggalLahir).getFullYear())
                          .map((y) => ({ value: y, label: y }))}
                      />
                    </div>
                    <Button
                      variant="danger"
                      size="sm"
                      onClick={() =>
                        setPrestasi((list) =>
                          list.length === 1
                            ? [emptyPrestasi()]
                            : list.filter((x) => x.id !== p.id)
                        )
                      }
                      rightIcon={<Trash2 className="h-3.5 w-3.5" />}
                      disabled={isGrafisLocked}
                      title={isGrafisLocked ? "Terkunci: Data ini terdaftar sebagai Alumni Grafis" : undefined}
                    >
                      Hapus
                    </Button>
                  </div>
                  <div className="flex flex-col gap-2 mt-3">
                    <Label>Bukti Prestasi</Label>
                    <div className="flex items-center gap-3">
                      <input
                        type="file"
                        id={`bukti-${p.id}`}
                        disabled={isGrafisLocked}
                        className="hidden"
                        accept=".pdf,.jpg,.jpeg,.png"
                        onChange={async (e) => {
                          const file = e.target.files?.[0]
                          if (!file) return
                          if (file.size > 10 * 1024 * 1024) {
                            toast('Ukuran file maksimal 10MB', 'error')
                            e.target.value = ''
                            return
                          }

                          const validExts = ['pdf', 'jpg', 'jpeg', 'png']
                          const ext = file.name.split('.').pop()?.toLowerCase() || ''
                          if (!validExts.includes(ext)) {
                            toast('Format file tidak didukung', 'error')
                            e.target.value = ''
                            return
                          }

                          const formData = new FormData()
                          formData.append('file', file)
                          try {
                            const res = await api.post('/upload/document', formData, {
                              headers: { 'Content-Type': 'multipart/form-data' },
                            })
                            updatePrestasi(p.id, { buktiUrl: res.data.url })
                            toast('Bukti berhasil diunggah', 'success')
                          } catch (err: any) {
                            toast(getFriendlyErrorMessage(err, 'Gagal mengunggah bukti'), 'error')
                          }
                          e.target.value = ''
                        }}
                      />
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        disabled={isGrafisLocked}
                        onClick={() => document.getElementById(`bukti-${p.id}`)?.click()}
                      >
                        {p.buktiUrl ? 'Ganti File' : 'Upload File'}
                      </Button>
                      {p.buktiUrl && (
                        <div className="mt-2 flex items-center gap-2 text-sm">
                          {typeof p.buktiUrl === 'string' && p.buktiUrl.match(/\.pdf$/i) ? (
                            <FileText className="h-4 w-4 text-primary" />
                          ) : (
                            <ImageIcon className="h-4 w-4 text-primary" />
                          )}
                          <a href={getFileUrl(p.buktiUrl)} target="_blank" rel="noreferrer" className="text-primary hover:underline truncate">
                            {formatFileName(p.buktiUrl)}
                          </a>
                        </div>
                      )}
                    </div>
                  </div>
                  {isGrafisLocked && (
                    <div className="text-xs text-amber-600 font-medium italic mt-1">
                      Terkunci: Tidak bisa diedit karena sudah dimasukkan ke Alumni Grafis
                    </div>
                  )}
                </div>
              )})}
              <Button
                variant="outline"
                className="w-full"
                onClick={() => setPrestasi((list) => [...list, emptyPrestasi()])}
                leftIcon={<Plus className="h-4 w-4" />}
              >
                Tambah Prestasi
              </Button>
            </div>
          </SectionCard>

          <SectionCard title="Alumni Grafis" hasError={!!(errors.alumniGrafisId || errors.alumniGrafisKategori)}>
            <div className="space-y-4">
              <div>
                <Label>Apakah Anda memiliki prestasi di tingkat nasional atau lebih tinggi, menduduki jabatan minimal manajer, atau berstatus sebagai tokoh publik?</Label>
                <Select
                  value={alumniGrafisKategori}
                  disabled={alumniGrafisStatus === 'APPROVED'}
                  onChange={(e) => {
                    setAlumniGrafisKategori(e.target.value as any)
                    setAlumniGrafisId('')
                  }}
                >
                  <option value="" disabled hidden>Pilih Kategori</option>
                  <option value="Jabatan strategis/Public Figure">Jabatan strategis/Public Figure</option>
                  <option value="Prestasi">Berprestasi</option>
                  <option value="None">None</option>
                </Select>
              </div>

              {(alumniGrafisKategori === 'Jabatan strategis/Public Figure' || alumniGrafisKategori === 'Public Figure') && (
                <div>
                  <Label>Pilih Pekerjaan</Label>
                  <Select
                    value={alumniGrafisId}
                    disabled={alumniGrafisStatus === 'APPROVED'}
                    onChange={(e) => setAlumniGrafisId(e.target.value)}
                  >
                    <option value="" disabled hidden>Pilih Pekerjaan</option>
                    {pekerjaan.filter(p => p.pekerjaan.trim() || p.perusahaan.trim()).map(p => (
                      <option key={p.id} value={p.id}>
                        {p.pekerjaan} {p.perusahaan ? `di ${p.perusahaan}` : ''}
                      </option>
                    ))}
                  </Select>
                </div>
              )}

              {alumniGrafisKategori === 'Prestasi' && (
                <div>
                  <Label>Pilih Prestasi</Label>
                  <Select
                    value={alumniGrafisId}
                    disabled={alumniGrafisStatus === 'APPROVED'}
                    onChange={(e) => setAlumniGrafisId(e.target.value)}
                  >
                    <option value="" disabled hidden>Pilih Prestasi</option>
                    {prestasi.filter(p => p.judul.trim()).map(p => (
                      <option key={p.id} value={p.id}>
                        {p.judul} {p.tahun ? `(${p.tahun})` : ''}
                      </option>
                    ))}
                  </Select>
                </div>
              )}
            </div>
          </SectionCard>
        </div>

        <aside className="lg:sticky lg:top-8 space-y-6">
          <SectionCard title="Action">
            <Button onClick={handleSubmit} className="w-full" size="lg">
              {isEdit ? 'Simpan Perubahan' : 'Tambah Alumni'}
            </Button>
            <button
              type="button"
              onClick={() => navigate('/admin/alumni')}
              className="mt-3 w-full text-sm text-gray-500 hover:text-gray-800"
            >
              Batal
            </button>
          </SectionCard>
        </aside>
      </div>
      {cropTarget && (
        <ImageCropModal
          open={cropModalOpen}
          imageUrl={cropTarget.url}
          title={cropTarget.title}
          aspectRatio={1}
          aspectRatioLabel="Foto Profil (1 : 1)"
          imageType={cropTarget?.imageType}
          onClose={closeCrop}
          onCropComplete={handleAvatarCropComplete}
        />
      )}
      {cropLoadingOverlay}
    </div>
  )
}

