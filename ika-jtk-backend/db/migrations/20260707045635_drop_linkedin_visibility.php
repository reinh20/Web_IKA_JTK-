<?php
declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class DropLinkedinVisibility extends AbstractMigration
{
    /**
     * Change Method.
     *
     * Write your reversible migrations using this method.
     *
     * More information on writing migrations is available here:
     * https://book.cakephp.org/phinx/0/en/migrations.html#the-change-method
     *
     * Remember to call "create()" or "update()" and NOT "save()" when working
     * with the Table class.
     */
    public function up()
    {
        $table = $this->table('Alumni');
        if ($table->hasColumn('linkedinVisibility')) {
            $table->removeColumn('linkedinVisibility')
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Alumni');
        if (!$table->hasColumn('linkedinVisibility')) {
            $table->addColumn('linkedinVisibility', 'string', ['limit' => 20, 'default' => 'private', 'null' => false])
                  ->update();
        }
    }
}
