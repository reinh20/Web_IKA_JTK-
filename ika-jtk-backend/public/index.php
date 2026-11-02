<?php

// Global CORS preflight handler — dijalankan sebelum Phalcon supaya OPTIONS
// tidak pernah nyangkut di router yang bisa crash / return non-2xx.
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Vary: Origin');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Range, Content-Disposition, Content-Type, Accept, Authorization');
    header('Access-Control-Max-Age: 86400');
    http_response_code(204);
    exit;
}

// Serve static files with CORS (untuk PHP Built-in Server)
if (php_sapi_name() === 'cli-server') {
    $uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));
    $filePath = __DIR__ . $uri;
    if ($uri !== '/' && file_exists($filePath)) {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, OPTIONS');
        header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization');

        $ext = pathinfo($filePath, PATHINFO_EXTENSION);
        $mimeTypes = [
            'jpg' => 'image/jpeg',
            'jpeg'=> 'image/jpeg',
            'png' => 'image/png',
            'webp'=> 'image/webp',
            'pdf' => 'application/pdf',
            'html'=> 'text/html',
            'yaml'=> 'application/x-yaml',
            'yml' => 'application/x-yaml',
            'json'=> 'application/json'
        ];
        
        if (isset($mimeTypes[strtolower($ext)])) {
            header('Content-Type: ' . $mimeTypes[strtolower($ext)]);
        }
        
        readfile($filePath);
        exit;
    }
}

use Phalcon\Di\FactoryDefault;
use Phalcon\Mvc\Micro;
use Phalcon\Events\Manager as EventsManager;
use Dotenv\Dotenv;

date_default_timezone_set('Asia/Jakarta');

error_reporting(E_ALL);
ini_set('display_errors', '0');

set_error_handler(function($severity, $message, $file, $line) {
    if (!(error_reporting() & $severity)) {
        return;
    }
    throw new \ErrorException($message, 0, $severity, $file, $line);
});

define('BASE_PATH', dirname(__DIR__));
define('APP_PATH', BASE_PATH . '/app');

set_error_handler(function($errno, $errstr, $errfile, $errline) {
    if (!(error_reporting() & $errno)) {
        return false;
    }
    $time = date('Y-m-d H:i:s');
    $method = $_SERVER['REQUEST_METHOD'] ?? '';
    $url = $_SERVER['REQUEST_URI'] ?? '';
    $errNames = [
        E_ERROR => 'E_ERROR', E_WARNING => 'E_WARNING', E_PARSE => 'E_PARSE',
        E_NOTICE => 'E_NOTICE', E_CORE_ERROR => 'E_CORE_ERROR', E_CORE_WARNING => 'E_CORE_WARNING',
        E_COMPILE_ERROR => 'E_COMPILE_ERROR', E_COMPILE_WARNING => 'E_COMPILE_WARNING',
        E_USER_ERROR => 'E_USER_ERROR', E_USER_WARNING => 'E_USER_WARNING',
        E_USER_NOTICE => 'E_USER_NOTICE', E_STRICT => 'E_STRICT',
        E_RECOVERABLE_ERROR => 'E_RECOVERABLE_ERROR', E_DEPRECATED => 'E_DEPRECATED',
        E_USER_DEPRECATED => 'E_USER_DEPRECATED'
    ];
    $errType = $errNames[$errno] ?? ("UNKNOWN_ERROR_" . $errno);
    $logText = "\n==================================================\n"
             . "SYSTEM DEBUG: [$time] PHP SYSTEM ERROR ($errType)\n"
             . "Endpoint : $method $url\n"
             . "File     : $errfile (Line: $errline)\n"
             . "Error    : $errstr\n"
             . "==================================================\n";
    file_put_contents(BASE_PATH . '/system_error.log', $logText, FILE_APPEND);
    return false;
});

set_exception_handler(function($e) {
    $time = date('Y-m-d H:i:s');
    $method = $_SERVER['REQUEST_METHOD'] ?? '';
    $url = $_SERVER['REQUEST_URI'] ?? '';
    $type = get_class($e);
    $msg = $e->getMessage();
    $file = $e->getFile();
    $line = $e->getLine();
    $trace = $e->getTraceAsString();
    $logText = "\n==================================================\n"
             . "SYSTEM DEBUG: [$time] UNCAUGHT SYSTEM EXCEPTION: $type\n"
             . "Endpoint : $method $url\n"
             . "File     : $file (Line: $line)\n"
             . "Error    : $msg\n"
             . "Trace    :\n$trace\n"
             . "==================================================\n";
    file_put_contents(BASE_PATH . '/system_error.log', $logText, FILE_APPEND);
});

register_shutdown_function(function() {
    $error = error_get_last();
    if ($error && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR, E_USER_ERROR])) {
        $time = date('Y-m-d H:i:s');
        $method = $_SERVER['REQUEST_METHOD'] ?? '';
        $url = $_SERVER['REQUEST_URI'] ?? '';
        $msg = $error['message'];
        $file = $error['file'];
        $line = $error['line'];
        $logText = "\n================================================================================\n"
                 . "SYSTEM DEBUG: [$time] FATAL SHUTDOWN ERROR\n"
                 . "Endpoint: $method $url\n"
                 . "File: $file (Line: $line)\n"
                 . "Error: $msg\n"
                 . "================================================================================\n";
        file_put_contents(BASE_PATH . '/system_error.log', $logText, FILE_APPEND);
        file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . " FATAL in $file:$line -> $msg\n", FILE_APPEND);
    }
});

try {
    require BASE_PATH . '/vendor/autoload.php';

    // Load .env
    if (file_exists(BASE_PATH . '/.env')) {
        $dotenv = Dotenv::createImmutable(BASE_PATH);
        $dotenv->load();
    }

    $di = new FactoryDefault();

    // Include Services
    include APP_PATH . '/config/services.php';

    $app = new Micro($di);
    
    // Setup Events Manager for Middleware
    $eventsManager = new EventsManager();
    $app->setEventsManager($eventsManager);

    // Include Router
    include APP_PATH . '/config/router.php';

    // Attach middleware
    $authMiddleware = new \App\Middleware\AuthMiddleware();
    $eventsManager->attach('micro', $authMiddleware);

    // --- CORS Headers Configuration ---
    $app->before(function () use ($app) {
        $origin = $app->request->getHeader('Origin') ?: '*';
        $app->response->setHeader('Access-Control-Allow-Origin', $origin);
        $app->response->setHeader('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
        $app->response->setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Range, Content-Disposition, Content-Type, Authorization');
        return true;
    });

    // (Preflight OPTIONS sudah ditangani di awal file — lihat blok CORS di atas.)
    // ----------------------------------

    // Set JSON Response by default and log any HTTP >= 400 responses to system_error.log
    $app->after(function () use ($app) {
        $statusCode = (int) ($app->response->getStatusCode() ?: 200);
        if ($statusCode >= 400) {
            $returned = $app->getReturnedValue();
            $time = date('Y-m-d H:i:s');
            $method = $_SERVER['REQUEST_METHOD'] ?? '';
            $url = $_SERVER['REQUEST_URI'] ?? '';
            $rawContent = $app->response->getContent();
            $respStr = $rawContent ?: (is_string($returned) ? $returned : print_r($returned, true));
            $logText = "\n--------------------------------------------------\n"
                     . "SYSTEM DEBUG: [$time] HTTP ERROR $statusCode\n"
                     . "Endpoint : $method $url\n"
                     . "Response : " . trim($respStr) . "\n"
                     . "--------------------------------------------------\n";
            file_put_contents(BASE_PATH . '/system_error.log', $logText, FILE_APPEND);
        }

        if (!$app->response->isSent()) {
            $app->response->setContentType('application/json', 'UTF-8');
            
            $returned = $app->getReturnedValue();
            if ($returned !== null) {
                $app->response->setJsonContent($returned);
            }
            
            $app->response->send();
        }
    });

    // Handle any exceptions within Phalcon routing/controllers
    $app->error(function ($exception) use ($app) {
        $time = date('Y-m-d H:i:s');
        $method = $_SERVER['REQUEST_METHOD'] ?? '';
        $url = $_SERVER['REQUEST_URI'] ?? '';
        $type = get_class($exception);
        $msg = $exception->getMessage();
        $file = $exception->getFile();
        $line = $exception->getLine();
        $trace = $exception->getTraceAsString();
        $logText = "\n==================================================\n"
                 . "SYSTEM DEBUG: [$time] EXCEPTION: $type\n"
                 . "Endpoint : $method $url\n"
                 . "File     : $file (Line: $line)\n"
                 . "Error    : $msg\n"
                 . "Trace    :\n$trace\n"
                 . "==================================================\n";
        file_put_contents(BASE_PATH . '/system_error.log', $logText, FILE_APPEND);
        file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . " $type in $file:$line -> $msg\n", FILE_APPEND);
        
        $app->response->setStatusCode(500);
        $app->response->setContentType('application/json', 'UTF-8');
        $app->response->setJsonContent([
            'status' => 'error',
            'message' => 'Terjadi kesalahan sistem internal. Silakan coba beberapa saat lagi.'
        ]);
        $app->response->send();
        return false;
    });

    // Handle the request
    $app->handle($_SERVER['REQUEST_URI'] ?? '/');

} catch (\Throwable $e) {
    http_response_code(500);
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET,PUT,POST,DELETE,OPTIONS');
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Range, Content-Disposition, Content-Type, Authorization');
    header('Content-Type: application/json; charset=UTF-8');
    $err = [
        'status' => 'error',
        'message' => 'Terjadi kesalahan sistem internal. Silakan coba beberapa saat lagi.'
    ];
    $time = date('Y-m-d H:i:s');
    $method = $_SERVER['REQUEST_METHOD'] ?? '';
    $url = $_SERVER['REQUEST_URI'] ?? '';
    $type = get_class($e);
    $msg = $e->getMessage();
    $file = $e->getFile();
    $line = $e->getLine();
    $trace = $e->getTraceAsString();
    $logText = "\n==================================================\n"
             . "SYSTEM DEBUG: [$time] UNHANDLED EXCEPTION: $type\n"
             . "Endpoint : $method $url\n"
             . "File     : $file (Line: $line)\n"
             . "Error    : $msg\n"
             . "Trace    :\n$trace\n"
             . "==================================================\n";
    file_put_contents(BASE_PATH . '/system_error.log', $logText, FILE_APPEND);
    file_put_contents(BASE_PATH . '/api_error.log', date('Y-m-d H:i:s') . " $type in $file:$line -> $msg\n", FILE_APPEND);
    echo json_encode($err);
}
