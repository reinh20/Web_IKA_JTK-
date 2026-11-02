<?php
declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class UpdateKeanggotaanTerms extends AbstractMigration
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
        $this->execute("UPDATE \"Alumni\" SET keanggotaan = 'Alumni' WHERE keanggotaan IN ('Anggota', 'Alumni Baru')");
        $this->execute("UPDATE \"Alumni\" SET keanggotaan = 'Executive' WHERE keanggotaan = 'Pengurus'");

        $table = $this->table('Alumni');
        if ($table->hasColumn('keanggotaan')) {
            $table->changeColumn('keanggotaan', 'string', ['length' => 50, 'default' => 'Alumni', 'null' => false])
                  ->update();
        }
    }

    public function down()
    {
        $table = $this->table('Alumni');
        if ($table->hasColumn('keanggotaan')) {
            $table->changeColumn('keanggotaan', 'string', ['length' => 50, 'default' => 'Anggota', 'null' => false])
                  ->update();
        }

        $this->execute("UPDATE \"Alumni\" SET keanggotaan = 'Anggota' WHERE keanggotaan = 'Alumni'");
        $this->execute("UPDATE \"Alumni\" SET keanggotaan = 'Pengurus' WHERE keanggotaan = 'Executive'");
    }
}
