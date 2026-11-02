import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Input, Label } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'
import { toast } from '@/components/ui/Toast'
import api from '@/lib/api'
import { getFriendlyErrorMessage } from '../../utils/errorHandler';
import { useAuthStore } from '@/stores/authStore'

const MODULES: Array<{ id: string; label: string; viewOnly?: boolean }> = [
  { id: 'alumni', label: 'Alumni' },
  { id: 'alumnigrafis', label: 'Alumni Grafis' },
  { id: 'berita', label: 'Berita' },
  { id: 'agenda', label: 'Agenda' },
  { id: 'loker', label: 'Lowongan Kerja' },
  { id: 'testimoni', label: 'Testimoni' },
  { id: 'pemilu', label: 'Pemilu' },
  { id: 'settings', label: 'Portal Settings' },
]

export function RoleFormPage() {
  const user = useAuthStore((s) => s.user)
  const canEdit = user?.permissions?.includes('roles_edit') ?? false

  const { name } = useParams()
  const isEdit = !!name
  const navigate = useNavigate()

  useEffect(() => {
    if (!canEdit) {
      toast('Anda tidak memiliki hak akses untuk mengedit role', 'error')
      navigate('/admin/roles')
      return
    }
  }, [canEdit, navigate])

  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    permissions: [] as string[],
    isSystem: false,
  })

  useEffect(() => {
    if (isEdit) {
      fetchRole()
    }
  }, [isEdit])

  const fetchRole = async () => {
    try {
      setLoading(true)
      const res = await api.get<any[]>('/admin/roles')
      const role = res.data.find(r => r.name === name)
      if (role) {
        let perms = role.permissions || []
        // Loop parse in case of multiple stringifications
        while (typeof perms === 'string') {
          try {
            perms = JSON.parse(perms)
          } catch (e) {
            perms = []
            break
          }
        }
        if (!Array.isArray(perms)) {
          perms = []
        }
        
        // Filter out single character garbages from previous bugs
        perms = perms.filter((p: any) => typeof p === 'string' && (p.endsWith('_view') || p.endsWith('_edit')))
        setFormData({
          name: role.name,
          description: role.description || '',
          permissions: perms,
          isSystem: role.isSystem || false,
        })
      } else {
        toast('Role tidak ditemukan', 'error')
        navigate('/admin/roles')
      }
    } catch (error) {
      toast('Gagal memuat role', 'error')
      navigate('/admin/roles')
    } finally {
      setLoading(false)
    }
  }

  const handlePermissionChange = (moduleId: string, type: 'view' | 'edit', checked: boolean) => {
    setFormData(prev => {
      const permName = `${moduleId}_${type}`
      let newPerms = [...prev.permissions]
      
      if (checked) {
        if (!newPerms.includes(permName)) newPerms.push(permName)
        // If they check edit, automatically check view
        if (type === 'edit') {
          const viewPerm = `${moduleId}_view`
          if (!newPerms.includes(viewPerm)) newPerms.push(viewPerm)
        }
      } else {
        newPerms = newPerms.filter(p => p !== permName)
        // If they uncheck view, automatically uncheck edit
        if (type === 'view') {
          const editPerm = `${moduleId}_edit`
          newPerms = newPerms.filter(p => p !== editPerm)
        }
      }
      
      return { ...prev, permissions: newPerms }
    })
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      if (isEdit) {
        await api.put(`/admin/roles/${encodeURIComponent(name)}`, {
          description: formData.description,
          permissions: formData.permissions
        })
        toast('Role berhasil diperbarui', 'success')
      } else {
        await api.post('/admin/roles', {
          name: formData.name,
          description: formData.description,
          permissions: formData.permissions
        })
        toast('Role berhasil dibuat', 'success')
      }
      navigate('/admin/roles')
    } catch (error: any) {
      toast(getFriendlyErrorMessage(error, 'Gagal menyimpan role'), 'error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="px-10 py-8">
      <div>
        <Breadcrumb
          items={[
            { label: 'Manajemen Role', to: '/admin/roles' },
            { label: isEdit ? 'Edit Role' : 'Tambah Role' },
          ]}
        />
        <h1 className="mt-2 text-3xl font-bold text-gray-900">
          {isEdit ? 'Edit Role Admin' : 'Tambah Role Admin'}
        </h1>
        <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />
      </div>

      <div className="mt-8">
        <SectionCard title={isEdit ? 'Edit Role' : 'Tambah Role Baru'}>
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="space-y-4">
            <div>
              <Label htmlFor="name">Nama Role</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
                disabled={isEdit}
                placeholder="Misal: Humas"
              />
              {isEdit && formData.isSystem && (
                <p className="mt-1 text-sm text-gray-500">
                  Role bawaan sistem tidak dapat diubah namanya.
                </p>
              )}
            </div>

            <div>
              <Label htmlFor="description">Deskripsi</Label>
              <Input
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                disabled={formData.isSystem}
                placeholder="Penjelasan singkat mengenai fungsi role ini"
              />
            </div>
          </div>

          <div className="border-t border-gray-200 pt-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Izin Akses (Permissions)</h3>
            <p className="text-sm text-gray-500 mb-6">
              Pilih modul mana saja yang dapat diakses oleh role ini. Anda dapat memberikan akses hanya-lihat (View) atau akses ubah data (Edit).
            </p>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {MODULES.map(mod => {
                const canView = formData.permissions.includes(`${mod.id}_view`)
                const canEdit = formData.permissions.includes(`${mod.id}_edit`)

                return (
                  <div key={mod.id} className="p-4 border rounded-md bg-white">
                    <h4 className="font-semibold text-gray-800 mb-3">{mod.label}</h4>
                    <div className="space-y-2">
                      <label className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          className="rounded text-primary focus:ring-primary"
                          checked={canView}
                          disabled={formData.isSystem}
                          onChange={(e) => handlePermissionChange(mod.id, 'view', e.target.checked)}
                        />
                        <span className="text-sm text-gray-700">Lihat Data (View)</span>
                      </label>
                      {!mod.viewOnly && (
                        <label className="flex items-center gap-2">
                          <input
                            type="checkbox"
                            className="rounded text-primary focus:ring-primary"
                            checked={canEdit}
                            disabled={formData.isSystem}
                            onChange={(e) => handlePermissionChange(mod.id, 'edit', e.target.checked)}
                          />
                          <span className="text-sm text-gray-700">Ubah Data (Edit/Create/Delete)</span>
                        </label>
                      )}
                    </div>
                  </div>
                )
              })}
            </div>
            
            {formData.isSystem && (
              <div className="mt-4 p-4 bg-yellow-50 text-yellow-800 text-sm rounded-md border border-yellow-200">
                Peringatan: Role ini adalah role bawaan sistem. Izin aksesnya tidak dapat diubah demi keamanan dan kestabilan aplikasi.
              </div>
            )}
          </div>

          <div className="flex justify-end gap-3 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={() => navigate('/admin/roles')}
              disabled={loading}
            >
              Batal
            </Button>
            {!formData.isSystem && (
              <Button type="submit" disabled={loading}>
                {loading ? 'Menyimpan...' : 'Simpan Role'}
              </Button>
            )}
          </div>
        </form>
      </SectionCard>
      </div>
    </div>
  )
}
