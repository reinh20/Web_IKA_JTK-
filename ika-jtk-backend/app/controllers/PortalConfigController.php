<?php
namespace App\Controllers;
use Phalcon\Mvc\Controller;
use App\Models\PortalConfig;

class PortalConfigController extends Controller
{
    private $defaults = [
        'site_name' => 'IKA JTK POLBAN',
        'tagline' => 'Portal Alumni Teknik Komputer dan Informatika POLBAN',
        'logo_url' => '',
        'maintenance_mode' => false,
        'allow_public_registration' => true,
        'hero_slides' => [],
        'about' => ['title' => 'Apa itu IKA JTK?', 'content' => '', 'label' => 'Definisi IKA JTK', 'bgColor' => '#FFF1E5'],
        'features' => [],
        'faqs' => [],
        'organization' => [],
        'contacts' => [
            'instagram' => '@ikajtk.id',
            'email' => 'pengurus@ikajtk.id',
            'whatsapp' => '',
            'alamat' => 'Politeknik Negeri Bandung',
        ],
        'terms_conditions' => [
            'title' => 'User Agreement (Syarat & Ketentuan Pengguna)',
            'subtitle' => 'Perjanjian hukum, ketentuan keanggotaan, dan aturan penggunaan layanan Portal IKA JTK POLBAN.',
            'last_updated' => '',
            'intro' => '',
            'content' => '<p><strong>Tanggal Terakhir Diperbarui: 16 Juli 2026</strong></p><p>Selamat datang di Portal Resmi Ikatan Alumni Teknik Komputer Politeknik Negeri Bandung (IKA JTK POLBAN). Dokumen Syarat dan Ketentuan Pengguna ("Perjanjian") ini mengatur hak, kewajiban, dan batasan hukum antara Anda sebagai pengguna dengan organisasi IKA JTK POLBAN. Dengan mendaftar, mengakses, atau menggunakan layanan pada portal ini, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh isi ketentuan di bawah ini.</p><hr/><h3>1. Kualifikasi dan Verifikasi Keanggotaan</h3><p>Portal ini disediakan khusus untuk melayani jejaring komunikasi dan profesional civitas akademika serta alumni Jurusan Teknik Komputer POLBAN:</p><ul><li>Pendaftaran akun wajib menggunakan identitas asli yang akurat, termasuk Nama Lengkap, Tahun Angkatan, dan Nomor Alumni / bukti kelulusan yang sah.</li><li>Setiap pendaftaran akun baru akan melalui proses verifikasi dan validasi oleh tim Admin / Pengurus IKA JTK POLBAN sebelum status akun diaktifkan secara penuh.</li><li>Tindakan memalsukan identitas akademik, memanipulasi data kelulusan, atau mengatasnamakan alumni lain merupakan pelanggaran hukum berat yang berakibat pada pembatalan akun permanen, pelaporan kepada almamater, serta tindakan hukum sesuai undang-undang yang berlaku.</li></ul><h3>2. Keamanan Akun dan Tanggung Jawab Pengguna</h3><ul><li><strong>Kerahasiaan Kredensial:</strong> Anda bertanggung jawab penuh untuk menjaga kerahasiaan username, kata sandi, serta token akses akun Anda.</li><li><strong>Aktivitas Akun:</strong> Segala bentuk aktivitas, transaksi, dan publikasi konten yang dilakukan melalui akun Anda sepenuhnya menjadi tanggung jawab Anda pribadi.</li><li><strong>Larangan Berbagi Akun:</strong> Akun alumni bersifat personal dan tidak dapat dialihkan, dipinjamkan, atau diperjualbelikan kepada pihak lain dalam kondisi apa pun.</li><li><strong>Pelaporan Insiden:</strong> Jika Anda mengetahui atau mencurigai adanya akses ilegal atau kebocoran kredensial pada akun Anda, Anda wajib segera melaporkannya kepada Pengurus IKA JTK.</li></ul><h3>3. Aturan Penggunaan Layanan (Acceptable Use Policy)</h3><p>Dalam berinteraksi dan memanfaatkan fitur Portal IKA JTK (seperti Direktori Alumni, Lowongan Kerja, Berita, dan Pemilu), setiap pengguna dilarang keras untuk:</p><ul><li>Mengunggah atau menyebarkan informasi palsu (hoaks), penipuan lowongan kerja fiktif, ujaran kebencian, pelecehan, rasisme, pornografi, atau konten yang menyinggung SARA.</li><li>Melakukan aktivitas yang merusak marwah, martabat, dan nama baik organisasi IKA JTK maupun almamater Politeknik Negeri Bandung.</li><li>Melakukan pengumpulan data massal (data scraping/crawling) terhadap direktori alumni atau kontak pribadi anggota tanpa izin tertulis dari Pengurus Pusat IKA JTK POLBAN.</li><li>Melakukan serangan siber, penyebaran virus/malware, atau manipulasi sistem pemungutan suara elektronik (E-Voting/Pemilu Alumni).</li></ul><h3>4. Hak Kekayaan Intelektual dan Lisensi Konten</h3><p>Seluruh hak cipta atas arsitektur sistem, desain grafis, logo organisasi, dan basis data Portal IKA JTK adalah milik sah IKA JTK POLBAN. Terkait konten yang Anda kirimkan (berita, testimoni, lowongan kerja):</p><ul><li><strong>Kepemilikan Konten:</strong> Anda tetap menjadi pemilik hak cipta atas materi/konten yang Anda tulis atau publikasikan di portal ini.</li><li><strong>Lisensi Penayangan:</strong> Dengan mengunggah konten ke dalam portal, Anda memberikan hak non-eksklusif, bebas royalti, dan dapat dialihkan kepada IKA JTK POLBAN untuk menayangkan, mendistribusikan, dan mempromosikan konten tersebut demi kemajuan komunitas alumni.</li><li><strong>Tanggung Jawab Hukum:</strong> Anda menjamin bahwa konten yang Anda unggah tidak melanggar hak cipta pihak ketiga mana pun dan membebaskan IKA JTK dari segala tuntutan hukum yang timbul dari konten Anda.</li></ul><h3>5. Batasan Tanggung Jawab (Limitation of Liability)</h3><p>Layanan portal ini disediakan sebagaimana adanya ("as is" dan "as available"). IKA JTK POLBAN berupaya maksimal menjaga keandalan dan keamanan portal, namun tidak memberikan jaminan bahwa layanan akan selalu bebas dari gangguan teknis, keterlambatan, atau pemeliharaan sistem. IKA JTK POLBAN juga tidak bertanggung jawab atas kerugian material maupun immaterial yang timbul akibat interaksi, kesepakatan karir/bisnis, atau transaksi langsung antar alumni yang dilakukan di luar platform portal.</p><h3>6. Sanksi, Pembatasan, dan Penghentian Layanan</h3><p>Pengurus dan Admin IKA JTK POLBAN memiliki hak prerogatif untuk memberikan peringatan tertulis, membatasi hak akses fitur (suspend), atau menonaktifkan akun secara permanen apabila pengguna terbukti melanggar Syarat dan Ketentuan Pengguna ini, melanggar Kode Etik Komunitas, atau merugikan kepentingan organisasi.</p><h3>7. Perubahan Ketentuan dan Hukum yang Berlaku</h3><p>IKA JTK POLBAN berhak untuk memperbarui atau mengubah Syarat dan Ketentuan Pengguna ini sewaktu-waktu agar selaras dengan perkembangan organisasi dan regulasi yang berlaku. Perubahan akan diinformasikan melalui portal. Perjanjian ini tunduk dan ditafsirkan berdasarkan Hukum Republik Indonesia. Segala sengketa yang timbul akan diselesaikan terlebih dahulu secara musyawarah dan kekeluargaan di bawah mediasi Pengurus Pusat IKA JTK POLBAN.</p>'
        ],
    ];

    private function resolveUrls(array $result)
    {
        $scheme = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'] ?? 'localhost:5000';
        $baseUrl = $scheme . '://' . $host;

        if (isset($result['organization']) && is_array($result['organization'])) {
            foreach ($result['organization'] as &$org) {
                if (is_array($org) && isset($org['imageUrl']) && is_string($org['imageUrl']) && strpos($org['imageUrl'], '/') === 0) {
                    $org['imageUrl'] = $baseUrl . $org['imageUrl'];
                } elseif (is_object($org) && isset($org->imageUrl) && is_string($org->imageUrl) && strpos($org->imageUrl, '/') === 0) {
                    $org->imageUrl = $baseUrl . $org->imageUrl;
                }
            }
            unset($org);
        }

        foreach (['hero_slides', 'heroSlides'] as $slideKey) {
            if (isset($result[$slideKey]) && is_array($result[$slideKey])) {
                foreach ($result[$slideKey] as &$slide) {
                    if (is_array($slide) && isset($slide['imageUrl']) && is_string($slide['imageUrl']) && strpos($slide['imageUrl'], '/') === 0) {
                        $slide['imageUrl'] = $baseUrl . $slide['imageUrl'];
                    } elseif (is_object($slide) && isset($slide->imageUrl) && is_string($slide->imageUrl) && strpos($slide->imageUrl, '/') === 0) {
                        $slide->imageUrl = $baseUrl . $slide->imageUrl;
                    }
                }
                unset($slide);
            }
        }

        if (isset($result['about_banner']) && is_array($result['about_banner'])) {
            foreach (['imageUrl', 'logoUrl'] as $imgKey) {
                if (isset($result['about_banner'][$imgKey]) && is_string($result['about_banner'][$imgKey]) && strpos($result['about_banner'][$imgKey], '/') === 0) {
                    $result['about_banner'][$imgKey] = $baseUrl . $result['about_banner'][$imgKey];
                }
            }
        }

        if (isset($result['logo_url']) && is_string($result['logo_url']) && strpos($result['logo_url'], '/') === 0) {
            $result['logo_url'] = $baseUrl . $result['logo_url'];
        }

        return $result;
    }

    private function castBooleans(array $result): array
    {
        // PHP json_decode(value, true) returns 1/0 for booleans stored in DB.
        // Explicitly re-cast so json_encode serialises as JSON true/false.
        foreach (['maintenance_mode', 'allow_public_registration'] as $field) {
            if (array_key_exists($field, $result)) {
                $result[$field] = (bool) $result[$field];
            }
        }
        return $result;
    }

    public function index()
    {
        $all = PortalConfig::find(['conditions' => 'deletedAt IS NULL']);
        $result = [];
        foreach ($all as $config) {
            if ($config->value !== null) {
                $result[$config->key] = $config->value;
            }
        }
        $result = array_merge($this->defaults, $result);
        $result = $this->resolveUrls($result);
        $result = $this->castBooleans($result);

        $this->response->setStatusCode(200);
        $this->response->setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
        $this->response->setHeader('Pragma', 'no-cache');
        return $result;
    }

    public function update()
    {
        $request = $this->request->getJsonRawBody(true);
        if (!is_array($request) || empty($request)) {
            $request = $this->request->getPost();
        }
        if (!is_array($request) || empty($request)) {
            $this->response->setStatusCode(400);
            return ['error' => 'Tidak ada data yang dikirim.'];
        }
        
        foreach ($request as $key => $value) {
            $config = PortalConfig::findFirst([
                'conditions' => 'key = ?0 AND deletedAt IS NULL', 'bind' => [$key]
            ]);
            
            if (!$config) {
                $config = new PortalConfig();
                $config->key = $key;
            }
            
            $config->value = $value;
            if ($config->save() === false) {
                $messages = $config->getMessages();
                $this->response->setStatusCode(400);
                return ['error' => 'Gagal menyimpan: ' . $key, 'detail' => implode(', ', $messages)];
            }
        }

        return $this->index();
    }

    public function publicConfig()
    {
        $all = PortalConfig::find(['conditions' => 'deletedAt IS NULL']);
        $result = [];
        foreach ($all as $config) {
            if ($config->value !== null) {
                $result[$config->key] = $config->value;
            }
        }
        $result = array_merge($this->defaults, $result);
        // maintenance_mode is intentionally kept in public config so the portal
        // can detect it and show a maintenance page to users.
        $result = $this->resolveUrls($result);
        $result = $this->castBooleans($result);
        
        $this->response->setStatusCode(200);
        $this->response->setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
        $this->response->setHeader('Pragma', 'no-cache');
        return $result;
    }
}
