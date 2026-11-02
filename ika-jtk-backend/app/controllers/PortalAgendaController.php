<?php
namespace App\Controllers;
use Phalcon\Mvc\Controller;
use App\Models\Agenda;
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use App\Traits\AuthorFormatter;

class PortalAgendaController extends Controller
{
    use AuthorFormatter;
    public function index()
    {
        $upcoming = $this->request->getQuery('upcoming', 'string', 'false');
        $page = $this->request->getQuery('page', 'int', null);
        $limit = $this->request->getQuery('limit', 'int', 10);
        $search = $this->request->getQuery('search', 'string', '');
        $lokasi = $this->request->getQuery('lokasi', 'string', '');

        $conditions = '[deletedAt] IS NULL AND status = :status:';
        $bind = ['status' => 'Published'];
        
        if ($upcoming === 'true') {
            $conditions .= ' AND tanggalEvent >= :tanggalEvent:';
            $bind['tanggalEvent'] = date('Y-m-d');
        } else if ($upcoming === 'past') {
            $conditions .= ' AND tanggalEvent < :tanggalEvent:';
            $bind['tanggalEvent'] = date('Y-m-d');
        }

        if ($search !== '') {
            $conditions .= ' AND (LOWER(judul) LIKE LOWER(:search:) OR LOWER(deskripsi) LIKE LOWER(:search:))';
            $bind['search'] = '%' . $search . '%';
        }

        if ($lokasi !== '') {
            $conditions .= ' AND LOWER(lokasi) LIKE LOWER(:lokasi:)';
            $bind['lokasi'] = '%' . $lokasi . '%';
        }

        $queryOpts = [
            'conditions' => $conditions,
            'bind' => $bind,
            'order' => $upcoming === 'past' ? '[tanggalEvent] DESC, [createdAt] DESC, [id] DESC' : '[tanggalEvent] ASC, [createdAt] DESC, [id] DESC'
        ];

        if ($page !== null) {
            $total = Agenda::count([
                'conditions' => $conditions,
                'bind' => $bind
            ]);

            $queryOpts['limit'] = $limit;
            $queryOpts['offset'] = ($page - 1) * $limit;

            $list = Agenda::find($queryOpts);
            $result = [];
            foreach ($list as $item) {
                $data = $item->toArray();
                $data['author'] = $this->formatAuthor($data);
                unset($data['authorId'], $data['authorNama'], $data['authorRole'], $data['authorAvatarUrl']);
                $result[] = $data;
            }

            $this->response->setStatusCode(200);
            return [
                'data' => $result,
                'total' => $total,
            ];
        }

        // Fallback
        $list = Agenda::find($queryOpts);
        $result = [];
        foreach ($list as $item) {
            $data = $item->toArray();
            $data['author'] = $this->formatAuthor($data);
            unset($data['authorId'], $data['authorNama'], $data['authorRole'], $data['authorAvatarUrl']);
            $result[] = $data;
        }
        $this->response->setStatusCode(200);
        return $result;
    }

    public function show($id)
    {
        $item = Agenda::findFirst([
            'conditions' => '[deletedAt] IS NULL AND id = ?0 AND status = ?1',
            'bind' => [$id, 'Published']
        ]);
        if (!$item) {
            $this->response->setStatusCode(404);
            return ['error' => 'Agenda tidak ditemukan.'];
        }
        $data = $item->toArray();
        $data['author'] = $this->formatAuthor($data);
        unset($data['authorId'], $data['authorNama'], $data['authorRole'], $data['authorAvatarUrl']);
        $this->response->setStatusCode(200);
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

        $item = new Agenda();
        $item->judul = $req['judul'] ?? '';
        $item->deskripsi = $req['deskripsi'] ?? '';
        $item->bannerUrl = $req['bannerUrl'] ?? null;
        $item->bannerThumbnailUrl = $req['bannerThumbnailUrl'] ?? null;
        $item->tags = $req['tags'] ?? '';
        $item->tanggalEvent = $req['tanggalEvent'] ?? date('Y-m-d');
        $item->waktu = $req['waktu'] ?? '';
        $item->lokasi = $req['lokasi'] ?? '';
        $item->status = 'Submission';
        $item->authorId = $userId;
        
        $alumni = \App\Models\Alumni::findFirst(['conditions' => 'id = ?0', 'bind' => [$userId]]);
        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['error' => 'Alumni tidak ditemukan'];
        }
        if (!in_array($alumni->status, ['APPROVED', 'ACTIVE'])) {
            $this->response->setStatusCode(403);
            return ['error' => 'Hanya alumni yang sudah disetujui oleh admin (Approved) yang dapat mengupload konten.'];
        }

        $item->authorNama = $alumni->nama;
        $item->authorRole = 'Alumni';
        $item->authorAvatarUrl = $alumni->avatarUrl;

        if ($item->save() === false) {
            $this->response->setStatusCode(400);
            return ['error' => 'Gagal menyimpan agenda: ' . implode(', ', $item->getMessages())];
        }

        $this->response->setStatusCode(201);
        return ['message' => 'Agenda berhasil disubmit.', 'data' => $item->toArray()];
    }

    public function reservasi($id)
    {
        if (!$this->getDI()->has('userId') || !$this->getDI()->get('userId')) {
            $this->response->setStatusCode(401);
            return ['error' => 'Unauthorized'];
        }
        $userId = $this->getDI()->get('userId');

        $agenda = Agenda::findFirst([
            'conditions' => '[deletedAt] IS NULL AND id = ?0 AND status = ?1',
            'bind' => [$id, 'Published']
        ]);

        if (!$agenda) {
            $this->response->setStatusCode(404);
            return ['error' => 'Agenda tidak ditemukan atau tidak tersedia.'];
        }

        if (strtotime($agenda->tanggalEvent) < strtotime(date('Y-m-d'))) {
            $this->response->setStatusCode(400);
            return ['error' => 'Agenda telah berlalu dan tidak dapat dihadiri.'];
        }

        $alumni = \App\Models\Alumni::findFirst(['conditions' => 'id = ?0', 'bind' => [$userId]]);
        if (!$alumni || !in_array($alumni->status, ['APPROVED', 'ACTIVE'])) {
            $this->response->setStatusCode(403);
            return ['error' => 'Hanya alumni terverifikasi yang dapat melakukan reservasi.'];
        }

        // Cek apakah sudah reservasi
        $existing = \App\Models\PesertaAgenda::findFirst([
            'conditions' => '[agendaId] = ?0 AND [alumniId] = ?1',
            'bind' => [$id, $userId]
        ]);

        if ($existing) {
            $this->response->setStatusCode(400);
            return ['error' => 'Anda sudah terdaftar pada agenda ini.'];
        }

        $peserta = new \App\Models\PesertaAgenda();
        $peserta->agendaId = $id;
        $peserta->alumniId = $userId;
        $peserta->nama = $alumni->nama;
        $peserta->email = $alumni->email;

        if ($peserta->save() === false) {
            $this->response->setStatusCode(500);
            return ['error' => 'Gagal melakukan reservasi.'];
        }

        // Kirim email via SMTP
        $config = $this->getDI()->get('config');
        $mail = new PHPMailer(true);
        try {
            // Server settings
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

            // Recipients
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

            // Content
            $mail->isHTML(false);
            $mail->Subject = 'Konfirmasi Reservasi Agenda: ' . $agenda->judul;
            $mail->Body    = "Kepada {$alumni->nama},\n\nTerima kasih telah melakukan reservasi untuk agenda '{$agenda->judul}'.\nTanggal: {$agenda->tanggalEvent}\nWaktu: {$agenda->waktu}\nLokasi: {$agenda->lokasi}\n\nSalam,\nAdmin IKA JTK";

            $mail->send();
        } catch (Exception $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

            error_log("Gagal mengirim email reservasi: {$mail->ErrorInfo}");
        }

        $this->response->setStatusCode(200);
        return [
            'message' => 'Reservasi berhasil! Detail acara telah dikirim ke email Anda (simulasi).',
            'data' => $peserta->toArray()
        ];
    }
}
