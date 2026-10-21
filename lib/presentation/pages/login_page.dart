import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthLoginRequested(_emailCtrl.text.trim(), _passCtrl.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bg(context);
    final accent = AppTheme.accent(context);
    final textCol = AppTheme.text(context);
    final text2Col = AppTheme.text2(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/');
          } else if (state is AuthError) {
            final msg = state.message == 'EMAIL_NOT_VERIFIED'
                ? 'Email chưa được xác minh. Vui lòng kiểm tra hộp thư!'
                : state.message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Logo ──────────────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF242424) : AppTheme.surface2(context),
                        shape: BoxShape.circle,
                        border: !isDarkMode
                            ? Border.all(
                                color: accent.withValues(alpha: 0.4),
                                width: 1.5,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: isDarkMode ? 0.12 : 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('📚', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Heading ───────────────────────────────────
                    Text(
                      'Simple Quizlet',
                      style: AppTheme.displayMd(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đăng nhập để tiếp tục',
                      style: AppTheme.bodyMd(context).copyWith(
                        color: text2Col,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Form ──────────────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField(
                            controller: _emailCtrl,
                            label: 'Email',
                            hint: 'you@example.com',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                              if (!v.contains('@')) return 'Email không hợp lệ';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _passCtrl,
                            label: 'Mật khẩu',
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppTheme.text3(context),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          // ── Primary CTA: Pill ──────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: isDarkMode ? Colors.black : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                                ),
                              ),
                              onPressed: loading ? null : _submit,
                              child: loading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: isDarkMode ? Colors.black : Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'ĐĂNG NHẬP',
                                      style: AppTheme.labelLg(context).copyWith(
                                        color: isDarkMode ? Colors.black : Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Register link ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Chưa có tài khoản? ', style: AppTheme.bodyMd(context).copyWith(color: text2Col)),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: AppTheme.bodyLg(context),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppTheme.text2(context)),
        hintStyle: TextStyle(color: AppTheme.text3(context)),
        prefixIcon: Icon(icon, color: AppTheme.text3(context), size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}
