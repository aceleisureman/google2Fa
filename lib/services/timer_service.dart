import 'dart:async';
import 'package:flutter/foundation.dart';
import 'totp_service.dart';

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  Timer? _timer;
  int _remainingSeconds = 30;
  int _lastPeriod = 0;

  int get remainingSeconds => _remainingSeconds;

  void start() {
    _updateTime();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _updateTime());
  }

  void _updateTime() {
    final newRemaining = TotpService.getRemainingSeconds();
    final currentPeriod = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    
    if (newRemaining != _remainingSeconds || currentPeriod != _lastPeriod) {
      _remainingSeconds = newRemaining;
      _lastPeriod = currentPeriod;
      notifyListeners();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

final timerService = TimerService();
