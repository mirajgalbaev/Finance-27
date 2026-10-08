import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_27/models/reminder_model.dart';
import 'package:finance_27/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:finance_27/services/notification_service.dart';

final reminderProvider = StateNotifierProvider<ReminderNotifier, List<ReminderModel>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return ReminderNotifier(user?.id);
});

class ReminderNotifier extends StateNotifier<List<ReminderModel>> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  StreamSubscription? _sub;
  
  // Cache completions
  Map<String, bool> _completions = {};
  StreamSubscription? _completionsSub;

  ReminderNotifier(this._userId) : super([]) {
    _initListener();
  }

  void _initListener() {
    _sub?.cancel();
    _completionsSub?.cancel();
    if (_userId == null) {
      state = [];
      _completions = {};
      return;
    }

    _sub = _firestore.collection('users').doc(_userId).collection('reminders').snapshots().listen((snapshot) {
      final reminders = snapshot.docs.map((doc) => ReminderModel.fromMap(doc.data(), doc.id)).toList();
      state = reminders;
    });

    _completionsSub = _firestore.collection('users').doc(_userId).collection('reminders_completions').snapshots().listen((snapshot) {
      final comps = <String, bool>{};
      for (var doc in snapshot.docs) {
        comps[doc.id] = doc.data()['completed'] ?? false;
      }
      _completions = comps;
      // Re-trigger state to update UI
      state = [...state];
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _completionsSub?.cancel();
    super.dispose();
  }

  Future<void> addReminder({
    required String title,
    required DateTime startDate,
    required String timeText,
    required String recurrence,
  }) async {
    if (_userId == null) return;
    
    final newReminder = ReminderModel(
      id: _uuid.v4(),
      title: title,
      startDate: startDate,
      timeText: timeText,
      recurrence: recurrence,
    );
    
    state = [...state, newReminder];
    await _firestore.collection('users').doc(_userId).collection('reminders').doc(newReminder.id).set(newReminder.toMap());

    final timeParts = timeText.split(':');
    if (timeParts.length == 2) {
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      final scheduledDate = DateTime(startDate.year, startDate.month, startDate.day, hour, minute);
      NotificationService().scheduleTaskNotification(newReminder.id, newReminder.title, scheduledDate);
    }
  }

  Future<void> deleteReminder(String id) async {
    if (_userId == null) return;
    
    state = state.where((r) => r.id != id).toList();
    await _firestore.collection('users').doc(_userId).collection('reminders').doc(id).delete();
    NotificationService().cancelNotification(id);
  }

  Future<void> editReminder({
    required String id,
    required String title,
    required DateTime startDate,
    required String timeText,
    required String recurrence,
    bool? isCompleted,
  }) async {
    if (_userId == null) return;
    
    final index = state.indexWhere((r) => r.id == id);
    if (index != -1) {
      final updatedReminder = state[index].copyWith(
        title: title,
        startDate: startDate,
        timeText: timeText,
        recurrence: recurrence,
        isCompleted: isCompleted,
      );
      
      final newState = [...state];
      newState[index] = updatedReminder;
      state = newState;
      
      await _firestore.collection('users').doc(_userId).collection('reminders').doc(id).update(updatedReminder.toMap());

      NotificationService().cancelNotification(id);
      if (isCompleted != true) {
        final timeParts = timeText.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final scheduledDate = DateTime(startDate.year, startDate.month, startDate.day, hour, minute);
          NotificationService().scheduleTaskNotification(id, title, scheduledDate);
        }
      }
    }
  }

  String _getCompletionKey(String id, DateTime date) {
    return '${id}_${date.year}_${date.month}_${date.day}';
  }

  Future<void> toggleCompletionForDate(String id, DateTime date, bool completed) async {
    if (_userId == null) return;
    
    final key = _getCompletionKey(id, date);
    _completions[key] = completed;
    state = [...state]; // trigger UI update
    
    if (completed) {
      await _firestore.collection('users').doc(_userId).collection('reminders_completions').doc(key).set({'completed': true});
      NotificationService().cancelNotification(id);
    } else {
      await _firestore.collection('users').doc(_userId).collection('reminders_completions').doc(key).delete();
      final index = state.indexWhere((r) => r.id == id);
      if (index != -1) {
        final r = state[index];
        final timeParts = r.timeText.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final scheduledDate = DateTime(date.year, date.month, date.day, hour, minute);
          NotificationService().scheduleTaskNotification(id, r.title, scheduledDate);
        }
      }
    }
  }

  Future<void> reset() async {
    if (_userId == null) return;
    
    final batch = _firestore.batch();
    
    final remSnapshot = await _firestore.collection('users').doc(_userId).collection('reminders').get();
    for (var doc in remSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    final compSnapshot = await _firestore.collection('users').doc(_userId).collection('reminders_completions').get();
    for (var doc in compSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  List<ReminderModel> getRemindersForDate(DateTime date) {
    final checkDate = DateTime(date.year, date.month, date.day);

    return state.where((reminder) {
      final start = DateTime(reminder.startDate.year, reminder.startDate.month, reminder.startDate.day);
      if (checkDate.isBefore(start)) return false;
      if (checkDate.isAtSameMomentAs(start)) return true;

      final differenceInDays = checkDate.difference(start).inDays;

      switch (reminder.recurrence) {
        case 'none':
        case '1_day':
          return false;
        case '7_days':
          return differenceInDays <= 7;
        case '1_month':
          return differenceInDays <= 30;
        case '2_months':
          return differenceInDays <= 60;
        default:
          return false;
      }
    }).map((reminder) {
      final key = _getCompletionKey(reminder.id, date);
      final isDoneOnDate = _completions[key] ?? false;
      return reminder.copyWith(isCompleted: isDoneOnDate);
    }).toList();
  }
}
