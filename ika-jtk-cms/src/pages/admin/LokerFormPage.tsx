import { useNavigate, useParams } from 'react-router-dom'
import { useRef, useState, useEffect } from 'react'
import { formatFileName } from '../../utils/file'
import { Upload, Save, Plus, Trash2, X, Paperclip } from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Input, Label } from '@/components/ui/Input'
import { RichTextEditor } from '@/components/ui/RichTextEditor'
import { Select } from '@/components/ui/Select'
import { SearchableSelect } from '@/components/ui/SearchableSelect'
import { Button } from '@/components/ui/Button'
import { RadioGroup } from '@/components/ui/RadioGroup'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { ImageCropModal } from '@/components/ui/ImageCropModal'
import { TagInput } from '@/components/ui/TagInput'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { getFileUrl } from '@/lib/utils'
import { useImageCropUpload } from '@/lib/useImageCropUpload'
import { INDONESIA_CITIES } from '@/lib/indonesiaCities'
import type {
  FormFieldType,
  FormLamaranField,
  JenisPekerjaan,
  SkemaPelamaran,
  TipeLokasi,
} from '@/types/loker'

const JENIS_PEKERJAAN: JenisPekerjaan[] = ['Full Time', 'Part Time', 'Kontrak', 'Magang', 'Freelance']
const TIPE_LOKASI: TipeLokasi[] = ['Onsite', 'Remote', 'Hybrid']
const KOTA_OPTIONS = INDONESIA_CITIES.map(c => ({ value: c, label: c }))

function uid() {
  return Math.random().toString(36).slice(2, 10)
}

export function LokerFormPage() {
  const navigate = useNavigate()
  const { id } = useParams()
  const isEdit = Boolean(id)

  const [posisi, setPosisi] = useState('')
  const [namaPerusahaan, setNamaPerusahaan] = useState('')
  const [website, setWebsite] = useState('')
  const [logoName, setLogoName] = useState<string>('')
  const [logoPreviewUrl, setLogoPreviewUrl] = useState<string | null>(null)
  const [logoThumbnailUrl, setLogoThumbnailUrl] = useState<string | null>(null)
  const [tags, setTags] = useState('')
  const [jenisPekerjaan, setJenisPekerjaan] = useState<JenisPekerjaan>('Full Time')
  const [tipeLokasi, setTipeLokasi] = useState<TipeLokasi>('Onsite')
  const [kota, setKota] = useState('')
  const [deskripsi, setDeskripsi] = useState('')
  const [skemaPelamaran, setSkemaPelamaran] = useState<SkemaPelamaran>('internal')
  const [linkExternal, setLinkExternal] = useState('')
  const [formFields, setFormFields] = useState<FormLamaranField[]>([
    { id: uid(), label: 'Ekspetasi Gaji', tipe: 'text', required: false },
  ])
  const [confirmDraft, setConfirmDraft] = useState(false)
  const [confirmPublish, setConfirmPublish] = useState(false)
  const [isLoading, setIsLoading] = useState(isEdit)
  const fileRef = useRef<HTMLInputElement>(null)
  const { cropModalOpen, cropTarget, startCrop, closeCrop, uploadCroppedWithMeta, cropLoadingOverlay } = useImageCropUpload()
  const previewFileRefs = useRef<Record<string, HTMLInputElement | null>>({})
  const [previewFiles, setPreviewFiles] = useState<Record<string, File>>({})

  useEffect(() => {
    if (isEdit) {
      api.get(`/admin/loker/${id}`)
        .then((res) => {
          setPosisi(res.data.posisi)
          setNamaPerusahaan(res.data.namaPerusahaan)
          setWebsite(res.data.websitePerusahaan || '')
          setJenisPekerjaan(res.data.jenisPekerjaan)
          setTipeLokasi(res.data.tipeLokasi)
          setKota(res.data.kota)
          setDeskripsi(res.data.deskripsi)
          if (res.data.tags) setTags(res.data.tags)
          setSkemaPelamaran(res.data.skemaPelamaran)
          setLinkExternal(res.data.linkExternal || '')
          if (res.data.formLamaran) setFormFields(res.data.formLamaran)
          if (res.data.logoUrl) {
            const fileName = formatFileName(res.data.logoUrl) || 'logo.jpg'
            setLogoName(fileName)
            setLogoPreviewUrl(res.data.logoUrl)
          }
          if (res.data.logoThumbnailUrl) setLogoThumbnailUrl(res.data.logoThumbnailUrl)
        })
        .catch(() => {
          toast('Gagal memuat loker', 'error')
          navigate('/admin/loker')
        })
        .finally(() => setIsLoading(false))
    }
  }, [id, isEdit, navigate])

  const handlePickFile = () => fileRef.current?.click()
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (!f) return

    const validExts = ['jpg', 'jpeg', 'png', 'svg']
    const ext = f.name.split('.').pop()?.toLowerCase() || ''
    if (!validExts.includes(ext)) {
      toast('Format file tidak didukung. Gunakan JPG, PNG, atau SVG.', 'error')
      e.target.value = ''
      return
    }
    const localUrl = URL.createObjectURL(f)
    startCrop({ id: 'logo', url: localUrl, title: 'Potong Logo Perusahaan', maxSizeMb: 5, maxDimension: 1080, imageType: f.type })
    if (e.target) e.target.value = ''
  }

  const handleLogoCropComplete = async (cropFile: File) => {
    const res = await uploadCroppedWithMeta(cropFile)
    if (res && res.url) {
      setLogoPreviewUrl(res.url)
      setLogoName(cropFile.name)
      setLogoThumbnailUrl(res.thumbnailUrl || res.url)
    } else {
      toast('Gagal mengunggah logo hasil potong', 'error')
    }
  }
  const handlePreviewPick = (id: string) => previewFileRefs.current[id]?.click()
  const handlePreviewChange = (id: string, e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (f) {
      if (f.size > 5 * 1024 * 1024) {
        toast('Ukuran file maksimal 5MB', 'error')
        e.target.value = ''
        return
      }

      const validExts = ['jpg', 'jpeg', 'png', 'svg']
      const ext = f.name.split('.').pop()?.toLowerCase() || ''
      if (!validExts.includes(ext)) {
        toast('Format file tidak didukung. Gunakan JPG, PNG, atau SVG.', 'error')
        e.target.value = ''
        return
      }
      setPreviewFiles((m) => ({ ...m, [id]: f }))
      updateField(id, { fileName: f.name })
    }
  }

  const updateField = (id: string, patch: Partial<FormLamaranField>) =>
    setFormFields((list) => list.map((f) => (f.id === id ? { ...f, ...patch } : f)))

  const addField = () =>
    setFormFields((list) => [...list, { id: uid(), label: '', tipe: 'text' }])

  const removeField = (id: string) =>
    setFormFields((list) => list.filter((f) => f.id !== id))

  const submit = async (publishMode: boolean) => {
    if (publishMode) setConfirmPublish(false)
    else setConfirmDraft(false)

    try {
      setIsLoading(true)

      const payload: any = {
        posisi,
        namaPerusahaan,
        websitePerusahaan: website,
        jenisPekerjaan,
        tipeLokasi,
        kota,
        deskripsi,
        tags,
        skemaPelamaran,
        linkExternal,
        status: publishMode ? 'Published' : 'Draft',
      }
      if (logoPreviewUrl) {
        payload.logoUrl = logoPreviewUrl
        payload.logoThumbnailUrl = logoThumbnailUrl ?? logoPreviewUrl
      } else {
        payload.logoUrl = null
        payload.logoThumbnailUrl = null
      }

      // Upload field files
      const finalFormFields = [...formFields]
      for (const f of finalFormFields) {
        if (f.tipe === 'file' && previewFiles[f.id]) {
          const fd = new FormData()
          fd.append('file', previewFiles[f.id])
          try {
            const res = await api.post('/upload', fd, {
              headers: { 'Content-Type': 'multipart/form-data' }
            })
            f.fileUrl = res.data.url
          } catch (e) {
            console.error('Upload failed for field', f.id)
          }
        }
      }
      payload.formLamaran = finalFormFields

      if (isEdit) {
        await api.put(`/admin/loker/${id}`, payload)
      } else {
        await api.post('/admin/loker', payload)
      }

      toast(
        publishMode
          ? `Loker "${posisi}" berhasil dipublish`
          : `Loker "${posisi}" disimpan sebagai draft`,
        'success'
      )
      navigate('/admin/loker')
    } catch (error) {
      setIsLoading(false)
      toast('Gagal menyimpan loker', 'error')
    }
  }

  const formInvalid =
    posisi.trim().length === 0 ||
    namaPerusahaan.trim().length === 0 ||
    deskripsi.trim().length === 0 ||
    kota.length === 0 ||
    (skemaPelamaran === 'external' && linkExternal.trim().length === 0)

  if (isLoading) return <div className="p-10">Loading...</div>

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Loker', to: '/admin/loker' },
          { label: isEdit ? 'Edit Loker' : 'Tambah Loker' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">
        {isEdit ? 'Edit Loker' : 'Tambah Loker'}
      </h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_300px] gap-6 items-start">
        <div className="min-w-0 space-y-6">
          <SectionCard title="Form Loker">
            <div className="space-y-5">
              <div>
                <Label required>Posisi</Label>
                <Input
                  placeholder="Masukkan Posisi"
                  value={posisi}
                  onChange={(e) => setPosisi(e.target.value)}
                />
              </div>
              <div>
                <Label required>Nama Perusahaan</Label>
                <Input
                  placeholder="Masukkan Nama Perusahaan"
                  value={namaPerusahaan}
                  onChange={(e) => setNamaPerusahaan(e.target.value)}
                />
              </div>
              <div>
                <Label>Website Perusahaan</Label>
                <Input
                  placeholder="https://contoh.com"
                  value={website}
                  onChange={(e) => setWebsite(e.target.value)}
                />
              </div>
              <div>
                <Label>Logo Perusahaan</Label>
                {logoPreviewUrl && (
                  <div className="mb-3">
                    <img 
                      src={logoPreviewUrl.startsWith('blob:') ? logoPreviewUrl : getFileUrl(logoPreviewUrl)} 
                      alt="Logo Preview" 
                      className="h-24 w-auto rounded-md object-contain border border-gray-200"
                    />
                  </div>
                )}
                <div className="flex items-stretch gap-2">
                  <div className="flex-1 h-10 rounded-md border border-gray-300 bg-white px-3 flex items-center text-sm text-gray-500 truncate">
                    {logoName || 'Tidak Ada File'}
                  </div>
                  <Button
                    variant="outline"
                    onClick={handlePickFile}
                    rightIcon={<Upload className="h-4 w-4" />}
                  >
                    Pilih File
                  </Button>
                  <input
                    ref={fileRef}
                    type="file"
                    accept=".jpeg,.jpg,.png,.svg"
                    className="hidden"
                    onChange={handleFileChange}
                  />
                </div>
                <p className="mt-1.5 text-xs text-gray-500">
                  File yang didukung: .jpeg, .jpg, .png | Maks. 5MB (Rekomendasi: 1080x1080px)
                </p>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <Label required>Jenis Pekerjaan</Label>
                  <Select
                    value={jenisPekerjaan}
                    onChange={(e) => setJenisPekerjaan(e.target.value as JenisPekerjaan)}
                  >
                    {JENIS_PEKERJAAN.map((j) => (
                      <option key={j} value={j}>{j}</option>
                    ))}
                  </Select>
                </div>
                <div>
                  <Label required>Lokasi</Label>
                  <Select
                    value={tipeLokasi}
                    onChange={(e) => setTipeLokasi(e.target.value as TipeLokasi)}
                  >
                    {TIPE_LOKASI.map((t) => (
                      <option key={t} value={t}>{t}</option>
                    ))}
                  </Select>
                </div>
                <div>
                  <Label required>Kota</Label>
                  <SearchableSelect 
                    value={kota} 
                    onChange={setKota}
                    options={KOTA_OPTIONS}
                    placeholder="Pilih Kota"
                    searchPlaceholder="Cari kota..."
                  />
                </div>
              </div>
              <div>
                <Label required>Deskripsi Pekerjaan</Label>
                <RichTextEditor
                  minHeight={400}
                  placeholder="Tulis deskripsi pekerjaan, tanggung jawab, kualifikasi, jam kerja, benefit, dan cara melamar..."
                  value={deskripsi}
                  onChange={setDeskripsi}
                />
                <p className="mt-1.5 text-xs text-gray-500">
                  Gunakan heading & bullet list dari toolbar untuk memisahkan bagian (mis. Tanggung Jawab, Kualifikasi, Benefit).
                </p>
              </div>
              <div>
                <Label required>Skema Pelamaran</Label>
                <RadioGroup
                  name="skemaPelamaran"
                  value={skemaPelamaran}
                  onChange={(v) => setSkemaPelamaran(v as SkemaPelamaran)}
                  options={[
                    { value: 'internal', label: 'via Website IKAJTK' },
                    { value: 'external', label: 'via Link External' },
                  ]}
                />
                {skemaPelamaran === 'external' && (
                  <div className="mt-3">
                    <Input
                      placeholder="https://career.contoh.com/posisi"
                      value={linkExternal}
                      onChange={(e) => setLinkExternal(e.target.value)}
                    />
                  </div>
                )}
              </div>
              <div>
                <Label>Tags (SEO & Metadata)</Label>
                <TagInput
                  placeholder="Contoh: software engineer, remote, fulltime (ketik lalu tekan koma atau enter)"
                  value={tags}
                  onChange={setTags}
                />
              </div>
            </div>
          </SectionCard>

          {skemaPelamaran === 'internal' && (
            <SectionCard title="Form Lamaran">
              <p className="text-sm text-gray-500 mb-4">
                Atur input tambahan yang harus diisi pelamar saat melamar lewat website IKAJTK.
              </p>
              <div className="space-y-4">
                {formFields.map((f) => (
                  <div
                    key={f.id}
                    className="rounded-md border border-gray-200 bg-gray-50/50 p-4 space-y-3"
                  >
                    <div className="grid grid-cols-1 md:grid-cols-[2fr_1fr_auto] gap-3 items-end">
                      <div>
                        <Label>Informasi Tambahan</Label>
                        <Input
                          placeholder="Contoh: Ekspetasi Gaji"
                          value={f.label}
                          onChange={(e) =>
                            updateField(f.id, { label: e.target.value })
                          }
                        />
                      </div>
                      <div>
                        <Label>Tipe Input</Label>
                        <Select
                          value={f.tipe}
                          onChange={(e) =>
                            updateField(f.id, {
                              tipe: e.target.value as FormFieldType,
                              options: e.target.value === 'option' ? f.options ?? ['', ''] : undefined,
                            })
                          }
                        >
                          <option value="text">Teks</option>
                          <option value="longtext">Teks Panjang</option>
                          <option value="number">Number</option>
                          <option value="option">Option</option>
                          <option value="file">File</option>
                        </Select>
                      </div>
                      <Button
                        variant="danger"
                        size="sm"
                        onClick={() => removeField(f.id)}
                        rightIcon={<Trash2 className="h-3.5 w-3.5" />}
                      >
                        Hapus
                      </Button>
                    </div>
                    {f.tipe === 'text' && (
                      <div className="space-y-1.5">
                        <Label className="text-xs">Preview / Default Value</Label>
                        <Input 
                          placeholder={f.label || 'Jawaban singkat'}
                          value={f.defaultValue || ''}
                          onChange={(e) => updateField(f.id, { defaultValue: e.target.value })}
                        />
                      </div>
                    )}
                    {f.tipe === 'longtext' && (
                      <div className="space-y-1.5">
                        <Label className="text-xs">Preview / Default Value</Label>
                        <textarea
                          rows={3}
                          placeholder={f.label || 'Jawaban panjang'}
                          className="block w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-primary focus:ring-primary focus:outline-none"
                          value={f.defaultValue || ''}
                          onChange={(e) => updateField(f.id, { defaultValue: e.target.value })}
                        />
                      </div>
                    )}
                    {f.tipe === 'number' && (
                      <div className="space-y-1.5">
                        <Label className="text-xs">Preview / Default Value</Label>
                        <Input 
                          type="number" 
                          placeholder="0"
                          value={f.defaultValue || ''}
                          onChange={(e) => updateField(f.id, { defaultValue: e.target.value })}
                        />
                      </div>
                    )}
                    {f.tipe === 'file' && (
                      <div className="space-y-1.5">
                        <Label className="text-xs">Lampiran / Template File (Opsional)</Label>
                        <div className="flex items-center gap-3 rounded-md border border-gray-200 bg-white p-3">
                          <div className="h-10 w-10 rounded-md bg-primary/10 inline-flex items-center justify-center shrink-0">
                            <Paperclip className="h-5 w-5 text-primary" />
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-semibold text-gray-900 truncate">
                              {previewFiles[f.id]?.name || f.fileName || 'Pilih file lampiran / template'}
                            </p>
                            <p className="text-xs text-gray-500 truncate">
                              PDF / DOC / JPG / PNG
                            </p>
                          </div>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handlePreviewPick(f.id)}
                            rightIcon={<Upload className="h-3.5 w-3.5" />}
                          >
                            Pilih File
                          </Button>
                          <input
                            ref={(el) => {
                              previewFileRefs.current[f.id] = el
                            }}
                            type="file"
                            accept=".pdf,.doc,.docx,.jpg,.jpeg,.png"
                            className="hidden"
                            onChange={(e) => handlePreviewChange(f.id, e)}
                          />
                        </div>
                      </div>
                    )}
                    {f.tipe === 'option' && (
                      <div className="pl-2 border-l-2 border-accent/30 ml-1 space-y-2">
                        <Label className="text-xs">Option</Label>
                        {(f.options ?? []).map((opt, idx) => (
                          <div key={idx} className="flex items-center gap-2">
                            <Input
                              placeholder={`Opsi ${idx + 1}`}
                              value={opt}
                              onChange={(e) => {
                                const next = [...(f.options ?? [])]
                                next[idx] = e.target.value
                                updateField(f.id, { options: next })
                              }}
                            />
                            <button
                              type="button"
                              onClick={() => {
                                const next = (f.options ?? []).filter((_, i) => i !== idx)
                                updateField(f.id, { options: next })
                              }}
                              className="h-10 w-10 inline-flex items-center justify-center rounded-md text-gray-400 hover:bg-gray-100 hover:text-danger"
                              aria-label="Remove option"
                            >
                              <X className="h-4 w-4" />
                            </button>
                          </div>
                        ))}
                        <button
                          type="button"
                          onClick={() =>
                            updateField(f.id, {
                              options: [...(f.options ?? []), ''],
                            })
                          }
                          className="inline-flex items-center gap-1 text-sm font-semibold text-primary hover:underline"
                        >
                          <Plus className="h-3.5 w-3.5" /> Tambah Opsi
                        </button>
                      </div>
                    )}
                  </div>
                ))}
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={addField}
                  leftIcon={<Plus className="h-4 w-4" />}
                >
                  Tambah Input
                </Button>
              </div>
            </SectionCard>
          )}
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
                Publish Loker
              </Button>
              <button
                type="button"
                onClick={() => navigate('/admin/loker')}
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
            : 'Loker akan disimpan sebagai draft dan tidak muncul di halaman publik hingga kamu mempublikasikannya.'
        }
        confirmLabel="Simpan Draft"
        cancelLabel="Batal"
        onConfirm={() => submit(false)}
        onCancel={() => setConfirmDraft(false)}
      />

      <ConfirmDialog
        open={confirmPublish}
        title="Publish Loker Sekarang?"
        description="Loker akan langsung tampil di website portal alumni dan dapat dilamar."
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
          aspectRatio={1}
          aspectRatioLabel="Logo Perusahaan (1 : 1)"
          imageType={cropTarget?.imageType}
          onClose={closeCrop}
          onCropComplete={handleLogoCropComplete}
        />
      )}
      {cropLoadingOverlay}
    </div>
  )
}



