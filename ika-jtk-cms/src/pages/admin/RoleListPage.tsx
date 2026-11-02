import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Pagination } from '@/components/ui/Pagination'
import { ArrowLeft, Plus, Edit, Trash2, Search } from 'lucide-react'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { useAuthStore } from '@/stores/authStore'
import { getFriendlyErrorMessage } from '../../utils/errorHandler'

const MODULE_NAMES: Record<string, string> = {
  alumni: 'alumni',
  alumnigrafis: 'alumni grafis',
  berita: 'berita',
  agenda: 'agenda',
  loker: 'loker',
  testimoni: 'testimoni',
  pemilu: 'pemilu',
  settings: 'pengaturan portal',
  users: 'manajemen admin',
  roles: 'manajemen role',
}

function formatPermissionsToFriendlyText(perms: any): string {
  if (!perms) return '-'
  let list: string[] = []
  if (Array.isArray(perms)) {
    list = perms
  } else if (typeof perms === 'string') {
    try { list = JSON.parse(perms) } catch (_) {}
  }
  if (!list || list.length === 0) return '-'

  const hasEdit = list.some(p => p.endsWith('_edit'))
  const modules = Array.from(new Set(list.map(p => p.replace(/_(view|edit)$/, ''))))
  const moduleLabels = modules.map(m => MODULE_NAMES[m] || m)

  if (moduleLabels.length === 0) return '-'

  const formattedModules = moduleLabels.join(', ')
  if (hasEdit) {
    return `Dapat mengelola data ${formattedModules}.`
  } else {
    return `Dapat melihat data ${formattedModules} saja.`
  }
}

export function RoleListPage() {
  const user = useAuthStore((s) => s.user)
  const canEdit = user?.permissions?.includes('roles_edit') ?? false

  const [roles, setRoles] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [searchInput, setSearchInput] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const PAGE_SIZE = 12

  useEffect(() => {
    fetchRoles()
  }, [page, appliedSearch])

  const fetchRoles = async () => {
    try {
      setLoading(true)
      const res = await api.get<any>('/admin/roles', {
        params: {
          page,
          limit: PAGE_SIZE,
          search: appliedSearch
        }
      })
      if (res.data && Array.isArray(res.data.data)) {
        setRoles(res.data.data)
        setTotal(res.data.total)
      } else {
        setRoles(res.data)
        setTotal(res.data.length)
      }
    } catch (error) {
      toast('Gagal memuat daftar role', 'error')
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (name: string) => {
    if (!confirm(`Hapus role ${name}?`)) return
    try {
      await api.delete(`/admin/roles/${name}`)
      toast('Role berhasil dihapus', 'success')
      fetchRoles()
    } catch (error: any) {
      toast(getFriendlyErrorMessage(error, 'Gagal menghapus role'), 'error')
    }
  }

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE))
  const currentPage = Math.min(page, totalPages)
  const filteredRoles = roles

  return (
    <div className="px-10 py-8">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-4">
            <Link to="/admin/users">
              <Button variant="outline" size="sm" className="h-9 w-9 p-0">
                <ArrowLeft className="h-4 w-4" />
              </Button>
            </Link>
            <Breadcrumb items={[{ label: 'Manajemen Role' }]} />
          </div>
          <h1 className="mt-2 text-3xl font-bold text-gray-900">
            Manajemen Role
          </h1>
          <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />
        </div>
        {canEdit && (
          <Link to="/admin/roles/new">
            <Button className="flex items-center gap-2">
              <Plus className="h-4 w-4" />
              Tambah Role
            </Button>
          </Link>
        )}
      </div>

      <div className="mt-8 flex flex-wrap gap-4 items-center">
        <div className="w-full md:w-80 relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <Input
            placeholder="Cari Role..."
            className="pl-9"
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
      </div>

      <div className="mt-8">
        <SectionCard title="Daftar Role">
        {loading ? (
          <div className="p-8 text-center text-gray-500">Memuat...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="py-3 px-4 font-semibold text-gray-600">Nama Role</th>
                  <th className="py-3 px-4 font-semibold text-gray-600">Deskripsi</th>
                  <th className="py-3 px-4 font-semibold text-gray-600">Tipe</th>
                  <th className="py-3 px-4 font-semibold text-gray-600 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody>
                {filteredRoles.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="py-8 text-center text-gray-500">
                      Belum ada role
                    </td>
                  </tr>
                ) : (
                  filteredRoles.map((role) => (
                    <tr key={role.name} className="border-b border-gray-100 hover:bg-gray-50">
                      <td className="py-3 px-4 font-medium text-gray-900">{role.name}</td>
                      <td className="py-3 px-4 text-gray-600">
                        {role.description && role.description.trim().length > 0
                          ? role.description
                          : formatPermissionsToFriendlyText(role.permissions)}
                      </td>
                      <td className="py-3 px-4">
                        {role.isSystem ? (
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                            Sistem
                          </span>
                        ) : (
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
                            Kustom
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          {canEdit && (
                            <>
                              <Link to={`/admin/roles/${role.name}/edit`}>
                                <Button variant="outline" size="sm">
                                  <Edit className="h-4 w-4" />
                                </Button>
                              </Link>
                              {!role.isSystem && (
                                <Button
                                  variant="outline"
                                  size="sm"
                                  className="text-red-600 hover:text-red-700 hover:bg-red-50 border-gray-200 hover:border-red-200"
                                  onClick={() => handleDelete(role.name)}
                                >
                                  <Trash2 className="h-4 w-4" />
                                </Button>
                              )}
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </SectionCard>
      
      {totalPages > 1 && (
        <div className="mt-6 flex justify-center">
          <Pagination
            page={currentPage}
            totalPages={totalPages}
            onChange={setPage}
          />
        </div>
      )}
      </div>
    </div>
  )
}
