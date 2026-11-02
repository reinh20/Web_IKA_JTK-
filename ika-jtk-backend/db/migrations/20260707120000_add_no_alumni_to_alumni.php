<?php

use Phinx\Migration\AbstractMigration;

class AddNoAlumniToAlumni extends AbstractMigration
{
    public function up()
    {
        $table = $this->table('Alumni');
        if (!$table->hasColumn('noAlumni')) {
            $table->addColumn('noAlumni', 'string', ['length' => 20, 'null' => true])
                  ->addIndex(['noAlumni'], ['unique' => true, 'name' => 'idx_alumni_no_alumni'])
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Alumni');
        if ($table->hasColumn('noAlumni')) {
            $table->removeIndexByName('idx_alumni_no_alumni')
                  ->removeColumn('noAlumni')
                  ->update();
        }
    }
}
