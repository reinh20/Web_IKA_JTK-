<?php
declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class RemoveOtpFromAlumni extends AbstractMigration
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
    public function up(): void
    {
        $table = $this->table('Alumni');
        
        if ($table->hasColumn('verificationCode')) {
            $table->removeColumn('verificationCode');
        }
        if ($table->hasColumn('verificationCodeExpires')) {
            $table->removeColumn('verificationCodeExpires');
        }
        
        $table->update();
    }

    public function down(): void
    {
        $table = $this->table('Alumni');
        
        if (!$table->hasColumn('verificationCode')) {
            $table->addColumn('verificationCode', 'string', ['limit' => 255, 'null' => true]);
        }
        if (!$table->hasColumn('verificationCodeExpires')) {
            $table->addColumn('verificationCodeExpires', 'datetime', ['null' => true]);
        }
        
        $table->update();
    }
}
