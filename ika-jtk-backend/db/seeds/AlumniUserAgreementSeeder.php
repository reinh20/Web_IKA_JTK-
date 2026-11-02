<?php

use Phinx\Seed\AbstractSeed;

class AlumniUserAgreementSeeder extends AbstractSeed
{
    public function run(): void
    {
        $this->execute('UPDATE "Alumni" SET "userAgreement" = true WHERE "userAgreement" = false OR "userAgreement" IS NULL');
    }
}
