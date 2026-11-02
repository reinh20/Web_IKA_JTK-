<?php
declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class CreatePesertaAgendaTable extends AbstractMigration
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
        if (!$this->hasTable('peserta_agenda')) {
            $table = $this->table('peserta_agenda', ['id' => false, 'primary_key' => 'id']);
            $table->addColumn('id', 'string', ['limit' => 36])
                  ->addColumn('agendaId', 'string', ['limit' => 36])
                  ->addColumn('alumniId', 'string', ['limit' => 36])
                  ->addColumn('nama', 'string', ['limit' => 255])
                  ->addColumn('email', 'string', ['limit' => 255])
                  ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP'])
                  ->create();
        }
    }

    public function down()
    {
        if ($this->hasTable('peserta_agenda')) {
            $this->table('peserta_agenda')->drop()->save();
        }
    }
}
