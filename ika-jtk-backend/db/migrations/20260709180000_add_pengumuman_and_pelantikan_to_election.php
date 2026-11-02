<?php

use Phinx\Migration\AbstractMigration;

class AddPengumumanAndPelantikanToElection extends AbstractMigration
{
    public function up()
    {
        $table = $this->table('Election');
        if (!$table->hasColumn('pengumumanDate')) {
            $table->addColumn('pengumumanDate', 'timestamp', ['null' => true])
                  ->update();
        }
        if (!$table->hasColumn('pelantikanDate')) {
            $table->addColumn('pelantikanDate', 'timestamp', ['null' => true])
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Election');
        if ($table->hasColumn('pelantikanDate')) {
            $table->removeColumn('pelantikanDate')->update();
        }
        if ($table->hasColumn('pengumumanDate')) {
            $table->removeColumn('pengumumanDate')->update();
        }
    }
}
