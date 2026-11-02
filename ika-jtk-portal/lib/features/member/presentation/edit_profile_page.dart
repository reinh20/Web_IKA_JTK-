import 'dart:math' as math;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:ika_jtk_portal/shared/utils/file_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../app/tokens.dart';
import '../../../core/enums/alumni_status.dart';
import '../../../shared/widgets/searchable_dropdown_field.dart';
import '../../../shared/utils/country_codes.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/shimmer_placeholder.dart';
import '../../../shared/widgets/image_crop_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import 'widgets/member_app_bar.dart';
import '../providers/alumni_provider.dart';
import '../../berita/providers/berita_provider.dart';
import '../../agenda/providers/agenda_provider.dart';
import '../../loker/providers/loker_provider.dart';
import '../../pemilu/providers/pemilu_provider.dart';
import 'package:ika_jtk_portal/core/error_handler.dart';

/// Top-level function agar bisa dijalankan di background Isolate / Web Worker via compute()
Uint8List _compressImageIsolate(Uint8List bytes) {
  // Target ukuran dalam hitungan KB (< 500KB) untuk efisiensi database & storage
  const maxSize = 500 * 1024;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('Gagal membaca gambar');

  // Fast bypass: jika sudah kecil & resolusi di bawah batas, langsung kembalikan JPEG
  final jpgStep1 = img.encodeJpg(decoded, quality: 85);
  if (jpgStep1.length <= maxSize && decoded.width <= 1080 && decoded.height <= 1080) {
    return Uint8List.fromList(jpgStep1);
  }

  // Hitung dimensi maksimal 1080px
  final srcW = decoded.width;
  final srcH = decoded.height;
  const maxDim = 1080;

  final newW = srcW > srcH
      ? math.min(srcW, maxDim)
      : (srcW * math.min(srcH, maxDim) / srcH).round();
  final newH = srcW > srcH
      ? (srcH * math.min(srcW, maxDim) / srcW).round()
      : math.min(srcH, maxDim);

  // Gunakan Interpolation.linear (~3x lebih cepat dari cubic)
  final resized = img.copyResize(
    decoded,
    width: newW,
    height: newH,
    interpolation: img.Interpolation.linear,
  );

  final jpgResized = img.encodeJpg(resized, quality: 82);
  if (jpgResized.length <= maxSize) return Uint8List.fromList(jpgResized);

  // Fallback quality lebih rendah untuk edge case gambar noisy
  final jpgLowerQ = img.encodeJpg(resized, quality: 70);
  if (jpgLowerQ.length <= maxSize) return Uint8List.fromList(jpgLowerQ);

  throw Exception(
    'File terlalu besar setelah kompresi '
    '(${(jpgLowerQ.length / 1024 / 1024).toStringAsFixed(1)}MB). Batas maksimal adalah 4MB.',
  );
}

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _PekerjaanForm {
  String? id;
  String pekerjaan;
  String perusahaan;
  String bulanMulai;
  String tahunMulai;
  String bulanSelesai;
  String tahunSelesai;
  bool masihBekerja;
  bool isGrafis;
  _PekerjaanForm({
    String? id,
    this.pekerjaan = '',
    this.perusahaan = '',
    this.bulanMulai = '',
    this.tahunMulai = '',
    this.bulanSelesai = '',
    this.tahunSelesai = '',
    this.masihBekerja = false,
    this.isGrafis = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();
}

class _PrestasiForm {
  String? id;
  String judul;
  String tahun;
  String? buktiUrl;
  String? buktiFileName;
  Uint8List? buktiBytes;
  bool isBuktiError = false;
  bool isGrafis;
  
  _PrestasiForm({
    String? id,
    this.judul = '',
    this.tahun = '',
    this.buktiUrl,
    this.buktiFileName,
    this.buktiBytes,
    this.isGrafis = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _username = TextEditingController();
  final _tanggalLahir = TextEditingController();
  final _motto = TextEditingController();
  final _email = TextEditingController();
  final _hp = TextEditingController();
  final _linkedin = TextEditingController();
  final _alamat = TextEditingController();
  final _nomorIjazah = TextEditingController();
  final _ipk = TextEditingController();

  final _namaFocus = FocusNode();
  final _tanggalLahirFocus = FocusNode();
  final _angkatanFocus = FocusNode();
  final _hpFocus = FocusNode();

  final _dataAlumniAccordion = ExpansionTileController();
  final _kontakAccordion = ExpansionTileController();
  final _ijazahAccordion = ExpansionTileController();
  final _pekerjaanAccordion = ExpansionTileController();
  final _prestasiAccordion = ExpansionTileController();

  final _dataAlumniKey = GlobalKey();
  final _kontakKey = GlobalKey();
  final _ijazahKey = GlobalKey();
  final _pekerjaanKey = GlobalKey();
  final _prestasiKey = GlobalKey();

  String _angkatan = DateTime.now().year.toString();
  String _jenisKelamin = 'Laki-laki';
  String _tahunLulus = DateTime.now().year.toString();
  String? _ijazahFileName;
  bool _ijazahError = false;
  String? _avatarUrlState;

  String _emailVis = 'private';
  String _hpVis = 'private';
  String _alamatVis = 'private';
  
  String _hpPrefix = '🇮🇩 +62';

  final List<_PekerjaanForm> _pekerjaan = [];
  final List<_PrestasiForm> _prestasi = [];
  String? _alumniGrafisKategori;
  String? _alumniGrafisId;
  String? _alumniGrafisStatus; // PENDING, APPROVED, REJECTED
  bool _alumniGrafisRejectionDismissed = false;

  void _populateData(dynamic user) {
    if (user == null) return;
    _avatarUrlState = user.avatarUrl;
    _nama.text = user.nama;
    _username.text = user.username ?? '';
    _email.text = user.email;
    _tanggalLahir.text = user.tanggalLahir;
    _motto.text = user.motto ?? '';
    
    String hpRaw = user.hp ?? '';
    if (hpRaw.startsWith('+')) {
      hpRaw = hpRaw.substring(1);
    }
    
    final sortedCodes = List<Map<String, String>>.from(countryCodes)
      ..sort((a, b) => b['code']!.length.compareTo(a['code']!.length));
      
    bool found = false;
    if (hpRaw.startsWith('0')) {
      _hpPrefix = '🇮🇩 +62';
      hpRaw = hpRaw.substring(1).trim();
      found = true;
    } else {
      for (var c in sortedCodes) {
        if (hpRaw.startsWith(c['code']!)) {
          _hpPrefix = '${c['flag']} +${c['code']}';
          hpRaw = hpRaw.substring(c['code']!.length).trim();
          found = true;
          break;
        }
      }
    }
    if (!found) {
      _hpPrefix = '🇮🇩 +62';
    }
    _hp.text = hpRaw;
    
    String li = user.linkedin ?? '';
    li = li.replaceAll('https://www.linkedin.com/in/', '');
    li = li.replaceAll('https://linkedin.com/in/', '');
    _linkedin.text = li;
    
    _alamat.text = user.alamat ?? '';
    _nomorIjazah.text = user.nomorIjazah ?? '';
    _ipk.text = user.ipk != null ? user.ipk.toString() : '';
    _angkatan = user.angkatan?.toString() ?? DateTime.now().year.toString();
    _jenisKelamin = user.jenisKelamin;
    _tahunLulus = user.tahunLulus?.toString() ?? DateTime.now().year.toString();
    _ijazahFileName = (user.ijazahFile != null && user.ijazahFile!.isNotEmpty) ? user.ijazahFile : null;

    _emailVis = user.emailVisibility;
    _hpVis = user.hpVisibility;
    _alamatVis = user.alamatVisibility;

    _pekerjaan.clear();
    if (user.pekerjaan.isNotEmpty) {
      for (var p in user.pekerjaan) {
        _pekerjaan.add(_PekerjaanForm(
          id: p['id']?.toString(),
          pekerjaan: p['pekerjaan']?.toString() ?? '',
          perusahaan: p['perusahaan']?.toString() ?? '',
          bulanMulai: p['bulanMulai']?.toString() ?? '',
          tahunMulai: p['tahunMulai']?.toString() ?? '',
          bulanSelesai: p['bulanSelesai']?.toString() ?? '',
          tahunSelesai: p['tahunSelesai']?.toString() ?? '',
          masihBekerja: p['masihBekerja'] ?? false,
          isGrafis: p['isGrafis'] ?? false,
        ));
      }
    }

    _prestasi.clear();
    if (user.prestasi.isNotEmpty) {
      for (var p in user.prestasi) {
        _prestasi.add(_PrestasiForm(
          id: p['id']?.toString(),
          judul: p['judul']?.toString() ?? '',
          tahun: p['tahun']?.toString() ?? '',
          buktiUrl: p['buktiUrl'],
          isGrafis: p['isGrafis'] ?? false,
        ));
      }
    }
    
    if (user.alumniGrafis != null) {
      try {
        final decoded = (user.alumniGrafis is String) 
            ? jsonDecode(user.alumniGrafis) 
            : user.alumniGrafis;
        _alumniGrafisKategori = decoded['kategori']?.toString();
        if (_alumniGrafisKategori == 'Public Figure') {
          _alumniGrafisKategori = 'Jabatan strategis/Public Figure';
        }
        _alumniGrafisId = decoded['id']?.toString();
        _alumniGrafisStatus = decoded['status']?.toString();
      } catch (_) {}
    }

    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _populateData(user);
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _username.dispose();
    _tanggalLahir.dispose();
    _motto.dispose();
    _email.dispose();
    _hp.dispose();
    _linkedin.dispose();
    _alamat.dispose();
    _nomorIjazah.dispose();
    _ipk.dispose();
    _namaFocus.dispose();
    _tanggalLahirFocus.dispose();
    _angkatanFocus.dispose();
    _hpFocus.dispose();
    super.dispose();
  }

  void _expandAndScroll(ExpansionTileController controller, GlobalKey key, [FocusNode? focusNode]) {
    try {
      if (!controller.isExpanded) {
        controller.expand();
      }
    } catch (_) {
      // Ignore if not attached yet
    }
    
    // Wait for the expansion animation to start/finish
    Future.delayed(const Duration(milliseconds: 250), () {
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1, // Scroll so the header is near the top
        ).then((_) {
          if (focusNode != null) focusNode.requestFocus();
        });
      } else if (focusNode != null) {
        focusNode.requestFocus();
      }
    });
  }

  Future<void> _onSubmit() async {
    setState(() {
      _ijazahError = false;
    });

    final isStrictMode = _pekerjaan.any((p) => p.pekerjaan.isNotEmpty || p.perusahaan.isNotEmpty) ||
                         _prestasi.any((p) => p.judul.isNotEmpty) ||
                         (_alumniGrafisKategori != null && _alumniGrafisKategori!.isNotEmpty && _alumniGrafisKategori != 'None');

    final isFormValid = _formKey.currentState!.validate();

    // Periksa urut dari atas ke bawah, agar menggeser (scroll & expand) ke section pertama yang belum terisi
    if (isStrictMode && (_avatarUrlState == null || _avatarUrlState!.isEmpty) && _newAvatarBytes == null) {
      _expandAndScroll(_dataAlumniAccordion, _dataAlumniKey);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon unggah foto profil untuk verifikasi profil.'), backgroundColor: AppColors.danger));
      return;
    }
    if (_nama.text.trim().isEmpty) {
      _expandAndScroll(_dataAlumniAccordion, _dataAlumniKey, _namaFocus);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi nama lengkap Anda.'), backgroundColor: AppColors.danger));
      return;
    }
    if (_angkatan.isEmpty) {
      _expandAndScroll(_dataAlumniAccordion, _dataAlumniKey, _angkatanFocus);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon pilih tahun angkatan Anda.'), backgroundColor: AppColors.danger));
      return;
    }
    if (isStrictMode && _tanggalLahir.text.trim().isEmpty) {
      _expandAndScroll(_dataAlumniAccordion, _dataAlumniKey, _tanggalLahirFocus);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi tanggal lahir Anda untuk verifikasi profil.'), backgroundColor: AppColors.danger));
      return;
    }
    if (isStrictMode && _jenisKelamin.isEmpty) {
      _expandAndScroll(_dataAlumniAccordion, _dataAlumniKey);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon pilih jenis kelamin Anda.'), backgroundColor: AppColors.danger));
      return;
    }
    if (_hp.text.trim().isEmpty || _hp.text.length < 6 || _hp.text.length > 15) {
      _expandAndScroll(_kontakAccordion, _kontakKey, _hpFocus);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon periksa kembali nomor handphone Anda.'), backgroundColor: AppColors.danger));
      return;
    }
    if (isStrictMode && _linkedin.text.trim().isEmpty) {
      _expandAndScroll(_kontakAccordion, _kontakKey, null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon cantumkan profil LinkedIn Anda untuk verifikasi profil.'), backgroundColor: AppColors.danger));
      return;
    }
    if ((isStrictMode && _alamat.text.trim().isEmpty) || _alamat.text.trim().length > 300) {
      _expandAndScroll(_kontakAccordion, _kontakKey, null);
      final msg = _alamat.text.trim().isEmpty
          ? 'Mohon isi alamat domisili Anda untuk verifikasi profil.'
          : 'Alamat domisili maksimal 300 karakter.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.danger));
      return;
    }
    if (isStrictMode && _nomorIjazah.text.trim().isEmpty) {
      _expandAndScroll(_ijazahAccordion, _ijazahKey, null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi Nomor Ijazah / PDDIKTI / Surat Keterangan Jurusan untuk verifikasi profil.'), backgroundColor: AppColors.danger));
      return;
    }
    if (isStrictMode && _tahunLulus.isEmpty) {
      _expandAndScroll(_ijazahAccordion, _ijazahKey, null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon pilih tahun kelulusan Anda.'), backgroundColor: AppColors.danger));
      return;
    }
    if (_tahunLulus.isNotEmpty && _angkatan.isNotEmpty && (int.tryParse(_tahunLulus) ?? 0) < (int.tryParse(_angkatan) ?? 0)) {
      _expandAndScroll(_ijazahAccordion, _ijazahKey, null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tahun kelulusan tidak boleh lebih kecil dari angkatan.'), backgroundColor: AppColors.danger));
      return;
    }
    if (isStrictMode && _ipk.text.trim().isEmpty) {
      _expandAndScroll(_ijazahAccordion, _ijazahKey, null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi nilai IPK Anda untuk verifikasi profil.'), backgroundColor: AppColors.danger));
      return;
    }
    if (_ipk.text.trim().isNotEmpty && (double.tryParse(_ipk.text) ?? 0) > 4.00) {
      _expandAndScroll(_ijazahAccordion, _ijazahKey, null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nilai IPK maksimal adalah 4.00.'), backgroundColor: AppColors.danger));
      return;
    }
    if (isStrictMode && (_ijazahFileName == null || _ijazahFileName!.isEmpty)) {
      setState(() => _ijazahError = true);
      _expandAndScroll(_ijazahAccordion, _ijazahKey, null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon unggah dokumen ijazah untuk verifikasi profil Anda.'), backgroundColor: AppColors.danger));
      return;
    }
    if (_pekerjaan.any((p) => p.pekerjaan.isEmpty)) {
      _expandAndScroll(_pekerjaanAccordion, _pekerjaanKey);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi nama pekerjaan / posisi pada riwayat pekerjaan Anda.'), backgroundColor: AppColors.danger));
      return;
    }
    if (_prestasi.any((p) => (p.judul.isNotEmpty && p.tahun.isEmpty) || (p.judul.isEmpty && p.tahun.isNotEmpty))) {
      _expandAndScroll(_prestasiAccordion, _prestasiKey);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi judul dan tahun pada riwayat prestasi Anda.'), backgroundColor: AppColors.danger));
      return;
    }
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terdapat data pada formulir yang belum sesuai. Mohon periksa kembali isian Anda.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    
    // Catat status sebelum submit — untuk menampilkan pesan yang tepat setelahnya
    final wasRejected = ref.read(authProvider).user?.status == AlumniStatus.rejected;

    final pekerjaanList = _pekerjaan.map((p) {
      if (p.id == null || p.id!.isEmpty) p.id = DateTime.now().millisecondsSinceEpoch.toString() + p.hashCode.toString();
      return {
        'id': p.id,
        'pekerjaan': p.pekerjaan,
        'perusahaan': p.perusahaan,
        'bulanMulai': p.bulanMulai,
        'tahunMulai': int.tryParse(p.tahunMulai),
        'bulanSelesai': p.bulanSelesai,
        'tahunSelesai': int.tryParse(p.tahunSelesai),
        'masihBekerja': p.masihBekerja,
        'isGrafis': p.isGrafis,
      };
    }).toList();

    final prestasiList = _prestasi.where((p) => p.judul.trim().isNotEmpty).map((p) {
      if (p.id == null || p.id!.isEmpty) p.id = DateTime.now().millisecondsSinceEpoch.toString() + p.hashCode.toString();
      return {
        'id': p.id,
        'judul': p.judul,
        'tahun': int.tryParse(p.tahun),
        'buktiUrl': p.buktiUrl,
        'isGrafis': p.isGrafis,
      };
    }).toList();

    final tglLahirStr = _tanggalLahir.text.trim();
    if (tglLahirStr.isNotEmpty) {
      final tglLahirDate = DateTime.tryParse(tglLahirStr);
      if (tglLahirDate != null) {
        final birthYear = tglLahirDate.year;
        for (var p in _pekerjaan) {
          if (p.tahunMulai.isNotEmpty) {
            final startYear = int.tryParse(p.tahunMulai);
            if (startYear != null && startYear < birthYear) {
              _expandAndScroll(_pekerjaanAccordion, _pekerjaanKey);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Tahun mulai pekerjaan (${p.pekerjaan}) tidak valid (tidak dapat mendahului tahun lahir).')));
              return;
            }
          }
        }
        for (var p in _prestasi) {
          if (p.tahun.isNotEmpty) {
            final year = int.tryParse(p.tahun);
            if (year != null && year < birthYear) {
              _expandAndScroll(_prestasiAccordion, _prestasiKey);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Tahun pencapaian prestasi (${p.judul}) tidak valid (tidak dapat mendahului tahun lahir).')));
              return;
            }
          }
        }
      }
    }

    bool hasBuktiError = false;
    for (var p in _prestasi) {
      if (p.judul.isNotEmpty) {
        if ((p.buktiUrl == null || p.buktiUrl!.isEmpty) && (p.buktiFileName == null || p.buktiFileName!.isEmpty)) {
          setState(() {
            p.isBuktiError = true;
          });
          hasBuktiError = true;
        }
      }
    }
    if (hasBuktiError) {
      _expandAndScroll(_prestasiAccordion, _prestasiKey);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dokumen bukti prestasi wajib diunggah.')));
      return;
    }

    try {
      String? finalAvatarUrl = _avatarUrlState;
      if ((finalAvatarUrl == null || finalAvatarUrl.isEmpty) && _newAvatarBytes != null && _newAvatarFileName != null) {
        finalAvatarUrl = await ref.read(authProvider.notifier).uploadFile(_newAvatarBytes!, _newAvatarFileName!);
      }

      await ref.read(authProvider.notifier).updateProfile({
        'nama': _nama.text.trim(),
        'avatarUrl': finalAvatarUrl,
        'angkatan': int.tryParse(_angkatan),
        'tanggalLahir': _tanggalLahir.text.trim(),
        'jenisKelamin': _jenisKelamin,
        'motto': _motto.text.trim(),
        'email': _email.text.trim(),
        'hp': '${_hpPrefix.split('+').last.replaceAll(')', '')}${_hp.text.trim()}',
        'linkedin': _linkedin.text.trim().isEmpty ? '' : 'https://www.linkedin.com/in/${_linkedin.text.trim()}',
        'alamat': _alamat.text.trim(),
        'nomorIjazah': _nomorIjazah.text.trim(),
        'tahunLulus': int.tryParse(_tahunLulus),
        'ipk': _ipk.text.trim(),
        'ijazahFile': _ijazahFileName,
        'pekerjaan': pekerjaanList,
        'prestasi': prestasiList,
        'alumniGrafis': _alumniGrafisKategori != null && _alumniGrafisKategori != 'None' && _alumniGrafisKategori!.isNotEmpty && _alumniGrafisId != null && _alumniGrafisId!.isNotEmpty
            ? jsonEncode({
                'kategori': _alumniGrafisKategori,
                'id': _alumniGrafisId,
                // If previously rejected and user is re-submitting, omit status so backend resets to PENDING
              })
            : null,
        'emailVisibility': _emailVis,
        'nomorHandphoneVisibility': _hpVis,
        'alamatVisibility': _alamatVis,
      });

      if (!mounted) return;

      ref.invalidate(alumniProvider);
      ref.invalidate(beritaProvider);
      ref.invalidate(agendaProvider);
      ref.invalidate(lokerProvider);
      ref.invalidate(pemiluProvider);

      if (wasRejected) {
        // Cek apakah status sudah berubah ke PENDING setelah update
        final newStatus = ref.read(authProvider).user?.status;
        final backToPending = newStatus == AlumniStatus.pending;

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: backToPending
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    backToPending
                        ? Icons.hourglass_top_rounded
                        : Icons.check_circle_rounded,
                    size: 32,
                    color: backToPending
                        ? const Color(0xFF92400E)
                        : const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  backToPending
                      ? 'Profil Diperbarui — Menunggu Verifikasi'
                      : 'Profil Berhasil Diperbarui',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  backToPending
                      ? 'Data Anda telah tersimpan dan akun Anda kembali masuk ke antrian verifikasi admin. '
                        'Anda akan menerima notifikasi setelah admin meninjau data Anda.'
                      : 'Data profil Anda berhasil diperbarui. Pastikan semua data wajib (HP, Alamat, Nomor Ijazah) terisi agar akun Anda dapat diajukan ke verifikasi ulang.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF6B7280),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.go('/member/profile');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Oke, Mengerti',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile berhasil diperbarui')),
        );
        context.go('/member/profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getFriendlyMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Uint8List? _newAvatarBytes;
  String? _newAvatarFileName;

  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      String fileName = file.name;
      
      try {
        var bytes = file.bytes;
        if (bytes == null) return;

        if (bytes.length > 5 * 1024 * 1024 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto >5MB akan otomatis dikompresi di bawah 5MB saat disimpan.'),
              backgroundColor: AppColors.navy,
              duration: Duration(seconds: 3),
            ),
          );
        }

        final token = ref.read(authProvider).token;
        if (token == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Anda harus masuk/login terlebih dahulu.')),
            );
          }
          return;
        }

        if (!mounted) return;

        final result = await ImageCropDialog.show(
          context: context,
          imageBytes: bytes,
          fileName: fileName,
          aspectRatio: 1 / 1,
          uploadFn: (croppedBytes, name) async {
            return await ref.read(authProvider.notifier).uploadFile(croppedBytes, name);
          },
        );

        if (result != null && mounted) {
          setState(() {
            _newAvatarBytes = result.croppedBytes;
            _newAvatarFileName = fileName;
            _avatarUrlState = result.url;
          });
        }
      } catch (e) {
        if (mounted) {
          final msg = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _avatarUrlState = '';
      _newAvatarBytes = null;
      _newAvatarFileName = null;
    });
  }

  // Kompresi kilat menggunakan flutter_image_compress, fallback ke background isolate via compute()
  Future<Uint8List> _compressImage(Uint8List bytes, {bool isPng = false}) async {
    try {
      final targetFormat = isPng ? CompressFormat.png : CompressFormat.jpeg;
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1080,
        minHeight: 1080,
        quality: 75,
        format: targetFormat,
      );
      if (compressed.isNotEmpty && compressed.length < bytes.length) {
        return compressed;
      }
    } catch (_) {}
    return compute(_compressImageIsolate, bytes);
  }

  Future<void> _pickAndUploadIjazah() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        if (file.bytes!.length > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ukuran file maksimal 10MB'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }
        try {
          final url = await ref.read(authProvider.notifier).uploadFile(file.bytes!, file.name, type: 'document');
          setState(() {
            _ijazahFileName = url;
            _ijazahError = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ijazah berhasil diunggah!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mengunggah ijazah: $e'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _pickAndUploadPrestasiBukti(_PrestasiForm p) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        if (file.bytes!.length > 4 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ukuran file maksimal 4MB'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }
        try {
          final url = await ref.read(authProvider.notifier).uploadFile(file.bytes!, file.name, type: 'document');
          setState(() {
            p.buktiUrl = url;
            p.buktiFileName = file.name;
            p.isBuktiError = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bukti berhasil diunggah!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mengunggah bukti: $e'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      }
    }
  }

  bool get _isStrictMode => _pekerjaan.any((p) => p.pekerjaan.isNotEmpty || p.perusahaan.isNotEmpty) ||
                           _prestasi.any((p) => p.judul.isNotEmpty) ||
                           (_alumniGrafisKategori != null && _alumniGrafisKategori!.isNotEmpty && _alumniGrafisKategori != 'None');

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.user == null && next.user != null) {
        _populateData(next.user);
      }
    });

    final user = ref.watch(authProvider).user;
    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          const MemberAppBar(activeKey: ''),
          SectionWrapper(
            verticalPadding: 32,
            maxContentWidth: 1100,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb
                  const Text(
                    'PROFILE SAYA / EDIT PROFILE',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: AppColors.gray900,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(width: 40, height: 3, color: AppColors.accent),
                  const SizedBox(height: 32),

                  LayoutBuilder(builder: (context, c) {
                    final isMobile = c.maxWidth < AppBreakpoints.tablet;
                    return Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: isMobile ? double.infinity : 260,
                          child: _PhotoPanel(
                            user: user,
                            avatarUrl: _avatarUrlState,
                            newAvatarBytes: _newAvatarBytes,
                            onPickPhoto: _pickPhoto,
                            onRemovePhoto: _removePhoto,
                          ),
                        ),
                        SizedBox(width: isMobile ? 0 : 48, height: isMobile ? 24 : 0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AccordionSection(
                                key: _dataAlumniKey,
                                title: 'Data Alumni',
                                controller: _dataAlumniAccordion,
                                initiallyExpanded: true,
                                children: [
                              const _FieldLabel('Nama Lengkap', required: true),
                              TextFormField(
                                controller: _nama,
                                focusNode: _namaFocus,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel('Username'),
                              TextFormField(
                                controller: _username,
                                readOnly: true,
                                style: const TextStyle(color: Colors.black54),
                                decoration: InputDecoration(
                                  fillColor: Colors.grey.shade100,
                                  filled: true,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel('Angkatan', required: true),
                              SearchableDropdownField(
                                focusNode: _angkatanFocus,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Angkatan wajib diisi' : null,
                                items: (() {
                                  int minAngkatanYear = 1960;
                                  if (_tanggalLahir.text.isNotEmpty) {
                                    final tl = DateTime.tryParse(_tanggalLahir.text);
                                    if (tl != null && tl.year > minAngkatanYear) minAngkatanYear = tl.year;
                                  }
                                  final currentYear = DateTime.now().year;
                                  final tahun = [for (int i = currentYear; i >= minAngkatanYear; i--) i.toString()];
                                  if (_angkatan.isNotEmpty && !tahun.contains(_angkatan)) {
                                    tahun.add(_angkatan);
                                    tahun.sort((a, b) => b.compareTo(a));
                                  }
                                  return tahun;
                                })(),
                                initialValue: _angkatan,
                                hintText: 'Cari atau pilih angkatan...',
                                onChanged: (v) {
                                  setState(() {
                                    _angkatan = v ?? '';
                                    if (_tahunLulus.isNotEmpty && _angkatan.isNotEmpty) {
                                      final tl = int.tryParse(_tahunLulus);
                                      final a = int.tryParse(_angkatan);
                                      if (tl != null && a != null && tl < a) {
                                        _tahunLulus = _angkatan;
                                      }
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              _FieldLabel('Tanggal Lahir', required: _isStrictMode),
                              TextFormField(
                                controller: _tanggalLahir,
                                focusNode: _tanggalLahirFocus,
                                readOnly: true,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                onTap: () async {
                                  final now = DateTime.now();
                                  DateTime maxDate = now;
                                  if (_angkatan.isNotEmpty) {
                                    final angkatanYear = int.tryParse(_angkatan);
                                    if (angkatanYear != null) {
                                      final angkatanDate = DateTime(angkatanYear, 12, 31);
                                      if (angkatanDate.isBefore(maxDate)) {
                                        maxDate = angkatanDate;
                                      }
                                    }
                                  }
                                  
                                  final initial = _tanggalLahir.text.isNotEmpty 
                                      ? DateTime.tryParse(_tanggalLahir.text) ?? DateTime(now.year - 20, 1, 1)
                                      : DateTime(now.year - 20, 1, 1);
                                      
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: initial.isBefore(maxDate) ? initial : maxDate,
                                    firstDate: DateTime(1900),
                                    lastDate: maxDate,
                                  );
                                  if (picked != null) {
                                    final pad = (int n) => n.toString().padLeft(2, '0');
                                    _tanggalLahir.text = '${picked.year}-${pad(picked.month)}-${pad(picked.day)}';
                                    setState(() {});
                                  }
                                },
                                decoration: const InputDecoration(
                                  hintText: 'YYYY-MM-DD',
                                  suffixIcon: Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18),
                                ),
                                validator: (v) {
                                  if (_isStrictMode && (v == null || v.trim().isEmpty)) {
                                    return 'Wajib diisi untuk verifikasi profil alumni';
                                  }
                                  if (_angkatan.isNotEmpty) {
                                    final tl = DateTime.tryParse(v!);
                                    final ay = int.tryParse(_angkatan);
                                    if (tl != null && ay != null && tl.year > ay) {
                                      return 'Tanggal lahir tidak bisa lebih dari tahun angkatan';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel('Motto'),
                              TextFormField(
                                controller: _motto,
                                decoration: const InputDecoration(),
                              ),
                              const SizedBox(height: 16),
                              _FieldLabel('Jenis Kelamin', required: _isStrictMode),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RadioOption(
                                      label: 'Laki-laki',
                                      selected: _jenisKelamin == 'Laki-laki',
                                      onTap: () => setState(
                                          () => _jenisKelamin = 'Laki-laki'),
                                    ),
                                  ),
                                  Expanded(
                                    child: _RadioOption(
                                      label: 'Perempuan',
                                      selected: _jenisKelamin == 'Perempuan',
                                      onTap: () => setState(
                                          () => _jenisKelamin = 'Perempuan'),
                                    ),
                                  ),
                                ],
                              ),
                                ],
                              ),
                              _AccordionSection(
                                key: _kontakKey,
                                title: 'Kontak',
                                controller: _kontakAccordion,
                                children: [
                              const _FieldLabel('Email'),
                              TextFormField(
                                controller: _email,
                                readOnly: true,
                                style: const TextStyle(color: AppColors.gray600),
                                decoration: const InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.gray50,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _VisibilityRow(
                                label: 'Visibilitas Email',
                                value: _emailVis,
                                onChange: (v) => setState(() => _emailVis = v),
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel('Nomor Handphone', required: true),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: SearchableDropdownField(
                                      items: searchableCountryCodes,
                                      initialValue: searchableCountryCodes.contains(_hpPrefix) ? _hpPrefix : '🇮🇩 +62',
                                      hintText: 'Cari...',
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _hpPrefix = v);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _hp,
                                      focusNode: _hpFocus,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        hintText: '812...',
                                      ),
                                      validator: (v) {
                                        final s = v?.trim() ?? '';
                                        if (s.isEmpty) return 'Nomor handphone wajib diisi';
                                        if (_hpPrefix.contains('+62') && s.startsWith('0')) return 'Jangan sertakan angka 0 di awal';
                                        if (s.length < 6 || s.length > 15) return 'Nomor handphone tidak valid';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _VisibilityRow(
                                label: 'Visibilitas Nomor Handphone',
                                value: _hpVis,
                                onChange: (v) => setState(() => _hpVis = v),
                              ),
                              const SizedBox(height: 16),
                              _FieldLabel('LinkedIn', required: _isStrictMode),
                              TextFormField(
                                controller: _linkedin,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(left: 14, right: 4),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'https://linkedin.com/in/',
                                          style: TextStyle(
                                            color: AppColors.gray500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                                  hintText: 'username',
                                ),
                                validator: (v) {
                                  if (_isStrictMode && (v == null || v.trim().isEmpty)) {
                                    return 'Wajib diisi untuk verifikasi profil alumni';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              _FieldLabel('Alamat', required: _isStrictMode),
                              TextFormField(
                                controller: _alamat,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(),
                                maxLength: 300,
                                validator: (v) {
                                  if (_isStrictMode && (v == null || v.trim().isEmpty)) {
                                    return 'Wajib diisi untuk verifikasi profil alumni';
                                  }
                                  if ((v ?? '').trim().length > 300) {
                                    return 'Alamat maksimal 300 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 6),
                              _VisibilityRow(
                                label: 'Visibilitas Alamat',
                                value: _alamatVis,
                                onChange: (v) =>
                                    setState(() => _alamatVis = v),
                              ),
                                ],
                              ),
                              _AccordionSection(
                                key: _ijazahKey,
                                title: 'Ijazah / PDDIKTI / Surat Keterangan Jurusan',
                                controller: _ijazahAccordion,
                                children: [
                              _FieldLabel('Nomor Ijazah / PDDIKTI / Surat Keterangan Jurusan', required: _isStrictMode),
                              TextFormField(
                                controller: _nomorIjazah,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(
                                  hintText: 'IJ-2018-001234',
                                ),
                                validator: (val) {
                                  if (_isStrictMode && (val == null || val.trim().isEmpty)) {
                                    return 'Wajib diisi untuk verifikasi profil alumni';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _FieldLabel('Tahun Lulus', required: _isStrictMode),
                              DropdownButtonFormField<String>(
                                initialValue: _tahunLulus,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                items: (() {
                                  final currentYear = DateTime.now().year;
                                  int startYear = int.tryParse(_angkatan) ?? (currentYear - 30);
                                  int endYear = currentYear;
                                  
                                  final list = <String>[];
                                  for (int y = endYear; y >= startYear; y--) {
                                    list.add(y.toString());
                                  }
                                  if (!list.contains(_tahunLulus) && _tahunLulus.isNotEmpty) {
                                      list.add(_tahunLulus);
                                      list.sort((a, b) => b.compareTo(a));
                                  }
                                  return list.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList();
                                })(),
                                onChanged: (v) => setState(
                                    () => _tahunLulus = v ?? _tahunLulus),
                                validator: (val) {
                                  if (_isStrictMode && (val == null || val.trim().isEmpty)) {
                                    return 'Wajib diisi untuk verifikasi profil alumni';
                                  }
                                  if (val != null && val.isNotEmpty && _angkatan.isNotEmpty) {
                                    final tl = int.tryParse(val);
                                    final a = int.tryParse(_angkatan);
                                    if (tl != null && a != null && tl < a) {
                                      return 'Tahun lulus tidak bisa lebih kecil dari angkatan';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _FieldLabel('IPK', required: _isStrictMode),
                              TextFormField(
                                controller: _ipk,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  TextInputFormatter.withFunction((oldValue, newValue) {
                                    if (newValue.text.isEmpty) return newValue;
                                    if (newValue.text == '.') return newValue;
                                    final number = double.tryParse(newValue.text);
                                    if (number != null && number > 4.00) return oldValue;
                                    return newValue;
                                  }),
                                ],
                                validator: (val) {
                                  if (_isStrictMode && (val == null || val.trim().isEmpty)) {
                                    return 'Wajib diisi untuk verifikasi profil alumni';
                                  }
                                  if (val != null && val.isNotEmpty) {
                                    final number = double.tryParse(val);
                                    if (number != null && number > 4.00) {
                                      return 'IPK maksimal adalah 4.00';
                                    }
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  hintText: '3.75',
                                  suffixText: '/ 4.00',
                                ),
                              ),
                              const SizedBox(height: 16),
                              _FieldLabel('Upload Ijazah / PDDIKTI / Surat Keterangan Jurusan (PDF/Image)', required: _isStrictMode),
                              _DocumentUploader(
                                fileName: _ijazahFileName != null ? formatFileName(_ijazahFileName) : null,
                                emptyText: 'Belum ada ijazah/pddikti/surat keterangan jurusan',
                                helperText: 'Format PDF/Image, maksimal 10 MB',
                                hasError: _ijazahError,
                                onPick: _pickAndUploadIjazah,
                                onRemove: _ijazahFileName == null
                                    ? null
                                    : () => setState(() {
                                          _ijazahFileName = null;
                                          _ijazahError = false;
                                        }),
                              ),
                                ],
                              ),
                              _AccordionSection(
                                key: _pekerjaanKey,
                                title: 'Pekerjaan',
                                controller: _pekerjaanAccordion,
                                children: [
                              ..._pekerjaan.asMap().entries.map((entry) {
                                final i = entry.key;
                                final p = entry.value;
                                int? birthYear;
                                if (_tanggalLahir.text.isNotEmpty) {
                                  birthYear = DateTime.tryParse(_tanggalLahir.text)?.year;
                                }
                                final isLocked = p.isGrafis ||
                                    (_alumniGrafisId == p.id &&
                                        (_alumniGrafisKategori == 'Jabatan strategis/Public Figure' ||
                                            _alumniGrafisKategori == 'Public Figure'));
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _PekerjaanCard(
                                    data: p,
                                    birthYear: birthYear,
                                    isLocked: isLocked,
                                    onUpdate: (patch) =>
                                        setState(() => patch(p)),
                                    onRemove: () => setState(
                                            () => _pekerjaan.removeAt(i)),
                                  ),
                                );
                              }),
                              OutlinedButton(
                                onPressed: () => setState(
                                    () => _pekerjaan.add(_PekerjaanForm())),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: const Text('Tambah Pekerjaan'),
                              ),
                                ],
                              ),
                              _AccordionSection(
                                key: _prestasiKey,
                                title: 'Prestasi',
                                controller: _prestasiAccordion,
                                children: [
                              ..._prestasi.asMap().entries.map((entry) {
                                final i = entry.key;
                                final p = entry.value;
                                int? birthYear;
                                if (_tanggalLahir.text.isNotEmpty) {
                                  birthYear = DateTime.tryParse(_tanggalLahir.text)?.year;
                                }
                                final isLocked = p.isGrafis ||
                                    (_alumniGrafisId == p.id &&
                                        _alumniGrafisKategori == 'Prestasi');
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _PrestasiCard(
                                    data: p,
                                    birthYear: birthYear,
                                    isLocked: isLocked,
                                    onUpdate: (patch) =>
                                        setState(() => patch(p)),
                                    onRemove: () => setState(
                                            () => _prestasi.removeAt(i)),
                                    onPickBukti: () => _pickAndUploadPrestasiBukti(p),
                                    onRemoveBukti: (p.buktiUrl != null || p.buktiFileName != null || p.buktiBytes != null)
                                        ? () => setState(() {
                                              p.buktiUrl = null;
                                              p.buktiFileName = null;
                                              p.buktiBytes = null;
                                            })
                                        : null,
                                  ),
                                );
                              }),
                              OutlinedButton(
                                onPressed: () => setState(
                                    () => _prestasi.add(_PrestasiForm())),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: const Text('Tambah Prestasi'),
                              ),
                                ],
                              ),
                              if (user?.status == AlumniStatus.approved || user?.status == AlumniStatus.active)
                                _AccordionSection(
                                  title: 'Alumni Grafis',
                                  children: [
                                const _FieldLabel('Apakah Anda memiliki prestasi di tingkat nasional atau lebih tinggi, menduduki jabatan minimal manajer, atau berstatus sebagai tokoh publik?'),
                              DropdownButtonFormField<String>(
                                value: _alumniGrafisKategori,
                                hint: const Text('Pilih Kategori'),
                                items: const [
                                  DropdownMenuItem(value: 'Jabatan strategis/Public Figure', child: Text('Jabatan strategis/Public Figure')),
                                  DropdownMenuItem(value: 'Prestasi', child: Text('Berprestasi')),
                                  DropdownMenuItem(value: 'None', child: Text('None')),
                                ],
                                onChanged: _alumniGrafisStatus == 'APPROVED' ? null : (v) {
                                  setState(() {
                                    _alumniGrafisKategori = v;
                                    _alumniGrafisId = null;
                                  });
                                },
                              ),
                              if (_alumniGrafisKategori == 'Jabatan strategis/Public Figure') ...[
                                const SizedBox(height: 16),
                                const _FieldLabel('Pilih Pekerjaan'),
                                DropdownButtonFormField<String>(
                                  value: _pekerjaan.any((p) => p.id == _alumniGrafisId && (p.pekerjaan.trim().isNotEmpty || p.perusahaan.trim().isNotEmpty)) 
                                      ? _alumniGrafisId 
                                      : null,
                                  hint: const Text('Pilih Pekerjaan'),
                                  isExpanded: true,
                                  items: _pekerjaan.where((p) => p.pekerjaan.trim().isNotEmpty || p.perusahaan.trim().isNotEmpty).map((p) {
                                    return DropdownMenuItem(
                                      value: p.id,
                                      child: Text('${p.pekerjaan}${p.perusahaan.isNotEmpty ? ' di ${p.perusahaan}' : ''}'),
                                    );
                                  }).toList(),
                                  onChanged: _alumniGrafisStatus == 'APPROVED' ? null : (v) => setState(() => _alumniGrafisId = v),
                                ),
                              ],
                              if (_alumniGrafisKategori == 'Prestasi') ...[
                                const SizedBox(height: 16),
                                const _FieldLabel('Pilih Prestasi'),
                                DropdownButtonFormField<String>(
                                  value: _prestasi.any((p) => p.id == _alumniGrafisId && p.judul.trim().isNotEmpty) 
                                      ? _alumniGrafisId 
                                      : null,
                                  hint: const Text('Pilih Prestasi'),
                                  isExpanded: true,
                                  items: _prestasi.where((p) => p.judul.trim().isNotEmpty).map((p) {
                                    return DropdownMenuItem(
                                      value: p.id,
                                      child: Text('${p.judul}${p.tahun.isNotEmpty ? ' (${p.tahun})' : ''}'),
                                    );
                                  }).toList(),
                                  onChanged: _alumniGrafisStatus == 'APPROVED' ? null : (v) => setState(() => _alumniGrafisId = v),
                                ),
                              ],
                                ],
                              ),
                              const SizedBox(height: 32),

                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _onSubmit,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 16),
                                  ),
                                  child: const Text('Simpan Perubahan'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _PhotoPanel extends StatelessWidget {
  final AlumniProfile? user;
  final String? avatarUrl;
  final Uint8List? newAvatarBytes;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  const _PhotoPanel({
    required this.user,
    required this.avatarUrl,
    required this.newAvatarBytes,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (avatarUrl != null && avatarUrl!.isNotEmpty) || newAvatarBytes != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            width: double.infinity,
            height: 280,
            child: hasPhoto
                ? (newAvatarBytes != null
                    ? Image.memory(
                        newAvatarBytes!,
                        fit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        key: ValueKey(avatarUrl),
                        imageUrl: avatarUrl!.startsWith('/')
                            ? '${AuthController.serverHost}$avatarUrl'
                            : avatarUrl!.startsWith('http')
                                ? avatarUrl!
                                : 'https://i.pravatar.cc/150?u=${user?.id}',
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const ShimmerPlaceholder(),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.gray200),
                      ))
                : Container(
                    color: AppColors.gray200,
                    child: const Center(
                      child: Icon(Icons.person, size: 64,
                          color: AppColors.gray400),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Maks. 5MB (Rekomendasi dimensi 1080 x 1080 px)',
          style: TextStyle(fontSize: 11, color: AppColors.gray500),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPickPhoto,
            child: const Text('Ganti Photo'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: onRemovePhoto,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: const Text(
              'Hapus Photo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccordionSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final ExpansionTileController? controller;

  const _AccordionSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ExpansionTile(
          controller: controller,
          tilePadding: EdgeInsets.zero,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Container(width: 32, height: 3, color: AppColors.accent),
            ],
          ),
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          childrenPadding: const EdgeInsets.only(top: 8, bottom: 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: const Border(),
          children: children,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.gray800,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.gray300,
                  width: 2,
                ),
              ),
              child: Center(
                child: selected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.gray800)),
          ],
        ),
      ),
    );
  }
}

class _VisibilityRow extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChange;
  const _VisibilityRow({
    required this.label,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final isPublic = value == 'public';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.gray800,
          ),
        ),
        Row(
          children: [
            Text(
              isPublic ? 'Publik' : 'Privat',
              style: TextStyle(
                fontSize: 13,
                color: isPublic ? AppColors.primary : AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isPublic,
              onChanged: (bool isActive) {
                onChange(isActive ? 'public' : 'private');
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}

class _PekerjaanCard extends StatelessWidget {
  final _PekerjaanForm data;
  final int? birthYear;
  final bool isLocked;
  final void Function(void Function(_PekerjaanForm)) onUpdate;
  final VoidCallback onRemove;

  const _PekerjaanCard({
    required this.data,
    this.birthYear,
    this.isLocked = false,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final currentYear = DateTime.now().year;
    final currentMonthIndex = DateTime.now().month - 1;
    var years = List.generate(60, (i) => (currentYear - i).toString());
    if (birthYear != null) {
      years = years.where((y) => int.parse(y) >= birthYear!).toList();
    }
    final yearsSelesai = data.tahunMulai.isEmpty 
        ? years 
        : years.where((y) => int.parse(y) >= int.parse(data.tahunMulai)).toList();
        
    List<String> getAvailableMonths(String yearStr) {
      if (yearStr == currentYear.toString()) {
        return months.sublist(0, currentMonthIndex + 1);
      }
      return months;
    }
    
    List<String> getAvailableMonthsSelesai() {
      List<String> available = months;
      if (data.tahunSelesai == data.tahunMulai && data.bulanMulai.isNotEmpty) {
        final startIdx = months.indexOf(data.bulanMulai);
        if (startIdx != -1) {
          available = available.sublist(startIdx);
        }
      }
      if (data.tahunSelesai == currentYear.toString()) {
        available = available.where((m) => months.indexOf(m) <= currentMonthIndex).toList();
      }
      return available;
    }
    
    final monthsMulai = getAvailableMonths(data.tahunMulai);
    final monthsSelesai = getAvailableMonthsSelesai();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Pekerjaan'),
          TextFormField(
            initialValue: data.pekerjaan,
            enabled: !isLocked,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (v) => onUpdate((d) => d.pekerjaan = v),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Nama pekerjaan wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Perusahaan'),
          TextFormField(
            initialValue: data.perusahaan,
            enabled: !isLocked,
            onChanged: (v) => onUpdate((d) => d.perusahaan = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Dari'),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value:
                                (data.bulanMulai.isNotEmpty && monthsMulai.contains(data.bulanMulai)) 
                                    ? data.bulanMulai 
                                    : null,
                            hint: const Text('Bulan'),
                            items: monthsMulai
                                .map((m) => DropdownMenuItem(
                                    value: m, child: Text(m)))
                                .toList(),
                            onChanged: isLocked
                                ? null
                                : (v) => onUpdate((d) {
                              d.bulanMulai = v ?? '';
                              if (d.tahunSelesai == d.tahunMulai && d.bulanMulai.isNotEmpty && d.bulanSelesai.isNotEmpty) {
                                final startIdx = months.indexOf(d.bulanMulai);
                                final endIdx = months.indexOf(d.bulanSelesai);
                                if (endIdx < startIdx) {
                                  d.bulanSelesai = '';
                                }
                              }
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SearchableDropdownField(
                            initialValue:
                                data.tahunMulai.isEmpty ? null : data.tahunMulai,
                            hintText: 'Tahun',
                            items: years,
                            enabled: !isLocked,
                            onChanged: isLocked
                                ? null
                                : (v) => onUpdate((d) {
                              d.tahunMulai = v ?? '';
                              if (d.tahunSelesai.isNotEmpty && d.tahunMulai.isNotEmpty && int.parse(d.tahunSelesai) < int.parse(d.tahunMulai)) {
                                d.tahunSelesai = '';
                              }
                              if (d.tahunMulai == currentYear.toString()) {
                                final availMonths = getAvailableMonths(d.tahunMulai);
                                if (d.bulanMulai.isNotEmpty && !availMonths.contains(d.bulanMulai)) {
                                  d.bulanMulai = '';
                                }
                              }
                              // Reset bulanSelesai if it becomes invalid (e.g. before bulanMulai)
                              if (d.tahunSelesai == d.tahunMulai && d.bulanMulai.isNotEmpty && d.bulanSelesai.isNotEmpty) {
                                final startIdx = months.indexOf(d.bulanMulai);
                                final endIdx = months.indexOf(d.bulanSelesai);
                                if (endIdx < startIdx) {
                                  d.bulanSelesai = '';
                                }
                              }
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Sampai'),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: (data.bulanSelesai.isNotEmpty && monthsSelesai.contains(data.bulanSelesai))
                                ? data.bulanSelesai
                                : null,
                            hint: const Text('Bulan'),
                            items: monthsSelesai
                                .map((m) => DropdownMenuItem(
                                    value: m, child: Text(m)))
                                .toList(),
                            onChanged: (isLocked || data.masihBekerja)
                                ? null
                                : (v) => onUpdate(
                                    (d) => d.bulanSelesai = v ?? ''),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SearchableDropdownField(
                            initialValue: data.tahunSelesai.isEmpty
                                ? null
                                : data.tahunSelesai,
                            hintText: 'Tahun',
                            items: yearsSelesai,
                            enabled: !isLocked && !data.masihBekerja,
                            onChanged: (isLocked || data.masihBekerja)
                                ? null
                                : (v) => onUpdate((d) {
                                      d.tahunSelesai = v ?? '';
                                      if (d.tahunSelesai == currentYear.toString()) {
                                        if (d.bulanSelesai.isNotEmpty && months.indexOf(d.bulanSelesai) > currentMonthIndex) {
                                          d.bulanSelesai = '';
                                        }
                                      }
                                      if (d.tahunSelesai == d.tahunMulai && d.bulanMulai.isNotEmpty && d.bulanSelesai.isNotEmpty) {
                                        if (months.indexOf(d.bulanSelesai) < months.indexOf(d.bulanMulai)) {
                                          d.bulanSelesai = '';
                                        }
                                      }
                                    }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: data.masihBekerja,
                onChanged: isLocked
                    ? null
                    : (v) =>
                        onUpdate((d) => d.masihBekerja = v ?? false),
              ),
              const Text(
                'Saya masih bekerja pada perusahaan ini',
                style: TextStyle(
                  color: AppColors.gray700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLocked)
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Terkunci (Tidak bisa diedit karena sudah dimasukkan ke Alumni Grafis)',
                  style: TextStyle(color: AppColors.gray500, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onRemove,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: const Text(
                  'Hapus',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrestasiCard extends StatelessWidget {
  final _PrestasiForm data;
  final int? birthYear;
  final bool isLocked;
  final void Function(void Function(_PrestasiForm)) onUpdate;
  final VoidCallback? onRemove;
  final VoidCallback onPickBukti;
  final VoidCallback? onRemoveBukti;
  const _PrestasiCard({
    required this.data,
    this.birthYear,
    this.isLocked = false,
    required this.onUpdate,
    this.onRemove,
    required this.onPickBukti,
    this.onRemoveBukti,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    var years = List.generate(60, (i) => (currentYear - i).toString());
    if (birthYear != null) {
      years = years.where((y) => int.parse(y) >= birthYear!).toList();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Judul Prestasi'),
          TextFormField(
            initialValue: data.judul,
            enabled: !isLocked,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (v) => onUpdate((d) => d.judul = v),
            validator: (v) {
              if (data.tahun.isNotEmpty && (v == null || v.trim().isEmpty)) {
                return 'Judul wajib diisi jika tahun diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Tahun'),
          SearchableDropdownField(
            initialValue: data.tahun.isEmpty ? null : data.tahun,
            hintText: '2025',
            items: years,
            enabled: !isLocked,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (data.judul.isNotEmpty && (v == null || v.trim().isEmpty)) {
                return 'Tahun wajib diisi jika judul diisi';
              }
              return null;
            },
            onChanged: isLocked ? null : (v) => onUpdate((d) => d.tahun = v ?? ''),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Upload Bukti Prestasi (Wajib)'),
          _DocumentUploader(
            fileName: data.buktiUrl != null ? formatFileName(data.buktiUrl) : data.buktiFileName,
            emptyText: 'Belum ada file bukti',
            helperText: 'Format PDF/Image, maksimal 4 MB',
            hasError: data.isBuktiError,
            enabled: !isLocked,
            onPick: onPickBukti,
            onRemove: onRemoveBukti,
          ),
          const SizedBox(height: 12),
          if (isLocked)
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Terkunci (Tidak bisa diedit karena sudah dimasukkan ke Alumni Grafis)',
                  style: TextStyle(color: AppColors.gray500, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onRemove,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: const Text(
                  'Hapus',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentUploader extends StatelessWidget {
  final String? fileName;
  final String emptyText;
  final String helperText;
  final bool hasError;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final bool enabled;
  const _DocumentUploader({
    required this.fileName,
    required this.onPick,
    this.emptyText = 'Belum ada file',
    this.helperText = 'Format PDF/Image, maksimal 10 MB',
    this.hasError = false,
    this.enabled = true,
    this.onRemove,
  });

  bool get _hasFile => fileName != null && fileName!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasError ? AppColors.danger.withOpacity(0.05) : AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: hasError ? AppColors.danger : AppColors.gray200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasFile ? fileName! : emptyText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _hasFile
                        ? AppColors.gray900
                        : AppColors.gray500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  helperText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray500,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Dokumen ijazah wajib diunggah',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (enabled && _hasFile && onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.danger,
              tooltip: 'Hapus file',
            ),
          OutlinedButton.icon(
            onPressed: enabled ? onPick : null,
            icon: const Icon(Icons.upload_file, size: 16),
            label: Text(!_hasFile ? 'Pilih File' : 'Ganti File'),
          ),
        ],
      ),
    );
  }
}
