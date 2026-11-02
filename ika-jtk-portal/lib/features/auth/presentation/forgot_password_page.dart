import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/tokens.dart';
import '../../../shared/widgets/section_wrapper.dart';
import '../../../shared/widgets/sticky_footer_scroll_view.dart';
import '../../landing/presentation/widgets/public_app_bar.dart';
import '../../landing/presentation/widgets/site_footer.dart';
import '../providers/auth_provider.dart';
import 'package:ika_jtk_portal/core/error_handler.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _otpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _serverEmailError;

  Timer? _timer;
  int _secondsLeft = 120;
  bool _canResend = false;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _otp.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsLeft = 120;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      _serverEmailError = null;
    });
    if (!_emailFormKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).forgotPassword(_email.text);
      setState(() {
        _otpSent = true;
      });
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP telah dikirim ke email Anda.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      final errorMsg = ErrorHandler.getFriendlyMessage(e);
      if (errorMsg.toLowerCase().contains('tidak terdaftar')) {
        setState(() {
          _serverEmailError = 'Email tidak terdaftar';
        });
        _emailFormKey.currentState!.validate();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    try {
      await ref.read(authProvider.notifier).forgotPassword(_email.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP baru telah dikirim.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _startTimer();
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

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).resetPassword(
            email: _email.text,
            otp: _otp.text,
            newPassword: _newPassword.text,
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi berhasil diatur ulang. Silakan masuk.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
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

  Widget _buildEmailStep(bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LUPA KATA SANDI',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Atur Ulang Kata Sandi',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Masukkan email yang terdaftar pada akun Anda. Kami akan mengirimkan kode verifikasi (OTP) untuk mengatur ulang kata sandi Anda.',
            style: TextStyle(
              color: AppColors.gray600,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(width: 40, height: 3, color: AppColors.accent),
          const SizedBox(height: 32),
          const _Label('Email'),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            decoration: const InputDecoration(
              hintText: 'Masukkan alamat email...',
            ),
            onChanged: (v) {
              if (_serverEmailError != null) {
                setState(() {
                  _serverEmailError = null;
                });
                _emailFormKey.currentState!.validate();
              }
            },
            validator: (v) {
              if (_serverEmailError != null) return _serverEmailError;
              
              final s = v?.trim() ?? '';
              if (s.isEmpty) return 'Email wajib diisi';
              final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
              if (!emailRegex.hasMatch(s)) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => context.go('/login'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gray600,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Kembali'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim Kode OTP'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(bool isLoading) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LUPA KATA SANDI',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buat Kata Sandi Baru',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kode verifikasi telah dikirim ke ${_email.text}. Silakan masukkan kode tersebut beserta kata sandi baru Anda.',
            style: const TextStyle(
              color: AppColors.gray600,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(width: 40, height: 3, color: AppColors.accent),
          const SizedBox(height: 32),
          const _Label('Kode OTP'),
          TextFormField(
            controller: _otp,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            decoration: const InputDecoration(
              hintText: 'Masukkan 6 digit kode OTP...',
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return 'Kode OTP wajib diisi';
              if (s.length < 6) return 'Kode OTP harus 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: _canResend
                ? TextButton(
                    onPressed: isLoading ? null : _resendOtp,
                    child: const Text(
                      'Kirim Ulang Kode',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    'Kirim ulang dalam ${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          const _Label('Kata Sandi Baru'),
          TextFormField(
            controller: _newPassword,
            obscureText: _obscurePassword,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            decoration: InputDecoration(
              hintText: 'Masukkan kata sandi baru...',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.gray500,
                  size: 20,
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
              if (s.isEmpty) return 'Kata sandi baru wajib diisi';
              if (s.contains(' ')) return 'Kata sandi baru tidak boleh mengandung spasi';
              if (s.length < 8) return 'Kata sandi minimal 8 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),
          const _Label('Konfirmasi Kata Sandi Baru'),
          TextFormField(
            controller: _confirmPassword,
            obscureText: _obscureConfirmPassword,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            decoration: InputDecoration(
              hintText: 'Masukkan ulang kata sandi baru...',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.gray500,
                  size: 20,
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
              if (s.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
              if (s.contains(' ')) return 'Konfirmasi kata sandi tidak boleh mengandung spasi';
              if (s != _newPassword.text) return 'Kata sandi tidak cocok';
              return null;
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _otpSent = false;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gray600,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Kembali'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan Kata Sandi'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: StickyFooterScrollView(
        children: [
          const PublicAppBar(activeKey: ''),
          SectionWrapper(
            verticalPadding: 64,
            maxContentWidth: 720,
            child: _otpSent ? _buildResetStep(auth.isLoading) : _buildEmailStep(auth.isLoading),
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
