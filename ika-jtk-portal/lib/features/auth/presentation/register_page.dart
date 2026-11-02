import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/searchable_dropdown_field.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../providers/auth_provider.dart';
import 'package:ika_jtk_portal/core/error_handler.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _tanggalLahir = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String _angkatan = '';
  String _jenisKelamin = '';

  final _emailFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  String? _emailError;
  String? _usernameError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus && _email.text.trim().isNotEmpty && _email.text.trim().contains('@')) {
        _checkEmailUnique();
      }
    });
    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus && _username.text.trim().isNotEmpty) {
        _checkUsernameUnique();
      }
    });
  }

  Future<void> _checkEmailUnique() async {
    try {
      await ref.read(authProvider.notifier).checkUnique(email: _email.text.trim());
      if (mounted && _emailError != null) {
        setState(() => _emailError = null);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _emailError = ErrorHandler.getFriendlyMessage(e));
      }
    }
  }

  Future<void> _checkUsernameUnique() async {
    try {
      await ref.read(authProvider.notifier).checkUnique(username: _username.text.trim());
      if (mounted && _usernameError != null) {
        setState(() => _usernameError = null);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _usernameError = ErrorHandler.getFriendlyMessage(e));
      }
    }
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _usernameFocusNode.dispose();
    _nama.dispose();
    _tanggalLahir.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    setState(() {
      _emailError = null;
      _usernameError = null;
    });

    try {
      await ref.read(authProvider.notifier).checkUnique(
        email: _email.text.trim(),
        username: _username.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        final msg = ErrorHandler.getFriendlyMessage(e);
        if (msg.toLowerCase().contains('email')) {
          setState(() => _emailError = msg);
        } else if (msg.toLowerCase().contains('username')) {
          setState(() => _usernameError = msg);
        }
        _formKey.currentState?.validate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terdapat data yang belum lengkap atau tidak valid. Silakan periksa kembali form Anda.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi kata sandi tidak cocok'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_jenisKelamin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jenis kelamin wajib dipilih'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda wajib menyetujui Ketentuan & Kebijakan (User Agreements) untuk mendaftar'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).register(
            nama: _nama.text.trim(),
            angkatan: _angkatan,
            tanggalLahir: _tanggalLahir.text.trim(),
            jenisKelamin: _jenisKelamin,
            email: _email.text.trim(),
            username: _username.text.trim(),
            password: _password.text,
            userAgreement: _agreedToTerms,
          );
      if (mounted) {
        context.go('/register/verify?email=${Uri.encodeComponent(_email.text.trim())}');
      }
    } catch (e) {
      if (mounted) {
        final msg = ErrorHandler.getFriendlyMessage(e);
        if (msg.toLowerCase().contains('email')) {
          setState(() => _emailError = msg);
        } else if (msg.toLowerCase().contains('username')) {
          setState(() => _usernameError = msg);
        }
        _formKey.currentState?.validate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
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
    
    final initial = DateTime(now.year - 20, 1, 1);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(maxDate) ? initial : maxDate,
      firstDate: DateTime(1950),
      lastDate: maxDate,
    );
    if (picked != null) {
      final pad = (int n) => n.toString().padLeft(2, '0');
      _tanggalLahir.text =
          '${picked.year}-${pad(picked.month)}-${pad(picked.day)}';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    
    int minAngkatanYear = 1960;
    if (_tanggalLahir.text.isNotEmpty) {
      final tl = DateTime.tryParse(_tanggalLahir.text);
      if (tl != null && tl.year > minAngkatanYear) {
        minAngkatanYear = tl.year;
      }
    }
    final currentYear = DateTime.now().year;
    final tahun = [
      for (int i = currentYear; i >= minAngkatanYear; i--) i.toString()
    ];
    if (_angkatan.isNotEmpty && !tahun.contains(_angkatan)) {
      tahun.add(_angkatan);
      tahun.sort((a, b) => b.compareTo(a));
    }

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          const PublicAppBar(activeKey: ''),
          SectionWrapper(
            verticalPadding: 64,
            maxContentWidth: 720,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DAFTAR',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gabung dengan Alumni JTK Polban',
                    style: TextStyle(
                      color: AppColors.gray900,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dengan bergabung, Anda dapat mengakses direktori alumni, berbagi pengalaman, mendapatkan informasi terbaru, serta memperluas jaringan profesional.',
                    style: TextStyle(
                      color: AppColors.gray600,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(width: 40, height: 3, color: AppColors.accent),
                  const SizedBox(height: 24),
                  const Text(
                    'Silakan isi data diri Anda dengan lengkap agar kami dapat memverifikasi keanggotaan Anda sebagai alumni Teknik Komputer Polban.',
                    style: TextStyle(
                      color: AppColors.gray600,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const _Label('Nama Lengkap'),
                  TextFormField(
                    controller: _nama,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan Nama Lengkap...',
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  const _Label('Angkatan'),
                  SearchableDropdownField(
                    items: tahun,
                    initialValue: _angkatan.isEmpty ? null : _angkatan,
                    hintText: 'Cari atau pilih angkatan...',
                    onChanged: (v) => setState(() => _angkatan = v ?? ''),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Pilih angkatan' : null,
                  ),
                  const SizedBox(height: 16),

                  const _Label('Tanggal Lahir'),
                  TextFormField(
                    controller: _tanggalLahir,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: InputDecoration(
                      hintText: 'Pilih Tanggal Lahir...',
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.gray500,
                        ),
                        onPressed: _pickDate,
                      ),
                    ),
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Tanggal lahir wajib diisi';
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

                  const _Label('Jenis Kelamin'),
                  Row(
                    children: [
                      Expanded(
                        child: _RadioOption(
                          label: 'Laki-laki',
                          selected: _jenisKelamin == 'Laki-laki',
                          onTap: () =>
                              setState(() => _jenisKelamin = 'Laki-laki'),
                        ),
                      ),
                      Expanded(
                        child: _RadioOption(
                          label: 'Perempuan',
                          selected: _jenisKelamin == 'Perempuan',
                          onTap: () =>
                              setState(() => _jenisKelamin = 'Perempuan'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const _Label('Email'),
                  TextFormField(
                    controller: _email,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                    decoration: InputDecoration(
                      hintText: 'Masukkan Email...',
                      errorText: _emailError,
                    ),
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Email wajib diisi';
                      if (!s.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const _Label('Username'),
                  TextFormField(
                    controller: _username,
                    focusNode: _usernameFocusNode,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                    decoration: InputDecoration(
                      hintText: 'Masukkan Username...',
                      errorText: _usernameError,
                    ),
                    onChanged: (_) {
                      if (_usernameError != null) {
                        setState(() => _usernameError = null);
                      }
                    },
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Username wajib diisi';
                      if ((v ?? '').contains(' ')) return 'Username tidak boleh mengandung spasi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const _Label('Kata Sandi'),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                    decoration: InputDecoration(
                      hintText: 'Masukkan Kata Sandi...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.gray500,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (v) {
                      final s = v ?? '';
                      if (s.isEmpty) return 'Kata sandi wajib diisi';
                      if (s.contains(' ')) return 'Kata sandi tidak boleh mengandung spasi';
                      if (s.length < 8) {
                        return 'Kata sandi minimal 8 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const _Label('Konfirmasi Kata Sandi'),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: _obscureConfirmPassword,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                    decoration: InputDecoration(
                      hintText: 'Masukkan Konfirmasi Kata Sandi...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.gray500,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (v) {
                      final s = v ?? '';
                      if (s.isEmpty) {
                        return 'Konfirmasi kata sandi wajib diisi';
                      }
                      if (s.contains(' ')) {
                        return 'Konfirmasi kata sandi tidak boleh mengandung spasi';
                      }
                      if (s != _password.text) {
                        return 'Konfirmasi kata sandi tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Catatan box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '📝',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Catatan :',
                              style: const TextStyle(
                                color: AppColors.gray900,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Data yang Anda masukkan akan diverifikasi oleh admin untuk memastikan keanggotaan alumni. Anda akan menerima email notifikasi setelah akun Anda diaktifkan.',
                          style: TextStyle(
                            color: AppColors.gray700,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Agreements Checkbox
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _agreedToTerms ? AppColors.primary.withOpacity(0.04) : AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _agreedToTerms ? AppColors.primary : AppColors.gray300,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (val) {
                              setState(() {
                                _agreedToTerms = val ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreedToTerms = !_agreedToTerms;
                              });
                            },
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: AppColors.gray800,
                                  fontSize: 13,
                                  height: 1.5,
                                  fontFamily: 'Inter',
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Saya menyatakan bahwa data yang saya masukkan adalah benar, dan saya telah membaca serta menyetujui ',
                                  ),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: InkWell(
                                      onTap: () => context.push('/user-agreements'),
                                      child: const Text(
                                        'User Agreement',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' yang berlaku di IKA JTK POLBAN. *',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  LayoutBuilder(builder: (context, c) {
                    final isMobile = c.maxWidth < AppBreakpoints.tablet;
                    final loginLink = Wrap(
                      children: [
                        const Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            color: AppColors.gray600,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );

                    final button = ElevatedButton(
                      onPressed: (auth.isLoading || !_agreedToTerms) ? null : _onSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Gabung Sekarang'),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          loginLink,
                          const SizedBox(height: 16),
                          SizedBox(width: double.infinity, child: button),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: loginLink),
                        button,
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
