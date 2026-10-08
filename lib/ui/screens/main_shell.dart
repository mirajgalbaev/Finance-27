import 'package:flutter/material.dart';
import 'package:finance_27/ui/screens/dashboard_screen.dart';
import 'package:finance_27/ui/screens/planner_screen.dart';
import 'package:finance_27/ui/screens/analytics_screen.dart';
import 'package:finance_27/ui/screens/goals_screen.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/core/localization_provider.dart';
import 'package:finance_27/core/quotes_data.dart';

final tabProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  final List<Widget> _screens = const [
    const DashboardScreen(),
    const PlannerScreen(),
    const AnalyticsScreen(),
    const GoalsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedIndex = ref.watch(tabProvider);

    return Scaffold(
      body: _screens[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          if (index == 0 && ref.read(tabProvider) != 0) {
            ref.read(randomQuoteIndexProvider.notifier).state = Random().nextInt(50);
          }
          ref.read(tabProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: AppStrings.get(ref, 'tab_status')),
          BottomNavigationBarItem(icon: const Icon(Icons.assignment), label: AppStrings.get(ref, 'tab_war_plan')),
          BottomNavigationBarItem(icon: const Icon(Icons.bar_chart), label: AppStrings.get(ref, 'tab_analytics')),
          BottomNavigationBarItem(icon: const Icon(Icons.flag), label: AppStrings.get(ref, 'tab_goals')),
        ],
      ),
    );
  }
}
