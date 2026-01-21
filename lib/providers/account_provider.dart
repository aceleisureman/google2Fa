import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../services/storage_service.dart';

class AccountProvider extends ChangeNotifier {
  List<Account> _accounts = [];
  String _searchQuery = '';
  bool _isLoading = false;

  List<Account> get accounts {
    if (_searchQuery.isEmpty) {
      return _accounts;
    }
    final query = _searchQuery.toLowerCase();
    return _accounts.where((account) {
      // 模糊搜索：支持搜索邮箱、辅助邮箱、密码的任意部分
      return _fuzzyMatch(account.email.toLowerCase(), query) ||
          _fuzzyMatch(account.recoveryEmail.toLowerCase(), query) ||
          account.email.toLowerCase().contains(query) ||
          account.recoveryEmail.toLowerCase().contains(query);
    }).toList();
  }

  // 模糊匹配：支持不连续字符匹配
  bool _fuzzyMatch(String text, String pattern) {
    int patternIndex = 0;
    for (int i = 0; i < text.length && patternIndex < pattern.length; i++) {
      if (text[i] == pattern[patternIndex]) {
        patternIndex++;
      }
    }
    return patternIndex == pattern.length;
  }

  List<Account> get allAccounts => _accounts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int get totalCount => _accounts.length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();

    _accounts = await StorageService.loadAccounts();
    
    // 自动备份
    if (_accounts.isNotEmpty) {
      await StorageService.autoBackup(_accounts);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addAccount(Account account) async {
    // 检查是否已存在相同邮箱
    final exists = _accounts.any((a) => a.email == account.email);
    if (exists) return false;
    
    _accounts.add(account);
    await StorageService.saveAccounts(_accounts);
    notifyListeners();
    return true;
  }

  // 批量导入账号（自动去重）
  Future<Map<String, int>> batchImportAccounts(List<Account> accounts) async {
    int addedCount = 0;
    int duplicateCount = 0;
    
    for (final account in accounts) {
      final exists = _accounts.any((a) => a.email == account.email);
      if (!exists) {
        _accounts.add(account);
        addedCount++;
      } else {
        duplicateCount++;
      }
    }
    
    if (addedCount > 0) {
      await StorageService.saveAccounts(_accounts);
      notifyListeners();
    }
    
    return {'added': addedCount, 'duplicate': duplicateCount};
  }

  Future<void> updateAccount(Account account) async {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      _accounts[index] = account;
      await StorageService.saveAccounts(_accounts);
      notifyListeners();
    }
  }

  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    await StorageService.saveAccounts(_accounts);
    notifyListeners();
  }

  Future<int> importAccounts(String filePath) async {
    final importedAccounts = await StorageService.importFromFile(filePath);
    int addedCount = 0;
    
    for (final account in importedAccounts) {
      // Check for duplicates by email
      final exists = _accounts.any((a) => a.email == account.email);
      if (!exists) {
        _accounts.add(account);
        addedCount++;
      }
    }
    
    if (addedCount > 0) {
      await StorageService.saveAccounts(_accounts);
      notifyListeners();
    }
    
    return addedCount;
  }

  Future<void> exportAccounts(String filePath) async {
    await StorageService.exportToFile(filePath, _accounts);
  }

  Future<void> deleteAllAccounts() async {
    _accounts.clear();
    await StorageService.saveAccounts(_accounts);
    notifyListeners();
  }

  /// 从备份还原账号
  Future<Map<String, int>> restoreFromBackup() async {
    final backupAccounts = await StorageService.restoreFromBackup();
    if (backupAccounts.isEmpty) {
      return {'added': 0, 'duplicate': 0, 'total': 0};
    }
    
    int addedCount = 0;
    int duplicateCount = 0;
    
    for (final account in backupAccounts) {
      final exists = _accounts.any((a) => a.email == account.email);
      if (!exists) {
        _accounts.add(account);
        addedCount++;
      } else {
        duplicateCount++;
      }
    }
    
    if (addedCount > 0) {
      await StorageService.saveAccounts(_accounts);
      notifyListeners();
    }
    
    return {
      'added': addedCount,
      'duplicate': duplicateCount,
      'total': backupAccounts.length,
    };
  }

  /// 获取备份信息
  Future<Map<String, dynamic>?> getBackupInfo() async {
    return await StorageService.getBackupInfo();
  }

  /// 检查备份是否存在
  Future<bool> hasBackup() async {
    return await StorageService.backupExists();
  }

  /// 获取备份列表
  Future<List<Map<String, dynamic>>> getBackupList() async {
    return await StorageService.getBackupList();
  }

  /// 从指定备份文件还原
  Future<Map<String, int>> restoreFromBackupFile(String filePath) async {
    final backupAccounts = await StorageService.restoreFromBackupFile(filePath);
    if (backupAccounts.isEmpty) {
      return {'added': 0, 'duplicate': 0, 'total': 0};
    }
    
    int addedCount = 0;
    int duplicateCount = 0;
    
    for (final account in backupAccounts) {
      final exists = _accounts.any((a) => a.email == account.email);
      if (!exists) {
        _accounts.add(account);
        addedCount++;
      } else {
        duplicateCount++;
      }
    }
    
    if (addedCount > 0) {
      await StorageService.saveAccounts(_accounts);
      notifyListeners();
    }
    
    return {
      'added': addedCount,
      'duplicate': duplicateCount,
      'total': backupAccounts.length,
    };
  }
}
