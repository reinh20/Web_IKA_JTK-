<?php

use Phalcon\Mvc\Micro\Collection as MicroCollection;
use App\Controllers\AuthController;
use App\Controllers\ElectionController;
use App\Controllers\AdminElectionController;
use App\Controllers\AdminAlumniController;
use App\Controllers\UploadController;
use App\Controllers\PortalConfigController;
use App\Controllers\PortalBeritaController;
use App\Controllers\PortalAgendaController;
use App\Controllers\PortalLokerController;
use App\Controllers\PortalAlumniController;
use App\Controllers\PortalLamaranController;

// --- Auth Routes ---
$authCollection = new MicroCollection();
$authCollection->setHandler(new AuthController())
               ->setPrefix('/api/auth');
               
$authCollection->post('/register', 'register');
$authCollection->post('/check-unique', 'checkUnique');
$authCollection->post('/resend-otp', 'resendOtp');
$authCollection->post('/verify-email', 'verify');
$authCollection->post('/login', 'login');
$authCollection->post('/logout', 'logout');
$authCollection->post('/forgot-password', 'forgotPassword');
$authCollection->post('/reset-password', 'resetPassword');
$authCollection->get('/me', 'me');
$authCollection->put('/profile', 'updateProfile');

$app->mount($authCollection);

// --- Election Routes ---
$electionCollection = new MicroCollection();
$electionCollection->setHandler(new ElectionController())
                   ->setPrefix('/api/elections');
                   
$electionCollection->get('/', 'index');
$electionCollection->get('/{id}/summary', 'summary');
$electionCollection->get('/{id}', 'show');
$electionCollection->post('/vote', 'vote');

$app->mount($electionCollection);

// --- Admin Election Routes ---
$adminElectionCollection = new MicroCollection();
$adminElectionCollection->setHandler(new AdminElectionController())
                        ->setPrefix('/api/admin/elections');

$adminElectionCollection->get('/', 'index');
$adminElectionCollection->get('/{id}/summary', 'summary');
$adminElectionCollection->get('/{id}', 'show');
$adminElectionCollection->post('/', 'create');
$adminElectionCollection->put('/{id}', 'update');
$adminElectionCollection->delete('/{id}', 'delete');

// Candidate Management
$adminElectionCollection->post('/{electionId}/candidates', 'addCandidate');
$adminElectionCollection->put('/{electionId}/candidates/{candidateId}', 'updateCandidate');
$adminElectionCollection->delete('/{electionId}/candidates/{candidateId}', 'deleteCandidate');

$app->mount($adminElectionCollection);

// --- Admin Alumni Routes ---
$adminAlumniCollection = new MicroCollection();
$adminAlumniCollection->setHandler(new \App\Controllers\AdminAlumniController())
                      ->setPrefix('/api/admin/alumni');
$adminAlumniCollection->get('/', 'index');
$adminAlumniCollection->get('/{id}', 'show');
$adminAlumniCollection->post('/', 'create');
$adminAlumniCollection->put('/{id}', 'update');
$adminAlumniCollection->delete('/{id}', 'delete');
$adminAlumniCollection->post('/{id}/approve', 'approve');
$adminAlumniCollection->post('/{id}/reject', 'reject');
$adminAlumniCollection->put('/{id}/role', 'updateRole');
$app->mount($adminAlumniCollection);

// --- Upload Routes ---
$uploadCollection = new MicroCollection();
$uploadCollection->setHandler(new UploadController())
                 ->setPrefix('/api/upload');
                 
$uploadCollection->post('/', 'upload');
$uploadCollection->post('/general', 'upload');
$uploadCollection->post('/avatar', 'avatar');
$uploadCollection->post('/document', 'document');
$uploadCollection->post('/ijazah', 'ijazah');

$app->mount($uploadCollection);

// --- Admin Auth Routes ---
$adminAuthCollection = new MicroCollection();
$adminAuthCollection->setHandler(new \App\Controllers\AdminAuthController())
                    ->setPrefix('/api/admin/auth');
$adminAuthCollection->post('/login', 'login');
$adminAuthCollection->post('/logout', 'logout');
$adminAuthCollection->get('/me', 'me');
$app->mount($adminAuthCollection);

// --- Admin Users Routes ---
$adminUsersCollection = new MicroCollection();
$adminUsersCollection->setHandler(new \App\Controllers\AdminUsersController())
                     ->setPrefix('/api/admin/users');
$adminUsersCollection->get('/', 'index');
$adminUsersCollection->get('/{id}', 'show');
$adminUsersCollection->post('/', 'create');
$adminUsersCollection->put('/{id}', 'update');
$adminUsersCollection->delete('/{id}', 'delete');
$app->mount($adminUsersCollection);


// --- Admin Berita Routes ---
$adminBeritaCollection = new MicroCollection();
$adminBeritaCollection->setHandler(new \App\Controllers\AdminBeritaController())
                      ->setPrefix('/api/admin/berita');
$adminBeritaCollection->get('/', 'index');
$adminBeritaCollection->get('/{id}', 'show');
$adminBeritaCollection->post('/', 'create');
$adminBeritaCollection->put('/{id}', 'update');
$adminBeritaCollection->delete('/{id}', 'delete');
$adminBeritaCollection->post('/{id}/approve', 'approve');
$adminBeritaCollection->post('/{id}/reject', 'reject');
$app->mount($adminBeritaCollection);

// --- Admin Agenda Routes ---
$adminAgendaCollection = new MicroCollection();
$adminAgendaCollection->setHandler(new \App\Controllers\AdminAgendaController())
                      ->setPrefix('/api/admin/agenda');
$adminAgendaCollection->get('/', 'index');
$adminAgendaCollection->get('/{id}', 'show');
$adminAgendaCollection->post('/', 'create');
$adminAgendaCollection->put('/{id}', 'update');
$adminAgendaCollection->delete('/{id}', 'delete');
$adminAgendaCollection->post('/{id}/approve', 'approve');
$adminAgendaCollection->post('/{id}/reject', 'reject');
$app->mount($adminAgendaCollection);

// --- Admin Loker Routes ---
$adminLokerCollection = new MicroCollection();
$adminLokerCollection->setHandler(new \App\Controllers\AdminLokerController())
                     ->setPrefix('/api/admin/loker');
$adminLokerCollection->get('/', 'index');
$adminLokerCollection->get('/{id}', 'show');
$adminLokerCollection->post('/', 'create');
$adminLokerCollection->put('/{id}', 'update');
$adminLokerCollection->delete('/{id}', 'delete');
$adminLokerCollection->post('/{id}/approve', 'approve');
$adminLokerCollection->post('/{id}/reject', 'reject');
$adminLokerCollection->put('/{id}/lamaran/{lamaranId}/status', 'updateLamaranStatus');
$adminLokerCollection->delete('/{id}/lamaran/{lamaranId}', 'deleteLamaran');
$app->mount($adminLokerCollection);

// --- Admin Alumni Routes ---
$adminAlumniCollection = new MicroCollection();
$adminAlumniCollection->setHandler(new \App\Controllers\AdminAlumniController())
                      ->setPrefix('/api/admin/alumni');
$adminAlumniCollection->get('/', 'index');
$adminAlumniCollection->get('/{id}', 'show');
$adminAlumniCollection->put('/{id}', 'update');
$adminAlumniCollection->delete('/{id}', 'delete');
$adminAlumniCollection->post('/{id}/approve', 'approve');
$adminAlumniCollection->post('/{id}/reject', 'reject');
$adminAlumniCollection->post('/{id}/role', 'updateRole');
$app->mount($adminAlumniCollection);

// --- Admin Alumni Grafis Routes ---
$adminAlumniGrafisCollection = new MicroCollection();
$adminAlumniGrafisCollection->setHandler(new \App\Controllers\AdminAlumniController())
                            ->setPrefix('/api/admin/alumni-grafis');
$adminAlumniGrafisCollection->get('/', 'getAlumniGrafisRequests');
$adminAlumniGrafisCollection->post('/{id}/verify', 'verifyAlumniGrafis');
$app->mount($adminAlumniGrafisCollection);

// --- Testimoni Routes (alumni) ---
$testimoniCollection = new MicroCollection();
$testimoniCollection->setHandler(new \App\Controllers\TestimoniController())
                    ->setPrefix('/api/testimoni');
$testimoniCollection->get('/', 'index');
$testimoniCollection->get('/me', 'me');
$testimoniCollection->post('/', 'create');
$app->mount($testimoniCollection);

// --- Admin Testimoni Routes ---
$adminTestimoniCollection = new MicroCollection();
$adminTestimoniCollection->setHandler(new \App\Controllers\AdminTestimoniController())
                         ->setPrefix('/api/admin/testimoni');
$adminTestimoniCollection->get('/', 'index');
$adminTestimoniCollection->get('/{id}', 'show');
$adminTestimoniCollection->put('/{id}', 'update');
$adminTestimoniCollection->delete('/{id}', 'delete');
$app->mount($adminTestimoniCollection);

// Admin Role Routes
$adminRoleCollection = new MicroCollection();
$adminRoleCollection->setHandler(new \App\Controllers\AdminRoleController())
                    ->setPrefix('/api/admin/roles');
$adminRoleCollection->get('/', 'index');
$adminRoleCollection->post('/', 'create');
$adminRoleCollection->put('/{name}', 'update');
$adminRoleCollection->delete('/{name}', 'delete');
$app->mount($adminRoleCollection);

// Admin Users Routes
$adminUsersCollection = new MicroCollection();
$adminUsersCollection->setHandler(new \App\Controllers\AdminUsersController())
                     ->setPrefix('/api/admin/users');
$adminUsersCollection->get('/', 'index');
$adminUsersCollection->get('/{id}', 'show');
$adminUsersCollection->post('/', 'create');
$adminUsersCollection->put('/{id}', 'update');
$adminUsersCollection->delete('/{id}', 'delete');
$app->mount($adminUsersCollection);

// --- Admin Audit Log Routes (read-only) ---
$adminAuditLogCollection = new MicroCollection();
$adminAuditLogCollection->setHandler(new \App\Controllers\AdminAuditLogController())
                        ->setPrefix('/api/admin/audit-logs');
$adminAuditLogCollection->get('/', 'index');
$adminAuditLogCollection->get('/{id}', 'show');
$app->mount($adminAuditLogCollection);

// --- API Documentation (Swagger UI) ---
$app->get('/docs', function () use ($app) {
    $app->response->setContentType('text/html', 'UTF-8');
    $app->response->setContent(file_get_contents(BASE_PATH . '/public/docs.html'));
    return $app->response->send();
});
// --- Admin Pemilu Routes ---
$adminPemiluCollection = new MicroCollection();
$adminPemiluCollection->setHandler(new \App\Controllers\AdminPemiluController())
                      ->setPrefix('/api/admin/pemilu');
$adminPemiluCollection->get('/', 'index');
$adminPemiluCollection->get('/{id}', 'show');
$adminPemiluCollection->post('/', 'create');
$adminPemiluCollection->put('/{id}', 'update');
$adminPemiluCollection->delete('/{id}', 'delete');
$app->mount($adminPemiluCollection);

// --- Portal Config Routes ---
$portalConfigCollection = new MicroCollection();
$portalConfigCollection->setHandler(new \App\Controllers\PortalConfigController())
                       ->setPrefix('/api/admin/portal-config');
$portalConfigCollection->get('/', 'index');
$portalConfigCollection->put('/', 'update');
$app->mount($portalConfigCollection);

// --- Public Portal Config ---
$publicConfigCollection = new MicroCollection();
$publicConfigCollection->setHandler(new \App\Controllers\PortalConfigController())
                       ->setPrefix('/api/portal');
$publicConfigCollection->get('/config', 'publicConfig');
$app->mount($publicConfigCollection);

// --- Portal Public Routes ---
$portalBeritaCollection = new MicroCollection();
$portalBeritaCollection->setHandler(new PortalBeritaController())
                       ->setPrefix('/api/portal/berita');
$portalBeritaCollection->get('/', 'index');
$portalBeritaCollection->get('/{id}', 'show');
$portalBeritaCollection->post('/', 'create');
$app->mount($portalBeritaCollection);

$portalAgendaCollection = new MicroCollection();
$portalAgendaCollection->setHandler(new PortalAgendaController())
                       ->setPrefix('/api/portal/agenda');
$portalAgendaCollection->get('/', 'index');
$portalAgendaCollection->get('/{id}', 'show');
$portalAgendaCollection->post('/', 'create');
$portalAgendaCollection->post('/{id}/reservasi', 'reservasi');
$app->mount($portalAgendaCollection);

$portalLokerCollection = new MicroCollection();
$portalLokerCollection->setHandler(new PortalLokerController())
                       ->setPrefix('/api/portal/loker');
$portalLokerCollection->get('/', 'index');
$portalLokerCollection->get('/{id}', 'show');
$portalLokerCollection->post('/', 'create');
$portalLokerCollection->post('/{id}/apply', 'apply');
$app->mount($portalLokerCollection);

$portalAlumniCollection = new MicroCollection();
$portalAlumniCollection->setHandler(new PortalAlumniController())
                       ->setPrefix('/api/portal/alumni');
$portalAlumniCollection->get('/', 'index');
$portalAlumniCollection->get('/{id}', 'show');
$app->mount($portalAlumniCollection);

$portalLamaranCollection = new MicroCollection();
$portalLamaranCollection->setHandler(new \App\Controllers\PortalLamaranController())
                        ->setPrefix('/api/portal/lamaran');
$portalLamaranCollection->get('/', 'index');
$portalLamaranCollection->get('', 'index');
$app->mount($portalLamaranCollection);

// --- Public File Serving (Fallback if not handled by web server) ---
$fileCollection = new MicroCollection();
$fileCollection->setHandler(new \App\Controllers\FileController())
               ->setPrefix('/uploads');
$fileCollection->get('/{folder}/{file}', 'serve');
$app->mount($fileCollection);

// Route Not Found (404)
$app->notFound(function () use ($app) {
    // Sertakan CORS header supaya 404 tidak muncul sebagai error CORS yang misleading di browser.
    $origin = $app->request->getHeader('Origin') ?: '*';
    $app->response->setHeader('Access-Control-Allow-Origin', $origin);
    $app->response->setHeader('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
    $app->response->setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Range, Content-Disposition, Content-Type, Authorization');
    $app->response->setHeader('Access-Control-Allow-Credentials', 'true');
    $app->response->setStatusCode(404, 'Not Found');
    $app->response->setContentType('application/json', 'UTF-8');
    $app->response->setContent(json_encode([
        'status' => 'error',
        'message' => 'Endpoint tidak ditemukan.'
    ]));
    $app->response->send();
});
