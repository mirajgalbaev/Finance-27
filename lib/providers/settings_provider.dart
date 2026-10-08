import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_27/providers/auth_provider.dart';

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return CurrencyNotifier(user?.id);
});

class CurrencyNotifier extends StateNotifier<String> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _sub;

  CurrencyNotifier(this._userId) : super('USD') {
    _initListener();
  }

  void _initListener() {
    _sub?.cancel();
    if (_userId == null) {
      state = 'USD';
      return;
    }

    _sub = _firestore.collection('users').doc(_userId).collection('settings').doc('general').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        state = snapshot.data()?['currency'] ?? 'USD';
      } else {
        state = 'USD';
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> setCurrency(String currencyCode) async {
    if (_userId == null) return;
    
    state = currencyCode;
    await _firestore.collection('users').doc(_userId).collection('settings').doc('general').set({
      'currency': currencyCode
    }, SetOptions(merge: true));
  }

  Future<void> reset() async {
    if (_userId == null) return;
    
    await _firestore.collection('users').doc(_userId).collection('settings').doc('general').delete();
    state = 'USD';
  }
}
