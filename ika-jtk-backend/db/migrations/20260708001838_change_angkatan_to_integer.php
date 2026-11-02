<?php
declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class ChangeAngkatanToInteger extends AbstractMigration
{
    /**
     * Change Method.
     *
     * Write your reversible migrations using this method.
     *
     * More information on writing migrations is available here:
     * https://book.cakephp.org/phinx/0/en/migrations.html#the-change-method
     *
     * Remember to call "create()" or "update()" and NOT "save()" when working
     * with the Table class.
     */
    public function up(): void
    {
        // Safe casting: removes all non-digits, if empty returns NULL, then cast to integer.
        // This prevents PDOExceptions when there's an empty string or non-numeric data.
        
        $this->execute('ALTER TABLE "Alumni" ALTER COLUMN "angkatan" TYPE integer USING NULLIF(regexp_replace("angkatan", \'\\D\', \'\', \'g\'), \'\')::integer');
        $this->execute('ALTER TABLE "Alumni" ALTER COLUMN "tahunLulus" TYPE integer USING NULLIF(regexp_replace("tahunLulus", \'\\D\', \'\', \'g\'), \'\')::integer');

        $this->execute('ALTER TABLE "PendingRegistration" ALTER COLUMN "angkatan" TYPE integer USING NULLIF(regexp_replace("angkatan", \'\\D\', \'\', \'g\'), \'\')::integer');
        
        $this->execute('ALTER TABLE "Candidate" ALTER COLUMN "angkatan" TYPE integer USING NULLIF(regexp_replace("angkatan", \'\\D\', \'\', \'g\'), \'\')::integer');
        
        $this->execute('ALTER TABLE "Testimoni" ALTER COLUMN "alumniAngkatan" TYPE integer USING NULLIF(regexp_replace("alumniAngkatan", \'\\D\', \'\', \'g\'), \'\')::integer');
    }

    public function down(): void
    {
        $this->execute('ALTER TABLE "Alumni" ALTER COLUMN "angkatan" TYPE varchar(50)');
        $this->execute('ALTER TABLE "Alumni" ALTER COLUMN "tahunLulus" TYPE varchar(50)');

        $this->execute('ALTER TABLE "PendingRegistration" ALTER COLUMN "angkatan" TYPE varchar(50)');
        
        $this->execute('ALTER TABLE "Candidate" ALTER COLUMN "angkatan" TYPE varchar(50)');
        
        $this->execute('ALTER TABLE "Testimoni" ALTER COLUMN "alumniAngkatan" TYPE varchar(50)');
    }
}
