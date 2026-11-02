<?php

namespace App\Controllers;

use Phalcon\Mvc\Controller;

class FileController extends Controller
{
    public function serve($folder, $file)
    {
        $folder = preg_replace('/[^a-zA-Z0-9_-]/', '', $folder);
        $file = preg_replace('/[^a-zA-Z0-9_.-]/', '', $file);
        
        $filePath = BASE_PATH . '/public/uploads/' . $folder . '/' . $file;
        
        if (!file_exists($filePath)) {
            $this->response->setStatusCode(404);
            return ['error' => 'File not found'];
        }
        
        $ext = pathinfo($filePath, PATHINFO_EXTENSION);
        $mimeTypes = [
            'jpg' => 'image/jpeg',
            'jpeg'=> 'image/jpeg',
            'png' => 'image/png',
            'webp'=> 'image/webp',
            'pdf' => 'application/pdf',
        ];
        
        $contentType = $mimeTypes[strtolower($ext)] ?? 'application/octet-stream';
        
        $this->response->setContentType($contentType);
        $this->response->setContent(file_get_contents($filePath));
        $this->response->send();
        
        // Prevent JSON encoding by returning false
        return false;
    }
}
