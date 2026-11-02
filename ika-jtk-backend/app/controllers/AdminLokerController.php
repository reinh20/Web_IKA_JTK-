<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Loker;
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use App\Traits\AuthorFormatter;

class AdminLokerController extends Controller
{
    use AuthorFormatter;
    public function index()
    {
        $page = $this->request->getQuery('page', 'int', null);
        $limit = $this->request->getQuery('limit', 'int', 10);
        $search = $this->request->getQuery('search', 'string', '');
        $status = $this->request->getQuery('status', 'string', '');
        $tab = $this->request->getQuery('tab', 'string', '');

        $conditions = '[deletedAt] IS NULL';
        $bind = [];

        if ($tab === 'submission') {
            $conditions .= ' AND status = :status_submission:';
            $bind['status_submission'] = 'Submission';
        } else if ($tab === 'semua' || $tab !== '') {
            $conditions .= ' AND status != :status_submission:';
            $bind['status_submission'] = 'Submission';
        }
        
        if ($status !== '' && $status !== 'all' && $tab !== 'submission') {
            $conditions .= ' AND status = :status:';
            $bind['status'] = $status;
        }

        if ($search !== '') {
            $conditions .= ' AND (LOWER(posisi) LIKE LOWER(:search:) OR LOWER(namaPerusahaan) LIKE LOWER(:search:) OR LOWER(tags) LIKE LOWER(:search:))';
            $bind['search'] = '%' . $search . '%';
        }

        $queryOpts = [
            'conditions' => $conditions,
            'bind' => $bind,
            'order' => '[createdAt] DESC, [id] DESC'
        ];

        if ($page !== null) {
            $total = Loker::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $semuaCount = Loker::count([
                'conditions' => '[deletedAt] IS NULL AND status != :status_submission:',
                'bind' => ['status_submission' => 'Submission']
            ]);

            $submissionCount = Loker::count([
                'conditions' => '[deletedAt] IS NULL AND status = :status_submission:',
                'bind' => ['status_submission' => 'Submission']
            ]);

            $queryOpts['limit'] = $limit;
            $queryOpts['offset'] = ($page - 1) * $limit;

            $list = Loker::find($queryOpts);
            $result = [];
            foreach ($list as $item) {
                $data = $this->format($item);
                if (is_string($data['author'])) $data['author'] = json_decode($data['author'], true);
                if (is_string($data['formLamaran'])) $data['formLamaran'] = json_decode($data['formLamaran'], true) ?: [];
                $result[] = $data;
            }

            $this->response->setStatusCode(200);
            return [
                'data' => $result,
                'total' => $total,
                'semuaCount' => $semuaCount,
                'submissionCount' => $submissionCount
            ];
        }

        // Fallback for non-paginated queries
        $list = Loker::find($queryOpts);
        $result = [];
        foreach ($list as $item) {
            $data = $this->format($item);
            if (is_string($data['author'])) $data['author'] = json_decode($data['author'], true);
            if (is_string($data['formLamaran'])) $data['formLamaran'] = json_decode($data['formLamaran'], true) ?: [];
            $result[] = $data;
        }
        $this->response->setStatusCode(200);
        return $result;
    }

    public function show($id)
    {
        $item = Loker::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Loker not found'];
        }
        $data = $this->format($item);
        if (is_string($data['author'])) $data['author'] = json_decode($data['author'], true);
        if (is_string($data['formLamaran'])) $data['formLamaran'] = json_decode($data['formLamaran'], true) ?: [];
        $this->response->setStatusCode(200);
        return $data;
    }

    public function create()
    {
        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $item = new Loker();
        $item->noLoker = $req['noLoker'] ?? '';
        $item->posisi = $req['posisi'] ?? '';
        $item->namaPerusahaan = $req['namaPerusahaan'] ?? '';
        $item->websitePerusahaan = $req['websitePerusahaan'] ?? '';
        $item->logoUrl = $req['logoUrl'] ?? null;
        $item->logoThumbnailUrl = $req['logoThumbnailUrl'] ?? null;
        $item->jenisPekerjaan = $req['jenisPekerjaan'] ?? '';
        $item->tipeLokasi = $req['tipeLokasi'] ?? '';
        $item->kota = $req['kota'] ?? '';
        $item->deskripsi = $req['deskripsi'] ?? '';
        $item->tags = $req['tags'] ?? '';
        $item->skemaPelamaran = $req['skemaPelamaran'] ?? 'internal';
        $item->linkExternal = $req['linkExternal'] ?? '';
        $item->status = $req['status'] ?? 'Draft';

        if (isset($req['formLamaran']) && is_array($req['formLamaran'])) {
            $item->formLamaran = json_encode($req['formLamaran']);
        }

        if (isset($req['author']) && is_array($req['author'])) {
            $item->authorId = $req['author']['id'] ?? '';
            $item->authorNama = $req['author']['nama'] ?? '';
            $item->authorRole = $req['author']['role'] ?? '';
            $item->authorAvatarUrl = $req['author']['avatarUrl'] ?? '';
        }
        if (empty($item->authorId) && $this->getDI()->has('userId')) {
            $item->authorId = $this->getDI()->get('userId') ?: '8fb57aec0d5becbad9460ce4c5d32811';
        }

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menyimpan loker: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(201);
        return $this->format($item);
    }

    public function update($id)
    {
        $item = Loker::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Loker not found'];
        }

        $prevStatus = $item->status;
        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        if (isset($req['noLoker'])) $item->noLoker = $req['noLoker'];
        if (isset($req['posisi'])) $item->posisi = $req['posisi'];
        if (isset($req['namaPerusahaan'])) $item->namaPerusahaan = $req['namaPerusahaan'];
        if (isset($req['websitePerusahaan'])) $item->websitePerusahaan = $req['websitePerusahaan'];
        if (array_key_exists('logoUrl', $req)) $item->logoUrl = $req['logoUrl'];
        if (array_key_exists('logoThumbnailUrl', $req)) $item->logoThumbnailUrl = $req['logoThumbnailUrl'];
        if (isset($req['jenisPekerjaan'])) $item->jenisPekerjaan = $req['jenisPekerjaan'];
        if (isset($req['tipeLokasi'])) $item->tipeLokasi = $req['tipeLokasi'];
        if (isset($req['kota'])) $item->kota = $req['kota'];
        if (isset($req['deskripsi'])) $item->deskripsi = $req['deskripsi'];
        if (isset($req['skemaPelamaran'])) $item->skemaPelamaran = $req['skemaPelamaran'];
        if (isset($req['linkExternal'])) $item->linkExternal = $req['linkExternal'];
        if (isset($req['status'])) $item->status = $req['status'];
        if (isset($req['tags'])) $item->tags = $req['tags'];

        if (isset($req['formLamaran']) && is_array($req['formLamaran'])) {
            $item->formLamaran = json_encode($req['formLamaran']);
        }

        if (isset($req['pelamar']) && is_array($req['pelamar'])) {
            $item->pelamar = json_encode($req['pelamar']);
        }

        if (isset($req['author']) && is_array($req['author'])) {
            $item->authorId = $req['author']['id'] ?? '';
            $item->authorNama = $req['author']['nama'] ?? '';
            $item->authorRole = $req['author']['role'] ?? '';
            $item->authorAvatarUrl = $req['author']['avatarUrl'] ?? '';
        }

        if ($item->status === 'Submission') {
            $item->status = 'Draft';
        }

        if ($item->status === 'Published') {
            if ($prevStatus !== 'Published' || empty($item->publishedAt)) {
                $item->publishedAt = date('Y-m-d H:i:s');
            }
        } else {
            $item->publishedAt = null;
        }

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal memperbarui loker: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(200);
        return $this->format($item);
    }

    public function approve($id)
    {
        $item = Loker::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Loker not found'];
        }

        $item->status = 'Published';
        $item->publishedAt = date('Y-m-d H:i:s');

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menyetujui loker: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(200);
        return $this->format($item);
    }

    public function reject($id)
    {
        $item = Loker::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Loker not found'];
        }

        $item->status = 'Rejected';
        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menolak loker: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(200);
        return $this->format($item);
    }

    public function delete($id)
    {
        $item = Loker::findFirst(['conditions' => 'id = ?0 AND [deletedAt] IS NULL', 'bind' => [$id]]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Loker not found'];
        }
        $item->deletedAt = date('Y-m-d H:i:s');
        if ($item->save() === false) {
            $messages = $item->getMessages();
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menghapus.', 'detail' => implode(', ', $messages)];
        }
        $this->response->setStatusCode(200);
        return ['message' => 'Loker berhasil dihapus'];
    }

    private function format($item)
    {
        $data = $item->toArray();
        $data['author'] = $this->formatAuthor($data);
        // Override pelamar with data from Lamaran table
        $lamarans = \App\Models\Lamaran::find([
            'conditions' => 'lokerId = ?0 AND [deletedAt] IS NULL',
            'bind' => [$item->id]
        ]);
        
        $pelamarList = [];
        foreach ($lamarans as $lamaran) {
            $alumni = $lamaran->alumni;
            
            $pelamarList[] = [
                'id' => $lamaran->id, // Important: id of the application itself
                'alumniId' => $lamaran->alumniId,
                'noAlumni' => $alumni ? ($alumni->noAlumni ?? '') : '',
                'nama' => $alumni ? $alumni->nama : '',
                'angkatan' => $alumni ? $alumni->angkatan : '',
                'email' => $alumni ? $alumni->email : '',
                'avatarUrl' => $alumni ? $alumni->avatarUrl : '',
                'keanggotaan' => $alumni ? $alumni->keanggotaan : 'Alumni',
                'tanggalPelamar' => $lamaran->createdAt,
                'jawaban' => json_decode($lamaran->jawaban, true) ?: [],
                'status' => $lamaran->status
            ];
        }
        $data['pelamar'] = $pelamarList;
        
        unset($data['authorId'], $data['authorNama'], $data['authorRole'], $data['authorAvatarUrl']);
        return $data;
    }

    public function updateLamaranStatus($id, $lamaranId)
    {
        $lamaran = \App\Models\Lamaran::findFirst([
            'conditions' => 'id = ?0 AND lokerId = ?1',
            'bind' => [$lamaranId, $id]
        ]);

        if (!$lamaran) {
            $this->response->setStatusCode(404);
            return ['error' => 'Lamaran not found'];
        }

        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();
        if (isset($req['status'])) {
            if ($lamaran->status === $req['status']) {
                $this->response->setStatusCode(200);
                return ['message' => 'Status sudah ' . $req['status'] . ', tidak ada perubahan.'];
            }

            $lamaran->status = $req['status'];
            if ($lamaran->save() === false) {
                $this->response->setStatusCode(400);
                return ['error' => 'Gagal memperbarui status lamaran'];
            }

            // Kirim email jika status Diterima atau Ditolak
            $newStatus = strtolower($req['status']);
            if (str_contains($newStatus, 'terima') || str_contains($newStatus, 'tolak')) {
                $loker = Loker::findFirst(['conditions' => 'id = ?0', 'bind' => [$id]]);
                $alumni = \App\Models\Alumni::findFirst(['conditions' => 'id = ?0', 'bind' => [$lamaran->alumniId]]);
                
                if ($loker && $alumni && !empty($alumni->email)) {
                    $config = $this->getDI()->get('config');
                    $mail = new PHPMailer(true);
                    try {
                        $mail->isSMTP();
                        $mail->Host       = $config['smtp_host'] ?: 'smtp.gmail.com';
                        $mail->SMTPAuth   = true;
                        $mail->Username   = $config['smtp_user'];
                        $mail->Password   = $config['smtp_pass'];
                        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
                        $mail->Port       = $config['smtp_port'] ?: 587;
                        $mail->SMTPOptions = array(
                            'ssl' => array(
                                'verify_peer' => false,
                                'verify_peer_name' => false,
                                'allow_self_signed' => true
                            )
                        );
                        $fromEmail = $config['smtp_user'] ?: 'no-reply@example.com';
                        $fromName = 'Admin IKA JTK';
                        if (!empty($config['smtp_from'])) {
                            if (preg_match('/^(.*?)\s*<(.*?)>$/', $config['smtp_from'], $matches)) {
                                $fromName = trim($matches[1]);
                                $fromEmail = trim($matches[2]);
                            } else {
                                $fromEmail = trim($config['smtp_from']);
                            }
                        }
                        $mail->setFrom($fromEmail, $fromName);
                        $mail->addAddress($alumni->email, $alumni->nama);
                        $mail->isHTML(false);

                        if (str_contains($newStatus, 'terima')) {
                            $mail->Subject = "Selamat! Anda Diterima untuk posisi {$loker->posisi} di {$loker->namaPerusahaan}";
                            $mail->Body    = "Kepada {$alumni->nama},\n\nSelamat! Lamaran Anda untuk posisi {$loker->posisi} di {$loker->namaPerusahaan} telah DITERIMA.\nSilakan tunggu informasi lebih lanjut atau hubungi pihak perusahaan secara langsung.\n\nSalam,\nAdmin IKA JTK";
                        } else {
                            $mail->Subject = "Update Status Lamaran: {$loker->posisi} di {$loker->namaPerusahaan}";
                            $mail->Body    = "Kepada {$alumni->nama},\n\nMohon maaf, lamaran Anda untuk posisi {$loker->posisi} di {$loker->namaPerusahaan} saat ini DITOLAK.\nTerima kasih atas ketertarikan Anda dan tetap semangat!\n\nSalam,\nAdmin IKA JTK";
                        }
                        
                        $mail->send();
                    } catch (Exception $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

                        error_log("Gagal mengirim email update status lamaran: {$mail->ErrorInfo}");
                    }
                }
            }
        }

        $this->response->setStatusCode(200);
        return ['message' => 'Status lamaran berhasil diperbarui', 'status' => $lamaran->status];
    }

    public function deleteLamaran($id, $lamaranId)
    {
        $lamaran = \App\Models\Lamaran::findFirst([
            'conditions' => 'id = ?0 AND lokerId = ?1 AND [deletedAt] IS NULL',
            'bind' => [$lamaranId, $id]
        ]);

        if (!$lamaran) {
            $this->response->setStatusCode(404);
            return ['error' => 'Lamaran not found'];
        }

        $lamaran->deletedAt = date('Y-m-d H:i:s');
        if ($lamaran->save() === false) {
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal menghapus lamaran'];
        }

        $loker = Loker::findFirst(['conditions' => 'id = ?0', 'bind' => [$id]]);
        $this->response->setStatusCode(200);
        return $this->format($loker);
    }
}
