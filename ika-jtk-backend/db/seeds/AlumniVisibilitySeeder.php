<?php

use Phinx\Seed\AbstractSeed;

class AlumniVisibilitySeeder extends AbstractSeed
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
        // Execute raw SQL to ensure all current alumni have 'private' visibility if they are null
        $this->execute('UPDATE "Alumni" SET "emailVisibility" = \'private\' WHERE "emailVisibility" IS NULL');
        $this->execute('UPDATE "Alumni" SET "nomorHandphoneVisibility" = \'private\' WHERE "nomorHandphoneVisibility" IS NULL');
        $this->execute('UPDATE "Alumni" SET "alamatVisibility" = \'private\' WHERE "alamatVisibility" IS NULL');
    }
}
