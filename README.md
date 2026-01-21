# Google 2FA Manager

一个用于管理 Google 账号和 2FA 验证码的 Windows 桌面应用。

## 功能特性

- **账号管理**: 添加、编辑、删除 Google 账号
- **2FA 自动刷新**: 实时显示 TOTP 验证码，每秒自动刷新
- **批量导入**: 支持从文件或文本批量导入账号
- **导出功能**: 将账号导出为文本文件
- **搜索功能**: 快速搜索账号
- **一键复制**: 快速复制密码和验证码
- **时尚 UI**: 现代化深色主题界面

## 账号格式

```
账号----密码----辅助邮箱----2FA密钥
```

示例:
```
example@gmail.com----mypassword123----recovery@mail.com----JBSWY3DPEHPK3PXP
```

## 运行项目

```bash
# 获取依赖
flutter pub get

# 运行 Windows 应用
flutter run -d windows
```

## 构建发布版本

```bash
flutter build windows
```

构建产物位于 `build/windows/runner/Release/` 目录。

## 技术栈

- Flutter 3.x
- Provider (状态管理)
- OTP (TOTP 生成)
- Google Fonts
- Flutter Animate
