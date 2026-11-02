<?php

use Phinx\Migration\AbstractMigration;

class AddKeanggotaanToAlumni extends AbstractMigration
{
    public function up()
    {
        $table = $this->table('Alumni');
        if (!$table->hasColumn('keanggotaan')) {
            $table->addColumn('keanggotaan', 'string', ['length' => 50, 'default' => 'Anggota', 'null' => false])
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Alumni');
        if ($table->hasColumn('keanggotaan')) {
            $table->removeColumn('keanggotaan')
                  ->update();
        }
    }
}
