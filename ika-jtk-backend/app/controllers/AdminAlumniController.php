<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Alumni;
use App\Enums\AlumniStatus;

class AdminAlumniController extends Controller
{
    private function formatAlumni($alumni)
    {
        $data = $alumni->toArray();
        unset($data['password']);

        if (is_string($data['pekerjaan'])) {
            $data['pekerjaan'] = json_decode($data['pekerjaan'], true) ?: [];
        }
        if (is_string($data['prestasi'])) {
            $data['prestasi'] = json_decode($data['prestasi'], true) ?: [];
        }
        if (is_string($data['alumniGrafis'])) {
            $data['alumniGrafis'] = json_decode($data['alumniGrafis'], true) ?: null;
        }

        // Map hp to nomorHandphone for CMS compatibility
        if (isset($data['hp'])) {
            $data['nomorHandphone'] = $data['hp'];
        }

        // ijazahFile disimpan sebagai key mentah Spaces — presign on-demand agar admin bisa buka file private.
        if (!empty($data['ijazahFile'])
            && !str_starts_with($data['ijazahFile'], 'http://')
            && !str_starts_with($data['ijazahFile'], 'https://')
            && !str_starts_with($data['ijazahFile'], '/')
        ) {
            $data['ijazahFile'] = $this->di->getShared('spaces')->presignedGetUrl($data['ijazahFile'], 900);
        }
        
        if (isset($data['status'])) {
            $data['status'] = strtoupper($data['status']);
        }

        // Populate diterimaPada untuk alumni yang terverifikasi (APPROVED / ACTIVE)
        if (!empty($data['status']) && in_array(strtoupper($data['status']), ['APPROVED', 'ACTIVE'])) {
            $verif = \App\Models\AlumniVerification::findFirst([
                'conditions' => 'alumniId = ?0 AND status = ?1 AND deletedAt IS NULL',
                'bind'       => [$alumni->id, \App\Enums\AlumniStatus::APPROVED->value],
                'order'      => 'createdAt DESC'
            ]);
            if ($verif) {
                $data['diterimaPada'] = $verif->createdAt;
            } else {
                $data['diterimaPada'] = $alumni->updatedAt ?: $alumni->createdAt;
            }
        } else {
            $data['diterimaPada'] = null;
        }

        return $data;
    }

    private function getReadableError($messages)
    {
        if (empty($messages)) return 'Gagal menyimpan data.';
        $msg = (string) $messages[0];
        
        if (stripos($msg, 'email') !== false && stripos($msg, 'unique') !== false) {
            return 'Email sudah terdaftar. Silakan gunakan email lain.';
        }
        if (stripos($msg, 'username') !== false && stripos($msg, 'unique') !== false) {
            return 'Username sudah terdaftar.';
        }
        if (stripos($msg, 'required') !== false) {
            return 'Ada kolom wajib yang belum diisi (' . $msg . ').';
        }
        return 'Gagal menyimpan: ' . $msg;
    }

    public function index()
    {
        $verifiedOnly = $this->request->getQuery('verified') === 'true';
        $page = $this->request->getQuery('page', 'int');
        $limit = $this->request->getQuery('limit', 'int', 10);
        $search = trim($this->request->getQuery('search', 'string', ''));
        $tab = trim($this->request->getQuery('tab', 'string', 'semua'));

        $conditions = "status != 'UNVERIFIED'";
        if ($verifiedOnly) {
            $conditions = "status = 'APPROVED' OR status = 'ACTIVE'";
        }
        
        $baseConditions = "deletedAt IS NULL AND ($conditions)";
        $bind = [];

        // Apply tab filter if pagination is used (and verifiedOnly is false)
        if ($page !== null && !$verifiedOnly) {
            if ($tab === 'baru') {
                $baseConditions .= " AND status = 'PENDING'";
            } else {
                $baseConditions .= " AND status != 'PENDING'";
            }
        }

        if ($page !== null && $search !== '') {
            $baseConditions .= " AND (LOWER(nama) LIKE LOWER(:search_start:) OR LOWER(nama) LIKE LOWER(:search_space:) OR LOWER(email) LIKE LOWER(:search_any:))";
            $bind['search_start'] = $search . '%';
            $bind['search_space'] = '% ' . $search . '%';
            $bind['search_any'] = '%' . $search . '%';
        }

        $queryOptions = [
            'conditions' => $baseConditions,
            'bind' => $bind,
            'order' => 'createdAt DESC'
        ];

        if ($page !== null) {
            $total = \App\Models\Alumni::count([
                'conditions' => $baseConditions,
                'bind' => $bind
            ]);
            
            // counts for tabs
            $semuaCount = \App\Models\Alumni::count([
                'conditions' => "deletedAt IS NULL AND status != 'UNVERIFIED' AND status != 'PENDING'"
            ]);
            $baruCount = \App\Models\Alumni::count([
                'conditions' => "deletedAt IS NULL AND status = 'PENDING'"
            ]);

            $queryOptions['limit'] = $limit;
            $queryOptions['offset'] = ($page - 1) * $limit;
            
            $alumnis = \App\Models\Alumni::find($queryOptions);
            
            $result = [];
            foreach ($alumnis as $alumni) {
                if (strtoupper($alumni->status) === \App\Enums\AlumniStatus::APPROVED->value) {
                    $verification = \App\Models\AlumniVerification::findFirst([
                        'conditions' => 'alumniId = ?0',
                        'bind' => [$alumni->id],
                        'order' => 'createdAt DESC'
                    ]);
                    if ($verification && strtotime($verification->createdAt) <= strtotime('-5 minutes')) {
                        $alumni->status = \App\Enums\AlumniStatus::ACTIVE->value;
                        $alumni->save();
                    }
                }
                $result[] = $this->formatAlumni($alumni);
            }
            
            return [
                'data' => $result,
                'total' => $total,
                'page' => $page,
                'limit' => $limit,
                'semuaCount' => $semuaCount,
                'baruCount' => $baruCount
            ];
        }

        // Backward compatibility mode
        $alumnis = \App\Models\Alumni::find($queryOptions);
        $result = [];
        foreach ($alumnis as $alumni) {
            if (strtoupper($alumni->status) === \App\Enums\AlumniStatus::APPROVED->value) {
                $verification = \App\Models\AlumniVerification::findFirst([
                    'conditions' => 'alumniId = ?0',
                    'bind' => [$alumni->id],
                    'order' => 'createdAt DESC'
                ]);
                if ($verification && strtotime($verification->createdAt) <= strtotime('-5 minutes')) {
                    $alumni->status = \App\Enums\AlumniStatus::ACTIVE->value;
                    $alumni->save();
                }
            }
            $result[] = $this->formatAlumni($alumni);
        }
        return $result;
    }

    public function create()
    {
        $data = $this->request->getJsonRawBody(true);

        if (empty(trim($data['nama'] ?? ''))) {
            $this->response->setStatusCode(400);
            return ['error' => 'Nama wajib diisi'];
        }

        if (empty(trim($data['email'] ?? ''))) {
            $this->response->setStatusCode(400);
            return ['error' => 'Email wajib diisi'];
        }

        if (empty(trim((string)($data['angkatan'] ?? '')))) {
            $this->response->setStatusCode(400);
            return ['error' => 'Angkatan wajib diisi'];
        }

        if (empty(trim((string)($data['jenisKelamin'] ?? '')))) {
            $this->response->setStatusCode(400);
            return ['error' => 'Jenis kelamin wajib diisi'];
        }

        if (empty(trim((string)($data['nomorHandphone'] ?? $data['hp'] ?? '')))) {
            $this->response->setStatusCode(400);
            return ['error' => 'Nomor handphone wajib diisi'];
        }

        if (empty(trim((string)($data['keanggotaan'] ?? '')))) {
            $this->response->setStatusCode(400);
            return ['error' => 'Keanggotaan wajib diisi'];
        }

        $normalizedEmail = strtolower(trim($data['email']));
        $existingEmail = Alumni::findFirst(['conditions' => 'email = ?0', 'bind' => [$normalizedEmail]]);
        if ($existingEmail) {
            $this->response->setStatusCode(400);
            return ['error' => 'Email sudah terdaftar. Silakan gunakan email lain.'];
        }

        $usernameVal = trim((string)($data['username'] ?? ''));
        if (empty($usernameVal)) {
            $this->response->setStatusCode(400);
            return ['error' => 'Username wajib diisi'];
        }
        if (preg_match('/\s/', $usernameVal)) {
            $this->response->setStatusCode(400);
            return ['error' => 'Username tidak boleh mengandung spasi'];
        }
        $normalizedUsername = strtolower($usernameVal);
        $existingUsername = Alumni::findFirst(['conditions' => 'username = ?0', 'bind' => [$normalizedUsername]]);
        if ($existingUsername) {
            $this->response->setStatusCode(400);
            return ['error' => 'Username sudah terdaftar.'];
        }

        $alumni = new Alumni();
        $alumni->nama = trim($data['nama']);
        $alumni->angkatan = $data['angkatan'] ?? '';
        $alumni->tanggalLahir = $data['tanggalLahir'] ?? null;

        if ($alumni->tanggalLahir) {
            $birthTime = strtotime($alumni->tanggalLahir);
            $today = strtotime(date('Y-m-d'));
            if ($birthTime >= $today) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tanggal lahir tidak boleh hari ini atau di masa depan'];
            }
            if ($alumni->angkatan) {
                $birthYear = (int) date('Y', $birthTime);
                $angkatanYear = (int) $alumni->angkatan;
                if ($birthYear > $angkatanYear) {
                    $this->response->setStatusCode(400);
                    return ['error' => 'Tahun lahir tidak boleh lebih besar dari tahun angkatan'];
                }
            }
        }

        $alumni->jenisKelamin = $data['jenisKelamin'] ?? null;
        $alumni->email = $data['email'] ?? '';
        $alumni->motto = $data['motto'] ?? '';
        $alumni->avatarUrl = $data['fotoUrl'] ?? $data['avatarUrl'] ?? null;
        $alumni->hp = $data['nomorHandphone'] ?? $data['hp'] ?? '';
        $alumni->linkedin = $data['linkedin'] ?? '';
        $alumni->alamat = $data['alamat'] ?? '';
        $alumni->status = $data['status'] ?? AlumniStatus::ACTIVE->value; // Auto active since admin adds it
        $alumni->keanggotaan = $data['keanggotaan'] ?? 'Alumni';
        $alumni->emailVerified = true;
        $alumni->ijazahFile = $data['ijazahFile'] ?? null;
        $alumni->nomorIjazah = $data['nomorIjazah'] ?? '';
        $alumni->tahunLulus = isset($data['tahunLulus']) && $data['tahunLulus'] !== '' ? (int) $data['tahunLulus'] : null;
        $alumni->ipk = isset($data['ipk']) && $data['ipk'] !== '' ? (float) $data['ipk'] : null;
        if (isset($data['alumniGrafis'])) {
            $alumni->alumniGrafis = is_array($data['alumniGrafis']) ? json_encode($data['alumniGrafis']) : $data['alumniGrafis'];
        }
        
        $userAgreement = isset($data['userAgreement']) && $data['userAgreement'] === true;
        if (!$userAgreement) {
            $this->response->setStatusCode(400);
            return ['error' => 'Anda harus menyetujui User Agreements (Privacy Policy & T&C)'];
        }
        $alumni->userAgreement = true;

        // Username: pakai input admin jika diisi, jika tidak generate otomatis.
        $inputUsername = isset($data['username']) ? trim($data['username']) : '';
        if ($inputUsername !== '') {
            if (preg_match('/\s/', $inputUsername)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Username tidak boleh mengandung spasi'];
            }
            $alumni->username = $inputUsername;
        } else {
            $baseUsername = strtolower(preg_replace('/[^a-z0-9]/i', '', $alumni->nama ?: 'alumni'));
            if (empty($baseUsername)) $baseUsername = 'alumni';
            $username = $baseUsername . rand(1000, 9999);
            while (\App\Models\Alumni::findFirst(['conditions' => 'deletedAt IS NULL AND username = ?0', 'bind' => [$username]])) {
                $username = $baseUsername . rand(1000, 9999);
            }
            $alumni->username = $username;
        }

        // Password: pakai input admin jika diisi, jika tidak generate acak.
        $inputPassword = isset($data['password']) ? (string) $data['password'] : '';
        if ($inputPassword !== '') {
            if (preg_match('/\s/', $inputPassword)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Password tidak boleh mengandung spasi'];
            }
            $alumni->password = password_hash($inputPassword, PASSWORD_BCRYPT);
        } else {
            $alumni->password = password_hash(bin2hex(random_bytes(8)), PASSWORD_BCRYPT);
        }

        if (isset($data['pekerjaan']) && is_array($data['pekerjaan'])) {
            $cleanPekerjaan = [];
            foreach ($data['pekerjaan'] as $p) {
                if (empty(trim($p['pekerjaan'] ?? '')) && empty(trim($p['perusahaan'] ?? ''))) {
                    continue;
                }
                if (!empty($p['tahunMulai']) && !empty($p['tahunSelesai']) && empty($p['masihBekerja'])) {
                    if ((int)$p['tahunSelesai'] < (int)$p['tahunMulai']) {
                        $this->response->setStatusCode(400);
                        return ['error' => 'Tahun selesai pekerjaan tidak boleh lebih kecil dari tahun mulai (tidak boleh backdate)'];
                    } elseif ((int)$p['tahunSelesai'] == (int)$p['tahunMulai'] && !empty($p['bulanMulai']) && !empty($p['bulanSelesai'])) {
                        $months = ['Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'Mei' => 5, 'Jun' => 6, 'Jul' => 7, 'Agu' => 8, 'Sep' => 9, 'Okt' => 10, 'Nov' => 11, 'Des' => 12];
                        if (isset($months[$p['bulanSelesai']]) && isset($months[$p['bulanMulai']])) {
                            if ($months[$p['bulanSelesai']] < $months[$p['bulanMulai']]) {
                                $this->response->setStatusCode(400);
                                return ['error' => 'Bulan selesai pekerjaan tidak boleh lebih kecil dari bulan mulai (tidak boleh backdate)'];
                            }
                        }
                    }
                }
                $cleanPekerjaan[] = $p;
            }
            $alumni->pekerjaan = json_encode($cleanPekerjaan);
        }
        if (isset($data['prestasi']) && is_array($data['prestasi'])) {
            $cleanPrestasi = [];
            foreach ($data['prestasi'] as $p) {
                if (empty(trim($p['judul'] ?? '')) && empty(trim($p['tahun'] ?? ''))) {
                    continue;
                }
                $cleanPrestasi[] = $p;
            }
            $alumni->prestasi = json_encode($cleanPrestasi);
        }

        // --- STRICT MODE & CONDITIONAL VALIDATION ---
        $pekerjaanArray = is_string($alumni->pekerjaan) ? json_decode($alumni->pekerjaan, true) : $alumni->pekerjaan;
        if (!is_array($pekerjaanArray)) $pekerjaanArray = [];
        
        $prestasiArray = is_string($alumni->prestasi) ? json_decode($alumni->prestasi, true) : $alumni->prestasi;
        if (!is_array($prestasiArray)) $prestasiArray = [];
        
        $grafisData = is_string($alumni->alumniGrafis) ? json_decode($alumni->alumniGrafis, true) : $alumni->alumniGrafis;

        $isStrictMode = false;
        foreach ($pekerjaanArray as $p) {
            $job = trim($p['pekerjaan'] ?? '');
            $company = trim($p['perusahaan'] ?? '');
            if (($company || !empty($p['tahunMulai']) || !empty($p['bulanMulai'])) && !$job) {
                $this->response->setStatusCode(400);
                return ['error' => 'Nama pekerjaan wajib diisi.'];
            }
            if ($job !== '' || $company !== '') {
                $isStrictMode = true;
            }
        }
        
        foreach ($prestasiArray as $p) {
            $title = trim($p['judul'] ?? '');
            $hasTahun = !empty($p['tahun']);
            if ($title && !$hasTahun) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tahun prestasi wajib diisi jika judul diisi.'];
            }
            if (!$title && $hasTahun) {
                $this->response->setStatusCode(400);
                return ['error' => 'Judul prestasi wajib diisi jika tahun diisi.'];
            }
            if ($title !== '' && empty($p['buktiUrl'])) {
                $this->response->setStatusCode(400);
                return ['error' => 'Dokumen bukti prestasi wajib diunggah untuk "' . $title . '".'];
            }
            if ($title !== '') {
                $isStrictMode = true;
            }
        }

        if ($grafisData && ($grafisData['kategori'] ?? 'None') !== 'None') {
            if (empty($grafisData['id'])) {
                $this->response->setStatusCode(400);
                return ['error' => 'Pilihan data pekerjaan/prestasi wajib dipilih untuk Alumni Grafis.'];
            }
            $isStrictMode = true;
        }

        // Dalam create() (menambah alumni baru di CMS), Mode Ketat HANYA di-bypass untuk status INACTIVE (draf nonaktif).
        // Jangan bypass untuk ACTIVE agar validasi profil lengkap tetap berlaku.
        if ($isStrictMode && strtoupper($alumni->status) === \App\Enums\AlumniStatus::INACTIVE->value) {
            // Bypass Mode Ketat untuk INACTIVE
        } elseif ($isStrictMode) {
            $missingFields = [];
            if (empty($alumni->avatarUrl)) $missingFields[] = 'Foto Profil';
            if (empty(trim((string)$alumni->angkatan))) $missingFields[] = 'Angkatan';
            if (empty(trim((string)$alumni->tanggalLahir))) $missingFields[] = 'Tanggal Lahir';
            if (empty(trim((string)$alumni->linkedin))) $missingFields[] = 'LinkedIn';
            if (empty(trim((string)$alumni->alamat))) $missingFields[] = 'Alamat';
            if (empty(trim((string)$alumni->tahunLulus))) $missingFields[] = 'Tahun Lulus';
            if (empty(trim((string)$alumni->ipk))) $missingFields[] = 'IPK';
            if (empty($alumni->ijazahFile)) $missingFields[] = 'Ijazah';

            if (!empty($missingFields)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Mode Ketat: Terdapat data wajib yang belum diisi untuk melengkapi profil (' . implode(', ', $missingFields) . ').'];
            }
        }
        // --- END STRICT MODE & CONDITIONAL VALIDATION ---

        try {
            if (in_array(strtoupper($alumni->status), [\App\Enums\AlumniStatus::APPROVED->value, \App\Enums\AlumniStatus::ACTIVE->value])) {
                if (empty($alumni->noAlumni)) {
                    $alumni->noAlumni = \App\Models\Alumni::generateNextNoAlumni(date('Y-m-d H:i:s'));
                }
            }

            if ($alumni->save() === false) {
                $this->response->setStatusCode(400);
                return ['error' => $this->getReadableError($alumni->getMessages())];
            }
        } catch (\PDOException $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

            $this->response->setStatusCode(400);
            if (stripos($e->getMessage(), 'unique') !== false && stripos($e->getMessage(), 'email') !== false) {
                return ['error' => 'Email sudah terdaftar. Silakan gunakan email lain.'];
            }
            if (stripos($e->getMessage(), 'unique') !== false && stripos($e->getMessage(), 'username') !== false) {
                return ['error' => 'Username sudah terdaftar.'];
            }
            return ['error' => 'Gagal menyimpan: Data sudah ada atau tidak valid.'];
        }

        $this->syncAlumniGrafisRecord($alumni);

        $this->response->setStatusCode(201);
        return $this->formatAlumni($alumni);
    }

    public function show($id)
    {
        $alumni = Alumni::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$id]]);
        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['error' => 'Alumni tidak ditemukan'];
        }
        return $this->formatAlumni($alumni);
    }

    public function update($id)
    {
        $data = $this->request->getJsonRawBody(true);
        $alumni = Alumni::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$id]]);
        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['error' => 'Not found'];
        }

        if (isset($data['nomorHandphone'])) {
            $data['hp'] = $data['nomorHandphone'];
        }

        if (isset($data['nama'])) {
            $data['nama'] = trim($data['nama']);
            if (empty($data['nama'])) {
                $this->response->setStatusCode(400);
                return ['error' => 'Nama wajib diisi'];
            }
        }

        $usernameVal = trim((string)($data['username'] ?? $alumni->username ?? ''));
        if (empty($usernameVal)) {
            $this->response->setStatusCode(400);
            return ['error' => 'Username wajib diisi'];
        }
        if (preg_match('/\s/', $usernameVal)) {
            $this->response->setStatusCode(400);
            return ['error' => 'Username tidak boleh mengandung spasi'];
        }
        if (strtolower($usernameVal) !== strtolower((string)$alumni->username)) {
            $existingUsername = Alumni::findFirst(['conditions' => 'username = ?0 AND id != ?1', 'bind' => [strtolower($usernameVal), $id]]);
            if ($existingUsername) {
                $this->response->setStatusCode(400);
                return ['error' => 'Username sudah terdaftar.'];
            }
        }
        $data['username'] = $usernameVal;

        if (isset($data['email'])) {
            $data['email'] = trim($data['email']);
            if (empty($data['email'])) {
                $this->response->setStatusCode(400);
                return ['error' => 'Email wajib diisi'];
            }
            if (strtolower($data['email']) !== strtolower((string)$alumni->email)) {
                $existingEmail = Alumni::findFirst(['conditions' => 'email = ?0 AND id != ?1', 'bind' => [strtolower($data['email']), $id]]);
                if ($existingEmail) {
                    $this->response->setStatusCode(400);
                    return ['error' => 'Email sudah terdaftar. Silakan gunakan email lain.'];
                }
            }
        }

        $oldPekerjaanDB = is_string($alumni->pekerjaan) ? json_decode($alumni->pekerjaan, true) : $alumni->pekerjaan;
        if (!is_array($oldPekerjaanDB)) $oldPekerjaanDB = [];
        $oldPrestasiDB = is_string($alumni->prestasi) ? json_decode($alumni->prestasi, true) : $alumni->prestasi;
        if (!is_array($oldPrestasiDB)) $oldPrestasiDB = [];

        if (isset($data['pekerjaan']) && is_array($data['pekerjaan'])) {
            foreach ($oldPekerjaanDB as $oldPek) {
                if (!empty($oldPek['isGrafis'])) {
                    $found = false;
                    foreach ($data['pekerjaan'] as &$newPek) {
                        if (($oldPek['id'] ?? null) && ($newPek['id'] ?? null) === $oldPek['id']) {
                            $found = true;
                            $newPek['isGrafis'] = true;
                            if (($oldPek['pekerjaan'] ?? '') !== ($newPek['pekerjaan'] ?? '') ||
                                ($oldPek['perusahaan'] ?? '') !== ($newPek['perusahaan'] ?? '') ||
                                ((string)($oldPek['tahunMulai'] ?? '')) !== ((string)($newPek['tahunMulai'] ?? '')) ||
                                ($oldPek['bulanMulai'] ?? '') !== ($newPek['bulanMulai'] ?? '') ||
                                ((string)($oldPek['tahunSelesai'] ?? '')) !== ((string)($newPek['tahunSelesai'] ?? '')) ||
                                ($oldPek['bulanSelesai'] ?? '') !== ($newPek['bulanSelesai'] ?? '') ||
                                !empty($oldPek['masihBekerja']) !== !empty($newPek['masihBekerja'])) {
                                $this->response->setStatusCode(400);
                                return ['error' => 'Data pekerjaan yang sudah dimasukkan ke Alumni Grafis tidak bisa diedit.'];
                            }
                            break;
                        }
                    }
                    if (!$found) {
                        $this->response->setStatusCode(400);
                        return ['error' => 'Data pekerjaan yang sudah dimasukkan ke Alumni Grafis tidak bisa dihapus.'];
                    }
                }
            }
        }

        if (isset($data['prestasi']) && is_array($data['prestasi'])) {
            foreach ($oldPrestasiDB as $oldPres) {
                if (!empty($oldPres['isGrafis'])) {
                    $found = false;
                    foreach ($data['prestasi'] as &$newPres) {
                        if (($oldPres['id'] ?? null) && ($newPres['id'] ?? null) === $oldPres['id']) {
                            $found = true;
                            $newPres['isGrafis'] = true;
                            if (($oldPres['judul'] ?? '') !== ($newPres['judul'] ?? '') ||
                                ((string)($oldPres['tahun'] ?? '')) !== ((string)($newPres['tahun'] ?? '')) ||
                                ($oldPres['buktiUrl'] ?? '') !== ($newPres['buktiUrl'] ?? '')) {
                                $this->response->setStatusCode(400);
                                return ['error' => 'Data prestasi yang sudah dimasukkan ke Alumni Grafis tidak bisa diedit.'];
                            }
                            break;
                        }
                    }
                    if (!$found) {
                        $this->response->setStatusCode(400);
                        return ['error' => 'Data prestasi yang sudah dimasukkan ke Alumni Grafis tidak bisa dihapus.'];
                    }
                }
            }
        }

        $fields = [
            'nama', 'angkatan', 'tanggalLahir', 'jenisKelamin', 'email', 'motto',
            'hp', 'linkedin', 'alamat', 'status', 'keanggotaan', 'username',
            'emailVisibility', 'nomorHandphoneVisibility', 'alamatVisibility',
            'alumniGrafis', 'nomorIjazah', 'ijazahFile', 'tahunLulus', 'ipk'
        ];
        $userRole = $this->di->getShared('userRole');
        
        foreach ($fields as $f) {
            if (array_key_exists($f, $data)) {
                if ($f === 'email') {
                    if ($alumni->emailVerified && $data[$f] !== $alumni->email && $userRole !== 'Super Admin') {
                        $this->response->setStatusCode(403);
                        return ['error' => 'Hanya Superadmin yang dapat mengubah email alumni yang sudah terverifikasi.'];
                    }
                }
                if (in_array($f, ['alumniGrafis'])) {
                    $alumni->$f = is_array($data[$f]) ? json_encode($data[$f]) : $data[$f];
                } elseif ($f === 'ipk') {
                    $alumni->$f = ($data[$f] !== '' && $data[$f] !== null) ? (float) $data[$f] : null;
                } elseif ($f === 'tahunLulus') {
                    $alumni->$f = ($data[$f] !== '' && $data[$f] !== null) ? (int) $data[$f] : null;
                } else {
                    $alumni->$f = $data[$f];
                }
            }
        }

        if ($alumni->tanggalLahir) {
            $birthTime = strtotime($alumni->tanggalLahir);
            $today = strtotime(date('Y-m-d'));
            if ($birthTime >= $today) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tanggal lahir tidak boleh hari ini atau di masa depan'];
            }
        }

        if ($alumni->tanggalLahir && $alumni->angkatan) {
            $birthYear = (int) date('Y', strtotime($alumni->tanggalLahir));
            $angkatanYear = (int) $alumni->angkatan;
            if ($birthYear > $angkatanYear) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tahun lahir tidak boleh lebih besar dari tahun angkatan'];
            }
        }
        if (isset($data['nomorHandphone'])) $alumni->hp = $data['nomorHandphone'];
        if (array_key_exists('fotoUrl', $data)) $alumni->avatarUrl = $data['fotoUrl'];
        if (array_key_exists('avatarUrl', $data)) $alumni->avatarUrl = $data['avatarUrl'];

        // Password hanya diubah bila admin mengisi field password (tidak kosong).
        if (isset($data['password']) && trim((string) $data['password']) !== '') {
            if (preg_match('/\s/', (string) $data['password'])) {
                $this->response->setStatusCode(400);
                return ['error' => 'Password tidak boleh mengandung spasi'];
            }
            $alumni->password = password_hash((string) $data['password'], PASSWORD_BCRYPT);
        }

        if (isset($data['pekerjaan']) && is_array($data['pekerjaan'])) {
            $cleanPekerjaan = [];
            foreach ($data['pekerjaan'] as $p) {
                if (empty(trim($p['pekerjaan'] ?? '')) && empty(trim($p['perusahaan'] ?? ''))) {
                    continue;
                }
                if (!empty($p['tahunMulai']) && !empty($p['tahunSelesai']) && empty($p['masihBekerja'])) {
                    if ((int)$p['tahunSelesai'] < (int)$p['tahunMulai']) {
                        $this->response->setStatusCode(400);
                        return ['error' => 'Tahun selesai pekerjaan tidak boleh lebih kecil dari tahun mulai (tidak boleh backdate)'];
                    } elseif ((int)$p['tahunSelesai'] == (int)$p['tahunMulai'] && !empty($p['bulanMulai']) && !empty($p['bulanSelesai'])) {
                        $months = ['Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'Mei' => 5, 'Jun' => 6, 'Jul' => 7, 'Agu' => 8, 'Sep' => 9, 'Okt' => 10, 'Nov' => 11, 'Des' => 12];
                        if (isset($months[$p['bulanSelesai']]) && isset($months[$p['bulanMulai']])) {
                            if ($months[$p['bulanSelesai']] < $months[$p['bulanMulai']]) {
                                $this->response->setStatusCode(400);
                                return ['error' => 'Bulan selesai pekerjaan tidak boleh lebih kecil dari bulan mulai (tidak boleh backdate)'];
                            }
                        }
                    }
                }
                $cleanPekerjaan[] = $p;
            }
            $alumni->pekerjaan = json_encode($cleanPekerjaan);
        }
        if (isset($data['prestasi']) && is_array($data['prestasi'])) {
            $cleanPrestasi = [];
            foreach ($data['prestasi'] as $p) {
                if (empty(trim($p['judul'] ?? '')) && empty(trim($p['tahun'] ?? ''))) {
                    continue;
                }
                $cleanPrestasi[] = $p;
            }
            $alumni->prestasi = json_encode($cleanPrestasi);
        }

        // --- STRICT MODE & CONDITIONAL VALIDATION ---
        $pekerjaanArray = is_string($alumni->pekerjaan) ? json_decode($alumni->pekerjaan, true) : $alumni->pekerjaan;
        if (!is_array($pekerjaanArray)) $pekerjaanArray = [];
        
        $prestasiArray = is_string($alumni->prestasi) ? json_decode($alumni->prestasi, true) : $alumni->prestasi;
        if (!is_array($prestasiArray)) $prestasiArray = [];
        
        $grafisData = is_string($alumni->alumniGrafis) ? json_decode($alumni->alumniGrafis, true) : $alumni->alumniGrafis;

        $isStrictMode = false;
        foreach ($pekerjaanArray as $p) {
            $job = trim($p['pekerjaan'] ?? '');
            $company = trim($p['perusahaan'] ?? '');
            if (($company || !empty($p['tahunMulai']) || !empty($p['bulanMulai'])) && !$job) {
                $this->response->setStatusCode(400);
                return ['error' => 'Nama pekerjaan wajib diisi.'];
            }
            if ($job !== '' || $company !== '') {
                $isStrictMode = true;
            }
        }
        
        foreach ($prestasiArray as $p) {
            $title = trim($p['judul'] ?? '');
            $hasTahun = !empty($p['tahun']);
            if ($title && !$hasTahun) {
                $this->response->setStatusCode(400);
                return ['error' => 'Tahun prestasi wajib diisi jika judul diisi.'];
            }
            if (!$title && $hasTahun) {
                $this->response->setStatusCode(400);
                return ['error' => 'Judul prestasi wajib diisi jika tahun diisi.'];
            }
            if ($title !== '') {
                $isStrictMode = true;
            }
        }

        if ($grafisData && ($grafisData['kategori'] ?? 'None') !== 'None') {
            if (empty($grafisData['id'])) {
                $this->response->setStatusCode(400);
                return ['error' => 'Pilihan data pekerjaan/prestasi wajib dipilih untuk Alumni Grafis.'];
            }
            
            $grafisId = (string) $grafisData['id'];
            $kategori = $grafisData['kategori'];
            $found = false;
            
            if (stripos($kategori, 'prestasi') !== false) {
                foreach ($prestasiArray as $p) {
                    if ((string)($p['id'] ?? '') === $grafisId) {
                        $found = true;
                        break;
                    }
                }
            } else {
                foreach ($pekerjaanArray as $p) {
                    if ((string)($p['id'] ?? '') === $grafisId) {
                        $found = true;
                        break;
                    }
                }
            }
            
            if (!$found) {
                $this->response->setStatusCode(400);
                return ['error' => 'Data pekerjaan/prestasi yang dipilih untuk Alumni Grafis tidak valid atau telah dihapus.'];
            }

            $isStrictMode = true;
        }

        // Dalam update(), Mode Ketat di-bypass jika hanya mengubah status (contoh: klik Aktifkan/Nonaktifkan di tabel) atau jika status menjadi INACTIVE
        $isOnlyStatusChange = (count($data) === 1 && isset($data['status']));
        if ($isStrictMode && ($isOnlyStatusChange || strtoupper($alumni->status) === \App\Enums\AlumniStatus::INACTIVE->value)) {
            // Bypass Mode Ketat
        } elseif ($isStrictMode) {
            $missingFields = [];
            if (empty($alumni->avatarUrl)) $missingFields[] = 'Foto Profil';
            if (empty(trim((string)$alumni->angkatan))) $missingFields[] = 'Angkatan';
            if (empty(trim((string)$alumni->tanggalLahir))) $missingFields[] = 'Tanggal Lahir';
            if (empty(trim((string)$alumni->linkedin))) $missingFields[] = 'LinkedIn';
            if (empty(trim((string)$alumni->alamat))) $missingFields[] = 'Alamat';
            if (empty(trim((string)$alumni->tahunLulus))) $missingFields[] = 'Tahun Lulus';
            if (empty(trim((string)$alumni->ipk))) $missingFields[] = 'IPK';
            if (empty($alumni->ijazahFile)) $missingFields[] = 'Ijazah';

            if (!empty($missingFields)) {
                $this->response->setStatusCode(400);
                return ['error' => 'Mode Ketat: Terdapat data wajib yang belum diisi untuk melengkapi profil (' . implode(', ', $missingFields) . ').'];
            }
        }
        // --- END STRICT MODE & CONDITIONAL VALIDATION ---

        try {
            if (in_array(strtoupper($alumni->status), [\App\Enums\AlumniStatus::APPROVED->value, \App\Enums\AlumniStatus::ACTIVE->value])) {
                if (empty($alumni->noAlumni)) {
                    $alumni->noAlumni = \App\Models\Alumni::generateNextNoAlumni($alumni->createdAt ?: date('Y-m-d H:i:s'));
                }
            }

            if ($alumni->save()) {
                if (in_array(strtoupper($alumni->status), [\App\Enums\AlumniStatus::APPROVED->value, \App\Enums\AlumniStatus::ACTIVE->value])) {
                    $verif = \App\Models\AlumniVerification::findFirst([
                        'conditions' => 'alumniId = ?0 AND status = ?1 AND deletedAt IS NULL',
                        'bind'       => [$alumni->id, \App\Enums\AlumniStatus::APPROVED->value],
                    ]);
                    if (!$verif) {
                        $verification = new \App\Models\AlumniVerification();
                        $verification->alumniId = $alumni->id;
                        $verification->adminId = $this->di->getShared('userId');
                        $verification->status = \App\Enums\AlumniStatus::APPROVED->value;
                        $verification->save();
                    }
                }
                $this->syncAlumniGrafisRecord($alumni);
                return $this->formatAlumni($alumni);
            }
        } catch (\PDOException $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

            $this->response->setStatusCode(400);
            if (stripos($e->getMessage(), 'unique') !== false && stripos($e->getMessage(), 'email') !== false) {
                return ['error' => 'Email sudah terdaftar. Silakan gunakan email lain.'];
            }
            if (stripos($e->getMessage(), 'unique') !== false && stripos($e->getMessage(), 'username') !== false) {
                return ['error' => 'Username sudah terdaftar.'];
            }
            return ['error' => 'Gagal menyimpan: Data sudah ada atau tidak valid.'];
        }
        
        $this->response->setStatusCode(400);
        return ['error' => $this->getReadableError($alumni->getMessages())];
    }
    
    public function delete($id)
    {
        $alumni = Alumni::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$id]]);
        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['error' => 'Not found'];
        }

        if (in_array(strtoupper($alumni->status), [\App\Enums\AlumniStatus::APPROVED->value, \App\Enums\AlumniStatus::ACTIVE->value, \App\Enums\AlumniStatus::INACTIVE->value])) {
            $this->response->setStatusCode(400);
            return ['error' => 'Data alumni yang telah diverifikasi tidak dapat dihapus.'];
        }

        $alumni->deletedAt = date('Y-m-d H:i:s');
        if ($alumni->save() === false) {
            $messages = $alumni->getMessages();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menghapus.', 'detail' => implode(', ', $messages)];
        }
        return ['message' => 'Deleted'];
    }

    public function approve($id)
    {
        $alumni = Alumni::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$id]]);
        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['error' => 'Not found'];
        }

        if ($alumni->status === AlumniStatus::APPROVED->value) {
            $this->response->setStatusCode(400);
            return ['error' => 'Alumni is already approved'];
        }

        $this->db->begin();

        $prevStatus = $alumni->status;
        $this->di->getShared('auditLog')->skipNextChange('Alumni', $alumni->id);
        $alumni->status = AlumniStatus::ACTIVE->value;
        if (empty($alumni->noAlumni)) {
            $alumni->noAlumni = Alumni::generateNextNoAlumni($alumni->createdAt);
        }
        if (!$alumni->save()) {
            $this->db->rollback();
            $this->response->setStatusCode(500);
            $errors = [];
            foreach ($alumni->getMessages() as $msg) { $errors[] = (string)$msg; }
            error_log("Failed to approve alumni: " . implode(', ', $errors));
            return ['error' => 'Failed to approve alumni', 'details' => $errors];
        }

        $adminId = $this->di->getShared('userId');
        $verification = new \App\Models\AlumniVerification();
        $verification->alumniId = $alumni->id;
        $verification->adminId = $adminId;
        $verification->status = AlumniStatus::APPROVED->value;

        if (!$verification->save()) {
            $this->db->rollback();
            $this->response->setStatusCode(500);
            $errors = [];
            foreach ($verification->getMessages() as $msg) { $errors[] = (string)$msg; }
            error_log("Failed to save verification: " . implode(', ', $errors));
            return ['error' => 'Failed to save verification', 'details' => $errors];
        }

        $this->db->commit();
        $this->sendVerificationEmail($alumni->email, $alumni->nama, 'Approved');
        $verification->save();

        $this->di->getShared('auditLog')->log([
            'action'      => 'approve',
            'entityType'  => 'Alumni',
            'entityId'    => $alumni->id,
            'description' => "Approve alumni {$alumni->nama}",
            'changes'     => ['before' => ['status' => $prevStatus], 'after' => ['status' => $alumni->status]],
        ]);

        return ['message' => 'Alumni approved successfully', 'alumni' => $alumni];
    }

    public function reject($id)
    {
        $data = $this->request->getJsonRawBody(true);
        $reason = $data['reason'] ?? '';

        if (!$reason) {
            $this->response->setStatusCode(400);
            return ['error' => 'Reason is required for rejection'];
        }

        $alumni = Alumni::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$id]]);
        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['error' => 'Not found'];
        }

        if ($alumni->status === AlumniStatus::REJECTED->value) {
            $this->response->setStatusCode(400);
            return ['error' => 'Alumni is already rejected'];
        }

        $this->db->begin();

        $prevStatus = $alumni->status;
        $this->di->getShared('auditLog')->skipNextChange('Alumni', $alumni->id);
        $alumni->status = AlumniStatus::REJECTED->value;
        if (!$alumni->save()) {
            $this->db->rollback();
            $errors = [];
            foreach ($alumni->getMessages() as $msg) { $errors[] = (string)$msg; }
            error_log("Failed to reject alumni: " . implode(', ', $errors));
            return ['error' => 'Failed to reject alumni', 'details' => $errors];
        }

        $adminId = $this->di->getShared('userId');
        $verification = new \App\Models\AlumniVerification();
        $verification->alumniId = $alumni->id;
        $verification->adminId = $adminId;
        $verification->status = AlumniStatus::REJECTED->value;
        $verification->reason = $reason;

        if (!$verification->save()) {
            $this->db->rollback();
            $this->response->setStatusCode(500);
            $errors = [];
            foreach ($verification->getMessages() as $msg) { $errors[] = (string)$msg; }
            error_log("Failed to save rejection record: " . implode(', ', $errors));
            return ['error' => 'Failed to save rejection record', 'details' => $errors];
        }

        $this->db->commit();
        $this->sendVerificationEmail($alumni->email, $alumni->nama, 'Rejected', $reason);

        $this->di->getShared('auditLog')->log([
            'action'      => 'reject',
            'entityType'  => 'Alumni',
            'entityId'    => $alumni->id,
            'description' => "Tolak alumni {$alumni->nama}",
            'changes'     => ['before' => ['status' => $prevStatus], 'after' => ['status' => $alumni->status]],
            'metadata'    => ['reason' => $reason],
        ]);

        return ['message' => 'Alumni rejected successfully', 'alumni' => $alumni];
    }

    public function updateRole($id)
    {
        // Role alumni sudah dihapus — admin dikelola di tabel Admin terpisah.
        // Endpoint ini tidak lagi berlaku untuk Alumni.
        $this->response->setStatusCode(400);
        return ['error' => 'Pengelolaan role admin kini menggunakan tabel Admin terpisah. Gunakan endpoint /api/admin/users.'];
    }

    private function sendVerificationEmail($email, $nama, $status, $reason = '')
    {
        $config = $this->di->get('config');
        
        $fromEmail = $config['smtp_user'];
        $fromName = 'Admin IKA JTK';
        if (preg_match('/^(.*?)\s*<(.*?)>$/', $config['smtp_from'], $matches)) {
            $fromName = trim($matches[1]);
            $fromEmail = trim($matches[2]);
        }
        
        $mail = new \PHPMailer\PHPMailer\PHPMailer(true);

        try {
            $mail->isSMTP();
            $mail->Host       = $config['smtp_host'];
            $mail->SMTPAuth   = true;
            $mail->Username   = $config['smtp_user'];
            $mail->Password   = $config['smtp_pass'];
            $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port       = $config['smtp_port'];

            $mail->setFrom($fromEmail, $fromName);
            $mail->addAddress($email, $nama);

            $mail->isHTML(true);
            
            if ($status === 'Approved') {
                $mail->Subject = 'Pendaftaran Alumni IKA JTK Disetujui';
                $mail->Body    = "<p>Halo {$nama},</p><p>Selamat! Pendaftaran Anda sebagai alumni IKA JTK Polban telah <strong>disetujui</strong> oleh administrator.</p><p>Sekarang Anda dapat login ke portal IKA JTK menggunakan akun Anda.</p>";
            } else {
                $mail->Subject = 'Pendaftaran Alumni IKA JTK Ditolak';
                $mail->Body    = "<p>Halo {$nama},</p><p>Mohon maaf, pendaftaran Anda sebagai alumni IKA JTK Polban <strong>ditolak</strong> oleh administrator.</p><p>Alasan penolakan: <em>{$reason}</em></p><p>Silakan daftar kembali dengan data yang valid atau hubungi administrator jika Anda merasa ini adalah sebuah kesalahan.</p>";
            }

            $mail->send();
            return true;
        } catch (\Exception $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

            file_put_contents(BASE_PATH . '/email_error.log', "Error: " . $mail->ErrorInfo . "\n" . $e->getMessage(), FILE_APPEND);
            error_log("Email sending failed: {$mail->ErrorInfo}");
            return false;
        }
    }

    public function getAlumniGrafisRequests()
    {
        $status = $this->request->getQuery('status', 'string', 'PENDING');
        
        if ($status === 'ALL') {
            $requests = \App\Models\AlumniGrafisRequest::find([
                'conditions' => "status != 'PENDING' AND deletedAt IS NULL",
                'order' => 'createdAt DESC'
            ]);
        } else {
            $requests = \App\Models\AlumniGrafisRequest::find([
                'conditions' => 'status = ?0 AND deletedAt IS NULL',
                'bind' => [$status],
                'order' => 'createdAt DESC'
            ]);
        }

        $result = [];
        foreach ($requests as $req) {
            $alumni = \App\Models\Alumni::findFirst([
                'conditions' => 'id = ?0',
                'bind' => [$req->alumniId]
            ]);
            
            if ($alumni) {
                $item = $req->toArray();
                
                // Set alumni details
                $item['alumni'] = [
                    'id' => $alumni->id,
                    'nama' => $alumni->nama,
                    'angkatan' => $alumni->angkatan,
                    'avatarUrl' => $alumni->avatarUrl
                ];
                
                // Get detail (Pekerjaan or Prestasi) based on kategori and grafisId
                $detailData = null;
                if (strpos(strtolower($req->kategori), 'prestasi') !== false) {
                    $prestasi = is_string($alumni->prestasi) ? json_decode($alumni->prestasi, true) : ($alumni->prestasi ?? []);
                    if (is_array($prestasi)) {
                        foreach ($prestasi as $p) {
                            if (($p['id'] ?? '') === $req->grafisId) {
                                $detailData = $p;
                                break;
                            }
                        }
                    }
                } else {
                    $pekerjaan = is_string($alumni->pekerjaan) ? json_decode($alumni->pekerjaan, true) : ($alumni->pekerjaan ?? []);
                    if (is_array($pekerjaan)) {
                        foreach ($pekerjaan as $p) {
                            if (($p['id'] ?? '') === $req->grafisId) {
                                $detailData = $p;
                                break;
                            }
                        }
                    }
                }
                
                $item['detail'] = $detailData;
                $result[] = $item;
            }
        }
        
        $this->response->setStatusCode(200);
        return $result;
    }

    public function verifyAlumniGrafis($id)
    {
        $data = $this->request->getJsonRawBody(true) ?: $this->request->getPost();
        if (!isset($data['status']) || !in_array($data['status'], ['APPROVED', 'REJECTED', 'ARCHIVED'])) {
            $this->response->setStatusCode(400);
            return ['message' => 'Status tidak valid'];
        }

        $req = \App\Models\AlumniGrafisRequest::findFirst([
            'conditions' => 'id = ?0 AND deletedAt IS NULL',
            'bind' => [$id]
        ]);

        if (!$req) {
            $this->response->setStatusCode(404);
            return ['message' => 'Pengajuan tidak ditemukan'];
        }

        if ($data['status'] === 'APPROVED') {
            $alumniCheck = \App\Models\Alumni::findFirst([
                'conditions' => 'id = ?0 AND deletedAt IS NULL',
                'bind' => [$req->alumniId]
            ]);
            if (!$alumniCheck || !in_array(strtoupper($alumniCheck->status), [\App\Enums\AlumniStatus::ACTIVE->value, \App\Enums\AlumniStatus::APPROVED->value])) {
                $this->response->setStatusCode(400);
                return ['message' => 'Akun alumni belum diverifikasi (status aktif/approved). Verifikasi akun alumni terlebih dahulu sebelum menyetujui Alumni Grafis.'];
            }
        }

        $req->status = $data['status'];
        if (!$req->save()) {
            $this->response->setStatusCode(500);
            return ['message' => 'Gagal mengupdate pengajuan'];
        }

        $alumni = \App\Models\Alumni::findFirst([
            'conditions' => 'id = ?0',
            'bind' => [$req->alumniId]
        ]);

        if ($alumni) {
            $isPrestasi = strpos(strtolower($req->kategori), 'prestasi') !== false;
            
            if ($data['status'] === 'APPROVED') {
                // Set isGrafis = true in the corresponding item
                if ($isPrestasi) {
                    $prestasi = is_string($alumni->prestasi) ? json_decode($alumni->prestasi, true) : ($alumni->prestasi ?? []);
                    if (is_array($prestasi)) {
                        foreach ($prestasi as &$p) {
                            if (($p['id'] ?? '') === $req->grafisId) {
                                $p['isGrafis'] = true;
                                break;
                            }
                        }
                        $alumni->prestasi = json_encode($prestasi);
                    }
                } else {
                    $pekerjaan = is_string($alumni->pekerjaan) ? json_decode($alumni->pekerjaan, true) : ($alumni->pekerjaan ?? []);
                    if (is_array($pekerjaan)) {
                        foreach ($pekerjaan as &$p) {
                            if (($p['id'] ?? '') === $req->grafisId) {
                                $p['isGrafis'] = true;
                                break;
                            }
                        }
                        $alumni->pekerjaan = json_encode($pekerjaan);
                    }
                }
                
                // Update alumniGrafis JSON field for backward compatibility
                $alumniGrafis = is_string($alumni->alumniGrafis) ? json_decode($alumni->alumniGrafis, true) : [];
                $alumniGrafis['kategori'] = $req->kategori;
                $alumniGrafis['id'] = $req->grafisId;
                $alumniGrafis['status'] = 'APPROVED';
                $alumni->alumniGrafis = json_encode($alumniGrafis);
            } elseif ($data['status'] === 'REJECTED') {
                // If rejected, just update status in JSON if it's the current one
                $alumniGrafis = is_string($alumni->alumniGrafis) ? json_decode($alumni->alumniGrafis, true) : null;
                if ($alumniGrafis && ($alumniGrafis['id'] ?? '') === $req->grafisId) {
                    $alumniGrafis['status'] = 'REJECTED';
                    $alumni->alumniGrafis = json_encode($alumniGrafis);
                }
            } elseif ($data['status'] === 'ARCHIVED') {
                // If archived, set isGrafis to false in prestai/pekerjaan
                if ($isPrestasi) {
                    $prestasi = is_string($alumni->prestasi) ? json_decode($alumni->prestasi, true) : ($alumni->prestasi ?? []);
                    if (is_array($prestasi)) {
                        foreach ($prestasi as &$p) {
                            if (($p['id'] ?? '') === $req->grafisId) {
                                $p['isGrafis'] = false;
                                break;
                            }
                        }
                        $alumni->prestasi = json_encode($prestasi);
                    }
                } else {
                    $pekerjaan = is_string($alumni->pekerjaan) ? json_decode($alumni->pekerjaan, true) : ($alumni->pekerjaan ?? []);
                    if (is_array($pekerjaan)) {
                        foreach ($pekerjaan as &$p) {
                            if (($p['id'] ?? '') === $req->grafisId) {
                                $p['isGrafis'] = false;
                                break;
                            }
                        }
                        $alumni->pekerjaan = json_encode($pekerjaan);
                    }
                }
                
                // Update status in JSON to ARCHIVED
                $alumniGrafis = is_string($alumni->alumniGrafis) ? json_decode($alumni->alumniGrafis, true) : null;
                if ($alumniGrafis && ($alumniGrafis['id'] ?? '') === $req->grafisId) {
                    $alumniGrafis['status'] = 'ARCHIVED';
                    $alumni->alumniGrafis = json_encode($alumniGrafis);
                }
            }
            
            $alumni->save();
        }

        $this->response->setStatusCode(200);
        return ['message' => 'Status berhasil diupdate', 'data' => $req->toArray()];
    }

    private function syncAlumniGrafisRecord($alumni)
    {
        $grafisData = is_string($alumni->alumniGrafis) ? json_decode($alumni->alumniGrafis, true) : $alumni->alumniGrafis;
        if ($grafisData && isset($grafisData['kategori']) && isset($grafisData['id']) && $grafisData['kategori'] !== 'None' && !empty($grafisData['id'])) {
            $grafisData['status'] = $grafisData['status'] ?? 'APPROVED';
            $alumni->alumniGrafis = json_encode($grafisData);

            $isPrestasi = false;
            $prestasi = is_string($alumni->prestasi) ? json_decode($alumni->prestasi, true) : ($alumni->prestasi ?? []);
            if (is_array($prestasi)) {
                foreach ($prestasi as &$p) {
                    if (($p['id'] ?? '') === $grafisData['id']) {
                        $p['isGrafis'] = true;
                        $isPrestasi = true;
                    } else {
                        $p['isGrafis'] = false;
                    }
                }
                $alumni->prestasi = json_encode($prestasi);
            }

            $pekerjaan = is_string($alumni->pekerjaan) ? json_decode($alumni->pekerjaan, true) : ($alumni->pekerjaan ?? []);
            if (is_array($pekerjaan)) {
                foreach ($pekerjaan as &$p) {
                    if (!$isPrestasi && ($p['id'] ?? '') === $grafisData['id']) {
                        $p['isGrafis'] = true;
                    } else {
                        $p['isGrafis'] = false;
                    }
                }
                $alumni->pekerjaan = json_encode($pekerjaan);
            }

            // Delete old AlumniGrafisRequest for this alumni
            $oldRequests = \App\Models\AlumniGrafisRequest::find([
                'conditions' => 'alumniId = ?0',
                'bind' => [$alumni->id]
            ]);
            foreach ($oldRequests as $old) {
                $old->delete();
            }

            // Create new AlumniGrafisRequest
            $req = new \App\Models\AlumniGrafisRequest();
            $req->alumniId = $alumni->id;
            $req->kategori = $grafisData['kategori'];
            $req->grafisId = $grafisData['id'];
            $req->status = $grafisData['status'];
            $req->save();
            $alumni->save();
        } else {
            $oldRequests = \App\Models\AlumniGrafisRequest::find([
                'conditions' => 'alumniId = ?0',
                'bind' => [$alumni->id]
            ]);
            foreach ($oldRequests as $old) {
                $old->delete();
            }

            $changed = false;
            $pekerjaan = is_string($alumni->pekerjaan) ? json_decode($alumni->pekerjaan, true) : ($alumni->pekerjaan ?? []);
            if (is_array($pekerjaan)) {
                foreach ($pekerjaan as &$p) {
                    if (!empty($p['isGrafis'])) {
                        $p['isGrafis'] = false;
                        $changed = true;
                    }
                }
                if ($changed) $alumni->pekerjaan = json_encode($pekerjaan);
            }
            $prestasi = is_string($alumni->prestasi) ? json_decode($alumni->prestasi, true) : ($alumni->prestasi ?? []);
            if (is_array($prestasi)) {
                $changedPrestasi = false;
                foreach ($prestasi as &$p) {
                    if (!empty($p['isGrafis'])) {
                        $p['isGrafis'] = false;
                        $changedPrestasi = true;
                    }
                }
                if ($changedPrestasi) $alumni->prestasi = json_encode($prestasi);
            }
            if ($changed || $changedPrestasi) {
                $alumni->save();
            }
        }
    }
}
