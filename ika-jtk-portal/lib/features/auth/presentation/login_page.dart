import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../../../core/portal_config_provider.dart';
import '../providers/auth_provider.dart';
import 'package:ika_jtk_portal/core/error_handler.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  Map<String, String> _savedCredentials = {};

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Migrate old single credential if exists (simpan username tanpa password)
    final oldUser = prefs.getString('saved_username');
    if (oldUser != null && oldUser.isNotEmpty) {
      _savedCredentials[oldUser] = '';
      prefs.remove('saved_username');
      prefs.remove('saved_password');
      prefs.setString('saved_credentials', jsonEncode(_savedCredentials));
    }
    
    final savedJson = prefs.getString('saved_credentials');
    if (savedJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(savedJson);
        _savedCredentials = decoded.map((key, value) => MapEntry(key, ''));
      } catch (e) {
        // ignore
      }
    }

    // Langsung isi (autofill) bagian username begitu membuka page login (tanpa mengisi password)
    final lastUser = prefs.getString('last_logged_username');
    if (mounted) {
      setState(() {
        if (_username.text.isEmpty) {
          if (lastUser != null && lastUser.isNotEmpty) {
            _username.text = lastUser;
          } else if (_savedCredentials.isNotEmpty) {
            _username.text = _savedCredentials.keys.last;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      await ref.read(authProvider.notifier).login(_username.text, _password.text);
      
      // Save username locally (DO NOT save password as requested)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_logged_username', _username.text.trim());
      if (_rememberMe) {
        _savedCredentials[_username.text.trim()] = ''; // Hanya username, password kosong
        await prefs.setString('saved_credentials', jsonEncode(_savedCredentials));
      }
      
      if (mounted) context.go('/member');
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('VERIFICATION_NEEDED:')) {
          final email = errorMsg.split('VERIFICATION_NEEDED:').last.trim();
          context.push('/register/verify?email=$email');
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getFriendlyMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final config = ref.watch(portalConfigProvider).valueOrNull;
    final siteName = config?.siteName ?? 'IKA JTK POLBAN';
    final logoUrl = config?.logoUrl ?? '';

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
                  if (logoUrl.isNotEmpty) ...[
                    Image.network(
                      logoUrl,
                      height: 64,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'MASUK',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat Datang di $siteName!',
                    style: const TextStyle(
                      color: AppColors.gray900,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Silakan masuk untuk terhubung kembali dengan sesama alumni, akses informasi terbaru, dan jelajahi peluang eksklusif yang tersedia untuk Anda.',
                    style: TextStyle(
                      color: AppColors.gray600,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(width: 40, height: 3, color: AppColors.accent),
                  const SizedBox(height: 32),
                  const _Label('Username'),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return _savedCredentials.keys.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      _username.text = selection;
                      _password.text = ''; // Jangan autofill password
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                      // Keep _username synced with the autocomplete controller
                      if (_username.text != fieldTextEditingController.text) {
                        fieldTextEditingController.text = _username.text;
                      }
                      fieldTextEditingController.addListener(() {
                        _username.text = fieldTextEditingController.text;
                      });
                      
                      return TextFormField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                        decoration: const InputDecoration(
                          hintText: 'Masukkan Username...',
                        ),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Username wajib diisi';
                          if ((v ?? '').contains(' ')) return 'Username tidak boleh mengandung spasi';
                          return null;
                        },
                      );
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
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) {
                            setState(() {
                              _rememberMe = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ingat saya (Autofill)',
                        style: TextStyle(
                          color: AppColors.gray700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(builder: (context, c) {
                    final isMobile = c.maxWidth < AppBreakpoints.tablet;
                    final links = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          children: [
                            const Text(
                              'Belum punya akun? ',
                              style: TextStyle(
                                color: AppColors.gray600,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: const Text(
                                'Daftar',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          children: [
                            const Text(
                              'Lupa Kata Sandi? ',
                              style: TextStyle(
                                color: AppColors.gray600,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/lupa-sandi'),
                              child: const Text(
                                'Reset Kata Sandi',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );

                    final button = ElevatedButton(
                      onPressed: auth.isLoading ? null : _onSubmit,
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
                          : const Text('Masuk'),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          links,
                          const SizedBox(height: 16),
                          SizedBox(width: double.infinity, child: button),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: links),
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
