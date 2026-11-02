import React, { useState, useEffect, useRef } from 'react'
import { Scissors, Check, X, RotateCcw, Move } from 'lucide-react'
import { Button } from './Button'

interface ImageCropModalProps {
  open: boolean
  imageUrl: string
  onClose: () => void
  onCropComplete: (file: File) => Promise<void> | void
  title?: string
  aspectRatio?: number
  aspectRatioLabel?: string
  imageType?: string
}

interface CropBox {
  x: number
  y: number
  width: number
  height: number
}

export function ImageCropModal({
  open,
  imageUrl,
  onClose,
  onCropComplete,
  title = 'Potong Gambar Slide',
  aspectRatio = 36 / 13,
  aspectRatioLabel = 'Portal Desktop (36 : 13)',
  imageType,
}: ImageCropModalProps) {
  const [imgObj, setImgObj] = useState<HTMLImageElement | null>(null)
  const [aspect, setAspect] = useState<number | null>(aspectRatio)
  const [crop, setCrop] = useState<CropBox>({ x: 0, y: 0, width: 100, height: 100 })
  const [imgDisplaySize, setImgDisplaySize] = useState<{ width: number; height: number }>({ width: 0, height: 0 })
  const [loading, setLoading] = useState<boolean>(true)
  const [processing, setProcessing] = useState<boolean>(false)

  const containerRef = useRef<HTMLDivElement>(null)
  const dragInfoRef = useRef<{
    type: 'move' | 'se' | 'sw' | 'ne' | 'nw'
    startX: number
    startY: number
    startCrop: CropBox
  } | null>(null)

  // Load image
  useEffect(() => {
    if (!open || !imageUrl) {
      setImgObj(null)
      return
    }
    setLoading(true)
    setImgObj(null)
    const img = new Image()
    // Do not set crossOrigin for blob/data URLs as it breaks CORS in Chrome/Edge
    if (!imageUrl.startsWith('blob:') && !imageUrl.startsWith('data:')) {
      img.crossOrigin = 'anonymous'
    }
    img.onload = () => {
      if (img.naturalWidth > 2048 || img.naturalHeight > 2048) {
        try {
          const maxDim = 2048
          const scale = Math.min(maxDim / img.naturalWidth, maxDim / img.naturalHeight)
          const canvas = document.createElement('canvas')
          canvas.width = Math.round(img.naturalWidth * scale)
          canvas.height = Math.round(img.naturalHeight * scale)
          const ctx = canvas.getContext('2d')
          if (ctx) {
            ctx.drawImage(img, 0, 0, canvas.width, canvas.height)
            const scaledImg = new Image()
            scaledImg.onload = () => {
              setImgObj(scaledImg)
              setLoading(false)
            }
            scaledImg.src = canvas.toDataURL('image/jpeg', 0.9)
            return
          }
        } catch (_) {}
      }
      setImgObj(img)
      setLoading(false)
    }
    img.onerror = () => {
      // fallback if crossOrigin fails
      const img2 = new Image()
      img2.onload = () => {
        setImgObj(img2)
        setLoading(false)
      }
      img2.onerror = () => {
        setLoading(false)
      }
      img2.src = imageUrl
    }
    img.src = imageUrl
  }, [open, imageUrl])

  // Calculate display size and default crop
  const initCropForAspect = (targetAspect: number | null, dw: number, dh: number) => {
    if (!dw || !dh) return
    if (!targetAspect) {
      // free aspect ratio defaults to 80% box
      const cw = dw * 0.8
      const ch = dh * 0.8
      setCrop({ x: (dw - cw) / 2, y: (dh - ch) / 2, width: cw, height: ch })
      return
    }
    let cw = dw * 0.85
    let ch = cw / targetAspect
    if (ch > dh * 0.85) {
      ch = dh * 0.85
      cw = ch * targetAspect
    }
    setCrop({
      x: Math.max(0, (dw - cw) / 2),
      y: Math.max(0, (dh - ch) / 2),
      width: cw,
      height: ch,
    })
  }

  useEffect(() => {
    if (!imgObj || !containerRef.current) return
    const rect = containerRef.current.getBoundingClientRect()
    const maxW = rect.width - 32
    const maxH = rect.height - 32

    const natW = imgObj.naturalWidth
    const natH = imgObj.naturalHeight
    if (!natW || !natH) return

    let dw = natW
    let dh = natH
    const scale = Math.min(maxW / natW, maxH / natH)
    if (scale < 1) {
      dw = natW * scale
      dh = natH * scale
    }

    setImgDisplaySize({ width: dw, height: dh })
    setAspect(aspectRatio)
    initCropForAspect(aspectRatio, dw, dh)
  }, [imgObj, open, aspectRatio])

  // Mouse / Touch Dragging
  const handleMouseDown = (e: React.MouseEvent, type: 'move' | 'se' | 'sw' | 'ne' | 'nw') => {
    e.preventDefault()
    dragInfoRef.current = {
      type,
      startX: e.clientX,
      startY: e.clientY,
      startCrop: { ...crop },
    }
  }

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!dragInfoRef.current || !imgDisplaySize.width) return
      const { type, startX, startY, startCrop } = dragInfoRef.current
      const dx = e.clientX - startX
      const dy = e.clientY - startY
      const maxW = imgDisplaySize.width
      const maxH = imgDisplaySize.height

      if (type === 'move') {
        const nx = Math.max(0, Math.min(maxW - startCrop.width, startCrop.x + dx))
        const ny = Math.max(0, Math.min(maxH - startCrop.height, startCrop.y + dy))
        setCrop({ ...startCrop, x: nx, y: ny })
      } else if (type === 'se') {
        let nw = Math.max(40, Math.min(maxW - startCrop.x, startCrop.width + dx))
        let nh = aspect ? nw / aspect : Math.max(40, Math.min(maxH - startCrop.y, startCrop.height + dy))
        if (aspect && startCrop.y + nh > maxH) {
          nh = maxH - startCrop.y
          nw = nh * aspect
        }
        if (aspect && startCrop.x + nw > maxW) {
          nw = maxW - startCrop.x
          nh = nw / aspect
        }
        setCrop({ ...startCrop, width: nw, height: nh })
      }
    }

    const handleMouseUp = () => {
      dragInfoRef.current = null
    }

    if (open) {
      window.addEventListener('mousemove', handleMouseMove)
      window.addEventListener('mouseup', handleMouseUp)
    }
    return () => {
      window.removeEventListener('mousemove', handleMouseMove)
      window.removeEventListener('mouseup', handleMouseUp)
    }
  }, [open, aspect, imgDisplaySize])

  const handleApplyCrop = () => {
    if (!imgObj || !imgDisplaySize.width || processing) return
    setProcessing(true)

    const scaleX = imgObj.naturalWidth / imgDisplaySize.width
    const scaleY = imgObj.naturalHeight / imgDisplaySize.height

    const canvas = document.createElement('canvas')
    const cropNatX = Math.max(0, Math.min(imgObj.naturalWidth, Math.round(crop.x * scaleX)))
    const cropNatY = Math.max(0, Math.min(imgObj.naturalHeight, Math.round(crop.y * scaleY)))
    const cropNatW = Math.max(1, Math.min(imgObj.naturalWidth - cropNatX, Math.round(crop.width * scaleX)))
    const cropNatH = Math.max(1, Math.min(imgObj.naturalHeight - cropNatY, Math.round(crop.height * scaleY)))

    canvas.width = cropNatW
    canvas.height = cropNatH
    const ctx = canvas.getContext('2d')

    if (ctx) {
      ctx.drawImage(
        imgObj,
        cropNatX,
        cropNatY,
        cropNatW,
        cropNatH,
        0,
        0,
        cropNatW,
        cropNatH
      )

      const isPng = imageType?.toLowerCase().includes('png') ?? false
      const exportType = isPng ? 'image/png' : 'image/jpeg'
      const ext = isPng ? 'png' : 'jpg'

      canvas.toBlob(
        async (blob) => {
          if (blob) {
            const file = new File([blob], `cropped_${Date.now()}.${ext}`, {
              type: exportType,
              lastModified: Date.now(),
            })
            try {
              await Promise.resolve(onCropComplete(file))
            } finally {
              setProcessing(false)
              onClose()
            }
          } else {
            setProcessing(false)
          }
        },
        exportType,
        0.95
      )
    } else {
      setProcessing(false)
    }
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
      <div className="relative w-full max-w-4xl bg-gray-900 rounded-2xl shadow-2xl border border-gray-700 overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-800 bg-gray-900/90">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-lg bg-accent/20 text-accent">
              <Scissors className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-white">{title}</h3>
              <p className="text-xs text-gray-400">Sesuaikan rasio dan area potong gambar sebelum diunggah</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-gray-400 hover:text-white hover:bg-gray-800 transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Aspect Ratio Display (Locked) */}
        <div className="flex flex-wrap items-center justify-between gap-3 px-6 py-3 bg-gray-800/60 border-b border-gray-800 text-xs text-gray-300">
          <div className="flex items-center gap-2">
            <span className="font-semibold text-gray-400">Rasio Potong:</span>
            <span className="px-3 py-1.5 rounded-md font-medium bg-accent text-white shadow-sm flex items-center gap-1.5">
              <span>{aspectRatioLabel}</span>
              <span className="text-[10px] bg-white/20 px-1.5 py-0.5 rounded">Default / Terkunci</span>
            </span>
          </div>

          <button
            onClick={() => {
              if (imgDisplaySize.width && imgDisplaySize.height) {
                initCropForAspect(aspectRatio, imgDisplaySize.width, imgDisplaySize.height)
              }
            }}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-md bg-gray-700 hover:bg-gray-600 text-gray-300 transition-colors"
          >
            <RotateCcw className="h-3.5 w-3.5" />
            Reset Posisi
          </button>
        </div>

        {/* Viewport Area */}
        <div
          ref={containerRef}
          className="relative flex-1 min-h-[380px] md:min-h-[460px] bg-gray-950 flex items-center justify-center overflow-hidden p-4 select-none"
        >
          {loading || processing ? (
            <div className="absolute inset-0 z-50 flex flex-col items-center justify-center gap-3 bg-gray-950/85 backdrop-blur-sm animate-fade-in text-center p-6 pointer-events-auto">
              <div className="w-14 h-14 rounded-full border-4 border-accent/20 border-t-accent animate-spin" />
              <div className="space-y-1">
                <h4 className="text-base font-bold text-white">
                  {processing ? 'Mengunggah Gambar Hasil Potong...' : 'Memuat Gambar...'}
                </h4>
                <p className="text-xs text-gray-400 animate-pulse">
                  {processing ? 'Mohon tunggu, sedang memproses dan mengunggah ke server...' : 'Menyiapkan area potong gambar...'}
                </p>
              </div>
            </div>
          ) : null}
          {!loading && imgObj && imgDisplaySize.width ? (
            <div
              className="relative shadow-2xl"
              style={{
                width: imgDisplaySize.width,
                height: imgDisplaySize.height,
              }}
            >
              {/* Underlying Image */}
              <img
                src={imgObj.src}
                alt="Original"
                className="w-full h-full object-contain pointer-events-none opacity-40"
              />

              {/* Cropped Active Area (clipped) */}
              <div
                className="absolute overflow-hidden"
                style={{
                  left: crop.x,
                  top: crop.y,
                  width: crop.width,
                  height: crop.height,
                }}
              >
                <img
                  src={imgObj.src}
                  alt="Cropped focus"
                  className="absolute max-w-none pointer-events-none"
                  style={{
                    width: imgDisplaySize.width,
                    height: imgDisplaySize.height,
                    left: -crop.x,
                    top: -crop.y,
                  }}
                />
              </div>

              {/* Crop Frame / Grid */}
              <div
                className="absolute border-2 border-white cursor-move flex items-center justify-center shadow-[0_0_0_9999px_rgba(0,0,0,0.65)]"
                style={{
                  left: crop.x,
                  top: crop.y,
                  width: crop.width,
                  height: crop.height,
                }}
                onMouseDown={(e) => handleMouseDown(e, 'move')}
              >
                {/* Rule of thirds lines */}
                <div className="absolute inset-0 grid grid-cols-3 grid-rows-3 pointer-events-none">
                  <div className="border-r border-b border-white/30" />
                  <div className="border-r border-b border-white/30" />
                  <div className="border-b border-white/30" />
                  <div className="border-r border-b border-white/30" />
                  <div className="border-r border-b border-white/30" />
                  <div className="border-b border-white/30" />
                  <div className="border-r border-white/30" />
                  <div className="border-r border-white/30" />
                  <div />
                </div>

                {/* Move Hint Icon */}
                <div className="p-2 rounded-full bg-black/40 text-white/80 pointer-events-none backdrop-blur-sm">
                  <Move className="h-5 w-5" />
                </div>

                {/* Resize Handle SE */}
                <div
                  className="absolute -bottom-2 -right-2 w-5 h-5 bg-accent border-2 border-white rounded-full cursor-se-resize flex items-center justify-center shadow-md z-10"
                  onMouseDown={(e) => {
                    e.stopPropagation()
                    handleMouseDown(e, 'se')
                  }}
                />
              </div>
            </div>
          ) : null}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between px-6 py-4 border-t border-gray-800 bg-gray-900/90">
          <div className="text-xs text-gray-400">
            Geser kotak potong atau tarik titik sudut kanan bawah untuk mengatur ukuran.
          </div>
          <div className="flex items-center gap-3">
            <Button variant="outline" onClick={onClose} disabled={processing}>
              Batal
            </Button>
            <Button
              onClick={handleApplyCrop}
              disabled={processing || loading}
              leftIcon={processing ? undefined : <Check className="h-4 w-4" />}
              className="bg-accent hover:bg-accent/90 text-white font-semibold"
            >
              {processing ? 'Memproses...' : 'Potong & Unggah'}
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}

