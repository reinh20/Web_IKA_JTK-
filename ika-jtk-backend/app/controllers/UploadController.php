<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;

class UploadController extends Controller
{
    private const TYPES = [
        'general'  => ['prefix' => 'general',  'acl' => 'public-read', 'ext' => ['jpg', 'jpeg', 'png', 'pdf', 'xlsx', 'xls', 'doc', 'docx', 'csv', 'mp4'], 'label' => 'general'],
        'avatar'   => ['prefix' => 'avatar',   'acl' => 'public-read', 'ext' => ['jpg', 'jpeg', 'png'],           'label' => 'avatar'],
        'document' => ['prefix' => 'document', 'acl' => 'public-read', 'ext' => ['pdf', 'jpg', 'jpeg', 'png'],    'label' => 'document'],
        'ijazah'   => ['prefix' => 'ijazah',   'acl' => 'private',     'ext' => ['pdf', 'jpg', 'jpeg', 'png'],    'label' => 'ijazah'],
    ];

    private const MIME_MAP = [
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png'  => 'image/png',
        'webp' => 'image/webp',
        'pdf'  => 'application/pdf',
    ];

    public function upload()
    {
        return $this->handleUpload('general');
    }

    public function avatar()
    {
        return $this->handleUpload('avatar');
    }

    public function document()
    {
        return $this->handleUpload('document');
    }

    public function ijazah()
    {
        return $this->handleUpload('ijazah');
    }

    private function handleUpload(string $type)
    {
        try {
            if (!$this->request->hasFiles()) {
                $this->response->setStatusCode(400);
                return ['error' => 'File tidak ditemukan di payload'];
            }
            // Deteksi payload yang melebihi post_max_size: body kosong padahal
            // client mengirim multipart. PHP membuang $_FILES & $_POST saat ini.
            $contentLength = (int) $this->request->getHeader('CONTENT_LENGTH');
            if ($contentLength > 0 && empty($_POST) && empty($_FILES)) {
                $this->response->setStatusCode(413);
                return ['error' => 'Ukuran file terlalu besar untuk diunggah (melebihi batas server). Kompres gambar atau naikkan post_max_size/upload_max_filesize.'];
            }

            if ($this->request->hasFiles() !== true) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tidak ada file yang diunggah. Pastikan field bernama "file" terkirim sebagai multipart/form-data.'];
            }

            $files = $this->request->getUploadedFiles();
            if (empty($files)) {
                $this->response->setStatusCode(400);
                return ['error' => 'File tidak ditemukan di payload'];
            }

            $cfg = self::TYPES[$type] ?? null;
            if ($cfg === null) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tipe upload tidak valid'];
            }

            $file = $files[0];

            $maxSize = ($type === 'avatar') ? (5 * 1024 * 1024) : (10 * 1024 * 1024);
            if ($file->getSize() > $maxSize) {
                $this->response->setStatusCode(413);
                $labelMb = ($type === 'avatar') ? '5MB' : '10MB';
                return ['error' => "Ukuran file melebihi batas maksimal {$labelMb}."];
            }

            $ext  = strtolower($file->getExtension() ?: 'bin');

            if (!in_array($ext, $cfg['ext'], true)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Format file ' . $cfg['label'] . ' tidak valid'];
            }

            $body = file_get_contents($file->getTempName());
            if ($body === false) {
                $this->response->setStatusCode(500);
                return ['error' => 'Gagal membaca file yang diunggah'];
            }

            $mime = self::MIME_MAP[$ext] ?? ($file->getRealType() ?: 'application/octet-stream');

            /** @var \App\Services\ImageProcessorService $imageProcessor */
            $imageProcessor = $this->di->getShared('imageProcessor');

            // Optimasi gambar (jika tipe gambar) untuk menyeragamkan ukuran & meminimalisir size
            if (in_array($ext, ['jpg', 'jpeg', 'png', 'webp'], true)) {
                try {
                    $maxWidth = $type === 'avatar' ? 1200 : 1920;
                    $optimized = $imageProcessor->optimizeImage($body, $ext, $maxWidth, 95);
                    $body = $optimized['body'];
                    $mime = $optimized['mime'];
                    $ext = $optimized['ext'];
                } catch (\Throwable $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

                    error_log('Gagal optimasi gambar ' . $file->getName() . ': ' . $e->getMessage());
                    // Fallback to original body if optimization fails
                }
            }

            $originalName = pathinfo($file->getName(), PATHINFO_FILENAME);
            $safeName = preg_replace('/[^a-zA-Z0-9_\-]/', '_', $originalName);

            $baseName = uniqid($type . '_') . '___' . $safeName;
            $key  = $cfg['prefix'] . '/' . $baseName . '.' . $ext;

            /** @var \App\Services\SpacesStorageService $spaces */
            $spaces = $this->di->getShared('spaces');
            $result = $spaces->upload($key, $body, $mime, $cfg['acl']);

            $thumbnailUrl = null;
            if ($cfg['acl'] === 'public-read' && in_array($ext, ['jpg', 'jpeg', 'png', 'webp'], true)) {
                try {
                    /** @var \App\Services\ImageProcessorService $imageProcessor */
                    $imageProcessor = $this->di->getShared('imageProcessor');
                    $thumb = $imageProcessor->generateThumbnail($body, $ext);
                    $thumbKey = $cfg['prefix'] . '/' . $baseName . '_thumb.' . $thumb['ext'];
                    $thumbnailUrl = $spaces->upload($thumbKey, $thumb['body'], $thumb['mime'], $cfg['acl']);
                } catch (\Throwable $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

                    error_log('Thumbnail generation gagal untuk ' . $key . ': ' . $e->getMessage());
                }
            }

            $this->response->setStatusCode(200);
            return [
                'message'      => 'Upload berhasil',
                'url'          => $result,
                'thumbnailUrl' => $thumbnailUrl,
                'key'          => $key,
                'private'      => $cfg['acl'] === 'private',
            ];
        } catch (\Throwable $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

            error_log('Kesalahan Upload: ' . $e->getMessage());
            $this->response->setStatusCode(500);
            return ['error' => 'Terjadi kesalahan sistem saat mengunggah file. Silakan coba beberapa saat lagi.'];
        }
    }

    private function uploadErrorMessage($code)
    {
        switch ($code) {
            case UPLOAD_ERR_INI_SIZE:
                return 'File melebihi batas upload_max_filesize server.';
            case UPLOAD_ERR_FORM_SIZE:
                return 'File melebihi batas ukuran yang diizinkan form.';
            case UPLOAD_ERR_PARTIAL:
                return 'File hanya terunggah sebagian.';
            case UPLOAD_ERR_NO_FILE:
                return 'Tidak ada file yang dikirim.';
            case UPLOAD_ERR_NO_TMP_DIR:
                return 'Folder temporary server tidak ditemukan.';
            case UPLOAD_ERR_CANT_WRITE:
                return 'Server gagal menulis file ke disk.';
            default:
                return 'Kesalahan upload tidak dikenal (kode ' . $code . ').';
        }
    }
}
