import 'dart:convert';
import 'package:uuid/uuid.dart';

class Account {
  final String id;
  String email;
  String password;
  String recoveryEmail;
  String totpSecret;
  DateTime createdAt;
  DateTime updatedAt;

  Account({
    String? id,
    required this.email,
    required this.password,
    required this.recoveryEmail,
    required this.totpSecret,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Account copyWith({
    String? email,
    String? password,
    String? recoveryEmail,
    String? totpSecret,
  }) {
    return Account(
      id: id,
      email: email ?? this.email,
      password: password ?? this.password,
      recoveryEmail: recoveryEmail ?? this.recoveryEmail,
      totpSecret: totpSecret ?? this.totpSecret,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'recoveryEmail': recoveryEmail,
      'totpSecret': totpSecret,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      recoveryEmail: json['recoveryEmail'],
      totpSecret: json['totpSecret'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Parse from format: 账号----密码----辅助邮箱----2fa
  static Account? fromImportString(String line) {
    final parts = line.split('----');
    if (parts.length >= 4) {
      return Account(
        email: parts[0].trim(),
        password: parts[1].trim(),
        recoveryEmail: parts[2].trim(),
        totpSecret: parts[3].trim().replaceAll(' ', '').toUpperCase(),
      );
    }
    return null;
  }

  String toExportString() {
    return '$email----$password----$recoveryEmail----$totpSecret';
  }

  static List<Account> fromJsonList(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Account.fromJson(json)).toList();
  }

  static String toJsonList(List<Account> accounts) {
    return json.encode(accounts.map((a) => a.toJson()).toList());
  }
}
