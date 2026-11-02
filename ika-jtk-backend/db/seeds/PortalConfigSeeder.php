<?php

declare(strict_types=1);

use Phinx\Seed\AbstractSeed;

/**
 * Seeds the PortalConfig table with the default "Pengaturan Portal" content
 * (the dummy data the CMS used before it was wired to the backend).
 *
 * Storage model: one row per config key; `value` holds a JSON-encoded payload.
 * Matches the shape the portal expects at GET /api/portal/config and the
 * payload the CMS PortalSettings page saves.
 *
 * Idempotent: existing keys are left untouched (so admin edits are not
 * overwritten); only missing keys are inserted.
 */
class PortalConfigSeeder extends AbstractSeed
{
    public function run(): void
    {
        $defaults = [
            'site_name' => 'IKA JTK POLBAN',
            'tagline'   => 'Portal Alumni Teknik Komputer dan Informatika POLBAN',
            'maintenance_mode' => false,
            'allow_public_registration' => true,

            'hero_slides' => [
                [
                    'id' => 's1',
                    'judul' => 'REUNI AKBAR 2024',
                    'badge' => 'BERITA',
                    'newsTitle' => 'Agenda Reuni Akbar 2025 Segera Hadir!',
                    'excerpt' => 'Jangan lewatkan momen reuni akbar tahun ini. Catat tanggalnya dan ajak teman-teman alumni lainnya.',
                    'imageUrl' => 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=1600&q=80',
                ],
                [
                    'id' => 's2',
                    'judul' => 'GATHERING ALUMNI',
                    'badge' => 'EVENT',
                    'newsTitle' => 'Networking Bersama Alumni Senior',
                    'excerpt' => 'Manfaatkan kesempatan langka untuk berdiskusi dengan para senior alumni.',
                    'imageUrl' => 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1600&q=80',
                ],
            ],

            'about' => [
                'title' => 'Apa itu IKA JTK?',
                'content' => 'IKA JTK Polban adalah ikatan para alumni lulusan dari jurusan Teknik Komputer dan Informatika Politeknik Negeri Bandung.',
            ],

            'features' => [
                ['id' => 'f1', 'icon' => 'network',   'title' => 'Jejaring Alumni', 'desc' => 'Bangun koneksi profesional lintas angkatan.'],
                ['id' => 'f2', 'icon' => 'briefcase', 'title' => 'Lowongan Kerja',  'desc' => 'Temukan peluang karier yang dibagikan alumni.'],
                ['id' => 'f3', 'icon' => 'calendar',  'title' => 'Agenda Alumni',   'desc' => 'Ikuti kegiatan alumni dan reuni.'],
                ['id' => 'f4', 'icon' => 'photo',     'title' => 'Galeri & Cerita', 'desc' => 'Momen bersama melalui foto dan testimoni alumni.'],
            ],

            'faqs' => [],

            'organization' => [],

            'contacts' => [
                'instagram' => '@ikajtk.id',
                'email' => 'pengurus@ikajtk.id',
                'whatsapp' => '+62 812 3456 7890',
                'alamat' => 'Politeknik Negeri Bandung, Jl. Gegerkalong Hilir, Bandung',
            ],
        ];

        $now = date('Y-m-d H:i:s');

        foreach ($defaults as $key => $value) {
            $existing = $this->fetchRow(
                "SELECT \"key\" FROM \"PortalConfig\" WHERE \"key\" = " . $this->quote($key)
            );
            if (!empty($existing)) {
                // Preserve any admin-edited value already stored.
                continue;
            }

            $json = json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

            $this->execute(sprintf(
                'INSERT INTO "PortalConfig" ("key", "value", "createdAt", "updatedAt") VALUES (%s, %s, %s, %s)',
                $this->quote($key),
                $this->quote($json),
                $this->quote($now),
                $this->quote($now)
            ));
        }
    }

    private function quote(string $v): string
    {
        return $this->getAdapter()->getConnection()->quote($v);
    }
}
