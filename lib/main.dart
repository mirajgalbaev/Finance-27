import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finance_27/core/app_theme.dart';
import 'package:finance_27/models/jar_model.dart';
import 'package:finance_27/models/task_model.dart';
import 'package:finance_27/models/goal_model.dart';
import 'package:finance_27/models/transaction_model.dart';
import 'package:finance_27/models/income_model.dart';
import 'package:finance_27/models/goal_deposit_model.dart';
import 'package:finance_27/models/reminder_model.dart';
import 'package:finance_27/models/daily_note_model.dart';
import 'package:finance_27/models/trade_model.dart';
import 'package:finance_27/models/user_model.dart';
import 'package:finance_27/ui/screens/splash_screen.dart';
import 'package:finance_27/services/notification_service.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:finance_27/core/localization_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('tr');
  await initializeDateFormatting('ru');
  
  await Hive.initFlutter('Finance27_HiveData');
  
  // Register Adapters
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(JarTypeAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(JarModelAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TaskModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GoalModelAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(TransactionModelAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(IncomeModelAdapter());
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(GoalDepositModelAdapter());
  if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(ReminderModelAdapter());
  if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(DailyNoteModelAdapter());
  if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(TradeModelAdapter());
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(UserModelAdapter());
  
  await NotificationService().initialize();

  // Open Boxes
  Future<void> openBoxSafe<T>(String name) async {
    try {
      await Hive.openBox<T>(name);
    } catch (e) {
      await Hive.deleteBoxFromDisk(name);
      await Hive.openBox<T>(name);
    }
  }

  await openBoxSafe<JarModel>('jars');
  await openBoxSafe<TaskModel>('tasks');
  await openBoxSafe<GoalModel>('goals');
  await openBoxSafe<TransactionModel>('transactions');
  await openBoxSafe<IncomeModel>('incomes');
  await openBoxSafe<ReminderModel>('remindersBox');
  await openBoxSafe<DailyNoteModel>('dailyNotes');
  await openBoxSafe<TradeModel>('tradesBox');
  await openBoxSafe<UserModel>('usersBox');
  await openBoxSafe('authSession');
  await openBoxSafe('settings');

  runApp(
    const ProviderScope(
      child: Finance27App(),
    ),
  );
}

class Finance27App extends ConsumerWidget {
  const Finance27App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    // Use 'ru' for 'kg' as flutter_localizations doesn't support 'kg' natively yet for date pickers
    final materialLocale = currentLocale == 'kg' ? const Locale('ru') : Locale(currentLocale);
    
    // Ensure Intl uses a safe locale
    Intl.defaultLocale = materialLocale.toString();

    return MaterialApp(
      title: 'Kundoluk 27',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: materialLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
        Locale('ru'),
        Locale('kg'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
