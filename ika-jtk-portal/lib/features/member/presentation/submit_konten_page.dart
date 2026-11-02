import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import 'widgets/member_app_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../berita/providers/berita_provider.dart';
import '../../agenda/providers/agenda_provider.dart';
import '../../../core/indonesia_cities.dart';
import '../../loker/providers/loker_provider.dart';
import 'dart:typed_data';
import '../../../shared/widgets/image_crop_dialog.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

enum _KontenTipe { berita, agenda, loker }

enum _SkemaPelamaran { internal, external }

enum _InputTipe { teks, number, option, file }

/// Top-level function agar bisa dijalankan di background Isolate / Web Worker via compute()
Uint8List _compressImageIsolate(Uint8List bytes) {
  // Safety margin di bawah server limit (5MB) supaya multipart overhead tidak
  // mendekati batas proxy.
  const maxSize = 2 * 1024 * 1024; // Ubah ke 2MB

  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('Gagal membaca gambar');

  // Fast bypass: jika sudah kecil & resolusi di bawah batas, langsung kembalikan JPEG
  final jpgStep1 = img.encodeJpg(decoded, quality: 80);
  if (jpgStep1.length <= maxSize &&
      decoded.width <= 1080 &&
      decoded.height <= 1080) {
    return Uint8List.fromList(jpgStep1);
  }

  // Resize & scale down proportionally
  int newW = decoded.width;
  int newH = decoded.height;
  if (newW > 1080 || newH > 1080) {
    if (newW > newH) {
      newH = (newH * (1080 / newW)).round();
      newW = 1080;
    } else {
      newW = (newW * (1080 / newH)).round();
      newH = 1080;
    }
  }

  final resized = img.copyResize(
    decoded,
    width: newW,
    height: newH,
    interpolation: img.Interpolation.linear,
  );

  // Progressive compression: turunkan quality 5% tiap loop (minimal 35%)
  int quality = 95;
  List<int> resultBytes = img.encodeJpg(resized, quality: quality);

  while (resultBytes.length > maxSize && quality > 35) {
    quality -= 5;
    resultBytes = img.encodeJpg(resized, quality: quality);
  }

  return Uint8List.fromList(resultBytes);
}

class _FormFieldInput {
  String label;
  _InputTipe tipe;
  List<String> options;
  _FormFieldInput({
    this.label = '',
    this.tipe = _InputTipe.teks,
    this.options = const ['', ''],
  });
}

class SubmitKontenPage extends ConsumerStatefulWidget {
  const SubmitKontenPage({super.key});

  @override
  ConsumerState<SubmitKontenPage> createState() => _SubmitKontenPageState();
}

class _SubmitKontenPageState extends ConsumerState<SubmitKontenPage> {
  _KontenTipe _tipe = _KontenTipe.berita;
  bool _submitted = false;
  bool _isLoading = false;

  // Form Validation State
  final Set<String> _errorFields = {};
  
  // Validation Keys (Berita)
  final _keyJudulBerita = GlobalKey();
  final _keyKontenBerita = GlobalKey();
  final _keyBannerBerita = GlobalKey();
  
  // Validation Keys (Agenda)
  final _keyJudulAgenda = GlobalKey();
  final _keyDeskripsiAgenda = GlobalKey();
  final _keyTglWaktuAgenda = GlobalKey();
  final _keyLokasiAgenda = GlobalKey();
  
  // Validation Keys (Loker)
  final _keyPosisiLoker = GlobalKey();
  final _keyPerusahaanLoker = GlobalKey();
  final _keyDeskripsiLoker = GlobalKey();
  final _keyKotaLoker = GlobalKey();
  final _keyLinkEksternal = GlobalKey();

  // Shared
  final _judul = TextEditingController();
  final _tags = TextEditingController();
  final _bannerFileName = ValueNotifier<String>('');
  final _bannerBytes = ValueNotifier<List<int>?>(null);
  final _bannerUrl = ValueNotifier<String>('');
  final _bannerThumbnailUrl = ValueNotifier<String>('');

  // Berita
  final _isiBerita = TextEditingController();
  String _kategoriBerita = 'Pengumuman';

  // Agenda
  final _deskripsiAgenda = TextEditingController();
  final _tanggalWaktu = TextEditingController();
  final _lokasiAlamat = TextEditingController();

  // Loker
  final _posisi = TextEditingController();
  final _namaPerusahaan = TextEditingController();
  final _websitePerusahaan = TextEditingController();
  final _logoFileName = ValueNotifier<String>('');
  final _logoBytes = ValueNotifier<List<int>?>(null);
  final _logoUrl = ValueNotifier<String>('');
  final _logoThumbnailUrl = ValueNotifier<String>('');
  String _jenisPekerjaan = 'Full Time';
  String _lokasi = 'Onsite';
  String _kota = '';
  final _deskripsiPekerjaan = TextEditingController();
  _SkemaPelamaran _skema = _SkemaPelamaran.internal;
  final _linkEksternal = TextEditingController();
  final List<_FormFieldInput> _formLamaran = [
    _FormFieldInput(label: 'Ekspetasi Gaji'),
    _FormFieldInput(label: 'Pengalaman (Tahun)', tipe: _InputTipe.number),
    _FormFieldInput(
      label: 'Bersedia untuk kerja on-site',
      tipe: _InputTipe.option,
      options: ['Ya', 'Tidak'],
    ),
  ];

  @override
  void dispose() {
    _judul.dispose();
    _tags.dispose();
    _isiBerita.dispose();
    _deskripsiAgenda.dispose();
    _tanggalWaktu.dispose();
    _lokasiAlamat.dispose();
    _posisi.dispose();
    _namaPerusahaan.dispose();
    _websitePerusahaan.dispose();
    _deskripsiPekerjaan.dispose();
    _linkEksternal.dispose();
    super.dispose();
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

  Future<void> _pickBanner() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.first;
      String fileName = pickedFile.name;

      final bytes = pickedFile.bytes;
      if (bytes == null) return;
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran file maksimal 5MB'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      final auth = ref.read(authProvider);
      final token = auth.token;
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anda harus login terlebih dahulu')),
          );
        }
        return;
      }

      final cropRes = await ImageCropDialog.show(
        context: context,
        imageBytes: bytes,
        fileName: fileName,
        aspectRatio: 16 / 9,
        uploadFn: (croppedBytes, name) async {
          if (_tipe == _KontenTipe.agenda) {
            return await ref
                .read(agendaProvider.notifier)
                .uploadBanner(croppedBytes, name, token);
          }
          return await ref
              .read(beritaProvider.notifier)
              .uploadBanner(croppedBytes, name, token);
        },
      );

      if (cropRes != null) {
        _bannerFileName.value = fileName;
        _bannerBytes.value = cropRes.croppedBytes;
        _bannerUrl.value = cropRes.url;
        _bannerThumbnailUrl.value = cropRes.thumbnailUrl;
      }
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.first;
      String fileName = pickedFile.name;

      final bytes = pickedFile.bytes;
      if (bytes == null) return;
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran file maksimal 5MB'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      final cropRes = await ImageCropDialog.show(
        context: context,
        imageBytes: bytes,
        fileName: fileName,
        aspectRatio: 1 / 1,
        uploadFn: (croppedBytes, name) async {
          return await ref
              .read(lokerProvider.notifier)
              .uploadFile(croppedBytes, name);
        },
      );

      if (cropRes != null) {
        _logoFileName.value = fileName;
        _logoBytes.value = cropRes.croppedBytes;
        _logoUrl.value = cropRes.url;
        _logoThumbnailUrl.value = cropRes.thumbnailUrl;
      }
    }
  }

  Future<void> _submit() async {
    if (_tipe == _KontenTipe.berita) {
      final auth = ref.read(authProvider);
      final token = auth.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda harus login terlebih dahulu')),
        );
        return;
      }

      final judul = _judul.text.trim();
      final konten = _isiBerita.text.trim();

      List<String> emptyFields = [];
      GlobalKey? firstErrorKey;
      
      void addError(String field, GlobalKey key) {
        emptyFields.add(field);
        _errorFields.add(field);
        firstErrorKey ??= key;
      }

      _errorFields.clear();

      if (judul.isEmpty) addError('Judul Berita', _keyJudulBerita);
      if (konten.isEmpty) addError('Konten Berita', _keyKontenBerita);
      if (_bannerUrl.value.isEmpty && _bannerBytes.value == null) addError('Banner', _keyBannerBerita);

      if (emptyFields.isNotEmpty) {
        setState(() {}); // Trigger UI to show red borders
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harap lengkapi: ${emptyFields.join(', ')}'),
            backgroundColor: AppColors.danger,
          ),
        );
        if (firstErrorKey != null && firstErrorKey!.currentContext != null) {
          Scrollable.ensureVisible(
            firstErrorKey!.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return;
      }

      setState(() => _isLoading = true);

      String bannerUrl = _bannerUrl.value;
      String thumbUrl = _bannerThumbnailUrl.value;
      if (bannerUrl.isEmpty && _bannerBytes.value != null) {
        final uploaded = await ref
            .read(beritaProvider.notifier)
            .uploadBanner(_bannerBytes.value!, _bannerFileName.value, token);
        if (uploaded != null) {
          bannerUrl = uploaded['url'] ?? '';
          thumbUrl = uploaded['thumbnailUrl'] ?? '';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengunggah banner')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final success = await ref
          .read(beritaProvider.notifier)
          .submitBerita(
            judul,
            konten,
            bannerUrl,
            _kategoriBerita,
            token,
            tags: _tags.text.trim(),
            thumbnailUrl: thumbUrl,
          );

      setState(() => _isLoading = false);

      if (success) {
        setState(() => _submitted = true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengirim berita')));
      }
    } else if (_tipe == _KontenTipe.agenda) {
      final auth = ref.read(authProvider);
      final token = auth.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda harus login terlebih dahulu')),
        );
        return;
      }

      final judul = _judul.text.trim();
      final deskripsi = _deskripsiAgenda.text.trim();
      final tglWaktu = _tanggalWaktu.text.trim(); // "28/01/2025, 19:00"
      final lokasi = _lokasiAlamat.text.trim();

      List<String> emptyFields = [];
      GlobalKey? firstErrorKey;
      
      void addError(String field, GlobalKey key) {
        emptyFields.add(field);
        _errorFields.add(field);
        firstErrorKey ??= key;
      }

      _errorFields.clear();

      if (judul.isEmpty) addError('Judul Agenda', _keyJudulAgenda);
      if (deskripsi.isEmpty) addError('Deskripsi', _keyDeskripsiAgenda);
      if (tglWaktu.isEmpty) addError('Tanggal & Waktu', _keyTglWaktuAgenda);
      if (lokasi.isEmpty) addError('Lokasi', _keyLokasiAgenda);

      if (emptyFields.isNotEmpty) {
        setState(() {}); // Trigger UI to show red borders
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harap lengkapi: ${emptyFields.join(', ')}'),
            backgroundColor: AppColors.danger,
          ),
        );
        if (firstErrorKey != null && firstErrorKey!.currentContext != null) {
          Scrollable.ensureVisible(
            firstErrorKey!.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return;
      }

      setState(() => _isLoading = true);

      // Parse tanggalWaktu
      String tanggalEvent = '';
      String waktu = '';
      if (tglWaktu.contains(',')) {
        final parts = tglWaktu.split(',');
        final tgl = parts[0].trim();
        waktu = parts.length > 1 ? parts[1].trim() : '';

        // Convert DD/MM/YYYY to YYYY-MM-DD
        final tParts = tgl.split('/');
        if (tParts.length == 3) {
          tanggalEvent = '${tParts[2]}-${tParts[1]}-${tParts[0]}';
        } else {
          tanggalEvent = tgl;
        }
      } else {
        tanggalEvent = tglWaktu;
      }

      String bannerUrl = _bannerUrl.value;
      String thumbUrl = _bannerThumbnailUrl.value;
      if (bannerUrl.isEmpty && _bannerBytes.value != null) {
        final uploaded = await ref
            .read(agendaProvider.notifier)
            .uploadBanner(_bannerBytes.value!, _bannerFileName.value, token);
        if (uploaded != null) {
          bannerUrl = uploaded['url'] ?? '';
          thumbUrl = uploaded['thumbnailUrl'] ?? '';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengunggah banner')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final success = await ref
          .read(agendaProvider.notifier)
          .submitAgenda(
            judul: judul,
            deskripsi: deskripsi,
            tanggalEvent: tanggalEvent,
            waktu: waktu,
            lokasi: lokasi,
            bannerUrl: bannerUrl,
            token: token,
            tags: _tags.text.trim(),
            thumbnailUrl: thumbUrl,
          );

      setState(() => _isLoading = false);

      if (success) {
        setState(() => _submitted = true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengirim agenda')));
      }
    } else if (_tipe == _KontenTipe.loker) {
      final auth = ref.read(authProvider);
      final token = auth.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda harus login terlebih dahulu')),
        );
        return;
      }
      final posisi = _posisi.text.trim();
      final namaPerusahaan = _namaPerusahaan.text.trim();
      final deskripsi = _deskripsiPekerjaan.text.trim();
      final kota = _kota.trim();

      List<String> emptyFields = [];
      GlobalKey? firstErrorKey;
      
      void addError(String field, GlobalKey key) {
        emptyFields.add(field);
        _errorFields.add(field);
        firstErrorKey ??= key;
      }

      _errorFields.clear();

      if (posisi.isEmpty) addError('Posisi', _keyPosisiLoker);
      if (namaPerusahaan.isEmpty) addError('Nama Perusahaan', _keyPerusahaanLoker);
      if (deskripsi.isEmpty) addError('Deskripsi Pekerjaan', _keyDeskripsiLoker);
      if (kota.isEmpty) addError('Kota', _keyKotaLoker);

      if (emptyFields.isNotEmpty) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harap lengkapi: ${emptyFields.join(', ')}'),
            backgroundColor: AppColors.danger,
          ),
        );
        if (firstErrorKey != null && firstErrorKey!.currentContext != null) {
          Scrollable.ensureVisible(
            firstErrorKey!.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return;
      }

      setState(() => _isLoading = true);
      String logoUrl = _logoUrl.value;
      String thumbUrl = _logoThumbnailUrl.value;
      if (logoUrl.isEmpty && _logoBytes.value != null) {
        final uploaded = await ref
            .read(lokerProvider.notifier)
            .uploadFile(_logoBytes.value!, _logoFileName.value);
        if (uploaded != null) {
          logoUrl = uploaded['url'] ?? '';
          thumbUrl = uploaded['thumbnailUrl'] ?? '';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengunggah logo perusahaan')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final formLamaranData = _formLamaran.map((f) {
        return {
          'id': f.label.toLowerCase().replaceAll(' ', '_'),
          'label': f.label,
          'tipe': f.tipe.name,
          'required': true,
          if (f.tipe == _InputTipe.option) 'options': f.options,
        };
      }).toList();

      final success = await ref
          .read(lokerProvider.notifier)
          .submitLoker(
            posisi: _posisi.text.trim(),
            namaPerusahaan: _namaPerusahaan.text.trim(),
            websitePerusahaan: _websitePerusahaan.text.trim(),
            logoUrl: logoUrl,
            jenisPekerjaan: _jenisPekerjaan,
            tipeLokasi: _lokasi,
            kota: _kota,
            deskripsi: _deskripsiPekerjaan.text.trim(),
            skemaPelamaran: _skema.name,
            linkExternal: _linkEksternal.text.trim(),
            formLamaran: _skema == _SkemaPelamaran.internal
                ? formLamaranData
                : [],
            token: token,
            tags: _tags.text.trim(),
            logoThumbnailUrl: thumbUrl,
          );

      setState(() => _isLoading = false);

      if (success) {
        setState(() => _submitted = true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengirim loker')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          const MemberAppBar(activeKey: ''),
          SectionWrapper(
            verticalPadding: 40,
            maxContentWidth: 720,
            child: _submitted ? const _SuccessView() : _buildForm(),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUBMIT KONTEN',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bagikan Informasi Alumni',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Container(width: 40, height: 3, color: AppColors.accent),
        const SizedBox(height: 12),
        const Text(
          'Alumni IKA JTK dapat mengirimkan informasi seperti prestasi, kegiatan, atau lowongan kerja untuk ditampilkan di website. Semua kontribusi akan ditinjau terlebih dahulu oleh tim admin sebelum dipublikasikan.',
          style: TextStyle(color: AppColors.gray600, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),

        const _Label('Tipe Konten'),
        DropdownButtonFormField<_KontenTipe>(
          initialValue: _tipe,
          items: const [
            DropdownMenuItem(value: _KontenTipe.berita, child: Text('Berita')),
            DropdownMenuItem(value: _KontenTipe.agenda, child: Text('Agenda')),
            DropdownMenuItem(value: _KontenTipe.loker, child: Text('Loker')),
          ],
          onChanged: (v) => setState(() => _tipe = v ?? _KontenTipe.berita),
        ),
        const SizedBox(height: 16),

        if (_tipe == _KontenTipe.berita) ..._beritaFields(),
        if (_tipe == _KontenTipe.agenda) ..._agendaFields(),
        if (_tipe == _KontenTipe.loker) ..._lokerFields(),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Ingin menyampaikan langsung via email?',
                    style: TextStyle(color: AppColors.gray500, fontSize: 12),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kirim ke: ika.jtk@polban.ac.id',
                    style: TextStyle(
                      color: AppColors.gray700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kirim Konten'),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _beritaFields() {
    return [
      const _Label('Kategori Berita'),
      DropdownButtonFormField<String>(
        value: _kategoriBerita,
        items: const [
          DropdownMenuItem(value: 'Karir', child: Text('Karir')),
          DropdownMenuItem(value: 'Inspirasi', child: Text('Inspirasi')),
          DropdownMenuItem(value: 'Event', child: Text('Event')),
          DropdownMenuItem(value: 'Pengabdian', child: Text('Pengabdian')),
          DropdownMenuItem(value: 'Pengumuman', child: Text('Pengumuman')),
          DropdownMenuItem(value: 'Akademik', child: Text('Akademik')),
        ],
        onChanged: (v) => setState(() => _kategoriBerita = v ?? 'Pengumuman'),
      ),
      const SizedBox(height: 16),
      const _Label('Judul Berita'),
      TextField(
        key: _keyJudulBerita,
        controller: _judul,
        decoration: InputDecoration(
          hintText: 'Masukkan Judul Berita...',
          errorText: _errorFields.contains('Judul Berita') ? 'Wajib diisi' : null,
        ),
      ),
      const SizedBox(height: 16),
      const _Label('Berita'),
      TextField(
        key: _keyKontenBerita,
        controller: _isiBerita,
        maxLines: 8,
        decoration: InputDecoration(
          hintText: 'Masukkan Konten Berita...',
          errorText: _errorFields.contains('Konten Berita') ? 'Wajib diisi' : null,
        ),
      ),
      const SizedBox(height: 16),
      Container(
        key: _keyBannerBerita,
        child: _BannerCoverField(
          fileName: _bannerFileName,
          fileBytes: _bannerBytes,
          onPickFile: _pickBanner,
          isError: _errorFields.contains('Banner'),
        ),
      ),
      const SizedBox(height: 16),
      const _Label('Tag / Kata Kunci (opsional)'),
      TextField(
        controller: _tags,
        decoration: const InputDecoration(
          hintText: 'Pisahkan dengan koma, contoh: teknologi, karir, alumni...',
        ),
      ),
    ];
  }

  List<Widget> _agendaFields() {
    return [
      const _Label('Judul Agenda'),
      TextField(
        key: _keyJudulAgenda,
        controller: _judul,
        decoration: InputDecoration(
          hintText: 'Masukkan Judul Agenda...',
          errorText: _errorFields.contains('Judul Agenda') ? 'Wajib diisi' : null,
        ),
      ),
      const SizedBox(height: 16),
      const _Label('Deskripsi Agenda'),
      TextField(
        key: _keyDeskripsiAgenda,
        controller: _deskripsiAgenda,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: 'Masukkan Deskripsi Agenda...',
          errorText: _errorFields.contains('Deskripsi') ? 'Wajib diisi' : null,
        ),
      ),
      const SizedBox(height: 16),
      const _Label('Tanggal & Waktu'),
      TextField(
        key: _keyTglWaktuAgenda,
        controller: _tanggalWaktu,
        readOnly: true,
        onTap: () async {
          final now = DateTime.now();
          final date = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: now,
            lastDate: now.add(const Duration(days: 365 * 5)),
          );
          if (date != null && mounted) {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(now),
            );
            if (time != null && mounted) {
              setState(() {
                _tanggalWaktu.text =
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}, ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              });
            }
          }
        },
        decoration: InputDecoration(
          hintText: 'Pilih Tanggal & Waktu...',
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          errorText: _errorFields.contains('Tanggal & Waktu') ? 'Wajib diisi' : null,
        ),
      ),
      const SizedBox(height: 16),
      const _Label('Lokasi/Alamat'),
      TextField(
        key: _keyLokasiAgenda,
        controller: _lokasiAlamat,
        decoration: InputDecoration(
          hintText: 'Masukkan Lokasi/Alamat...',
          errorText: _errorFields.contains('Lokasi') ? 'Wajib diisi' : null,
        ),
      ),
      const SizedBox(height: 16),
      _BannerCoverField(
        fileName: _bannerFileName,
        fileBytes: _bannerBytes,
        onPickFile: _pickBanner,
      ),
      const SizedBox(height: 16),
      const _Label('Tag / Kata Kunci (opsional)'),
      TextField(
        controller: _tags,
        decoration: const InputDecoration(
          hintText:
              'Pisahkan dengan koma, contoh: seminar, reuni, kemahasiswaan...',
        ),
      ),
    ];
  }

  List<Widget> _lokerFields() {
    const jenisOpts = [
      'Full Time',
      'Part Time',
      'Kontrak',
      'Magang',
      'Freelance',
    ];
    const lokasiOpts = ['Onsite', 'Remote', 'Hybrid'];

    return [
      const _Label('Posisi'),
      TextField(
        key: _keyPosisiLoker,
        controller: _posisi,
        decoration: InputDecoration(
          hintText: 'Masukkan Posisi...',
          errorText: _errorFields.contains('Posisi') ? 'Wajib diisi' : null,
        ),
      ),
      const SizedBox(height: 16),
      const _Label('Nama Perusahaan'),
      TextField(
        key: _keyPerusahaanLoker,
        controller: _namaPerusahaan,
        decoration: InputDecoration(
          hintText: 'Masukkan Nama Perusahaan...',
          errorText: _errorFields.contains('Nama Perusahaan') ? 'Wajib diisi' : null,
        ),
      ),
      const SizedBox(height: 16),
      const _Label('Website Perusahaan'),
      TextField(
        controller: _websitePerusahaan,
        decoration: const InputDecoration(
          hintText: 'Masukkan Website Perusahaan...',
        ),
      ),
      const SizedBox(height: 16),
      const _Label('Logo Perusahaan'),
      ValueListenableBuilder<List<int>?>(
        valueListenable: _logoBytes,
        builder: (context, bytes, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: bytes != null ? null : AppColors.gray50,
              border: Border.all(color: AppColors.gray200),
              image: bytes != null
                  ? DecorationImage(
                      image: MemoryImage(Uint8List.fromList(bytes)),
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            child: bytes == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 32,
                          color: AppColors.gray400,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Logo',
                          style: TextStyle(
                            color: AppColors.gray500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          );
        },
      ),
      _FilePickerRow(fileName: _logoFileName, onPickFile: _pickLogo),
      const SizedBox(height: 4),
      const Text(
        'File yang didukung: .jpeg, .jpg, .png, .svg | Maks. 5MB (Rekomendasi: 1080x1080px)\nJika tidak ada logo perusahaan, kami akan mengambil dari website perusahaan',
        style: TextStyle(color: AppColors.gray500, fontSize: 11),
      ),
      const SizedBox(height: 16),
      const _Label('Jenis Pekerjaan'),
      DropdownButtonFormField<String>(
        initialValue: _jenisPekerjaan,
        items: jenisOpts
            .map((j) => DropdownMenuItem(value: j, child: Text(j)))
            .toList(),
        onChanged: (v) => setState(() => _jenisPekerjaan = v ?? 'Full Time'),
      ),
      const SizedBox(height: 16),
      const _Label('Lokasi'),
      DropdownButtonFormField<String>(
        initialValue: _lokasi,
        items: lokasiOpts
            .map((l) => DropdownMenuItem(value: l, child: Text(l)))
            .toList(),
        onChanged: (v) => setState(() => _lokasi = v ?? 'Onsite'),
      ),
      const SizedBox(height: 16),
      const _Label('Kota'),
      Autocomplete<String>(
        initialValue: TextEditingValue(text: _kota),
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return indonesiaCities.take(10); // Show top 10 as hint if empty
          }
          return indonesiaCities.where((c) =>
              c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: (String selection) {
          setState(() {
            _kota = selection;
          });
        },
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextField(
            key: _keyKotaLoker,
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Ketik atau cari kota...',
              suffixIcon: const Icon(Icons.search, size: 18),
              errorText: _errorFields.contains('Kota') ? 'Wajib diisi' : null,
            ),
            onChanged: (v) {
              _kota = v;
            },
          );
        },
      ),
      const SizedBox(height: 16),
      const _Label('Deskripsi Pekerjaan'),
      TextField(
        key: _keyDeskripsiLoker,
        controller: _deskripsiPekerjaan,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: 'Masukkan Deskripsi Pekerjaan...',
          errorText: _errorFields.contains('Deskripsi Pekerjaan') ? 'Wajib diisi' : null,
        ),
      ),
      const _Label('Skema Pelamaran'),
      Row(
        children: [
          _RadioOpt(
            label: 'via Website IKAJTK',
            selected: _skema == _SkemaPelamaran.internal,
            onTap: () => setState(() => _skema = _SkemaPelamaran.internal),
          ),
          const SizedBox(width: 24),
          _RadioOpt(
            label: 'via Link Eksternal',
            selected: _skema == _SkemaPelamaran.external,
            onTap: () => setState(() => _skema = _SkemaPelamaran.external),
          ),
        ],
      ),
      const SizedBox(height: 16),

      if (_skema == _SkemaPelamaran.external) ...[
        const _Label('Link/Tautan'),
        TextField(
          controller: _linkEksternal,
          decoration: const InputDecoration(
            hintText: 'Masukkan Link/Tautan...',
          ),
        ),
      ] else ...[
        const SizedBox(height: 8),
        Container(width: 50, height: 3, color: AppColors.accent),
        const SizedBox(height: 8),
        const Text(
          'Form Lamaran',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        ..._formLamaran.asMap().entries.map((entry) {
          final i = entry.key;
          final f = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FormLamaranCard(
              data: f,
              onUpdate: (patch) => setState(() => patch(f)),
              onRemove: () => setState(() => _formLamaran.removeAt(i)),
            ),
          );
        }),
        OutlinedButton(
          onPressed: () => setState(() => _formLamaran.add(_FormFieldInput())),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Tambah Input'),
        ),
      ],
      const SizedBox(height: 16),
      const _Label('Tag / Kata Kunci (opsional)'),
      TextField(
        controller: _tags,
        decoration: const InputDecoration(
          hintText:
              'Pisahkan dengan koma, contoh: IT, fullstack, jakarta, manager...',
        ),
      ),
    ];
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.success, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'BERHASIL',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Konten Berhasil Dikirim!',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 40, height: 3, color: AppColors.accent),
          const SizedBox(height: 16),
          const Text(
            'Terima kasih atas kontribusinya. Admin IKA JTK akan mereview konten Anda sebelum dipublikasikan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gray600,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => GoRouter.of(context).go('/member'),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Kembali ke Beranda'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.gray800,
        ),
      ),
    );
  }
}

class _BannerCoverField extends StatelessWidget {
  final ValueNotifier<String> fileName;
  final ValueNotifier<List<int>?> fileBytes;
  final VoidCallback onPickFile;
  final bool isError;
  const _BannerCoverField({
    required this.fileName,
    required this.fileBytes,
    required this.onPickFile,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Banner/Cover'),
        ValueListenableBuilder<List<int>?>(
          valueListenable: fileBytes,
          builder: (context, bytes, child) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: bytes != null ? null : (isError ? AppColors.danger.withValues(alpha: 0.05) : AppColors.gray50),
                border: bytes != null
                    ? null
                    : Border.all(color: isError ? AppColors.danger : AppColors.gray200),
                image: bytes != null
                    ? DecorationImage(
                        image: MemoryImage(Uint8List.fromList(bytes)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: bytes == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: AppColors.gray400,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pilih Banner/Cover',
                            style: TextStyle(
                              color: AppColors.gray500,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Rekomendasi: 1920x1080px',
                            style: TextStyle(
                              color: AppColors.gray400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            );
          },
        ),
        _FilePickerRow(fileName: fileName, onPickFile: onPickFile),
        const SizedBox(height: 4),
        const Text(
          'File yang didukung: .jpeg, .jpg, .png | Maks. 5MB (Rekomendasi: 1920x1080px)',
          style: TextStyle(color: AppColors.gray500, fontSize: 11),
        ),
      ],
    );
  }
}

class _FilePickerRow extends StatelessWidget {
  final ValueNotifier<String> fileName;
  final VoidCallback onPickFile;
  const _FilePickerRow({required this.fileName, required this.onPickFile});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: fileName,
      builder: (_, value, _) {
        return Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.gray300),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.md),
                    bottomLeft: Radius.circular(AppRadius.md),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  value.isEmpty ? 'Tidak Ada File' : value,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: onPickFile,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  border: Border.all(color: AppColors.gray300),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppRadius.md),
                    bottomRight: Radius.circular(AppRadius.md),
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Pilih File',
                  style: TextStyle(
                    color: AppColors.gray700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RadioOpt extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioOpt({
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
        padding: const EdgeInsets.symmetric(vertical: 6),
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
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.gray800),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormLamaranCard extends StatelessWidget {
  final _FormFieldInput data;
  final void Function(void Function(_FormFieldInput)) onUpdate;
  final VoidCallback onRemove;
  const _FormLamaranCard({
    required this.data,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Informasi Tambahan'),
                    TextFormField(
                      initialValue: data.label,
                      onChanged: (v) => onUpdate((d) => d.label = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Tipe Input'),
                    DropdownButtonFormField<_InputTipe>(
                      initialValue: data.tipe,
                      items: const [
                        DropdownMenuItem(
                          value: _InputTipe.teks,
                          child: Text('Text'),
                        ),
                        DropdownMenuItem(
                          value: _InputTipe.number,
                          child: Text('Number'),
                        ),
                        DropdownMenuItem(
                          value: _InputTipe.option,
                          child: Text('Option'),
                        ),
                        DropdownMenuItem(
                          value: _InputTipe.file,
                          child: Text('File'),
                        ),
                      ],
                      onChanged: (v) {
                        onUpdate((d) {
                          d.tipe = v ?? _InputTipe.teks;
                          if (d.tipe == _InputTipe.option &&
                              d.options.isEmpty) {
                            d.options = ['', ''];
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.tipe == _InputTipe.file) ...[
            const _Label('Preview Upload'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.gray200),
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
                      Icons.attach_file,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pelamar mengupload file',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'PDF / DOC / JPG / PNG, maksimal 5 MB',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Pilih File'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (data.tipe == _InputTipe.option) ...[
            const _Label('Option'),
            ...data.options.asMap().entries.map((entry) {
              final idx = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: entry.value,
                        decoration: InputDecoration(
                          hintText: 'Opsi ${idx + 1}',
                        ),
                        onChanged: (v) => onUpdate((d) {
                          final next = List<String>.from(d.options);
                          next[idx] = v;
                          d.options = next;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PlusMinusButton(
                      icon: Icons.add,
                      onTap: () =>
                          onUpdate((d) => d.options = [...d.options, '']),
                    ),
                    const SizedBox(width: 4),
                    _PlusMinusButton(
                      icon: Icons.remove,
                      onTap: data.options.length > 1
                          ? () => onUpdate((d) {
                              final next = List<String>.from(d.options);
                              next.removeAt(idx);
                              d.options = next;
                            })
                          : null,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onRemove,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(horizontal: 20),
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

class _PlusMinusButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _PlusMinusButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.gray100 : Colors.white,
          border: Border.all(color: AppColors.gray300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? AppColors.gray300 : AppColors.gray700,
        ),
      ),
    );
  }
}
