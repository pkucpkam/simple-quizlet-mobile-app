import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthRegisterRequested(
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _usernameCtrl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistered) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đăng ký thành công! Vui lòng kiểm tra email để xác minh tài khoản.'),
                backgroundColor: AppTheme.successColor,
                duration: Duration(seconds: 4),
              ),
            );
            context.go('/login');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.errorColor),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tạo tài khoản mới', style: AppTheme.displayMd),
                  const SizedBox(height: 6),
                  Text('Điền thông tin để bắt đầu học', style: AppTheme.bodyMd),
                  const SizedBox(height: 28),

                  _label('Email'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTheme.bodyLg,
                    decoration: const InputDecoration(hintText: 'you@example.com'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                      if (!v.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _label('Tên người dùng'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _usernameCtrl,
                    style: AppTheme.bodyLg,
                    decoration: const InputDecoration(hintText: 'username của bạn'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên người dùng';
                      if (v.trim().length < 3) return 'Tên người dùng ít nhất 3 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _label('Mật khẩu'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: AppTheme.bodyLg,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.text3Color,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (v.length < 6) return 'Mật khẩu ít nhất 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _label('Xác nhận mật khẩu'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    style: AppTheme.bodyLg,
                    decoration: const InputDecoration(hintText: '••••••••'),
                    validator: (v) {
                      if (v != _passCtrl.text) return 'Mật khẩu không khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Đăng ký'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Đã có tài khoản? ', style: AppTheme.bodyMd),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Đăng nhập'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTheme.bodyMd.copyWith(color: AppTheme.textColor, fontWeight: FontWeight.w500),
      );
}
