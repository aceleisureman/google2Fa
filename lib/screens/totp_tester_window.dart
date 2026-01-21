import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../services/totp_service.dart';
import '../widgets/toast_utils.dart';

class TotpTesterWindow extends StatefulWidget {
  const TotpTesterWindow({super.key});

  @override
  State<TotpTesterWindow> createState() => _TotpTesterWindowState();
}

class _TotpTesterWindowState extends State<TotpTesterWindow> with WindowListener {
  final _secretController = TextEditingController();
  String _totpCode = '';
  int _remainingSeconds = 30;
  Timer? _timer;
  bool _isValid = false;
  bool _isAlwaysOnTop = true;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindow();
    _startTimer();
  }

  Future<void> _initWindow() async {
    await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
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

  Future<void> _toggleAlwaysOnTop() async {
    setState(() {
      _isAlwaysOnTop = !_isAlwaysOnTop;
    });
    await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / 30.0;
    final isLowTime = _remainingSeconds <= 5;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: GestureDetector(
          onPanStart: (_) => windowManager.startDragging(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E1E3F),
                  const Color(0xFF0F0F23).withOpacity(0.9),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.verified_user, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  '2FA 测试验证',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Always on top toggle
                Tooltip(
                  message: _isAlwaysOnTop ? '取消置顶' : '窗口置顶',
                  child: IconButton(
                    onPressed: _toggleAlwaysOnTop,
                    icon: Icon(
                      _isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
                      color: _isAlwaysOnTop ? const Color(0xFF10B981) : Colors.white.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
                ),
                // Close button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white.withOpacity(0.6), size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Secret input
            Text(
              '输入 2FA 密钥',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _secretController,
              onChanged: (_) => _updateTotp(),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'JBSWY3DPEHPK3PXP',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: Icon(Icons.key, color: Colors.white.withOpacity(0.5), size: 18),
                suffixIcon: _secretController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _secretController.clear();
                          _updateTotp();
                        },
                        icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.5), size: 16),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _secretController.text.isEmpty
                        ? Colors.white.withOpacity(0.1)
                        : _isValid
                            ? const Color(0xFF10B981).withOpacity(0.5)
                            : Colors.red.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _isValid ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
            if (_secretController.text.isNotEmpty && !_isValid)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '无效的 2FA 密钥格式',
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 11,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // TOTP Display
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isValid
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // TOTP Code
                        Expanded(
                          child: GestureDetector(
                            onTap: _copyToClipboard,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '验证码',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _totpCode.isEmpty ? '------' : _totpCode,
                                  style: TextStyle(
                                    color: _isValid
                                        ? (isLowTime ? Colors.orange : const Color(0xFF10B981))
                                        : Colors.white.withOpacity(0.3),
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 6,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Timer
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 4,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isLowTime ? Colors.orange : const Color(0xFF6366F1),
                                ),
                              ),
                              Text(
                                '$_remainingSeconds',
                                style: TextStyle(
                                  color: isLowTime ? Colors.orange : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isValid) ...[
                      const SizedBox(height: 12),
                      Text(
                        '点击验证码可复制',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Copy button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isValid ? _copyToClipboard : null,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制验证码'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
