import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Input, Label } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'
import { SearchableSelect } from '@/components/ui/SearchableSelect'
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

export function AdminUserFormPage() {
  const { id } = useParams()
  const isEdit = !!id
  const navigate = useNavigate()
  const user = useAuthStore((s) => s.user)
  const canEdit = user?.permissions?.includes('users_edit') ?? false

  const [loading, setLoading] = useState(false)
  const [availableRoles, setAvailableRoles] = useState<any[]>([])
  const [formData, setFormData] = useState({
    nama: '',
    email: '',
    username: '',
    password: '',
    confirmPassword: '',
    role: 'Admin',
  })

  useEffect(() => {
    if (!canEdit) {
      toast('Anda tidak memiliki hak akses untuk mengedit admin', 'error')
      navigate('/admin/users')
      return
    }
  }, [canEdit, navigate])

  useEffect(() => {
    fetchRoles()
    if (isEdit) {
      fetchAdmin()
    }
  }, [isEdit])

  const fetchRoles = async () => {
    try {
      const res = await api.get<any[]>('/admin/roles')
      const roles = Array.isArray(res.data) ? res.data : []
      setAvailableRoles(roles)
      if (!isEdit && roles.length > 0) {
        // Prefer a non-Super Admin role as the default selection.
        const assignable = roles.filter(r => r.name !== 'Super Admin')
        const preferred = assignable.find(r => !r.isSystem) || assignable[0] || roles[0]
        if (preferred) {
          setFormData(prev => ({ ...prev, role: preferred.name }))
        }
      }
    } catch (error) {
      toast('Gagal memuat daftar role', 'error')
    }
  }

  const fetchAdmin = async () => {
    try {
      setLoading(true)
      const res = await api.get<any>(`/admin/users/${id}`)
      const data = res.data
      setFormData({
        nama: data.nama || '',
        email: data.email || '',
        username: data.username || '',
        password: '', // do not fill password
        confirmPassword: '',
        role: data.role || 'Admin Viewer',
      })
    } catch (error) {
      toast('Gagal memuat data admin', 'error')
      navigate('/admin/users')
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault()
    try {
      setLoading(true)
      const payload: any = { ...formData }
      if (/\s/.test(payload.username)) {
        setLoading(false)
        return toast('Username tidak boleh mengandung spasi', 'error')
      }
      if (isEdit && !payload.password) {
        delete payload.password // don't send empty password if edit
      }

      if (payload.password) {
        if (/\s/.test(payload.password) || /\s/.test(payload.confirmPassword)) {
          setLoading(false)
          return toast('Password tidak boleh mengandung spasi', 'error')
        }
        if (payload.password !== payload.confirmPassword) {
          setLoading(false)
          return toast('Konfirmasi password tidak sesuai', 'error')
        }
      }
      delete payload.confirmPassword // remove confirmPassword before sending

      if (isEdit) {
        await api.put(`/admin/users/${id}`, payload)
        toast('Admin berhasil diperbarui', 'success')
      } else {
        await api.post('/admin/users', payload)
        toast('Admin berhasil ditambahkan', 'success')
      }
      navigate('/admin/users')
    } catch (error: any) {
      toast(getFriendlyErrorMessage(error, 'Gagal menyimpan data'), 'error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="px-10 py-8">
      <Breadcrumb
        items={[
          { label: 'Manajemen Admin', to: '/admin/users' },
          { label: isEdit ? 'Edit Admin' : 'Tambah Admin' },
        ]}
      />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">
        {isEdit ? 'Edit Akun Admin' : 'Tambah Akun Admin'}
      </h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-[1fr_300px] gap-6 items-start">
        <div className="min-w-0">
          <SectionCard title="Data Admin">
            <div className="p-6 space-y-4">
              <div>
                <Label required>Nama Lengkap</Label>
                <Input
                  required
                  placeholder="Masukkan Nama Lengkap"
                  value={formData.nama}
                  onChange={(e) => setFormData({ ...formData, nama: e.target.value })}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label required>Email</Label>
                  <Input
                    required
                    type="email"
                    noSpaces
                    placeholder="Masukkan Email"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  />
                </div>
                <div>
                  <Label required>Username</Label>
                  <Input
                    required
                    noSpaces
                    autoComplete="off"
                    placeholder="Masukkan Username"
                    value={formData.username}
                    onKeyDown={(e) => { if (e.key === ' ') e.preventDefault(); }}
                    onChange={(e) => setFormData({ ...formData, username: e.target.value.replace(/\s/g, '') })}
                  />
                </div>
              </div>

              <div>
                <Label required={!isEdit}>
                  Password {isEdit && <span className="text-gray-400 font-normal">(Kosongkan jika tidak ingin diubah)</span>}
                </Label>
                <Input
                  required={!isEdit}
                  type="password"
                  noSpaces
                  autoComplete="new-password"
                  placeholder="Masukkan Password"
                  value={formData.password}
                  onKeyDown={(e) => { if (e.key === ' ') e.preventDefault(); }}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value.replace(/\s/g, '') })}
                />
              </div>

              <div>
                <Label required={!isEdit || formData.password.trim().length > 0}>Konfirmasi Password</Label>
                <Input
                  required={!isEdit || formData.password.trim().length > 0}
                  type="password"
                  noSpaces
                  autoComplete="new-password"
                  placeholder="Masukkan Konfirmasi Password"
                  value={formData.confirmPassword}
                  onKeyDown={(e) => { if (e.key === ' ') e.preventDefault(); }}
                  onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value.replace(/\s/g, '') })}
                />
              </div>

              <div>
                <Label required>Role (Hak Akses)</Label>
                <SearchableSelect
                  options={
                    isEdit && formData.role === 'Super Admin'
                      ? [{ value: 'Super Admin', label: 'Super Admin (Full Access)' }]
                      : availableRoles
                          .filter(r => r.name !== 'Super Admin')
                          .map(r => ({
                            value: r.name,
                            label: `${r.name} ${r.isSystem ? '(Bawaan Sistem)' : '(Kustom)'}`,
                          }))
                  }
                  value={formData.role}
                  onChange={(v) => setFormData({ ...formData, role: v })}
                  disabled={isEdit && formData.role === 'Super Admin'}
                  placeholder="Pilih Role..."
                  searchPlaceholder="Cari role..."
                />
              </div>
            </div>
          </SectionCard>
          
          <SectionCard title="Informasi Role (Hak Akses)" className="mt-6">
            <div className="p-6 overflow-x-auto">
              <table className="w-full text-left border-collapse min-w-[600px]">
                <thead>
                  <tr className="border-b border-gray-200">
                    <th className="py-2 pr-4 font-semibold text-gray-600">Nama Role</th>
                    <th className="py-2 px-4 font-semibold text-gray-600">Tipe</th>
                    <th className="py-2 pl-4 font-semibold text-gray-600">Keterangan / Izin Akses</th>
                  </tr>
                </thead>
                <tbody>
                  {availableRoles.map(r => (
                    <tr key={r.name} className={`border-b border-gray-100 ${formData.role === r.name ? 'bg-blue-50/50' : 'hover:bg-gray-50'}`}>
                      <td className="py-3 pr-4 font-medium text-gray-900">{r.name}</td>
                      <td className="py-3 px-4">
                        {r.isSystem ? (
                          <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded">Sistem</span>
                        ) : (
                          <span className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded">Kustom</span>
                        )}
                      </td>
                      <td className="py-3 pl-4 text-sm text-gray-600">
                        {r.description && r.description.trim().length > 0
                          ? r.description
                          : formatPermissionsToFriendlyText(r.permissions)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </SectionCard>
        </div>

        <aside className="lg:sticky lg:top-8">
          <SectionCard title="Action">
            {canEdit ? (
              <Button 
                onClick={() => handleSubmit()} 
                className="w-full" 
                size="lg" 
                disabled={loading}
              >
                {loading ? 'Menyimpan...' : (isEdit ? 'Simpan Perubahan' : 'Tambah Admin')}
              </Button>
            ) : (
              <div className="text-center text-sm text-gray-500 py-2">
                Anda tidak memiliki akses untuk mengubah data admin.
              </div>
            )}
            <button
              type="button"
              onClick={() => navigate('/admin/users')}
              className="mt-3 w-full text-sm text-gray-500 hover:text-gray-800"
              disabled={loading}
            >
              Batal
            </button>
          </SectionCard>
        </aside>
      </div>
    </div>
  )
}
