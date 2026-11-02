import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../app/tokens.dart';
import '../../../core/portal_data.dart';
import '../../../core/app_config.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../member/presentation/widgets/member_app_bar.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../providers/loker_provider.dart';

class ApplyLokerPage extends ConsumerStatefulWidget {
  final String lokerId;
  const ApplyLokerPage({super.key, required this.lokerId});

  @override
  ConsumerState<ApplyLokerPage> createState() => _ApplyLokerPageState();
}

class _ApplyLokerPageState extends ConsumerState<ApplyLokerPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _selectedOptions = {};
  final Map<String, PlatformFile> _pickedFiles = {};
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  LokerContent? get _loker => ref.watch(lokerProvider)
      .items
      .where((l) => l.id == widget.lokerId)
      .firstOrNull;

  void _initControllers(List<FormLamaranField> fields) {
    for (final f in fields) {
      if (f.tipe != 'option' && f.tipe != 'file') {
        _controllers.putIfAbsent(f.id, () => TextEditingController(text: f.defaultValue ?? ''));
      }
      if (f.tipe == 'option') {
        _selectedOptions.putIfAbsent(f.id, () => '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loker = _loker;

    if (loker == null) {
      return Scaffold(
        body: StickyFooterScrollView(children: [
          const MemberAppBar(activeKey: 'loker'),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Text('Lowongan tidak ditemukan.',
                  style: TextStyle(color: AppColors.gray500)),
            ),
          ),
          const SiteFooter(),
        ]),
      );
    }

    final fields = loker.formLamaran;
    _initControllers(fields);

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          const MemberAppBar(activeKey: 'loker'),
          SectionWrapper(
            verticalPadding: 40,
            maxContentWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => context.go('/loker/${loker.id}'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Kembali ke Detail',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lamar Loker',
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(width: 40, height: 3, color: AppColors.accent),
                const SizedBox(height: 8),
                Text(
                  '${loker.posisi} · ${loker.namaPerusahaan}',
                  style: const TextStyle(color: AppColors.gray600, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Form Lamaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(width: 28, height: 2, color: AppColors.accent),
                        const SizedBox(height: 20),
                        ...fields.map((f) => _buildField(f)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.go('/loker/${loker.id}'),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _submitting ? null : _submit,
                                icon: _submitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send, size: 16),
                                label: const Text('Kirim Lamaran'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }

  Widget _buildField(FormLamaranField f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(
            f.label,
            required: f.required == true,
          ),
          const SizedBox(height: 6),
          if (f.tipe == 'text')
            TextFormField(
              controller: _controllers[f.id],
              decoration: const InputDecoration(hintText: 'Jawaban singkat'),
              validator: f.required == true
                  ? (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null
                  : null,
            )
          else if (f.tipe == 'longtext')
            TextFormField(
              controller: _controllers[f.id],
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Jawaban panjang'),
              validator: f.required == true
                  ? (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null
                  : null,
            )
          else if (f.tipe == 'number')
            TextFormField(
              controller: _controllers[f.id],
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '0'),
              validator: f.required == true
                  ? (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null
                  : null,
            )
          else if (f.tipe == 'option' && f.options != null)
            ...f.options!.map((opt) => _RadioOpt(
                  label: opt,
                  selected: _selectedOptions[f.id] == opt,
                  onTap: () => setState(() => _selectedOptions[f.id] = opt),
                ))
          else if (f.tipe == 'file')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (f.fileUrl != null && f.fileUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => launchUrlString(f.fileUrl!.startsWith('/') ? '${AppConfig.serverHost}${f.fileUrl}' : f.fileUrl!),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              f.fileName ?? 'Unduh Lampiran / Template',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      setState(() {
                        _pickedFiles[f.id] = result.files.first;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gray200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.upload_file, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pickedFiles[f.id]?.name ?? 'Upload File',
                            style: TextStyle(color: AppColors.gray600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if required files/options are selected
    final loker = _loker;
    if (loker == null) return;
    
    for (final f in loker.formLamaran) {
      if (f.required == true) {
        if (f.tipe == 'option' && (_selectedOptions[f.id] ?? '').isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${f.label} wajib diisi')));
          return;
        }
        if (f.tipe == 'file' && _pickedFiles[f.id] == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${f.label} wajib diisi')));
          return;
        }
      }
    }

    setState(() => _submitting = true);

    final Map<String, dynamic> jawaban = {};

    for (final f in loker.formLamaran) {
      if (f.tipe == 'option') {
        jawaban[f.id] = _selectedOptions[f.id] ?? '';
      } else if (f.tipe == 'file') {
        final file = _pickedFiles[f.id];
        if (file != null && file.bytes != null) {
          final url = await ref.read(lokerProvider.notifier).uploadFile(file.bytes!, file.name);
          if (url == null) {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunggah file ${f.label}')));
            return;
          }
          jawaban[f.id] = url['url'] ?? '';
        } else {
          jawaban[f.id] = '';
        }
      } else {
        jawaban[f.id] = _controllers[f.id]?.text ?? '';
      }
    }

    final result = await ref.read(lokerProvider.notifier).apply(loker.id, jawaban);

    setState(() => _submitting = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Lamaran berhasil dikirim!')),
      );
      context.go('/member/lamaran');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Gagal mengirim lamaran.')),
      );
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.gray800,
          ),
        ),
        if (required)
          const Text(' *', style: TextStyle(color: AppColors.danger, fontSize: 13)),
      ],
    );
  }
}

class _RadioOpt extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioOpt({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
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
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.gray800)),
          ],
        ),
      ),
    );
  }
}
