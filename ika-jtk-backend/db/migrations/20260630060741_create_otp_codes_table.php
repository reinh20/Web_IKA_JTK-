<?php
declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class CreateOtpCodesTable extends AbstractMigration
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
    public function change()
    {
        $table = $this->table('OtpCodes', ['id' => false, 'primary_key' => 'id']);
        
        $table->addColumn('id', 'uuid', ['null' => false])
              ->addColumn('email', 'string', ['limit' => 255, 'null' => false])
              ->addColumn('code', 'string', ['limit' => 10, 'null' => false])
              ->addColumn('purpose', 'string', ['limit' => 50, 'null' => false])
              ->addColumn('isUsed', 'boolean', ['default' => false, 'null' => false])
              ->addColumn('expiresAt', 'datetime', ['null' => false])
              ->addColumn('createdAt', 'datetime', ['null' => false])
              ->addIndex(['email'])
              ->addIndex(['code'])
              ->create();
    }
}
