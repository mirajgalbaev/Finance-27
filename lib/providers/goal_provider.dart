import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_27/models/goal_model.dart';
import 'package:finance_27/models/goal_deposit_model.dart';
import 'package:finance_27/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

final goalProvider = StateNotifierProvider<GoalNotifier, List<GoalModel>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return GoalNotifier(user?.id);
});

class GoalNotifier extends StateNotifier<List<GoalModel>> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  StreamSubscription? _sub;

  GoalNotifier(this._userId) : super([]) {
    _initListener();
  }

  void _initListener() {
    _sub?.cancel();
    if (_userId == null) {
      state = [];
      return;
    }

    _sub = _firestore.collection('users').doc(_userId).collection('goals').snapshots().listen((snapshot) {
      final goals = snapshot.docs.map((doc) => GoalModel.fromMap(doc.data(), doc.id)).toList();
      state = goals;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void addGoal(String title, double targetAmount, DateTime deadline, {bool isFinancial = true, String? currency}) {
    if (_userId == null) return;
    
    final newGoal = GoalModel(
      id: _uuid.v4(),
      title: title,
      targetAmount: targetAmount,
      deadline: deadline,
      isFinancial: isFinancial,
      currency: currency,
    );
    
    state = [...state, newGoal];
    _firestore.collection('users').doc(_userId).collection('goals').doc(newGoal.id).set(newGoal.toMap());
  }

  void addDeposit(String goalId, double amount, String title) {
    if (_userId == null) return;
    
    state = state.map<GoalModel>((goal) {
      if (goal.id == goalId) {
        final newDeposit = GoalDepositModel(
          id: _uuid.v4(),
          amount: amount,
          date: DateTime.now(),
          title: title,
        );
        final newAmount = goal.currentAmount + amount;
        DateTime? newCompletedAt = goal.completedAt;
        if (newCompletedAt == null && newAmount >= goal.targetAmount) {
          newCompletedAt = DateTime.now();
        }

        final updatedGoal = goal.copyWith(
          currentAmount: newAmount,
          deposits: [...goal.deposits, newDeposit],
          completedAt: newCompletedAt,
        );
        
        _firestore.collection('users').doc(_userId).collection('goals').doc(goalId).update(updatedGoal.toMap());
        return updatedGoal;
      }
      return goal;
    }).toList();
  }

  void deleteDeposit(String goalId, String depositId) {
    if (_userId == null) return;
    
    state = state.map<GoalModel>((goal) {
      if (goal.id == goalId) {
        try {
          final deposit = goal.deposits.firstWhere((d) => d.id == depositId);
          final updatedDeposits = goal.deposits.where((d) => d.id != depositId).toList();
          final updatedGoal = goal.copyWith(
            currentAmount: goal.currentAmount - deposit.amount,
            deposits: updatedDeposits,
          );
          
          _firestore.collection('users').doc(_userId).collection('goals').doc(goalId).update(updatedGoal.toMap());
          return updatedGoal;
        } catch (e) {
          return goal; // Deposit not found
        }
      }
      return goal;
    }).toList();
  }

  void deleteGoal(String id) {
    if (_userId == null) return;
    
    state = state.where((goal) => goal.id != id).toList();
    _firestore.collection('users').doc(_userId).collection('goals').doc(id).delete();
  }

  void editGoal(String id, String newTitle, double newTargetAmount, DateTime newDeadline, {bool isFinancial = true, String? currency}) {
    if (_userId == null) return;
    
    state = state.map<GoalModel>((goal) {
      if (goal.id == id) {
        final updatedGoal = goal.copyWith(
          title: newTitle,
          targetAmount: newTargetAmount,
          deadline: newDeadline,
          isFinancial: isFinancial,
          currency: currency,
        );
        
        _firestore.collection('users').doc(_userId).collection('goals').doc(id).update(updatedGoal.toMap());
        return updatedGoal;
      }
      return goal;
    }).toList();
  }

  Future<void> reset() async {
    if (_userId == null) return;
    
    final snapshot = await _firestore.collection('users').doc(_userId).collection('goals').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
