import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finance_27/providers/reminder_provider.dart';

final alarmServiceProvider = Provider<AlarmService>((ref) {
  final service = AlarmService(ref);
  service.init();
  return service;
});

class AlarmService {
  final Ref ref;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _alarmedTaskIds = {};

  AlarmService(this.ref);

  void init() {
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final todayReminders = ref.read(reminderProvider.notifier).getRemindersForDate(now);

    for (var reminder in todayReminders) {
      if (!reminder.isCompleted && reminder.timeText == timeStr) {
        if (!_alarmedTaskIds.contains(reminder.id)) {
           _playDogBark();
           _alarmedTaskIds.add(reminder.id);
        }
      }
    }
  }

  Future<void> _playDogBark() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/dog_bark.ogg'));
    } catch (e) {
      // Ignore errors
    }
  }

  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
  }
}
