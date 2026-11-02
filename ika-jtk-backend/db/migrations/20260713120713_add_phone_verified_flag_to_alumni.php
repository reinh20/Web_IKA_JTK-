<?php

use Phinx\Migration\AbstractMigration;

class AddPhoneVerifiedFlagToAlumni extends AbstractMigration
{
    public function up()
    {
        $table = $this->table('Alumni');
        
        if (!$table->hasColumn('phoneVerified')) {
            $table->addColumn('phoneVerified', 'boolean', ['default' => false, 'null' => true])
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Alumni');
        
        if ($table->hasColumn('phoneVerified')) {
            $table->removeColumn('phoneVerified')
                  ->update();
        }
    }
}
