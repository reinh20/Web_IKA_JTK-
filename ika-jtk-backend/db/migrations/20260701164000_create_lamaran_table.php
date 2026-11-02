<?php
declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class CreateLamaranTable extends AbstractMigration
{
    public function up()
    {
        // Check if table already exists, since we manually created it via SQL script
        if (!$this->hasTable('Lamaran')) {
            $table = $this->table('Lamaran', ['id' => false, 'primary_key' => 'id']);
            $table->addColumn('id', 'string', ['limit' => 255])
                  ->addColumn('lokerId', 'string', ['limit' => 255])
                  ->addColumn('alumniId', 'string', ['limit' => 255])
                  ->addColumn('jawaban', 'json', ['default' => '{}'])
                  ->addColumn('status', 'string', ['limit' => 50, 'default' => 'Sedang Direview'])
                  ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP'])
                  ->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP'])
                  ->addColumn('deletedAt', 'timestamp', ['null' => true])
                  ->addIndex(['lokerId'])
                  ->addIndex(['alumniId'])
                  ->addForeignKey('lokerId', 'Loker', 'id', ['delete' => 'CASCADE'])
                  ->addForeignKey('alumniId', 'Alumni', 'id', ['delete' => 'CASCADE'])
                  ->create();
        }
    }

    public function down()
    {
        if ($this->hasTable('Lamaran')) {
            $this->table('Lamaran')->drop()->save();
        }
    }
}
