<?php

use Phinx\Seed\AbstractSeed;

class LamaranSeeder extends AbstractSeed
{
    /**
     * Run Method.
     *
     * Write your database seeder using this method.
     *
     * More information on writing seeders is available here:
     * https://book.cakephp.org/phinx/0/en/seeding.html
     */
    public function run(): void
    {
        // Only run seeder if you want dummy data.
        // It's recommended to test the UI flow instead,
        // but here is a placeholder for Lamaran dummy data.
        
        /*
        $data = [
            [
                'id' => 'sample-lamaran-id-123',
                'lokerId' => 'some-loker-id',
                'alumniId' => 'some-alumni-id',
                'jawaban' => '{"alasan": "Saya tertarik"}',
                'status' => 'Sedang Direview',
                'createdAt' => date('Y-m-d H:i:s'),
                'updatedAt' => date('Y-m-d H:i:s'),
            ]
        ];

        $table = $this->table('Lamaran');
        $table->insert($data)->saveData();
        */
    }
}
