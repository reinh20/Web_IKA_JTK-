<?php
declare(strict_types=1);
use Phinx\Migration\AbstractMigration;

final class CreatePortalConfigTable extends AbstractMigration
{
    public function change(): void
    {
        $this->table('PortalConfig', ['id' => false, 'primary_key' => 'key'])
            ->addColumn('key', 'string', ['limit' => 100])
            ->addColumn('value', 'jsonb', ['default' => '{}', 'null' => false])
            ->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'null' => true])
            ->create();
    }
}
