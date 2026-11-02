import { useNavigate, useParams } from 'react-router-dom'
import { useRef, useState, useEffect } from 'react'
import { Upload, Save } from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Input, Label } from '@/components/ui/Input'
import { RichTextEditor } from '@/components/ui/RichTextEditor'
import { Button } from '@/components/ui/Button'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { ImageCropModal } from '@/components/ui/ImageCropModal'
import { TagInput } from '@/components/ui/TagInput'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { getFileUrl } from '@/lib/utils'
import { useImageCropUpload } from '@/lib/useImageCropUpload'
import { getFriendlyErrorMessage } from '../../utils/errorHandler'
import { formatFileName } from '../../utils/file';

function toDatetimeLocal(iso: string | null | undefined) {
  if (!iso) return ''
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

export function AgendaFormPage() {
  const navigate = useNavigate()
  const { id } = useParams()
  const isEdit = Boolean(id)

  const [judul, setJudul] = useState('')
  const [deskripsi, setDeskripsi] = useState('')
  const [tanggalWaktu, setTanggalWaktu] = useState('')
  const [lokasi, setLokasi] = useState('')
  const [bannerName, setBannerName] = useState<string>('')
  const [bannerUrl, setBannerUrl] = useState<string | null>(null)
  const [bannerThumbnailUrl, setBannerThumbnailUrl] = useState<string | null>(null)
  const [tags, setTags] = useState<string>('')
  const [confirmDraft, setConfirmDraft] = useState(false)
  const [confirmPublish, setConfirmPublish] = useState(false)
  const [isLoading, setIsLoading] = useState(isEdit)
  const fileRef = useRef<HTMLInputElement>(null)
  const { cropModalOpen, cropTarget, startCrop, closeCrop, uploadCroppedWithMeta, cropLoadingOverlay } = useImageCropUpload()

  useEffect(() => {
    if (isEdit) {
      api.get(`/admin/agenda/${id}`)
        .then((res) => {
          setJudul(res.data.judul)
          setDeskripsi(res.data.deskripsi)
          setTanggalWaktu(toDatetimeLocal(res.data.tanggalEvent))
          setLokasi(res.data.lokasi)
          if (res.data.tags) setTags(res.data.tags)
          if (res.data.bannerUrl) {
            const fileName = formatFileName(res.data.bannerUrl) || 'banner.jpg'
            setBannerName(fileName)
            setBannerUrl(res.data.bannerUrl)
          }
          if (res.data.bannerThumbnailUrl) setBannerThumbnailUrl(res.data.bannerThumbnailUrl)
        })
        .catch(() => {
          toast('Gagal memuat agenda', 'error')
          navigate('/admin/agenda')
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
    startCrop({ id: 'banner', url: localUrl, title: 'Potong Banner Agenda', maxSizeMb: 5, maxDimension: 1080, imageType: f.type })
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
        deskripsi,
        tags,
        tanggalEvent: new Date(tanggalWaktu).toISOString(),
        lokasi,
        status: publishMode ? 'Published' : 'Draft',
        bannerUrl: bannerUrl ?? null,
        bannerThumbnailUrl: bannerUrl ? (bannerThumbnailUrl ?? bannerUrl) : null,
      }

      if (isEdit) {
        await api.put(`/admin/agenda/${id}`, payload)
      } else {
        await api.post('/admin/agenda', payload)
      }

      toast(
        publishMode
          ? `Agenda "${judul.slice(0, 30)}..." berhasil dipublish`
          : `Agenda "${judul.slice(0, 30)}..." disimpan sebagai draft`,
        'success'
      )
      navigate('/admin/agenda')
    } catch (error: any) {
      setIsLoading(false)
      toast(getFriendlyErrorMessage(error, 'Gagal menyimpan agenda'), 'error')
    }
  }

  const formInvalid =
    judul.trim().length === 0 ||
    deskripsi.trim().length === 0 ||
    tanggalWaktu.length === 0 ||
    lokasi.trim().length === 0

  if (isLoading) return <div className="p-10">Loading...</div>

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Agenda', to: '/admin/agenda' },
          { label: isEdit ? 'Edit Agenda' : 'Tambah Agenda' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">
        {isEdit ? 'Edit Agenda' : 'Tambah Agenda'}
      </h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_300px] gap-6 items-start">
        <div className="min-w-0">
          <SectionCard title="Form Agenda">
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
                <Label required>Judul Agenda</Label>
                <Input
                  placeholder="Masukkan Judul Agenda..."
                  value={judul}
                  onChange={(e) => setJudul(e.target.value)}
                />
              </div>

              <div>
                <Label required>Deskripsi Agenda</Label>
                <RichTextEditor
                  minHeight={240}
                  placeholder="Masukkan Deskripsi Agenda..."
                  value={deskripsi}
                  onChange={setDeskripsi}
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label required>Tanggal & Waktu</Label>
                  <Input
                    type="datetime-local"
                    value={tanggalWaktu}
                    min={toDatetimeLocal(new Date().toISOString())}
                    onChange={(e) => setTanggalWaktu(e.target.value)}
                  />
                </div>
                <div>
                  <Label required>Lokasi/Alamat</Label>
                  <Input
                    placeholder="Masukkan Lokasi/Alamat"
                    value={lokasi}
                    onChange={(e) => setLokasi(e.target.value)}
                  />
                </div>
              </div>

              <div>
                <Label>Tags (SEO & Metadata)</Label>
                <TagInput
                  placeholder="Contoh: webinar, reuni, karir (ketik lalu tekan koma atau enter)"
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
                Publish Agenda
              </Button>
              <button
                type="button"
                onClick={() => navigate('/admin/agenda')}
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
            : 'Agenda akan disimpan sebagai draft dan tidak akan muncul di halaman publik hingga kamu mempublikasikannya.'
        }
        confirmLabel="Simpan Draft"
        cancelLabel="Batal"
        onConfirm={() => submit(false)}
        onCancel={() => setConfirmDraft(false)}
      />

      <ConfirmDialog
        open={confirmPublish}
        title="Publish Agenda Sekarang?"
        description="Agenda akan langsung tampil di website portal alumni. Pastikan semua informasi sudah final."
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
          aspectRatioLabel="Banner Agenda (16 : 9)"
          imageType={cropTarget?.imageType}
          onClose={closeCrop}
          onCropComplete={handleBannerCropComplete}
        />
      )}
      {cropLoadingOverlay}
    </div>
  )
}



