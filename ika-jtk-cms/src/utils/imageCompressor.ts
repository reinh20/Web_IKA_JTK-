export async function compressImage(file: File, maxSizeMb: number = 0.5, maxDim: number = 1080): Promise<File> {
  const maxSize = maxSizeMb * 1024 * 1024;

  const img = await new Promise<HTMLImageElement>((resolve, reject) => {
    const i = new Image();
    i.onload = () => resolve(i);
    i.onerror = () => reject(new Error('Gagal membaca gambar dari file yang dipilih'));
    i.src = URL.createObjectURL(file);
  });

  const srcW = img.naturalWidth;
  const srcH = img.naturalHeight;

  // 1. Fast Bypass: Jangan bypass kecuali file sudah sangat kecil (< 300KB)
  if ((file.type === 'image/jpeg' || file.type === 'image/png') && file.size <= 300 * 1024 && srcW <= maxDim && srcH <= maxDim) {
    return file;
  }

  // Hitung dimensi target proporsional
  const newW = srcW > srcH ? Math.min(srcW, maxDim) : Math.round(srcW * Math.min(srcH, maxDim) / srcH);
  const newH = srcW > srcH ? Math.round(srcH * Math.min(srcW, maxDim) / srcW) : Math.min(srcH, maxDim);

  const canvas = document.createElement('canvas');
  canvas.width = newW;
  canvas.height = newH;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Canvas context tidak tersedia');

  // 2. Hardware/GPU Acceleration: Gunakan createImageBitmap jika didukung browser agar kompresi super cepat
  try {
    if (typeof window.createImageBitmap === 'function') {
      const bitmap = await createImageBitmap(file, { resizeWidth: newW, resizeHeight: newH, resizeQuality: 'medium' });
      ctx.drawImage(bitmap, 0, 0);
      bitmap.close();
    } else {
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = 'medium';
      ctx.drawImage(img, 0, 0, newW, newH);
    }
  } catch {
    ctx.drawImage(img, 0, 0, newW, newH);
  }

  // Tentukan format output berdasarkan format asli (PNG -> PNG, lainnya -> JPEG)
  const isPng = file.type.toLowerCase().includes('png') || file.name.toLowerCase().endsWith('.png');
  const outMime = isPng ? 'image/png' : 'image/jpeg';
  const outExt = isPng ? 'png' : 'jpg';

  // 3. Encode dengan kualitas tinggi (0.80)
  const step1Blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, outMime, 0.80));
  if (step1Blob && step1Blob.size <= maxSize) {
    return new File([step1Blob], file.name.replace(/\.[^/.]+$/, "") + `.${outExt}`, { type: outMime, lastModified: Date.now() });
  }

  // Jika masih terlalu besar, turunkan kualitas (0.70)
  const step2Blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, outMime, 0.70));
  if (step2Blob && step2Blob.size <= maxSize) {
    return new File([step2Blob], file.name.replace(/\.[^/.]+$/, "") + `.${outExt}`, { type: outMime, lastModified: Date.now() });
  }

  const finalSizeMb = step2Blob ? (step2Blob.size / 1024 / 1024).toFixed(1) : (file.size / 1024 / 1024).toFixed(1);
  throw new Error(`File gambar terlalu besar setelah kompresi (${finalSizeMb}MB). Batas maksimal adalah ${maxSizeMb}MB.`);
}
