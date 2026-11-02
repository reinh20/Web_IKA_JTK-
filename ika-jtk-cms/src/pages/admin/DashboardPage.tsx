import { Link } from 'react-router-dom'
import { useState, useEffect } from 'react'
import {
  Users, Newspaper, Calendar, Briefcase, MessageSquareQuote, Vote,
  TrendingUp, Clock, Bell, ChevronRight,
} from 'lucide-react'
import { Breadcrumb } from '@/components/admin/Breadcrumb'
import { SectionCard } from '@/components/admin/SectionCard'
import { Badge } from '@/components/ui/Badge'
import { formatDate } from '@/lib/utils'
import { useAuthStore } from '@/stores/authStore'
import api from '@/lib/api'
import { AlumniStatus } from '@/types/alumni'

export function DashboardPage() {
  const user = useAuthStore((s) => s.user)

  const [alumniActive, setAlumniActive] = useState(0)
  const [alumniBaru, setAlumniBaru] = useState(0)
  const [alumniTotal, setAlumniTotal] = useState(0)
  const [beritaPublished, setBeritaPublished] = useState(0)
  const [beritaSubmission, setBeritaSubmission] = useState(0)
  const [agendaPublished, setAgendaPublished] = useState(0)
  const [agendaSubmission, setAgendaSubmission] = useState(0)
  const [lokerPublished, setLokerPublished] = useState(0)
  const [lokerSubmission, setLokerSubmission] = useState(0)
  const [recentBerita, setRecentBerita] = useState<any[]>([])
  const [upcomingAgenda, setUpcomingAgenda] = useState<any[]>([])

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [resAlumni, resBerita, resAgenda, resLoker] = await Promise.all([
          api.get('/admin/alumni'),
          api.get('/admin/berita'),
          api.get('/admin/agenda'),
          api.get('/admin/loker'),
        ])

        const alumni = resAlumni.data || []
        const berita = resBerita.data || []
        const agenda = resAgenda.data || []
        const loker = resLoker.data || []

        setAlumniTotal(alumni.length)
        setAlumniActive(alumni.filter((a: any) => a.status === AlumniStatus.ACTIVE || a.status === AlumniStatus.APPROVED).length)
        setAlumniBaru(alumni.filter((a: any) => a.status === AlumniStatus.PENDING).length)

        setBeritaPublished(berita.filter((b: any) => b.status === 'Published').length)
        setBeritaSubmission(berita.filter((b: any) => b.status === 'Submission').length)

        setAgendaPublished(agenda.filter((a: any) => a.status === 'Published').length)
        setAgendaSubmission(agenda.filter((a: any) => a.status === 'Submission').length)

        setLokerPublished(loker.filter((l: any) => l.status === 'Published').length)
        setLokerSubmission(loker.filter((l: any) => l.status === 'Submission').length)

        setRecentBerita(berita.slice(0, 4))
        setUpcomingAgenda(agenda.slice(0, 4))
      } catch (error) {
        console.error('Failed to fetch dashboard data', error)
      }
    }
    fetchData()
  }, [])

  const totalSubmissions = alumniBaru + beritaSubmission + agendaSubmission + lokerSubmission

  return (
    <div className="px-10 py-8">
      <Breadcrumb items={[{ label: 'Dashboard' }]} />
      <h1 className="mt-2 text-3xl font-bold text-gray-900">
        Selamat datang, {user?.nama ?? 'Admin'}!
      </h1>
      <span className="block mt-2 h-0.5 w-10 bg-accent rounded-full" />
      <p className="mt-4 text-sm text-gray-600">
        Ringkasan aktivitas dan data IKA JTK POLBAN hari ini.
      </p>

      {/* Stats grid */}
      <div className="mt-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          icon={<Users className="h-5 w-5" />}
          color="primary"
          label="Total Alumni"
          value={alumniTotal}
          sub={`${alumniActive} aktif`}
          to="/admin/alumni"
        />
        <StatCard
          icon={<Newspaper className="h-5 w-5" />}
          color="accent"
          label="Berita"
          value={beritaPublished}
          sub={`${beritaSubmission} submission`}
          to="/admin/berita"
        />
        <StatCard
          icon={<Calendar className="h-5 w-5" />}
          color="success"
          label="Agenda Aktif"
          value={agendaPublished}
          sub={`${agendaSubmission} submission`}
          to="/admin/agenda"
        />
        <StatCard
          icon={<Briefcase className="h-5 w-5" />}
          color="navy"
          label="Lowongan"
          value={lokerPublished}
          sub={`${lokerSubmission} submission`}
          to="/admin/loker"
        />
      </div>

      {/* Notifications & Quick actions */}
      <div className="mt-6 grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6 items-start">
        <div className="space-y-6">
          {/* Pending submissions */}
          <SectionCard title="Menunggu Tindakan">
            <div className="space-y-2">
              <SubmissionRow
                label="Pendaftaran Alumni Baru"
                count={alumniBaru}
                to="/admin/alumni?tab=baru"
                hint="Verifikasi & approve pendaftaran dari portal"
              />
              <SubmissionRow
                label="Submission Berita"
                count={beritaSubmission}
                to="/admin/berita?tab=submission"
                hint="Berita dari alumni menunggu review"
              />
              <SubmissionRow
                label="Submission Agenda"
                count={agendaSubmission}
                to="/admin/agenda?tab=submission"
                hint="Acara dari alumni menunggu review"
              />
              <SubmissionRow
                label="Submission Loker"
                count={lokerSubmission}
                to="/admin/loker?tab=submission"
                hint="Lowongan dari alumni menunggu review"
              />
              {totalSubmissions === 0 && (
                <p className="text-sm text-gray-500 py-4 text-center">
                  Tidak ada submission menunggu. Hebat!
                </p>
              )}
            </div>
          </SectionCard>

          {/* Recent berita */}
          <SectionCard
            title="Berita Terbaru"
            actions={
              <Link
                to="/admin/berita"
                className="text-sm font-semibold text-primary hover:underline inline-flex items-center gap-1"
              >
                Lihat semua <ChevronRight className="h-3 w-3" />
              </Link>
            }
          >
            <div className="divide-y divide-gray-100 -my-3">
              {recentBerita.map((b) => (
                <Link
                  key={b.id}
                  to={`/admin/berita/${b.id}`}
                  className="flex items-center gap-3 py-3 hover:bg-gray-50/60 rounded-md px-2 -mx-2"
                >
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 truncate">
                      {b.judul}
                    </p>
                    <p className="text-xs text-gray-500">
                      {formatDate(b.createdAt)} · {b.author.nama}
                    </p>
                  </div>
                  <Badge
                    variant={
                      b.status === 'Published'
                        ? 'green'
                        : b.status === 'Draft'
                          ? 'orange'
                          : 'gray'
                    }
                  >
                    {b.status}
                  </Badge>
                </Link>
              ))}
            </div>
          </SectionCard>
        </div>

        <aside className="space-y-6">
          <SectionCard title="Agenda Mendatang">
            <div className="divide-y divide-gray-100 -my-3">
              {upcomingAgenda.map((a) => (
                <Link
                  key={a.id}
                  to={`/admin/agenda/${a.id}`}
                  className="flex items-start gap-3 py-3 hover:bg-gray-50/60 rounded-md px-2 -mx-2"
                >
                  <div className="flex-shrink-0 w-12 text-center bg-primary-light text-primary rounded-md py-1">
                    <p className="text-xs font-bold">
                      {new Date(a.tanggalEvent).getDate()}
                    </p>
                    <p className="text-[10px] uppercase">
                      {new Date(a.tanggalEvent).toLocaleString('id-ID', {
                        month: 'short',
                      })}
                    </p>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 line-clamp-1">
                      {a.judul}
                    </p>
                    <p className="text-xs text-gray-500 truncate">{a.lokasi}</p>
                  </div>
                </Link>
              ))}
            </div>
          </SectionCard>

          <SectionCard title="Quick Actions">
            <div className="space-y-2">
              <QuickAction
                icon={<Newspaper className="h-4 w-4" />}
                label={user?.permissions?.includes('berita_edit') || user?.role === 'Super Admin' ? 'Tambah Berita' : 'Lihat Berita'}
                to={user?.permissions?.includes('berita_edit') || user?.role === 'Super Admin' ? '/admin/berita/new' : '/admin/berita'}
              />
              <QuickAction
                icon={<Calendar className="h-4 w-4" />}
                label={user?.permissions?.includes('agenda_edit') || user?.role === 'Super Admin' ? 'Tambah Agenda' : 'Lihat Agenda'}
                to={user?.permissions?.includes('agenda_edit') || user?.role === 'Super Admin' ? '/admin/agenda/new' : '/admin/agenda'}
              />
              <QuickAction
                icon={<Briefcase className="h-4 w-4" />}
                label={user?.permissions?.includes('loker_edit') || user?.role === 'Super Admin' ? 'Tambah Loker' : 'Lihat Loker'}
                to={user?.permissions?.includes('loker_edit') || user?.role === 'Super Admin' ? '/admin/loker/new' : '/admin/loker'}
              />
              <QuickAction
                icon={<MessageSquareQuote className="h-4 w-4" />}
                label={user?.permissions?.includes('testimoni_edit') || user?.role === 'Super Admin' ? 'Kelola Testimoni' : 'Lihat Testimoni'}
                to="/admin/testimoni"
              />
              <QuickAction
                icon={<Vote className="h-4 w-4" />}
                label={user?.permissions?.includes('pemilu_edit') || user?.role === 'Super Admin' ? 'Kelola Pemilu' : 'Lihat Pemilu'}
                to="/admin/pemilu"
              />
            </div>
          </SectionCard>
        </aside>
      </div>
    </div>
  )
}

interface StatCardProps {
  icon: React.ReactNode
  color: 'primary' | 'accent' | 'success' | 'navy'
  label: string
  value: number
  sub: string
  to: string
}

function StatCard({ icon, color, label, value, sub, to }: StatCardProps) {
  const colorBg = {
    primary: 'bg-primary-light text-primary',
    accent: 'bg-accent-light text-accent',
    success: 'bg-success-bg text-success',
    navy: 'bg-navy text-white',
  }[color]

  return (
    <Link
      to={to}
      className="block rounded-lg border border-gray-200 bg-white p-5 hover:shadow-md transition-shadow group"
    >
      <div className="flex items-center justify-between mb-3">
        <div className={`p-2 rounded-md ${colorBg}`}>{icon}</div>
        <ChevronRight className="h-4 w-4 text-gray-400 group-hover:text-gray-700 transition-colors" />
      </div>
      <p className="text-2xl font-bold text-gray-900">{value.toLocaleString('id-ID')}</p>
      <p className="text-sm font-medium text-gray-700 mt-0.5">{label}</p>
      <p className="text-xs text-gray-500 mt-1 flex items-center gap-1">
        <TrendingUp className="h-3 w-3" />
        {sub}
      </p>
    </Link>
  )
}

function SubmissionRow({
  label, count, to, hint,
}: { label: string; count: number; to: string; hint: string }) {
  return (
    <Link
      to={to}
      className="flex items-center gap-3 p-3 hover:bg-gray-50 rounded-md transition-colors"
    >
      <div className="p-2 rounded-md bg-accent-light text-accent">
        <Bell className="h-4 w-4" />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-900">{label}</p>
        <p className="text-xs text-gray-500">{hint}</p>
      </div>
      {count > 0 ? (
        <Badge variant="orange">{count} baru</Badge>
      ) : (
        <span className="text-xs text-gray-400">Tidak ada</span>
      )}
    </Link>
  )
}

function QuickAction({ icon, label, to }: { icon: React.ReactNode; label: string; to: string }) {
  return (
    <Link
      to={to}
      className="flex items-center gap-3 p-2.5 rounded-md hover:bg-gray-50 text-sm text-gray-700 hover:text-gray-900"
    >
      <span className="text-gray-500">{icon}</span>
      {label}
      <Clock className="h-3 w-3 text-gray-400 ml-auto" />
    </Link>
  )
}
