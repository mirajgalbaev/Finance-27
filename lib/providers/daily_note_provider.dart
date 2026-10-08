import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_27/models/daily_note_model.dart';
import 'package:finance_27/providers/auth_provider.dart';
import 'package:intl/intl.dart';

final dailyNoteProvider = StateNotifierProvider<DailyNoteNotifier, List<DailyNoteModel>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return DailyNoteNotifier(user?.id);
});

class DailyNoteNotifier extends StateNotifier<List<DailyNoteModel>> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _sub;

  DailyNoteNotifier(this._userId) : super([]) {
    _initListener();
  }

  void _initListener() {
    _sub?.cancel();
    if (_userId == null) {
      state = [];
      return;
    }

    _sub = _firestore.collection('users').doc(_userId).collection('daily_notes').snapshots().listen((snapshot) {
      final notes = snapshot.docs.map((doc) => DailyNoteModel.fromMap(doc.data(), doc.id)).toList();
      state = notes;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> saveNote(DateTime date, String text) async {
    if (_userId == null) return;
    
    final key = _formatDateKey(date);
    
    final note = DailyNoteModel(
      dateKey: key,
      text: text,
      updatedAt: DateTime.now(),
    );
    
    final index = state.indexWhere((n) => n.dateKey == key);
    if (index != -1) {
      final newState = [...state];
      newState[index] = note;
      state = newState;
    } else {
      state = [...state, note];
    }
    
    await _firestore.collection('users').doc(_userId).collection('daily_notes').doc(key).set(note.toMap());
  }

  DailyNoteModel? getNoteForDate(DateTime date) {
    final key = _formatDateKey(date);
    try {
      return state.firstWhere((n) => n.dateKey == key);
    } catch (e) {
      return null;
    }
  }

  Future<void> reset() async {
    if (_userId == null) return;
    
    final snapshot = await _firestore.collection('users').doc(_userId).collection('daily_notes').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
