<?php

use Phinx\Migration\AbstractMigration;

class AddCandidateExtraFields extends AbstractMigration
{
    public function up()
    {
        $table = $this->table('Candidate');
        if (!$table->hasColumn('programKerja')) {
            $table->addColumn('programKerja', 'text', ['null' => true, 'default' => '[]'])
                  ->update();
        }
        if (!$table->hasColumn('prestasi')) {
            $table->addColumn('prestasi', 'text', ['null' => true, 'default' => '[]'])
                  ->update();
        }
        if (!$table->hasColumn('tagline')) {
            $table->addColumn('tagline', 'string', ['limit' => 255, 'null' => true])
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Candidate');
        if ($table->hasColumn('tagline')) {
            $table->removeColumn('tagline')->update();
        }
        if ($table->hasColumn('prestasi')) {
            $table->removeColumn('prestasi')->update();
        }
        if ($table->hasColumn('programKerja')) {
            $table->removeColumn('programKerja')->update();
        }
    }
}
