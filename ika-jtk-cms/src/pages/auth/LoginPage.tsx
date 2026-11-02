import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Input, Label } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'
import { useAuthStore } from '@/stores/authStore'
import api from '@/lib/api'
import { getFileUrl } from '@/lib/utils'
import defaultLogoUrl from '/logo.png'
import { getFriendlyErrorMessage } from '../../utils/errorHandler';

const schema = z.object({
  email: z.string().min(1, 'Email wajib diisi').email('Format email tidak valid').refine(val => !/\s/.test(val), 'Email tidak boleh mengandung spasi'),
  password: z.string().min(1, 'Password wajib diisi').refine(val => !/\s/.test(val), 'Password tidak boleh mengandung spasi'),
  rememberMe: z.boolean().optional(),
})

type FormValues = z.infer<typeof schema>

export function LoginPage() {
  const login = useAuthStore((s) => s.login)
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [siteName, setSiteName] = useState('IKA JTK POLBAN')
  const [logo, setLogo] = useState(defaultLogoUrl)
  
  const [savedCredentials, setSavedCredentials] = useState<Record<string, string>>({})
  const [showSuggestions, setShowSuggestions] = useState(false)
  const [suggestions, setSuggestions] = useState<string[]>([])
  const wrapperRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    api.getPublicPortalConfig().then((data) => {
      if (data?.site_name) {
        setSiteName(data.site_name)
        document.title = `${data.site_name} — Admin`
      }
      if (data?.logo_url) setLogo(getFileUrl(data.logo_url))
    }).catch(() => {})
    
    // Load saved credentials
    try {
      const saved = localStorage.getItem('cms_saved_credentials')
      if (saved) {
        setSavedCredentials(JSON.parse(saved))
      }
    } catch (e) {
      // ignore
    }
  }, [])
  
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
        setShowSuggestions(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { email: '', password: '', rememberMe: true },
  })

  const emailValue = watch('email')
  
  // Langsung terisi bagian username begitu membuka page login (hanya username, password tidak)
  useEffect(() => {
    try {
      const lastUser = localStorage.getItem('cms_last_username')
      const saved = localStorage.getItem('cms_saved_credentials')
      if (lastUser && lastUser.trim() !== '') {
        setValue('email', lastUser, { shouldValidate: true })
      } else if (saved) {
        const parsed = JSON.parse(saved)
        const keys = Object.keys(parsed)
        if (keys.length > 0) {
          setValue('email', keys[keys.length - 1], { shouldValidate: true })
        }
      }
    } catch (e) {
      // ignore
    }
  }, [setValue])
  
  useEffect(() => {
    if (emailValue) {
      const matches = Object.keys(savedCredentials).filter(k => 
        k.toLowerCase().includes(emailValue.toLowerCase())
      )
      setSuggestions(matches)
      setShowSuggestions(true)
    } else {
      setSuggestions([])
      setShowSuggestions(false)
    }
  }, [emailValue, savedCredentials])

  const handleSelectAccount = (email: string) => {
    setValue('email', email, { shouldValidate: true })
    // Do not autofill the password field
    setShowSuggestions(false)
  }

  const onSubmit = async (values: FormValues) => {
    setError(null)
    setLoading(true)
    try {
      await login(values.email, values.password)

      localStorage.setItem('cms_last_username', values.email.trim())
      if (values.rememberMe) {
        const updated = { ...savedCredentials, [values.email.trim()]: '' } // Do not save password
        localStorage.setItem('cms_saved_credentials', JSON.stringify(updated))
        setSavedCredentials(updated)
      }
      
      navigate('/admin/alumni', { replace: true })
    } catch (err: any) {
      setError(getFriendlyErrorMessage(err, 'Login gagal. Coba lagi.'))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="w-full max-w-md rounded-xl border border-gray-200 bg-white shadow-lg p-8">
      <div className="flex items-center gap-3 mb-6">
        <img src={logo} alt="Logo" className="h-10 w-10 object-contain" />
        <div>
          <p className="font-bold text-primary leading-tight">{siteName}</p>
          <p className="text-xs text-gray-500">Panel Admin</p>
        </div>
      </div>
      <h1 className="text-2xl font-bold text-gray-900 mb-1">Masuk</h1>
      <p className="text-sm text-gray-500 mb-6">
        Gunakan akun admin untuk mengelola portal IKA JTK.
      </p>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
        <div className="relative" ref={wrapperRef}>
          <Label htmlFor="email" required>Email</Label>
          <Input
            id="email"
            type="email"
            noSpaces
            placeholder="admin@ikajtk.id"
            autoComplete="username"
            {...register('email')}
            error={errors.email?.message}
            onFocus={() => {
              if (suggestions.length > 0) setShowSuggestions(true)
            }}
          />
          {showSuggestions && suggestions.length > 0 && (
            <div className="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-md shadow-lg max-h-48 overflow-y-auto">
              <ul className="py-1">
                {suggestions.map((s) => (
                  <li 
                    key={s}
                    className="px-4 py-2 hover:bg-gray-100 cursor-pointer text-sm text-gray-800"
                    onClick={() => handleSelectAccount(s)}
                  >
                    {s}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
        <div>
          <Label htmlFor="password" required>Password</Label>
          <Input
            id="password"
            type="password"
            noSpaces
            placeholder="••••••••"
            autoComplete="off"
            {...register('password')}
            error={errors.password?.message}
          />
        </div>
        
        <div className="flex items-center gap-2">
          <input
            type="checkbox"
            id="rememberMe"
            className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
            {...register('rememberMe')}
          />
          <Label htmlFor="rememberMe" className="text-sm text-gray-600 cursor-pointer mb-0 pb-0">
            Ingat saya
          </Label>
        </div>

        {error && (
          <p className="text-sm text-danger bg-danger-bg border border-danger/20 rounded-md px-3 py-2">
            {error}
          </p>
        )}
        <Button type="submit" loading={loading} className="w-full" size="lg">
          Masuk
        </Button>
      </form>
    </div>
  )
}
