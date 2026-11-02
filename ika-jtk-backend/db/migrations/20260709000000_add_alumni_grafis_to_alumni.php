<?php

use Phinx\Migration\AbstractMigration;

class AddAlumniGrafisToAlumni extends AbstractMigration
{
    public function up()
    {
        $table = $this->table('Alumni');
        if (!$table->hasColumn('alumniGrafis')) {
            // Kita gunakan tipe text atau json, karena Postgres mendukung jsonb/json, 
            // phinx memiliki dukungan JSON.
            // Namun, untuk kompatibilitas, kita bisa gunakan json.
            $table->addColumn('alumniGrafis', 'json', ['null' => true])
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Alumni');
        if ($table->hasColumn('alumniGrafis')) {
            $table->removeColumn('alumniGrafis')->update();
        }
    }
}
