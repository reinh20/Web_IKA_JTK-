<?php
namespace App\Controllers;
use Phalcon\Mvc\Controller;
use App\Models\Loker;
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use App\Traits\AuthorFormatter;

class PortalLokerController extends Controller
{
    use AuthorFormatter;
    public function index()
    {
        $page = $this->request->getQuery('page', 'int', null);
        $limit = $this->request->getQuery('limit', 'int', 10);
        $search = trim($this->request->getQuery('search', 'string', ''));
        $jenisPekerjaan = trim($this->request->getQuery('jenisPekerjaan', 'string', ''));
        if ($jenisPekerjaan === '') {
            $jenisPekerjaan = trim($this->request->getQuery('tipePekerjaan', 'string', ''));
        }
        $tipeLokasi = trim($this->request->getQuery('tipeLokasi', 'string', ''));
        if ($tipeLokasi === '') {
            $tipeLokasi = trim($this->request->getQuery('sistemKerja', 'string', ''));
        }
        $kota = trim($this->request->getQuery('kota', 'string', ''));

        $conditions = '[deletedAt] IS NULL AND status = :status:';
        $bind = ['status' => 'Published'];

        if ($search !== '') {
            $conditions .= ' AND (LOWER(posisi) LIKE LOWER(:search:) OR LOWER(namaPerusahaan) LIKE LOWER(:search:) OR LOWER(kota) LIKE LOWER(:search:) OR LOWER(tags) LIKE LOWER(:search:) OR LOWER(deskripsi) LIKE LOWER(:search:))';
            $bind['search'] = '%' . $search . '%';
        }
        
        if ($jenisPekerjaan !== '' && strtolower($jenisPekerjaan) !== 'semua' && strtolower($jenisPekerjaan) !== 'semua tipe') {
            $conditions .= ' AND LOWER(jenisPekerjaan) = LOWER(:jenisPekerjaan:)';
            $bind['jenisPekerjaan'] = $jenisPekerjaan;
        }

        if ($tipeLokasi !== '' && strtolower($tipeLokasi) !== 'semua' && strtolower($tipeLokasi) !== 'semua sistem') {
            $conditions .= ' AND LOWER(tipeLokasi) = LOWER(:tipeLokasi:)';
            $bind['tipeLokasi'] = $tipeLokasi;
        }

        if ($kota !== '' && strtolower($kota) !== 'semua') {
            if (in_array(strtolower($kota), ['remote', 'onsite', 'hybrid'])) {
                $conditions .= ' AND LOWER(tipeLokasi) = LOWER(:kota:)';
                $bind['kota'] = $kota;
            } else {
                $conditions .= ' AND (LOWER(kota) LIKE LOWER(:kotaLike:) OR LOWER(tipeLokasi) = LOWER(:kota:))';
                $bind['kota'] = $kota;
                $bind['kotaLike'] = '%' . $kota . '%';
            }
        }

        $queryOpts = [
            'conditions' => $conditions,
            'bind' => $bind,
            'order' => '[publishedAt] DESC, [createdAt] DESC, [id] DESC'
        ];

        if ($page !== null) {
            $total = Loker::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $queryOpts['limit'] = $limit;
            $queryOpts['offset'] = ($page - 1) * $limit;

            $list = Loker::find($queryOpts);
            $result = [];
            foreach ($list as $item) {
                $result[] = $this->formatLoker($item);
            }

            $this->response->setStatusCode(200);
            return [
                'data' => $result,
                'total' => $total,
            ];
        }

        // Fallback
        $list = Loker::find($queryOpts);
        $result = [];
        foreach ($list as $item) {
            $result[] = $this->formatLoker($item);
        }
        $this->response->setStatusCode(200);
        return $result;
    }

    public function show($id)
    {
        $item = Loker::findFirst([
            'conditions' => '[deletedAt] IS NULL AND id = ?0 AND status = ?1',
            'bind' => [$id, 'Published']
        ]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Loker tidak ditemukan.'];
        }
        $this->response->setStatusCode(200);
        return $this->formatLoker($item);
    }

    private function formatLoker($item)
    {
        $data = $item->toArray();
        if (is_string($data['formLamaran'] ?? null)) {
            $data['formLamaran'] = json_decode($data['formLamaran'], true) ?: [];
        }
        unset($data['pelamar']);

        $data['author'] = $this->formatAuthor($data);
        unset(
            $data['authorId'],
            $data['authorNama'],
            $data['authorRole'],
            $data['authorAvatarUrl'],
        );
        return $data;
    }

    public function create()
    {
        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        if (!$this->getDI()->has('userId') || !$this->getDI()->get('userId')) {
            $this->response->setStatusCode(401);
            return ['error' => 'Unauthorized'];
        }
        $userId = $this->getDI()->get('userId');

        $alumni = \App\Models\Alumni::findFirst(['conditions' => 'id = ?0', 'bind' => [$userId]]);
        if (!$alumni || !in_array($alumni->status, ['APPROVED', 'ACTIVE'])) {
            $this->response->setStatusCode(403);
            return ['error' => 'Hanya alumni yang sudah disetujui oleh admin (Approved) yang dapat mengupload konten.'];
        }

        $item = new Loker();
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
        $item->status = 'Submission';
        $item->authorId = $userId;

        if (isset($req['formLamaran']) && is_array($req['formLamaran'])) {
            $item->formLamaran = json_encode($req['formLamaran']);
        }

        $item->authorNama = $alumni->nama;
        $item->authorRole = 'Alumni';
        $item->authorAvatarUrl = $alumni->avatarUrl;

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menyimpan loker: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(201);
        return ['message' => 'Loker berhasil disubmit.', 'data' => $item->toArray()];
    }

    public function apply($id)
    {
        if (!$this->getDI()->has('userId') || !$this->getDI()->get('userId')) {
            $this->response->setStatusCode(401);
            return ['error' => 'Unauthorized'];
        }
        $userId = $this->getDI()->get('userId');

        $loker = Loker::findFirst([
            'conditions' => '[deletedAt] IS NULL AND id = ?0 AND status = ?1',
            'bind' => [$id, 'Published']
        ]);
        if (!$loker) {
            $this->response->setStatusCode(404);
            return ['error' => 'Loker tidak ditemukan atau tidak tersedia.'];
        }

        // Pengecekan skemaPelamaran dihapus agar eksternal juga tercatat di CMS

        $alumni = \App\Models\Alumni::findFirst(['conditions' => 'id = ?0', 'bind' => [$userId]]);
        if (!$alumni || !in_array($alumni->status, ['APPROVED', 'ACTIVE'])) {
            $this->response->setStatusCode(403);
            return ['error' => 'Hanya alumni terverifikasi yang dapat melamar.'];
        }

        $req = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $lamaran = new \App\Models\Lamaran();
        $lamaran->lokerId = $loker->id;
        $lamaran->alumniId = $userId;
        $lamaran->jawaban = json_encode($req['jawaban'] ?? []);
        $lamaran->status = 'Sedang Direview';

        if ($lamaran->save() === false) {
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal mengirim lamaran.'];
        }

        // Kirim email konfirmasi pendaftaran
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
            $mail->Subject = "Konfirmasi Lamaran Pekerjaan: {$loker->posisi} di {$loker->namaPerusahaan}";
            $mail->Body    = "Kepada {$alumni->nama},\n\nTerima kasih telah mendaftar untuk posisi {$loker->posisi} di {$loker->namaPerusahaan}.\nLamaran Anda saat ini sedang direview oleh admin/pembuat loker.\nKami akan memberitahu Anda jika ada perubahan status pada lamaran Anda.\n\nSalam,\nAdmin IKA JTK";

            $mail->send();
        } catch (Exception $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

            error_log("Gagal mengirim email konfirmasi lamaran: {$mail->ErrorInfo}");
        }

        $this->response->setStatusCode(200);
        return [
            'message' => 'Lamaran berhasil dikirim!', 
            'data' => [
                'id' => $lamaran->id,
                'lokerId' => $lamaran->lokerId,
                'alumniId' => $lamaran->alumniId,
                'status' => $lamaran->status
            ]
        ];
    }
}
