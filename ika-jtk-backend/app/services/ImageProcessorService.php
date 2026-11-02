<?php

namespace App\Services;

use RuntimeException;

class ImageProcessorService
{
    public function optimizeImage(string $body, string $ext, int $maxWidth = 1920, int $quality = 85): array
    {
        if (!function_exists('imagecreatefromstring')) {
            throw new RuntimeException('GD extension tidak tersedia');
        }

        $src = @imagecreatefromstring($body);
        if ($src === false) {
            throw new RuntimeException('File bukan image valid');
        }

        $srcW = imagesx($src);
        $srcH = imagesy($src);
        if ($srcW <= 0 || $srcH <= 0) {
            imagedestroy($src);
            throw new RuntimeException('Dimensi image tidak valid');
        }

        if ($srcW <= $maxWidth) {
            $dstW = $srcW;
            $dstH = $srcH;
            $dst = imagecreatetruecolor($dstW, $dstH);
            
            // Handle transparency for PNG/WebP if we want to preserve it, but we are converting to JPEG mostly or preserving?
            // Wait, the prompt says "penyeragaman resize foto", standardizing to JPEG is usually best for size unless it's a transparent logo.
            // Let's preserve PNG as PNG if possible, or just convert to WebP?
            // I'll convert everything to WebP for best compression and quality!
        } else {
            $dstW = $maxWidth;
            $dstH = (int) round($srcH * ($maxWidth / $srcW));
            $dst = imagecreatetruecolor($dstW, $dstH);
        }

        // Preserve transparency
        if (in_array(strtolower($ext), ['png', 'webp'])) {
            imagealphablending($dst, false);
            imagesavealpha($dst, true);
            $transparent = imagecolorallocatealpha($dst, 255, 255, 255, 127);
            imagefill($dst, 0, 0, $transparent);
        } else {
            $white = imagecolorallocate($dst, 255, 255, 255);
            imagefill($dst, 0, 0, $white);
        }

        imagecopyresampled($dst, $src, 0, 0, 0, 0, $dstW, $dstH, $srcW, $srcH);

        ob_start();
        $finalExt = strtolower($ext);
        if ($finalExt === 'png') {
            imagepng($dst, null, 6); // level 6 compression for faster processing
            $mime = 'image/png';
        } elseif ($finalExt === 'webp') {
            imagewebp($dst, null, $quality);
            $mime = 'image/webp';
        } else {
            imagejpeg($dst, null, $quality);
            $finalExt = 'jpg';
            $mime = 'image/jpeg';
        }
        $out = ob_get_clean();

        imagedestroy($src);
        imagedestroy($dst);

        if ($out === false || $out === '') {
            throw new RuntimeException('Gagal encode image yang dioptimasi');
        }

        return [
            'body' => $out,
            'mime' => $mime,
            'ext'  => $finalExt,
        ];
    }

    public function generateThumbnail(string $body, string $ext, int $maxWidth = 320, int $quality = 65): array
    {
        if (!function_exists('imagecreatefromstring')) {
            throw new RuntimeException('GD extension tidak tersedia');
        }

        $src = @imagecreatefromstring($body);
        if ($src === false) {
            throw new RuntimeException('File bukan image valid');
        }

        $srcW = imagesx($src);
        $srcH = imagesy($src);
        if ($srcW <= 0 || $srcH <= 0) {
            imagedestroy($src);
            throw new RuntimeException('Dimensi image tidak valid');
        }

        if ($srcW <= $maxWidth) {
            $dstW = $srcW;
            $dstH = $srcH;
        } else {
            $dstW = $maxWidth;
            $dstH = (int) round($srcH * ($maxWidth / $srcW));
        }

        $dst = imagecreatetruecolor($dstW, $dstH);
        
        // Preserve transparency
        if (strtolower($ext) === 'png') {
            imagealphablending($dst, false);
            imagesavealpha($dst, true);
            $transparent = imagecolorallocatealpha($dst, 255, 255, 255, 127);
            imagefill($dst, 0, 0, $transparent);
        } else {
            $white = imagecolorallocate($dst, 255, 255, 255);
            imagefill($dst, 0, 0, $white);
        }

        imagecopyresampled($dst, $src, 0, 0, 0, 0, $dstW, $dstH, $srcW, $srcH);

        ob_start();
        $finalExt = strtolower($ext);
        if ($finalExt === 'png') {
            $ok = imagepng($dst, null, 6);
            $mime = 'image/png';
        } else {
            $ok = imagejpeg($dst, null, $quality);
            $finalExt = 'jpg';
            $mime = 'image/jpeg';
        }
        $out = ob_get_clean();

        imagedestroy($src);
        imagedestroy($dst);

        if (!$ok || $out === false || $out === '') {
            throw new RuntimeException('Gagal encode thumbnail');
        }

        return [
            'body' => $out,
            'mime' => $mime,
            'ext'  => $finalExt,
        ];
    }
}
