import { useNavigate, useParams } from 'react-router-dom'
import { useRef, useState, useEffect } from 'react'
import { Upload, Save } from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Input, Label } from '@/components/ui/Input'
import { RichTextEditor } from '@/components/ui/RichTextEditor'
import { Button } from '@/components/ui/Button'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { SearchableSelect } from '@/components/ui/SearchableSelect'
import { ImageCropModal } from '@/components/ui/ImageCropModal'
import { TagInput } from '@/components/ui/TagInput'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { getFileUrl } from '@/lib/utils'
import { useImageCropUpload } from '@/lib/useImageCropUpload'
import { getFriendlyErrorMessage } from '../../utils/errorHandler'
import { formatFileName } from '../../utils/file';

type AlumniOption = { id: string; nama: string; angkatan: string }

export function BeritaFormPage() {
  const navigate = useNavigate()
  const { id } = useParams()
  const isEdit = Boolean(id)

  const [judul, setJudul] = useState('')
  const [konten, setKonten] = useState('')
  const [kategori, setKategori] = useState('Pengumuman')
  const kategoriOptions = ['Alumni', 'Karir', 'Inspirasi', 'Event', 'Pengabdian', 'Pengumuman', 'Akademik']
  const [bannerName, setBannerName] = useState<string>('')
  const [bannerUrl, setBannerUrl] = useState<string | null>(null)
  const [bannerThumbnailUrl, setBannerThumbnailUrl] = useState<string | null>(null)
  const [tags, setTags] = useState<string>('')
  const [highlightedAlumniId, setHighlightedAlumniId] = useState<string>('')
  const [alumniOptions, setAlumniOptions] = useState<AlumniOption[]>([])
  const [confirmDraft, setConfirmDraft] = useState(false)
  const [confirmPublish, setConfirmPublish] = useState(false)
  const [isLoading, setIsLoading] = useState(isEdit)
  const fileRef = useRef<HTMLInputElement>(null)
  const { cropModalOpen, cropTarget, startCrop, closeCrop, uploadCroppedWithMeta, cropLoadingOverlay } = useImageCropUpload()

  useEffect(() => {
    api.get('/admin/alumni?verified=true')
      .then((res) => {
        const list: AlumniOption[] = (res.data as Array<Record<string, unknown>>).map((a) => ({
          id: String(a.id ?? ''),
          nama: String(a.nama ?? ''),
          angkatan: String(a.angkatan ?? ''),
        }))
        setAlumniOptions(list)
      })
      .catch(() => {
        // Non-blocking: kalau fetch gagal, dropdown tetap render dengan pilihan kosong.
      })
  }, [])

  useEffect(() => {
    if (isEdit) {
      api.get(`/admin/berita/${id}`)
        .then((res) => {
          setJudul(res.data.judul)
          setKonten(res.data.konten)
          if (res.data.kategori) setKategori(res.data.kategori)
          if (res.data.tags) setTags(res.data.tags)
          if (res.data.bannerUrl) {
            const fileName = formatFileName(res.data.bannerUrl) || 'banner.jpg'
            setBannerName(fileName)
            setBannerUrl(res.data.bannerUrl)
          }
          if (res.data.bannerThumbnailUrl) setBannerThumbnailUrl(res.data.bannerThumbnailUrl)
          if (res.data.highlightedAlumniId) setHighlightedAlumniId(String(res.data.highlightedAlumniId))
        })
        .catch(() => {
          toast('Gagal memuat berita', 'error')
          navigate('/admin/berita')
        })
        .finally(() => setIsLoading(false))
    }
  }, [id, isEdit, navigate])

  const handlePickFile = () => fileRef.current?.click()
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (!f) return

    const validExts = ['jpg', 'jpeg', 'png']
    const ext = f.name.split('.').pop()?.toLowerCase() || ''
    if (!validExts.includes(ext)) {
      toast('Format file tidak didukung. Gunakan JPG atau PNG.', 'error')
      e.target.value = ''
      return
    }

    if (f.size > 5 * 1024 * 1024) {
      toast('Ukuran file maksimal 5MB', 'error')
      e.target.value = ''
      return
    }

    const localUrl = URL.createObjectURL(f)
    startCrop({ id: 'banner', url: localUrl, title: 'Potong Banner Berita', maxSizeMb: 5, maxDimension: 1080, imageType: f.type })
    if (e.target) e.target.value = ''
  }

  const handleBannerCropComplete = async (file: File) => {
    const res = await uploadCroppedWithMeta(file)
    if (res && res.url) {
      setBannerUrl(res.url)
      setBannerName(file.name)
      setBannerThumbnailUrl(res.thumbnailUrl || res.url)
    } else {
      toast('Gagal mengunggah gambar hasil potong', 'error')
    }
  }

  const submit = async (publishMode: boolean) => {
    if (publishMode) setConfirmPublish(false)
    else setConfirmDraft(false)

    try {
      setIsLoading(true)

      const payload: any = {
        judul,
        konten,
        kategori,
        tags,
        status: publishMode ? 'Published' : 'Draft',
        bannerUrl: bannerUrl ?? null,
        bannerThumbnailUrl: bannerUrl ? (bannerThumbnailUrl ?? bannerUrl) : null,
        highlightedAlumniId: kategori === 'Alumni' && highlightedAlumniId ? highlightedAlumniId : null,
      }

      if (isEdit) {
        await api.put(`/admin/berita/${id}`, payload)
      } else {
        await api.post('/admin/berita', payload)
      }

      toast(
        publishMode
          ? `Berita "${judul.slice(0, 30)}..." berhasil dipublish`
          : `Berita "${judul.slice(0, 30)}..." disimpan sebagai draft`,
        'success'
      )
      navigate('/admin/berita')
    } catch (error: any) {
      setIsLoading(false)
      toast(getFriendlyErrorMessage(error, 'Gagal menyimpan berita'), 'error')
    }
  }

  const formInvalid = judul.trim().length === 0 || konten.trim().length === 0 || !bannerUrl

  if (isLoading) return <div className="p-10">Loading...</div>

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Berita', to: '/admin/berita' },
          { label: isEdit ? 'Edit Berita' : 'Tambah Berita' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">
        {isEdit ? 'Edit Berita' : 'Tambah Berita'}
      </h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_300px] gap-6 items-start">
        <div className="min-w-0">
          <SectionCard title="Form Berita">
            <div className="space-y-5">
              <div>
                <Label required>Banner/Cover</Label>
                {bannerUrl && (
                  <div className="mb-3">
                    <img
                      src={bannerUrl.startsWith('blob:') ? bannerUrl : getFileUrl(bannerUrl)}
                      alt="Banner Preview"
                      className="h-40 w-auto rounded-md object-cover border border-gray-200"
                    />
                  </div>
                )}
                <div className="flex items-stretch gap-2">
                  <div className="flex-1 h-10 rounded-md border border-gray-300 bg-white px-3 flex items-center text-sm text-gray-500 truncate">
                    {bannerName || 'Tidak Ada File'}
                  </div>
                  <Button
                    variant="outline"
                    onClick={handlePickFile}
                    rightIcon={<Upload className="h-4 w-4" />}
                  >
                    {bannerUrl ? 'Ganti File' : 'Pilih File'}
                  </Button>
                  <input
                    ref={fileRef}
                    type="file"
                    accept=".jpeg,.jpg,.png"
                    className="hidden"
                    onChange={handleFileChange}
                  />
                </div>
                <p className="mt-1.5 text-xs text-gray-500">
                  File yang didukung: .jpeg, .jpg, .png | Maks. 5MB (Rekomendasi: 1920x1080px)
                </p>
              </div>

              <div>
                <Label required>Judul Berita</Label>
                <Input
                  placeholder="Masukkan Judul Berita..."
                  value={judul}
                  onChange={(e) => setJudul(e.target.value)}
                />
              </div>

              <div>
                <Label required>Kategori</Label>
                <select
                  value={kategori}
                  onChange={(e) => setKategori(e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-accent focus:ring-accent sm:text-sm h-10 px-3 bg-white border outline-none transition-colors"
                >
                  {kategoriOptions.map(opt => (
                    <option key={opt} value={opt}>{opt}</option>
                  ))}
                </select>
              </div>

              {kategori === 'Alumni' && (
                <div>
                  <Label>Alumni yang Disorot</Label>
                  <SearchableSelect
                    value={highlightedAlumniId}
                    onChange={setHighlightedAlumniId}
                    placeholder="Pilih alumni untuk banner featured..."
                    searchPlaceholder="Cari nama alumni..."
                    options={alumniOptions.map((a) => ({
                      value: a.id,
                      label: a.angkatan ? `${a.nama} — ${a.angkatan}` : a.nama,
                    }))}
                  />
                  <p className="mt-1.5 text-xs text-gray-500">
                    Alumni ini akan tampil di card oranye pada banner "Direktori Alumni" beserta tautan ke profilnya.
                  </p>
                </div>
              )}

              <div>
                <Label required>Berita</Label>
                <RichTextEditor
                  minHeight={400}
                  placeholder="Masukkan Konten Berita..."
                  value={konten}
                  onChange={setKonten}
                />
              </div>

              <div>
                <Label>Tags (SEO & Metadata)</Label>
                <TagInput
                  placeholder="Contoh: teknologi, alumni, seminar (ketik lalu tekan koma atau enter)"
                  value={tags}
                  onChange={setTags}
                />
              </div>
            </div>
          </SectionCard>
        </div>

        <aside className="lg:sticky lg:top-8">
          <SectionCard title="Action">
            <div className="space-y-3">
              <Button
                variant="outline"
                className="w-full"
                disabled={formInvalid}
                onClick={() => setConfirmDraft(true)}
                leftIcon={<Save className="h-4 w-4" />}
              >
                {isEdit ? 'Simpan Perubahan' : 'Simpan Draft'}
              </Button>
              <Button
                className="w-full"
                disabled={formInvalid}
                onClick={() => setConfirmPublish(true)}
              >
                Publish Berita
              </Button>
              <button
                type="button"
                onClick={() => navigate('/admin/berita')}
                className="w-full text-sm text-gray-500 hover:text-gray-800 mt-2"
              >
                Batal
              </button>
            </div>
          </SectionCard>
        </aside>
      </div>

      <ConfirmDialog
        open={confirmDraft}
        title={isEdit ? 'Simpan Perubahan?' : 'Simpan Sebagai Draft?'}
        description={
          isEdit
            ? 'Perubahan akan disimpan tetapi tidak akan langsung dipublish ke website.'
            : 'Berita akan disimpan sebagai draft dan tidak akan muncul di website hingga di-publish.'
        }
        confirmLabel="Simpan Draft"
        cancelLabel="Batal"
        onConfirm={() => submit(false)}
        onCancel={() => setConfirmDraft(false)}
      />

      <ConfirmDialog
        open={confirmPublish}
        title="Publish Berita Sekarang?"
        description="Berita akan langsung tampil di website portal alumni. Pastikan konten sudah final."
        confirmLabel="Publish"
        cancelLabel="Batal"
        onConfirm={() => submit(true)}
        onCancel={() => setConfirmPublish(false)}
      />

      {cropTarget && (
        <ImageCropModal
          open={cropModalOpen}
          imageUrl={cropTarget.url}
          title={cropTarget.title}
          aspectRatio={16 / 9}
          aspectRatioLabel="Banner Berita (16 : 9)"
          imageType={cropTarget?.imageType}
          onClose={closeCrop}
          onCropComplete={handleBannerCropComplete}
        />
      )}
      {cropLoadingOverlay}
    </div>
  )
}



