<?php

use Phinx\Migration\AbstractMigration;

class AddHighlightedAlumniToBerita extends AbstractMigration
{
    public function up()
    {
        $table = $this->table('Berita');
        if (!$table->hasColumn('highlightedAlumniId')) {
            $table->addColumn('highlightedAlumniId', 'string', ['length' => 255, 'null' => true])
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Berita');
        if ($table->hasColumn('highlightedAlumniId')) {
            $table->removeColumn('highlightedAlumniId')
                  ->update();
        }
    }
}
