<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class CreateAuditLogTable extends AbstractMigration
{
    public function change(): void
    {
        $table = $this->table('AuditLog', ['id' => false, 'primary_key' => 'id']);
        $table->addColumn('id',          'uuid')
              ->addColumn('source',      'string', ['limit' => 20])
              ->addColumn('actorType',   'string', ['limit' => 20, 'null' => true])
              ->addColumn('actorId',     'uuid',   ['null' => true])
              ->addColumn('actorName',   'string', ['limit' => 150, 'null' => true])
              ->addColumn('actorRole',   'string', ['limit' => 50,  'null' => true])
              ->addColumn('action',      'string', ['limit' => 50])
              ->addColumn('entityType',  'string', ['limit' => 50,  'null' => true])
              ->addColumn('entityId',    'string', ['limit' => 64,  'null' => true])
              ->addColumn('description', 'string', ['limit' => 500, 'null' => true])
              ->addColumn('changes',     'jsonb',  ['null' => true])
              ->addColumn('metadata',    'jsonb',  ['null' => true])
              ->addColumn('ipAddress',   'string', ['limit' => 45,  'null' => true])
              ->addColumn('userAgent',   'string', ['limit' => 500, 'null' => true])
              ->addColumn('createdAt',   'timestamp', ['default' => 'CURRENT_TIMESTAMP'])
              ->addIndex(['createdAt'])
              ->addIndex(['actorId'])
              ->addIndex(['action'])
              ->addIndex(['source'])
              ->addIndex(['entityType', 'entityId'])
              ->create();
    }
}
