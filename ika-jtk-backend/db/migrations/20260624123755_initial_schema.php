<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * Baseline schema untuk IKA JTK Backend (Phalcon + PostgreSQL).
 *
 * Ditulis dengan Phinx Table API. Memakai method change() sehingga
 * rollback dibuat otomatis oleh Phinx (tidak perlu down() manual).
 *
 * Skema mengikuti definisi model di app/models/ (sumber kebenaran).
 * Nama tabel & kolom case-sensitive mengikuti setSource() dan properti
 * camelCase pada masing-masing model.
 *
 * Catatan: ID adalah string(255) berisi UUID/hex yang di-generate di
 * level model (lihat beforeValidationOnCreate), bukan auto-increment —
 * karena itu setiap tabel memakai ['id' => false, 'primary_key' => 'id'].
 */
final class InitialSchema extends AbstractMigration
{
    public function up(): void
    {
        // --- Admin ---
        $this->table('Admin', ['id' => false, 'primary_key' => 'id'])
            ->addColumn('id', 'string', ['limit' => 255])
            ->addColumn('nama', 'string', ['limit' => 255])
            ->addColumn('email', 'string', ['limit' => 255])
            ->addColumn('username', 'string', ['limit' => 255])
            ->addColumn('password', 'string', ['limit' => 255])
            ->addColumn('role', 'string', ['limit' => 50, 'default' => 'Super Admin', 'null' => true])
            ->addColumn('avatarUrl', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addIndex('email', ['unique' => true])
            ->addIndex('username', ['unique' => true])
            ->create();

        // --- Alumni ---
        $this->table('Alumni', ['id' => false, 'primary_key' => 'id'])
            ->addColumn('id', 'string', ['limit' => 255])
            ->addColumn('nama', 'string', ['limit' => 255])
            ->addColumn('angkatan', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('tanggalLahir', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('jenisKelamin', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('email', 'string', ['limit' => 255])
            ->addColumn('username', 'string', ['limit' => 255])
            ->addColumn('password', 'string', ['limit' => 255])
            ->addColumn('status', 'string', ['limit' => 50, 'default' => 'Pending', 'null' => true])
            ->addColumn('emailVerified', 'boolean', ['default' => false, 'null' => true])
            ->addColumn('motto', 'text', ['null' => true])
            ->addColumn('avatarUrl', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('hp', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('linkedin', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('alamat', 'text', ['null' => true])
            ->addColumn('nomorIjazah', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('tahunLulus', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('ipk', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('ijazahFile', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('pekerjaan', 'jsonb', ['default' => '[]', 'null' => true])
            ->addColumn('prestasi', 'jsonb', ['default' => '[]', 'null' => true])
            ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addIndex('email', ['unique' => true])
            ->addIndex('username', ['unique' => true])
            ->create();

        // --- PendingRegistration ---
        $this->table('PendingRegistration', ['id' => false, 'primary_key' => 'id'])
            ->addColumn('id', 'string', ['limit' => 255])
            ->addColumn('nama', 'string', ['limit' => 255])
            ->addColumn('angkatan', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('tanggalLahir', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('jenisKelamin', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('email', 'string', ['limit' => 255])
            ->addColumn('username', 'string', ['limit' => 255])
            ->addColumn('password', 'string', ['limit' => 255])
            ->addColumn('verificationCode', 'string', ['limit' => 10, 'null' => true])
            ->addColumn('verificationCodeExpires', 'timestamp', ['null' => true])
            ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->create();

        // --- Alumni_Verification ---
        $this->table('Alumni_Verification', ['id' => false, 'primary_key' => 'id'])
            ->addColumn('id', 'string', ['limit' => 255])
            ->addColumn('alumniId', 'string', ['limit' => 255])
            ->addColumn('adminId', 'string', ['limit' => 255])
            ->addColumn('status', 'string', ['limit' => 50])
            ->addColumn('reason', 'text', ['null' => true])
            ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->create();

        // --- Berita ---
        $this->table('Berita', ['id' => false, 'primary_key' => 'id'])
            ->addColumn('id', 'string', ['limit' => 255])
            ->addColumn('noBerita', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('judul', 'string', ['limit' => 255])
            ->addColumn('konten', 'text')
            ->addColumn('bannerUrl', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('authorId', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('authorNama', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('authorRole', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('authorAvatarUrl', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('status', 'string', ['limit' => 50, 'default' => 'Draft', 'null' => true])
            ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addColumn('publishedAt', 'timestamp', ['null' => true])
            ->create();

        // --- Agenda ---
        $this->table('Agenda', ['id' => false, 'primary_key' => 'id'])
            ->addColumn('id', 'string', ['limit' => 255])
            ->addColumn('noEvent', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('judul', 'string', ['limit' => 255])
            ->addColumn('deskripsi', 'text')
            ->addColumn('bannerUrl', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('tanggalEvent', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('waktu', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('lokasi', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('authorId', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('authorNama', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('authorRole', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('authorAvatarUrl', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('status', 'string', ['limit' => 50, 'default' => 'Draft', 'null' => true])
            ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addColumn('publishedAt', 'timestamp', ['null' => true])
            ->create();

        // --- Loker ---
        $this->table('Loker', ['id' => false, 'primary_key' => 'id'])
            ->addColumn('id', 'string', ['limit' => 255])
            ->addColumn('noLoker', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('posisi', 'string', ['limit' => 255])
            ->addColumn('namaPerusahaan', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('websitePerusahaan', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('logoUrl', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('jenisPekerjaan', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('tipeLokasi', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('kota', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('deskripsi', 'text', ['null' => true])
            ->addColumn('skemaPelamaran', 'string', ['limit' => 50, 'default' => 'internal', 'null' => true])
            ->addColumn('linkExternal', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('formLamaran', 'jsonb', ['default' => '[]', 'null' => true])
            ->addColumn('authorId', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('authorNama', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('authorRole', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('authorAvatarUrl', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('status', 'string', ['limit' => 50, 'default' => 'Draft', 'null' => true])
            ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addColumn('publishedAt', 'timestamp', ['null' => true])
            ->addColumn('pelamar', 'jsonb', ['default' => '[]', 'null' => true])
            ->create();

        // --- Testimoni ---
        $this->table('Testimoni', ['id' => false, 'primary_key' => 'id'])
            ->addColumn('id', 'string', ['limit' => 255])
            ->addColumn('alumniId', 'string', ['limit' => 255])
            ->addColumn('alumniNama', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('alumniAngkatan', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('alumniAvatarUrl', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('isi', 'text')
            ->addColumn('visibility', 'string', ['limit' => 50, 'default' => 'public', 'null' => true])
            ->addColumn('status', 'string', ['limit' => 50, 'default' => 'Pending', 'null' => true])
            ->addColumn('submittedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addColumn('reviewedAt', 'timestamp', ['null' => true])
            ->create();

        // --- Election ---
        $this->table('Election', ['id' => false, 'primary_key' => 'id'])
            ->addColumn('id', 'string', ['limit' => 255])
            ->addColumn('judul', 'string', ['limit' => 255])
            ->addColumn('deskripsi', 'text', ['null' => true])
            ->addColumn('periodeStart', 'timestamp', ['null' => true])
            ->addColumn('periodeEnd', 'timestamp', ['null' => true])
            ->addColumn('status', 'string', ['limit' => 50, 'default' => 'Draft', 'null' => true])
            ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->create();

        // --- Candidate ---
        $this->table('Candidate', ['id' => false, 'primary_key' => 'id'])
            ->addColumn('id', 'string', ['limit' => 255])
            ->addColumn('electionId', 'string', ['limit' => 255])
            ->addColumn('alumniId', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('nama', 'string', ['limit' => 255])
            ->addColumn('angkatan', 'string', ['limit' => 50, 'null' => true])
            ->addColumn('fotoUrl', 'string', ['limit' => 255, 'null' => true])
            ->addColumn('nomorUrut', 'integer', ['null' => true])
            ->addColumn('visi', 'text', ['null' => true])
            ->addColumn('misi', 'jsonb', ['default' => '[]', 'null' => true])
            ->addColumn('pengalaman', 'jsonb', ['default' => '[]', 'null' => true])
            ->addColumn('voteCount', 'integer', ['default' => 0, 'null' => true])
            ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->create();

        // --- VoteRecord ---
        // unique_vote: satu alumni hanya boleh memilih sekali per election
        $this->table('VoteRecord', ['id' => false, 'primary_key' => 'id'])
            ->addColumn('id', 'string', ['limit' => 255])
            ->addColumn('alumniId', 'string', ['limit' => 255])
            ->addColumn('electionId', 'string', ['limit' => 255])
            ->addColumn('candidateId', 'string', ['limit' => 255])
            ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->addIndex(['alumniId', 'electionId'], ['unique' => true, 'name' => 'unique_vote'])
            ->create();
    }

    public function down(): void
    {
        $tables = [
            'VoteRecord', 'Candidate', 'Election', 'Testimoni', 'Berita',
            'Loker', 'Agenda', 'OtpCodes', 'Alumni_Verification', 'PendingRegistration', 'Alumni', 'Admin'
        ];
        foreach ($tables as $table) {
            if ($this->hasTable($table)) {
                $this->table($table)->drop()->save();
            }
        }
    }
}
