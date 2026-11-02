<?php

use Phinx\Migration\AbstractMigration;

class AddHideStatistikToElection extends AbstractMigration
{
    public function up()
    {
        $table = $this->table('Election');
        if (!$table->hasColumn('hideStatistik')) {
            $table->addColumn('hideStatistik', 'integer', ['default' => 0, 'null' => false])
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Election');
        if ($table->hasColumn('hideStatistik')) {
            $table->removeColumn('hideStatistik')->update();
        }
    }
}
