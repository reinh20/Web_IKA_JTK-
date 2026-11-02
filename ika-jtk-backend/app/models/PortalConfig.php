<?php
namespace App\Models;
use Phalcon\Mvc\Model;
use App\Traits\LogsChanges;

class PortalConfig extends Model
{
    use LogsChanges;

    public $key;
    public $value;
    public $createdAt;
    public $updatedAt;
    public $deletedAt;

    protected function auditEntityType(): string
    {
        return 'Portal Settings';
    }

    public function initialize()
    {
        $this->keepSnapshots(true);
        $this->setSource("PortalConfig");
    }

    public function beforeValidation()
    {
        if (!is_string($this->value)) {
            $this->value = json_encode($this->value, JSON_UNESCAPED_UNICODE);
        } elseif (is_string($this->value) && json_decode($this->value) === null && $this->value !== 'null') {
            $this->value = json_encode($this->value, JSON_UNESCAPED_UNICODE);
        }
        $this->updatedAt = date('Y-m-d H:i:s');
        if (empty($this->createdAt)) {
            $this->createdAt = date('Y-m-d H:i:s');
        }
    }

    public function afterFetch()
    {
        if (is_string($this->value)) {
            $this->value = json_decode($this->value, true);
        }
    }
}
