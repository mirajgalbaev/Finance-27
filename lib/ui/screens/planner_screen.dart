import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/providers/task_provider.dart';
import 'package:finance_27/providers/trade_provider.dart';
import 'package:finance_27/ui/screens/daily_trade_journal_screen.dart';
import 'package:finance_27/ui/widgets/task_tile.dart';
import 'package:finance_27/core/localization_provider.dart';
import 'package:finance_27/providers/settings_provider.dart';
import 'package:finance_27/providers/reminder_provider.dart';
import 'package:finance_27/models/reminder_model.dart';
import 'package:finance_27/models/daily_note_model.dart';
import 'package:finance_27/models/trade_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:audioplayers/audioplayers.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(ref, 'weekly_plan')),
        bottom: TabBar(
          controller: _tabController,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          tabs: [
            Tab(text: AppStrings.get(ref, 'overview_tab')),
            Tab(text: AppStrings.get(ref, 'daily_plan_tab')),
            Tab(text: AppStrings.get(ref, 'finance_plan_tab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _OverviewTab(),
          _DailyPlanTab(),
          _FinancePlanTabInner(),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab({Key? key}) : super(key: key);

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  int _selectedMainTabIndex = 0;
  DateTime _overviewDate = DateTime.now();

  Widget _buildMainTabButton(int index, String title) {
    bool isSelected = _selectedMainTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMainTabIndex = index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditReminderDialog(BuildContext context, WidgetRef ref, ReminderModel reminder) {
    String title = reminder.title.contains(' - ') ? reminder.title.substring(reminder.title.indexOf(' - ') + 3) : reminder.title;
    if (title.trim().isEmpty) title = reminder.title;
    String groupTitle = reminder.title.contains(' - ') ? reminder.title.split(' - ').first : '';
    
    TimeOfDay selectedTime = TimeOfDay.now();
    try {
      final parts = reminder.timeText.split(RegExp(r'[: ]'));
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      if (reminder.timeText.toLowerCase().contains('pm') && hour < 12) hour += 12;
      if (reminder.timeText.toLowerCase().contains('am') && hour == 12) hour = 0;
      selectedTime = TimeOfDay(hour: hour, minute: minute);
    } catch (_) {}

    String recurrence = reminder.recurrence;
    final controller = TextEditingController(text: title);
    final groupController = TextEditingController(text: groupTitle);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return Dialog(
              backgroundColor: theme.scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.edit, color: Colors.blueAccent, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(AppStrings.get(ref, 'edit_task') ?? 'GГ¶revi DГјzenle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: groupController,
                        decoration: InputDecoration(
                          labelText: 'Grup AdД± (Opsiyonel)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.cardColor,
                          prefixIcon: const Icon(Icons.folder_open, color: Colors.blueAccent),
                        ),
                        onChanged: (value) => groupTitle = value,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'GГ¶rev AdД±',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.cardColor,
                          prefixIcon: const Icon(Icons.task_alt, color: Colors.blueAccent),
                        ),
                        onChanged: (value) => title = value,
                      ),
                      const SizedBox(height: 24),
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orangeAccent.withOpacity(0.3), width: 1.5),
                          ),
                          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.orangeAccent),
                                  const SizedBox(width: 12),
                                  Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const Icon(Icons.edit, color: Colors.grey, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                              ),
                              child: Text(AppStrings.get(ref, 'cancel') ?? 'Д°ptal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (title.isNotEmpty) {
                                  String finalTitle = groupTitle.isNotEmpty ? '$groupTitle - $title' : title;
                                  ref.read(reminderProvider.notifier).editReminder(
                                    id: reminder.id,
                                    title: finalTitle,
                                    startDate: reminder.startDate,
                                    timeText: selectedTime.format(context),
                                    recurrence: recurrence,
                                    isCompleted: reminder.isCompleted,
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: Colors.blueAccent,
                              ),
                              child: Text(AppStrings.get(ref, 'save_upper') ?? 'KAYDET', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = _overviewDate;
    final displayedTasks = ref.watch(taskProvider.notifier).getTasksForDate(today);
    final theme = Theme.of(context);
    final locale = AppStrings.getDateFormatLocale(ref.watch(localeProvider));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Today's Date Header & Centered Toggle
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   IconButton(icon: const Icon(Icons.chevron_left, color: Colors.blueAccent), onPressed: () => setState(() => _overviewDate = _overviewDate.subtract(const Duration(days: 1)))),
                   Expanded(
                     child: FittedBox(
                       fit: BoxFit.scaleDown,
                       child: Text(DateFormat('MMMM d, yyyy', AppStrings.getDateFormatLocale(locale)).format(_overviewDate), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                     ),
                   ),
                   IconButton(icon: const Icon(Icons.chevron_right, color: Colors.blueAccent), onPressed: () => setState(() => _overviewDate = _overviewDate.add(const Duration(days: 1)))),
                 ],
               ),
               const SizedBox(height: 16),
               Center(
                 child: Container(
                   decoration: BoxDecoration(
                     color: const Color(0xFF1E293B),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.white12),
                   ),
                   padding: const EdgeInsets.all(4),
                   child: Row(
                     mainAxisSize: MainAxisSize.max,
                     children: [
                       _buildMainTabButton(0, AppStrings.get(ref, 'home_page') ?? 'Ana Sayfa'),
                       const SizedBox(width: 4),
                       _buildMainTabButton(1, AppStrings.get(ref, 'daily_plan_tab') ?? 'GГјnlГјk Plan'),
                       const SizedBox(width: 4),
                       _buildMainTabButton(2, AppStrings.get(ref, 'open_trades') ?? 'AГ§Д±k Д°Еџlemler'),
                     ],
                   ),
                 ),
               ),
            ],
          ),
        ),
        
        Expanded(
          child: _selectedMainTabIndex == 0 
          ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      ref.watch(reminderProvider); // rebuild on changes
                      final allReminders = ref.read(reminderProvider.notifier).getRemindersForDate(today);
                      
                      List<ReminderModel> activeReminders = [];
                      List<ReminderModel> completedReminders = [];
                      
                      for (var r in allReminders) {
                        if (r.isCompleted) {
                           completedReminders.add(r);
                        } else {
                           activeReminders.add(r);
                        }
                      }

                      Widget buildReminderList(List<ReminderModel> items, bool isCompleted) {
                         if (items.isEmpty) return const SizedBox.shrink();
                         return Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: items.map((r) {
                              String groupTitle = r.title.contains(' - ') ? r.title.split(' - ').first : '';
                              String subTitle = r.title.contains(' - ') ? r.title.substring(r.title.indexOf(' - ') + 3) : r.title;
                              if (subTitle.trim().isEmpty) subTitle = r.title;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCompleted ? theme.cardColor.withOpacity(0.1) : theme.cardColor.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Checkbox(
                                     value: r.isCompleted,
                                     activeColor: Colors.greenAccent,
                                     checkColor: Colors.black,
                                     onChanged: (val) {
                                        if (val != null) {
                                          ref.read(reminderProvider.notifier).toggleCompletionForDate(r.id, today, val);
                                        }
                                     }
                                  ),
                                  title: Row(
                                    children: [
                                      Text(r.timeText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isCompleted ? Colors.white38 : Colors.blueAccent)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(subTitle, style: TextStyle(
                                           fontSize: 14, 
                                           fontWeight: FontWeight.w600,
                                           color: isCompleted ? Colors.white38 : Colors.white,
                                           decoration: isCompleted ? TextDecoration.lineThrough : null,
                                        )),
                                      ),
                                    ],
                                  ),
                                  subtitle: groupTitle.isNotEmpty ? Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(groupTitle, style: TextStyle(
                                       fontSize: 11, 
                                       fontWeight: FontWeight.bold,
                                       color: isCompleted ? Colors.orangeAccent.withOpacity(0.3) : Colors.orangeAccent
                                    )),
                                  ) : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                         icon: Icon(Icons.edit, size: 18, color: isCompleted ? Colors.blueAccent.withOpacity(0.3) : Colors.blueAccent),
                                         onPressed: () => _showEditReminderDialog(context, ref, r),
                                         padding: EdgeInsets.zero,
                                         constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                         icon: Icon(Icons.delete, size: 18, color: isCompleted ? Colors.redAccent.withOpacity(0.3) : Colors.redAccent),
                                         onPressed: () => ref.read(reminderProvider.notifier).deleteReminder(r.id),
                                         padding: EdgeInsets.zero,
                                         constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                           }).toList(),
                         );
                      }

                      if (activeReminders.isEmpty && completedReminders.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activeReminders.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(AppStrings.get(ref, 'todays_tasks') ?? 'BUGГњNГњN GГ–REVLERД°', style: TextStyle(color: Colors.grey, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                            ),
                            buildReminderList(activeReminders, false),
                          ],
                          
                          if (completedReminders.isNotEmpty) ...[
                            if (activeReminders.isNotEmpty) const Divider(height: 32, color: Colors.white12),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('${AppStrings.get(ref, 'completed_tasks') ?? 'TAMAMLANAN GГ–REVLER'} (${completedReminders.length})', style: const TextStyle(color: Colors.greenAccent, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                            ),
                            buildReminderList(completedReminders, true),
                          ],
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            )
          : _selectedMainTabIndex == 1
              ? PlannerSetupFullScreen(isEmbeddedView: true, embeddedDate: _overviewDate)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _OpenTradesPanel(overviewDate: _overviewDate),
                ),
        ),
      ],
    );
  }
}

class _OpenTradesPanel extends ConsumerStatefulWidget {
  final DateTime overviewDate;
  const _OpenTradesPanel({Key? key, required this.overviewDate}) : super(key: key);

  @override
  ConsumerState<_OpenTradesPanel> createState() => _OpenTradesPanelState();
}

class _OpenTradesPanelState extends ConsumerState<_OpenTradesPanel> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _exportScreenshot() async {
    try {
        final Uint8List? imageBytes = await _screenshotController.capture(pixelRatio: 2.0, delay: const Duration(milliseconds: 100));
        if (imageBytes == null) return;

        
        String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        String fileName = 'DailyTrades_${timestamp}.png';
        
        if (kIsWeb) {
          final blob = html.Blob([imageBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kay?t Basar?l?! PNG Dosyas? indirildi.')), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
          }
        } else {
            Directory dir;
            if (defaultTargetPlatform == TargetPlatform.android) {
                dir = Directory('/storage/emulated/0/Download');
            } else {
                dir = await getApplicationDocumentsDirectory();
            }
            final filePath = '${dir.path}/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(imageBytes);
            if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.macOS) { await Gal.putImage(filePath); } else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Windows Indirilenler Klasorune Kaydedildi: $filePath'), duration: Duration(seconds: 5), backgroundColor: Colors.green)); }
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_png') ?? 'Galeriye Kaydedildi!')));
        }

    } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_failed') ?? 'Kay?t basar?s?z: {error}').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
}

  Widget _buildTpCell(TradeModel t) {
    if (t.market == 'Spot') {
      List<String> lines = [];
      if (t.takeProfit != null) lines.add('в¬‡ ${AppStrings.get(ref, 'buy') ?? 'AlД±m'} 1: ${t.takeProfit}');
      if (t.buyTargets != null && t.buyTargets!.isNotEmpty) {
        for (int i = 0; i < t.buyTargets!.length; i++) {
           lines.add('в¬‡ ${AppStrings.get(ref, 'buy') ?? 'AlД±m'} ${i+2}: ${t.buyTargets![i]}');
        }
      }
      if (t.sellTargets != null && t.sellTargets!.isNotEmpty) {
        for (int i = 0; i < t.sellTargets!.length; i++) {
           lines.add('в¬† ${AppStrings.get(ref, 'sell') ?? 'SatД±Еџ'} ${i+1}: ${t.sellTargets![i]}');
        }
      }
      if (lines.isEmpty) return Text('-');
      return Text(lines.join("\n"), style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.amberAccent));
    } else {
      List<String> tps = [];
      if (t.takeProfit != null) tps.add('TP-1: ${t.takeProfit}');
      if (t.takeProfits != null) {
        for (int i = 0; i < t.takeProfits!.length; i++) {
          tps.add('TP-${i + 2}: ${t.takeProfits![i]}');
        }
      }
      if (tps.isEmpty) return Text('-');
      return Text(tps.join("\n"), style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.greenAccent));
    }
  }

  String _selectedTab = 'Futures';

  Widget _buildTabButton(String title) {
    bool isSelected = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = title),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailySummary(List<TradeModel> exchangeTrades, DateTime date, String exchange) {
    int winCount = 0;
    int lossCount = 0;
    double totalProfit = 0;
    double totalLoss = 0;
    double totalCapital = 0;

    final closedTrades = exchangeTrades.where((t) => 
      t.exitPrice != null && t.exitDate != null && 
      t.exitDate!.year == date.year && t.exitDate!.month == date.month && t.exitDate!.day == date.day
    ).toList();
    
    final openedTodayCount = exchangeTrades.where((t) => t.date.year == date.year && t.date.month == date.month && t.date.day == date.day).length;

    for (var t in closedTrades) {
      final pnl = t.pnlAmount ?? 0;
      if (pnl > 0) {
        winCount++;
        totalProfit += pnl;
      } else if (pnl < 0) {
        lossCount++;
        totalLoss += pnl;
      }
      totalCapital += t.capitalAllocated ?? 0;
    }

    double netPnL = totalProfit + totalLoss;
    final currencySymbol = '\$';
    bool isNetWin = netPnL >= 0;

    if (exchangeTrades.isEmpty) return const SizedBox.shrink();

    Widget buildMetricCard(String label, String value, Color valueColor, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 12, color: Colors.white54), const SizedBox(width: 4)],
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Text('${exchange.toUpperCase()} ' + (AppStrings.get(ref, 'daily_upper') ?? 'GГњNLГњK') + ' $_selectedTab ' + (AppStrings.get(ref, 'summary_upper') ?? 'Г–ZETД°'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: isNetWin ? Colors.green.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  isNetWin ? AppStrings.get(ref, 'day_in_profit') ?? 'GГњN KГ‚RDA' : AppStrings.get(ref, 'day_in_loss') ?? 'GГњN ZARARDA',
                  style: TextStyle(color: isNetWin ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: buildMetricCard(AppStrings.get(ref, 'opened_trades') ?? 'AГ‡ILAN Д°ЕћLEM', '$openedTodayCount', Colors.white, icon: Icons.add_circle_outline)),
              const SizedBox(width: 12),
              Expanded(child: buildMetricCard(AppStrings.get(ref, 'closed_trades') ?? 'KAPANAN Д°ЕћLEM', '${closedTrades.length}', Colors.white, icon: Icons.check_circle_outline)),
              const SizedBox(width: 12),
              Expanded(child: buildMetricCard(AppStrings.get(ref, 'used_margin') ?? 'KULLANILAN MARJД°N', '$currencySymbol${totalCapital.toStringAsFixed(2)}', Colors.orangeAccent, icon: Icons.account_balance_wallet)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: buildMetricCard(AppStrings.get(ref, 'winning_trades') ?? 'KAZANAN Д°ЕћLEM', '$winCount', Colors.greenAccent, icon: Icons.trending_up)),
              const SizedBox(width: 12),
              Expanded(child: buildMetricCard(AppStrings.get(ref, 'losing_trades') ?? 'KAYBEDEN Д°ЕћLEM', '$lossCount', Colors.redAccent, icon: Icons.trending_down)),
              const SizedBox(width: 12),
              Expanded(child: buildMetricCard(AppStrings.get(ref, 'net_profit_loss'), isNetWin ? '+$currencySymbol${netPnL.toStringAsFixed(2)}' : '-$currencySymbol${netPnL.abs().toStringAsFixed(2)}', isNetWin ? Colors.greenAccent : Colors.redAccent, icon: Icons.attach_money)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: buildMetricCard(AppStrings.get(ref, 'money_won') ?? 'KAZANILAN PARA', '+$currencySymbol${totalProfit.toStringAsFixed(2)}', Colors.greenAccent)),
              const SizedBox(width: 12),
              Expanded(child: buildMetricCard(AppStrings.get(ref, 'money_lost') ?? 'KAYBEDД°LEN PARA', '-$currencySymbol${totalLoss.abs().toStringAsFixed(2)}', Colors.redAccent)),
              const SizedBox(width: 12),
              Expanded(child: const SizedBox.shrink()),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
    final currencySymbol = '\$';
    
    final allTrades = ref.watch(tradeProvider);
    final selectedDate = widget.overviewDate;
    
    final displayedTrades = allTrades.where((t) {
      if (t.market.toLowerCase() != _selectedTab.toLowerCase()) return false;
      bool isOpen = t.exitPrice == null;
      bool isOpenedToday = t.date.year == selectedDate.year && t.date.month == selectedDate.month && t.date.day == selectedDate.day;
      bool isClosedToday = t.exitDate != null && t.exitDate!.year == selectedDate.year && t.exitDate!.month == selectedDate.month && t.exitDate!.day == selectedDate.day;
      return isOpen || isOpenedToday || isClosedToday;
    }).toList();

    displayedTrades.sort((a, b) => b.date.compareTo(a.date));

    final activeExchanges = displayedTrades.map((t) => t.exchange).toSet().toList();

    return SingleChildScrollView(
      child: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: const Color(0xFF0F172A),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(AppStrings.get(ref, 'daily_transactions') ?? 'GГњNLГњK Д°ЕћLEMLER', style: TextStyle(color: Colors.orangeAccent, letterSpacing: 1.0, fontWeight: FontWeight.bold, fontSize: 13)),
                  ElevatedButton.icon(
                    onPressed: _exportScreenshot,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text(AppStrings.get(ref, 'export') ?? 'DД±ЕџarД± Aktar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ]
              ),
            ),
        const SizedBox(height: 8),
        // TAB SELECTOR
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildTabButton('Futures'),
                const SizedBox(width: 4),
                _buildTabButton('Spot'),
                  const SizedBox(width: 4),
                  _buildTabButton('MT5'),
              ],
            ),
          ),
        ),
        
        if (activeExchanges.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Aktif $_selectedTab iЕџlemi bulunmamaktadД±r.', style: const TextStyle(color: Colors.white30)),
          ),

        ...activeExchanges.map((exchange) {
          final exchangeTrades = displayedTrades.where((t) => t.exchange == exchange).toList();
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance, color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(exchange.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      headingTextStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                      dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
                      columns: [
                        DataColumn(label: Text(AppStrings.get(ref, 'table_no') ?? 'NO')),
                      DataColumn(label: Text(AppStrings.get(ref, 'table_date') ?? 'TARД°H')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_time') ?? 'SAAT')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_exchange') ?? 'BORSA')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_market') ?? 'PIYASA')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_pair') ?? 'PARД°TE')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_direction') ?? 'YГ–N')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_leverage') ?? 'KALDIRAГ‡')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_capital') ?? 'SERMAYE')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_entry') ?? 'GД°RД°Ећ')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_exit') ?? 'Г‡IKIЕћ')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_sl') ?? 'SL')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_tp') ?? 'TP')),
                        DataColumn(label: Text('P&L %')),
                        DataColumn(label: Text('P&L \$')),
                        DataColumn(label: Text(AppStrings.get(ref, 'table_notes') ?? 'NOTLAR')),
                        DataColumn(label: Text(AppStrings.get(ref, 'edit_upper') ?? 'DГњZENLE')),
                        DataColumn(label: Text(AppStrings.get(ref, 'delete_upper') ?? (AppStrings.get(ref, 'delete_upper') ?? 'SД°L'))),
                      ],
                      rows: exchangeTrades.asMap().entries.map((entry) {
                        int index = entry.key + 1;
                        var t = entry.value;
                        bool isLong = t.type.toLowerCase() == 'long' || t.type.toLowerCase() == 'alД±Еџ';
                        double parsedPnlPct = t.pnlPercent ?? 0;
                        double parsedPnlAmt = t.pnlAmount ?? 0;
                        bool isWin = parsedPnlAmt > 0;
                        
                        String displayDate = DateFormat('dd.MM.yyyy', AppStrings.getDateFormatLocale(locale)).format(t.date);
                        if (t.exitDate != null && (t.date.year != t.exitDate!.year || t.date.month != t.exitDate!.month || t.date.day != t.exitDate!.day)) {
                           displayDate = '${DateFormat('dd.MM', AppStrings.getDateFormatLocale(locale)).format(t.date)} - ${DateFormat('dd.MM', AppStrings.getDateFormatLocale(locale)).format(t.exitDate!)}';
                        }

                        return DataRow(cells: [
                        DataCell(Text(index.toString(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                          DataCell(Text(displayDate, style: const TextStyle(color: Colors.white54))),
                          DataCell(Text(t.timeText)),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_balance, size: 14, color: Colors.amberAccent),
                              const SizedBox(width: 6),
                              Text(t.exchange),
                            ],
                          )),
                          DataCell(Text(t.market)),
                          DataCell(Text((t.pair.toLowerCase() == "belirsiz" || t.pair.toLowerCase() == "undefined" || t.pair == "РќРµ РѕРїСЂРµРґРµР»РµРЅРѕ" || t.pair == "Р‘РµР»РіРёСЃРёР·") ? (AppStrings.get(ref, 'undefined_text') ?? 'Belirsiz') : t.pair, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLong ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isLong ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
                              ),
                              child: Text(t.type.toUpperCase(), style: TextStyle(color: isLong ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                            )
                          ),
                          DataCell(Text(t.leverage, style: const TextStyle(color: Colors.white70))),
                          DataCell(Text('$currencySymbol${t.capitalAllocated}')),
                          DataCell(Text('${t.entryPrice}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(t.exitPrice != null ? '${t.exitPrice}' : (AppStrings.get(ref, 'open_upper') ?? 'AГ‡IK'), style: TextStyle(color: t.exitPrice == null ? Colors.orangeAccent : Colors.white, fontWeight: t.exitPrice == null ? FontWeight.bold : FontWeight.normal))),
                          DataCell(Text(t.stopLoss != null ? '${t.stopLoss}' : '-')),
                          DataCell(_buildTpCell(t)),
                          DataCell(
                            t.exitPrice == null 
                              ? Text(AppStrings.get(ref, 'open_upper') ?? 'AГ‡IK', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))
                              : Text(
                                  parsedPnlPct > 0 ? '+${parsedPnlPct.toStringAsFixed(2)}%' : '${parsedPnlPct.toStringAsFixed(2)}%',
                                  style: TextStyle(color: isWin ? Colors.greenAccent : (parsedPnlPct < 0 ? Colors.redAccent : Colors.white)),
                                )
                          ),
                          DataCell(
                            t.exitPrice == null 
                              ? Text(AppStrings.get(ref, 'open_upper') ?? 'AГ‡IK', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))
                              : Text(
                                  parsedPnlAmt > 0 ? '+$currencySymbol${parsedPnlAmt.toStringAsFixed(2)}' : (parsedPnlAmt < 0 ? '-$currencySymbol${parsedPnlAmt.abs().toStringAsFixed(2)}' : '\$0'),
                                  style: TextStyle(color: isWin ? Colors.greenAccent : (parsedPnlAmt < 0 ? Colors.redAccent : Colors.white), fontWeight: FontWeight.bold),
                                )
                          ),
                          DataCell(SizedBox(width: 150, child: Text(t.notes ?? '', overflow: TextOverflow.ellipsis))),
                          DataCell(
                            IconButton(
                               icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                               onPressed: () {
                                 showDialog(
                                   context: context,
                                   builder: (context) => AddTradeDialog(date: t.date, trade: t),
                                 );
                               },
                            )
                          ),
                          DataCell(
                            IconButton(
                               icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                               onPressed: () => ref.read(tradeProvider.notifier).deleteTrade(t.id),
                            )
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDailySummary(exchangeTrades, widget.overviewDate, exchange),
              ],
            ),
          );
        }).toList(),
      ],
    ))));
  }
}

class _DailyPlanTab extends ConsumerStatefulWidget {
  const _DailyPlanTab({Key? key}) : super(key: key);

  @override
  ConsumerState<_DailyPlanTab> createState() => _DailyPlanTabState();
}



class SubTaskModel {
  String title;
  List<DateTime> dates;
  TimeOfDay time;
  SubTaskModel({required this.title, required this.dates, required this.time});
}

class PlannerSetupFullScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final bool isEmbeddedView;
  final DateTime? embeddedDate;
  const PlannerSetupFullScreen({Key? key, this.initialDate, this.isEmbeddedView = false, this.embeddedDate}) : super(key: key);

  @override
  ConsumerState<PlannerSetupFullScreen> createState() => _PlannerSetupFullScreenState();
}

class _PlannerSetupFullScreenState extends ConsumerState<PlannerSetupFullScreen> {
  List<DateTime> _globalDates = [];
  TimeOfDay _globalTime = TimeOfDay.now();
  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _viewSelectedDate = DateTime.now();
  bool _isDailyTab = true;
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _exportScreenshot() async {
    try {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'exporting') ?? 'DД±Еџa aktarД±lД±yor...'), duration: const Duration(seconds: 2)));
        await Future.delayed(const Duration(milliseconds: 300));
        
        final locale = AppStrings.getDateFormatLocale(ref.read(localeProvider));
        final allReminders = ref.read(reminderProvider);
        final dayRems = ref.read(reminderProvider.notifier).getRemindersForDate(_viewSelectedDate).toList();
        final monthRems = allReminders.where((r) => r.startDate.year == _viewMonth.year && r.startDate.month == _viewMonth.month).toList();
        final activeRems = _isDailyTab ? dayRems : monthRems;
        
        List<ReminderModel> sortedTasks = List.from(activeRems);
        sortedTasks.sort((a, b) => a.startDate.compareTo(b.startDate));

        final widgetToCapture = ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: Localizations(
            locale: const Locale('en', 'US'),
            delegates: const [DefaultMaterialLocalizations.delegate, DefaultWidgetsLocalizations.delegate],
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: MediaQuery(
                data: const MediaQueryData(size: const Size(1080, 1920)),
                child: Theme(
                  data: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0F172A)),
                  child: Container(
                    width: 1080, height: 1920,
                    color: const Color(0xFF0F172A),
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Kundoluk 27', style: TextStyle(color: Colors.amber, fontSize: 48, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 48),
                        _buildSummaryBox(locale, activeRems),
                        const SizedBox(height: 48),
                        if (sortedTasks.isEmpty)
                          Expanded(child: Center(child: Text(AppStrings.get(ref, 'no_tasks_found') ?? 'Seçilen dönem için görev bulunamadı.', style: const TextStyle(color: Colors.white54, fontSize: 32))))
                        else
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildSectionTitle(_isDailyTab ? (AppStrings.get(ref, 'daily_tasks_table') ?? 'GГњNLГњK GГ–REVLER TABLOSU') : (AppStrings.get(ref, 'monthly_tasks_table') ?? 'AYLIK GГ–REVLER TABLOSU')),
                                  const SizedBox(height: 24),
                                  _buildTaskDataTable(ref, sortedTasks, locale, isEmbedded: false, viewDate: _isDailyTab ? _viewSelectedDate : null),
                                ]
                              )
                            )
                          )
                      ]
                    )
                  )
                )
              )
            )
          )
        );

        final Uint8List? imageBytes = await _captureOffScreenWidget(widgetToCapture);
        if (imageBytes == null) return;
        
        String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        String fileName = 'DailyPlan_${timestamp}.png';
        
        if (kIsWeb) {
          final blob = html.Blob([imageBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)..setAttribute("download", fileName)..click();
          html.Url.revokeObjectUrl(url);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kay?t Basar?l?! PNG Dosyas? indirildi.')), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
        } else {
            Directory dir;
            if (defaultTargetPlatform == TargetPlatform.android) {
                dir = Directory('/storage/emulated/0/Download');
            } else {
                dir = await getApplicationDocumentsDirectory();
            }
            final filePath = '${dir.path}/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(imageBytes);
            if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.macOS) { await Gal.putImage(filePath); } else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Windows Indirilenler Klasorune Kaydedildi: $filePath'), duration: Duration(seconds: 5), backgroundColor: Colors.green)); }
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_png') ?? 'Galeriye Kaydedildi!')));
        }
    } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_failed') ?? 'Kay?t basar?s?z: {error}').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  Widget _buildSummaryBox(String locale, List<ReminderModel> monthReminders) {
    int total = monthReminders.length;
    int completedCount = monthReminders.where((r) => r.isCompleted).length;
    int pendingCount = total - completedCount;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(AppStrings.get(ref, 'task_stats') ?? 'GÖREV İSTATİSTİKLERİ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(DateFormat(_isDailyTab ? 'dd MMMM yyyy' : 'MMMM yyyy', locale).format(_isDailyTab ? _viewSelectedDate : _viewMonth), style: const TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem((AppStrings.get(ref, 'total_task') ?? 'Toplam Görev').replaceAll('\n', ' '), total.toString(), Colors.blueAccent),
                  const SizedBox(width: 16),
                  _buildStatItem(AppStrings.get(ref, 'completed_task') ?? 'Tamamlanan', completedCount.toString(), Colors.greenAccent),
                  const SizedBox(width: 16),
                  _buildStatItem(AppStrings.get(ref, 'pending_task') ?? 'Bekleyen', pendingCount.toString(), Colors.orangeAccent),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }


  final TextEditingController _titleController = TextEditingController();
  List<SubTaskModel> _subTasks = [];
  List<String> _savedTemplates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    if (widget.initialDate != null) {
      _globalDates = [widget.initialDate!];
      _viewSelectedDate = widget.initialDate!;
      _viewMonth = DateTime(widget.initialDate!.year, widget.initialDate!.month, 1);
    } else {
      _globalDates = [DateTime.now()];
    }
  }


  Future<void> _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedTemplates = prefs.getStringList('planner_templates') ?? [];
    });
  }

  Future<void> _saveTemplate() async {
    final text = _titleController.text.trim();
    if (text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Г–nce ana plan baЕџlД±ДџД±nД± yazД±n.')));
       return;
    }
    if (!_savedTemplates.contains(text)) {
      _savedTemplates.add(text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('planner_templates', _savedTemplates);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ећablon Kaydedildi!'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu Еџablon zaten kayД±tlД±.')));
    }
  }

  void _showTemplatesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppStrings.get(ref, 'saved_templates') ?? 'KayД±tlД± Ећablonlar', style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: _savedTemplates.isEmpty 
              ? const Text('KayД±tlД± Еџablon yok.', style: TextStyle(color: Colors.white54))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _savedTemplates.length,
                  itemBuilder: (context, index) {
                    final t = _savedTemplates[index];
                    return ListTile(
                      title: Text(t, style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        setState(() => _titleController.text = t);
                        Navigator.pop(ctx);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          setDialogState(() => _savedTemplates.removeAt(index));
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setStringList('planner_templates', _savedTemplates);
                        }
                      )
                    );
                  }
                )
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get(ref, 'cancel') ?? 'Д°ptal', style: const TextStyle(color: Colors.grey)))
          ]
        )
      )
    );
  }

  void _savePlan() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('LГјtfen Ana Plan baЕџlД±ДџД± girin')));
      return;
    }

    if (_subTasks.isEmpty) {
      for (var date in _globalDates) {
        ref.read(reminderProvider.notifier).addReminder(
          title: title,
          startDate: date,
          timeText: _globalTime.format(context),
          recurrence: 'none'
        );
      }
    } else {
      for (var st in _subTasks) {
        for (var date in st.dates) {
          ref.read(reminderProvider.notifier).addReminder(
            title: title + ' - ' + st.title,
            startDate: date,
            timeText: st.time.format(context),
            recurrence: 'none'
          );
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'sub_tasks_added') ?? 'Plan Eklendi!'), backgroundColor: Colors.green));
    setState(() {
      _titleController.clear();
      _subTasks.clear();
    });
  }

  void _showAddSubTaskDialog() {
    String subTitle = '';
    TimeOfDay stTime = _globalTime;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppStrings.get(ref, 'add_task') ?? 'Alt GГ¶rev Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: AppStrings.get(ref, 'sub_task_upper') ?? 'Alt GГ¶rev AdД±'),
                onChanged: (val) => subTitle = val,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(AppStrings.get(ref, 'time_label') ?? 'Saat:', style: const TextStyle(color: Colors.white70)),
                  TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(context: context, initialTime: stTime);
                      if (time != null) setDialogState(() => stTime = time);
                    },
                    child: Text(stTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get(ref, 'cancel') ?? 'Д°ptal')),
            ElevatedButton(
              onPressed: () {
                if (subTitle.isNotEmpty) {
                  setState(() {
                    _subTasks.add(SubTaskModel(title: subTitle, dates: List.from(_globalDates), time: stTime));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: Text(AppStrings.get(ref, 'save') ?? 'Kaydet')
            )
          ],
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
    final allReminders = ref.watch(reminderProvider);

    final dayRems = ref.read(reminderProvider.notifier).getRemindersForDate(_viewSelectedDate).toList();
    final monthRems = allReminders.where((r) => r.startDate.year == _viewMonth.year && r.startDate.month == _viewMonth.month).toList();
    final activeRems = _isDailyTab ? dayRems : monthRems;
    
    String displayDates = _globalDates.isEmpty 
      ? '' 
      : _globalDates.map((d) => DateFormat('dd MMM yyyy', locale).format(d)).join(', ');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(AppStrings.get(ref, 'planner_setup') ?? 'РќР°СЃС‚СЂРѕР№РєР° РїР»Р°РЅРёСЂРѕРІС‰РёРєР°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAB308),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_task),
            label: Text(AppStrings.get(ref, 'add_plan') ?? 'Р”РћР‘РђР’РРўР¬ РџР›РђРќ', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            onPressed: _savePlan,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () async {
                final dates = await showDialog<List<DateTime>>(
                  context: context,
                  builder: (ctx) => MultiDateSelectionDialog(initialDates: _globalDates)
                );
                if (dates != null) {
                  setState(() => _globalDates = dates);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(displayDates.isEmpty ? 'Tarih SeГ§in' : displayDates, style: const TextStyle(color: Colors.white, fontSize: 14))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.title, color: Colors.blueAccent, size: 20),
                        hintText: AppStrings.get(ref, 'main_plan_title') ?? 'Р—Р°РіРѕР»РѕРІРѕРє РћСЃРЅРѕРІРЅРѕРіРѕ РџР»Р°РЅР°',
                        hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.access_time, color: Colors.redAccent),
                    onPressed: () async {
                      final time = await showTimePicker(context: context, initialTime: _globalTime);
                      if (time != null) setState(() => _globalTime = time);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.save, color: Colors.blueAccent),
                    onPressed: _saveTemplate,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.list_alt, color: Colors.orangeAccent),
                    onPressed: _showTemplatesDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(AppStrings.get(ref, 'sub_tasks') ?? 'РџРѕРґР·Р°РґР°С‡Рё', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                TextButton.icon(
                  onPressed: _showAddSubTaskDialog,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 18),
                  label: Text(AppStrings.get(ref, 'add_task') ?? 'Р”РћР‘РђР’РРўР¬ Р—РђР”РђР§РЈ', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text(AppStrings.get(ref, 'sub_task_info') ?? 'Р•СЃР»Рё РІС‹ РЅРµ РґРѕР±Р°РІРёС‚Рµ РїРѕРґР·Р°РґР°С‡Сѓ, Р“Р»Р°РІРЅС‹Р№ РїР»Р°РЅ Р±СѓРґРµС‚ РґРѕР±Р°РІР»РµРЅ РЅР° РІС‹Р±СЂР°РЅРЅС‹Рµ РґРЅРё.', style: const TextStyle(color: Colors.blueAccent, fontStyle: FontStyle.italic, fontSize: 11)),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 16),
            if (_subTasks.isNotEmpty) ...[
              ..._subTasks.map((st) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, color: Colors.white54, size: 16),
                    const SizedBox(width: 12),
                    Expanded(child: Text(st.title, style: const TextStyle(color: Colors.white))),
                    Text(st.time.format(context), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.redAccent, size: 18), onPressed: () => setState(() => _subTasks.remove(st)))
                  ],
                ),
              )).toList(),
              const SizedBox(height: 16),
            ],
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDailyTab = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isDailyTab ? const Color(0xFFEAB308) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(AppStrings.get(ref, 'daily_upper') ?? 'Р•Р–Р•Р”РќР•Р’РќРћ', style: TextStyle(color: _isDailyTab ? Colors.black : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDailyTab = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isDailyTab ? const Color(0xFFEAB308) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(AppStrings.get(ref, 'monthly_upper') ?? 'Р•Р–Р•РњР•РЎРЇР§РќРћ', style: TextStyle(color: !_isDailyTab ? Colors.black : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      if (_isDailyTab) {
                        _viewSelectedDate = _viewSelectedDate.subtract(const Duration(days: 1));
                      } else {
                        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
                      }
                    });
                  }
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _isDailyTab ? _viewSelectedDate : _viewMonth,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) {
                        setState(() {
                          if (_isDailyTab) {
                            _viewSelectedDate = selected;
                          } else {
                            _viewMonth = DateTime(selected.year, selected.month, 1);
                          }
                        });
                      }
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(_isDailyTab ? 'dd MMMM yyyy' : 'MMMM yyyy', locale).format(_isDailyTab ? _viewSelectedDate : _viewMonth).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      icon: const Icon(Icons.download, size: 14),
                      label: Text(AppStrings.get(ref, 'export_title') ?? 'DД±Еџa Aktar', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _exportScreenshot,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          if (_isDailyTab) {
                            _viewSelectedDate = _viewSelectedDate.add(const Duration(days: 1));
                          } else {
                            _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
                          }
                        });
                      }
                    ),
                  ]
                )
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryBox(locale, activeRems),
            const SizedBox(height: 24),
            Builder(
              builder: (ctx) {
                if (activeRems.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32), 
                    child: Center(
                      child: Text(AppStrings.get(ref, 'no_tasks_found') ?? 'Seçilen dönem için görev bulunamadı.', style: const TextStyle(color: Colors.white54))
                    )
                  );
                }
                List<ReminderModel> sortedTasks = List.from(activeRems);
                sortedTasks.sort((a, b) => a.startDate.compareTo(b.startDate));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle(_isDailyTab ? (AppStrings.get(ref, 'daily_tasks_table') ?? 'GГњNLГњK GГ–REVLER TABLOSU') : (AppStrings.get(ref, 'monthly_tasks_table') ?? 'AYLIK GГ–REVLER TABLOSU')),
                    const SizedBox(height: 12),
                    _buildTaskDataTable(ref, sortedTasks, locale, isEmbedded: widget.isEmbeddedView, viewDate: _isDailyTab ? _viewSelectedDate : null),
                    const SizedBox(height: 24),
                  ]
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  void _exportPlanner() {
    _exportScreenshot();
  }

  void _showEditReminderDialog(BuildContext context, dynamic t) {
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DГјzenleme geГ§ici olarak devre dД±ЕџД±.')));
  }

  Widget _buildActionButtons(List<ReminderModel> activeRems) {
     return Row(
       mainAxisAlignment: MainAxisAlignment.end,
       children: [
          ElevatedButton.icon(
             onPressed: () {
                 showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                       backgroundColor: Theme.of(context).cardColor,
                       title: Text((AppStrings.get(ref, 'delete_all') ?? 'TГјmГјnГј Sil'), style: TextStyle(color: Colors.white)),
                       content: Text(AppStrings.get(ref, 'confirm_delete_all_tasks') ?? 'Listedeki tГјm gГ¶revler silinecek! OnaylД±yor musunuz?', style: TextStyle(color: Colors.white70)),
                       actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get(ref, 'cancel_upper') ?? 'Д°PTAL', style: TextStyle(color: Colors.grey))),
                          ElevatedButton(
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                             onPressed: () {
                                for (var r in activeRems) {
                                   ref.read(reminderProvider.notifier).deleteReminder(r.id);
                                }
                                Navigator.pop(ctx);
                             }, 
                             child: Text(AppStrings.get(ref, 'delete_all_upper') ?? 'TГњMГњNГњ SД°L', style: TextStyle(color: Colors.white))
                          )
                       ]
                    )
                 );
             },
             icon: const Icon(Icons.delete_sweep, color: Colors.white),
             label: Text((AppStrings.get(ref, 'delete_upper') ?? 'SД°L'), style: TextStyle(color: Colors.white)),
             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
             onPressed: _exportPlanner,
             icon: const Icon(Icons.download, color: Colors.white),
             label: Text((AppStrings.get(ref, 'export_title') ?? 'DД±Еџa Aktar'), style: TextStyle(color: Colors.white)),
             style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
       ]
     );
  }

  Widget _buildTaskDataTable(WidgetRef ref, List<ReminderModel> tasks, String locale, {bool isEmbedded = false, DateTime? viewDate}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingTextStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
          columns: [
            DataColumn(label: Text(AppStrings.get(ref, 'table_no') ?? 'NO')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_no') ?? 'NO')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_date') ?? 'TARД°H')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_time') ?? 'SAAT')),
            DataColumn(label: Text(AppStrings.get(ref, 'main_template_upper') ?? 'ANA ЕћABLON')),
            DataColumn(label: Text(AppStrings.get(ref, 'sub_task_upper') ?? 'ALT GГ–REV')),
            DataColumn(label: Text(AppStrings.get(ref, 'status_action_upper') ?? 'DURUM (Д°ЕћLEM)')),
            if (!isEmbedded) ...[
              DataColumn(label: Text(AppStrings.get(ref, 'edit_upper') ?? 'DГњZENLE')),
              DataColumn(label: Text(AppStrings.get(ref, 'delete_upper') ?? (AppStrings.get(ref, 'delete_upper') ?? 'SД°L'))),
            ]
          ],
          rows: tasks.asMap().entries.map((e) {
            final int index = e.key + 1;
            final t = e.value;
            String displayDate = DateFormat('dd.MM.yyyy', AppStrings.getDateFormatLocale(locale)).format(t.startDate);
            String mainTitle = t.title.contains(' - ') ? t.title.split(' - ').first : t.title;
            String subTitle = t.title.contains(' - ') ? t.title.substring(t.title.indexOf(' - ') + 3) : '-';

            return DataRow(cells: [
                        DataCell(Text(index.toString(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
              DataCell(Text(index.toString(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
              DataCell(Text(displayDate, style: const TextStyle(color: Colors.white54))),
              DataCell(Text(t.timeText, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))),
              DataCell(Text(mainTitle, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(SizedBox(width: 150, child: Text(subTitle, overflow: TextOverflow.ellipsis, style: TextStyle(color: t.isCompleted ? Colors.greenAccent : Colors.white, decoration: t.isCompleted ? TextDecoration.lineThrough : null)))),
              DataCell(
                 InkWell(
                   onTap: () {
                       DateTime targetDate = viewDate ?? t.startDate;
                       ref.read(reminderProvider.notifier).toggleCompletionForDate(
                          t.id, 
                          targetDate, 
                          !t.isCompleted
                       );
                   },
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: t.isCompleted ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                       borderRadius: BorderRadius.circular(6),
                       border: Border.all(color: t.isCompleted ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
                     ),
                     child: Text(t.isCompleted ? (AppStrings.get(ref, 'completed_upper') ?? 'TAMAMLANDI') : (AppStrings.get(ref, 'open_pending') ?? 'AГ‡IK (BEKLД°YOR)'), style: TextStyle(color: t.isCompleted ? Colors.green : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                   )
                 )
              ),
              if (!isEmbedded) ...[
                DataCell(
                  IconButton(
                     icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                     onPressed: () => _showEditReminderDialog(context, t),
                  )
                ),
                DataCell(
                  IconButton(
                     icon: const Icon(Icons.delete, color: Colors.white30, size: 18),
                     onPressed: () => ref.read(reminderProvider.notifier).deleteReminder(t.id),
                  )
                ),
              ]
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Color _getPerformanceColor(double ratio) {
     if (ratio >= 0.8) return Colors.greenAccent;
     if (ratio >= 0.5) return Colors.orangeAccent;
     return Colors.redAccent;
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        const Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
      ]
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, height: 1.2)),
      ],
    );
  }
}

class MultiDateSelectionDialog extends ConsumerStatefulWidget {
  final List<DateTime> initialDates;
  const MultiDateSelectionDialog({Key? key, required this.initialDates}) : super(key: key);

  @override
  ConsumerState<MultiDateSelectionDialog> createState() => _MultiDateSelectionDialogState();
}

class _MultiDateSelectionDialogState extends ConsumerState<MultiDateSelectionDialog> {
  late List<DateTime> _selectedDates;
  late DateTime _currentMonth;
  DateTime? _rangeStart;

  @override
  void initState() {
    super.initState();
    _selectedDates = List.from(widget.initialDates);
    if (_selectedDates.isNotEmpty) {
      _currentMonth = DateTime(_selectedDates.first.year, _selectedDates.first.month, 1);
    } else {
      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    }
  }

  void _toggleDate(DateTime date) {
    setState(() {
      final existingIndex = _selectedDates.indexWhere((d) => d.year == date.year && d.month == date.month && d.day == date.day);
      if (existingIndex >= 0) {
        _selectedDates.removeAt(existingIndex);
      } else {
        _selectedDates.add(date);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    int offset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    int totalCells = offset + daysInMonth > 35 ? 42 : 35;

    final theme = Theme.of(context);
    final String locale = ref.watch(localeProvider) ?? "tr_TR";

    // FIX OVERFLOW via SingleChildScrollView around Column, and properly size AlertDialog
    return AlertDialog(
      title: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text((AppStrings.get(ref, 'select_days') ?? (AppStrings.get(ref, 'select_days') ?? 'GГјnleri SeГ§in')), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text((AppStrings.get(ref, 'select_range_hint') ?? 'AralД±k seГ§mek iГ§in Г¶nce ilk gГјne Г§ift dokunun, sonra bitiЕџe dokunun.'), style: TextStyle(fontSize: 11, color: Colors.grey)),
         ]
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: theme.cardColor,
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1); _rangeStart = null; })),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(DateFormat('MMMM yyyy', AppStrings.getDateFormatLocale(ref.watch(localeProvider) ?? 'tr_TR')).format(_currentMonth).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1); _rangeStart = null; })),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, childAspectRatio: 1.0, crossAxisSpacing: 4, mainAxisSpacing: 4,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  int day = index - offset + 1;
                  if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
                  
                  DateTime cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                  bool isSelected = _selectedDates.any((d) => d.year == cellDate.year && d.month == cellDate.month && d.day == cellDate.day);
                  bool isRangeStart = _rangeStart != null && cellDate.year == _rangeStart!.year && cellDate.month == _rangeStart!.month && cellDate.day == _rangeStart!.day;
                  
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (_rangeStart != null) {
                         DateTime start = _rangeStart!.isBefore(cellDate) ? _rangeStart! : cellDate;
                         DateTime end = _rangeStart!.isBefore(cellDate) ? cellDate : _rangeStart!;
                         setState(() {
                            DateTime current = start;
                            while(current.isBefore(end) || current.isAtSameMomentAs(end)) {
                               bool exists = _selectedDates.any((d) => d.year == current.year && d.month == current.month && d.day == current.day);
                               if (!exists) _selectedDates.add(current);
                               current = current.add(const Duration(days: 1));
                            }
                            _rangeStart = null;
                         });
                      } else {
                         _toggleDate(cellDate);
                      }
                    },
                    onDoubleTap: () {
                      setState(() {
                         if (isRangeStart) {
                            _rangeStart = null;
                         } else {
                            _rangeStart = cellDate;
                         }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor : (isRangeStart ? Colors.orangeAccent : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? theme.primaryColor : (isRangeStart ? Colors.orangeAccent : Colors.grey.withOpacity(0.2))),
                      ),
                      alignment: Alignment.center,
                      child: Text(day.toString(), style: TextStyle(color: isSelected || isRangeStart ? Colors.white : (theme.textTheme.bodyMedium?.color ?? Colors.white), fontWeight: isSelected || isRangeStart ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.get(ref, 'cancel_upper') ?? 'Д°PTAL', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedDates), 
          style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
          child: Text(AppStrings.get(ref, 'save_upper') ?? 'KAYDET')
        ),
      ],
    );
  }


}


class _DailyPlanTabState extends ConsumerState<_DailyPlanTab> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
    final allReminders = ref.watch(reminderProvider);

    // Filter by selected current month to display full tables underneath
    final monthReminders = allReminders
       .where((r) => r.startDate.year == _currentMonth.year && r.startDate.month == _currentMonth.month)
       .map((r) => ref.read(reminderProvider.notifier).getRemindersForDate(r.startDate).firstWhere((element) => element.id == r.id, orElse: () => r))
       .toList();
    monthReminders.sort((a, b) => a.startDate.compareTo(b.startDate));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Container(
                  height: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const PlannerSetupFullScreen()));
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text((AppStrings.get(ref, 'planner_setup') ?? 'Planner Setup').toUpperCase(), style: TextStyle(color: Colors.grey, letterSpacing: 2.0, fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.blueAccent, size: 32),
                          ),
                          const SizedBox(height: 12),
                          Text(AppStrings.get(ref, 'add_new_task') ?? 'Yeni GГ¶rev Ekle', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ),
               ),
               const SizedBox(height: 24),
               
               // Finance Plan Style Header
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1))),
                   Expanded(
                     child: InkWell(
                       onTap: () async {
                          final date = await showDatePicker(
                             context: context,
                             initialDate: _currentMonth,
                             firstDate: DateTime(2000),
                             lastDate: DateTime(2100),
                             initialDatePickerMode: DatePickerMode.year,
                             builder: (context, child) => Theme(
                                data: ThemeData.dark().copyWith(
                                   colorScheme: const ColorScheme.dark(
                                      primary: Colors.blueAccent,
                                      onPrimary: Colors.white,
                                      surface: Color(0xFF1E293B),
                                      onSurface: Colors.white,
                                   ),
                                ),
                                child: child!,
                             ),
                          );
                          if (date != null) {
                             setState(() => _currentMonth = DateTime(date.year, date.month, 1));
                          }
                       },
                       borderRadius: BorderRadius.circular(8),
                       child: Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                         child: FittedBox(
                           fit: BoxFit.scaleDown,
                           child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(DateFormat('MM', AppStrings.getDateFormatLocale(locale)).format(_currentMonth), style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey)),
                              const SizedBox(width: 8),
                              Text(DateFormat('MMMM', AppStrings.getDateFormatLocale(locale)).format(_currentMonth).toUpperCase(), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w300, letterSpacing: 4)),
                              const SizedBox(width: 8),
                              Text(DateFormat('yyyy', AppStrings.getDateFormatLocale(locale)).format(_currentMonth), style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey)),
                            ],
                           ),
                         ),
                       ),
                     ),
                   ),
                   IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1))),
                 ],
               ),
               const SizedBox(height: 8),
               
               // Days of week
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: AppStrings.getTranslatedDays(locale).map((day) {
                    return Expanded(
                      child: Container(
                        color: theme.brightness == Brightness.dark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(day, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
               const SizedBox(height: 4),

               // Finance Styled Calendar
               _buildFinanceStyleCalendarGrid(allReminders),
               const SizedBox(height: 32),

               if (monthReminders.isNotEmpty) ...[
                 _buildActionButtons(monthReminders),
                 const SizedBox(height: 16),
               ],
               
               Screenshot(
                  controller: _screenshotController,
                  child: Container(
                     color: theme.scaffoldBackgroundColor,
                     padding: const EdgeInsets.all(8.0),
                     child: Column(
                        children: [
                           // Daily Summary
                           _buildDailySummaryBox(locale, monthReminders),
                           const SizedBox(height: 32),

                           // Tables
                           if (monthReminders.isNotEmpty) ...[
                             _buildSectionTitle((AppStrings.get(ref, 'monthly_tasks_table') ?? 'AYLIK GГ–REVLER TABLOSU')),
                             const SizedBox(height: 12),
                             _buildTaskDataTable(ref, monthReminders, locale),
                             const SizedBox(height: 32),
                           ],
                           
                           if (monthReminders.isEmpty)
                              Center(child: Padding(padding: EdgeInsets.all(32), child: Text(AppStrings.get(ref, 'no_monthly_tasks') ?? 'Bu aya ait gГ¶rev bulunamadД±.', style: TextStyle(color: Colors.white30, fontSize: 16)))),
                        ]
                     )
                  )
               ),

               const SizedBox(height: 64),
            ]
         )
      )
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        const Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
      ]
    );
  }

  Widget _buildTaskDataTable(WidgetRef ref, List<ReminderModel> tasks, String locale) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingTextStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
          columns: [
            DataColumn(label: Text(AppStrings.get(ref, 'table_no') ?? 'NO')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_no') ?? 'NO')),
                      DataColumn(label: Text(AppStrings.get(ref, 'table_date') ?? 'TARД°H')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_time') ?? 'SAAT')),
            DataColumn(label: Text(AppStrings.get(ref, 'main_template_upper') ?? 'ANA ЕћABLON')),
            DataColumn(label: Text(AppStrings.get(ref, 'sub_task_upper') ?? 'ALT GГ–REV')),
            DataColumn(label: Text(AppStrings.get(ref, 'status_action_upper') ?? 'DURUM (Д°ЕћLEM)')),
            DataColumn(label: Text(AppStrings.get(ref, 'edit_upper') ?? 'DГњZENLE')),
            DataColumn(label: Text(AppStrings.get(ref, 'delete_upper') ?? (AppStrings.get(ref, 'delete_upper') ?? 'SД°L'))),
          ],
          rows: tasks.asMap().entries.map((e) {
            final int index = e.key + 1;
            final t = e.value;
            String displayDate = DateFormat('dd.MM.yyyy', AppStrings.getDateFormatLocale(locale)).format(t.startDate);
            String mainTitle = t.title.contains(' - ') ? t.title.split(' - ').first : t.title;
            String subTitle = t.title.contains(' - ') ? t.title.substring(t.title.indexOf(' - ') + 3) : '-';

            return DataRow(cells: [
                        DataCell(Text(index.toString(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
              DataCell(Text(index.toString(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
              DataCell(Text(displayDate, style: const TextStyle(color: Colors.white54))),
              DataCell(Text(t.timeText, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))),
              DataCell(Text(mainTitle, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(SizedBox(width: 150, child: Text(subTitle, overflow: TextOverflow.ellipsis, style: TextStyle(color: t.isCompleted ? Colors.greenAccent : Colors.white, decoration: t.isCompleted ? TextDecoration.lineThrough : null)))),
              DataCell(
                 InkWell(
                   onTap: () {
                       ref.read(reminderProvider.notifier).toggleCompletionForDate(t.id, t.startDate, !t.isCompleted);
                   },
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: t.isCompleted ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                       borderRadius: BorderRadius.circular(6),
                       border: Border.all(color: t.isCompleted ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
                     ),
                     child: Text(t.isCompleted ? (AppStrings.get(ref, 'completed_upper') ?? 'TAMAMLANDI') : (AppStrings.get(ref, 'open_pending') ?? 'AГ‡IK (BEKLД°YOR)'), style: TextStyle(color: t.isCompleted ? Colors.green : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                   )
                 )
              ),
              DataCell(
                IconButton(
                   icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                   onPressed: () => _showEditReminderDialog(context, t),
                )
              ),
              DataCell(
                IconButton(
                   icon: const Icon(Icons.delete, color: Colors.white30, size: 18),
                   onPressed: () => ref.read(reminderProvider.notifier).deleteReminder(t.id),
                )
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    String title = "";
    TimeOfDay selectedTime = TimeOfDay.now();
    String recurrence = "none";
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(AppStrings.get(ref, 'add_new_task') ?? 'Yeni GГ¶rev Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: AppStrings.get(ref, 'task_name') ?? 'GГ¶rev AdД±'),
                      onChanged: (value) => title = value,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.get(ref, 'time_label') ?? 'Saat:', style: TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setDialogState(() => selectedTime = time);
                            }
                          },
                          child: Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.get(ref, 'cancel') ?? 'Д°ptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (title.isNotEmpty) {
                      ref.read(reminderProvider.notifier).addReminder(
                        title: title,
                        startDate: _selectedDate,
                        timeText: selectedTime.format(context),
                        recurrence: recurrence,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(AppStrings.get(ref, 'save') ?? 'Kaydet'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showEditReminderDialog(BuildContext context, ReminderModel reminder) {
    String title = reminder.title;
    TimeOfDay selectedTime = TimeOfDay.now();
    try {
      final parts = reminder.timeText.split(RegExp(r'[: ]'));
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      if (reminder.timeText.toLowerCase().contains('pm') && hour < 12) hour += 12;
      if (reminder.timeText.toLowerCase().contains('am') && hour == 12) hour = 0;
      selectedTime = TimeOfDay(hour: hour, minute: minute);
    } catch (_) {}

    String recurrence = reminder.recurrence;
    final controller = TextEditingController(text: title);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(AppStrings.get(ref, 'edit_task') ?? 'GГ¶revi DГјzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: AppStrings.get(ref, 'task_name') ?? 'GГ¶rev AdД±'),
                      onChanged: (value) => title = value,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.get(ref, 'time_label') ?? 'Saat:', style: TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setDialogState(() => selectedTime = time);
                            }
                          },
                          child: Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.get(ref, 'cancel') ?? 'Д°ptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (title.isNotEmpty) {
                      ref.read(reminderProvider.notifier).editReminder(
                        id: reminder.id,
                        title: title,
                        startDate: reminder.startDate,
                        timeText: selectedTime.format(context),
                        recurrence: recurrence,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(AppStrings.get(ref, 'save') ?? 'Kaydet'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildFinanceStyleCalendarGrid(List<ReminderModel> allReminders) {
    int daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    
    int offset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    int totalCells = offset + daysInMonth > 35 ? 42 : 35;

    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final aspectRatio = screenWidth < 400 ? 0.35 : (screenWidth < 650 ? 0.45 : 0.6);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        int day = index - offset + 1;
        if (day < 1 || day > daysInMonth) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.02),
              border: Border.all(color: Colors.grey.withOpacity(0.1))
            ),
          );
        }
        
        DateTime cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
        bool isSelected = cellDate.day == _selectedDate.day && cellDate.month == _selectedDate.month && cellDate.year == _selectedDate.year;
        final dayTasks = ref.read(reminderProvider.notifier).getRemindersForDate(cellDate).toList();
        
        int completedTaskCount = dayTasks.where((t) => t.isCompleted).length;
        double percentage = dayTasks.isEmpty ? 0.0 : (completedTaskCount / dayTasks.length) * 100;
        bool allCompleted = dayTasks.isNotEmpty && completedTaskCount == dayTasks.length;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
            Navigator.push(context, MaterialPageRoute(builder: (context) => PlannerSetupFullScreen(initialDate: cellDate)));
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.2), width: isSelected ? 2 : 1),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                       color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                       shape: BoxShape.circle,
                    ),
                    child: Text(day.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
                  ),
                ),
                const SizedBox(height: 4),
                if (dayTasks.isNotEmpty)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('${dayTasks.length} ' + (AppStrings.get(ref, 'tasks_suffix') ?? 'GГ¶rev'), style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('%${percentage.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: allCompleted ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: allCompleted ? Colors.green.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: allCompleted ? Colors.green.withOpacity(0.3) : Colors.orangeAccent.withOpacity(0.3))
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(allCompleted ? (AppStrings.get(ref, 'completed_task') ?? 'TamamlandД±') : (AppStrings.get(ref, 'open_status') ?? 'AГ§Д±k'), style: TextStyle(fontSize: 8, color: allCompleted ? Colors.green : Colors.orangeAccent, fontWeight: FontWeight.bold), maxLines: 1),
                          ),
                        )
                      ]
                    )
                  )
              ],
            ),
          ),
        );
      },
        );
      },
    );
  }

  Widget _buildDailySummaryBox(String locale, List<ReminderModel> monthReminders) {
    int total = monthReminders.length;
    int completedCount = monthReminders.where((r) => r.isCompleted).length;
    int pendingCount = total - completedCount;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text((AppStrings.get(ref, 'monthly_upper') ?? 'AYLIK') + ' ' + (AppStrings.get(ref, 'task_stats') ?? 'GГ–REV Д°STATД°STД°KLERД°'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(DateFormat('MMMM yyyy', AppStrings.getDateFormatLocale(locale)).format(_currentMonth), style: const TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatBox((AppStrings.get(ref, 'total_task') ?? 'TOPLAM\nGГ–REV'), '$total', Colors.white),
                              const SizedBox(width: 16),
                              _buildStatBox((AppStrings.get(ref, 'completed_task') ?? 'TAMAMLANAN'), '$completedCount', Colors.greenAccent),
                              const SizedBox(width: 16),
                              _buildStatBox((AppStrings.get(ref, 'pending_task') ?? 'BEKLEYEN'), '$pendingCount', Colors.orangeAccent),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: Colors.white12),
                Expanded(
                   flex: 2,
                   child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                            Text(total == 0 ? '%0' : '%${((completedCount / total) * 100).toStringAsFixed(1)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 8),
                            Text((AppStrings.get(ref, 'completion_rate') ?? 'Tamamlanma OranД±'), style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                               value: total == 0 ? 0 : (completedCount / total),
                               backgroundColor: Colors.white10,
                               color: _getPerformanceColor(total == 0 ? 0 : completedCount / total),
                               minHeight: 8,
                               borderRadius: BorderRadius.circular(4),
                            )
                         ]
                      )
                   )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double ratio) {
     if (ratio >= 0.8) return Colors.greenAccent;
     if (ratio >= 0.5) return Colors.orangeAccent;
     return Colors.redAccent;
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, height: 1.2)),
      ],
    );
  }

  Future<void> _exportPlanner() async {
    try {
        final locale = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
        final allReminders = ref.watch(reminderProvider);
        final monthReminders = allReminders
           .where((r) => r.startDate.year == _currentMonth.year && r.startDate.month == _currentMonth.month)
           .map((r) => ref.read(reminderProvider.notifier).getRemindersForDate(r.startDate).firstWhere((element) => element.id == r.id, orElse: () => r))
           .toList();
        monthReminders.sort((a, b) => a.startDate.compareTo(b.startDate));

        final widgetToCapture = ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: Localizations(
            locale: const Locale('en', 'US'),
            delegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: MediaQuery(
                data: const MediaQueryData(size: Size(1080, 1920)),
                child: Theme(
                  data: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0F172A)),
                  child: Container(
                    width: 1080, height: 1920,
                    color: const Color(0xFF0F172A),
                    child: FittedBox(
                      fit: BoxFit.scaleDown, alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 1080,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                             color: const Color(0xFF0F172A),
                             padding: const EdgeInsets.all(32.0),
                             child: Column(
                                children: [
                                   _buildDailySummaryBox(locale, monthReminders),
                                   const SizedBox(height: 32),
                                   if (monthReminders.isNotEmpty) ...[
                                     _buildSectionTitle((AppStrings.get(ref, 'monthly_tasks_table') ?? 'AYLIK GOREVLER TABLOSU')),
                                     const SizedBox(height: 12),
                                     _buildTaskDataTable(ref, monthReminders, locale),
                                     const SizedBox(height: 32),
                                   ],
                                   if (monthReminders.isEmpty)
                                      Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(AppStrings.get(ref, 'no_monthly_tasks') ?? 'Bu aya ait gorev bulunamadi.', style: const TextStyle(color: Colors.white30, fontSize: 16)))),
                                ]
                             )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        );
        final Uint8List? imageBytes = await _captureOffScreenWidget(widgetToCapture);
        if (imageBytes == null) return;

        String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        String prefix = "MonthlyPlan";
        String fileName = '${prefix}_${timestamp}.png';

        if (kIsWeb) {
          final blob = html.Blob([imageBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kay?t Basar?l?! PNG Dosyas? indirildi.')), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
          }
        } else {
            Directory dir;
            if (defaultTargetPlatform == TargetPlatform.android) {
                dir = Directory('/storage/emulated/0/Download');
            } else {
                dir = await getApplicationDocumentsDirectory();
            }
            final filePath = '${dir.path}/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(imageBytes);
            if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.macOS) { await Gal.putImage(filePath); } else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Windows Indirilenler Klasorune Kaydedildi: $filePath'), duration: Duration(seconds: 5), backgroundColor: Colors.green)); }
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_png') ?? 'Galeriye Kaydedildi!')));
        }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_failed') ?? 'Kay?t basar?s?z: {error}').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  Widget _buildActionButtons(List<ReminderModel> activeRems) {
     return Row(
       mainAxisAlignment: MainAxisAlignment.end,
       children: [
          ElevatedButton.icon(
             onPressed: () {
                 showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                       backgroundColor: Theme.of(context).cardColor,
                       title: Text((AppStrings.get(ref, 'delete_all') ?? 'TГјmГјnГј Sil'), style: TextStyle(color: Colors.white)),
                       content: Text(AppStrings.get(ref, 'confirm_delete_all_tasks') ?? 'Listedeki tГјm gГ¶revler silinecek! OnaylД±yor musunuz?', style: TextStyle(color: Colors.white70)),
                       actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get(ref, 'cancel_upper') ?? 'Д°PTAL', style: TextStyle(color: Colors.grey))),
                          ElevatedButton(
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                             onPressed: () {
                                for (var r in activeRems) {
                                   ref.read(reminderProvider.notifier).deleteReminder(r.id);
                                }
                                Navigator.pop(ctx);
                             }, 
                             child: Text(AppStrings.get(ref, 'delete_all_upper') ?? 'TГњMГњNГњ SД°L', style: TextStyle(color: Colors.white))
                          )
                       ]
                    )
                 );
             },
             icon: const Icon(Icons.delete_sweep, color: Colors.white),
             label: Text((AppStrings.get(ref, 'delete_upper') ?? 'SД°L'), style: TextStyle(color: Colors.white)),
             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
             onPressed: _exportPlanner,
             icon: const Icon(Icons.download, color: Colors.white),
             label: Text((AppStrings.get(ref, 'export_title') ?? 'DД±Еџa Aktar'), style: TextStyle(color: Colors.white)),
             style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
       ]
     );
  }
}

class _FinancePlanTabInner extends ConsumerStatefulWidget {
  const _FinancePlanTabInner({Key? key}) : super(key: key);

  @override
  ConsumerState<_FinancePlanTabInner> createState() => _FinancePlanTabInnerState();
}

class _FinancePlanTabInnerState extends ConsumerState<_FinancePlanTabInner> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();
  final Map<String, ScreenshotController> _screenshotControllers = {};
  String _selectedTab = 'Futures';

  Future<void> _exportScreenshot(String exchange) async {
    try {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'exporting') ?? 'DД±Еџa aktarД±lД±yor, lГјtfen bekleyin...'), duration: const Duration(seconds: 2)));
        await Future.delayed(const Duration(milliseconds: 300));
        
        final allTrades = ref.read(tradeProvider);
        final monthTrades = allTrades.where((t) => 
            (t.exitDate == null && t.date.year <= _currentMonth.year && t.date.month <= _currentMonth.month) || 
            (t.exitDate != null && t.exitDate!.year == _currentMonth.year && t.exitDate!.month == _currentMonth.month)
        ).toList();
        final displayedTrades = monthTrades.where((t) => t.market == _selectedTab).toList();
    displayedTrades.sort((a, b) => b.date.compareTo(a.date));
        final exchangeTrades = displayedTrades.where((t) => t.exchange == exchange).toList();
        final currencySymbol = '\$';
        final locale = AppStrings.getDateFormatLocale(ref.read(localeProvider));
        
        final widgetToCapture = ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: Localizations(
            locale: const Locale('en', 'US'),
            delegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: MediaQuery(
                data: const MediaQueryData(size: const Size(1080, 1920)),
                child: Theme(
                  data: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0F172A)),
                  child: Container(
                    width: 1080, height: 1920,
                    color: const Color(0xFF0F172A),
                    child: FittedBox(
                      fit: BoxFit.scaleDown, alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 1080,
                        child: Material(
                          color: Colors.transparent,
                          child: _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale, Theme.of(context)),
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        );
        final Uint8List? imageBytes = await _captureOffScreenWidget(widgetToCapture);
        if (imageBytes == null) return;

        
        String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        String fileName = '${exchange}_MonthlyJournal_${timestamp}.png';
        
        if (kIsWeb) {
          final blob = html.Blob([imageBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kay?t Basar?l?! PNG Dosyas? indirildi.')), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
          }
        } else {
            Directory dir;
            if (defaultTargetPlatform == TargetPlatform.android) {
                dir = Directory('/storage/emulated/0/Download');
            } else {
                dir = await getApplicationDocumentsDirectory();
            }
            final filePath = '${dir.path}/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(imageBytes);
            if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.macOS) { await Gal.putImage(filePath); } else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Windows Indirilenler Klasorune Kaydedildi: $filePath'), duration: Duration(seconds: 5), backgroundColor: Colors.green)); }
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_success_png') ?? 'Galeriye Kaydedildi!')));
        }

    } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_failed') ?? 'KayД±t baЕџarД±sД±z: {error}').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
}

  Widget _buildTpCell(TradeModel t) {
    if (t.market == 'Spot') {
      List<String> lines = [];
      if (t.takeProfit != null) lines.add('в¬‡ ${AppStrings.get(ref, 'buy') ?? 'AlД±m'} 1: ${t.takeProfit}');
      if (t.buyTargets != null && t.buyTargets!.isNotEmpty) {
        for (int i = 0; i < t.buyTargets!.length; i++) {
           lines.add('в¬‡ ${AppStrings.get(ref, 'buy') ?? 'AlД±m'} ${i+2}: ${t.buyTargets![i]}');
        }
      }
      if (t.sellTargets != null && t.sellTargets!.isNotEmpty) {
        for (int i = 0; i < t.sellTargets!.length; i++) {
           lines.add('в¬† ${AppStrings.get(ref, 'sell') ?? 'SatД±Еџ'} ${i+1}: ${t.sellTargets![i]}');
        }
      }
      if (lines.isEmpty) return Text('-');
      return Text(lines.join("\n"), style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.amberAccent));
    } else {
      List<String> tps = [];
      if (t.takeProfit != null) tps.add('TP-1: ${t.takeProfit}');
      if (t.takeProfits != null) {
        for (int i = 0; i < t.takeProfits!.length; i++) {
          tps.add('TP-${i + 2}: ${t.takeProfits![i]}');
        }
      }
      if (tps.isEmpty) return Text('-');
      return Text(tps.join("\n"), style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.greenAccent));
    }
  }

  Widget _buildMonthSelector(ThemeData theme, String locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1)),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _currentMonth,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (picked != null) {
                  setState(() => _currentMonth = DateTime(picked.year, picked.month, 1));
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('MM', AppStrings.getDateFormatLocale(locale)).format(_currentMonth), style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(DateFormat('MMMM', AppStrings.getDateFormatLocale(locale)).format(_currentMonth).toUpperCase(), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w300, letterSpacing: 4)),
                    const SizedBox(width: 8),
                    Text(DateFormat('yyyy', AppStrings.getDateFormatLocale(locale)).format(_currentMonth), style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey)),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title) {
    bool isSelected = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = title),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyTradeTable(ThemeData theme, String locale, String currencySymbol, List<TradeModel> displayedTrades) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingTextStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
          columns: [
            DataColumn(label: Text(AppStrings.get(ref, 'table_no') ?? 'NO')),
                      DataColumn(label: Text(AppStrings.get(ref, 'table_date') ?? 'TARД°H')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_time') ?? 'SAAT')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_exchange') ?? 'BORSA')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_market') ?? 'PIYASA')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_pair') ?? 'PARД°TE')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_direction') ?? 'YГ–N')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_leverage') ?? 'KALDIRAГ‡')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_capital') ?? 'SERMAYE')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_entry') ?? 'GД°RД°Ећ')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_exit') ?? 'Г‡IKIЕћ')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_sl') ?? 'SL')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_tp') ?? 'TP')),
            DataColumn(label: Text('P&L %')),
            DataColumn(label: Text('P&L \$')),
            DataColumn(label: Text(AppStrings.get(ref, 'table_notes') ?? 'NOTLAR')),
            DataColumn(label: Text(AppStrings.get(ref, 'edit_upper'))),
            DataColumn(label: Text(AppStrings.get(ref, 'delete_upper'))),
          ],
          rows: displayedTrades.asMap().entries.map((entry) {
                      int index = entry.key + 1;
                      var t = entry.value;
            bool isLong = t.type.toLowerCase() == 'long' || t.type.toLowerCase() == 'alД±Еџ';
            double parsedPnlPct = t.pnlPercent ?? 0;
            double parsedPnlAmt = t.pnlAmount ?? 0;
            bool isWin = parsedPnlAmt > 0;

            String displayDate = DateFormat('dd.MM.yyyy', AppStrings.getDateFormatLocale(locale)).format(t.date);
            if (t.exitDate != null && (t.date.year != t.exitDate!.year || t.date.month != t.exitDate!.month || t.date.day != t.exitDate!.day)) {
               displayDate = '${DateFormat('dd.MM', AppStrings.getDateFormatLocale(locale)).format(t.date)} - ${DateFormat('dd.MM', AppStrings.getDateFormatLocale(locale)).format(t.exitDate!)}';
            }

            return DataRow(cells: [
                        DataCell(Text(index.toString(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
              DataCell(Text(displayDate, style: const TextStyle(color: Colors.white54))),
              DataCell(Text(t.timeText)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance, size: 14, color: Colors.amberAccent),
                  const SizedBox(width: 6),
                  Text(t.exchange),
                ],
              )),
              DataCell(Text(t.market)),
              DataCell(Text((t.pair.toLowerCase() == "belirsiz" || t.pair.toLowerCase() == "undefined" || t.pair == "РќРµ РѕРїСЂРµРґРµР»РµРЅРѕ" || t.pair == "Р‘РµР»РіРёСЃРёР·") ? (AppStrings.get(ref, 'undefined_text') ?? 'Belirsiz') : t.pair, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLong ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isLong ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
                  ),
                  child: Text(t.type, style: TextStyle(color: isLong ? Colors.green : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              DataCell(Text(t.leverage, style: const TextStyle(color: Colors.white54))),
              DataCell(Text('$currencySymbol${t.capitalAllocated}')),
              DataCell(Text('${t.entryPrice}')),
              DataCell(Text(t.exitPrice != null ? '${t.exitPrice}' : '-')),
              DataCell(Text(t.stopLoss != null ? '${t.stopLoss}' : '-')),
              DataCell(_buildTpCell(t)),
              DataCell(
                t.exitPrice == null 
                  ? Text(AppStrings.get(ref, 'status_open'), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))
                  : Text(
                      parsedPnlPct > 0 ? '+${parsedPnlPct.toStringAsFixed(2)}%' : '${parsedPnlPct.toStringAsFixed(2)}%',
                      style: TextStyle(color: isWin ? Colors.greenAccent : (parsedPnlPct < 0 ? Colors.redAccent : Colors.white)),
                    )
              ),
              DataCell(
                t.exitPrice == null 
                  ? Text(AppStrings.get(ref, 'status_open'), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))
                  : Text(
                      parsedPnlAmt > 0 ? '+$currencySymbol${parsedPnlAmt.toStringAsFixed(2)}' : (parsedPnlAmt < 0 ? '-$currencySymbol${parsedPnlAmt.abs().toStringAsFixed(2)}' : '\$0'),
                      style: TextStyle(color: isWin ? Colors.greenAccent : (parsedPnlAmt < 0 ? Colors.redAccent : Colors.white), fontWeight: FontWeight.bold),
                    )
              ),
              DataCell(SizedBox(width: 150, child: Text(t.notes ?? '', overflow: TextOverflow.ellipsis))),
              DataCell(
                IconButton(
                   icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                   onPressed: () {
                     showDialog(
                       context: context,
                       builder: (context) => AddTradeDialog(date: t.date, trade: t),
                     );
                   },
                )
              ),
              DataCell(
                IconButton(
                   icon: const Icon(Icons.delete, color: Colors.white30, size: 18),
                   onPressed: () => ref.read(tradeProvider.notifier).deleteTrade(t.id),
                )
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(tradeProvider); // watch for reactivity on trades
    final theme = Theme.of(context);
    final locale = AppStrings.getDateFormatLocale(ref.watch(localeProvider));
    final currencySymbol = '\$';
    
    final allTrades = ref.read(tradeProvider);
    final monthTrades = allTrades.where((t) => 
        (t.date.year == _currentMonth.year && t.date.month == _currentMonth.month) || 
        (t.exitDate != null && t.exitDate!.year == _currentMonth.year && t.exitDate!.month == _currentMonth.month)
    ).toList();
    final displayedTrades = monthTrades.where((t) => t.market == _selectedTab).toList();
    displayedTrades.sort((a, b) => b.date.compareTo(a.date));

    final activeExchanges = displayedTrades.map((t) => t.exchange).toSet().toList();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (Month Year)
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16),
               child: _buildMonthSelector(theme, locale),
            ),
            
            // Days of week
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: AppStrings.getTranslatedDays(locale).map((day) {
                  return Expanded(
                    child: Container(
                      color: theme.brightness == Brightness.dark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      child: Text(day, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
            
            // Grid
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16),
               child: _buildMonthlyCalendarGrid(),
            ),
            const SizedBox(height: 24),

            // Tab Selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _buildTabButton('Futures'),
                    const SizedBox(width: 4),
                    _buildTabButton('Spot'),
                  const SizedBox(width: 4),
                  _buildTabButton('MT5'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (activeExchanges.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(AppStrings.get(ref, 'no_trades_month'), style: const TextStyle(color: Colors.white30, fontSize: 16)),
                ),
              ),

            ...activeExchanges.map((exchange) {
              final exchangeTrades = displayedTrades.where((t) => t.exchange == exchange).toList();
              if (!_screenshotControllers.containsKey(exchange)) {
                 _screenshotControllers[exchange] = ScreenshotController();
              }
              return _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale, theme);
            }).toList(),

            if (activeExchanges.isNotEmpty)
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildGlobalMonthlyGrandTotalSummary(displayedTrades, currencySymbol, locale),
               ),
               
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeBlock(String exchange, List<TradeModel> exchangeTrades, String currencySymbol, String locale, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
          color: const Color(0xFF0F172A),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title and Export Button
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       const Icon(Icons.account_balance, color: Colors.amberAccent),
                       const SizedBox(width: 8),
                       Text('$exchange ${AppStrings.get(ref, 'monthly_report')}'.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 1.5)),
                    ]
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _exportScreenshot(exchange),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(AppStrings.get(ref, 'export')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]
              ),
              const SizedBox(height: 16),
              
              // The Month Selector inside Screenshot
              _buildMonthSelector(theme, locale),
              const SizedBox(height: 16),

              // Table
              _buildMonthlyTradeTable(theme, locale, currencySymbol, exchangeTrades),
              const SizedBox(height: 24),
              
              // Monthly Trade Summary Stats
              _buildMonthlyTradeSummary(theme, locale, exchangeTrades, exchange),
            ],
          ),
        )
    );
  }

  Widget _buildMonthlyCalendarGrid() {
    int daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    
    int offset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    int totalCells = offset + daysInMonth > 35 ? 42 : 35;

    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final aspectRatio = screenWidth < 400 ? 0.35 : (screenWidth < 650 ? 0.45 : 0.6);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        int day = index - offset + 1;
        if (day < 1 || day > daysInMonth) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.02),
              border: Border.all(color: Colors.grey.withOpacity(0.1))
            ),
          );
        }
        
        DateTime cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
        bool isSelected = cellDate.day == _selectedDate.day && cellDate.month == _selectedDate.month && cellDate.year == _selectedDate.year;
        final rawDayTrades = ref.watch(tradeProvider.notifier).getTradesForDate(cellDate);
        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);
        
        final dayTrades = rawDayTrades.where((t) {
            if ((t.exitPrice == null || t.exitDate == null) && cellDate.isAfter(todayMidnight)) {
                return false;
            }
            return true;
        }).toList();
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DailyTradeJournalScreen(date: cellDate)),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.2), width: isSelected ? 2 : 1),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                       color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                       shape: BoxShape.circle,
                    ),
                    child: Text(day.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
                  ),
                ),
                const SizedBox(height: 4),
                if (dayTrades.isNotEmpty)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            if (dayTrades.any((t) => t.market == 'Spot'))
                                Text('S:${dayTrades.where((t) => t.market == 'Spot').length}', style: const TextStyle(fontSize: 9, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                              if (dayTrades.any((t) => t.market == 'Futures'))
                                Text('F:${dayTrades.where((t) => t.market == 'Futures').length}', style: const TextStyle(fontSize: 9, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                              if (dayTrades.any((t) => t.market == 'MT5'))
                                Text('MT5:${dayTrades.where((t) => t.market == 'MT5').length}', style: const TextStyle(fontSize: 9, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${dayTrades.where((t) => t.exitPrice != null).length}/${dayTrades.length} ${AppStrings.get(ref, 'done')}', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: dayTrades.where((t) => t.exitPrice != null).length == dayTrades.length && dayTrades.isNotEmpty ? Colors.greenAccent : Colors.white54, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        if (dayTrades.isNotEmpty)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              children: dayTrades.take(2).map((trade) {
                                double pnlAmount = trade.pnlAmount ?? 0;
                                bool isOpen = trade.exitPrice == null;
                                bool isWin = pnlAmount >= 0;
                                String prefix = trade.market == 'Spot' ? 'S' : (trade.market == 'MT5' ? 'MT5' : 'F');
                                return Container(
                                   margin: const EdgeInsets.only(bottom: 2),
                                   padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                   decoration: BoxDecoration(
                                      color: isOpen ? Colors.orangeAccent.withOpacity(0.1) : (isWin ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1)),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: isOpen ? Colors.orangeAccent.withOpacity(0.3) : (isWin ? Colors.green.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)))
                                   ),
                                   child: isOpen 
                                     ? Text('$prefix: ${AppStrings.get(ref, 'status_open') ?? 'AГ‡IK'}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orangeAccent), textAlign: TextAlign.center, maxLines: 1)
                                     : Text(
                                         '$prefix: ${isWin ? '+' : '-'}\$${pnlAmount.abs().toStringAsFixed(1)}',
                                         style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isWin ? Colors.green : Colors.redAccent),
                                         maxLines: 1,
                                         textAlign: TextAlign.center,
                                         overflow: TextOverflow.ellipsis,
                                       ),
                                );
                              }).toList(),
                            ),
                          ),
                        if (dayTrades.length > 2)
                          Padding(
                             padding: const EdgeInsets.only(top: 2),
                             child: Text('+${dayTrades.length - 2}', style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          )
                      ],
                    )
                  )
              ],
            ),
          ),
        );
      },
        );
      },
    );
  }


  // Removed simple task empty state and FAB dialog.

  Widget _buildMonthlyTradeSummary(ThemeData theme, String locale, List<TradeModel> displayedTrades, String exchange) {
    final currencySymbol = '\$';

    int winCount = 0;
    int lossCount = 0;
    double totalProfit = 0;
    double totalLoss = 0;

    final closedTrades = displayedTrades.where((t) => t.exitPrice != null).toList();
    closedTrades.sort((a, b) => a.exitDate!.compareTo(b.exitDate!));

    for (var t in closedTrades) {
      final pnl = t.pnlAmount ?? 0;
      if (pnl > 0) {
        winCount++;
        totalProfit += pnl;
      } else if (pnl < 0) {
        lossCount++;
        totalLoss += pnl;
      }
    }

    double netPnL = totalProfit + totalLoss;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text('$exchange $_selectedTab ${AppStrings.get(ref, 'trade_summary')}'.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(DateFormat('MMMM yyyy', AppStrings.getDateFormatLocale(locale)).format(_currentMonth), style: const TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          SizedBox(
            height: 320,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBox(AppStrings.get(ref, 'total_closed'), '${closedTrades.length}', Colors.white),
                            _buildStatBox(AppStrings.get(ref, 'winning_trades'), '$winCount', Colors.greenAccent),
                            _buildStatBox(AppStrings.get(ref, 'loser_upper') ?? 'KAYBEDEN', '$lossCount', Colors.redAccent),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBox(AppStrings.get(ref, 'money_won'), '+$currencySymbol${totalProfit.toStringAsFixed(2)}', Colors.greenAccent),
                            _buildStatBox(AppStrings.get(ref, 'money_lost'), '-$currencySymbol${totalLoss.abs().toStringAsFixed(2)}', Colors.redAccent),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text('${AppStrings.get(ref, 'monthly_net_profit')} $exchange', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${netPnL >= 0 ? '+' : ''}$currencySymbol${netPnL.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: netPnL >= 0 ? Colors.greenAccent : Colors.redAccent),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(color: Colors.white12, width: 1),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$exchange ${AppStrings.get(ref, 'pnl_chart')}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Expanded(child: _buildBarChart(closedTrades)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGlobalMonthlyGrandTotalSummary(List<TradeModel> displayedTrades, String currencySymbol, String locale) {
    int winCount = 0;
    int lossCount = 0;
    double grandProfit = 0;
    double grandLoss = 0;

    final closedTrades = displayedTrades.where((t) => t.exitPrice != null).toList();

    for (var t in closedTrades) {
      final pnl = t.pnlAmount ?? 0;
      if (pnl > 0) {
        winCount++;
        grandProfit += pnl;
      } else if (pnl < 0) {
        lossCount++;
        grandLoss += pnl;
      }
    }

    double grandNet = grandProfit + grandLoss;

    return Column(
      children: [
        const Divider(color: Colors.white24, height: 40, thickness: 2),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
               colors: [const Color(0xFF1E293B), Colors.blueAccent.withOpacity(0.1)],
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
          ),
          child: Column(
            children: [
              Text('${AppStrings.get(ref, 'general_monthly_summary')} (${DateFormat('MMMM yyyy', AppStrings.getDateFormatLocale(locale)).format(_currentMonth)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                    _buildStatBox(AppStrings.get(ref, 'total_profit'), '+$currencySymbol${grandProfit.toStringAsFixed(2)}', Colors.greenAccent),
                    _buildStatBox(AppStrings.get(ref, 'total_loss'), '-$currencySymbol${grandLoss.abs().toStringAsFixed(2)}', Colors.redAccent),
                    _buildStatBox(AppStrings.get(ref, 'all_exchanges_closed'), '${closedTrades.length}', Colors.white),
                 ],
              ),
              const SizedBox(height: 24),
              Text(AppStrings.get(ref, 'all_exchanges_net_pnl'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  grandNet >= 0 ? '+$currencySymbol${grandNet.toStringAsFixed(2)}' : '-$currencySymbol${grandNet.abs().toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: grandNet >= 0 ? Colors.greenAccent : Colors.redAccent),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<TradeModel> trades) {
    if (trades.isEmpty) return Center(child: Text(AppStrings.get(ref, 'no_data') ?? 'Veri Yok', style: const TextStyle(color: Colors.white24)));
    
    double maxAbsY = 0;
    
    List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < trades.length; i++) {
        final t = trades[i];
        final pnlAmt = t.pnlAmount ?? 0;
        
        if (pnlAmt.abs() > maxAbsY) maxAbsY = pnlAmt.abs();
        
        barGroups.add(
           BarChartGroupData(
              x: i,
              showingTooltipIndicators: [0], // Her sГјtunun ucunda kГўr/zararД± gГ¶sterecek
              barRods: [
                 BarChartRodData(
                    fromY: 0,
                    toY: pnlAmt,
                    color: pnlAmt >= 0 ? Colors.greenAccent : Colors.redAccent,
                    width: 20, // Mum geniЕџliДџi
                    borderRadius: BorderRadius.zero, // Mum gibi keskin kenarlar
                 ),
              ],
           )
        );
    }

    if (maxAbsY == 0) maxAbsY = 10;
    double maxY = maxAbsY * 1.3; // Гњstte ve altta yazД±lar iГ§in %30 boЕџluk bД±rak
    double minY = -maxY; // 0 Г§izgisi tam ortada olsun diye simetrik eksen

    double chartWidth = trades.length * 80.0; // SГјtunlar arasД± daha geniЕџ mesafe
    if (chartWidth < 300) chartWidth = 300;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: minY,
              gridData: FlGridData(
                show: true, 
                drawVerticalLine: false, 
                getDrawingHorizontalLine: (val) {
                   if (val == 0) return const FlLine(color: Colors.white54, strokeWidth: 2); // Ortadaki 0 Г§izgisi kalД±n beyaz
                   return const FlLine(color: Colors.white10, strokeWidth: 1);
                }
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30, // Sadece Coin ismi iГ§in alt boЕџluk
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= trades.length) return const SizedBox.shrink();
                      final t = trades[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(t.pair, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: false, // KalД±cД± olarak gГ¶sterdiДџimiz iГ§in dokunmayД± kapat
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.transparent, // ArkaplanД± Еџeffaf yap
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 4,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final t = trades[groupIndex];
                      final pnlAmt = t.pnlAmount ?? 0;
                      final pnlPct = t.pnlPercent ?? 0;
                      final isWin = pnlAmt >= 0;
                      final color = isWin ? Colors.greenAccent : Colors.redAccent;
                      
                      return BarTooltipItem(
                         isWin ? '+\$${pnlAmt.toStringAsFixed(1)}\n+%${pnlPct.toStringAsFixed(1)}' 
                               : '-\$${pnlAmt.abs().toStringAsFixed(1)}\n-%${pnlPct.abs().toStringAsFixed(1)}',
                         TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                      );
                  }
                )
              ),
              barGroups: barGroups,
            ),
          ),
        ),
      ),
    );
  }
}


Future<Uint8List?> _captureOffScreenWidget(Widget widget) async {
  final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
  // ignore: deprecated_member_use
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final RenderView renderView = RenderView(
    view: view,
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: repaintBoundary,
    ),
    configuration: const ViewConfiguration(
      logicalConstraints: BoxConstraints.tightFor(width: 1080, height: 1920),
      physicalConstraints: BoxConstraints.tightFor(width: 1080 * 2.0, height: 1920 * 2.0),
      devicePixelRatio: 2.0,
    ),
  );

  final PipelineOwner pipelineOwner = PipelineOwner();
  final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

  final RenderObjectToWidgetElement<RenderBox> rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    child: widget,
  ).attachToRenderTree(buildOwner);

  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();

  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  final ui.Image image = await repaintBoundary.toImage(pixelRatio: 2.0);
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}

