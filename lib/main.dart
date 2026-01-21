import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';
import 'package:path_provider/path_provider.dart';
import 'providers/account_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/about_dialog.dart';
import 'services/timer_service.dart';

// 单实例检测 - 使用文件锁
File? _lockFile;
RandomAccessFile? _lockFileHandle;

Future<bool> _checkSingleInstance() async {
  try {
    final directory = await getApplicationSupportDirectory();
    final appDir = Directory('${directory.path}\\Google2FAManager');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    final lockPath = '${appDir.path}\\.2fa_manager.lock';
    
    _lockFile = File(lockPath);
    _lockFileHandle = await _lockFile!.open(mode: FileMode.write);
    
    // 尝试获取独占锁
    await _lockFileHandle!.lock(FileLock.exclusive);
    return true;
  } catch (e) {
    // 无法获取锁，说明已有实例运行
    print('Another instance is already running');
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 检查单实例
  if (!await _checkSingleInstance()) {
    exit(0);
  }
  
  // Initialize window manager
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(490, 770),
    minimumSize: Size(490, 770),
    center: true,
    backgroundColor: Color(0xFF0D1117),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Google 2FA Manager',
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setBackgroundColor(const Color(0xFF0D1117));
  });
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class _MyAppState extends State<MyApp> with WindowListener {
  final SystemTray _systemTray = SystemTray();
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initSystemTray();
    timerService.start();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initSystemTray() async {
    try {
      // Try multiple icon paths
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      
      List<String> possiblePaths = [
        '$exeDir\\data\\flutter_assets\\assets\\app_icon.ico',
        '$exeDir/data/flutter_assets/assets/app_icon.ico',
        'assets/app_icon.ico',
      ];
      
      String? iconPath;
      for (var path in possiblePaths) {
        if (File(path).existsSync()) {
          iconPath = path;
          break;
        }
      }
      
      await _systemTray.initSystemTray(
        iconPath: iconPath ?? '',
        toolTip: 'Google 2FA Manager - 双击显示',
      );

      final Menu menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(
          label: 'Google 2FA Manager',
          enabled: false,
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: '显示窗口',
          onClicked: (menuItem) async {
            await windowManager.show();
            await windowManager.focus();
          },
        ),
        MenuItemLabel(
          label: '关于',
          onClicked: (menuItem) async {
            await windowManager.show();
            await windowManager.focus();
            // 延迟显示对话框，确保窗口已显示
            Future.delayed(const Duration(milliseconds: 200), () {
              final context = navigatorKey.currentContext;
              if (context != null) {
                showDialog(
                  context: context,
                  builder: (context) => const AboutAppDialog(),
                );
              }
            });
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: '退出程序',
          onClicked: (menuItem) {
            _isExiting = true;
            _systemTray.destroy();
            exit(0);
          },
        ),
      ]);

      await _systemTray.setContextMenu(menu);

      _systemTray.registerSystemTrayEventHandler((eventName) async {
        if (eventName == kSystemTrayEventClick) {
          // 左键单击显示窗口
          await windowManager.show();
          await windowManager.focus();
        } else if (eventName == kSystemTrayEventRightClick) {
          // 右键点击弹出菜单
          _systemTray.popUpContextMenu();
        }
      });
      
      debugPrint('System tray initialized with icon: $iconPath');
    } catch (e) {
      debugPrint('System tray init failed: $e');
    }
  }

  @override
  void onWindowClose() async {
    if (!_isExiting) {
      // Hide to tray instead of closing
      await windowManager.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AccountProvider()..loadAccounts(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Google 2FA Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A73E8),
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
