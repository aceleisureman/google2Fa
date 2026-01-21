import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import '../services/totp_service.dart';
import '../services/timer_service.dart';
import 'edit_account_dialog.dart';

class AccountCard extends StatefulWidget {
  final Account account;
  final int index;

  const AccountCard({
    super.key,
    required this.account,
    required this.index,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  String _totpCode = '';
  int _remainingSeconds = 30;
  bool _showPassword = false;
  int _lastPeriod = 0;

  @override
  void initState() {
    super.initState();
    _updateTotp();
    timerService.addListener(_onTimerUpdate);
  }

  @override
  void dispose() {
    timerService.removeListener(_onTimerUpdate);
    super.dispose();
  }

  void _onTimerUpdate() {
    final currentPeriod = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    if (currentPeriod != _lastPeriod) {
      _lastPeriod = currentPeriod;
      _totpCode = TotpService.generateCode(widget.account.totpSecret);
    }
    if (mounted) {
      setState(() {
        _remainingSeconds = timerService.remainingSeconds;
      });
    }
  }

  void _updateTotp() {
    _lastPeriod = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    _totpCode = TotpService.generateCode(widget.account.totpSecret);
    _remainingSeconds = TotpService.getRemainingSeconds();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showTopRightToast('$label 已复制');
  }

  void _showTopRightToast(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => EditAccountDialog(account: widget.account),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E3F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除账号 ${widget.account.email} 吗？',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AccountProvider>().deleteAccount(widget.account.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / 30.0;
    final isLowTime = _remainingSeconds <= 5;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF161B22),
            const Color(0xFF21262D),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF30363D),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _copyToClipboard(_totpCode, '验证码'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      widget.account.email[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Email info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.account.email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _showPassword ? widget.account.password : '••••••',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showPassword = !_showPassword),
                            child: Icon(
                              _showPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white.withOpacity(0.4),
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 2FA Code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _totpCode,
                        style: TextStyle(
                          color: isLowTime ? Colors.orange : const Color(0xFF34A853),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 2,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isLowTime ? Colors.orange : const Color(0xFF1A73E8),
                              ),
                            ),
                            Text(
                              '$_remainingSeconds',
                              style: TextStyle(
                                color: isLowTime ? Colors.orange : Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Actions
                GestureDetector(
                  onTap: _showEditDialog,
                  child: Icon(Icons.edit_outlined, color: Colors.white.withOpacity(0.4), size: 16),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _confirmDelete,
                  child: Icon(Icons.delete_outline, color: Colors.red.shade300.withOpacity(0.4), size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: (widget.index % 6) * 30))
        .fadeIn(duration: 200.ms);
  }
}
