import { useEffect, useRef, useState } from 'react'
import api from '@/lib/api'
import {
  Globe, Settings as SettingsIcon, Image as ImageIcon, MessageSquare, HelpCircle,
  Upload, Plus, Trash2, Save, ScrollText, CheckCircle2, AlertCircle,
} from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Input, Label } from '@/components/ui/Input'
import { RichTextEditor } from '@/components/ui/RichTextEditor'
import { Button } from '@/components/ui/Button'
import { Checkbox } from '@/components/ui/Checkbox'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { toast } from '@/components/ui/Toast'
import { useAuthStore } from '@/stores/authStore'
import { cn, getAvatarUrl, getFileUrl } from '@/lib/utils'
import { compressImage } from '@/utils/imageCompressor'
import { ImageCropModal } from '@/components/ui/ImageCropModal'
import defaultLogoUrl from '/logo.png'

interface HeroSlide {
  id: string
  judul: string
  badge: string
  newsTitle: string
  excerpt: string
  imageUrl: string
  imageFile?: File | null
  imageName?: string
  bgImageX?: number
  bgImageY?: number
  showOverlay?: boolean
  overlayColor?: string
  overlayOpacity?: number
}

interface OrganizationItem {
  id: string
  nama: string
  jabatan: string
  batch: string
  imageUrl: string
  imageName?: string
}

interface FaqItem {
  id: string
  pertanyaan: string
  jawaban: string
}

interface Feature {
  id: string
  icon: string
  title: string
  desc: string
}

function uid() {
  return Math.random().toString(36).slice(2, 10)
}

const ICONS = ['network', 'briefcase', 'calendar', 'photo', 'star', 'heart']

export function PortalSettingsPage() {
  const user = useAuthStore((s) => s.user)
  const canEdit = user?.permissions?.includes('settings_edit') ?? false
  const [tab, setTab] = useState<'general' | 'hero' | 'about' | 'organisasi' | 'features' | 'faq' | 'kontak' | 'terms'>('general')
  const [confirmSave, setConfirmSave] = useState(false)

  // General
  const [siteName, setSiteName] = useState('IKA JTK POLBAN')
  const [tagline, setTagline] = useState('Portal Alumni Teknik Komputer dan Informatika POLBAN')
  const [logoUrl, setLogoUrl] = useState('')
  const [maintenanceMode, setMaintenanceMode] = useState(false)
  const [allowPublicRegistration, setAllowPublicRegistration] = useState(true)

  // Hero slides
  const [slides, setSlides] = useState<HeroSlide[]>([
    {
      id: 's1',
      judul: 'REUNI AKBAR 2024',
      badge: 'BERITA',
      newsTitle: 'Agenda Reuni Akbar 2025 Segera Hadir!',
      excerpt: 'Jangan lewatkan momen reuni akbar tahun ini. Catat tanggalnya dan ajak teman-teman alumni lainnya.',
      imageUrl: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=1600&q=80',
    },
    {
      id: 's2',
      judul: 'GATHERING ALUMNI',
      badge: 'EVENT',
      newsTitle: 'Networking Bersama Alumni Senior',
      excerpt: 'Manfaatkan kesempatan langka untuk berdiskusi dengan para senior alumni.',
      imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1600&q=80',
    },
  ])

  // About
  const [aboutTitle, setAboutTitle] = useState('Apa itu IKA JTK?')
  const [aboutLabel, setAboutLabel] = useState('Definisi IKA JTK')
  const [aboutBgColor, setAboutBgColor] = useState('#FFF1E5')
  const [aboutText, setAboutText] = useState(
    'IKA JTK Polban adalah ikatan para alumni lulusan dari jurusan Teknik Komputer dan Informatika Politeknik Negeri Bandung...',
  )

  // Banner "Tentang"
  const [bannerImageUrl, setBannerImageUrl] = useState('')
  const [bannerImageName, setBannerImageName] = useState('')
  const [bannerTagline, setBannerTagline] = useState('Bersama, Berdampak.')
  const [bannerHeaderLine1, setBannerHeaderLine1] = useState('JURUSAN TEKNIK KOMPUTER DAN INFORMATIKA')
  const [bannerHeaderLine2, setBannerHeaderLine2] = useState('POLITEKNIK NEGERI BANDUNG')
  const [logoWidth, setLogoWidth] = useState(48)
  const [logoHeight, setLogoHeight] = useState(48)
  const [logoX, setLogoX] = useState(80)
  const [logoY, setLogoY] = useState(5)
  const [bgImageX, setBgImageX] = useState(50)
  const [bgImageY, setBgImageY] = useState(50)
  const [taglineX, setTaglineX] = useState(5)
  const [taglineY, setTaglineY] = useState(85)
  const [showOverlay, setShowOverlay] = useState(true)
  const [overlayColor, setOverlayColor] = useState('#1E2A4D')
  const [overlayOpacity, setOverlayOpacity] = useState(80)
  const bannerRef = useRef<HTMLDivElement>(null)
  const aboutBannerRef = useRef<Record<string, any>>({})
  const bannerImageUrlRef = useRef('')
  const [saveStatus, setSaveStatus] = useState<{ type: 'success' | 'error' | 'loading' | null; message: string }>({ type: null, message: '' })

  // Organization
  const [organization, setOrganization] = useState<OrganizationItem[]>([])
  const [verifiedAlumni, setVerifiedAlumni] = useState<any[]>([])
  const [showAddOrgModal, setShowAddOrgModal] = useState(false)
  const [selectedAlumniId, setSelectedAlumniId] = useState('')
  const [selectedJabatan, setSelectedJabatan] = useState('Anggota')
  const [alumniSearchQuery, setAlumniSearchQuery] = useState('')

  // Cropper state
  const [cropModalOpen, setCropModalOpen] = useState(false)
  const [cropTarget, setCropTarget] = useState<{ id: string; url: string; title?: string; fileType?: string; imageType?: string } | null>(null)
  const [uploadingText, setUploadingText] = useState<string>('')

  // Features
  const [features, setFeatures] = useState<Feature[]>([
    { id: 'f1', icon: 'network', title: 'Jejaring Alumni', desc: 'Bangun koneksi profesional lintas angkatan.' },
    { id: 'f2', icon: 'briefcase', title: 'Lowongan Kerja', desc: 'Temukan peluang karier yang dibagikan alumni.' },
    { id: 'f3', icon: 'calendar', title: 'Agenda Alumni', desc: 'Ikuti kegiatan alumni dan reuni.' },
    { id: 'f4', icon: 'photo', title: 'Galeri & Cerita', desc: 'Momen bersama melalui foto dan testimoni alumni.' },
  ])

  // FAQ
  const [faqs, setFaqs] = useState<FaqItem[]>([
    { id: 'q1', pertanyaan: 'Bagaimana cara mendaftar akun?', jawaban: 'Silakan klik menu Daftar, isi formulir, dan tunggu verifikasi admin.' },
    { id: 'q2', pertanyaan: 'Apa itu Sistem Informasi Alumni?', jawaban: 'Sistem dokumentasi alumni IKA JTK POLBAN.' },
  ])

  // Kontak
  const [instagram, setInstagram] = useState('@ikajtk.id')
  const [email, setEmail] = useState('pengurus@ikajtk.id')
  const [whatsapp, setWhatsapp] = useState('+62 812 3456 7890')
  const [alamat, setAlamat] = useState('Politeknik Negeri Bandung, Jl. Gegerkalong Hilir, Bandung')

  // User Agreement (Terms & Conditions)
  const [termsTitle, setTermsTitle] = useState('User Agreement (Syarat & Ketentuan Pengguna)')
  const [termsSubtitle, setTermsSubtitle] = useState('Perjanjian hukum, ketentuan keanggotaan, dan aturan penggunaan layanan Portal IKA JTK POLBAN.')
  const [termsLastUpdated, setTermsLastUpdated] = useState('')
  const [termsIntro, setTermsIntro] = useState('')
  const [termsContent, setTermsContent] = useState('<p><strong>Tanggal Terakhir Diperbarui: 16 Juli 2026</strong></p><p>Selamat datang di Portal Resmi Ikatan Alumni Teknik Komputer Politeknik Negeri Bandung (IKA JTK POLBAN). Dokumen Syarat dan Ketentuan Pengguna ("Perjanjian") ini mengatur hak, kewajiban, dan batasan hukum antara Anda sebagai pengguna dengan organisasi IKA JTK POLBAN. Dengan mendaftar, mengakses, atau menggunakan layanan pada portal ini, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh isi ketentuan di bawah ini.</p><hr/><h3>1. Kualifikasi dan Verifikasi Keanggotaan</h3><p>Portal ini disediakan khusus untuk melayani jejaring komunikasi dan profesional civitas akademika serta alumni Jurusan Teknik Komputer POLBAN:</p><ul><li>Pendaftaran akun wajib menggunakan identitas asli yang akurat, termasuk Nama Lengkap, Tahun Angkatan, dan Nomor Alumni / bukti kelulusan yang sah.</li><li>Setiap pendaftaran akun baru akan melalui proses verifikasi dan validasi oleh tim Admin / Pengurus IKA JTK POLBAN sebelum status akun diaktifkan secara penuh.</li><li>Tindakan memalsukan identitas akademik, memanipulasi data kelulusan, atau mengatasnamakan alumni lain merupakan pelanggaran hukum berat yang berakibat pada pembatalan akun permanen, pelaporan kepada almamater, serta tindakan hukum sesuai undang-undang yang berlaku.</li></ul><h3>2. Keamanan Akun dan Tanggung Jawab Pengguna</h3><ul><li><strong>Kerahasiaan Kredensial:</strong> Anda bertanggung jawab penuh untuk menjaga kerahasiaan username, kata sandi, serta token akses akun Anda.</li><li><strong>Aktivitas Akun:</strong> Segala bentuk aktivitas, transaksi, dan publikasi konten yang dilakukan melalui akun Anda sepenuhnya menjadi tanggung jawab Anda pribadi.</li><li><strong>Larangan Berbagi Akun:</strong> Akun alumni bersifat personal dan tidak dapat dialihkan, dipinjamkan, atau diperjualbelikan kepada pihak lain dalam kondisi apa pun.</li><li><strong>Pelaporan Insiden:</strong> Jika Anda mengetahui atau mencurigai adanya akses ilegal atau kebocoran kredensial pada akun Anda, Anda wajib segera melaporkannya kepada Pengurus IKA JTK.</li></ul><h3>3. Aturan Penggunaan Layanan (Acceptable Use Policy)</h3><p>Dalam berinteraksi dan memanfaatkan fitur Portal IKA JTK (seperti Direktori Alumni, Lowongan Kerja, Berita, dan Pemilu), setiap pengguna dilarang keras untuk:</p><ul><li>Mengunggah atau menyebarkan informasi palsu (hoaks), penipuan lowongan kerja fiktif, ujaran kebencian, pelecehan, rasisme, pornografi, atau konten yang menyinggung SARA.</li><li>Melakukan aktivitas yang merusak marwah, martabat, dan nama baik organisasi IKA JTK maupun almamater Politeknik Negeri Bandung.</li><li>Melakukan pengumpulan data massal (data scraping/crawling) terhadap direktori alumni atau kontak pribadi anggota tanpa izin tertulis dari Pengurus Pusat IKA JTK POLBAN.</li><li>Melakukan serangan siber, penyebaran virus/malware, atau manipulasi sistem pemungutan suara elektronik (E-Voting/Pemilu Alumni).</li></ul><h3>4. Hak Kekayaan Intelektual dan Lisensi Konten</h3><p>Seluruh hak cipta atas arsitektur sistem, desain grafis, logo organisasi, dan basis data Portal IKA JTK adalah milik sah IKA JTK POLBAN. Terkait konten yang Anda kirimkan (berita, testimoni, lowongan kerja):</p><ul><li><strong>Kepemilikan Konten:</strong> Anda tetap menjadi pemilik hak cipta atas materi/konten yang Anda tulis atau publikasikan di portal ini.</li><li><strong>Lisensi Penayangan:</strong> Dengan mengunggah konten ke dalam portal, Anda memberikan hak non-eksklusif, bebas royalti, dan dapat dialihkan kepada IKA JTK POLBAN untuk menayangkan, mendistribusikan, dan mempromosikan konten tersebut demi kemajuan komunitas alumni.</li><li><strong>Tanggung Jawab Hukum:</strong> Anda menjamin bahwa konten yang Anda unggah tidak melanggar hak cipta pihak ketiga mana pun dan membebaskan IKA JTK dari segala tuntutan hukum yang timbul dari konten Anda.</li></ul><h3>5. Batasan Tanggung Jawab (Limitation of Liability)</h3><p>Layanan portal ini disediakan sebagaimana adanya ("as is" dan "as available"). IKA JTK POLBAN berupaya maksimal menjaga keandalan dan keamanan portal, namun tidak memberikan jaminan bahwa layanan akan selalu bebas dari gangguan teknis, keterlambatan, atau pemeliharaan sistem. IKA JTK POLBAN juga tidak bertanggung jawab atas kerugian material maupun immaterial yang timbul akibat interaksi, kesepakatan karir/bisnis, atau transaksi langsung antar alumni yang dilakukan di luar platform portal.</p><h3>6. Sanksi, Pembatasan, dan Penghentian Layanan</h3><p>Pengurus dan Admin IKA JTK POLBAN memiliki hak prerogatif untuk memberikan peringatan tertulis, membatasi hak akses fitur (suspend), atau menonaktifkan akun secara permanen apabila pengguna terbukti melanggar Syarat dan Ketentuan Pengguna ini, melanggar Kode Etik Komunitas, atau merugikan kepentingan organisasi.</p><h3>7. Perubahan Ketentuan dan Hukum yang Berlaku</h3><p>IKA JTK POLBAN berhak untuk memperbarui atau mengubah Syarat dan Ketentuan Pengguna ini sewaktu-waktu agar selaras dengan perkembangan organisasi dan regulasi yang berlaku. Perubahan akan diinformasikan melalui portal. Perjanjian ini tunduk dan ditafsirkan berdasarkan Hukum Republik Indonesia. Segala sengketa yang timbul akan diselesaikan terlebih dahulu secara musyawarah dan kekeluargaan di bawah mediasi Pengurus Pusat IKA JTK POLBAN.</p>')

  useEffect(() => {
    fetchConfig()
  }, [])

  const fetchConfig = async () => {
    try {
      const [data, alumniList] = await Promise.all([
        api.getPortalConfig().catch(() => ({})),
        api.getAlumni(true).catch(() => []),
      ])
      if (Array.isArray(alumniList)) {
        const onlyActive = alumniList.filter((al: any) => {
          const st = (al.status || '').toUpperCase()
          return st === 'ACTIVE' || st === 'APPROVED'
        })
        setVerifiedAlumni(onlyActive)
      }
      setSiteName(data.site_name || 'IKA JTK POLBAN')
      setTagline(data.tagline || '')
      setLogoUrl(data.logo_url || '')
      setMaintenanceMode(data.maintenance_mode || false)
      setAllowPublicRegistration(data.allow_public_registration !== false)
      if (data.hero_slides) setSlides(data.hero_slides)
      if (data.about) {
        setAboutTitle(data.about.title || 'Apa itu IKA JTK?')
        setAboutText(data.about.content || '')
        setAboutLabel(data.about.label || 'Definisi IKA JTK')
        setAboutBgColor(data.about.bgColor || '#FFF1E5')
      }
      if (data.about_banner) {
        const imgUrl = data.about_banner.imageUrl || ''
        setBannerImageUrl(imgUrl)
        bannerImageUrlRef.current = imgUrl
        setBannerImageName(data.about_banner.imageName || '')
        setBannerTagline(data.about_banner.tagline || 'Bersama, Berdampak.')
        setBannerHeaderLine1(data.about_banner.headerLine1 || 'JURUSAN TEKNIK KOMPUTER DAN INFORMATIKA')
        setBannerHeaderLine2(data.about_banner.headerLine2 || 'POLITEKNIK NEGERI BANDUNG')
        setLogoWidth(data.about_banner.logoWidth ?? 48)
        setLogoHeight(data.about_banner.logoHeight ?? 48)
        const posMapX: Record<string, number> = { 'top-right': 80, 'top-left': 5, 'bottom-right': 80, 'bottom-left': 5 }
        const posMapY: Record<string, number> = { 'top-right': 5, 'top-left': 5, 'bottom-right': 75, 'bottom-left': 75 }
        const oldPos = data.about_banner.logoPosition
        setLogoX(data.about_banner.logoX ?? (oldPos ? posMapX[oldPos] : 80))
        setLogoY(data.about_banner.logoY ?? (oldPos ? posMapY[oldPos] : 5))
        setBgImageX(data.about_banner.bgImageX ?? 50)
        setBgImageY(data.about_banner.bgImageY ?? 50)
        setTaglineX(data.about_banner.taglineX ?? 5)
        setTaglineY(data.about_banner.taglineY ?? 85)
        setShowOverlay(data.about_banner.showOverlay ?? true)
        setOverlayColor(data.about_banner.overlayColor || '#1E2A4D')
        setOverlayOpacity(data.about_banner.overlayOpacity ?? 80)
      }
      if (data.features) setFeatures(data.features)
      if (data.faqs) setFaqs(data.faqs)
      if (data.organization) setOrganization(data.organization)
      if (data.contacts) {
        setInstagram(data.contacts.instagram || '')
        setEmail(data.contacts.email || '')
        setWhatsapp(data.contacts.whatsapp || '')
        setAlamat(data.contacts.alamat || '')
      }
      if (data.terms_conditions) {
        setTermsTitle(data.terms_conditions.title || 'User Agreement (Syarat & Ketentuan Pengguna)')
        setTermsSubtitle(data.terms_conditions.subtitle || 'Perjanjian hukum, ketentuan keanggotaan, dan aturan penggunaan layanan Portal IKA JTK POLBAN.')
        let loadedContent = data.terms_conditions.content || ''
        const loadedLastUpdated = data.terms_conditions.last_updated || ''
        const loadedIntro = data.terms_conditions.intro || ''
        if (loadedContent && (loadedLastUpdated || loadedIntro) && !loadedContent.includes(loadedLastUpdated) && !loadedContent.includes('Terakhir Diperbarui')) {
          loadedContent = `${loadedLastUpdated ? `<p><strong>Tanggal Terakhir Diperbarui: ${loadedLastUpdated}</strong></p>` : ''}${loadedIntro ? `<p>${loadedIntro}</p><hr/>` : ''}${loadedContent}`
        } else if (!loadedContent) {
          loadedContent = `${loadedLastUpdated ? `<p><strong>Tanggal Terakhir Diperbarui: ${loadedLastUpdated}</strong></p>` : ''}${loadedIntro ? `<p>${loadedIntro}</p><hr/>` : ''}`
        }
        setTermsContent(loadedContent)
        setTermsLastUpdated('')
        setTermsIntro('')
      }
    } catch (err) {
      // Use defaults
    }
  }

  const saveOrganizationToDb = async (newOrgList: OrganizationItem[]) => {
    setOrganization(newOrgList)
    setSaveStatus({ type: 'loading', message: 'Sedang memperbarui struktur organisasi ke server...' })
    try {
      const current = await api.getPortalConfig().catch(() => ({}))
      const payload: Record<string, any> = {
        ...current,
        site_name: siteName,
        tagline,
        maintenance_mode: maintenanceMode,
        allow_public_registration: allowPublicRegistration,
        hero_slides: slides,
        about: { title: aboutTitle, content: aboutText, label: aboutLabel, bgColor: aboutBgColor },
        about_banner: { imageUrl: bannerImageUrl, imageName: bannerImageName, tagline: bannerTagline, headerLine1: bannerHeaderLine1, headerLine2: bannerHeaderLine2, logoUrl: '', logoName: '', logoWidth, logoHeight, logoX, logoY, bgImageX, bgImageY, taglineX, taglineY, showOverlay, overlayColor, overlayOpacity },
        organization: newOrgList,
        features,
        faqs,
        contacts: { instagram, email, whatsapp, alamat },
        terms_conditions: { title: termsTitle, subtitle: termsSubtitle, last_updated: termsLastUpdated, intro: termsIntro, content: termsContent },
      }
      await api.updatePortalConfig(payload)
      window.dispatchEvent(new Event('portal-config-updated'))
      const timeStr = new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
      setSaveStatus({ type: 'success', message: `Struktur organisasi berhasil diperbarui di database pada ${timeStr} WIB` })
      toast('Struktur organisasi berhasil diperbarui di database', 'success')
    } catch (err: any) {
      const detail = err?.response?.data?.detail || err?.response?.data?.error || err?.response?.data?.message || err?.message || 'Terjadi kesalahan sistem yang tidak diketahui'
      setSaveStatus({ type: 'error', message: `Gagal memperbarui ke database: ${detail}` })
      toast(`Gagal memperbarui ke database: ${detail}`, 'error')
    }
  }

  const handleAddFromAlumni = () => {
    if (!selectedAlumniId) {
      toast('Pilih alumni terlebih dahulu', 'error')
      return
    }
    const al = verifiedAlumni.find((a) => a.id === selectedAlumniId)
    if (!al) return
    const rawBatch = al.angkatan ? al.angkatan.toString() : ''
    const formattedBatch = rawBatch
      ? (rawBatch.length === 4 ? `JTK${rawBatch.slice(-2)}` : rawBatch)
      : ''
    const newItem: OrganizationItem = {
      id: uid(),
      nama: al.nama || 'Alumni',
      jabatan: selectedJabatan || 'Anggota',
      batch: formattedBatch,
      imageUrl: al.avatarUrl || al.fotoProfil || '',
    }
    saveOrganizationToDb([...organization, newItem])
    setShowAddOrgModal(false)
    setSelectedAlumniId('')
    setSelectedJabatan('Anggota')
  }

  const checkSize = (file: File, e?: React.ChangeEvent<HTMLInputElement>) => {
    const validExts = ['jpg', 'jpeg', 'png', 'svg']
    const ext = file.name.split('.').pop()?.toLowerCase() || ''
    if (!validExts.includes(ext)) {
      toast('Format file tidak didukung. Gunakan JPG, PNG, atau SVG.', 'error')
      if (e) e.target.value = ''
      return false
    }
    return true
  }

  const slideFileRefs = useRef<Record<string, HTMLInputElement | null>>({})
  const handlePickSlideImage = (id: string) => slideFileRefs.current[id]?.click()
  const handleSlideImageChange = async (id: string, e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (!f) return
    if (!checkSize(f, e)) return
    
    // Langsung buka modal potong gambar (default dimensi 36:13) saat file dipilih
    if (f) {
      const localUrl = URL.createObjectURL(f)
      const slideIndex = slides.findIndex((x) => x.id === id)
      const slideNumber = slideIndex >= 0 ? slideIndex + 1 : 1
      setCropTarget({
        id,
        url: localUrl,
        title: `Potong Gambar: Slide ${slideNumber}`,
        imageType: f.type,
      })
      setCropModalOpen(true)
    }
    if (e.target) e.target.value = ''
  }

  const orgFileRefs = useRef<Record<string, HTMLInputElement | null>>({})
  const handlePickOrgImage = (id: string) => orgFileRefs.current[id]?.click()
  const handleOrgImageChange = async (id: string, e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (!f) return
    if (!checkSize(f, e)) return
    const localUrl = URL.createObjectURL(f)
    setCropTarget({ id: `org_${id}`, url: localUrl, title: 'Potong Foto Pengurus', imageType: f.type })
    setCropModalOpen(true)
    if (e.target) e.target.value = ''
  }

  const bannerImageFileRef = useRef<HTMLInputElement | null>(null)
  const handlePickBannerImage = () => bannerImageFileRef.current?.click()
  const handleBannerImageChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (!f) return
    if (!checkSize(f, e)) return
    
    // Langsung buka modal potong gambar (default dimensi 16:6) saat file dipilih
    if (f) {
      const localUrl = URL.createObjectURL(f)
      setCropTarget({
        id: 'banner',
        url: localUrl,
        title: 'Potong Gambar: Banner Tentang',
        imageType: f.type,
      })
      setCropModalOpen(true)
    }
    if (e.target) e.target.value = ''
  }

  const logoFileRef = useRef<HTMLInputElement | null>(null)
  const handlePickLogo = () => logoFileRef.current?.click()
  const handleLogoChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (!f) return
    if (!checkSize(f, e)) return
    const localUrl = URL.createObjectURL(f)
    setCropTarget({ id: 'logo', url: localUrl, title: 'Potong Logo Portal', imageType: f.type })
    setCropModalOpen(true)
    if (e.target) e.target.value = ''
  }

  const slidesRef = useRef<HeroSlide[]>(slides)
  useEffect(() => {
    slidesRef.current = slides
  }, [slides])

  const autoSaveSlides = async (newSlides?: HeroSlide[]) => {
    try {
      await api.updatePortalConfig({ hero_slides: newSlides || slidesRef.current })
    } catch (_) {}
  }

  const handleCroppedUpload = async (file: File) => {
    if (!cropTarget) return
    if (!checkSize(file)) return
    
    let finalFile = file
    const isOrg = cropTarget.id.startsWith('org_')
    const maxSizeMb = isOrg ? 5 : 10
    const maxDim = isOrg ? 1080 : 1920

    if (file.size > maxSizeMb * 1024 * 1024) {
      setUploadingText('Mengompresi gambar...')
      try {
        finalFile = await compressImage(file, maxSizeMb, maxDim)
      } catch (err: any) {
        toast(err.message || 'Gagal mengompresi gambar', 'error')
        setUploadingText('')
        return
      }
    }

    const formData = new FormData()
    formData.append('file', finalFile)
    setUploadingText('Mengunggah gambar hasil potong...')
    try {
      toast('Mengunggah gambar hasil potong...', 'success')
      const endpoint = cropTarget.id.startsWith('org_') ? '/upload/avatar' : '/upload'
      const res = await api.post(endpoint, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      if (res.data?.url) {
        if (cropTarget.id === 'banner') {
          bannerImageUrlRef.current = res.data.url
          setBannerImageUrl(res.data.url)
          setBannerImageName(file.name)
          aboutBannerRef.current.imageUrl = res.data.url
          toast('Gambar banner berhasil dipotong (klik Simpan Perubahan untuk menerapkan)', 'success')
        } else if (cropTarget.id === 'logo') {
          setLogoUrl(res.data.url)
          toast('Logo portal berhasil dipotong (klik Simpan Perubahan untuk menerapkan)', 'success')
        } else if (cropTarget.id.startsWith('org_')) {
          const orgId = cropTarget.id.replace('org_', '')
          const next = organization.map((x) =>
            x.id === orgId ? { ...x, imageName: file.name, imageUrl: res.data.url } : x
          )
          saveOrganizationToDb(next)
          toast('Foto pengurus berhasil dipotong dan diperbarui', 'success')
        } else {
          updateSlide(cropTarget.id, { imageName: file.name, imageUrl: res.data.url }, false)
          toast('Gambar slide berhasil dipotong (klik Simpan Perubahan untuk menerapkan)', 'success')
        }
      }
    } catch (err) {
      toast('Gagal mengunggah gambar hasil potong', 'error')
    } finally {
      setUploadingText('')
      setCropModalOpen(false)
      setCropTarget(null)
    }
  }

  const updateSlide = (id: string, patch: Partial<HeroSlide>, autoSave = false) => {
    setSlides((s) => {
      const next = s.map((x) => (x.id === id ? { ...x, ...patch } : x))
      slidesRef.current = next
      if (autoSave) autoSaveSlides(next)
      return next
    })
  }
  const updateFeature = (id: string, patch: Partial<Feature>) =>
    setFeatures((s) => s.map((x) => (x.id === id ? { ...x, ...patch } : x)))
  const updateFaq = (id: string, patch: Partial<FaqItem>) =>
    setFaqs((s) => s.map((x) => (x.id === id ? { ...x, ...patch } : x)))
  const updateOrg = (id: string, patch: Partial<OrganizationItem>) =>
    setOrganization((s) => s.map((x) => (x.id === id ? { ...x, ...patch } : x)))

  const handleSave = async () => {
    setConfirmSave(false)
    setSaveStatus({ type: 'loading', message: 'Sedang menyimpan semua pengaturan portal ke server...' })
    try {
      const payload: Record<string, any> = {
        site_name: siteName,
        tagline,
        logo_url: logoUrl,
        maintenance_mode: maintenanceMode,
        allow_public_registration: allowPublicRegistration,
        hero_slides: slides,
        about: { title: aboutTitle, content: aboutText, label: aboutLabel, bgColor: aboutBgColor },
        about_banner: { imageUrl: bannerImageUrlRef.current || bannerImageUrl, imageName: bannerImageName, tagline: bannerTagline, headerLine1: bannerHeaderLine1, headerLine2: bannerHeaderLine2, logoUrl: '', logoName: '', logoWidth, logoHeight, logoX, logoY, bgImageX, bgImageY, taglineX, taglineY, showOverlay, overlayColor, overlayOpacity },
        organization,
        features,
        faqs,
        contacts: { instagram, email, whatsapp, alamat },
        terms_conditions: { title: termsTitle, subtitle: termsSubtitle, last_updated: termsLastUpdated, intro: termsIntro, content: termsContent },
      }
      await api.updatePortalConfig(payload)
      await fetchConfig()
      window.dispatchEvent(new Event('portal-config-updated'))
      const timeStr = new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
      setSaveStatus({ type: 'success', message: `Pengaturan portal berhasil disimpan ke database pada ${timeStr} WIB` })
      toast('Pengaturan portal berhasil disimpan', 'success')
    } catch (err: any) {
      console.log('Error saving portal config:', err)
      console.log('Error detail:', err.response?.data)
      const detail = err.response?.data?.detail || err.response?.data?.error || err.response?.data?.message || err.message || 'Terjadi kesalahan sistem yang tidak diketahui'
      setSaveStatus({ type: 'error', message: `Gagal menyimpan pengaturan portal: ${detail}` })
      toast(`Gagal menyimpan pengaturan portal: ${detail}`, 'error')
    }
  }

  // Sync banner config to ref for auto-save
  aboutBannerRef.current = {
    imageUrl: bannerImageUrlRef.current || bannerImageUrl,
    imageName: bannerImageName,
    tagline: bannerTagline,
    headerLine1: bannerHeaderLine1,
    headerLine2: bannerHeaderLine2,
    logoUrl: '',
    logoName: '',
    logoWidth,
    logoHeight,
    logoX, logoY, bgImageX, bgImageY, taglineX, taglineY,
    showOverlay, overlayColor, overlayOpacity,
  }
  return (
    <div className="px-10 py-8">
      <Breadcrumb items={[{ label: 'Portal Settings' }]} />
      <div className="mt-2 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Pengaturan Portal</h1>
          <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />
        </div>
        {canEdit && (
          <Button
            onClick={() => setConfirmSave(true)}
            disabled={saveStatus.type === 'loading'}
            leftIcon={<Save className="h-4 w-4" />}
          >
            {saveStatus.type === 'loading' ? 'Menyimpan...' : 'Simpan Perubahan'}
          </Button>
        )}
      </div>
      <p className="mt-4 text-sm text-gray-600 max-w-3xl">
        Kelola konten yang tampil di portal publik IKA JTK POLBAN. Perubahan akan langsung tampil di halaman portal setelah disimpan.
      </p>

      {saveStatus.type && (
        <div
          className={cn(
            'mt-6 p-4 rounded-lg border flex items-center justify-between gap-3 animate-in fade-in-50',
            saveStatus.type === 'loading' && 'bg-blue-50 border-blue-200 text-blue-800',
            saveStatus.type === 'success' && 'bg-green-50 border-green-200 text-green-800',
            saveStatus.type === 'error' && 'bg-red-50 border-red-200 text-red-800 font-medium'
          )}
        >
          <div className="flex items-center gap-3">
            {saveStatus.type === 'loading' && <div className="h-4 w-4 border-2 border-blue-600 border-t-transparent rounded-full animate-spin shrink-0" />}
            {saveStatus.type === 'success' && <CheckCircle2 className="h-5 w-5 text-green-600 shrink-0" />}
            {saveStatus.type === 'error' && <AlertCircle className="h-5 w-5 text-red-600 shrink-0" />}
            <span className="text-sm">{saveStatus.message}</span>
          </div>
          {saveStatus.type !== 'loading' && (
            <button
              onClick={() => setSaveStatus({ type: null, message: '' })}
              className="text-xs font-semibold underline hover:opacity-75 shrink-0 ml-4"
            >
              Tutup
            </button>
          )}
        </div>
      )}

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-[220px_1fr] gap-6 items-start">
        {/* Side nav */}
        <aside className="lg:sticky lg:top-8">
          <nav className="bg-white rounded-lg border border-gray-200 p-2 space-y-0.5">
            <NavTabBtn icon={<SettingsIcon className="h-4 w-4" />} label="Umum" active={tab === 'general'} onClick={() => setTab('general')} />
            <NavTabBtn icon={<ImageIcon className="h-4 w-4" />} label="Hero & Banner" active={tab === 'hero'} onClick={() => setTab('hero')} />
            <NavTabBtn icon={<MessageSquare className="h-4 w-4" />} label="Tentang & Organisasi" active={tab === 'about' || tab === 'organisasi'} onClick={() => setTab('about')} />
            <NavTabBtn icon={<Globe className="h-4 w-4" />} label="Fitur Portal" active={tab === 'features'} onClick={() => setTab('features')} />
            <NavTabBtn icon={<HelpCircle className="h-4 w-4" />} label="FAQ" active={tab === 'faq'} onClick={() => setTab('faq')} />
            <NavTabBtn icon={<MessageSquare className="h-4 w-4" />} label="Kontak" active={tab === 'kontak'} onClick={() => setTab('kontak')} />
            <NavTabBtn icon={<ScrollText className="h-4 w-4" />} label="User Agreement" active={tab === 'terms'} onClick={() => setTab('terms')} />
          </nav>
        </aside>

        {/* Content */}
        <div className={cn("flex-1 space-y-6", !canEdit && "pointer-events-none")}>
          {tab === 'general' && (
            <SectionCard title="Pengaturan Umum">
              <div className="space-y-4">
                <div>
                  <Label required>Nama Site</Label>
                  <Input value={siteName} onChange={(e) => setSiteName(e.target.value)} />
                </div>
                <div>
                  <Label>Tagline</Label>
                  <Input value={tagline} onChange={(e) => setTagline(e.target.value)} />
                  <p className="mt-1 text-xs text-gray-500">
                    Tampil di footer dan meta description portal.
                  </p>
                </div>
                <div>
                  <Label>Logo Portal</Label>
                  <div className="flex items-center gap-3">
                    <img
                      src={logoUrl ? getFileUrl(logoUrl) : defaultLogoUrl}
                      alt="Logo"
                      className="h-16 w-16 rounded border border-gray-200 object-contain"
                    />
                    <input ref={logoFileRef} type="file" accept=".jpg,.jpeg,.png" className="hidden" onChange={handleLogoChange} />
                    {canEdit && (
                      <div className="flex flex-col">
                        <Button type="button" variant="outline" size="sm" onClick={handlePickLogo} rightIcon={<Upload className="h-4 w-4" />}>
                          Ganti Logo
                        </Button>
                        <p className="text-[10px] text-gray-500 mt-1">Maks. 10MB (Rekomendasi: 400x400px)</p>
                      </div>
                    )}
                  </div>
                </div>
                <div className="pt-4 border-t border-gray-100 space-y-3">
                  <h3 className="font-semibold text-gray-900 text-sm">Mode Portal</h3>
                  <div className="space-y-2">
                    <label className="flex items-start gap-3 cursor-pointer group">
                      <input
                        type="radio"
                        name="portalMode"
                        className="mt-0.5 h-4 w-4 accent-primary cursor-pointer"
                        checked={!maintenanceMode}
                        onChange={() => {
                          setMaintenanceMode(false)
                          setAllowPublicRegistration(true)
                        }}
                      />
                      <div>
                        <span className="text-sm font-medium text-gray-800 group-hover:text-gray-900">
                          Normal — seluruh publik dapat melihat portal
                        </span>
                        <p className="text-xs text-gray-500 mt-0.5">Portal aktif dan dapat diakses oleh semua pengunjung.</p>
                      </div>
                    </label>
                    <label className="flex items-start gap-3 cursor-pointer group">
                      <input
                        type="radio"
                        name="portalMode"
                        className="mt-0.5 h-4 w-4 accent-primary cursor-pointer"
                        checked={maintenanceMode}
                        onChange={() => {
                          setMaintenanceMode(true)
                          setAllowPublicRegistration(false)
                        }}
                      />
                      <div>
                        <span className="text-sm font-medium text-gray-800 group-hover:text-gray-900">
                          Mode Maintenance — sembunyikan portal dari publik
                        </span>
                        <p className="text-xs text-gray-500 mt-0.5">Portal tidak dapat diakses publik dan akan menampilkan halaman pemeliharaan.</p>
                      </div>
                    </label>
                  </div>
                </div>
              </div>
            </SectionCard>
          )}

          {tab === 'hero' && (
            <SectionCard
              title="Hero Carousel"
              actions={
                canEdit && (
                  <Button
                    size="sm"
                    onClick={() =>
                      setSlides([
                        ...slides,
                        {
                          id: uid(),
                          judul: 'JUDUL BARU',
                          badge: 'BERITA',
                          newsTitle: '',
                          excerpt: '',
                          imageUrl: '',
                          bgImageX: 50,
                          bgImageY: 50,
                          showOverlay: true,
                          overlayColor: '#1E2A4D',
                          overlayOpacity: 40,
                        },
                      ])
                    }
                    leftIcon={<Plus className="h-4 w-4" />}
                  >
                    Tambah Slide
                  </Button>
                )
              }
            >
              <div className="space-y-4">
                {slides.map((s, i) => (
                  <div
                    key={s.id}
                    className="rounded-md border border-gray-200 bg-gray-50/50 p-4 space-y-3"
                  >
                    <div className="flex items-center justify-between">
                      <h4 className="font-semibold text-gray-900 text-sm">
                        Slide #{i + 1}
                      </h4>
                      {canEdit && (
                        <button
                          type="button"
                          onClick={() => {
                            if (slides.length <= 1) {
                              toast('Hero Carousel harus memiliki minimal 1 item', 'error')
                              return
                            }
                            setSlides(slides.filter((x) => x.id !== s.id))
                          }}
                          className="p-1.5 rounded hover:bg-white text-gray-400 hover:text-danger"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      )}
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                      <div>
                        <Label>Overlay Title</Label>
                        <Input
                          value={s.judul}
                          onChange={(e) => updateSlide(s.id, { judul: e.target.value })}
                        />
                      </div>
                      <div>
                        <Label>Badge</Label>
                        <Input
                          value={s.badge}
                          onChange={(e) => updateSlide(s.id, { badge: e.target.value })}
                        />
                      </div>
                    </div>
                    <div>
                      <Label>News Title</Label>
                      <Input
                        value={s.newsTitle}
                        onChange={(e) => updateSlide(s.id, { newsTitle: e.target.value })}
                      />
                    </div>
                    <div>
                      <Label>Excerpt</Label>
                      <RichTextEditor
                        minHeight={100}
                        value={s.excerpt}
                        onChange={(html) => updateSlide(s.id, { excerpt: html })}
                      />
                    </div>
                    <div>
                      <Label>Gambar Slide</Label>
                      <div className="flex items-stretch gap-2">
                        <div className="flex-1 h-10 rounded-md border border-gray-300 bg-white px-3 flex items-center text-sm text-gray-500 truncate">
                          {s.imageName || (s.imageUrl ? 'Gambar tersimpan' : 'Tidak Ada File')}
                        </div>
                        {canEdit && (
                          <Button
                            variant="outline"
                            onClick={() => handlePickSlideImage(s.id)}
                            rightIcon={<Upload className="h-4 w-4" />}
                          >
                            Pilih File
                          </Button>
                        )}
                        <input
                          ref={(el) => {
                            slideFileRefs.current[s.id] = el
                          }}
                          type="file"
                          accept=".jpeg,.jpg,.png"
                          className="hidden"
                          onChange={(e) => handleSlideImageChange(s.id, e)}
                        />
                      </div>
                      <p className="mt-1.5 text-xs text-gray-400">
                        File yang didukung: .jpeg, .jpg, .png. Gambar akan otomatis dipotong sesuai dimensi (1440 x 520 px) saat dipilih.
                      </p>
                      {s.imageUrl && (
                        <div className="mt-3 rounded-lg overflow-hidden border border-gray-200 bg-gray-100 max-w-xl">
                          <img
                            src={getAvatarUrl(s.imageUrl, `Slide ${i + 1}`)}
                            alt={`Slide ${i + 1}`}
                            className="w-full max-h-[220px] object-cover"
                          />
                        </div>
                      )}
                    </div>

                    {/* Overlay Slide */}
                    <div className="space-y-3 pt-3 border-t border-gray-200">
                      <Label>Overlay</Label>
                      <Checkbox
                        label="Tampilkan layer overlay di atas gambar slide"
                        checked={s.showOverlay ?? true}
                        onChange={(e) => updateSlide(s.id, { showOverlay: e.target.checked })}
                      />
                      {(s.showOverlay ?? true) && (
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 max-w-md bg-white p-3 rounded-lg border border-gray-200">
                          <div className="space-y-2">
                            <Label>Warna</Label>
                            <div className="flex items-center gap-2">
                              <input
                                type="color"
                                value={s.overlayColor || '#1E2A4D'}
                                onChange={(e) => updateSlide(s.id, { overlayColor: e.target.value })}
                                className="h-10 w-12 rounded border border-gray-300 cursor-pointer shrink-0"
                              />
                              <Input
                                value={s.overlayColor || '#1E2A4D'}
                                onChange={(e) => updateSlide(s.id, { overlayColor: e.target.value })}
                                placeholder="#1E2A4D"
                              />
                            </div>
                          </div>
                          <div className="space-y-2">
                            <Label>Opacity</Label>
                            <div className="flex items-center gap-3 pt-2">
                              <input
                                type="range"
                                min={0}
                                max={100}
                                value={s.overlayOpacity ?? 40}
                                onChange={(e) => updateSlide(s.id, { overlayOpacity: Number(e.target.value) })}
                                className="flex-1 h-2 accent-orange-500 cursor-pointer"
                              />
                              <span className="text-sm font-medium text-gray-700 w-10 text-right">{s.overlayOpacity ?? 40}%</span>
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
                {slides.length === 0 && (
                  <p className="text-sm text-gray-500 text-center py-8">
                    Belum ada slide. Klik "Tambah Slide" untuk menambah.
                  </p>
                )}
              </div>
            </SectionCard>
          )}

          {tab === 'hero' && (
            <SectionCard title="Banner Definisi Beranda (Di Bawah Hero)">
              <p className="text-sm text-gray-500 mb-4">
                Atur kata-kata dan warna latar belakang (background) untuk section Definisi IKA JTK yang tampil langsung di bawah Hero Carousel pada Beranda Portal.
              </p>
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <Label>Label Kecil (Badge Atas)</Label>
                    <Input
                      value={aboutLabel}
                      onChange={(e) => setAboutLabel(e.target.value)}
                      placeholder="Contoh: DEFINISI IKA JTK"
                    />
                  </div>
                  <div>
                    <Label>Warna Latar Belakang (Background Color)</Label>
                    <div className="flex items-center gap-3">
                      <input
                        type="color"
                        value={aboutBgColor}
                        onChange={(e) => setAboutBgColor(e.target.value)}
                        className="h-10 w-14 rounded border border-gray-300 cursor-pointer p-1"
                      />
                      <Input
                        value={aboutBgColor}
                        onChange={(e) => setAboutBgColor(e.target.value)}
                        placeholder="#FFF1E5"
                      />
                    </div>
                  </div>
                </div>
                <div>
                  <Label>Judul Utama</Label>
                  <Input
                    value={aboutTitle}
                    onChange={(e) => setAboutTitle(e.target.value)}
                    placeholder="Contoh: Apa itu IKA JTK?"
                  />
                </div>
                <div>
                  <Label>Kata-kata / Deskripsi</Label>
                  <RichTextEditor
                    minHeight={250}
                    value={aboutText}
                    onChange={setAboutText}
                  />
                </div>
              </div>
            </SectionCard>
          )}

          {(tab === 'about' || tab === 'organisasi') && (
            <SectionCard title="Banner Tentang">
              <p className="text-sm text-gray-500 mb-5">
                Atur tampilan banner gambar besar yang muncul di halaman "Tentang" portal.
              </p>

              {/* Preview banner — drag logo, resize handle */}
              <div className="mx-auto" style={{ maxWidth: 1100 }}>
              <div
                ref={bannerRef}
                className="rounded-xl overflow-hidden relative select-none"
                style={{ aspectRatio: '16/6', background: '#1E2A4D' }}
              >
                {/* Background image */}
                {bannerImageUrl ? (
                  <img
                    src={getFileUrl(bannerImageUrl)}
                    alt="Banner Preview"
                    className="absolute inset-0 w-full h-full object-cover pointer-events-none"
                    style={{ objectPosition: `${bgImageX}% ${bgImageY}%` }}
                  />
                ) : (
                  <div className="absolute inset-0 flex items-center justify-center text-gray-500 text-sm pointer-events-none">Belum ada gambar banner</div>
                )}
                {/* Overlay — drag untuk reposition background */}
                {showOverlay && (
                  <div
                    className="absolute inset-0 cursor-grab"
                    style={{ backgroundColor: overlayColor, opacity: overlayOpacity / 100 }}
                    onMouseDown={(e) => {
                    if ((e.target as HTMLElement).closest('[data-draggable]')) return
                    e.preventDefault()
                    const rect = bannerRef.current?.getBoundingClientRect()
                    if (!rect) return
                    const sx = e.clientX, sy = e.clientY
                    const sx0 = bgImageX, sy0 = bgImageY
                    const onMove = (ev: MouseEvent) => {
                      const dx = ((ev.clientX - sx) / rect.width) * 100
                      const dy = ((ev.clientY - sy) / rect.height) * 100
                      const nx = Math.max(0, Math.min(100, sx0 - dx))
                      const ny = Math.max(0, Math.min(100, sy0 - dy))
                      setBgImageX(nx)
                      setBgImageY(ny)
                      aboutBannerRef.current.bgImageX = nx
                      aboutBannerRef.current.bgImageY = ny
                    }
                    const onUp = () => {
                       document.removeEventListener('mousemove', onMove)
                       document.removeEventListener('mouseup', onUp)
                     }
                     document.addEventListener('mousemove', onMove)
                     document.addEventListener('mouseup', onUp)
                   }}
                   />
                 )}
 
                {/* Logo + teks — posisi normal (Atas Kanan) */}
                <div
                  className="absolute top-4 right-6 flex items-center gap-3 p-1 w-max whitespace-nowrap z-10"
                >
                    <div className="text-right whitespace-nowrap">
                     <p className="text-white text-xs font-semibold tracking-[0.5px] whitespace-nowrap" style={{ textShadow: '0 1px 4px rgba(0,0,0,0.6)' }}>{bannerHeaderLine1 || 'JURUSAN TEKNIK KOMPUTER DAN INFORMATIKA'}</p>
                     <p className="text-[#F58220] text-xs font-black tracking-[0.5px] whitespace-nowrap" style={{ textShadow: '0 1px 4px rgba(0,0,0,0.6)' }}>{bannerHeaderLine2 || 'POLITEKNIK NEGERI BANDUNG'}</p>
                   </div>
                   <div className="relative shrink-0">
                     <img src={logoUrl ? getFileUrl(logoUrl) : defaultLogoUrl} alt="Logo" className="rounded-[8px] bg-white p-1.5 object-contain shrink-0" style={{ width: logoWidth, height: logoHeight }} />
                     {/* Resize handle */}
                     <div
                       className="absolute -bottom-2 -right-2 w-4 h-4 bg-white border-2 border-blue-500 rounded-full cursor-se-resize shadow"
                       onMouseDown={(e) => {
                         e.stopPropagation()
                         e.preventDefault()
                         const sx = e.clientX, sy = e.clientY
                         const sw = logoWidth, sh = logoHeight
                         const onMove = (ev: MouseEvent) => {
                           const nw = Math.max(16, Math.min(200, sw + ev.clientX - sx))
                           const nh = Math.max(16, Math.min(200, sh + ev.clientY - sy))
                           setLogoWidth(nw)
                           setLogoHeight(nh)
                           aboutBannerRef.current.logoWidth = nw
                           aboutBannerRef.current.logoHeight = nh
                         }
                         const onUp = () => {
                           document.removeEventListener('mousemove', onMove)
                           document.removeEventListener('mouseup', onUp)
                         }
                         document.addEventListener('mousemove', onMove)
                         document.addEventListener('mouseup', onUp)
                       }}
                     />
                   </div>
                </div>

                {/* Tagline — posisi normal (Bawah Kiri) */}
                <div
                  className="absolute bottom-4 left-6 p-1 w-max whitespace-nowrap z-10"
                >
                    <p className="text-white text-2xl font-black italic whitespace-nowrap" style={{ textShadow: '0 2px 8px rgba(0,0,0,0.6)' }}>{bannerTagline || 'Bersama, Berdampak.'}</p>
                </div>
              </div>
            </div>

              {/* ===== SECTION: BACKGROUND ===== */}
              <div className="border border-gray-200 rounded-lg p-5 bg-white space-y-4">
                <h3 className="font-semibold text-gray-900 text-sm border-b border-gray-100 pb-2">Background</h3>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label>Gambar Latar Belakang</Label>
                    <input ref={bannerImageFileRef} type="file" accept=".jpg,.jpeg,.png" className="hidden" onChange={handleBannerImageChange} />
                    <p className="text-[10px] text-gray-500">Maks. 10MB. Gambar akan otomatis dipotong sesuai dimensi portal (1920 x 720 px) saat dipilih.</p>
                    <div className="flex gap-2">
                      {canEdit && (
                        <button type="button" onClick={handlePickBannerImage}
                          className="flex-1 flex items-center gap-2 px-4 py-2 text-sm border border-dashed border-gray-300 rounded-lg text-gray-600 hover:border-primary hover:text-primary transition-colors justify-center">
                          <Upload className="h-4 w-4" />
                          {bannerImageName || 'Upload Gambar Latar'}
                        </button>
                      )}
                    </div>
                    {bannerImageUrl && (
                      <img src={getFileUrl(bannerImageUrl)} alt="Banner BG" className="mt-2 h-36 w-full rounded-lg border border-gray-200 object-cover" />
                    )}
                  </div>
                  <div className="space-y-2">
                    <Label>Posisi Latar (%)</Label>
                    <div className="flex gap-3 max-w-md">
                      <div className="flex-1">
                        <span className="block text-xs text-gray-400 mb-1">X (kiri)</span>
                        <Input type="number" min={0} max={100} value={Math.round(bgImageX)}
                          onChange={(e) => setBgImageX(Math.max(0, Math.min(100, Number(e.target.value))))} />
                      </div>
                      <div className="flex-1">
                        <span className="block text-xs text-gray-400 mb-1">Y (atas)</span>
                        <Input type="number" min={0} max={100} value={Math.round(bgImageY)}
                          onChange={(e) => setBgImageY(Math.max(0, Math.min(100, Number(e.target.value))))} />
                      </div>
                    </div>
                    <p className="text-xs text-gray-400">Drag di area preview untuk menggeser.</p>
                  </div>
                </div>
              </div>

              {/* ===== SECTION: OVERLAY ===== */}
              <div className="border border-gray-200 rounded-lg p-5 bg-white space-y-4">
                <h3 className="font-semibold text-gray-900 text-sm border-b border-gray-100 pb-2">Overlay</h3>
                <Checkbox label="Tampilkan layer overlay di atas gambar" checked={showOverlay}
                  onChange={(e) => setShowOverlay(e.target.checked)} />
                {showOverlay && (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Warna</Label>
                      <div className="flex items-center gap-2">
                        <input type="color" value={overlayColor}
                          onChange={(e) => setOverlayColor(e.target.value)}
                          className="h-10 w-12 rounded border border-gray-300 cursor-pointer shrink-0" />
                        <Input value={overlayColor} onChange={(e) => setOverlayColor(e.target.value)} placeholder="#1a2744" />
                      </div>
                    </div>
                    <div className="space-y-2">
                      <Label>Opacity</Label>
                      <div className="flex items-center gap-3">
                        <input type="range" min={0} max={100} value={overlayOpacity}
                          onChange={(e) => setOverlayOpacity(Number(e.target.value))}
                          className="flex-1 h-2 accent-orange-500" />
                        <span className="text-sm text-gray-600 w-8 text-right">{overlayOpacity}%</span>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              {/* ===== SECTION: LOGO & HEADER TEXT ===== */}
              <div className="border border-gray-200 rounded-lg p-5 bg-white space-y-4">
                <h3 className="font-semibold text-gray-900 text-sm border-b border-gray-100 pb-2">Logo & Teks Header (Kanan Atas)</h3>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label>Logo Banner</Label>
                    <div className="flex items-center gap-3 p-3 rounded-lg border border-gray-200 bg-gray-50">
                      <img src={logoUrl ? getFileUrl(logoUrl) : defaultLogoUrl} alt="Logo" className="h-12 w-12 rounded border border-gray-200 object-contain bg-white p-1" />
                      <div>
                        <p className="text-sm font-medium text-gray-800">Mengikuti Logo Umum</p>
                        <p className="text-xs text-gray-500">Logo pada banner otomatis menggunakan logo utama dari tab Pengaturan Umum.</p>
                      </div>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label>Ukuran (px)</Label>
                    <div className="flex gap-3 max-w-md">
                      <div className="flex-1">
                        <span className="block text-xs text-gray-400 mb-1">Lebar</span>
                        <Input type="number" min={16} max={200} value={logoWidth}
                          onChange={(e) => setLogoWidth(Number(e.target.value))} />
                      </div>
                      <div className="flex-1">
                        <span className="block text-xs text-gray-400 mb-1">Tinggi</span>
                        <Input type="number" min={16} max={200} value={logoHeight}
                          onChange={(e) => setLogoHeight(Number(e.target.value))} />
                      </div>
                    </div>
                  </div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Baris 1 (putih)</Label>
                    <Input value={bannerHeaderLine1}
                      placeholder="JURUSAN TEKNIK KOMPUTER DAN INFORMATIKA"
                      onChange={(e) => setBannerHeaderLine1(e.target.value)} />
                  </div>
                  <div className="space-y-2">
                    <Label>Baris 2 (oranye)</Label>
                    <Input value={bannerHeaderLine2}
                      placeholder="POLITEKNIK NEGERI BANDUNG"
                      onChange={(e) => setBannerHeaderLine2(e.target.value)} />
                  </div>
                </div>
              </div>

              {/* ===== SECTION: TAGLINE ===== */}
              <div className="border border-gray-200 rounded-lg p-5 bg-white space-y-4">
                <h3 className="font-semibold text-gray-900 text-sm border-b border-gray-100 pb-2">Tagline (Kiri Bawah)</h3>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label>Teks Tagline</Label>
                    <Input value={bannerTagline} placeholder="Bersama, Berdampak."
                      onChange={(e) => setBannerTagline(e.target.value)} />
                  </div>
                </div>
              </div>
            </SectionCard>
          )}


          {(tab === 'about' || tab === 'organisasi') && (
            <SectionCard
              title="Struktur Organisasi (Pengurus)"
              actions={
                canEdit && (
                  <Button
                    size="sm"
                    onClick={() => setShowAddOrgModal(true)}
                    leftIcon={<Plus className="h-4 w-4" />}
                  >
                    Tambah Pengurus dari Alumni
                  </Button>
                )
              }
            >
              <div className="space-y-4">
                {organization.map((o, i) => (
                  <div
                    key={o.id}
                    className="rounded-md border border-gray-200 bg-gray-50/50 p-4 space-y-3"
                  >
                    <div className="flex items-center justify-between">
                      <h4 className="font-semibold text-gray-900 text-sm">
                        Pengurus #{i + 1}
                      </h4>
                      {canEdit && (
                        <button
                          type="button"
                          onClick={() => saveOrganizationToDb(organization.filter((x) => x.id !== o.id))}
                          className="p-1.5 rounded hover:bg-white text-gray-400 hover:text-danger"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      )}
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                      <div>
                        <Label required>Nama</Label>
                        <Input
                          value={o.nama}
                          onChange={(e) => updateOrg(o.id, { nama: e.target.value })}
                        />
                      </div>
                      <div>
                        <Label required>Jabatan</Label>
                        <Input
                          value={o.jabatan}
                          onChange={(e) => updateOrg(o.id, { jabatan: e.target.value })}
                        />
                      </div>
                      <div>
                        <Label required>Batch / Angkatan</Label>
                        <Input
                          value={o.batch}
                          onChange={(e) => updateOrg(o.id, { batch: e.target.value })}
                        />
                      </div>
                    </div>
                    <div>
                      <Label>Foto Pengurus</Label>
                      <div className="flex items-stretch gap-2">
                        <div className="flex-1 h-10 rounded-md border border-gray-300 bg-white px-3 flex items-center text-sm text-gray-500 truncate">
                          {o.imageName || (o.imageUrl ? 'Foto tersimpan' : 'Tidak Ada File')}
                        </div>
                        {canEdit && (
                          <Button
                            variant="outline"
                            onClick={() => handlePickOrgImage(o.id)}
                            rightIcon={<Upload className="h-4 w-4" />}
                          >
                            Pilih File
                          </Button>
                        )}
                        <input
                          ref={(el) => {
                            orgFileRefs.current[o.id] = el
                          }}
                          type="file"
                          accept=".jpeg,.jpg,.png"
                          className="hidden"
                          onChange={(e) => handleOrgImageChange(o.id, e)}
                        />
                      </div>
                      {o.imageUrl && (
                        <img
                          src={getAvatarUrl(o.imageUrl, o.nama)}
                          alt={`Preview pengurus ${o.nama}`}
                          className="mt-3 h-24 w-24 rounded-full border border-gray-200 object-cover"
                        />
                      )}
                    </div>
                  </div>
                ))}
                {organization.length === 0 && (
                  <p className="text-sm text-gray-500 text-center py-6">Belum ada data struktur organisasi.</p>
                )}
              </div>
            </SectionCard>
          )}

          {tab === 'features' && (
            <SectionCard
              title="Fitur Portal (Kenapa Harus Join?)"
              actions={
                canEdit && (
                  <Button
                    size="sm"
                    onClick={() =>
                      setFeatures([
                        ...features,
                        { id: uid(), icon: 'star', title: '', desc: '' },
                      ])
                    }
                    leftIcon={<Plus className="h-4 w-4" />}
                  >
                    Tambah Fitur
                  </Button>
                )
              }
            >
              <div className="space-y-4">
                {features.map((f, i) => (
                  <div
                    key={f.id}
                    className="rounded-md border border-gray-200 bg-gray-50/50 p-4 space-y-3"
                  >
                    <div className="flex items-center justify-between">
                      <h4 className="font-semibold text-gray-900 text-sm">
                        Fitur #{i + 1}
                      </h4>
                      {canEdit && (
                        <button
                          type="button"
                          onClick={() => setFeatures(features.filter((x) => x.id !== f.id))}
                          className="p-1.5 rounded hover:bg-white text-gray-400 hover:text-danger"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      )}
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-[140px_1fr] gap-3">
                      <div>
                        <Label>Icon</Label>
                        <select
                          value={f.icon}
                          onChange={(e) => updateFeature(f.id, { icon: e.target.value })}
                          className="block w-full h-10 rounded-md border border-gray-300 bg-white px-3 text-sm"
                        >
                          {ICONS.map((i) => (
                            <option key={i} value={i}>{i}</option>
                          ))}
                        </select>
                      </div>
                      <div>
                        <Label>Judul</Label>
                        <Input
                          value={f.title}
                          onChange={(e) => updateFeature(f.id, { title: e.target.value })}
                        />
                      </div>
                    </div>
                    <div>
                      <Label>Deskripsi</Label>
                      <Input
                        value={f.desc}
                        onChange={(e) => updateFeature(f.id, { desc: e.target.value })}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </SectionCard>
          )}

          {tab === 'faq' && (
            <SectionCard
              title="FAQ (Frequently Asked Questions)"
              actions={
                canEdit && (
                  <Button
                    size="sm"
                    onClick={() =>
                      setFaqs([...faqs, { id: uid(), pertanyaan: '', jawaban: '' }])
                    }
                    leftIcon={<Plus className="h-4 w-4" />}
                  >
                    Tambah FAQ
                  </Button>
                )
              }
            >
              <div className="space-y-4">
                {faqs.map((q, i) => (
                  <div
                    key={q.id}
                    className="rounded-md border border-gray-200 bg-gray-50/50 p-4 space-y-3"
                  >
                    <div className="flex items-center justify-between">
                      <h4 className="font-semibold text-gray-900 text-sm">
                        FAQ #{i + 1}
                      </h4>
                      {canEdit && (
                        <button
                          type="button"
                          onClick={() => setFaqs(faqs.filter((x) => x.id !== q.id))}
                          className="p-1.5 rounded hover:bg-white text-gray-400 hover:text-danger"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      )}
                    </div>
                    <div>
                      <Label>Pertanyaan</Label>
                      <Input
                        value={q.pertanyaan}
                        onChange={(e) => updateFaq(q.id, { pertanyaan: e.target.value })}
                      />
                    </div>
                    <div>
                      <Label>Jawaban</Label>
                      <RichTextEditor
                        minHeight={120}
                        value={q.jawaban}
                        onChange={(html) => updateFaq(q.id, { jawaban: html })}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </SectionCard>
          )}

          {tab === 'kontak' && (
            <SectionCard title="Informasi Kontak">
              <div className="space-y-4">
                <div>
                  <Label>Instagram</Label>
                  <Input value={instagram} onChange={(e) => setInstagram(e.target.value)} />
                </div>
                <div>
                  <Label>Email</Label>
                  <Input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>
                <div>
                  <Label>WhatsApp</Label>
                  <Input value={whatsapp} onChange={(e) => setWhatsapp(e.target.value)} />
                </div>
                <div>
                  <Label>Alamat</Label>
                  <RichTextEditor
                    minHeight={120}
                    value={alamat}
                    onChange={setAlamat}
                  />
                </div>
              </div>
            </SectionCard>
          )}

          {tab === 'terms' && (
            <SectionCard title="Pengaturan User Agreement">
              <div className="space-y-4">
                <div>
                  <Label required>Judul Dokumen</Label>
                  <Input value={termsTitle} onChange={(e) => setTermsTitle(e.target.value)} />
                </div>
                <div>
                  <Label>Subjudul / Deskripsi Singkat</Label>
                  <Input value={termsSubtitle} onChange={(e) => setTermsSubtitle(e.target.value)} />
                </div>
                <div>
                  <Label>Isi Dokumen Syarat & Ketentuan (Tanggal Diperbarui, Pengantar, & Pasal/Aturan)</Label>
                  <RichTextEditor
                    minHeight={500}
                    value={termsContent}
                    onChange={setTermsContent}
                  />
                  <p className="mt-1 text-xs text-gray-500">
                    Tuliskan keterangan tanggal pembaruan, paragraf pengantar (intro), serta seluruh pasal & aturan dalam satu editor ini. Gunakan heading (H3), bullet list, dan formatting lainnya.
                  </p>
                </div>
              </div>
            </SectionCard>
          )}
        </div>
      </div>
      {showAddOrgModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-lg bg-white p-6 shadow-xl space-y-4">
            <h3 className="text-lg font-bold text-gray-900">Tambah Pengurus Organisasi</h3>
            <p className="text-xs text-gray-500">Pilih dari data alumni yang tersedia di sistem.</p>
            <div>
              <Label required>Cari & Pilih Alumni</Label>
              <Input
                placeholder="Ketik nama atau angkatan alumni..."
                value={alumniSearchQuery}
                onChange={(e) => setAlumniSearchQuery(e.target.value)}
              />
              <div className="mt-2 max-h-48 overflow-y-auto border border-gray-200 rounded-md bg-white divide-y divide-gray-100 shadow-inner">
                {verifiedAlumni
                  .filter((al) => {
                    const q = alumniSearchQuery.toLowerCase()
                    return (
                      al.nama?.toLowerCase().includes(q) ||
                      al.angkatan?.toString().toLowerCase().includes(q) ||
                      al.noAlumni?.toLowerCase().includes(q)
                    )
                  })
                  .map((al) => {
                    const isSelected = selectedAlumniId === al.id
                    return (
                      <div
                        key={al.id}
                        onClick={() => setSelectedAlumniId(al.id)}
                        className={`p-2.5 text-sm cursor-pointer flex items-center justify-between transition-colors ${
                          isSelected
                            ? 'bg-orange-100/90 font-medium text-orange-900 border-l-4 border-orange-500'
                            : 'text-gray-700 hover:bg-gray-50'
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <img
                            src={getAvatarUrl(al.avatarUrl, al.nama)}
                            alt={al.nama}
                            className="h-10 w-10 rounded-full object-cover border border-gray-200 shrink-0"
                          />
                          <div>
                            <div className="font-semibold text-gray-900">{al.nama}</div>
                            <div className="text-xs text-gray-500">
                              Angkatan {al.angkatan || '-'} {al.noAlumni ? `• No: ${al.noAlumni}` : ''}
                            </div>
                          </div>
                        </div>
                        {isSelected && (
                          <span className="text-xs font-bold text-orange-700 bg-orange-200 px-2 py-0.5 rounded shrink-0">
                            Terpilih
                          </span>
                        )}
                      </div>
                    )
                  })}
                {verifiedAlumni.length === 0 && (
                  <div className="p-4 text-xs text-center text-amber-600">Belum ada data alumni.</div>
                )}
                {verifiedAlumni.length > 0 &&
                  verifiedAlumni.filter((al) => {
                    const q = alumniSearchQuery.toLowerCase()
                    return (
                      al.nama?.toLowerCase().includes(q) ||
                      al.angkatan?.toString().toLowerCase().includes(q) ||
                      al.noAlumni?.toLowerCase().includes(q)
                    )
                  }).length === 0 && (
                    <div className="p-4 text-xs text-center text-gray-500">Alumni tidak ditemukan.</div>
                  )}
              </div>
            </div>
            <div>
              <Label required>Jabatan</Label>
              <Input
                value={selectedJabatan}
                onChange={(e) => setSelectedJabatan(e.target.value)}
                placeholder="Contoh: Ketua, Wakil Ketua, Sekjen, Anggota"
              />
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <Button variant="outline" size="sm" onClick={() => setShowAddOrgModal(false)}>
                Batal
              </Button>
              <Button size="sm" onClick={handleAddFromAlumni}>
                Simpan ke Struktur Organisasi
              </Button>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={confirmSave}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-primary-light text-primary">
            <Save className="h-6 w-6" />
          </div>
        }
        title="Simpan Pengaturan Portal?"
        description={
          maintenanceMode
            ? 'Portal dalam mode maintenance. Perubahan akan disimpan, namun portal tidak akan terlihat oleh publik hingga mode maintenance dinonaktifkan.'
            : 'Perubahan akan langsung tampil di portal publik IKA JTK POLBAN setelah disimpan.'
        }
        confirmLabel="Simpan"
        cancelLabel="Batal"
        onConfirm={handleSave}
        onCancel={() => setConfirmSave(false)}
      />

      {cropTarget && (
        <ImageCropModal
          open={cropModalOpen}
          imageUrl={cropTarget.url}
          title={cropTarget.title}
          aspectRatio={cropTarget.id === 'banner' ? 16 / 6 : cropTarget.id === 'logo' || cropTarget.id.startsWith('org_') ? 1 : 36 / 13}
          aspectRatioLabel={cropTarget.id === 'banner' ? 'Banner Tentang (16 : 6)' : cropTarget.id === 'logo' ? 'Logo Portal (1 : 1)' : cropTarget.id.startsWith('org_') ? 'Foto Pengurus (1 : 1)' : 'Portal Desktop (36 : 13)'}
          imageType={cropTarget?.imageType}
          onClose={() => setCropModalOpen(false)}
          onCropComplete={handleCroppedUpload}
        />
      )}

      {/* Global Fullscreen Loading Overlay during Uploads/Save to prevent Spamming */}
      {uploadingText ? (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/80 backdrop-blur-sm animate-fade-in select-none">
          <div className="bg-gray-900 border border-gray-700 px-8 py-6 rounded-2xl shadow-2xl flex flex-col items-center gap-4 max-w-sm text-center">
            <div className="relative flex items-center justify-center">
              <div className="w-14 h-14 rounded-full border-4 border-accent/20 border-t-accent animate-spin" />
            </div>
            <div>
              <h4 className="text-base font-bold text-white mb-1">Memproses Data</h4>
              <p className="text-sm text-gray-300 animate-pulse">{uploadingText}</p>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  )
}

interface NavTabBtnProps {
  icon: React.ReactNode
  label: string
  active: boolean
  onClick: () => void
}

function NavTabBtn({ icon, label, active, onClick }: NavTabBtnProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'w-full flex items-center gap-2 px-3 py-2.5 rounded-md text-sm font-medium transition-colors',
        active
          ? 'bg-primary-light text-primary'
          : 'text-gray-700 hover:bg-gray-50',
      )}
    >
      {icon}
      {label}
    </button>
  )
}



