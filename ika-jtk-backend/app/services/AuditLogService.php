<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\Admin;
use App\Models\Alumni;
use Phalcon\Di\DiInterface;
use Phalcon\Mvc\Model;

class AuditLogService
{
    private DiInterface $di;
    private array $actorCache = [];
    private static array $skipEntities = [];

    public function __construct(DiInterface $di)
    {
        $this->di = $di;
    }

    /**
     * Suppress the very next auto-log from LogsChanges for a specific entity.
     * Useful when a controller wants to record a business-level action (approve/reject/permission_change)
     * without also emitting the generic "update" log the trait would produce.
     */
    public function skipNextChange(string $entityType, ?string $entityId): void
    {
        self::$skipEntities[$entityType . ':' . ($entityId ?? '')] = true;
    }

    public function shouldSkip(string $entityType, ?string $entityId): bool
    {
        $key = $entityType . ':' . ($entityId ?? '');
        if (isset(self::$skipEntities[$key])) {
            unset(self::$skipEntities[$key]);
            return true;
        }
        return false;
    }

    /**
     * Record an audit log entry.
     *
     * $params keys (all optional except `action`):
     *   source       'cms'|'portal'|'system'   default: auto-detect
     *   action       string                    required
     *   entityType   string
     *   entityId     string
     *   description  string                    auto-generated if empty
     *   changes      ['before'=>[...], 'after'=>[...]]
     *   metadata     array
     *   actor        ['id'=>..., 'type'=>..., 'name'=>..., 'role'=>...]  override auto-detect
     */
    public function log(array $params): ?AuditLog
    {
        try {
            if (empty($params['action'])) return null;

            $actor    = $params['actor']    ?? $this->resolveActor();
            $source   = $params['source']   ?? $this->resolveSource();
            $reqMeta  = $this->resolveRequestMeta();

            $log = new AuditLog();
            $log->source      = $source;
            $log->actorType   = $actor['type']   ?? null;
            $log->actorId     = $actor['id']     ?? null;
            $log->actorName   = $actor['name']   ?? null;
            $log->actorRole   = $actor['role']   ?? null;
            $log->action      = $params['action'];
            $log->entityType  = $params['entityType']  ?? null;
            $log->entityId    = $params['entityId']    ?? null;
            $log->description = $params['description'] ?? $this->autoDescribe($actor, $params);
            $log->changes     = isset($params['changes'])  ? $params['changes']  : null;
            $log->metadata    = isset($params['metadata']) ? $params['metadata'] : null;
            $log->ipAddress   = $reqMeta['ip']         ?? null;
            $log->userAgent   = $reqMeta['userAgent']  ?? null;

            if ($log->save() === false) {
                $messages = [];
                foreach ($log->getMessages() as $m) $messages[] = (string) $m;
                error_log('[AuditLogService] gagal simpan log: ' . implode('; ', $messages));
                return null;
            }
            return $log;
        } catch (\Throwable $e) {
            error_log('[AuditLogService] exception: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Compute a diff between the model's original snapshot and current attributes.
     * Returns ['before' => [...], 'after' => [...]] with only changed fields (minus ignored).
     */
    public function diffSnapshot(Model $model, array $ignored = []): array
    {
        $before = [];
        $after  = [];

        if (!method_exists($model, 'getChangedFields')) {
            return ['before' => $before, 'after' => $after];
        }

        try {
            $changed = $model->getChangedFields();
        } catch (\Throwable $e) {
            return ['before' => $before, 'after' => $after];
        }

        $oldSnapshot = method_exists($model, 'getOldSnapshotData') ? ($model->getOldSnapshotData() ?: []) : [];

        foreach ($changed as $field) {
            if (in_array($field, $ignored, true)) continue;
            $before[$field] = $oldSnapshot[$field] ?? null;
            $after[$field]  = $model->readAttribute($field);
        }

        return ['before' => $before, 'after' => $after];
    }

    private function resolveActor(): array
    {
        $userId   = null;
        $userRole = null;
        $tokenSrc = null;

        try { $userId   = $this->di->has('userId')   ? $this->di->getShared('userId')   : null; } catch (\Throwable $e) {}
        try { $userRole = $this->di->has('userRole') ? $this->di->getShared('userRole') : null; } catch (\Throwable $e) {}

        if (!$userId) {
            return ['id' => null, 'type' => 'system', 'name' => 'System', 'role' => null];
        }

        // Guess actor type from source or role. Default to admin if userRole is set.
        $type = 'alumni';
        try {
            $req = $this->di->has('request') ? $this->di->getShared('request') : null;
            if ($req) {
                $path = $req->getURI();
                if (strpos($path, '/api/admin') === 0) $type = 'admin';
            }
        } catch (\Throwable $e) {}

        if ($userRole && $type === 'alumni') {
            $type = 'admin';
        }

        $cacheKey = $type . ':' . $userId;
        if (isset($this->actorCache[$cacheKey])) {
            return $this->actorCache[$cacheKey];
        }

        $name = null;
        if ($type === 'admin') {
            $admin = Admin::findFirst(['conditions' => 'id = ?0', 'bind' => [$userId]]);
            if ($admin) $name = $admin->nama;
        } else {
            $alumni = Alumni::findFirst(['conditions' => 'id = ?0', 'bind' => [$userId]]);
            if ($alumni) $name = $alumni->nama;
        }

        $actor = ['id' => $userId, 'type' => $type, 'name' => $name, 'role' => $userRole];
        $this->actorCache[$cacheKey] = $actor;
        return $actor;
    }

    private function resolveSource(): string
    {
        try {
            if (!$this->di->has('request')) return 'system';
            $req  = $this->di->getShared('request');
            $path = $req->getURI();
            if (strpos($path, '/api/admin') === 0) return 'cms';
            if (strpos($path, '/api/portal') === 0 || strpos($path, '/api/auth') === 0) return 'portal';
        } catch (\Throwable $e) {}
        return 'system';
    }

    private function resolveRequestMeta(): array
    {
        try {
            if (!$this->di->has('request')) return ['ip' => null, 'userAgent' => null];
            $req = $this->di->getShared('request');
            return [
                'ip'        => $req->getClientAddress(true) ?: null,
                'userAgent' => substr((string) $req->getUserAgent(), 0, 500) ?: null,
            ];
        } catch (\Throwable $e) {
            return ['ip' => null, 'userAgent' => null];
        }
    }

    private function autoDescribe(array $actor, array $params): string
    {
        $who    = $actor['name'] ?? ($actor['type'] ?? 'System');
        $action = $params['action'];
        $entity = $params['entityType'] ?? '';

        if ($entity) {
            return trim($who . ' ' . $action . ' ' . $entity);
        }
        return trim($who . ' ' . $action);
    }
}
