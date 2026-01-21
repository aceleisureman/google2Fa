import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/totp_service.dart';
import 'toast_utils.dart';

class TotpTesterDialog extends StatefulWidget {
  const TotpTesterDialog({super.key});

  @override
  State<TotpTesterDialog> createState() => _TotpTesterDialogState();
}

class _TotpTesterDialogState extends State<TotpTesterDialog> {
  final _secretController = TextEditingController();
  String _totpCode = '';
  int _remainingSeconds = 30;
  Timer? _timer;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _secretController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTotp();
    });
  }

  void _updateTotp() {
    if (_secretController.text.trim().isEmpty) {
      setState(() {
        _totpCode = '';
        _remainingSeconds = TotpService.getRemainingSeconds();
        _isValid = false;
      });
      return;
    }

    final secret = _secretController.text.trim();
    final isValid = TotpService.isValidSecret(secret);
    
    setState(() {
      _isValid = isValid;
      if (isValid) {
        _totpCode = TotpService.generateCode(secret);
      } else {
        _totpCode = '------';
      }
      _remainingSeconds = TotpService.getRemainingSeconds();
    });
  }

  void _copyToClipboard() {
    if (_totpCode.isNotEmpty && _isValid) {
      Clipboard.setData(ClipboardData(text: _totpCode));
      ToastUtils.showTopRightToast(context, '验证码已复制');
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / 30.0;
    final isLowTime = _remainingSeconds <= 5;

    return Dialog(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
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
                  child: const Icon(Icons.verified_user, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Text(
                  '2FA 测试验证',
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
            // Secret input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '输入 2FA 密钥',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _secretController,
                  onChanged: (_) => _updateTotp(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'JBSWY3DPEHPK3PXP',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: Icon(Icons.key, color: Colors.white.withOpacity(0.5)),
                    suffixIcon: _secretController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _secretController.clear();
                              _updateTotp();
                            },
                            icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.5), size: 18),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _secretController.text.isEmpty
                            ? Colors.white.withOpacity(0.1)
                            : _isValid
                                ? const Color(0xFF34A853).withOpacity(0.5)
                                : Colors.red.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isValid ? const Color(0xFF34A853) : const Color(0xFF1A73E8),
                      ),
                    ),
                  ),
                ),
                if (_secretController.text.isNotEmpty && !_isValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '无效的 2FA 密钥格式',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // TOTP Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isValid
                      ? const Color(0xFF34A853).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // TOTP Code
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '验证码',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _copyToClipboard,
                              child: Text(
                                _totpCode.isEmpty ? '------' : _totpCode,
                                style: TextStyle(
                                  color: _isValid
                                      ? (isLowTime ? Colors.orange : const Color(0xFF34A853))
                                      : Colors.white.withOpacity(0.3),
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 8,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Timer - 只有有效密钥时才显示
                      if (_isValid)
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 5,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isLowTime ? Colors.orange : const Color(0xFF1A73E8),
                                ),
                              ),
                              Text(
                                '$_remainingSeconds',
                                style: TextStyle(
                                  color: isLowTime ? Colors.orange : Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (_isValid) ...[
                    const SizedBox(height: 16),
                    Text(
                      '点击验证码可复制',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Copy button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isValid ? _copyToClipboard : null,
                icon: const Icon(Icons.copy),
                label: const Text('复制验证码'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
