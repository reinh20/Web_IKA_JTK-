<?php

namespace App\Models;

use Phalcon\Mvc\Model;
use App\Traits\TracksStorageFields;
use App\Traits\LogsChanges;

class Alumni extends Model
{
    use TracksStorageFields;
    use LogsChanges;

    protected function auditEntityType(): string { return 'Alumni'; }

    public $id;
    public $noAlumni;
    public $nama;
    public $angkatan;
    public $tanggalLahir;
    public $jenisKelamin;
    public $email;
    public $username;
    public $password;
    public $status = 'PENDING';
    public $emailVerified = false;
    public $phoneVerified = false;
    
    public $motto;
    public $avatarUrl;
    public $hp;
    public $linkedin;
    public $alamat;
    public $nomorIjazah;
    public $tahunLulus;
    public $ipk;
    public $ijazahFile;
    public $pekerjaan = '[]';
    public $prestasi = '[]';
    public $keanggotaan = 'Alumni';
    
    public $emailVisibility = 'private';
    public $nomorHandphoneVisibility = 'private';
    public $alamatVisibility = 'private';
    
    public $createdAt;
    public $updatedAt;
    public $deletedAt;
    public $alumniGrafis;
    public $userAgreement = false;

    public function initialize()
    {
        $this->setSource("Alumni");
        $this->keepSnapshots(true);
    }

    protected function trackedStorageFields(): array
    {
        return ['avatarUrl', 'ijazahFile'];
    }

    public function beforeUpdate()
    {
        $this->cleanupOldStorageOnUpdate();
    }

    public function beforeDelete()
    {
        $this->cleanupAllStorageOnDelete();
    }

    public function beforeValidationOnCreate()
    {
        if (empty($this->id)) {
            $this->id = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
                mt_rand(0, 0xffff), mt_rand(0, 0xffff),
                mt_rand(0, 0xffff),
                mt_rand(0, 0x0fff) | 0x4000,
                mt_rand(0, 0x3fff) | 0x8000,
                mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
            );
        }
        $this->createdAt = date('Y-m-d H:i:s');
        $this->updatedAt = date('Y-m-d H:i:s');
    }

    public function beforeValidationOnUpdate()
    {
        $this->updatedAt = date('Y-m-d H:i:s');
    }

    /**
     * Generate nomor alumni berikutnya untuk tahun yang sesuai dengan createdAt.
     * Format: TIF{YY}{6-digit}. Suffix = MAX(existing) + 1 dalam tahun itu, atau 1 kalau kosong.
     * MAX+1 stabil terhadap soft/hard delete (tidak seperti COUNT).
     */
    public static function generateNextNoAlumni(string $createdAt): string
    {
        $yy = date('y', strtotime($createdAt));
        $prefix = 'TIF' . $yy;

        $di = \Phalcon\Di\Di::getDefault();
        $db = $di->getShared('db');
        $row = $db->fetchOne(
            'SELECT MAX(CAST(SUBSTRING("noAlumni" FROM 6) AS INTEGER)) AS max_suffix '
            . 'FROM "Alumni" WHERE "noAlumni" LIKE \'TIF%\''
        );

        $next = ($row && $row['max_suffix'] !== null) ? ((int) $row['max_suffix']) + 1 : 1;
        return $prefix . str_pad((string) $next, 6, '0', STR_PAD_LEFT);
    }
}
