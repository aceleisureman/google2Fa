import 'dart:convert';
import 'dart:typed_data';

class GoogleAuthAccount {
  final String name;
  final String secret;
  final String issuer;

  GoogleAuthAccount({
    required this.name,
    required this.secret,
    required this.issuer,
  });
}

class GoogleAuthImport {
  /// 解析 Google Authenticator 导出的 otpauth-migration URL
  static List<GoogleAuthAccount> parseOtpAuthMigration(String data) {
    final accounts = <GoogleAuthAccount>[];
    
    try {
      String base64Data;
      
      // 处理 otpauth-migration:// URL 格式
      if (data.startsWith('otpauth-migration://offline?data=')) {
        base64Data = data.substring('otpauth-migration://offline?data='.length);
        base64Data = Uri.decodeComponent(base64Data);
      } else if (data.startsWith('otpauth-migration://')) {
        final uri = Uri.parse(data);
        base64Data = uri.queryParameters['data'] ?? '';
      } else {
        // 尝试直接作为 base64 解析
        base64Data = data;
      }
      
      if (base64Data.isEmpty) return accounts;
      
      // 解码 base64
      final bytes = base64Decode(base64Data);
      
      // 解析 protobuf 数据
      accounts.addAll(_parseProtobuf(bytes));
    } catch (e) {
      print('Error parsing otpauth-migration: $e');
    }
    
    return accounts;
  }

  /// 解析 protobuf 格式的数据
  static List<GoogleAuthAccount> _parseProtobuf(Uint8List bytes) {
    final accounts = <GoogleAuthAccount>[];
    int pos = 0;
    
    while (pos < bytes.length) {
      // 读取 field tag
      final tagResult = _readVarint(bytes, pos);
      if (tagResult == null) break;
      pos = tagResult.newPos;
      
      final fieldNumber = tagResult.value >> 3;
      final wireType = tagResult.value & 0x7;
      
      if (fieldNumber == 1 && wireType == 2) {
        // otp_parameters (repeated message)
        final lengthResult = _readVarint(bytes, pos);
        if (lengthResult == null) break;
        pos = lengthResult.newPos;
        
        final messageBytes = bytes.sublist(pos, pos + lengthResult.value);
        pos += lengthResult.value;
        
        final account = _parseOtpParameters(Uint8List.fromList(messageBytes));
        if (account != null) {
          accounts.add(account);
        }
      } else {
        // 跳过其他字段
        pos = _skipField(bytes, pos, wireType);
        if (pos < 0) break;
      }
    }
    
    return accounts;
  }

  /// 解析单个 OTP 参数
  static GoogleAuthAccount? _parseOtpParameters(Uint8List bytes) {
    String name = '';
    String issuer = '';
    Uint8List? secretBytes;
    int pos = 0;
    
    while (pos < bytes.length) {
      final tagResult = _readVarint(bytes, pos);
      if (tagResult == null) break;
      pos = tagResult.newPos;
      
      final fieldNumber = tagResult.value >> 3;
      final wireType = tagResult.value & 0x7;
      
      if (wireType == 2) {
        // Length-delimited (string or bytes)
        final lengthResult = _readVarint(bytes, pos);
        if (lengthResult == null) break;
        pos = lengthResult.newPos;
        
        final data = bytes.sublist(pos, pos + lengthResult.value);
        pos += lengthResult.value;
        
        switch (fieldNumber) {
          case 1: // secret (bytes)
            secretBytes = Uint8List.fromList(data);
            break;
          case 2: // name (string)
            name = utf8.decode(data);
            break;
          case 3: // issuer (string)
            issuer = utf8.decode(data);
            break;
        }
      } else if (wireType == 0) {
        // Varint
        final varintResult = _readVarint(bytes, pos);
        if (varintResult == null) break;
        pos = varintResult.newPos;
      } else {
        pos = _skipField(bytes, pos, wireType);
        if (pos < 0) break;
      }
    }
    
    if (secretBytes == null || secretBytes.isEmpty) return null;
    
    // 将 secret 转换为 base32
    final secret = _bytesToBase32(secretBytes);
    
    // 解析 name，可能包含 issuer:account 格式
    String accountName = name;
    if (name.contains(':')) {
      final parts = name.split(':');
      if (issuer.isEmpty) {
        issuer = parts[0];
      }
      accountName = parts.length > 1 ? parts[1] : parts[0];
    }
    
    return GoogleAuthAccount(
      name: accountName.trim(),
      secret: secret,
      issuer: issuer.trim(),
    );
  }

  /// 读取 varint
  static ({int value, int newPos})? _readVarint(Uint8List bytes, int pos) {
    int value = 0;
    int shift = 0;
    
    while (pos < bytes.length) {
      final byte = bytes[pos];
      pos++;
      value |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) {
        return (value: value, newPos: pos);
      }
      shift += 7;
      if (shift > 35) return null;
    }
    return null;
  }

  /// 跳过字段
  static int _skipField(Uint8List bytes, int pos, int wireType) {
    switch (wireType) {
      case 0: // Varint
        while (pos < bytes.length && (bytes[pos] & 0x80) != 0) {
          pos++;
        }
        return pos < bytes.length ? pos + 1 : -1;
      case 1: // 64-bit
        return pos + 8;
      case 2: // Length-delimited
        final lengthResult = _readVarint(bytes, pos);
        if (lengthResult == null) return -1;
        return lengthResult.newPos + lengthResult.value;
      case 5: // 32-bit
        return pos + 4;
      default:
        return -1;
    }
  }

  /// 将字节转换为 base32
  static String _bytesToBase32(Uint8List bytes) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final result = StringBuffer();
    
    int buffer = 0;
    int bitsLeft = 0;
    
    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;
      
      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        result.write(alphabet[(buffer >> bitsLeft) & 0x1F]);
      }
    }
    
    if (bitsLeft > 0) {
      result.write(alphabet[(buffer << (5 - bitsLeft)) & 0x1F]);
    }
    
    return result.toString();
  }

  /// 检查是否为有效的 otpauth-migration URL
  static bool isOtpAuthMigration(String data) {
    return data.trim().startsWith('otpauth-migration://');
  }
}
