import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_27/providers/auth_provider.dart';

final customMt5SymbolProvider = StateNotifierProvider<CustomMt5SymbolNotifier, List<String>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return CustomMt5SymbolNotifier(user?.id);
});

class CustomMt5SymbolNotifier extends StateNotifier<List<String>> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _sub;

  CustomMt5SymbolNotifier(this._userId) : super([]) {
    _initListener();
  }

  void _initListener() {
    _sub?.cancel();
    if (_userId == null) {
      state = [];
      return;
    }

    _sub = _firestore.collection('users').doc(_userId).collection('settings').doc('mt5_symbols').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final List<dynamic>? saved = snapshot.data()?['list'];
        if (saved != null) {
          state = saved.map((e) => e.toString()).toList();
        } else {
          state = [];
        }
      } else {
        state = [];
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> addSymbol(String symbol) async {
    if (_userId == null) return;
    symbol = symbol.trim().toUpperCase();
    if (state.contains(symbol) || symbol.isEmpty) return;

    final newList = List<String>.from(state)..add(symbol);
    state = newList;

    await _firestore.collection('users').doc(_userId).collection('settings').doc('mt5_symbols').set({
      'list': newList
    }, SetOptions(merge: true));
  }

  Future<void> removeSymbol(String symbol) async {
    if (_userId == null) return;
    symbol = symbol.trim().toUpperCase();
    if (!state.contains(symbol)) return;

    final newList = List<String>.from(state)..remove(symbol);
    state = newList;

    await _firestore.collection('users').doc(_userId).collection('settings').doc('mt5_symbols').set({
      'list': newList
    }, SetOptions(merge: true));
  }
}
