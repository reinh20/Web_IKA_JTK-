<?php

use Phinx\Migration\AbstractMigration;

class AddAlumniVisibilityFields extends AbstractMigration
{
    /**
     * Migrate Up.
     */
    public function up()
    {
        $table = $this->table('Alumni');
        
        $needsUpdate = false;
        
        if (!$table->hasColumn('emailVisibility')) {
            $table->addColumn('emailVisibility', 'string', ['limit' => 20, 'default' => 'private', 'null' => false]);
            $needsUpdate = true;
        }
        if (!$table->hasColumn('nomorHandphoneVisibility')) {
            $table->addColumn('nomorHandphoneVisibility', 'string', ['limit' => 20, 'default' => 'private', 'null' => false]);
            $needsUpdate = true;
        }
        if (!$table->hasColumn('linkedinVisibility')) {
            $table->addColumn('linkedinVisibility', 'string', ['limit' => 20, 'default' => 'private', 'null' => false]);
            $needsUpdate = true;
        }
        if (!$table->hasColumn('alamatVisibility')) {
            $table->addColumn('alamatVisibility', 'string', ['limit' => 20, 'default' => 'private', 'null' => false]);
            $needsUpdate = true;
        }
        
        if ($needsUpdate) {
            $table->update();
        }
    }

    /**
     * Migrate Down.
     */
    public function down()
    {
        $table = $this->table('Alumni');
        
        if ($table->hasColumn('emailVisibility')) {
            $table->removeColumn('emailVisibility');
        }
        if ($table->hasColumn('nomorHandphoneVisibility')) {
            $table->removeColumn('nomorHandphoneVisibility');
        }
        if ($table->hasColumn('linkedinVisibility')) {
            $table->removeColumn('linkedinVisibility');
        }
        if ($table->hasColumn('alamatVisibility')) {
            $table->removeColumn('alamatVisibility');
        }
        
        $table->update();
    }
}
