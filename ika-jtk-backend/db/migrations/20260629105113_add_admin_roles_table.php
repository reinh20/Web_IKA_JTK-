<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddAdminRolesTable extends AbstractMigration
{
    public function change(): void
    {
        // 1. Create admin_roles table
        $table = $this->table('AdminRole', ['id' => 'id']);
        $table->addColumn('name', 'string', ['limit' => 50])
              ->addColumn('description', 'string', ['limit' => 255, 'null' => true])
              ->addColumn('permissions', 'text', ['null' => true])
              ->addColumn('isSystem', 'boolean', ['default' => false])
              ->addColumn('createdAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP'])
              ->addColumn('updatedAt', 'timestamp', ['default' => 'CURRENT_TIMESTAMP', 'update' => 'CURRENT_TIMESTAMP'])
              ->addIndex(['name'], ['unique' => true])
              ->create();
    }
}
