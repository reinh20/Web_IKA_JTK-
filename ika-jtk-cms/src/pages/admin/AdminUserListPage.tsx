import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus, Edit2, Trash2, Search, Settings } from 'lucide-react'
import { getAvatarUrl } from '@/lib/utils'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Badge } from '@/components/ui/Badge'
import { Pagination } from '@/components/ui/Pagination'
import { ConfirmDialog } from '@/components/ui/ConfirmDialog'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { useAuthStore } from '@/stores/authStore'
import { getFriendlyErrorMessage } from '../../utils/errorHandler'

const PAGE_SIZE = 12

interface AdminUser {
  id: string
  nama: string
  email: string
  username: string
  role: string
  avatarUrl?: string
  createdAt: string
}

export function AdminUserListPage() {
  const navigate = useNavigate()
  const user = useAuthStore((s) => s.user)
  const canEdit = user?.permissions?.includes('users_edit') ?? false
  const canEditRoles = user?.permissions?.includes('roles_edit') ?? false

  const [users, setUsers] = useState<AdminUser[]>([])
  const [roles, setRoles] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [deleteTarget, setDeleteTarget] = useState<AdminUser | null>(null)

  const [searchInput, setSearchInput] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)

  const fetchData = async () => {
    try {
      setLoading(true)
      const resUsers = await api.get<any>('/admin/users', {
        params: {
          page,
          limit: PAGE_SIZE,
          search: appliedSearch
        }
      })
      if (resUsers.data && Array.isArray(resUsers.data.data)) {
        setUsers(resUsers.data.data)
        setTotal(resUsers.data.total)
      } else {
        setUsers(resUsers.data)
        setTotal(resUsers.data.length)
      }

      try {
        const resRoles = await api.get<any[]>('/admin/roles')
        console.log('Fetched roles successfully:', resRoles.data)
        setRoles(resRoles.data)
      } catch (roleErr) {
        console.error('Failed to fetch roles for mapping:', roleErr)
      }
    } catch (error: any) {
      if (error?.response?.status === 403) {
        toast('Akses ditolak', 'error')
        navigate('/admin/dashboard')
      } else {
        toast('Gagal memuat data admin', 'error')
      }
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [page, appliedSearch])

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE))
  const currentPage = Math.min(page, totalPages)
  const pageRows = users

  const handleDelete = async () => {
    if (!deleteTarget) return
    try {
      await api.delete(`/admin/users/${deleteTarget.id}`)
      toast('Admin berhasil dihapus', 'success')
      setDeleteTarget(null)
      fetchData()
    } catch (error: any) {
      toast(getFriendlyErrorMessage(error, 'Gagal menghapus admin'), 'error')
    }
  }

  const getRolePermissions = (roleName: string) => {
    const role = roles.find(r => r.name === roleName)
    if (!role || !role.permissions) return []
    
    let perms: string[] = []
    if (typeof role.permissions === 'string') {
      try {
        const parsed = JSON.parse(role.permissions)
        perms = Array.isArray(parsed) ? parsed : []
      } catch (e) {
        perms = []
      }
    } else if (Array.isArray(role.permissions)) {
      perms = role.permissions
    }
    
    // Filter out corrupted data from previous JSON.parse bug
    return perms.filter(p => typeof p === 'string' && (p.endsWith('_view') || p.endsWith('_edit')))
  }

  return (
    <div className="px-10 py-8">
      <Breadcrumb items={[{ label: 'Manajemen Admin' }]} />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">Manajemen Admin & Role</h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 flex flex-wrap items-end gap-4">
        <div className="flex-1 min-w-[280px] max-w-md">
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Nama/Username</label>
          <Input
            placeholder="Cari Nama, Username, atau Email"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                setAppliedSearch(searchInput)
                setPage(1)
              }
            }}
          />
        </div>
        <Button
          variant="outline"
          onClick={() => {
            setAppliedSearch(searchInput)
            setPage(1)
          }}
          rightIcon={<Search className="h-4 w-4" />}
        >
          Cari
        </Button>
        <div className="ml-auto flex gap-3">
          {canEditRoles && (
            <Button
              variant="outline"
              onClick={() => navigate('/admin/roles')}
              className="flex items-center gap-2"
            >
              <Settings className="h-4 w-4" />
              Kelola Tipe Role
            </Button>
          )}
          {canEdit && (
            <Button
              onClick={() => navigate('/admin/users/new')}
              rightIcon={<Plus className="h-4 w-4" />}
            >
              Tambah Admin
            </Button>
          )}
        </div>
      </div>

      {loading ? (
        <div className="py-16 text-center text-gray-500 mt-6">Memuat data...</div>
      ) : pageRows.length === 0 ? (
        <div className="py-16 text-center text-gray-500 mt-6">Belum ada data admin untuk filter ini.</div>
      ) : (
        <div className="mt-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {pageRows.map((user) => {
            const perms = getRolePermissions(user.role)
            return (
              <div key={user.id} className="bg-white rounded-xl border border-gray-200 overflow-hidden shadow-sm hover:shadow-md transition-shadow flex flex-col">
                <div className="p-5 flex-1">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-4">
                      <img
                        src={getAvatarUrl(user.avatarUrl, user.nama)}
                        alt=""
                        className="w-14 h-14 rounded-full object-cover bg-gray-100 ring-4 ring-gray-50"
                      />
                      <div>
                        <h3 className="font-bold text-gray-900 text-lg leading-tight">{user.nama}</h3>
                        <p className="text-sm text-gray-500 mt-0.5">{user.username}</p>
                      </div>
                    </div>
                  </div>
                  
                  <div className="mt-5 space-y-2">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-gray-500">Email:</span>
                      <span className="font-medium text-gray-800">{user.email}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-gray-500">Role:</span>
                      <Badge 
                        variant={
                          user.role === 'Super Admin' ? 'navy' :
                          user.role === 'Admin Verifikator' ? 'blue' : 'gray'
                        }
                      >
                        {user.role}
                      </Badge>
                    </div>
                  </div>

                  <div className="mt-5 pt-4 border-t border-gray-100">
                    <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Akses Modul:</p>
                    {perms.length === 0 ? (
                      <span className="text-sm text-gray-400 italic">Tidak ada akses spesifik</span>
                    ) : (
                      <div className="flex flex-wrap gap-1.5">
                        {perms.slice(0, 6).map((perm: string, idx: number) => (
                          <span key={idx} className="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-medium bg-gray-100 text-gray-700">
                            {perm.replace('_', ' ')}
                          </span>
                        ))}
                        {perms.length > 6 && (
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-medium bg-gray-50 text-gray-500">
                            +{perms.length - 6} lainnya
                          </span>
                        )}
                      </div>
                    )}
                  </div>
                </div>

                {canEdit && (
                  <div className="bg-gray-50 px-5 py-3 border-t border-gray-200 flex justify-end gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      className="h-8 text-xs"
                      onClick={() => navigate(`/admin/users/${user.id}/edit`)}
                    >
                      <Edit2 className="h-3.5 w-3.5 mr-1" /> Edit
                    </Button>
                    {user.role !== 'Super Admin' && (
                      <Button
                        variant="outline"
                        size="sm"
                        className="h-8 text-xs text-red-600 hover:text-red-700 hover:bg-red-50 border-gray-200 hover:border-red-200"
                        onClick={() => setDeleteTarget(user)}
                      >
                        <Trash2 className="h-3.5 w-3.5 mr-1" /> Hapus
                      </Button>
                    )}
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}

      <div className="mt-8 flex flex-col sm:flex-row items-center justify-between gap-3">
        <p className="text-sm text-gray-600">
          {total === 0
            ? 'Tidak ada data'
            : `Menampilkan ${(currentPage - 1) * PAGE_SIZE + 1}–${Math.min(currentPage * PAGE_SIZE, total)} dari ${total} data`}
        </p>
        <Pagination page={currentPage} totalPages={totalPages} onChange={setPage} />
      </div>

      <ConfirmDialog
        open={!!deleteTarget}
        icon={
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-danger-bg text-danger">
            <Trash2 className="h-6 w-6" />
          </div>
        }
        title="Hapus Admin"
        description={`Apakah Anda yakin ingin menghapus admin "${deleteTarget?.nama}"? Aksi ini tidak dapat dibatalkan.`}
        confirmLabel="Hapus"
        cancelLabel="Batal"
        variant="danger"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  )
}
