import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/account.dart';

class StorageService {
  static const String _fileName = 'accounts.json';
  static const String _backupFileName = '2fa_backup.txt';

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  static Future<List<Account>> loadAccounts() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        return Account.fromJsonList(contents);
      }
    } catch (e) {
      print('Error loading accounts: $e');
    }
    return [];
  }

  static Future<void> saveAccounts(List<Account> accounts) async {
    try {
      final file = await _localFile;
      await file.writeAsString(Account.toJsonList(accounts));
    } catch (e) {
      print('Error saving accounts: $e');
    }
  }

  static Future<List<Account>> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();
      final lines = contents.split('\n');
      final accounts = <Account>[];
      
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          final account = Account.fromImportString(line);
          if (account != null) {
            accounts.add(account);
          }
        }
      }
      return accounts;
    } catch (e) {
      print('Error importing accounts: $e');
      return [];
    }
  }

  static Future<void> exportToFile(String filePath, List<Account> accounts) async {
    try {
      final file = File(filePath);
      final lines = accounts.map((a) => a.toExportString()).join('\n');
      await file.writeAsString(lines);
    } catch (e) {
      print('Error exporting accounts: $e');
    }
  }

  /// 获取备份文件路径（exe所在目录）
  static Future<String> getBackupFilePath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = File(exePath).parent.path;
    return '$exeDir\\$_backupFileName';
  }

  /// 自动备份到exe根目录（保留最近10次备份）
  static Future<bool> autoBackup(List<Account> accounts) async {
    if (accounts.isEmpty) return false;
    try {
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final backupFileName = '2fa_backup_$timestamp.txt';
      final backupPath = '$exeDir\\$backupFileName';
      
      final file = File(backupPath);
      final lines = accounts.map((a) => a.toExportString()).join('\n');
      await file.writeAsString(lines);
      
      // 清理旧备份，只保留最近10个
      await _cleanOldBackups(exeDir);
      
      print('Auto backup saved to: $backupPath');
      return true;
    } catch (e) {
      print('Error auto backup: $e');
      return false;
    }
  }

  /// 清理旧备份，只保留最近10个
  static Future<void> _cleanOldBackups(String exeDir) async {
    try {
      final dir = Directory(exeDir);
      final backupFiles = <File>[];
      
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.contains('2fa_backup_') && entity.path.endsWith('.txt')) {
          backupFiles.add(entity);
        }
      }
      
      if (backupFiles.length > 10) {
        // 按修改时间排序，最新的在前
        backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        
        // 删除多余的备份
        for (int i = 10; i < backupFiles.length; i++) {
          await backupFiles[i].delete();
          print('Deleted old backup: ${backupFiles[i].path}');
        }
      }
    } catch (e) {
      print('Error cleaning old backups: $e');
    }
  }

  /// 检查备份文件是否存在
  static Future<bool> backupExists() async {
    final backups = await getBackupList();
    return backups.isNotEmpty;
  }

  /// 获取所有备份文件列表（最多10个，按时间倒序）
  static Future<List<Map<String, dynamic>>> getBackupList() async {
    try {
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      final dir = Directory(exeDir);
      final backupFiles = <File>[];
      
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.contains('2fa_backup_') && entity.path.endsWith('.txt')) {
          backupFiles.add(entity);
        }
      }
      
      // 按修改时间排序，最新的在前
      backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // 只取前10个
      final result = <Map<String, dynamic>>[];
      for (int i = 0; i < backupFiles.length && i < 10; i++) {
        final file = backupFiles[i];
        final stat = await file.stat();
        final contents = await file.readAsString();
        final accountCount = contents.split('\n').where((l) => l.trim().isNotEmpty).length;
        
        result.add({
          'path': file.path,
          'fileName': file.path.split('\\').last,
          'modifiedTime': stat.modified,
          'accountCount': accountCount,
        });
      }
      
      return result;
    } catch (e) {
      print('Error getting backup list: $e');
      return [];
    }
  }

  /// 从指定备份文件还原
  static Future<List<Account>> restoreFromBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return [];
      
      final contents = await file.readAsString();
      final lines = contents.split('\n');
      final accounts = <Account>[];
      
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          final account = Account.fromImportString(line);
          if (account != null) {
            accounts.add(account);
          }
        }
      }
      return accounts;
    } catch (e) {
      print('Error restoring from backup: $e');
      return [];
    }
  }

  /// 从备份文件还原（使用最新的备份）
  static Future<List<Account>> restoreFromBackup() async {
    final backups = await getBackupList();
    if (backups.isEmpty) return [];
    return restoreFromBackupFile(backups.first['path']);
  }

  /// 获取备份文件信息（最新的备份）
  static Future<Map<String, dynamic>?> getBackupInfo() async {
    final backups = await getBackupList();
    if (backups.isEmpty) return null;
    return backups.first;
  }
}
