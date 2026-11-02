import { useState, useCallback, useEffect, type ReactNode } from 'react'
import api from './api'
import { compressImage } from '../utils/imageCompressor'

export interface CropTarget {
  id: string
  url: string
  title?: string
  maxSizeMb?: number
  maxDimension?: number
  imageType?: string
}

export function useImageCropUpload() {
  const [cropModalOpen, setCropModalOpen] = useState(false)
  const [cropTarget, setCropTarget] = useState<CropTarget | null>(null)
  const [uploadingText, setUploadingText] = useState('')

  useEffect(() => {
    if (uploadingText) {
      document.body.style.cursor = 'wait'
    } else {
      document.body.style.cursor = 'default'
    }
    return () => {
      document.body.style.cursor = 'default'
    }
  }, [uploadingText])

  const startCrop = useCallback((target: CropTarget) => {
    setCropTarget(target)
    setCropModalOpen(true)
  }, [])

  const closeCrop = useCallback(() => {
    setCropModalOpen(false)
    setCropTarget(null)
  }, [])

  const uploadCropped = useCallback(async (file: File, endpoint = '/upload'): Promise<string | null> => {
    setUploadingText('Mengunggah gambar hasil potong...')
    try {
      let finalFile = file
      // Memaksa kompresi kilat (seperti di Portal) sebelum upload
      setUploadingText('Mengompresi gambar (kualitas tinggi)...')
      finalFile = await compressImage(file, cropTarget?.maxSizeMb || 5, cropTarget?.maxDimension || 1080)
      
      setUploadingText('Mengunggah gambar hasil kompresi...')
      const formData = new FormData()
      formData.append('file', finalFile)
      const res = await api.post(endpoint, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      if (!res.data?.url) {
        throw new Error('Respons server tidak valid (URL gambar kosong)')
      }
      return res.data.url
    } catch (err: any) {
      console.error('Upload cropped error:', err)
      const errMsg = err?.response?.data?.error || err?.message || 'Gagal mengunggah gambar. Periksa koneksi atau ukuran file Anda.'
      alert(`⚠️ Upload Gagal:\n${errMsg}`)
      return null
    } finally {
      setUploadingText('')
    }
  }, [cropTarget])

  const uploadCroppedWithMeta = useCallback(async (file: File, endpoint = '/upload'): Promise<{ url: string; thumbnailUrl?: string } | null> => {
    setUploadingText('Mengunggah gambar hasil potong...')
    try {
      let finalFile = file
      // Memaksa kompresi kilat (seperti di Portal) sebelum upload
      setUploadingText('Mengompresi gambar (kualitas tinggi)...')
      finalFile = await compressImage(file, cropTarget?.maxSizeMb || 5, cropTarget?.maxDimension || 1080)
      
      setUploadingText('Mengunggah gambar hasil kompresi...')
      const formData = new FormData()
      formData.append('file', finalFile)
      const res = await api.post(endpoint, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      if (!res.data?.url) {
        throw new Error('Respons server tidak valid (URL gambar kosong)')
      }
      return {
        url: res.data.url,
        thumbnailUrl: res.data.thumbnailUrl || res.data.url,
      }
    } catch (err: any) {
      console.error('Upload cropped with meta error:', err)
      const errMsg = err?.response?.data?.error || err?.message || 'Gagal mengunggah gambar. Periksa koneksi atau ukuran file Anda.'
      alert(`⚠️ Upload Gagal:\n${errMsg}`)
      return null
    } finally {
      setUploadingText('')
    }
  }, [cropTarget])

  const cropLoadingOverlay: ReactNode | null = uploadingText ? (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/80 backdrop-blur-sm animate-fade-in select-none cursor-wait">
      <div className="bg-gray-900 border border-gray-700 px-8 py-6 rounded-2xl shadow-2xl flex flex-col items-center gap-4 max-w-sm text-center cursor-wait">
        <div className="relative flex items-center justify-center">
          <div className="w-14 h-14 rounded-full border-4 border-accent/20 border-t-accent animate-spin" />
        </div>
        <div>
          <h4 className="text-base font-bold text-white mb-1">Memproses Data</h4>
          <p className="text-sm text-gray-300 animate-pulse">{uploadingText}</p>
        </div>
      </div>
    </div>
  ) : null

  return {
    cropModalOpen,
    cropTarget,
    uploadingText,
    startCrop,
    closeCrop,
    uploadCropped,
    uploadCroppedWithMeta,
    setUploadingText,
    cropLoadingOverlay,
  }
}
