import { X } from 'lucide-react'
import { Modal } from '@/components/ui/Modal'
import { Badge } from '@/components/ui/Badge'
import { formatDate } from '@/lib/utils'
import type { AuditLogEntry } from '@/types/auditLog'

interface Props {
  entry: AuditLogEntry | null
  onClose: () => void
}

function formatValue(v: unknown): string {
  if (v === null || v === undefined) return '—'
  if (typeof v === 'string') return v
  if (typeof v === 'number' || typeof v === 'boolean') return String(v)
  try {
    return JSON.stringify(v, null, 2)
  } catch {
    return String(v)
  }
}

function DiffTable({ changes }: { changes: AuditLogEntry['changes'] }) {
  if (!changes) return <p className="text-sm text-gray-500">Tidak ada perubahan tercatat.</p>

  const before = changes.before || {}
  const after = changes.after || {}
  const keys = Array.from(new Set([...Object.keys(before), ...Object.keys(after)]))

  if (keys.length === 0) return <p className="text-sm text-gray-500">Tidak ada perubahan tercatat.</p>

  return (
    <div className="overflow-hidden rounded-md border border-gray-200">
      <table className="w-full text-sm">
        <thead>
          <tr className="bg-gray-50 text-gray-700 text-left">
            <th className="px-3 py-2 font-semibold w-1/4">Field</th>
            <th className="px-3 py-2 font-semibold w-[37.5%]">Sebelum</th>
            <th className="px-3 py-2 font-semibold w-[37.5%]">Sesudah</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {keys.map((k) => {
            const b = (before as Record<string, unknown>)[k]
            const a = (after as Record<string, unknown>)[k]
            const bStr = formatValue(b)
            const aStr = formatValue(a)
            const changed = bStr !== aStr
            return (
              <tr key={k} className="align-top">
                <td className="px-3 py-2 font-medium text-gray-800">{k}</td>
                <td className={`px-3 py-2 whitespace-pre-wrap break-all font-mono text-xs ${changed ? 'bg-red-50 text-red-800' : 'text-gray-700'}`}>{bStr}</td>
                <td className={`px-3 py-2 whitespace-pre-wrap break-all font-mono text-xs ${changed ? 'bg-green-50 text-green-800' : 'text-gray-700'}`}>{aStr}</td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}

function actionVariant(action: string): 'green' | 'orange' | 'red' | 'gray' | 'blue' {
  if (action === 'create' || action === 'approve' || action === 'login' || action === 'restore') return 'green'
  if (action === 'delete' || action === 'reject') return 'red'
  if (action === 'update' || action === 'permission_change') return 'orange'
  if (action === 'logout') return 'gray'
  return 'blue'
}

function sourceVariant(source: string): 'green' | 'orange' | 'gray' {
  if (source === 'cms') return 'green'
  if (source === 'portal') return 'orange'
  return 'gray'
}

export function AuditLogDetailModal({ entry, onClose }: Props) {
  return (
    <Modal open={entry !== null} onClose={onClose} size="lg">
      {entry && (
        <div>
          <div className="flex items-start justify-between px-6 py-4 border-b border-gray-200">
            <div>
              <h2 className="text-lg font-bold text-gray-900">Detail Log Aktivitas</h2>
              <p className="mt-1 text-xs text-gray-500">{formatDate(entry.createdAt)} · {new Date(entry.createdAt).toLocaleTimeString('id-ID')}</p>
            </div>
            <button type="button" onClick={onClose} className="text-gray-400 hover:text-gray-600" aria-label="Tutup">
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="px-6 py-5 space-y-5 max-h-[70vh] overflow-y-auto">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <InfoRow label="Aksi">
                <Badge variant={actionVariant(entry.action)}>{entry.action}</Badge>
              </InfoRow>
              <InfoRow label="Source">
                <Badge variant={sourceVariant(entry.source)}>{entry.source.toUpperCase()}</Badge>
              </InfoRow>
              <InfoRow label="User">
                <span className="text-gray-900 font-medium">{entry.actorName || '—'}</span>
                {entry.actorType && (
                  <span className="ml-1 text-xs text-gray-500">({entry.actorType})</span>
                )}
              </InfoRow>
              <InfoRow label="Role">
                <span className="text-gray-800">{entry.actorRole || '—'}</span>
              </InfoRow>
              <InfoRow label="Entity">
                <span className="text-gray-800">{entry.entityType || '—'}</span>
                {entry.entityId && (
                  <span className="ml-1 text-xs text-gray-500 font-mono break-all">#{entry.entityId}</span>
                )}
              </InfoRow>
              <InfoRow label="IP Address">
                <span className="font-mono text-xs text-gray-700">{entry.ipAddress || '—'}</span>
              </InfoRow>
            </div>

            {entry.description && (
              <div>
                <p className="text-xs font-semibold text-gray-500 uppercase mb-1">Deskripsi</p>
                <p className="text-sm text-gray-800">{entry.description}</p>
              </div>
            )}

            {entry.userAgent && (
              <div>
                <p className="text-xs font-semibold text-gray-500 uppercase mb-1">User Agent</p>
                <p className="text-xs font-mono text-gray-600 break-all">{entry.userAgent}</p>
              </div>
            )}

            {entry.metadata && Object.keys(entry.metadata).length > 0 && (
              <div>
                <p className="text-xs font-semibold text-gray-500 uppercase mb-1">Metadata</p>
                <pre className="text-xs font-mono bg-gray-50 border border-gray-200 rounded p-3 overflow-x-auto">{JSON.stringify(entry.metadata, null, 2)}</pre>
              </div>
            )}

            <div>
              <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Perubahan</p>
              <DiffTable changes={entry.changes} />
            </div>
          </div>
        </div>
      )}
    </Modal>
  )
}

function InfoRow({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <p className="text-xs font-semibold text-gray-500 uppercase mb-1">{label}</p>
      <div className="text-sm">{children}</div>
    </div>
  )
}
