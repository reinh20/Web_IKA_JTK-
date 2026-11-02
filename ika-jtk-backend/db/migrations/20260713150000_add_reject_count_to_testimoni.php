<?php

use Phinx\Migration\AbstractMigration;

class AddRejectCountToTestimoni extends AbstractMigration
{
    public function change()
    {
        $table = $this->table('Testimoni', ['id' => false, 'primary_key' => ['id']]);
        $table->addColumn('rejectCount', 'integer', ['default' => 0, 'null' => false])
              ->update();
    }
}
