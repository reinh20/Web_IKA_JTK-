<?php

namespace App\Services;

use Aws\S3\S3Client;
use Aws\S3\Exception\S3Exception;

class SpacesStorageService
{
    private ?S3Client $client = null;
    private string $bucket;
    private string $endpoint;
    private string $publicUrlBase;
    private bool $isConfigured = false;
    private string $localUploadDir;

    public function __construct(array $cfg)
    {
        $this->bucket        = $cfg['bucket'] ?? '';
        $this->endpoint      = rtrim($cfg['endpoint'] ?? '', '/');
        $this->publicUrlBase = rtrim($cfg['public_url'] ?? '', '/');

        $baseDir = defined('BASE_PATH') ? BASE_PATH : dirname(__DIR__, 2);
        $this->localUploadDir = rtrim($baseDir, '/\\') . '/public/uploads';

        $key    = $cfg['key'] ?? '';
        $secret = $cfg['secret'] ?? '';

        if (!empty($key) && !empty($secret)) {
            try {
                $this->client = new S3Client([
                    'version'                 => 'latest',
                    'region'                  => $cfg['region'] ?? 'sgp1',
                    'endpoint'                => $this->endpoint,
                    'use_path_style_endpoint' => false,
                    'credentials' => [
                        'key'    => $key,
                        'secret' => $secret,
                    ],
                ]);
                $this->isConfigured = true;
            } catch (\Exception $e) {
                error_log("Spaces init error: " . $e->getMessage());
                $this->isConfigured = false;
            }
        }
    }

    /**
     * Upload konten ke Spaces atau fallback ke local disk jika Spaces tidak dikonfigurasi.
     */
    public function upload(string $key, string $body, string $mime, string $acl = 'public-read'): string
    {
        if ($this->isConfigured && $this->client) {
            try {
                $this->client->putObject([
                    'Bucket'       => $this->bucket,
                    'Key'          => $key,
                    'Body'         => $body,
                    'ContentType'  => $mime,
                    'ACL'          => $acl,
                    'CacheControl' => 'public, max-age=31536000',
                ]);

                return $acl === 'public-read'
                    ? $this->publicUrlBase . '/' . $key
                    : $key;
            } catch (\Exception $e) {
                error_log("Spaces upload failed, falling back to local disk: " . $e->getMessage());
            }
        }

        // Fallback to local storage in public/uploads/
        $localPath = $this->localUploadDir . '/' . $key;
        $dir = dirname($localPath);
        if (!is_dir($dir)) {
            mkdir($dir, 0777, true);
        }
        file_put_contents($localPath, $body);

        $baseUrl = rtrim($_ENV['APP_URL'] ?? 'http://localhost:5000', '/');
        return $baseUrl . '/uploads/' . $key;
    }

    /**
     * Delete objek.
     */
    public function delete(string $keyOrUrl): bool
    {
        $key = $this->normalizeToKey($keyOrUrl);
        if (!$key) {
            return false;
        }

        if ($this->isConfigured && $this->client) {
            try {
                $this->client->deleteObject([
                    'Bucket' => $this->bucket,
                    'Key'    => $key,
                ]);
                return true;
            } catch (\Exception $e) {
                error_log("Spaces delete failed for {$key}: " . $e->getMessage());
            }
        }

        $localPath = $this->localUploadDir . '/' . $key;
        if (file_exists($localPath)) {
            @unlink($localPath);
            return true;
        }
        return false;
    }

    /**
     * Buat presigned GET URL atau fallback ke path lokal.
     */
    public function presignedGetUrl(string $key, int $ttl = 900): string
    {
        if ($this->isConfigured && $this->client) {
            try {
                $cmd = $this->client->getCommand('GetObject', [
                    'Bucket' => $this->bucket,
                    'Key'    => $key,
                ]);
                $req = $this->client->createPresignedRequest($cmd, "+{$ttl} seconds");
                return (string) $req->getUri();
            } catch (\Exception $e) {
                error_log("Spaces presignedGetUrl failed: " . $e->getMessage());
            }
        }
        $baseUrl = rtrim($_ENV['APP_URL'] ?? 'http://localhost:5000', '/');
        return $baseUrl . '/uploads/' . $key;
    }

    public function objectExists(string $key): bool
    {
        if ($this->isConfigured && $this->client) {
            try {
                $this->client->headObject(['Bucket' => $this->bucket, 'Key' => $key]);
                return true;
            } catch (\Exception $e) {
                // Check local
            }
        }
        return file_exists($this->localUploadDir . '/' . $key);
    }

    public function getPublicUrlBase(): string
    {
        return $this->publicUrlBase;
    }

    private function normalizeToKey(string $keyOrUrl): ?string
    {
        if ($keyOrUrl === '') {
            return null;
        }
        if ($this->publicUrlBase !== '' && str_starts_with($keyOrUrl, $this->publicUrlBase . '/')) {
            return substr($keyOrUrl, strlen($this->publicUrlBase) + 1);
        }
        
        $baseUrl = rtrim($_ENV['APP_URL'] ?? 'http://localhost:5000', '/');
        if (str_starts_with($keyOrUrl, $baseUrl . '/uploads/')) {
            return substr($keyOrUrl, strlen($baseUrl . '/uploads/'));
        }
        
        if (str_starts_with($keyOrUrl, '/uploads/')) {
            return substr($keyOrUrl, 9); // length of "/uploads/"
        }
        
        if (str_starts_with($keyOrUrl, 'http://') || str_starts_with($keyOrUrl, 'https://')) {
            return null;
        }
        if (str_starts_with($keyOrUrl, '/')) {
            return null;
        }
        return $keyOrUrl;
    }
}
