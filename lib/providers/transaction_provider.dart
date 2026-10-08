import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_27/models/transaction_model.dart';
import 'package:finance_27/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return TransactionNotifier(user?.id);
});

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  StreamSubscription? _sub;

  TransactionNotifier(this._userId) : super([]) {
    _initListener();
  }

  void _initListener() {
    _sub?.cancel();
    if (_userId == null) {
      state = [];
      return;
    }

    _sub = _firestore.collection('users').doc(_userId).collection('transactions').snapshots().listen((snapshot) {
      final transactions = snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data(), doc.id)).toList();
      transactions.sort((a, b) => b.date.compareTo(a.date));
      state = transactions;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void addTransaction(TransactionModel transaction) {
    if (_userId == null) return;
    
    state = [...state, transaction];
    _firestore.collection('users').doc(_userId).collection('transactions').doc(transaction.id).set(transaction.toMap());
  }

  void editTransaction(String id, String newTitle, double newAmount) {
    if (_userId == null) return;
    
    state = state.map((t) {
      if (t.id == id) {
        final updatedTx = t.copyWith(title: newTitle, amount: newAmount);
        _firestore.collection('users').doc(_userId).collection('transactions').doc(id).update(updatedTx.toMap());
        return updatedTx;
      }
      return t;
    }).toList();
  }

  List<TransactionModel> getTransactionsForJar(dynamic jarType) {
    return state.where((t) => t.jarType == jarType).toList();
  }

  void deleteTransaction(String id) {
    if (_userId == null) return;
    
    state = state.where((t) => t.id != id).toList();
    _firestore.collection('users').doc(_userId).collection('transactions').doc(id).delete();
  }

  Future<void> reset() async {
    if (_userId == null) return;
    
    final snapshot = await _firestore.collection('users').doc(_userId).collection('transactions').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
