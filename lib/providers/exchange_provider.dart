import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_27/providers/auth_provider.dart';

final exchangeProvider = StateNotifierProvider<ExchangeNotifier, List<String>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return ExchangeNotifier(user?.id);
});

class ExchangeNotifier extends StateNotifier<List<String>> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _sub;

  ExchangeNotifier(this._userId) : super(['Binance', 'Bybit', 'OKX', 'Mexc']) {
    _initListener();
  }

  void _initListener() {
    _sub?.cancel();
    if (_userId == null) {
      state = ['Binance', 'Bybit', 'OKX', 'Mexc'];
      return;
    }

    _sub = _firestore.collection('users').doc(_userId).collection('settings').doc('exchanges').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final List<dynamic>? saved = snapshot.data()?['list'];
        if (saved != null) {
          state = List<String>.from(saved);
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> addExchange(String exchange) async {
    final trimmed = exchange.trim();
    if (trimmed.isEmpty || state.contains(trimmed)) return;
    
    final newState = [...state, trimmed];
    state = newState;
    
    if (_userId != null) {
      await _firestore.collection('users').doc(_userId).collection('settings').doc('exchanges').set({
        'list': newState
      });
    }
  }

  Future<void> removeExchange(String exchange) async {
    final newState = state.where((e) => e != exchange).toList();
    state = newState;
    
    if (_userId != null) {
      await _firestore.collection('users').doc(_userId).collection('settings').doc('exchanges').set({
        'list': newState
      });
    }
  }
}
