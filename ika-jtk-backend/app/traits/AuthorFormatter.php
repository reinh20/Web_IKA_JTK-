<?php

namespace App\Traits;

use App\Models\Admin;
use App\Models\Alumni;

trait AuthorFormatter
{
    /**
     * Helper to globally format author details.
     * Always fetches the latest avatarUrl and name from Admin or Alumni tables.
     */
    protected function formatAuthor(array $data): array
    {
        $authorId = $data['authorId'] ?? null;
        $authorRole = $data['authorRole'] ?? '';
        $authorNama = $data['authorNama'] ?? '';
        $authorAvatar = $data['authorAvatarUrl'] ?? '';

        if (!empty($authorId)) {
            // First check if it's an Alumni (if the role says Alumni or if we just check Alumni table)
            if (stripos($authorRole, 'alumni') !== false) {
                $alumniUser = Alumni::findFirst(['conditions' => 'id = ?0', 'bind' => [$authorId]]);
                if ($alumniUser) {
                    $authorNama = $alumniUser->nama;
                    $authorAvatar = $alumniUser->avatarUrl ?? $authorAvatar;
                }
            } else {
                $adminUser = Admin::findFirst(['conditions' => 'id = ?0', 'bind' => [$authorId]]);
                if ($adminUser) {
                    $authorNama = $adminUser->nama ?: ($adminUser->username ?: $authorNama);
                    $authorAvatar = $adminUser->avatarUrl ?? $authorAvatar;
                    $authorRole = $adminUser->role ?: $authorRole;
                } else {
                    // Fallback to alumni if not found in Admin (just in case)
                    $alumniUser = Alumni::findFirst(['conditions' => 'id = ?0', 'bind' => [$authorId]]);
                    if ($alumniUser) {
                        $authorNama = $alumniUser->nama;
                        $authorAvatar = $alumniUser->avatarUrl ?? $authorAvatar;
                        $authorRole = 'Alumni';
                    }
                }
            }
        } else {
            // Default fallback if authorId is totally empty
            $adminUser = Admin::findFirst(['conditions' => 'deletedAt IS NULL AND role = ?0', 'bind' => ['Super Admin']]);
            if (!$adminUser) {
                $adminUser = Admin::findFirst(['conditions' => 'deletedAt IS NULL']);
            }
            if ($adminUser) {
                $authorNama = $adminUser->nama ?: ($adminUser->username ?: 'Admin JTK');
                $authorRole = $adminUser->role ?: 'Super Admin';
                $authorAvatar = $adminUser->avatarUrl ?? $authorAvatar;
            } else {
                $authorNama = 'Admin JTK';
                $authorRole = 'Super Admin';
            }
        }

        return [
            'id' => $authorId ?? '',
            'nama' => $authorNama,
            'role' => $authorRole,
            'avatarUrl' => $authorAvatar ?? '',
        ];
    }
}
