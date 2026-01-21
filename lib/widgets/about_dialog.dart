import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'toast_utils.dart';

class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: 'banxiabk@gmail.com'));
    ToastUtils.showTopRightToast(context, '邮箱已复制');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A73E8).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.security,
                      size: 40,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            const Text(
              'Google 2FA Manager',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'v1.0.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            // Divider
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 20),
            // Info rows
            _buildInfoRow(
              icon: Icons.person_outline,
              label: '授权',
              value: 'leisureman',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: '联系',
              value: 'banxiabk@gmail.com',
              onTap: () => _copyEmail(context),
            ),
            const SizedBox(height: 24),
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '确定',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4285F4), size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: TextStyle(
                  color: onTap != null ? const Color(0xFF4285F4) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
        if (onTap != null) ...[
          const Spacer(),
          Icon(
            Icons.copy,
            size: 16,
            color: Colors.white.withOpacity(0.4),
          ),
        ],
      ],
    );
  }
}
