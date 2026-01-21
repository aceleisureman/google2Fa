import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/account_provider.dart';
import '../widgets/account_card.dart';
import '../widgets/add_account_dialog.dart';
import '../widgets/import_dialog.dart';
import '../widgets/totp_tester_dialog.dart';
import '../widgets/toast_utils.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddAccountDialog(),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => const ImportDialog(),
    );
  }

  void _showTotpTester() {
    showDialog(
      context: context,
      builder: (context) => const TotpTesterDialog(),
    );
  }

  Future<void> _exportAccounts() async {
    final provider = context.read<AccountProvider>();
    if (provider.allAccounts.isEmpty) {
      ToastUtils.showTopRightToast(context, '没有账号可导出');
      return;
    }

    final result = await FilePicker.platform.saveFile(
      dialogTitle: '导出账号',
      fileName: 'google_accounts.txt',
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null) {
      await provider.exportAccounts(result);
      if (mounted) {
        ToastUtils.showTopRightToast(context, '已导出 ${provider.allAccounts.length} 个账号');
      }
    }
  }

  void _doBackup() async {
    final provider = context.read<AccountProvider>();
    if (provider.allAccounts.isEmpty) {
      ToastUtils.showTopRightToast(context, '没有账号可备份');
      return;
    }
    
    final success = await StorageService.autoBackup(provider.allAccounts);
    if (mounted) {
      if (success) {
        ToastUtils.showTopRightToast(context, '备份成功');
      } else {
        ToastUtils.showTopRightToast(context, '备份失败');
      }
    }
  }

  void _showRestoreDialog() async {
    final provider = context.read<AccountProvider>();
    final backupList = await provider.getBackupList();
    
    if (!mounted) return;
    
    if (backupList.isEmpty) {
      ToastUtils.showTopRightToast(context, '没有找到备份文件');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restore, color: Color(0xFF4285F4), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '还原备份',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white.withOpacity(0.6), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '选择要还原的备份（共 ${backupList.length} 个）',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: backupList.length,
                  itemBuilder: (context, index) {
                    final backup = backupList[index];
                    final modifiedTime = backup['modifiedTime'] as DateTime;
                    final accountCount = backup['accountCount'] as int;
                    final timeStr = '${modifiedTime.month.toString().padLeft(2, '0')}-${modifiedTime.day.toString().padLeft(2, '0')} ${modifiedTime.hour.toString().padLeft(2, '0')}:${modifiedTime.minute.toString().padLeft(2, '0')}';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: index == 0 ? const Color(0xFF34A853).withOpacity(0.2) : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: index == 0 ? const Color(0xFF34A853) : Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          timeStr,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        subtitle: Text(
                          '$accountCount 个账号',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                        ),
                        trailing: index == 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34A853).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '最新',
                                  style: TextStyle(color: Color(0xFF34A853), fontSize: 10),
                                ),
                              )
                            : null,
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await provider.restoreFromBackupFile(backup['path']);
                          if (mounted) {
                            final added = result['added'] ?? 0;
                            final duplicate = result['duplicate'] ?? 0;
                            ToastUtils.showTopRightToast(context, '还原完成：新增 $added 个，跳过重复 $duplicate 个');
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点击备份项即可还原（自动去重）',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Column(
        children: [
          _buildTitleBar(),
          _buildHeader(),
          Expanded(child: _buildAccountList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        backgroundColor: const Color(0xFF1A73E8),
        child: const Icon(Icons.add, size: 28),
      ).animate().scale(delay: 300.ms, duration: 300.ms),
    );
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 32,
        color: const Color(0xFF0D1117),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Image.asset('assets/app_icon.png', width: 16, height: 16),
            const SizedBox(width: 8),
            const Text(
              'Google 2FA Manager',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            // Window controls
            _buildWindowButton(
              icon: Icons.remove,
              onTap: () => windowManager.minimize(),
              hoverColor: Colors.white.withOpacity(0.1),
            ),
            _buildWindowButton(
              icon: Icons.crop_square,
              onTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              hoverColor: Colors.white.withOpacity(0.1),
            ),
            _buildWindowButton(
              icon: Icons.close,
              onTap: () => windowManager.hide(),
              hoverColor: Colors.red.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color hoverColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: hoverColor,
        child: SizedBox(
          width: 46,
          height: 32,
          child: Icon(icon, size: 16, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        
        return Container(
          padding: EdgeInsets.fromLTRB(16, isNarrow ? 16 : 32, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF161B22),
                const Color(0xFF0D1117),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isNarrow ? 8 : 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.security, color: Colors.white, size: isNarrow ? 20 : 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNarrow ? '2FA Manager' : 'Google 2FA Manager',
                          style: TextStyle(
                            fontSize: isNarrow ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Consumer<AccountProvider>(
                          builder: (context, provider, _) => Text(
                            '共 ${provider.totalCount} 个账号',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isNarrow ? 12 : 16),
              // Action buttons row - wrap when narrow
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildActionButton(
                    icon: Icons.verified_user_outlined,
                    label: isNarrow ? '测试' : '2FA测试',
                    onTap: _showTotpTester,
                    highlight: true,
                    compact: isNarrow,
                  ),
                  _buildActionButton(
                    icon: Icons.file_upload_outlined,
                    label: '导入',
                    onTap: _showImportDialog,
                    compact: isNarrow,
                  ),
                  _buildActionButton(
                    icon: Icons.file_download_outlined,
                    label: '导出',
                    onTap: _exportAccounts,
                    compact: isNarrow,
                  ),
                  _buildActionButton(
                    icon: Icons.backup_outlined,
                    label: '备份',
                    onTap: _doBackup,
                    compact: isNarrow,
                  ),
                  _buildActionButton(
                    icon: Icons.restore,
                    label: '还原',
                    onTap: _showRestoreDialog,
                    compact: isNarrow,
                  ),
                ],
              ),
              SizedBox(height: isNarrow ? 12 : 16),
              _buildSearchBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            gradient: highlight
                ? const LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
                  )
                : null,
            border: highlight ? null : Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(compact ? 8 : 10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withOpacity(highlight ? 1.0 : 0.8), size: compact ? 14 : 16),
              SizedBox(width: compact ? 4 : 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(highlight ? 1.0 : 0.8),
                  fontSize: compact ? 11 : 13,
                  fontWeight: highlight ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<AccountProvider>().setSearchQuery(value);
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '模糊搜索账号 (支持不连续字符匹配)...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<AccountProvider>().setSearchQuery('');
                  },
                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.4), size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildAccountList() {
    return Consumer<AccountProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
          );
        }

        if (provider.accounts.isEmpty) {
          return _buildEmptyState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = 1;
            if (width > 1200) {
              crossAxisCount = 3;
            } else if (width > 800) {
              crossAxisCount = 2;
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 500,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 80,
              ),
              itemCount: provider.accounts.length,
              itemBuilder: (context, index) {
                final account = provider.accounts[index];
                return AccountCard(
                  account: account,
                  index: index,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无账号',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加账号\n或导入已有账号文件',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
