<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;
use App\Models\Alumni;
use App\Enums\AlumniStatus;
use App\Models\OtpCode;
use Firebase\JWT\JWT;

class AuthController extends Controller
{
    private function generateOTP()
    {
        try {
            // Hapus semua OTP yang sudah kedaluwarsa (garbage collection) agar tidak memberatkan DB
            $otps = \App\Models\OtpCode::find([
                'conditions' => 'expiresAt < ?0',
                'bind'       => [date('Y-m-d H:i:s')]
            ]);
            foreach ($otps as $otpCode) {
                $otpCode->delete();
            }
        } catch (\Exception $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

            // Abaikan jika terjadi error DB
        }
        return (string) rand(100000, 999999);
    }

    private function formatAlumniResponse($alumni)
    {
        $data = $alumni->toArray();
        unset($data['password']);

        if (is_string($data['pekerjaan'])) {
            $data['pekerjaan'] = json_decode($data['pekerjaan'], true) ?: [];
        }
        if (is_string($data['prestasi'])) {
            $data['prestasi'] = json_decode($data['prestasi'], true) ?: [];
        }
        if (isset($data['alumniGrafis']) && is_string($data['alumniGrafis'])) {
            $data['alumniGrafis'] = json_decode($data['alumniGrafis'], true) ?: null;
        }

        // Base URL untuk file legacy yang masih tersimpan sebagai path relatif (/uploads/...).
        // File yang sudah dimigrasikan ke Spaces sudah berupa absolute URL dan tidak perlu di-rewrite.
        $baseUrl = $_ENV['APP_URL'] ?? null;
        if (empty($baseUrl)) {
            $scheme = ($this->request->getScheme() ?: 'http');
            $host   = $this->request->getHttpHost() ?: 'localhost:5000';
            $baseUrl = $scheme . '://' . $host;
        }
        $baseUrl = rtrim($baseUrl, '/');

        if (!empty($data['avatarUrl']) && str_starts_with($data['avatarUrl'], '/')) {
            $data['avatarUrl'] = $baseUrl . $data['avatarUrl'];
        }
        // ijazahFile disimpan sebagai key mentah Spaces (misal "ijazah/xxx.pdf") karena sifatnya private —
        // butuh presigned URL yang di-generate on-demand. Value legacy (/uploads/...) tetap di-rewrite ke absolute.
        if (!empty($data['ijazahFile'])) {
            if (str_starts_with($data['ijazahFile'], '/')) {
                $data['ijazahFile'] = $baseUrl . $data['ijazahFile'];
            } elseif (!str_starts_with($data['ijazahFile'], 'http://') && !str_starts_with($data['ijazahFile'], 'https://')) {
                $spaces = $this->di->getShared('spaces');
                $data['ijazahFile'] = $spaces->presignedGetUrl($data['ijazahFile'], 900);
            }
        }

        $data['rejectionReason'] = null;
        if (strtoupper($alumni->status) === \App\Enums\AlumniStatus::REJECTED->value) {
            $verif = \App\Models\AlumniVerification::findFirst([
                'conditions' => 'alumniId = ?0 AND status = ?1 AND deletedAt IS NULL',
                'bind'       => [$alumni->id, \App\Enums\AlumniStatus::REJECTED->value],
                'order'      => 'createdAt DESC'
            ]);
            if ($verif) {
                $data['rejectionReason'] = $verif->reason;
            }
        }

        return $data;
    }

    private function sendOTPEmail($email, $nama, $otp, $isReset = false)
    {
        $config = $this->di->get('config');
        
        $fromEmail = $config['smtp_user'];
        $fromName = 'Alumni IKA JTK';
        if (preg_match('/^(.*?)\s*<(.*?)>$/', $config['smtp_from'], $matches)) {
            $fromName = trim($matches[1]);
            $fromEmail = trim($matches[2]);
        }
        
        $mail = new \PHPMailer\PHPMailer\PHPMailer(true);

        try {
            $mail->isSMTP();
            
            // Mengaktifkan log debug level server untuk mengetahui alasan penolakan
            $mail->SMTPDebug = 2; 
            $mail->Debugoutput = function($str, $level) {
                file_put_contents(BASE_PATH . '/email_error.log', "SMTP DEBUG: $str\n", FILE_APPEND);
            };

            $mail->Host       = $config['smtp_host'];
            $mail->SMTPAuth   = true;
            $mail->Username   = $config['smtp_user'];
            $mail->Password   = $config['smtp_pass'];
            $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port       = $config['smtp_port'];
            $mail->Timeout    = 15; // timeout SMTP connection 15 detik
            $mail->SMTPKeepAlive = false;
            
            // Fix for local SSL/TLS certificate verify issues in Windows
            $mail->SMTPOptions = array(
                'ssl' => array(
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                    'allow_self_signed' => true
                )
            );

            $mail->setFrom($fromEmail, $fromName);
            $mail->addAddress($email, $nama);

            $mail->isHTML(true);
            
            if ($isReset) {
                $mail->Subject = 'Reset Kata Sandi IKA JTK Polban';
                $mail->Body    = "<p>Halo {$nama},</p><p>Anda meminta untuk mereset kata sandi Anda. Kode OTP untuk reset kata sandi Anda adalah: <br><strong><span style='font-size: 24px;'>{$otp}</span></strong></p><p>Kode ini berlaku selama 2 menit. Jika Anda tidak meminta reset kata sandi, abaikan email ini.</p>";
            } else {
                $mail->Subject = 'Kode Verifikasi IKA JTK Polban';
                $mail->Body    = "<p>Halo {$nama},</p><p>Kode verifikasi Anda adalah: <strong>{$otp}</strong></p><p>Kode ini berlaku selama 2 menit.</p>";
            }

            $mail->send();
            return true;
        } catch (\Exception $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }
            file_put_contents(BASE_PATH . '/email_error.log', date('Y-m-d H:i:s') . " Error: " . $mail->ErrorInfo . "\n" . $e->getMessage() . "\n", FILE_APPEND);
            $time = date('Y-m-d H:i:s');
            $logText = "\n==================================================\n"
                     . "SYSTEM DEBUG: [$time] SMTP ERROR\n"
                     . "Endpoint : sendOTPEmail\n"
                     . "Error    : " . $mail->ErrorInfo . "\n"
                     . "Exception: " . $e->getMessage() . "\n"
                     . "==================================================\n";
            file_put_contents(BASE_PATH . '/system_error.log', $logText, FILE_APPEND);
            error_log("Email sending failed: {$mail->ErrorInfo}");
            return false;
        }
    }

    public function checkUnique()
    {
        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();
        $email    = trim($request['email'] ?? '');
        $username = trim($request['username'] ?? '');

        if ($email) {
            $normalizedEmail = strtolower($email);
            $existingEmail = Alumni::findFirst(['conditions' => 'email = ?0', 'bind' => [$normalizedEmail]]);
            if ($existingEmail) {
                if ($existingEmail->status === AlumniStatus::UNVERIFIED->value) {
                    $this->response->setStatusCode(400);
                    return ['available' => false, 'message' => 'Email sudah terdaftar tapi belum diverifikasi. Silakan login untuk memverifikasi OTP.'];
                }
                $this->response->setStatusCode(400);
                return ['available' => false, 'message' => 'Email sudah terdaftar'];
            }
        }

        if ($username) {
            $normalizedUsername = strtolower($username);
            $existingUsername = Alumni::findFirst(['conditions' => 'username = ?0', 'bind' => [$normalizedUsername]]);
            if ($existingUsername) {
                $this->response->setStatusCode(400);
                return ['available' => false, 'message' => 'Username sudah digunakan'];
            }
        }

        $this->response->setStatusCode(200);
        return ['available' => true];
    }

    public function register()
    {
        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $nama         = $request['nama'] ?? '';
        $angkatan     = $request['angkatan'] ?? '';
        $tanggalLahir = $request['tanggalLahir'] ?? '';
        $jenisKelamin = $request['jenisKelamin'] ?? '';
        $email        = $request['email'] ?? '';
        $username     = $request['username'] ?? '';
        $password     = $request['password'] ?? '';

        $userAgreement = !empty($request['userAgreement']) && ($request['userAgreement'] === true || $request['userAgreement'] === 'true' || $request['userAgreement'] === 1 || $request['userAgreement'] === '1');

        if (!$nama || !$angkatan || !$tanggalLahir || !$jenisKelamin || !$email || !$username || !$password) {
            $this->response->setStatusCode(400);
            return ['message' => 'Semua field wajib diisi'];
        }

        if (!$userAgreement) {
            $this->response->setStatusCode(400);
            return ['message' => 'Anda wajib menyetujui Ketentuan & Kebijakan (User Agreements) untuk melanjutkan pendaftaran'];
        }

        if ($tanggalLahir) {
            $birthTime = strtotime($tanggalLahir);
            $today = strtotime(date('Y-m-d'));
            if ($birthTime >= $today) {
                $this->response->setStatusCode(400);
                return ['message' => 'Tanggal lahir tidak boleh hari ini atau di masa depan'];
            }
            if ($angkatan) {
                $birthYear = (int) date('Y', $birthTime);
                $angkatanYear = (int) $angkatan;
                if ($birthYear > $angkatanYear) {
                    $this->response->setStatusCode(400);
                    return ['message' => 'Tahun lahir tidak boleh lebih besar dari tahun angkatan'];
                }
            }
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $this->response->setStatusCode(400);
            return ['message' => 'Format email tidak valid'];
        }

        if (preg_match('/\s/', $username)) {
            $this->response->setStatusCode(400);
            return ['message' => 'Username tidak boleh mengandung spasi'];
        }

        if (preg_match('/\s/', $password)) {
            $this->response->setStatusCode(400);
            return ['message' => 'Kata sandi tidak boleh mengandung spasi'];
        }

        if (strlen($password) < 8) {
            $this->response->setStatusCode(400);
            return ['message' => 'Kata sandi minimal 8 karakter'];
        }

        $normalizedEmail    = strtolower(trim($email));
        $normalizedUsername = strtolower(trim($username));

        // Cek apakah sudah ada di tabel Alumni
        $existingEmail = Alumni::findFirst(['conditions' => 'email = ?0', 'bind' => [$normalizedEmail]]);
        if ($existingEmail) {
            if ($existingEmail->status === AlumniStatus::UNVERIFIED->value) {
                $this->response->setStatusCode(400);
                return ['message' => 'Email sudah terdaftar tapi belum diverifikasi. Silakan login untuk memverifikasi OTP.'];
            }
            $this->response->setStatusCode(400);
            return ['message' => 'Email sudah terdaftar'];
        }

        $existingUsername = Alumni::findFirst(['conditions' => 'username = ?0', 'bind' => [$normalizedUsername]]);
        if ($existingUsername) {
            $this->response->setStatusCode(400);
            return ['message' => 'Username sudah digunakan'];
        }

        $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
        $otp = $this->generateOTP();

        // Gunakan transaksi database agar data hanya tersimpan jika semua proses berhasil
        $db = $this->di->getShared('db');
        $db->begin();

        try {
            $alumni = new Alumni();
            $alumni->nama                    = $nama;
            $alumni->angkatan                = $angkatan;
            $alumni->tanggalLahir            = $tanggalLahir;
            $alumni->jenisKelamin            = $jenisKelamin;
            $alumni->email                   = $normalizedEmail;
            $alumni->username                = $normalizedUsername;
            $alumni->password                = $hashedPassword;
            $alumni->status                  = AlumniStatus::UNVERIFIED->value; 
            $alumni->emailVerified           = false;
            $alumni->userAgreement           = true;

            if ($alumni->save() === false) {
                if ($db->isUnderTransaction()) {
                    $db->rollback();
                }
                $msgs = [];
                foreach ($alumni->getMessages() as $m) $msgs[] = $m->getMessage();
                $errStr = implode(', ', $msgs);
                $time = date('Y-m-d H:i:s');
                $logText = "\n==================================================\n"
                         . "SYSTEM DEBUG: [$time] REGISTRATION DB ERROR\n"
                         . "Endpoint : POST /api/auth/register\n"
                         . "Model    : Alumni\n"
                         . "Error    : " . $errStr . "\n"
                         . "==================================================\n";
                file_put_contents(BASE_PATH . '/system_error.log', $logText, FILE_APPEND);
                $this->response->setStatusCode(500);
                return ['message' => 'Error saving alumni: ' . $errStr, 'errors' => $msgs];
            }

            $otpCode = new OtpCode();
            $otpCode->email = $normalizedEmail;
            $otpCode->code = $otp;
            $otpCode->purpose = 'registration';
            $otpCode->expiresAt = date('Y-m-d H:i:s', time() + (2 * 60));
            
            if ($otpCode->save() === false) {
                if ($db->isUnderTransaction()) {
                    $db->rollback();
                }
                $msgs = [];
                foreach ($otpCode->getMessages() as $m) $msgs[] = $m->getMessage();
                $errStr = implode(', ', $msgs);
                $time = date('Y-m-d H:i:s');
                $logText = "\n==================================================\n"
                         . "SYSTEM DEBUG: [$time] REGISTRATION DB ERROR\n"
                         . "Endpoint : POST /api/auth/register\n"
                         . "Model    : OtpCode\n"
                         . "Error    : " . $errStr . "\n"
                         . "==================================================\n";
                file_put_contents(BASE_PATH . '/system_error.log', $logText, FILE_APPEND);
                $this->response->setStatusCode(500);
                return ['message' => 'Error saving OTP: ' . $errStr, 'errors' => $msgs];
            }

            $sent = $this->sendOTPEmail($normalizedEmail, $nama, $otp);
            if (!$sent) {
                if ($db->isUnderTransaction()) {
                    $db->rollback();
                }
                $time = date('Y-m-d H:i:s');
                $logText = "\n==================================================\n"
                         . "SYSTEM DEBUG: [$time] REGISTRATION SMTP ERROR\n"
                         . "Endpoint : POST /api/auth/register\n"
                         . "Error    : Failed to send OTP email to $normalizedEmail\n"
                         . "==================================================\n";
                file_put_contents(BASE_PATH . '/system_error.log', $logText, FILE_APPEND);
                $this->response->setStatusCode(500);
                return ['message' => 'Gagal mengirim email verifikasi OTP. Registrasi dibatalkan, silakan coba beberapa saat lagi.'];
            }

            $db->commit();

            $this->di->getShared('auditLog')->log([
                'source'      => 'portal',
                'action'      => 'create',
                'actor'       => ['id' => $alumni->id, 'type' => 'alumni', 'name' => $alumni->nama, 'role' => 'Alumni'],
                'entityType'  => 'Alumni',
                'entityId'    => $alumni->id,
                'description' => "Alumni {$alumni->nama} mendaftar akun portal baru",
            ]);

            $this->response->setStatusCode(201);
            return [
                'message' => 'Registrasi berhasil. Silakan cek email Anda untuk kode verifikasi.',
                'email'   => $normalizedEmail
            ];
        } catch (\Throwable $e) {
            if (isset($db) && $db->isUnderTransaction()) {
                $db->rollback();
            }
            $time = date('Y-m-d H:i:s');
            $logText = "\n==================================================\n"
                     . "SYSTEM DEBUG: [$time] REGISTRATION EXCEPTION\n"
                     . "Endpoint : POST /api/auth/register\n"
                     . "Error    : " . $e->getMessage() . "\n"
                     . "File     : " . $e->getFile() . ":" . $e->getLine() . "\n"
                     . "Trace    : " . $e->getTraceAsString() . "\n"
                     . "==================================================\n";
            file_put_contents(BASE_PATH . '/system_error.log', $logText, FILE_APPEND);
            error_log("Register exception: " . $e->getMessage() . " in " . $e->getFile() . ":" . $e->getLine());

            $this->response->setStatusCode(500);
            return [
                'message' => 'Register Exception: ' . $e->getMessage(),
                'error'   => $e->getMessage(),
                'file'    => $e->getFile(),
                'line'    => $e->getLine()
            ];
        }
    }

    public function verify()
    {
        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $email = $request['email'] ?? '';
        $code  = $request['code']  ?? '';

        if (!$email || !$code) {
            $this->response->setStatusCode(400);
            return ['message' => 'Email dan kode verifikasi wajib diisi'];
        }

        $normalizedEmail = strtolower(trim($email));

        // Cari di tabel Alumni
        $alumni = Alumni::findFirst([
            'conditions' => 'deletedAt IS NULL AND email = ?0',
            'bind'       => [$normalizedEmail]
        ]);

        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['message' => 'Data pendaftaran tidak ditemukan. Silakan daftar ulang.'];
        }

        if ($alumni->status !== AlumniStatus::UNVERIFIED->value) {
            $this->response->setStatusCode(200);
            return ['message' => 'Email sudah terverifikasi sebelumnya'];
        }

        $otpRecord = OtpCode::findFirst([
            'conditions' => 'deletedAt IS NULL AND email = ?0 AND code = ?1 AND purpose = ?2',
            'bind'       => [$normalizedEmail, $code, 'registration']
        ]);

        if (!$otpRecord) {
            $this->response->setStatusCode(400);
            return ['message' => 'Kode verifikasi salah atau tidak ditemukan'];
        }

        if ($otpRecord->isUsed) {
            $this->response->setStatusCode(400);
            return ['message' => 'Kode verifikasi sudah digunakan'];
        }

        if (strtotime($otpRecord->expiresAt) < time()) {
            $otpRecord->delete();
            $this->response->setStatusCode(400);
            return ['message' => 'Kode verifikasi telah kedaluwarsa. Silakan tekan Kirim Ulang Kode.'];
        }

        // OTP valid — delete it
        $otpRecord->delete();

        $alumni->status                 = AlumniStatus::PENDING->value;   // alumni baru, menunggu approval admin
        $alumni->emailVerified          = true;

        if ($alumni->save() === false) {
            $this->response->setStatusCode(500);
            return ['message' => 'Terjadi kesalahan saat memverifikasi akun. Silakan coba lagi.'];
        }

        $secret  = $this->di->get('config')['jwt_secret'];
        $payload = ['id' => $alumni->id, 'email' => $alumni->email, 'src' => 'alumni', 'exp' => time() + (3 * 60 * 60)];
        $token   = JWT::encode($payload, $secret, 'HS256');

        $this->di->getShared('auditLog')->log([
            'source'      => 'portal',
            'action'      => 'update',
            'actor'       => ['id' => $alumni->id, 'type' => 'alumni', 'name' => $alumni->nama, 'role' => 'Alumni'],
            'entityType'  => 'Alumni',
            'entityId'    => $alumni->id,
            'description' => "Alumni {$alumni->nama} memverifikasi email registrasi",
        ]);

        $this->response->setStatusCode(200);
        return [
            'message' => 'Email berhasil diverifikasi. Akun berhasil dibuat.',
            'token'   => $token,
            'user'    => $this->formatAlumniResponse($alumni)
        ];
    }

    public function resendOtp()
    {
        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();
        $email   = strtolower(trim($request['email'] ?? ''));

        if (!$email) {
            $this->response->setStatusCode(400);
            return ['message' => 'Email wajib diisi'];
        }

        // Cari di tabel Alumni
        $alumni = Alumni::findFirst([
            'conditions' => 'deletedAt IS NULL AND email = ?0',
            'bind'       => [$email]
        ]);

        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['message' => 'Data pendaftaran tidak ditemukan. Silakan daftar ulang.'];
        }

        if ($alumni->status !== AlumniStatus::UNVERIFIED->value) {
            $this->response->setStatusCode(400);
            return ['message' => 'Akun ini sudah diverifikasi.'];
        }

        $otp = $this->generateOTP();
        
        $otpCode = new OtpCode();
        $otpCode->email = $email;
        $otpCode->code = $otp;
        $otpCode->purpose = 'registration';
        $otpCode->expiresAt = date('Y-m-d H:i:s', time() + (2 * 60));
        if ($otpCode->save() === false) {
            $messages = [];
            foreach ($otpCode->getMessages() as $m) $messages[] = $m->getMessage();
            $this->response->setStatusCode(500);
            return ['message' => 'Gagal menyimpan OTP: ' . implode(', ', $messages)];
        }

        $this->sendOTPEmail($email, $alumni->nama, $otp);

        $this->response->setStatusCode(200);
        return ['message' => 'Kode verifikasi baru telah dikirim ke email Anda.'];
    }

    public function login()
    {
        $allowedIps = $_ENV['ALLOWED_IPS'] ?? '';
        if (!empty($allowedIps)) {
            $allowedList = array_map('trim', explode(',', $allowedIps));
            $clientIp = $this->request->getClientAddress();
            
            // Check if the client IP is in the allowed list
            if (!in_array($clientIp, $allowedList)) {
                $this->response->setStatusCode(403);
                return ['message' => 'IP tidak terdaftar'];
            }
        }

        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $emailOrUsername = $request['emailOrUsername'] ?? '';
        $password        = $request['password'] ?? '';

        if (!$emailOrUsername || !$password) {
            $this->response->setStatusCode(400);
            return ['message' => 'Email/Username dan kata sandi wajib diisi'];
        }

        $key    = strtolower(trim($emailOrUsername));
        $alumni = Alumni::findFirst(['conditions' => 'deletedAt IS NULL AND (email = ?0 OR username = ?1)', 'bind' => [$key, $key]]);

        if (!$alumni) {
            $this->response->setStatusCode(401);
            return ['message' => 'Email/Username atau kata sandi salah'];
        }

        if (!password_verify($password, $alumni->password)) {
            $this->response->setStatusCode(401);
            return ['message' => 'Email/Username atau kata sandi salah'];
        }

        if (strtoupper($alumni->status) === \App\Enums\AlumniStatus::INACTIVE->value) {
            $this->response->setStatusCode(403);
            return ['message' => 'Akun Anda telah dinonaktifkan. Silakan hubungi admin IKA JTK.'];
        }

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

        if ($alumni->status === AlumniStatus::UNVERIFIED->value) {
            // Otomatis buat OTP baru saat user mencoba login agar mereka tidak perlu klik "Kirim Ulang"
            try {
                $otps = \App\Models\OtpCode::find([
                    'conditions' => 'email = ?0',
                    'bind'       => [$alumni->email]
                ]);
                foreach ($otps as $otp) {
                    $otp->delete();
                }
            } catch (\Exception $e) {
            if (isset($e) && $e instanceof \Throwable) {
                file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . ' [CONTROLLER_CATCH] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine() . "\n", FILE_APPEND);
            }

                // Abaikan jika terjadi error DB
            }
            $otp = $this->generateOTP();
            $otpCode = new OtpCode();
            $otpCode->email = $alumni->email;
            $otpCode->code = $otp;
            $otpCode->purpose = 'registration';
            $otpCode->expiresAt = date('Y-m-d H:i:s', time() + (2 * 60));
            $otpCode->save();
            $this->sendOTPEmail($alumni->email, $alumni->nama, $otp);

            $this->response->setStatusCode(403);
            return [
                'message'           => 'Akun belum diverifikasi. Kami telah mengirimkan kode OTP baru ke email Anda.',
                'email'             => $alumni->email,
                'needsVerification' => true
            ];
        }

        $secret  = $this->di->get('config')['jwt_secret'];
        $payload = ['id' => $alumni->id, 'email' => $alumni->email, 'src' => 'alumni', 'exp' => time() + (3 * 60 * 60)];
        $token   = JWT::encode($payload, $secret, 'HS256');

        $this->di->getShared('auditLog')->log([
            'source'      => 'portal',
            'action'      => 'login',
            'actor'       => ['id' => $alumni->id, 'type' => 'alumni', 'name' => $alumni->nama, 'role' => null],
            'entityType'  => 'Alumni',
            'entityId'    => $alumni->id,
            'description' => "Alumni {$alumni->nama} login ke portal",
        ]);

        $this->response->setStatusCode(200);
        return [
            'message' => 'Masuk berhasil',
            'token'   => $token,
            'user'    => $this->formatAlumniResponse($alumni)
        ];
    }

    public function me()
    {
        $userId = $this->di->getShared('userId');
        if (!$userId) {
            $this->response->setStatusCode(401);
            return ['message' => 'Pengguna tidak terautentikasi'];
        }

        $alumni = Alumni::findFirst(['conditions' => 'deletedAt IS NULL AND id = ?0', 'bind' => [$userId]]);

        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['message' => 'Alumni tidak ditemukan'];
        }

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

        return ['user' => $this->formatAlumniResponse($alumni)];
    }

    public function updateProfile()
    {
        $userId = $this->di->getShared('userId');
        if (!$userId) {
            $this->response->setStatusCode(401);
            return ['message' => 'Pengguna tidak terautentikasi'];
        }

        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $alumni = Alumni::findFirst([
            'conditions' => 'deletedAt IS NULL AND id = ?0',
            'bind' => [$userId]
        ]);

        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['message' => 'Alumni tidak ditemukan'];
        }

        if (isset($request['nama'])) {
            $request['nama'] = trim($request['nama']);
            if (empty($request['nama'])) {
                $this->response->setStatusCode(400);
                return ['message' => 'Nama wajib diisi'];
            }
        }

        $oldPekerjaanDB = is_string($alumni->pekerjaan) ? json_decode($alumni->pekerjaan, true) : $alumni->pekerjaan;
        if (!is_array($oldPekerjaanDB)) $oldPekerjaanDB = [];
        $oldPrestasiDB = is_string($alumni->prestasi) ? json_decode($alumni->prestasi, true) : $alumni->prestasi;
        if (!is_array($oldPrestasiDB)) $oldPrestasiDB = [];

        if (isset($request['pekerjaan']) && is_array($request['pekerjaan'])) {
            foreach ($oldPekerjaanDB as $oldPek) {
                if (!empty($oldPek['isGrafis'])) {
                    $found = false;
                    foreach ($request['pekerjaan'] as &$newPek) {
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
                                return ['message' => 'Data pekerjaan yang sudah dilock untuk Alumni Grafis tidak bisa diedit.'];
                            }
                            break;
                        }
                    }
                    if (!$found) {
                        $this->response->setStatusCode(400);
                        return ['message' => 'Data pekerjaan yang sudah dilock untuk Alumni Grafis tidak bisa dihapus.'];
                    }
                }
            }
        }

        if (isset($request['prestasi']) && is_array($request['prestasi'])) {
            foreach ($oldPrestasiDB as $oldPres) {
                if (!empty($oldPres['isGrafis'])) {
                    $found = false;
                    foreach ($request['prestasi'] as &$newPres) {
                        if (($oldPres['id'] ?? null) && ($newPres['id'] ?? null) === $oldPres['id']) {
                            $found = true;
                            $newPres['isGrafis'] = true;
                            if (($oldPres['judul'] ?? '') !== ($newPres['judul'] ?? '') ||
                                ((string)($oldPres['tahun'] ?? '')) !== ((string)($newPres['tahun'] ?? '')) ||
                                ($oldPres['buktiUrl'] ?? '') !== ($newPres['buktiUrl'] ?? '')) {
                                $this->response->setStatusCode(400);
                                return ['message' => 'Data prestasi yang sudah dilock untuk Alumni Grafis tidak bisa diedit.'];
                            }
                            break;
                        }
                    }
                    if (!$found) {
                        $this->response->setStatusCode(400);
                        return ['message' => 'Data prestasi yang sudah dilock untuk Alumni Grafis tidak bisa dihapus.'];
                    }
                }
            }
        }

        $fields = [
            'nama', 'angkatan', 'tanggalLahir', 'jenisKelamin', 'motto', 
            'avatarUrl', 'hp', 'linkedin', 'alamat', 'nomorIjazah', 
            'tahunLulus', 'ipk', 'ijazahFile', 'pekerjaan', 'prestasi',
            'emailVisibility', 'nomorHandphoneVisibility', 'alamatVisibility',
            'alumniGrafis'
        ];

        foreach ($fields as $field) {
            if (array_key_exists($field, $request)) {
                if ($field === 'ipk') {
                    $alumni->$field = (float) $request[$field];
                } elseif (in_array($field, ['pekerjaan', 'prestasi'])) {
                    $alumni->$field = is_array($request[$field]) ? json_encode($request[$field]) : $request[$field];
                } elseif ($field === 'alumniGrafis') {
                    $grafisData = is_array($request['alumniGrafis']) ? $request['alumniGrafis'] : ($request['alumniGrafis'] ? json_decode($request['alumniGrafis'], true) : null);
                    if ($grafisData && isset($grafisData['kategori']) && isset($grafisData['id'])) {
                        // Read current grafis from DB to detect changes
                        $currentGrafisRaw = $alumni->alumniGrafis;
                        $currentGrafis = $currentGrafisRaw ? (is_string($currentGrafisRaw) ? json_decode($currentGrafisRaw, true) : $currentGrafisRaw) : null;
                        
                        $oldKategori = $currentGrafis['kategori'] ?? '';
                        $oldId       = $currentGrafis['id'] ?? '';
                        $oldStatus   = $currentGrafis['status'] ?? '';
                        $newKategori = $grafisData['kategori'];
                        $newId       = $grafisData['id'];
                        
                        $hasChanged = ($newKategori !== $oldKategori || $newId !== $oldId);
                        
                        if ($hasChanged || $oldStatus === 'REJECTED' || $oldStatus === '') {
                            // Data changed or was rejected - reset to PENDING and re-submit
                            $grafisData['status'] = 'PENDING';
                            $alumni->alumniGrafis = json_encode($grafisData);
                            
                            // Delete all old requests for this alumni (so 1 person = 1 request history)
                            $oldRequests = \App\Models\AlumniGrafisRequest::find([
                                'conditions' => 'alumniId = ?0',
                                'bind' => [$alumni->id]
                            ]);
                            foreach ($oldRequests as $old) { $old->delete(); }
                            
                            // Create fresh PENDING request
                            $req = new \App\Models\AlumniGrafisRequest();
                            $req->alumniId = $alumni->id;
                            $req->kategori = $newKategori;
                            $req->grafisId = $newId;
                            $req->status = 'PENDING';
                            $req->save();
                        } else {
                            // No change - preserve existing status unchanged
                            $grafisData['status'] = $oldStatus;
                            $alumni->alumniGrafis = json_encode($grafisData);
                        }
                    } else {
                        $alumni->alumniGrafis = null;
                    }
                } else {
                    $alumni->$field = $request[$field];
                }
            }
        }

        if ($alumni->tanggalLahir) {
            $birthTime = strtotime($alumni->tanggalLahir);
            $today = strtotime(date('Y-m-d'));
            if ($birthTime >= $today) {
                $this->response->setStatusCode(400);
                return ['message' => 'Tanggal lahir tidak boleh hari ini atau di masa depan'];
            }
        }

        if ($alumni->tanggalLahir && $alumni->angkatan) {
            $birthYear = (int) date('Y', strtotime($alumni->tanggalLahir));
            $angkatanYear = (int) $alumni->angkatan;
            if ($birthYear > $angkatanYear) {
                $this->response->setStatusCode(400);
                return ['message' => 'Tahun lahir tidak boleh lebih besar dari tahun angkatan'];
            }
        }
        
        if (isset($request['pekerjaan']) && is_array($request['pekerjaan'])) {
            foreach ($request['pekerjaan'] as $p) {
                if (!empty($p['tahunMulai']) && !empty($p['tahunSelesai']) && empty($p['masihBekerja'])) {
                    if ((int)$p['tahunSelesai'] < (int)$p['tahunMulai']) {
                        $this->response->setStatusCode(400);
                        return ['message' => 'Tahun selesai pekerjaan tidak boleh lebih kecil dari tahun mulai (tidak boleh backdate)'];
                    } elseif ((int)$p['tahunSelesai'] == (int)$p['tahunMulai'] && !empty($p['bulanMulai']) && !empty($p['bulanSelesai'])) {
                        $months = ['Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'Mei' => 5, 'Jun' => 6, 'Jul' => 7, 'Agu' => 8, 'Sep' => 9, 'Okt' => 10, 'Nov' => 11, 'Des' => 12];
                        if (isset($months[$p['bulanSelesai']]) && isset($months[$p['bulanMulai']])) {
                            if ($months[$p['bulanSelesai']] < $months[$p['bulanMulai']]) {
                                $this->response->setStatusCode(400);
                                return ['message' => 'Bulan selesai pekerjaan tidak boleh lebih kecil dari bulan mulai (tidak boleh backdate)'];
                            }
                        }
                    }
                }
            }
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
                return ['message' => 'Nama pekerjaan wajib diisi.'];
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
                return ['message' => 'Tahun prestasi wajib diisi jika judul diisi.'];
            }
            if (!$title && $hasTahun) {
                $this->response->setStatusCode(400);
                return ['message' => 'Judul prestasi wajib diisi jika tahun diisi.'];
            }
            if ($title !== '') {
                $isStrictMode = true;
            }
        }

        if ($grafisData && ($grafisData['kategori'] ?? 'None') !== 'None') {
            if (empty($grafisData['id'])) {
                $this->response->setStatusCode(400);
                return ['message' => 'Pilihan data pekerjaan/prestasi wajib dipilih untuk Alumni Grafis.'];
            }
            $isStrictMode = true;
        }

        if ($isStrictMode) {
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
                return ['message' => 'Mode Ketat: Terdapat data wajib yang belum diisi untuk melengkapi profil (' . implode(', ', $missingFields) . ').'];
            }
        }
        // --- END STRICT MODE & CONDITIONAL VALIDATION ---

        // Check completion status for UNVERIFIED alumni
        $isProfileComplete = 
            $alumni->nama && 
            $alumni->angkatan && 
            $alumni->tanggalLahir && 
            $alumni->hp && 
            $alumni->alamat;

        if ($isProfileComplete && $alumni->status === \App\Enums\AlumniStatus::UNVERIFIED->value) {
            $alumni->status = \App\Enums\AlumniStatus::PENDING->value;
        }

        // Untuk alumni REJECTED, setiap kali memperbarui profil, otomatis kirim ulang untuk verifikasi (PENDING)
        if ($alumni->status === \App\Enums\AlumniStatus::REJECTED->value) {
            $alumni->status = \App\Enums\AlumniStatus::PENDING->value;
        }

        if ($alumni->save() === false) {
            $this->response->setStatusCode(500);
            return ['message' => 'Terjadi kesalahan saat memperbarui profil'];
        }

        $this->di->getShared('auditLog')->log([
            'source'      => 'portal',
            'action'      => 'update',
            'actor'       => ['id' => $alumni->id, 'type' => 'alumni', 'name' => $alumni->nama, 'role' => 'Alumni'],
            'entityType'  => 'Alumni',
            'entityId'    => $alumni->id,
            'description' => "Alumni {$alumni->nama} memperbarui data profil",
        ]);

        $this->response->setStatusCode(200);
        return [
            'message' => 'Profil berhasil diperbarui.',
            'user' => $this->formatAlumniResponse($alumni)
        ];
    }

    public function forgotPassword()
    {
        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();
        $email   = strtolower(trim($request['email'] ?? ''));

        if (!$email) {
            $this->response->setStatusCode(400);
            return ['message' => 'Email wajib diisi'];
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $this->response->setStatusCode(400);
            return ['message' => 'Format email tidak valid'];
        }

        $alumni = Alumni::findFirst([
            'conditions' => 'deletedAt IS NULL AND email = ?0',
            'bind'       => [$email]
        ]);

        if (!$alumni) {
            // Untuk keamanan, sebaiknya mengembalikan pesan sukses (agar tidak menginformasikan email terdaftar atau tidak).
            // Tapi untuk UX yang lebih baik, kita beritahu bahwa email tidak ditemukan jika memang ini policy-nya.
            $this->response->setStatusCode(404);
            return ['message' => 'Email tidak terdaftar'];
        }

        $otp = $this->generateOTP();
        
        $otpCode = new OtpCode();
        $otpCode->email = $email;
        $otpCode->code = $otp;
        $otpCode->purpose = 'password_reset';
        $otpCode->expiresAt = date('Y-m-d H:i:s', time() + (2 * 60));

        if ($otpCode->save() === false) {
            $this->response->setStatusCode(500);
            return ['message' => 'Terjadi kesalahan. Gagal membuat token reset.'];
        }

        $this->sendOTPEmail($email, $alumni->nama, $otp, true);

        $this->response->setStatusCode(200);
        return ['message' => 'Kode OTP untuk reset kata sandi telah dikirim ke email Anda.'];
    }

    public function resetPassword()
    {
        $request = $this->request->getJsonRawBody(true) ?: $this->request->getPost();

        $email       = strtolower(trim($request['email'] ?? ''));
        $otp         = trim($request['otp'] ?? '');
        $newPassword = $request['newPassword'] ?? '';

        if (!$email || !$otp || !$newPassword) {
            $this->response->setStatusCode(400);
            return ['message' => 'Email, OTP, dan kata sandi baru wajib diisi'];
        }

        if (preg_match('/\s/', $newPassword)) {
            $this->response->setStatusCode(400);
            return ['message' => 'Kata sandi baru tidak boleh mengandung spasi'];
        }

        if (strlen($newPassword) < 8) {
            $this->response->setStatusCode(400);
            return ['message' => 'Kata sandi minimal 8 karakter'];
        }

        $alumni = Alumni::findFirst([
            'conditions' => 'deletedAt IS NULL AND email = ?0',
            'bind'       => [$email]
        ]);

        if (!$alumni) {
            $this->response->setStatusCode(404);
            return ['message' => 'Email tidak terdaftar'];
        }

        $otpRecord = OtpCode::findFirst([
            'conditions' => 'deletedAt IS NULL AND email = ?0 AND code = ?1 AND purpose = ?2',
            'bind'       => [$email, $otp, 'password_reset']
        ]);

        if (!$otpRecord) {
            $this->response->setStatusCode(400);
            return ['message' => 'Kode OTP salah atau tidak ditemukan'];
        }

        if ($otpRecord->isUsed) {
            $this->response->setStatusCode(400);
            return ['message' => 'Kode OTP sudah digunakan'];
        }

        if (strtotime($otpRecord->expiresAt) < time()) {
            $otpRecord->delete();
            $this->response->setStatusCode(400);
            return ['message' => 'Kode OTP telah kedaluwarsa. Silakan minta kode baru.'];
        }

        // OTP valid, hapus OTP
        $otpRecord->delete();

        $alumni->password = password_hash($newPassword, PASSWORD_BCRYPT);

        if ($alumni->save() === false) {
            $this->response->setStatusCode(500);
            return ['message' => 'Gagal mereset kata sandi. Silakan coba lagi.'];
        }

        $this->response->setStatusCode(200);
        return ['message' => 'Kata sandi berhasil diatur ulang. Silakan login.'];
    }

    public function logout()
    {
        $userId = $this->di->getShared('userId');

        if ($userId) {
            $name = 'Alumni';
            try {
                $alumni = Alumni::findFirst([
                    'conditions' => 'id = ?0 AND deletedAt IS NULL',
                    'bind' => [$userId]
                ]);
                if ($alumni && !empty($alumni->nama)) {
                    $name = $alumni->nama;
                }
            } catch (\Throwable $e) {}

            $this->di->getShared('auditLog')->log([
                'source'      => 'portal',
                'action'      => 'logout',
                'actor'       => ['id' => $userId, 'type' => 'alumni', 'name' => $name, 'role' => 'Alumni'],
                'entityType'  => 'Alumni',
                'entityId'    => $userId,
                'description' => "Alumni {$name} logout dari portal",
            ]);
        }

        $this->response->setStatusCode(200);
        return ['message' => 'Berhasil keluar'];
    }
}
