import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import '../services/totp_service.dart';
import 'toast_utils.dart';

class EditAccountDialog extends StatefulWidget {
  final Account account;

  const EditAccountDialog({super.key, required this.account});

  @override
  State<EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<EditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _recoveryEmailController;
  late TextEditingController _totpSecretController;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.account.email);
    _passwordController = TextEditingController(text: widget.account.password);
    _recoveryEmailController = TextEditingController(text: widget.account.recoveryEmail);
    _totpSecretController = TextEditingController(text: widget.account.totpSecret);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _recoveryEmailController.dispose();
    _totpSecretController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedAccount = widget.account.copyWith(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        recoveryEmail: _recoveryEmailController.text.trim(),
        totpSecret: _totpSecretController.text.replaceAll(' ', '').toUpperCase(),
      );
      context.read<AccountProvider>().updateAccount(updatedAccount);
      Navigator.pop(context);
      ToastUtils.showTopRightToast(context, '账号更新成功');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '编辑账号',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white.withOpacity(0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _emailController,
                label: '邮箱账号',
                hint: 'example@gmail.com',
                icon: Icons.email_outlined,
                validator: (v) => v!.isEmpty ? '请输入邮箱' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: '密码',
                hint: '输入密码',
                icon: Icons.lock_outline,
                obscure: !_showPassword,
                suffix: IconButton(
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                validator: (v) => v!.isEmpty ? '请输入密码' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _recoveryEmailController,
                label: '辅助邮箱',
                hint: 'recovery@example.com',
                icon: Icons.alternate_email,
                validator: (v) => v!.isEmpty ? '请输入辅助邮箱' : null,
              ),
              const SizedBox(height: 16),
              _build2FATextField(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1A73E8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _build2FATextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2FA 密钥',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _totpSecretController,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(
                text: newValue.text.toUpperCase(),
                selection: newValue.selection,
              );
            }),
          ],
          onChanged: (value) {
            final cleaned = value.replaceAll(' ', '').toUpperCase();
            if (cleaned != value) {
              _totpSecretController.value = TextEditingValue(
                text: cleaned,
                selection: TextSelection.collapsed(offset: cleaned.length),
              );
            }
          },
          validator: (v) {
            if (v!.isEmpty) return '请输入2FA密钥';
            if (!TotpService.isValidSecret(v)) return '无效的2FA密钥';
            return null;
          },
          decoration: InputDecoration(
            hintText: 'JBSWY3DPEHPK3PXP',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(Icons.security, color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A73E8)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
          ),
        ),
      ],
    );
  }
}
