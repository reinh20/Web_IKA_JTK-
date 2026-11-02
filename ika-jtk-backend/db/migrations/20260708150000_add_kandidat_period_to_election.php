<?php

use Phinx\Migration\AbstractMigration;

class AddKandidatPeriodToElection extends AbstractMigration
{
    public function up()
    {
        $table = $this->table('Election');
        if (!$table->hasColumn('kandidatStart')) {
            $table->addColumn('kandidatStart', 'timestamp', ['null' => true])
                  ->update();
        }
        if (!$table->hasColumn('kandidatEnd')) {
            $table->addColumn('kandidatEnd', 'timestamp', ['null' => true])
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Election');
        if ($table->hasColumn('kandidatEnd')) {
            $table->removeColumn('kandidatEnd')->update();
        }
        if ($table->hasColumn('kandidatStart')) {
            $table->removeColumn('kandidatStart')->update();
        }
    }
}
