import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_27/models/jar_model.dart';
import 'package:finance_27/models/transaction_model.dart';
import 'package:finance_27/providers/transaction_provider.dart';
import 'package:finance_27/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

final jarProvider = StateNotifierProvider<JarNotifier, List<JarModel>>((ref) {
  final user = ref.watch(authProvider).currentUser;
  return JarNotifier(ref, user?.id);
});

class JarNotifier extends StateNotifier<List<JarModel>> {
  final Ref _ref;
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  StreamSubscription? _sub;

  JarNotifier(this._ref, this._userId) : super(JarType.values.map((type) => JarModel(type: type)).toList()) {
    _initListener();
  }

  void _initListener() {
    _sub?.cancel();
    if (_userId == null) {
      state = [];
      return;
    }

    _sub = _firestore.collection('users').doc(_userId).collection('jars').snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        _initializeDefaultJars();
      } else {
        final jars = snapshot.docs.map((doc) => JarModel.fromMap(doc.data())).toList();
        jars.sort((a, b) => a.type.sortOrder.compareTo(b.type.sortOrder));
        state = jars;
      }
    }, onError: (e) {
      if (state.isEmpty) {
        final defaultJars = JarType.values.map((type) => JarModel(type: type)).toList();
        state = defaultJars;
      }
    });
  }

  void _initializeDefaultJars() {
    if (_userId == null) return;
    final defaultJars = JarType.values.map((type) => JarModel(type: type)).toList();
    state = defaultJars;
    final batch = _firestore.batch();
    for (var jar in defaultJars) {
      final ref = _firestore.collection('users').doc(_userId).collection('jars').doc(jar.type.name);
      batch.set(ref, jar.toMap());
    }
    batch.commit();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _updateFirestore(List<JarModel> newState) async {
    if (_userId == null) return;
    // We update the local state optimistically so UI doesn't stutter, then write to firestore
    state = newState;
    final batch = _firestore.batch();
    for (var jar in newState) {
      final docRef = _firestore.collection('users').doc(_userId).collection('jars').doc(jar.type.name);
      batch.set(docRef, jar.toMap());
    }
    await batch.commit();
  }

  void distributeIncome(double amount, {String title = 'Income', String currency = 'USD', DateTime? date}) {
    if (amount <= 0) return;

    final newState = state.map((jar) {
      final added = amount * jar.allocationPercentage;
      if (added > 0) {
        _recordTransaction(added, true, jar.type, title: title, currency: currency, date: date);
      }
      final newBalances = Map<String, double>.from(jar.balances);
      newBalances[currency] = (newBalances[currency] ?? 0.0) + added;
      return jar.copyWith(balances: newBalances);
    }).toList();
    
    _updateFirestore(newState);
  }

  void deleteIncomeTransactions(dynamic income) {
    final txNotifier = _ref.read(transactionProvider.notifier);
    final allTxs = _ref.read(transactionProvider);
    
    final matchingTxs = allTxs.where((t) => 
       t.isIncome && 
       t.currency == income.currency && 
       (t.title == income.title || t.title == income.currency) &&
       (t.date.difference(income.date).inSeconds.abs() < 60)
    ).toList();

    final newState = state.map((jar) {
       final jarTxs = matchingTxs.where((t) => t.jarType == jar.type);
       double amountToRemove = 0.0;
       for (var tx in jarTxs) amountToRemove += tx.amount;
       
       if (amountToRemove > 0) {
         final newBalances = Map<String, double>.from(jar.balances);
         newBalances[income.currency] = (newBalances[income.currency] ?? 0.0) - amountToRemove;
         return jar.copyWith(balances: newBalances);
       }
       return jar;
    }).toList();
    
    for (var tx in matchingTxs) {
       txNotifier.deleteTransaction(tx.id);
    }
    
    _updateFirestore(newState);
  }

  void repairDatabase() {
    final txNotifier = _ref.read(transactionProvider.notifier);
    final allTxs = _ref.read(transactionProvider);

    // 1. Delete Reversals and matching Originals
    final reversals = allTxs.where((t) => t.title.startsWith('Reversed ')).toList();
    final Set<String> idsToDelete = {};
    for (var rev in reversals) {
      idsToDelete.add(rev.id);
      final originalTitle = rev.title.substring(9);
      final original = allTxs.where((t) => 
        t.title == originalTitle &&
        t.isIncome == true &&
        t.jarType == rev.jarType &&
        t.currency == rev.currency &&
        (t.amount - rev.amount).abs() < 0.01
      ).firstOrNull;
      if (original != null) {
        idsToDelete.add(original.id);
      }
    }

    for (var id in idsToDelete) {
      txNotifier.deleteTransaction(id);
    }

    // 2. Recalculate Jar Balances from scratch based on remaining valid transactions
    final validTxs = allTxs.where((t) => !idsToDelete.contains(t.id)).toList();

    final newState = state.map((jar) {
      final newBalances = <String, double>{};
      final jarTxs = validTxs.where((t) => t.jarType == jar.type);
      for (var tx in jarTxs) {
        newBalances[tx.currency] = (newBalances[tx.currency] ?? 0.0) + (tx.isIncome ? tx.amount : -tx.amount);
      }
      return jar.copyWith(balances: newBalances);
    }).toList();

    _updateFirestore(newState);
  }

  void reverseDistribution(double amount, {String title = 'Correction', String currency = 'USD'}) {
    if (amount <= 0) return;

    final newState = state.map((jar) {
      final subtracted = amount * jar.allocationPercentage;
      if (subtracted > 0) {
        _recordTransaction(subtracted, false, jar.type, title: title, currency: currency);
      }
      final newBalances = Map<String, double>.from(jar.balances);
      newBalances[currency] = (newBalances[currency] ?? 0.0) - subtracted;
      return jar.copyWith(balances: newBalances);
    }).toList();
    
    _updateFirestore(newState);
  }

  void updateJarConfigs({
    required Map<JarType, double> percentages,
    required Map<JarType, String?> names,
  }) {
    final total = percentages.values.fold(0.0, (sum, p) => sum + p);
    // Allow slight floating point variances
    if (total < 0.99 || total > 1.01) return;

    final newState = state.map((jar) {
      final newName = names[jar.type]?.trim();
      final hasNewName = newName != null && newName.isNotEmpty;
      final clearName = names.containsKey(jar.type) && !hasNewName;

      return jar.copyWith(
        customPercentage: percentages[jar.type] ?? jar.customPercentage,
        clearCustomName: clearName,
        customName: hasNewName ? newName : null,
      );
    }).toList();
    
    _updateFirestore(newState);
  }

  void addJarIncome(JarType type, double amount, String title, String currency) {
    final newState = state.map((jar) {
      if (jar.type == type) {
        _recordTransaction(amount, true, type, title: title, currency: currency);
        final newBalances = Map<String, double>.from(jar.balances);
        newBalances[currency] = (newBalances[currency] ?? 0.0) + amount;
        return jar.copyWith(balances: newBalances);
      }
      return jar;
    }).toList();
    
    _updateFirestore(newState);
  }

  void recordExpense(JarType type, double amount, String title, String currency) {
    final newState = state.map((jar) {
      if (jar.type == type) {
        _recordTransaction(amount, false, type, title: title, currency: currency);
        final newBalances = Map<String, double>.from(jar.balances);
        newBalances[currency] = (newBalances[currency] ?? 0.0) - amount;
        return jar.copyWith(balances: newBalances);
      }
      return jar;
    }).toList();
    
    _updateFirestore(newState);
  }

  void _recordTransaction(double amount, bool isIncome, JarType type, {String title = 'Transaction', String currency = 'USD', DateTime? date}) {
    final transaction = TransactionModel(
      id: _uuid.v4(),
      amount: amount,
      date: date ?? DateTime.now(),
      isIncome: isIncome,
      jarType: type,
      title: title.isEmpty ? currency : title,
      currency: currency,
    );
    _ref.read(transactionProvider.notifier).addTransaction(transaction);
  }

  void deleteJarTransaction(TransactionModel transaction) {
    final newState = state.map((jar) {
      if (jar.type == transaction.jarType) {
        final newBalances = Map<String, double>.from(jar.balances);
        final currency = transaction.currency;
        if (transaction.isIncome) {
           newBalances[currency] = (newBalances[currency] ?? 0.0) - transaction.amount;
        } else {
           newBalances[currency] = (newBalances[currency] ?? 0.0) + transaction.amount;
        }
        return jar.copyWith(balances: newBalances);
      }
      return jar;
    }).toList();
    
    _ref.read(transactionProvider.notifier).deleteTransaction(transaction.id);
    _updateFirestore(newState);
  }

  void editJarTransaction(TransactionModel oldTx, String newTitle, double newAmount) {
    if (oldTx.amount == newAmount && oldTx.title == newTitle) return;

    final newState = state.map((jar) {
      if (jar.type == oldTx.jarType) {
        double delta = newAmount - oldTx.amount;
        if (!oldTx.isIncome) {
          delta = -delta; // If expense increased, balance should decrease
        }
        final newBalances = Map<String, double>.from(jar.balances);
        final currency = oldTx.currency;
        newBalances[currency] = (newBalances[currency] ?? 0.0) + delta;
        return jar.copyWith(balances: newBalances);
      }
      return jar;
    }).toList();

    _ref.read(transactionProvider.notifier).editTransaction(oldTx.id, newTitle, newAmount);
    _updateFirestore(newState);
  }

  void savePercentagesAndNames(Map<JarType, double> percentages, Map<JarType, String?> names) {
    final newState = state.map((jar) {
      if (!jar.isActive) return jar;
      return jar.copyWith(
        customPercentage: percentages[jar.type],
        customName: names[jar.type],
        clearCustomName: names[jar.type] == null,
      );
    }).toList();
    _updateFirestore(newState);
  }

  void deleteJar(JarType type) {
    final activeJars = state.where((j) => j.isActive).toList();
    if (activeJars.length <= 1) return;
    
    final deletedJar = state.firstWhere((j) => j.type == type);
    final deletedPercent = deletedJar.allocationPercentage;
    
    final newState = state.map((jar) {
      if (jar.type == type) {
        return jar.copyWith(isActive: false, customPercentage: 0.0);
      }
      return jar;
    }).toList();
    
    if (deletedPercent > 0) {
      final firstActive = newState.firstWhere((j) => j.isActive);
      final index = newState.indexOf(firstActive);
      newState[index] = firstActive.copyWith(customPercentage: firstActive.allocationPercentage + deletedPercent);
    }
    
    _updateFirestore(newState);
  }

  void addJar(String name, double percentage) {
    final inactiveJars = state.where((j) => !j.isActive).toList();
    if (inactiveJars.isEmpty) return;
    
    final jarToActivate = inactiveJars.first;
    
    final activeJars = state.where((j) => j.isActive).toList();
    activeJars.sort((a, b) => b.allocationPercentage.compareTo(a.allocationPercentage));
    final largestJar = activeJars.first;
    
    double deductAmount = percentage;
    
    final newState = state.map((jar) {
      if (jar.type == jarToActivate.type) {
        return jar.copyWith(isActive: true, customName: name, customPercentage: percentage);
      }
      if (jar.type == largestJar.type) {
        double newPct = jar.allocationPercentage - deductAmount;
        if (newPct < 0) newPct = 0.0;
        return jar.copyWith(customPercentage: newPct);
      }
      return jar;
    }).toList();
    
    _updateFirestore(newState);
  }

  Future<void> reset() async {
    if (_userId == null) return;
    final batch = _firestore.batch();
    // Keep existing balances, but reset structure
    final newState = state.map((jar) => JarModel(type: jar.type, balances: jar.balances, isActive: true)).toList();
    for (var jar in newState) {
      final ref = _firestore.collection('users').doc(_userId).collection('jars').doc(jar.type.name);
      batch.set(ref, jar.toMap());
    }
    state = newState;
    await batch.commit();
  }
}
