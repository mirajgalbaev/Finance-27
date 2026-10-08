import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_27/models/task_model.dart';
import 'package:finance_27/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, List<TaskModel>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return TaskNotifier(user?.id);
});

class TaskNotifier extends StateNotifier<List<TaskModel>> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  StreamSubscription? _sub;

  TaskNotifier(this._userId) : super([]) {
    _initListener();
  }

  void _initListener() {
    _sub?.cancel();
    if (_userId == null) {
      state = [];
      return;
    }

    _sub = _firestore.collection('users').doc(_userId).collection('tasks').snapshots().listen((snapshot) {
      final tasks = snapshot.docs.map((doc) => TaskModel.fromMap(doc.data(), doc.id)).toList();
      state = tasks;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void addTask(String title, {double financialOutcome = 0.0, String? category}) {
    if (_userId == null) return;
    
    final newTask = TaskModel(
      id: _uuid.v4(),
      title: title,
      financialOutcome: financialOutcome,
      date: DateTime.now(),
      category: category,
    );
    
    // Optimistic UI update
    state = [...state, newTask];
    _firestore.collection('users').doc(_userId).collection('tasks').doc(newTask.id).set(newTask.toMap());
  }

  void toggleTask(String id) {
    if (_userId == null) return;
    
    state = state.map((task) {
      if (task.id == id) {
        final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
        _firestore.collection('users').doc(_userId).collection('tasks').doc(id).update({'isCompleted': updatedTask.isCompleted});
        return updatedTask;
      }
      return task;
    }).toList();
  }

  void deleteTask(String id) {
    if (_userId == null) return;
    
    state = state.where((task) => task.id != id).toList();
    _firestore.collection('users').doc(_userId).collection('tasks').doc(id).delete();
  }

  List<TaskModel> getTasksForDate(DateTime date) {
    return state.where((task) => 
      task.date.year == date.year && 
      task.date.month == date.month && 
      task.date.day == date.day
    ).toList();
  }

  Future<void> reset() async {
    if (_userId == null) return;
    
    final snapshot = await _firestore.collection('users').doc(_userId).collection('tasks').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
