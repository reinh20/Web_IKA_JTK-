import { createBrowserRouter, Navigate } from 'react-router-dom'
import { AdminLayout } from '@/layouts/AdminLayout'
import { AuthLayout } from '@/layouts/AuthLayout'
import { LoginPage } from '@/pages/auth/LoginPage'
import { DashboardPage } from '@/pages/admin/DashboardPage'
import { AlumniListPage } from '@/pages/admin/AlumniListPage'
import { AlumniFormPage } from '@/pages/admin/AlumniFormPage'
import { AlumniDetailPage } from '@/pages/admin/AlumniDetailPage'
import { AlumniGrafisListPage } from '@/pages/admin/AlumniGrafisListPage'
import { BeritaListPage } from '@/pages/admin/BeritaListPage'
import { BeritaFormPage } from '@/pages/admin/BeritaFormPage'
import { BeritaDetailPage } from '@/pages/admin/BeritaDetailPage'
import { AgendaListPage } from '@/pages/admin/AgendaListPage'
import { AgendaFormPage } from '@/pages/admin/AgendaFormPage'
import { AgendaDetailPage } from '@/pages/admin/AgendaDetailPage'
import { LokerListPage } from '@/pages/admin/LokerListPage'
import { LokerFormPage } from '@/pages/admin/LokerFormPage'
import { LokerDetailPage } from '@/pages/admin/LokerDetailPage'
import { TestimoniListPage } from '@/pages/admin/TestimoniListPage'
import { TestimoniDetailPage } from '@/pages/admin/TestimoniDetailPage'
import { PemiluListPage } from '@/pages/admin/PemiluListPage'
import { PemiluDetailPage } from '@/pages/admin/PemiluDetailPage'
import { PemiluFormPage, KandidatFormPage } from '@/pages/admin/PemiluFormPage'
import { PortalSettingsPage } from '@/pages/admin/PortalSettingsPage'
import { AdminUserListPage } from '@/pages/admin/AdminUserListPage'
import { AdminUserFormPage } from '@/pages/admin/AdminUserFormPage'
import { RoleListPage } from '@/pages/admin/RoleListPage'
import { RoleFormPage } from '@/pages/admin/RoleFormPage'
import { AuditLogListPage } from '@/pages/admin/AuditLogListPage'
import { UserAgreementsPage } from '@/pages/admin/UserAgreementsPage'
import { PermissionGuard } from '@/components/admin/PermissionGuard'

export const router = createBrowserRouter([
  {
    path: '/',
    element: <Navigate to="/admin/dashboard" replace />,
  },
  {
    element: <AuthLayout />,
    children: [
      { path: '/login', element: <LoginPage /> },
      { path: '/admin/login', element: <LoginPage /> },
    ],
  },
  {
    path: '/admin',
    element: <AdminLayout />,
    children: [
      { index: true, element: <Navigate to="/admin/dashboard" replace /> },
      { path: 'dashboard', element: <DashboardPage /> },

      // Alumni
      { path: 'alumni', element: <PermissionGuard permission="alumni_view"><AlumniListPage /></PermissionGuard> },
      { path: 'alumni/new', element: <PermissionGuard permission="alumni_view"><AlumniFormPage /></PermissionGuard> },
      { path: 'alumni/:id', element: <PermissionGuard permission="alumni_view"><AlumniDetailPage /></PermissionGuard> },
      { path: 'alumni/:id/edit', element: <PermissionGuard permission="alumni_view"><AlumniFormPage /></PermissionGuard> },

      // Alumni Grafis
      { path: 'alumni-grafis', element: <PermissionGuard permission="alumni_view"><AlumniGrafisListPage /></PermissionGuard> },

      // Berita
      { path: 'berita', element: <PermissionGuard permission="berita_view"><BeritaListPage /></PermissionGuard> },
      { path: 'berita/new', element: <PermissionGuard permission="berita_view"><BeritaFormPage /></PermissionGuard> },
      { path: 'berita/:id', element: <PermissionGuard permission="berita_view"><BeritaDetailPage /></PermissionGuard> },
      { path: 'berita/:id/edit', element: <PermissionGuard permission="berita_view"><BeritaFormPage /></PermissionGuard> },

      // Agenda
      { path: 'agenda', element: <PermissionGuard permission="agenda_view"><AgendaListPage /></PermissionGuard> },
      { path: 'agenda/new', element: <PermissionGuard permission="agenda_view"><AgendaFormPage /></PermissionGuard> },
      { path: 'agenda/:id', element: <PermissionGuard permission="agenda_view"><AgendaDetailPage /></PermissionGuard> },
      { path: 'agenda/:id/edit', element: <PermissionGuard permission="agenda_view"><AgendaFormPage /></PermissionGuard> },

      // Loker
      { path: 'loker', element: <PermissionGuard permission="loker_view"><LokerListPage /></PermissionGuard> },
      { path: 'loker/new', element: <PermissionGuard permission="loker_view"><LokerFormPage /></PermissionGuard> },
      { path: 'loker/:id', element: <PermissionGuard permission="loker_view"><LokerDetailPage /></PermissionGuard> },
      { path: 'loker/:id/edit', element: <PermissionGuard permission="loker_view"><LokerFormPage /></PermissionGuard> },

      // Testimoni
      { path: 'testimoni', element: <PermissionGuard permission="testimoni_view"><TestimoniListPage /></PermissionGuard> },
      { path: 'testimoni/:id', element: <PermissionGuard permission="testimoni_view"><TestimoniDetailPage /></PermissionGuard> },

      // Pemilu
      { path: 'pemilu', element: <PermissionGuard permission="pemilu_view"><PemiluListPage /></PermissionGuard> },
      { path: 'pemilu/new', element: <PermissionGuard permission="pemilu_view"><PemiluFormPage /></PermissionGuard> },
      { path: 'pemilu/:id', element: <PermissionGuard permission="pemilu_view"><PemiluDetailPage /></PermissionGuard> },
      { path: 'pemilu/:id/edit', element: <PermissionGuard permission="pemilu_view"><PemiluFormPage /></PermissionGuard> },
      { path: 'pemilu/:electionId/kandidat/new', element: <PermissionGuard permission="pemilu_view"><KandidatFormPage /></PermissionGuard> },
      { path: 'pemilu/:electionId/kandidat/:kandidatId/edit', element: <PermissionGuard permission="pemilu_view"><KandidatFormPage /></PermissionGuard> },

      // Portal Settings
      { path: 'portal', element: <PermissionGuard permission="settings_view"><PortalSettingsPage /></PermissionGuard> },

      // Manajemen Admin
      { path: 'users', element: <PermissionGuard permission="users_view"><AdminUserListPage /></PermissionGuard> },
      { path: 'users/new', element: <PermissionGuard permission="users_view"><AdminUserFormPage /></PermissionGuard> },
      { path: 'users/:id/edit', element: <PermissionGuard permission="users_view"><AdminUserFormPage /></PermissionGuard> },

      // Manajemen Role
      { path: 'roles', element: <PermissionGuard permission="roles_view"><RoleListPage /></PermissionGuard> },
      { path: 'roles/new', element: <PermissionGuard permission="roles_view"><RoleFormPage /></PermissionGuard> },
      { path: 'roles/:name/edit', element: <PermissionGuard permission="roles_view"><RoleFormPage /></PermissionGuard> },

      // Audit Log
      { path: 'audit-logs', element: <PermissionGuard permission="audit_log_view"><AuditLogListPage /></PermissionGuard> },

      // User Agreements
      { path: 'user-agreements', element: <PermissionGuard permission="settings_view"><UserAgreementsPage /></PermissionGuard> },
    ],
  },
  {
    path: '*',
    element: (
      <div className="min-h-screen flex items-center justify-center text-gray-500">
        404 — Halaman tidak ditemukan
      </div>
    ),
  },
])
