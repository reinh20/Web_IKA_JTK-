<?php

use Phinx\Migration\AbstractMigration;

class AddRejectReasonToTestimoni extends AbstractMigration
{
    public function up()
    {
        $table = $this->table('Testimoni');
        
        if (!$table->hasColumn('rejectReason')) {
            $table->addColumn('rejectReason', 'text', ['null' => true])
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Testimoni');
        
        if ($table->hasColumn('rejectReason')) {
            $table->removeColumn('rejectReason')
                  ->update();
        }
    }
}
