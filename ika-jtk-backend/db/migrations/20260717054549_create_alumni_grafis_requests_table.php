<?php
declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class CreateAlumniGrafisRequestsTable extends AbstractMigration
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
        $table = $this->table('AlumniGrafisRequests', ['id' => false, 'primary_key' => 'id']);
        $table->addColumn('id', 'uuid')
              ->addColumn('alumniId', 'uuid')
              ->addColumn('kategori', 'string', ['limit' => 100])
              ->addColumn('grafisId', 'string', ['limit' => 255])
              ->addColumn('status', 'string', ['limit' => 50, 'default' => 'PENDING'])
              ->addColumn('createdAt', 'datetime', ['default' => 'CURRENT_TIMESTAMP'])
              ->addColumn('updatedAt', 'datetime', ['null' => true])
              ->addColumn('deletedAt', 'datetime', ['null' => true])
              ->addIndex(['alumniId'])
              ->addIndex(['status'])
              ->create();
    }
}
