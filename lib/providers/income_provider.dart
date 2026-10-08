import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_27/models/income_model.dart';
import 'package:finance_27/providers/jar_provider.dart';
import 'package:finance_27/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

final incomeProvider = StateNotifierProvider<IncomeNotifier, List<IncomeModel>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return IncomeNotifier(ref, user?.id);
});

class IncomeNotifier extends StateNotifier<List<IncomeModel>> {
  final Ref _ref;
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  StreamSubscription? _sub;

  IncomeNotifier(this._ref, this._userId) : super([]) {
    _initListener();
  }

  void _initListener() {
    _sub?.cancel();
    if (_userId == null) {
      state = [];
      return;
    }

    _sub = _firestore.collection('users').doc(_userId).collection('incomes').snapshots().listen((snapshot) {
      final incomes = snapshot.docs.map((doc) => IncomeModel.fromMap(doc.data(), doc.id)).toList();
      incomes.sort((a, b) => b.date.compareTo(a.date));
      state = incomes;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void addIncome(double amount, String title, String currency, {DateTime? date}) {
    if (_userId == null || amount <= 0) return;

    final income = IncomeModel(
      id: _uuid.v4(),
      amount: amount,
      date: date ?? DateTime.now(),
      title: title.isEmpty ? 'Income' : title,
      currency: currency,
    );

    _ref.read(jarProvider.notifier).distributeIncome(amount, title: income.title, currency: currency, date: income.date);
    
    state = [income, ...state];
    _firestore.collection('users').doc(_userId).collection('incomes').doc(income.id).set(income.toMap());
  }

  void deleteIncome(String id) {
    if (_userId == null) return;
    
    final incomeIndex = state.indexWhere((i) => i.id == id);
    if (incomeIndex == -1) return;
    
    final income = state[incomeIndex];
    _ref.read(jarProvider.notifier).deleteIncomeTransactions(income);

    state = [...state]..removeAt(incomeIndex);
    _firestore.collection('users').doc(_userId).collection('incomes').doc(id).delete();
  }

  void editIncome(String id, double newAmount, String newTitle, String newCurrency, {DateTime? newDate}) {
    if (_userId == null || newAmount <= 0) return;

    final incomeIndex = state.indexWhere((i) => i.id == id);
    if (incomeIndex == -1) return;

    final oldIncome = state[incomeIndex];
    final difference = newAmount - oldIncome.amount;

    if (oldIncome.currency == newCurrency) {
      if (difference != 0) {
        if (difference > 0) {
          _ref.read(jarProvider.notifier).distributeIncome(difference, title: 'Adjusted ${oldIncome.title}', currency: newCurrency);
        } else {
          _ref.read(jarProvider.notifier).reverseDistribution(-difference, title: 'Adjusted ${oldIncome.title}', currency: newCurrency);
        }
      }
    } else {
      _ref.read(jarProvider.notifier).reverseDistribution(oldIncome.amount, title: 'Reversed ${oldIncome.title}', currency: oldIncome.currency);
      _ref.read(jarProvider.notifier).distributeIncome(newAmount, title: 'Adjusted ${oldIncome.title}', currency: newCurrency);
    }

    final updatedIncome = oldIncome.copyWith(
      amount: newAmount, 
      title: newTitle.isEmpty ? 'Income' : newTitle,
      currency: newCurrency,
      date: newDate ?? oldIncome.date,
    );
    
    final newState = [...state];
    newState[incomeIndex] = updatedIncome;
    state = newState;
    
    _firestore.collection('users').doc(_userId).collection('incomes').doc(id).update(updatedIncome.toMap());
  }

  Future<void> reset() async {
    if (_userId == null) return;
    
    final snapshot = await _firestore.collection('users').doc(_userId).collection('incomes').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
