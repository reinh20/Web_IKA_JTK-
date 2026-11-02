export type AuditSource = 'cms' | 'portal' | 'system'
export type AuditActorType = 'admin' | 'alumni' | 'system'

export type AuditAction =
  | 'login'
  | 'logout'
  | 'create'
  | 'update'
  | 'delete'
  | 'restore'
  | 'approve'
  | 'reject'
  | 'permission_change'
  | string

export type AuditEntityType =
  | 'Alumni'
  | 'Berita'
  | 'Agenda'
  | 'Loker'
  | 'Admin'
  | 'AdminRole'
  | string

export interface AuditChanges {
  before?: Record<string, unknown> | null
  after?: Record<string, unknown> | null
}

export interface AuditLogEntry {
  id: string
  source: AuditSource
  actorType: AuditActorType | null
  actorId: string | null
  actorName: string | null
  actorRole: string | null
  action: AuditAction
  entityType: AuditEntityType | null
  entityId: string | null
  description: string | null
  changes: AuditChanges | null
  metadata: Record<string, unknown> | null
  ipAddress: string | null
  userAgent: string | null
  createdAt: string
}

export interface AuditLogListResponse {
  data: AuditLogEntry[]
  meta: {
    page: number
    perPage: number
    total: number
    totalPages: number
  }
}

export const AUDIT_ACTIONS: { value: AuditAction; label: string }[] = [
  { value: 'login', label: 'Login' },
  { value: 'logout', label: 'Logout' },
  { value: 'create', label: 'Create' },
  { value: 'update', label: 'Update' },
  { value: 'delete', label: 'Delete' },
  { value: 'restore', label: 'Restore' },
  { value: 'approve', label: 'Approve' },
  { value: 'reject', label: 'Reject' },
  { value: 'permission_change', label: 'Permission Change' },
]

export const AUDIT_ENTITY_TYPES: { value: AuditEntityType; label: string }[] = [
  { value: 'Alumni', label: 'Alumni' },
  { value: 'Berita', label: 'Berita' },
  { value: 'Agenda', label: 'Agenda' },
  { value: 'Loker', label: 'Loker' },
  { value: 'Admin', label: 'Admin' },
  { value: 'AdminRole', label: 'Role' },
]

export const AUDIT_SOURCES: { value: AuditSource; label: string }[] = [
  { value: 'cms', label: 'CMS' },
  { value: 'portal', label: 'Portal' },
  { value: 'system', label: 'System' },
]
