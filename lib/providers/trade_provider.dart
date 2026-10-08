import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_27/models/trade_model.dart';
import 'package:finance_27/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

final tradeProvider = StateNotifierProvider<TradeNotifier, List<TradeModel>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return TradeNotifier(user?.id);
});

class TradeNotifier extends StateNotifier<List<TradeModel>> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  StreamSubscription? _sub;

  TradeNotifier(this._userId) : super([]) {
    _initListener();
  }

  void _initListener() {
    _sub?.cancel();
    if (_userId == null) {
      state = [];
      return;
    }

    _sub = _firestore.collection('users').doc(_userId).collection('trades').snapshots().listen((snapshot) {
      final trades = snapshot.docs.map((doc) => TradeModel.fromMap(doc.data(), doc.id)).toList();
      state = trades;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> addTrade({
    required DateTime date,
    required String timeText,
    required String exchange,
    required String market,
    required String pair,
    required String type,
    required String leverage,
    required double capitalAllocated,
    required double entryPrice,
    double? exitPrice,
    double? stopLoss,
    double? takeProfit,
    List<double>? takeProfits,
    List<double>? buyTargets,
    List<double>? sellTargets,
    double? pnlPercent,
    double? pnlAmount,
    String? notes,
    DateTime? exitDate,
  }) async {
    if (_userId == null) return;
    
    final newTrade = TradeModel(
      id: _uuid.v4(),
      date: date,
      timeText: timeText,
      exchange: exchange,
      market: market,
      pair: pair,
      type: type,
      leverage: leverage,
      capitalAllocated: capitalAllocated,
      entryPrice: entryPrice,
      exitPrice: exitPrice,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      takeProfits: takeProfits,
      buyTargets: buyTargets,
      sellTargets: sellTargets,
      pnlPercent: pnlPercent,
      pnlAmount: pnlAmount,
      notes: notes,
      exitDate: exitDate,
    );
    
    state = [...state, newTrade];
    await _firestore.collection('users').doc(_userId).collection('trades').doc(newTrade.id).set(newTrade.toMap());
  }

  Future<void> deleteTrade(String id) async {
    if (_userId == null) return;
    
    state = state.where((t) => t.id != id).toList();
    await _firestore.collection('users').doc(_userId).collection('trades').doc(id).delete();
  }

  Future<void> deleteAllTradesByMarket(String market) async {
    if (_userId == null) return;
    
    final idsToDelete = state.where((t) => t.market.toLowerCase() == market.toLowerCase()).map((t) => t.id).toList();
    state = state.where((t) => t.market.toLowerCase() != market.toLowerCase()).toList();
    
    final batch = _firestore.batch();
    for (var id in idsToDelete) {
      final ref = _firestore.collection('users').doc(_userId).collection('trades').doc(id);
      batch.delete(ref);
    }
    await batch.commit();
  }

  Future<void> editTrade(
    String id, {
    String? exchange,
    String? market,
    String? pair,
    String? type,
    String? leverage,
    double? capitalAllocated,
    double? entryPrice,
    double? exitPrice,
    double? stopLoss,
    double? takeProfit,
    List<double>? takeProfits,
    List<double>? buyTargets,
    List<double>? sellTargets,
    double? pnlPercent,
    double? pnlAmount,
    String? notes,
    DateTime? exitDate,
  }) async {
    if (_userId == null) return;
    
    final tradeIndex = state.indexWhere((t) => t.id == id);
    if (tradeIndex != -1) {
      final trade = state[tradeIndex];
      final updatedTrade = trade.copyWith(
        exchange: exchange,
        market: market,
        pair: pair,
        type: type,
        leverage: leverage,
        capitalAllocated: capitalAllocated,
        entryPrice: entryPrice,
        exitPrice: exitPrice,
        stopLoss: stopLoss,
        takeProfit: takeProfit,
        takeProfits: takeProfits,
        buyTargets: buyTargets,
        sellTargets: sellTargets,
        pnlPercent: pnlPercent,
        pnlAmount: pnlAmount,
        notes: notes,
        exitDate: exitDate,
      );
      
      state = [
        for (final t in state)
          if (t.id == id) updatedTrade else t
      ];
      
      await _firestore.collection('users').doc(_userId).collection('trades').doc(id).update(updatedTrade.toMap());
    }
  }

  List<TradeModel> getTradesForDate(DateTime reqDate) {
    return state.where((t) {
      final entryDateStr = "${t.date.year.toString().padLeft(4, '0')}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}";
      final reqDateStr = "${reqDate.year.toString().padLeft(4, '0')}-${reqDate.month.toString().padLeft(2, '0')}-${reqDate.day.toString().padLeft(2, '0')}";
      final eDate = DateTime.parse(entryDateStr);
      final rDate = DateTime.parse(reqDateStr);

      if (rDate.isBefore(eDate)) return false;

      if (t.exitPrice == null || t.exitDate == null) {
        return true; 
      } else {
        final exitDateStr = "${t.exitDate!.year.toString().padLeft(4, '0')}-${t.exitDate!.month.toString().padLeft(2, '0')}-${t.exitDate!.day.toString().padLeft(2, '0')}";
        final xDate = DateTime.parse(exitDateStr);
        return rDate.isBefore(xDate.add(const Duration(days: 1)));
      }
    }).toList();
  }

  Future<void> reset() async {
    if (_userId == null) return;
    
    final snapshot = await _firestore.collection('users').doc(_userId).collection('trades').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
