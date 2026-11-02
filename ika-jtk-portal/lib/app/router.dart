import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/landing/presentation/landing_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/register_success_page.dart';
import '../features/auth/presentation/verify_email_page.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/member/presentation/member_landing_page.dart';
import '../features/member/presentation/profile_page.dart';
import '../features/member/presentation/my_profile_page.dart';
import '../features/member/presentation/edit_profile_page.dart';
import '../features/member/presentation/notifications_page.dart';
import '../features/member/presentation/alumni_directory_page.dart';
import '../features/member/presentation/alumni_grafis_page.dart';
import '../features/member/presentation/alumni_public_profile_page.dart';
import '../features/member/presentation/lamaran_page.dart';
import '../features/member/presentation/submit_konten_page.dart';
import '../features/member/presentation/beri_testimoni_page.dart';
import '../features/berita/presentation/berita_page.dart';
import '../features/berita/presentation/berita_detail_page.dart';
import '../features/agenda/presentation/agenda_page.dart';
import '../features/agenda/presentation/agenda_detail_page.dart';
import '../features/loker/presentation/loker_page.dart';
import '../features/loker/presentation/loker_detail_page.dart';
import '../features/loker/presentation/apply_loker_page.dart';
import '../features/static/presentation/tentang_page.dart';
import '../features/static/presentation/suggestion_page.dart';
import '../features/static/presentation/user_agreements_page.dart';
import '../features/pemilu/presentation/pemilu_page.dart';
import '../features/pemilu/presentation/candidate_detail_page.dart';
import '../features/pemilu/presentation/vote_page.dart';
import '../features/pemilu/presentation/pemilu_statistik_page.dart';

/// ChangeNotifier yang "listen" ke authProvider dan memberi tahu GoRouter
/// agar mengevaluasi ulang `redirect` setiap kali state auth berubah.
/// Ini penting agar setelah _loadSession() selesai (async), router
/// langsung re-evaluate redirect tanpa perlu user berinteraksi.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

Widget _seoTitle(String title, Widget child) {
  return Title(
    title: title == 'Beranda' ? 'IKA JTK POLBAN — Portal Alumni' : '$title — IKA JTK POLBAN',
    color: const Color(0xFF1E3A8A),
    child: child,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    // refreshListenable memastikan redirect di-evaluasi ulang
    // setiap kali notifier memanggil notifyListeners()
    // (terpicu saat: session selesai dimuat, login, logout)
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Tunggu hingga session selesai dimuat dari SharedPreferences.
      // Selama belum siap, jangan redirect ke mana pun.
      if (!authState.isInitialized) return null;

      final loggedIn = authState.isLoggedIn;
      final loc = state.matchedLocation;
      final goingToMember = loc.startsWith('/member');
      final goingToVote = loc.contains('/vote');
      final goingToApply = loc.contains('/apply');
      final needsAuth = goingToMember || goingToVote || goingToApply;
      final goingToAuth = loc == '/login' || loc == '/register';

      if (needsAuth && !loggedIn) return '/login';
      if (goingToAuth && loggedIn) return '/member';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => _seoTitle('Beranda', const PublicLandingPage())),
      GoRoute(path: '/login', builder: (_, _) => _seoTitle('Masuk', const LoginPage())),
      GoRoute(path: '/register', builder: (_, _) => _seoTitle('Daftar Alumni', const RegisterPage())),
      GoRoute(
        path: '/register/verify',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return _seoTitle('Verifikasi Email', VerifyEmailPage(email: email));
        },
      ),
      GoRoute(
        path: '/register/success',
        builder: (_, _) => _seoTitle('Pendaftaran Berhasil', const RegisterSuccessPage()),
      ),
      GoRoute(path: '/lupa-sandi', builder: (_, _) => _seoTitle('Lupa Kata Sandi', const ForgotPasswordPage())),

      // Public content
      GoRoute(path: '/berita', builder: (_, _) => _seoTitle('Berita & Artikel', const BeritaListPage())),
      GoRoute(
        path: '/berita/:id',
        builder: (context, state) => _seoTitle('Detail Berita', BeritaDetailPage(beritaId: state.pathParameters['id']!)),
      ),
      GoRoute(path: '/agenda', builder: (_, _) => _seoTitle('Agenda & Event', const AgendaListPage())),
      GoRoute(
        path: '/agenda/:id',
        builder: (context, state) => _seoTitle('Detail Agenda', AgendaDetailPage(agendaId: state.pathParameters['id']!)),
      ),
      GoRoute(path: '/alumnigrafis', builder: (_, _) => _seoTitle('Infografis Alumni', const AlumniGrafisPage())),
      GoRoute(path: '/loker', builder: (_, _) => _seoTitle('Lowongan Kerja', const LokerListPage())),
      GoRoute(
        path: '/loker/:id',
        builder: (context, state) => _seoTitle('Detail Lowongan Kerja', LokerDetailPage(lokerId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/loker/:id/apply',
        builder: (context, state) => _seoTitle('Lamar Pekerjaan', ApplyLokerPage(lokerId: state.pathParameters['id']!)),
      ),
      GoRoute(path: '/tentang', builder: (_, _) => _seoTitle('Tentang IKA JTK', const TentangPage())),
      GoRoute(path: '/kritik-saran', builder: (_, _) => _seoTitle('Kritik & Saran', const SuggestionPage())),
      GoRoute(path: '/user-agreements', builder: (_, _) => _seoTitle('Kebijakan & Persetujuan Pengguna', const UserAgreementsPage())),
      GoRoute(
        path: '/alumni/:id',
        builder: (context, state) => _seoTitle('Profil Alumni', AlumniPublicProfilePage(alumniId: state.pathParameters['id']!)),
      ),

      // PEMILU (mixed public + member)
      GoRoute(path: '/pemilu', builder: (_, _) => _seoTitle('Pemilu Ketua IKA JTK', const PemiluPage())),
      GoRoute(path: '/pemilu/vote', builder: (_, _) => _seoTitle('Bilik Suara Pemilu', const VotePage())),
      GoRoute(path: '/pemilu/statistik', builder: (_, _) => _seoTitle('Statistik Pemilu', const PemiluStatistikPage())),
      GoRoute(
        path: '/pemilu/:id',
        builder: (context, state) => _seoTitle('Detail Kandidat', CandidateDetailPage(candidateId: state.pathParameters['id']!)),
      ),

      // Member-only
      GoRoute(
        path: '/member',
        builder: (_, _) => _seoTitle('Portal Anggota', const MemberLandingPage()),
        routes: [
          GoRoute(path: 'profile', builder: (_, _) => _seoTitle('Profil Saya', const MyProfilePage())),
          GoRoute(path: 'profile/edit', builder: (_, _) => _seoTitle('Edit Profil', const EditProfilePage())),
          GoRoute(path: 'notifications', builder: (_, _) => _seoTitle('Notifikasi', const NotificationsPage())),
          GoRoute(path: 'alumni', builder: (_, _) => _seoTitle('Direktori Alumni', const AlumniDirectoryPage())),
          GoRoute(
            path: 'alumni/:id',
            builder: (context, state) =>
                _seoTitle('Profil Alumni', AlumniPublicProfilePage(alumniId: state.pathParameters['id']!)),
          ),
          GoRoute(path: 'lamaran', builder: (_, _) => _seoTitle('Status Lamaran', const LamaranPage())),
          GoRoute(path: 'submit', builder: (_, _) => _seoTitle('Kirim Konten', const SubmitKontenPage())),
          GoRoute(path: 'testimoni', builder: (_, _) => _seoTitle('Tulis Testimoni', const BeriTestimoniPage())),
          GoRoute(path: 'profile-old', builder: (_, _) => _seoTitle('Profil Saya', const ProfilePage())),
        ],
      ),
    ],
  );
});
