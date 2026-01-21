import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/account_provider.dart';
import '../models/account.dart';
import 'toast_utils.dart';

class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final _textController = TextEditingController();
  bool _isImporting = false;
  String? _selectedFilePath;
  List<Account> _previewAccounts = [];
  int _invalidCount = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_parseInput);
  }

  @override
  void dispose() {
    _textController.removeListener(_parseInput);
    _textController.dispose();
    super.dispose();
  }

  void _parseInput() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _previewAccounts = [];
        _invalidCount = 0;
      });
      return;
    }

    final lines = text.split('\n');
    final accounts = <Account>[];
    final seenEmails = <String>{};
    int invalid = 0;

    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        final account = Account.fromImportString(line);
        if (account != null) {
          // 去重：同一批次内去重
          if (!seenEmails.contains(account.email)) {
            seenEmails.add(account.email);
            accounts.add(account);
          }
        } else {
          invalid++;
        }
      }
    }

    setState(() {
      _previewAccounts = accounts;
      _invalidCount = invalid;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
      });
    }
  }

  Future<void> _importFromFile() async {
    if (_selectedFilePath == null) return;

    setState(() => _isImporting = true);

    final count = await context.read<AccountProvider>().importAccounts(_selectedFilePath!);

    setState(() => _isImporting = false);

    if (mounted) {
      Navigator.pop(context);
      ToastUtils.showTopRightToast(context, '成功导入 $count 个账号');
    }
  }

  Future<void> _importFromText() async {
    if (_previewAccounts.isEmpty) return;

    setState(() => _isImporting = true);

    final provider = context.read<AccountProvider>();
    final result = await provider.batchImportAccounts(_previewAccounts);

    setState(() => _isImporting = false);

    if (mounted) {
      Navigator.pop(context);
      String message = '成功导入 ${result['added']} 个账号';
      if (result['duplicate']! > 0) {
        message += '，跳过 ${result['duplicate']} 个重复账号';
      }
      ToastUtils.showTopRightToast(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.file_upload, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Text(
                  '批量导入账号',
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
            const SizedBox(height: 20),
            // Format hint
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF1A73E8).withOpacity(0.8), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '格式: 账号----密码----辅助邮箱----2FA密钥',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '每行一个账号，自动去重',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // File import row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      _selectedFilePath ?? '未选择文件',
                      style: TextStyle(
                        color: Colors.white.withOpacity(_selectedFilePath != null ? 0.8 : 0.4),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('选择文件'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedFilePath != null && !_isImporting ? _importFromFile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('导入文件'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Text input label with stats
            Row(
              children: [
                Text(
                  '批量输入',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_previewAccounts.isNotEmpty || _invalidCount > 0)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '有效: ${_previewAccounts.length}',
                          style: const TextStyle(
                            color: Color(0xFF34A853),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_invalidCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '无效: $_invalidCount',
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Large text input
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'a@gmail.com----pass1----r1@mail.com----SECRET1\nb@gmail.com----pass2----r2@mail.com----SECRET2\nc@gmail.com----pass3----r3@mail.com----SECRET3',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Preview section
            if (_previewAccounts.isNotEmpty) ...[
              Text(
                '预览 (前5个)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _previewAccounts.length > 5 ? 5 : _previewAccounts.length,
                  itemBuilder: (context, index) {
                    final account = _previewAccounts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                account.email[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              account.email,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            account.recoveryEmail,
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Import button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _previewAccounts.isNotEmpty && !_isImporting ? _importFromText : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _previewAccounts.isEmpty ? '请输入账号' : '导入 ${_previewAccounts.length} 个账号',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
